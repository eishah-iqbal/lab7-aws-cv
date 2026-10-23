#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <bucket-name> <ec2-address> <lambda-address>"
    exit 1
fi

BUCKET="$1"
EC2_ADDR="${2#http://}"
EC2_ADDR="${EC2_ADDR#https://}"
EC2_ADDR="${EC2_ADDR%/}"
LAMBDA_URL="${3%/}"
REGION="ap-southeast-2"
EC2_ROLE="cv-ec2-role-23l-2587"
LAMBDA_ROLE="cv-lambda-role-23l-2587"
LAMBDA_FN="cv-func-23l-2587"
LOG_GROUP="/aws/lambda/${LAMBDA_FN}"
OUT="evidence.txt"

: > "$OUT"

section() {
    printf '== %s ==\n' "$1" >> "$OUT"
}

run_cmd() {
    "$@" >> "$OUT" 2>&1
    RC=$?
    if [ "$RC" -ne 0 ]; then
        echo "COMMAND FAILED (exit $RC): $*" >> "$OUT"
    fi
}

section caller
run_cmd aws sts get-caller-identity --region "$REGION"
echo >> "$OUT"

section public-access
run_cmd aws s3api get-public-access-block \
    --bucket "$BUCKET" --region "$REGION"
echo >> "$OUT"

section versioning
run_cmd aws s3api get-bucket-versioning \
    --bucket "$BUCKET" --region "$REGION"
echo >> "$OUT"

section objects
run_cmd aws s3 ls "s3://${BUCKET}/site/" \
    --recursive --region "$REGION"
echo >> "$OUT"

section ec2-policy
run_cmd aws iam get-role-policy \
    --role-name "$EC2_ROLE" \
    --policy-name cv-ec2-s3-read-policy \
    --region "$REGION"
echo >> "$OUT"

section lambda-policy
run_cmd aws iam list-attached-role-policies \
    --role-name "$LAMBDA_ROLE" --region "$REGION"
run_cmd aws iam get-role-policy \
    --role-name "$LAMBDA_ROLE" \
    --policy-name cv-lambda-s3-read-policy \
    --region "$REGION"
echo >> "$OUT"

INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=ip-address,Values=${EC2_ADDR}" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text --region "$REGION" 2>/dev/null)

SG_ID=$(aws ec2 describe-instances \
    --filters "Name=ip-address,Values=${EC2_ADDR}" \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text --region "$REGION" 2>/dev/null)

section security-group
if [ -n "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    run_cmd aws ec2 describe-security-groups \
        --group-ids "$SG_ID" \
        --query 'SecurityGroups[].IpPermissions' \
        --region "$REGION"
else
    echo "Could not find the security group for $EC2_ADDR" >> "$OUT"
fi
echo >> "$OUT"

section instance
if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
    run_cmd aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[].Instances[].{InstanceId:InstanceId,InstanceType:InstanceType,MetadataOptions:MetadataOptions,IamInstanceProfile:IamInstanceProfile,PublicIp:PublicIpAddress,Tags:Tags}' \
        --region "$REGION"
else
    echo "Could not find instance for $EC2_ADDR" >> "$OUT"
fi
echo >> "$OUT"

probe() {
    LABEL="$1"
    URL="$2"
    echo "$LABEL: $URL" >> "$OUT"
    curl -sS -o /dev/null \
        -w 'HTTP %{http_code} Content-Type %{content_type}\n' \
        "$URL" >> "$OUT" 2>&1 || echo "CURL FAILED" >> "$OUT"
}

section endpoints
probe EC2 "http://${EC2_ADDR}/"
probe EC2-CSS "http://${EC2_ADDR}/style.css"
probe EC2-PDF "http://${EC2_ADDR}/cv.pdf"
probe Lambda "${LAMBDA_URL}/"
probe Lambda-CSS "${LAMBDA_URL}/style.css"
probe Lambda-PDF "${LAMBDA_URL}/cv.pdf"
probe Direct-S3 "https://${BUCKET}.s3.${REGION}.amazonaws.com/site/index.html"
probe Lambda-404 "${LAMBDA_URL}/anything"
echo >> "$OUT"

section lambda-logs
run_cmd aws logs tail "$LOG_GROUP" \
    --since 1h --region "$REGION"
echo >> "$OUT"

section log-retention
run_cmd aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" \
    --query 'logGroups[].{Name:logGroupName,RetentionDays:retentionInDays}' \
    --region "$REGION"
echo >> "$OUT"

echo "DONE"