import os
import json
import time
import base64
import boto3

s3 = boto3.client("s3")


def lambda_handler(event, context):
    start = time.perf_counter()
    path = (
        event.get("rawPath")
        or event.get("requestContext", {})
                 .get("http", {})
                 .get("path", "/")
    ).split("?", 1)[0]

    bucket = os.environ["BUCKET"]
    prefix = os.environ["PREFIX"].strip("/")
    filename = None
    status = 200
    headers = {}
    body = ""
    is_base64 = False

    try:
        if path in ("/", "/index.html"):
            filename = "index.html"
            content_type = "text/html"
        elif path == "/style.css":
            filename = "style.css"
            content_type = "text/css"
        elif path == "/cv.pdf":
            filename = "cv.pdf"
            content_type = "application/pdf"
        else:
            status = 404
            content_type = "text/html"
            body = "<html><body><h1>404 Not Found</h1></body></html>"

        if filename:
            key = f"{prefix}/{filename}"
            response = s3.get_object(Bucket=bucket, Key=key)
            data = response["Body"].read()

            if filename == "cv.pdf":
                body = base64.b64encode(data).decode("ascii")
                is_base64 = True
            else:
                body = data.decode("utf-8")
                if filename == "index.html":
                    body = body.replace(
                        "{{HOSTED_ON}}",
                        f"Lambda - {context.function_name}"
                    )

            headers["Content-Type"] = content_type

            if filename == "index.html":
                headers["Cache-Control"] = "max-age=60"

    except Exception:
        status = 500
        headers = {"Content-Type": "text/html"}
        body = "<html><body><h1>Internal Server Error</h1></body></html>"
        is_base64 = False

    print(json.dumps({
        "fn": context.function_name,
        "path": path,
        "status": status,
        "ms": round((time.perf_counter() - start) * 1000, 2)
    }))

    return {
        "statusCode": status,
        "headers": headers,
        "body": body,
        "isBase64Encoded": is_base64
    }