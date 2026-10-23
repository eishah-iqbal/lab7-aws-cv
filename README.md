## S3 Sync Log Verification

Command executed:

```bash
sudo tail -n 10 /var/log/cv-sync.log
```

Output captured:

```text
2026-10-23T16:15:24+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:19:45+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:24:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:29:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:34:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:39:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:44:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:49:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:54:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:59:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
```

These entries confirm multiple successful synchronization runs.

## S3 Deletion Permission Test

Command executed:

```bash
aws s3 rm s3://cv-23l-2587-582129522828-ap-southeast-2-an/site/index.html
```

Output:

```text
delete failed: s3://cv-23l-2587-582129522828-ap-southeast-2-an/site/index.html An error occurred (AccessDenied) when calling the DeleteObject operation: User: arn:aws:sts::582129522828:assumed-role/cv-ec2-role-23l-2587/i-05f3084c5f0b204e3 is not authorized to perform: s3:DeleteObject on resource: "arn:aws:s3:::cv-23l-2587-582129522828-ap-southeast-2-an/site/index.html" because no identity-based policy allows the s3:DeleteObject action
```

The `AccessDenied` response confirms that the EC2 instance role does not have permission to delete objects from the S3 bucket.