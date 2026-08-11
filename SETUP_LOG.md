# Setup log — AWS deployment + CI/CD + S3 uploads

A record of everything actually done to get this project onto AWS, in the
order it happened, including the problems hit and how they were fixed.
`DEPLOY.md` is the clean step-by-step runbook (e.g. for setting this up
again from scratch on a new box); this file is the "what we actually did
and why" reference for troubleshooting and onboarding.

## Architecture

- **Repos** (4 separate GitHub repos, not one monorepo):
  - `varnisha-e-commarce-backend` — Express API
  - `varnisha-e-commarce-user` — Next.js storefront (`www.varnisha.com`)
  - `varnisha-e-commarce-admin` — Next.js admin panel (`laxmi.varnisha.com`)
  - `varnisha-e-commarce` — infra repo (Terraform, Nginx configs, PM2 config, bootstrap script, this file, `DEPLOY.md`)
- **Compute**: single EC2 instance (`t3.medium`, Ubuntu 22.04, `ap-south-1`) running:
  - self-hosted MongoDB (auth enabled, app user `varnishaApp` on db `ecommercestore`)
  - all 3 apps via PM2 (`varnisha-backend` :3045, `varnisha-user` :3000, `varnisha-admin` :3001)
  - Nginx reverse-proxying + Certbot-issued TLS for all 3 subdomains
- **Storage**: S3 bucket `varnisha-jewels-uploads-prod` (public read, IAM-role write) for admin image uploads; `varnisha-jewels-db-backups-prod` (private) for `mongodump` backups
- **DNS**: GoDaddy, 3 A records → the EC2 Elastic IP
- **CI/CD**: each app repo has its own `.github/workflows/deploy.yml` — push to `main` builds (backend: sanity-checks deps; frontends: full `next build`) then rsyncs over SSH and runs `pm2 startOrReload` on the box

Current Elastic IP: `13.234.5.160` (not a secret — safe to reference).

## What was built (chronological)

1. **CLAUDE.md** — initial repo documentation for the 3-app structure.
2. **Repo hygiene** (before any infra work):
   - Found `varnisha-e-commarce-backend` had real DB data committed to git history: `db_backup/` (JSON exports) and `data/` (raw MongoDB WiredTiger files, 100MB+ journal files) — both already pushed to GitHub (repo is private). Purged from all history with `git filter-repo`, force-pushed, verified clean (`.git` dropped from 100+MB to 339K).
   - The infra repo (`varnisha-e-commarce`) had a stray local commit that deleted its root `.gitignore`, leaving root-level `mongodb_data/` (real local Mongo data) tracked, on a local history that had diverged entirely from a freshly-reinitialized GitHub remote. Backed up the old local history to an unpushed branch, reset onto GitHub's clean state, restored `CLAUDE.md` and the local `mongodb_data/` files, added proper `.gitignore`.
3. **S3 image upload feature** (backend): discovered the only existing upload code (`POST /api/v1/ai-studio/analyze-image`) was broken (multer diskStorage doesn't populate `req.file.buffer`, which the controller read) and no other admin page had real upload wiring — product/category/etc. image fields were plain strings with no upload endpoint behind them at all.
   - Switched multer to `memoryStorage` (fixes the AI endpoint bug as a side effect).
   - Added `services/s3Service.js`, `controllers/admin/uploadController.js`, `routes/admin/uploadRoutes.js` → new `POST /api/v1/admin/uploads` endpoint, auth'd via `protect` + `requireAdmin`, uses the EC2 instance's IAM role (no static AWS keys in `.env`).
   - Wired this into the admin **Products** page (the only admin CRUD page actually connected to the real API — categories/collections/CMS pages are still static mockups with hardcoded demo data, not wired to the backend at all, so upload UI wasn't added there).
4. **Terraform** (`infra/terraform/`): EC2 instance, security group (22/80/443 open — 22 has to stay open to `0.0.0.0/0` since GitHub Actions runners have no fixed IP to allowlist; mitigated via key-only SSH auth, no password auth), IAM instance role scoped to S3, the two S3 buckets, Elastic IP, SSH keypair resource (public half only).
5. **Bootstrap script + PM2 + Nginx** (`infra/scripts/bootstrap.sh`, `ecosystem.config.js`, `infra/nginx/*.conf`): OS-level provisioning (Node, PM2, Nginx, MongoDB, Certbot, 2GB swapfile, SSH password-auth disabled), PM2 process definitions for all 3 apps, one Nginx server block per subdomain.
6. **GitHub Actions** (`deploy.yml` in each of the 3 app repos): build-in-CI, rsync over SSH, `pm2 startOrReload` on push to `main`.
7. **DEPLOY.md** — the manual runbook for everything requiring credentials (AWS, GoDaddy, GitHub secrets).

## Manual execution (what was actually run, and problems hit)

1. Installed AWS CLI + Terraform via `winget`.
2. `aws configure` — hit a snag: pasted real AWS credentials (root password, then a fake key, then a real access key + secret) into chat several times despite repeated warnings. **Those credentials must be treated as compromised** — rotate/deactivate anything pasted into a chat session. Going forward, credential values never get pasted here, only confirmation that a step is done.
3. IAM user `parthpatel` had zero permissions by default — attached `AmazonEC2FullAccess`, `AmazonS3FullAccess`, `IAMFullAccess` (broad, but acceptable for a personal single-user AWS account; Terraform needs EC2 + S3 + IAM role/policy/instance-profile creation).
4. Generated the shared deploy SSH keypair (`ssh-keygen -t ed25519`) — first attempt failed because `~/.ssh` didn't exist yet on Windows; created it, retried successfully.
5. `terraform.tfvars` — first `terraform apply` failed because the placeholder `ssh_public_key` value was never actually replaced with the real key; fixed by pasting the real `varnisha-deploy.pub` contents in.
6. `terraform apply` succeeded → `elastic_ip = 13.234.5.160`, bucket names as above.
7. GoDaddy DNS: adding A records initially failed ("Invalid data provided for record data") because a default `www` CNAME record already existed for that name — GoDaddy won't let you convert a CNAME to an A record in place, it has to be deleted first, then a fresh A record added. Also hit the same issue on `api`/`laxmi` from stale record state; a hard refresh / re-adding via "Add New Record" (not "Edit") resolved it. Also had to make the infra repo public since the EC2 box had no GitHub credentials for a plain `https://` clone of a private repo.
8. GitHub Actions secrets (`EC2_HOST`, `EC2_SSH_USER`, `EC2_SSH_PRIVATE_KEY`, `NEXT_PUBLIC_API_URL`) added to all 3 app repos.
9. One-time box setup: cloned the infra repo, copied Nginx configs + `ecosystem.config.js` into place, symlinked sites-enabled, created MongoDB users (`mongoAdmin`, `varnishaApp`) via `mongosh`, enabled `security.authorization` in `mongod.conf` and restarted, populated the backend's production `.env`.
10. First deploy attempt failed at "Set up SSH key" step's neighbors, actually two separate issues:
    - **Backend**: `npm ci` failed — `package-lock.json` had drifted (missing transitive deps like `gcp-metadata`, `gaxios` pulled in via `firebase-admin`). Fixed with a clean `rm -rf node_modules package-lock.json && npm install`, verified `npm ci` passes, committed.
    - **Frontends**: `next build` (Turbopack, Next 16's default) failed trying to fetch Google Fonts (`fonts.gstatic.com` 404s) for `Playfair_Display`. The `dev` script already used `--webpack` to avoid Turbopack (presumably for this exact class of issue) but `build` didn't — added `--webpack` to `build` too in both frontend repos, verified locally with a real build before pushing.
    - Also bumped CI's `actions/setup-node` version from 20 → 26 to match the local machine (whose npm actually produced a working lock file — npm's dependency resolution isn't perfectly stable across major versions), and updated `bootstrap.sh` to install Node 26 on the box too (the backend's `npm ci --omit=dev` runs on-box, so box and CI need matching Node/npm).
    - Switched `pm2 reload` → `pm2 startOrReload` in all 3 workflows: `reload` only works on an already-running PM2 process, which none of these were yet on a first-ever deploy — would have failed the deploy step even after a successful build.
11. Certbot (`sudo certbot --nginx -d ...`) succeeded once DNS was actually resolving correctly — confirmed via `curl -I https://...` returning real Nginx TLS responses (302→ redirect, later a 502 while apps weren't started, expected before step 10's fixes landed).
12. Later tried to add a cert for the bare apex `varnisha.com` (no `www`) — failed with "Could not automatically find a matching server block ... Set the `server_name` directive to use the Nginx installer." Root cause: the original Nginx setup only ever created server blocks for the 3 subdomains (`api`/`www`/`laxmi`); nothing declared `server_name varnisha.com`, so Certbot's Nginx installer had nowhere to attach. Fixed by adding `infra/nginx/varnisha.com.conf` (plain HTTP 301 redirect to `https://www.varnisha.com`) and a GoDaddy `@` A record, enabling the site, then re-running Certbot with `-d varnisha.com` added to the existing 3-domain command.
13. Flipped the canonical host: `varnisha.com` (bare apex) now proxies straight to the storefront app on :3000, and `www.varnisha.com` 301s to it instead — the reverse of step 12's original direction. Changed `infra/nginx/varnisha.com.conf` and `infra/nginx/www.varnisha.com.conf` (swapped which one proxies vs. redirects), `varnisha-e-commarce-backend/.env.example` and `DEPLOY.md`'s `CLIENT_URL` guidance (`https://www.varnisha.com` → `https://varnisha.com`). Backend CORS allowlist (`server.js`) already listed both hosts, so no code change needed there. **Not yet applied to the live box** — since both hostnames were already covered by the existing Certbot cert (issued with both `-d` flags in step 12), no new cert is needed, just: `git pull` the infra repo on the box, `sudo cp infra/nginx/*.conf /etc/nginx/sites-available/`, `sudo nginx -t && sudo systemctl reload nginx`, and update `CLIENT_URL` in the backend's on-box `.env` + restart it via PM2.

## Known gaps / follow-ups

- **Categories, collections, and CMS (blog/look/social) admin pages are static mockups** — hardcoded demo data, not wired to the real backend API at all. Product uploads work; these don't yet have a real create/edit flow to hook an uploader into.
- **`mongodump` → S3 backup cron** not yet implemented (DEPLOY.md step 9) — still to do.
- **Root `.tfstate` is local-only** (not remote/S3 backend) — fine for a solo operator, but means Terraform state only exists on this machine. Back it up.
- Credentials pasted into the chat session during setup (AWS root password, an AWS access key pair) should be rotated if not already done.

## Quick reference

| Thing | Value |
|---|---|
| Elastic IP | `13.234.5.160` |
| Region | `ap-south-1` |
| Uploads bucket | `varnisha-jewels-uploads-prod` |
| Backups bucket | `varnisha-jewels-db-backups-prod` |
| SSH user | `ubuntu` |
| App directories on box | `/home/ubuntu/apps/varnisha-e-commarce-{backend,user,admin}` |
| PM2 app names | `varnisha-backend`, `varnisha-user`, `varnisha-admin` |
| MongoDB app db/user | `ecommercestore` / `varnishaApp` |
