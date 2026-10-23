
#!/bin/bash
set -e

dnf install -y httpd awscli curl
systemctl enable --now httpd

curl -fsSL \
  "https://raw.githubusercontent.com/eishah-iqbal/lab7-aws-cv/main/ec2/sync-cv.sh" \
  -o /usr/local/bin/sync-cv.sh

chmod 755 /usr/local/bin/sync-cv.sh

cat > /etc/systemd/system/cv-sync.service <<'UNIT'
[Unit]
Description=Sync CV files from S3
After=network-online.target httpd.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sync-cv.sh
UNIT

cat > /etc/systemd/system/cv-sync.timer <<'UNIT'
[Unit]
Description=Run CV sync every five minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
UNIT

systemctl daemon-reload
systemctl start cv-sync.service
systemctl enable --now cv-sync.timer
