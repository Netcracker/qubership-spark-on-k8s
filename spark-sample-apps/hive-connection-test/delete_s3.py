import boto3
import os

def delete_s3_prefix_contents(bucket_name, prefix, s3_client):
    
    print(f"Starting deletion for s3://{bucket_name}/{prefix}...")
    
    paginator = s3_client.get_paginator("list_objects_v2")
    pages = paginator.paginate(Bucket=bucket_name, Prefix=prefix)
    
    delete_keys = {"Objects": []}
    
    for page in pages:
        if "Contents" in page:
            for obj in page["Contents"]:
                delete_keys["Objects"].append({"Key": obj["Key"]})
                
                # Delete in batches of 1000
                if len(delete_keys["Objects"]) >= 1000:
                    s3_client.delete_objects(Bucket=bucket_name, Delete=delete_keys)
                    print(f"Deleted {len(delete_keys['Objects'])} objects.")
                    delete_keys = {"Objects": []}

    # Delete any remaining objects
    if len(delete_keys["Objects"]) > 0:
        s3_client.delete_objects(Bucket=bucket_name, Delete=delete_keys)
        print(f"Deleted {len(delete_keys['Objects'])} final objects.")

    print(f"Deletion complete for s3://{bucket_name}/{prefix}.")


def main():
    # Create an S3 client
    aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    s3_endpoint_url = os.getenv("S3_ENDPOINT_URL")
    bucket_name = os.getenv("BUCKET_NAME")
    prefix = os.getenv("S3_PREFIX", "warehouse/mysparkdb2.db/") # Use a default value if not set

    if not all([aws_access_key, aws_secret_key, s3_endpoint_url, bucket_name]):
        print("Missing required environment variables for S3 connection.")
        exit(1)

    s3_client = boto3.client(
        "s3",
        verify=False,
        endpoint_url=s3_endpoint_url,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key,
    )

    delete_s3_prefix_contents(bucket_name, prefix, s3_client)


if __name__ == "__main__":
    main()
