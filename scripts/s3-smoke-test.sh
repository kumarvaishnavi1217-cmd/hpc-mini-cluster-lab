#!/usr/bin/env bash
# RADOS Gateway S3 smoke test using the AWS CLI. Run from any compute/login node.
set -euo pipefail
: "${AWS_ACCESS_KEY_ID:?export AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY:?export AWS_SECRET_ACCESS_KEY}"
EP="${RGW_ENDPOINT:-http://ceph01:7480}"
B="smoke-$(date +%s)"
aws --endpoint-url "$EP" s3 mb "s3://$B"
head -c 10M /dev/urandom > /tmp/s3obj
aws --endpoint-url "$EP" s3 cp /tmp/s3obj "s3://$B/obj"
aws --endpoint-url "$EP" s3 cp "s3://$B/obj" /tmp/s3obj.back
cmp /tmp/s3obj /tmp/s3obj.back && echo "PASS: S3 round-trip OK"
aws --endpoint-url "$EP" s3 rb "s3://$B" --force
rm -f /tmp/s3obj /tmp/s3obj.back
