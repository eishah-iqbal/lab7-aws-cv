
#!/bin/bash

BUCKET="cv-23l-2587-582129522828-ap-southeast-2-an"
PREFIX="site"
WEBROOT="/var/www/html"
LOG="/var/log/cv-sync.log"

TOKEN=$(curl -fsS -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") || TOKEN=""

INSTANCE_ID=$(curl -fsS \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/instance-id") || INSTANCE_ID="unknown"

if [ -z "$TOKEN" ] || [ "$INSTANCE_ID" = "unknown" ]; then
    echo "$(date -Is) status=FAILED reason=metadata" >> "$LOG"
    exit 1
fi

if aws s3 sync "s3://${BUCKET}/${PREFIX}/" "$WEBROOT/" \
     --delete --only-show-errors &&
   [ -f "$WEBROOT/index.html" ]; then

    sed -i "s|{{HOSTED_ON}}|EC2 - ${INSTANCE_ID}|g" \
      "$WEBROOT/index.html"

    echo "$(date -Is) status=SUCCESS instance=${INSTANCE_ID}" >> "$LOG"
else
    echo "$(date -Is) status=FAILED instance=${INSTANCE_ID}" >> "$LOG"
    exit 1
fi
