#!/usr/bin/env bash
# ==============================================================================
# Cloudflare Origin Firewall Lock Down Script
# Varnisha Jewels E-Commerce Platform
# ==============================================================================
# This script configures UFW (Uncomplicated Firewall) on the Ubuntu EC2 origin
# to ONLY accept HTTP (80) and HTTPS (443) traffic originating from official
# Cloudflare IP address ranges.
#
# Direct access to your origin server IP on ports 80/443 is BLOCKED, preventing
# attackers from bypassing Cloudflare WAF, DDoS protection, and rate limiting.
# SSH (Port 22) remains open for your key-based admin access and CI/CD deploy.
# ==============================================================================
set -euo pipefail

echo "======================================================================"
echo " Configuring Origin Firewall: Allow Only Cloudflare IPs"
echo "======================================================================"

# 1. Official Cloudflare IPv4 CIDR ranges
CF_IPV4=(
  "173.245.48.0/20"
  "103.21.244.0/22"
  "103.22.200.0/22"
  "103.31.4.0/22"
  "141.101.64.0/18"
  "108.162.192.0/18"
  "190.93.240.0/20"
  "188.114.96.0/20"
  "197.234.240.0/22"
  "198.41.128.0/17"
  "162.158.0.0/15"
  "104.16.0.0/13"
  "104.24.0.0/14"
  "172.64.0.0/13"
  "131.0.72.0/22"
)

# 2. Official Cloudflare IPv6 CIDR ranges
CF_IPV6=(
  "2400:cb00::/32"
  "2606:4700::/32"
  "2803:f800::/32"
  "2405:b500::/32"
  "2405:8100::/32"
  "2a06:98c0::/29"
  "2c0f:f248::/32"
)

if ! command -v ufw > /dev/null 2>&1; then
  echo "Installing ufw..."
  sudo apt-get update && sudo apt-get install -y ufw
fi

echo "Resetting existing UFW rules (preserving SSH)..."
sudo ufw --force reset

# Default policies: Deny incoming, Allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# CRITICAL: Always keep SSH open first so you don't get locked out
sudo ufw allow 22/tcp comment 'SSH Key-Auth Access'

# Allow HTTP (80) and HTTPS (443) ONLY from Cloudflare IPv4 blocks
echo "Adding Cloudflare IPv4 rules for ports 80 & 443..."
for ip in "${CF_IPV4[@]}"; do
  sudo ufw allow proto tcp from "$ip" to any port 80 comment 'Cloudflare IPv4 HTTP'
  sudo ufw allow proto tcp from "$ip" to any port 443 comment 'Cloudflare IPv4 HTTPS'
done

# Allow HTTP (80) and HTTPS (443) from Cloudflare IPv6 blocks
echo "Adding Cloudflare IPv6 rules for ports 80 & 443..."
for ip in "${CF_IPV6[@]}"; do
  sudo ufw allow proto tcp from "$ip" to any port 80 comment 'Cloudflare IPv6 HTTP'
  sudo ufw allow proto tcp from "$ip" to any port 443 comment 'Cloudflare IPv6 HTTPS'
done

# Explicitly drop external access to internal backend and database ports
sudo ufw deny 27017/tcp comment 'Block MongoDB External'
sudo ufw deny 3045/tcp comment 'Block Node Backend Direct'
sudo ufw deny 3000/tcp comment 'Block Storefront Next.js Direct'
sudo ufw deny 3001/tcp comment 'Block Admin Next.js Direct'

# Enable firewall
sudo ufw --force enable
sudo ufw status verbose

echo "======================================================================"
echo "✔ Origin firewall locked down successfully!"
echo "  - Direct HTTP/HTTPS to your origin server IP is now BLOCKED."
echo "  - All web requests MUST pass through Cloudflare WAF."
echo "  - SSH port 22 remains accessible for your administration."
echo "======================================================================"
