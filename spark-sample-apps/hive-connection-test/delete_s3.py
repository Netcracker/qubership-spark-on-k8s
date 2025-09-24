import boto3
import os

def main():
    # Create an S3 client
    aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    s3_endpoint_url = os.getenv("S3_ENDPOINT_URL")
    bucket_name = os.getenv("BUCKET_NAME")
    prefix = os.getenv("S3_PREFIX", "warehouse/mysparkdb2.db/")

    if not all([aws_access_key, aws_secret_key, s3_endpoint_url, bucket_name]):
        print("Missing required environment variables for S3 connection.")
        exit(1)

    s3_w = boto3.client(
        "s3",
        verify=False,
        endpoint_url=s3_endpoint_url,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
    )
    
    print(f"Starting deletion for s3://{bucket_name}/{prefix}...")

    # Use pagination for robustness, even if object count is low
    paginator = s3_w.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=bucket_name, Prefix=prefix)

    object_found = False
    for page in pages:
        if "Contents" in page:
            object_found = True
            for obj in page["Contents"]:
                # Delete objects one by one to avoid MissingContentMD5 error
                s3_w.delete_object(Bucket=bucket_name, Key=obj["Key"])
                print(f"Deleted: {obj['Key']}")

    if not object_found:
        print(f"Path s3://{bucket_name}/{prefix} does NOT exist or is already empty.")
    else:
        print(f"Deletion complete for s3://{bucket_name}/{prefix}.")


if __name__ == "__main__":
    main()
