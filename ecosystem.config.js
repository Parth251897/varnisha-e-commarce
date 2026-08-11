// PM2 process definitions for all 3 apps on the EC2 box.
// Copied to /home/ubuntu/apps/ecosystem.config.js during the one-time
// manual setup (see README). Each app is deployed independently by its
// own repo's GitHub Actions workflow into the cwd paths below.
module.exports = {
  apps: [
    {
      name: "varnisha-backend",
      cwd: "/home/ubuntu/apps/varnisha-e-commarce-backend",
      script: "server.js",
      env_production: { NODE_ENV: "production", PORT: 3045 },
      max_memory_restart: "500M",
      autorestart: true,
      max_restarts: 10,
      restart_delay: 5000,
    },
    {
      name: "varnisha-user",
      cwd: "/home/ubuntu/apps/varnisha-e-commarce-user",
      script: "node_modules/.bin/next",
      args: "start",
      env_production: { NODE_ENV: "production", PORT: 3000 },
      max_memory_restart: "400M",
      autorestart: true,
      max_restarts: 10,
      restart_delay: 5000,
    },
    {
      name: "varnisha-admin",
      cwd: "/home/ubuntu/apps/varnisha-e-commarce-admin",
      script: "node_modules/.bin/next",
      args: "start -p 3001",
      env_production: { NODE_ENV: "production" },
      max_memory_restart: "400M",
      autorestart: true,
      max_restarts: 10,
      restart_delay: 5000,
    },
  ],
};
