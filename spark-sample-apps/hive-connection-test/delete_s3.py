import boto3
import os

def main():
    # Create an S3 client
    aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    s3_endpoint_url = os.getenv("S3_ENDPOINT_URL")
    
    s3_w = boto3.client('s3',
        endpoint_url=s3_endpoint_url,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key
    )

# Define the S3 path
    bucket_name = "hive"
    prefix = "warehouse/mysparkdb2.db/"

# Delete S3 files one by one (avoids Content-MD5 error)
    response = s3_w.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
    if "Contents" in response:
        for obj in response["Contents"]:
            s3_w.delete_object(Bucket=bucket_name, Key=obj["Key"])
            print(f"Deleted: {obj['Key']}")
        print(f"Deleted all objects from s3://{bucket_name}/{prefix}")
    else:
        print(f"Path s3://{bucket_name}/{prefix} does NOT exist or is already empty.")

if __name__ == "__main__":
    main()