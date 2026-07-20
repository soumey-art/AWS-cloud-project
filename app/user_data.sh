#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# 1. Update system and install Node.js + Git
sudo yum update -y
sudo yum install -y git
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 2. Clone the repository
cd /home/ec2-user
git clone https://github.com/soumey-art/AWS-cloud-project.git
cd AWS-cloud-project/app

# 3. Install dependencies
npm install

# 4. Initialize Database Table (if not already created)
npm run db:init # or node db/init.js

# 5. Start app automatically using pm2
sudo npm install -y pm2 -g
pm2 start server.js --name "cloud-app"
pm2 startup
pm2 save
