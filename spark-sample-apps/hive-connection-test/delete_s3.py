import boto3


def get_secret(key_name):
    try:
        with open(f"/etc/s3-secrets/{key_name}", "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        return None


def main():
    # Create an S3 client
    aws_access_key = get_secret("AWS_ACCESS_KEY_ID")
    aws_secret_key = get_secret("AWS_SECRET_ACCESS_KEY")
    s3_endpoint_url = get_secret("S3_ENDPOINT_URL")
    bucket_name = get_secret("BUCKET_NAME")
    s3_prefix = "warehouse/" + (get_secret("DB_NAME")) or "warehouse/mysparkdb.db/"

    if not all([aws_access_key, aws_secret_key, s3_endpoint_url, bucket_name]):
        print("Missing required variables for S3 connection.")
        exit(1)

    s3_w = boto3.client(
        "s3",
        verify=False,
        endpoint_url=s3_endpoint_url,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
    )

    response = s3_w.list_objects_v2(Bucket=bucket_name, Prefix=s3_prefix)
    if "Contents" in response:
        for obj in response["Contents"]:
            s3_w.delete_object(Bucket=bucket_name, Key=obj["Key"])
            print(f"Deleted: {obj['Key']}")
        print(f"Deleted all objects from s3://{bucket_name}/{s3_prefix}")
    else:
        print(
            f"Path s3://{bucket_name}/{s3_prefix} does NOT exist or is already empty."
        )

    s3_w.put_object(Bucket=bucket_name, Key=s3_prefix)
    print(f"Created placeholder at s3://{bucket_name}/{s3_prefix}")


if __name__ == "__main__":
    main()
