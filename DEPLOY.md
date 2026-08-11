# Deployment runbook

Everything Claude built (Terraform, Nginx configs, `ecosystem.config.js`,
bootstrap script, GitHub Actions workflows) is already committed and pushed.
This is the list of steps that need to be run by you, in order, since they
require credentials/logins Claude never has access to.

## 1. Install tooling locally

```powershell
winget install -e --id Amazon.AWSCLI
winget install -e --id Hashicorp.Terraform
```

Then configure AWS CLI with your **own IAM user's** access key (not root):

```powershell
aws configure
```

## 2. Generate the shared deploy SSH keypair

```bash
ssh-keygen -t ed25519 -f ~/.ssh/varnisha-deploy -C "varnisha-deploy"
```

This one keypair is used for (a) your own SSH access to the box, and (b) the
GitHub Actions deploy secret in all 3 app repos. Keep `varnisha-deploy`
(private) safe; you'll paste its contents into GitHub secrets in step 5.

## 3. Terraform apply

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: paste the contents of ~/.ssh/varnisha-deploy.pub
# into ssh_public_key, and pick globally-unique bucket names.

terraform init
terraform plan    # review before applying — this creates billable resources
terraform apply
```

Note the `elastic_ip`, `uploads_bucket_name`, and `backups_bucket_name`
outputs — you'll need all three below.

## 4. Point DNS at the box (GoDaddy)

In GoDaddy's DNS management for `varnisha.com`, add 3 **A records**:

| Host    | Points to (elastic_ip output) | TTL |
|---------|-------------------------------|-----|
| `api`   | `<elastic_ip>`                | 600 |
| `www`   | `<elastic_ip>`                | 600 |
| `laxmi` | `<elastic_ip>`                | 600 |

Confirm propagation before continuing: `dig api.varnisha.com` (or `nslookup`
on Windows) should return the Elastic IP.

## 5. Add GitHub Actions secrets (all 3 app repos)

For each of `varnisha-e-commarce-backend`, `varnisha-e-commarce-user`,
`varnisha-e-commarce-admin` → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `EC2_HOST` | the `elastic_ip` output |
| `EC2_SSH_USER` | `ubuntu` |
| `EC2_SSH_PRIVATE_KEY` | contents of `~/.ssh/varnisha-deploy` (the private key) |
| `NEXT_PUBLIC_API_URL` | `https://api.varnisha.com/api/v1` (user + admin repos only) |

## 6. One-time manual setup on the box

```bash
ssh -i ~/.ssh/varnisha-deploy ubuntu@<elastic_ip>
```

Once connected:

```bash
# Clone the infra repo for the Nginx configs + ecosystem.config.js
git clone https://github.com/Parth251897/varnisha-e-commarce.git ~/infra
cp ~/infra/ecosystem.config.js ~/apps/ecosystem.config.js

# Nginx site configs
sudo cp ~/infra/infra/nginx/*.conf /etc/nginx/sites-available/
for f in api.varnisha.com www.varnisha.com laxmi.varnisha.com; do
  sudo ln -sf /etc/nginx/sites-available/$f.conf /etc/nginx/sites-enabled/
done
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# MongoDB: create an admin user and the app-scoped user, then enable auth
mongosh
```
Inside `mongosh`:
```js
use admin
db.createUser({ user: "mongoAdmin", pwd: passwordPrompt(), roles: ["userAdminAnyDatabase", "readWriteAnyDatabase"] })
use ecommercestore
db.createUser({ user: "varnishaApp", pwd: passwordPrompt(), roles: ["readWrite"] })
exit
```
Then enable auth and restart:
```bash
sudo sed -i '/^#security:/c\security:\n  authorization: enabled' /etc/mongod.conf
sudo systemctl restart mongod
```

Populate the backend's production `.env` (values only you have — never paste
these into chat with Claude):
```bash
nano ~/apps/varnisha-e-commarce-backend/.env
```
Set at minimum: `NODE_ENV=production`, `PORT=3045`,
`MONGO_URI=mongodb://varnishaApp:<password>@127.0.0.1:27017/ecommercestore`,
`JWT_SECRET=<generate with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">`,
`CLIENT_URL=https://www.varnisha.com`, `ADMIN_URL=https://laxmi.varnisha.com`,
`AWS_REGION=ap-south-1`, `S3_BUCKET_NAME=<uploads_bucket_name output>`, plus
Razorpay/Twilio/Firebase/Gemini/Email keys from your existing `.env`.

## 7. First deploy

Push any trivial commit to each of the 3 app repos' `main` branch (or just
re-push what's already there) to trigger the first GitHub Actions run, which
populates `~/apps/<repo>/` on the box and starts the PM2 processes.

Verify:
```bash
pm2 list          # all 3 apps should show "online"
curl http://127.0.0.1:3045
```

## 8. Enable HTTPS

Once DNS resolves and the apps are running over plain HTTP via Nginx:
```bash
sudo certbot --nginx -d api.varnisha.com -d www.varnisha.com -d laxmi.varnisha.com
```
Certbot rewrites the 3 Nginx configs to add TLS + auto-renewal.

## 9. Set up the mongodump → S3 backup cron

Add a daily cron job on the box (or extend `varnisha-e-commarce-backend/cron/cronJobs.js`)
that runs `mongodump` and uploads the archive to the `backups_bucket_name`
bucket via the AWS CLI or SDK — the EC2 instance role already has
`s3:PutObject` on that bucket, no credentials needed.

## Verification checklist

- [ ] `https://api.varnisha.com/` returns `{"success":true,"message":"Varnisha Jewels Security Core API is active",...}`
- [ ] `https://www.varnisha.com` and `https://laxmi.varnisha.com` load over valid HTTPS
- [ ] Pushing to one app repo only redeploys that app (`pm2 logs <app>` shows the restart)
- [ ] An image uploaded via the admin Products page returns a working `https://<bucket>.s3.ap-south-1.amazonaws.com/...` URL
- [ ] A manually-triggered `mongodump` lands in the private backup bucket
