import boto3
from botocore.config import Config
from botocore.exceptions import ClientError


def get_secret(key_name):
    try:
        with open(f"/etc/s3-secrets/{key_name}", "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        return None


def main():
    aws_access_key = get_secret("AWS_ACCESS_KEY_ID")
    aws_secret_key = get_secret("AWS_SECRET_ACCESS_KEY")
    s3_endpoint_url = get_secret("S3_ENDPOINT_URL")
    bucket_name = get_secret("BUCKET_NAME")

    db_name = get_secret("DB_NAME") or "mysparkdb.db"
    s3_prefix = f"warehouse/{db_name}/"

    if not all([aws_access_key, aws_secret_key, s3_endpoint_url, bucket_name]):
        print("Missing required variables for S3 connection.")
        exit(1)

    use_https = s3_endpoint_url.startswith("https")

    s3_w = boto3.client(
        "s3",
        endpoint_url=s3_endpoint_url,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
        verify="/certs/trust/s3.pem" if use_https else False,
        config=Config(
            signature_version="s3v4",
            s3={
                "addressing_style": "path",
                "payload_signing_enabled": True,
            },
        ),
    )

    try:
        # Check whether the bucket exists
        s3_w.head_bucket(Bucket=bucket_name)

        print(f"Bucket '{bucket_name}' exists.")

        # Bucket exists, so delete existing objects under the prefix
        response = s3_w.list_objects_v2(
            Bucket=bucket_name, Prefix=s3_prefix.rstrip("/")
        )

        if "Contents" in response:
            for obj in response["Contents"]:
                s3_w.delete_object(
                    Bucket=bucket_name,
                    Key=obj["Key"],
                )
                print(f"Deleted: {obj['Key']}")

            print(f"Deleted all objects from " f"s3://{bucket_name}/{s3_prefix}")
        else:
            print(
                f"Path s3://{bucket_name}/{s3_prefix} "
                f"does not exist or is already empty."
            )

    except ClientError as e:
        error_code = e.response["Error"].get("Code")

        if error_code in ("404", "NoSuchBucket"):
            print(f"Bucket '{bucket_name}' does not exist. " f"Creating bucket.")

            s3_w.create_bucket(Bucket=bucket_name)

            print(f"Created bucket '{bucket_name}'.")

        else:
            raise

    # Create the placeholder regardless of whether
    # the bucket already existed or was newly created.
    s3_w.put_object(
        Bucket=bucket_name,
        Key=s3_prefix,
        Body=b"",
    )

    print(f"Created placeholder at " f"s3://{bucket_name}/{s3_prefix}")


if __name__ == "__main__":
    main()
