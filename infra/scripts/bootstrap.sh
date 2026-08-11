#!/usr/bin/env bash
# EC2 first-boot provisioning (runs once via cloud-init/user_data on Ubuntu 22.04).
# OS-level packages only — app code, Nginx site configs, ecosystem.config.js,
# and .env are put in place during the one-time manual setup after apply
# (see the infra repo README for the exact commands).
#
# Re-runnable manually over SSH if the box needs re-provisioning without a
# full Terraform replace (idempotent where practical).
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y

# ── Swap (t3.medium has only 4GB RAM; MongoDB + 3 Node processes is tight) ──
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# ── Node.js 20.x LTS + PM2 ──────────────────────────────────────────────────
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g pm2
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 14
pm2 set pm2-logrotate:compress true

# ── Nginx ────────────────────────────────────────────────────────────────
apt-get install -y nginx
systemctl enable nginx

# ── Certbot ──────────────────────────────────────────────────────────────
apt-get install -y certbot python3-certbot-nginx

# ── MongoDB 7.0 (official repo, Ubuntu 22.04/jammy) ─────────────────────────
apt-get install -y gnupg curl
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
  gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -y
apt-get install -y mongodb-org
systemctl enable mongod
systemctl start mongod

# Cap WiredTiger cache so Mongo doesn't starve the Node processes.
# authorization is intentionally left disabled here — enabling it requires
# creating the admin/app users first, which happens in the one-time manual
# setup after this box exists.
if ! grep -q "wiredTigerCacheSizeGB" /etc/mongod.conf; then
  sed -i '/^storage:/a\  wiredTiger:\n    engineConfig:\n      cacheSizeGB: 1' /etc/mongod.conf
  systemctl restart mongod
fi

# ── SSH hardening: key-only auth (security group has 22 open to 0.0.0.0/0
# since GitHub Actions runners have no fixed IP range to allowlist) ─────────
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd

# ── App directories, one per repo, populated by each repo's own CI deploy ──
mkdir -p /home/ubuntu/apps/varnisha-e-commarce-backend
mkdir -p /home/ubuntu/apps/varnisha-e-commarce-user
mkdir -p /home/ubuntu/apps/varnisha-e-commarce-admin
chown -R ubuntu:ubuntu /home/ubuntu/apps

# PM2 process supervision survives reboot (actual `pm2 start` happens on
# first deploy, once app code + ecosystem.config.js are in place).
env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
