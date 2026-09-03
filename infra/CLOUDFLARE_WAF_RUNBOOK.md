# Cloudflare Domain Setup, WAF, AI SEO & Production Hardening Guide

This comprehensive guide details the exact steps to connect your domain to **Cloudflare**, configure **AI Training & Search Policies for maximum visibility in ChatGPT, Google Gemini, and Perplexity**, and harden the platform against cyberattacks.

---

## 1. Domain Onboarding: "Additional Configuration" Setup Guide

When adding your domain to Cloudflare, you are presented with the **"Additional configuration"** screen:

![Cloudflare AI Configuration](file:///C:/Users/parth/.gemini/antigravity-ide/brain/aa76aad0-0ead-4fa0-8621-94ac856bd3e5/.tempmediaStorage/media_1788415052641.png)

Here are the exact options you should select to ensure your artificial jewellery products and brand appear in **Google Gemini, ChatGPT, Perplexity, and Apple Intelligence**:

| Configuration Field | Recommended Selection | Why It Matters for AI SEO & Discovery |
| :--- | :--- | :--- |
| **Search** | **`Allow (do not block)`** *(Recommended)* | Allows search engine crawlers (Googlebot, Bingbot, SearchGPT, PerplexityBot) to index your products so customers can find your store via web searches. |
| **Agent** | **`Allow (do not block)`** *(Recommended)* | **CRITICAL FOR AI SEO**: Allows conversational AI agents (ChatGPT browsing, Google Gemini real-time query, Perplexity, Apple Intelligence) to pull live details from your store when users ask questions like *"Where can I buy handcrafted Kundan chokers in India?"*. |
| **Training** | **`Allow (do not block)`** | **FOR MAXIMUM AI BRAND AWARENESS**: Allows AI companies (OpenAI, Google, Anthropic) to learn about Varnisha Jewels, your product catalog, anti-tarnish guarantees, and craftsmanship during model training. This ensures future LLMs know about your brand organically. |
| **Block training in robots.txt** | **`Toggle OFF (Disabled)`** | Keep this toggle **DISABLED**. Enabling it will insert disallow directives in Cloudflare that prevent AI models from discovering your products. |
| **Import DNS records** | **`Import DNS records automatically`** *(Recommended)* | Cloudflare will automatically query existing DNS records from your current domain registrar and populate them with zero downtime. |

---

## 2. Generative Engine Optimization (GEO) & AI SEO Architecture

To rank in AI answer engines (ChatGPT, Google Gemini, Perplexity, Microsoft Copilot, Apple Intelligence), traditional keyword-stuffing is obsolete. AI models read semantic entities, structured facts, and verified trust signals.

### How Varnisha Jewels is Built for AI Search:
1. **Dynamic `robots.txt` ([`app/robots.js`](file:///d:/PARTH%20PROJECTS/E-commarce/E-commarce/varnisha-e-commarce/varnisha-e-commarce-user/app/robots.js))**:
   Explicitly permits the major AI retrieval bots:
   - `GPTBot` & `OAI-SearchBot` (OpenAI / ChatGPT Search)
   - `Google-Extended` (Google Gemini & Vertex AI)
   - `PerplexityBot` (Perplexity AI Search)
   - `ClaudeBot` & `Claude-Web` (Anthropic Claude)
   - `Applebot-Extended` (Apple Intelligence Siri & Spotlight)
2. **Schema.org Structured Data ([`app/layout.js`](file:///d:/PARTH%20PROJECTS/E-commarce/E-commarce/varnisha-e-commarce/varnisha-e-commarce-user/app/layout.js))**:
   - Implements JSON-LD for `JewelryStore` and `OfferCatalog`.
   - AI models parse these machine-readable tags to know your exact categories: *Bridal Kundan Chokers*, *18K Micron Gold Bangles*, *AAA+ CZ Rings*, and *Anti-Tarnish Jewellery*.
3. **Product Specifications & Statutory Data**:
   - Product pages include clear Base Metal, Plating type, Stone grade, HSN 7117 (3% GST Included), and 1-Year Polish & Anti-Tarnish warranty specifications. When an AI crawler inspects the page, it has high-confidence facts to cite in its answer.

---

## 3. DNS Records & Proxy Routing (Orange-Clouded)

In Cloudflare Dashboard -> **DNS -> Records**, ensure the following records point to your AWS Elastic IP:

| Type | Name | Target / IP | Proxy Status | TTL | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A** | `varnisha.com` | `[AWS Elastic IP]` | **Proxied (Orange Cloud)** | Auto | Main Customer Storefront |
| **CNAME** | `www` | `varnisha.com` | **Proxied (Orange Cloud)** | Auto | WWW Redirect |
| **A** | `api` | `[AWS Elastic IP]` | **Proxied (Orange Cloud)** | Auto | Backend API Server |
| **A** | `laxmi` | `[AWS Elastic IP]` | **Proxied (Orange Cloud)** | Auto | Admin Management Dashboard |

> [!IMPORTANT]
> Keep the **Orange Cloud (Proxied)** enabled on all web records. This shields your AWS origin server IP from hackers, port scanners, and volumetric DDoS attacks.

---

## 4. Nameserver Delegation & Final Verification Steps

When you reach the **Nameserver Directions** screen (`varnisha.com/nameserver-directions`):

### Step A: Make Sure DNSSEC is Turned OFF at your Registrar
- **What it is**: DNS Security Extensions (DNSSEC) adds a cryptographic signature to DNS records at your current registrar.
- **Action**: Log into your domain registrar (GoDaddy, Namecheap, Hostinger, etc.) -> **DNS Management** -> find **DNSSEC**.
- **Rule**: If it is **ON**, turn it **OFF**.
- *Why*: If old DNSSEC keys remain active while switching nameservers, DNS resolvers will treat Cloudflare's new nameservers as forged and visitors will get `DNS_PROBE_FINISHED_NXDOMAIN`. Once Cloudflare is active, you can re-enable DNSSEC directly inside Cloudflare with one click. If DNSSEC is already OFF or your registrar doesn't have it enabled, you can safely proceed.

### Step B: Delegate Nameservers at your Domain Registrar
1. Note the two Cloudflare nameservers shown on your screen (e.g. `eva.ns.cloudflare.com`, `seth.ns.cloudflare.com`).
2. Log into your domain registrar account.
3. Go to **DNS / Nameserver settings** for `varnisha.com`.
4. Switch nameserver mode from **Default** to **Custom Nameservers**.
5. Replace existing nameservers with the 2 Cloudflare nameservers.
6. Save changes.

### Step C: Click the Blue Button
- Click the blue button: **"I updated my nameservers"**.
- Cloudflare will begin querying the global root DNS servers. Verification typically completes within 5 to 15 minutes.

---

## 5. Origin Server Firewall Hardening: Allow ONLY Cloudflare IPs

Cloudflare warns: *"All traffic passes through Cloudflare before reaching your origin server... To prevent attackers from bypassing Cloudflare, block all traffic that does not come from Cloudflare IP addresses."*

### Threat Model Context (Threat Model Categories 5, 8 & 9):
If a malicious actor discovers your AWS EC2 Elastic IP address, they could launch DDoS floods or vulnerability scans directly against your server IP, bypassing Cloudflare WAF, Bot Fight Mode, and rate limiting entirely.

### Automated Solution:
We have provided an automated script [`infra/scripts/setup_cloudflare_firewall.sh`](file:///d:/PARTH%20PROJECTS/E-commarce/E-commarce/varnisha-e-commarce/infra/scripts/setup_cloudflare_firewall.sh) on your server.

To run it on your Ubuntu EC2 instance:
```bash
chmod +x infra/scripts/setup_cloudflare_firewall.sh
sudo ./infra/scripts/setup_cloudflare_firewall.sh
```

**What this script does**:
1. **Keeps SSH (Port 22) accessible** for your key-based admin logins and GitHub Actions deployments.
2. **Allows ports 80 (HTTP) and 443 (HTTPS) ONLY from official Cloudflare IPv4 & IPv6 CIDRs** (`173.245.48.0/20`, `104.16.0.0/13`, `172.64.0.0/13`, `2400:cb00::/32`, etc.).
3. **Drops all direct external traffic** from non-Cloudflare IPs to ports 80, 443, 3045, 3000, 3001, and 27017.
4. If an attacker attempts to browse `https://<YOUR_AWS_ELASTIC_IP>`, their connection is instantly dropped by the kernel. All users must access via `https://varnisha.com` protected by Cloudflare!

---

## 6. AWS VPC Routing Verification (Cloudflare `172.64.0.0/13` Check)

Cloudflare uses the public IP range `172.64.0.0/13` for its edge proxies.
In AWS:
- Standard private RFC 1918 space is `172.16.0.0/12` (`172.16.0.0` to `172.31.255.255`).
- AWS Default VPCs use CIDR `172.31.0.0/16` with a default route `0.0.0.0/0 -> igw-xxxx` (Internet Gateway).
- Since `172.31.0.0/16` does NOT overlap with `172.64.0.0/13`, standard AWS VPC routing works out of the box.
- **Rule of Thumb**: Check your AWS VPC Route Table in the AWS Console (`VPC -> Route Tables`). Ensure there is no over-broad custom route like `172.0.0.0/8` pointing to a NAT or Peering gateway. If you see only the default `172.31.0.0/16 -> local` and `0.0.0.0/0 -> igw-xxxx`, routing is 100% clean and no changes are required.

---

## 5. SSL/TLS Encryption Mode

Navigate to **SSL/TLS -> Overview**:
- **Encryption Mode**: Select **Full (Strict)**.
  - *Why*: Origin Nginx is configured with Let's Encrypt certificates (`api.varnisha.com/fullchain.pem`). "Full (Strict)" ensures end-to-end encryption from customer browser -> Cloudflare Edge -> Origin EC2, preventing Man-in-the-Middle (MitM) attacks.
- Navigate to **SSL/TLS -> Edge Certificates**:
  - **Always Use HTTPS**: **Enabled** (redirects all HTTP traffic to HTTPS).
  - **Minimum TLS Version**: **TLS 1.2** (disables vulnerable TLS 1.0/1.1 protocols).
  - **Opportunistic Encryption**: **Enabled**.
  - **TLS 1.3**: **Enabled** (speeds up handshakes and modernizes cryptography).
  - **Automatic HTTPS Rewrites**: **Enabled** (resolves mixed content warnings).

---

## 6. Security Level & Bot Defense

Navigate to **Security -> Settings**:
- **Security Level**: Set to **Medium** for normal operations.
- **Under Attack Mode**: Ready to toggle to **I'm Under Attack!** in the event of an active volumetric Layer 7 DDoS attack. This forces JavaScript challenges before requests reach the origin.
- **Challenge Passage**: **30 minutes**.
- **Browser Integrity Check**: **Enabled** (inspects HTTP headers for known malicious bot and scraper signatures).

Navigate to **Security -> Bots**:
- **Bot Fight Mode**: **Enabled** (detects and mitigates malicious automated scrapers without blocking verified AI search bots like GPTBot or Google-Extended).

---

## 7. Custom WAF Rate-Limiting Rules (Free Tier)

Navigate to **Security -> WAF -> Custom Rules**:

### Rule 1: Protect Authentication Endpoints against Brute-Force & Credential Stuffing
- **Rule Name**: `Protect Auth Endpoints`
- **Expression**:
  ```
  (http.request.uri.path contains "/api/v1/auth/login") or 
  (http.request.uri.path contains "/api/v1/auth/register") or 
  (http.request.uri.path contains "/api/v1/auth/forgot-password")
  ```
- **Action**: **Managed Challenge** if IP exceeds 10 requests per minute.

### Rule 2: Block Malicious User-Agents & Vulnerability Scanners
- **Rule Name**: `Block Automated Attack Scanners`
- **Expression**:
  ```
  (http.user_agent contains "sqlmap") or 
  (http.user_agent contains "nikto") or 
  (http.user_agent contains "gobuster") or 
  (http.user_agent contains "dirbuster") or
  (http.user_agent contains "wpscan")
  ```
- **Action**: **Block**.

---

## 8. Caching & Edge Optimization

Navigate to **Caching -> Configuration**:
- **Caching Level**: **Standard**.
- **Browser Cache TTL**: **Respect Existing Headers** (allows Next.js static asset hashes to control client caching).

Navigate to **Speed -> Optimization**:
- **Auto Minify**: Check **JavaScript**, **CSS**, and **HTML** for accelerated edge delivery.
- **Brotli**: **Enabled** (higher compression ratio than standard gzip).
- **Early Hints**: **Enabled** (accelerates stylesheet and font preloading).

---

## 9. Origin Nginx Real IP Restoration

Because traffic routes through Cloudflare, origin Nginx must restore the genuine visitor IP:
1. Copy the configuration file:
   ```bash
   sudo cp infra/nginx/cloudflare.conf /etc/nginx/conf.d/cloudflare.conf
   ```
2. Test Nginx syntax:
   ```bash
   sudo nginx -t
   ```
3. Reload Nginx:
   ```bash
   sudo systemctl reload nginx
   ```
4. Now, `req.ip` in Express.js correctly reflects the end-user IP address rather than Cloudflare edge servers.

---

## 10. AWS IMDSv2 Lockdown Command

To guarantee that SSRF vulnerabilities can never query EC2 instance metadata credentials:
```bash
aws ec2 modify-instance-metadata-options \
    --instance-id <YOUR_EC2_INSTANCE_ID> \
    --http-tokens required \
    --http-endpoint enabled
```
**Verification**:
```bash
# Direct unauthenticated request MUST return HTTP 401 Unauthorized
curl -i http://169.254.169.254/latest/meta-data/
```
