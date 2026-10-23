## EC2 S3 Sync and IAM Verification

### Automatic S3 Sync
- **Service:** `cv-sync.service`
- **Timer:** `cv-sync.timer`
- **Status:** Enabled and active
- **Sync interval:** Every 5 minutes
- **Web server:** Apache (`httpd`)

### Successful Sync Logs
The following entries confirm successful synchronization from S3 to the EC2 web directory:

```text
2026-10-23T16:15:24+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:19:45+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
2026-10-23T16:24:52+00:00 status=SUCCESS instance=i-05f3084c5f0b204e3
```

### IAM Permission Verification
An attempt to delete an S3 object using the EC2 instance role was denied, confirming that the role does not have `s3:DeleteObject` permission.

```text
An error occurred (AccessDenied) when calling the DeleteObject operation:
User: arn:aws:sts::582129522828:assumed-role/cv-ec2-role-23l-2587/i-05f3084c5f0b204e3
is not authorized to perform: s3:DeleteObject on resource:
arn:aws:s3:::cv-23l-2587-582129522828-ap-southeast-2-an/site/index.html
```

The EC2 instance role is restricted to the required S3 read and list permissions.