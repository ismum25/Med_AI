import io
import uuid
from datetime import timedelta
from app.config import settings


def get_minio_client():
    from minio import Minio
    return Minio(
        settings.MINIO_ENDPOINT,
        access_key=settings.MINIO_ACCESS_KEY,
        secret_key=settings.MINIO_SECRET_KEY,
        secure=settings.MINIO_SECURE,
    )


def _ensure_bucket(client, bucket: str):
    if not client.bucket_exists(bucket):
        client.make_bucket(bucket)


async def upload_file(file_bytes: bytes, file_name: str, content_type: str, folder: str = "reports") -> str:
    object_key = f"{folder}/{uuid.uuid4()}/{file_name}"

    if settings.STORAGE_BACKEND == "minio":
        client = get_minio_client()
        _ensure_bucket(client, settings.MINIO_BUCKET)
        client.put_object(
            settings.MINIO_BUCKET,
            object_key,
            io.BytesIO(file_bytes),
            length=len(file_bytes),
            content_type=content_type,
        )
    else:
        import boto3
        s3 = boto3.client(
            "s3",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_REGION,
        )
        s3.put_object(Bucket=settings.AWS_S3_BUCKET, Key=object_key, Body=file_bytes, ContentType=content_type)

    return object_key


def get_presigned_url(object_key: str, expires_seconds: int = 3600) -> str:
    if settings.STORAGE_BACKEND == "minio":
        client = get_minio_client()
        return client.presigned_get_object(
            settings.MINIO_BUCKET, object_key, expires=timedelta(seconds=expires_seconds)
        )
    else:
        import boto3
        s3 = boto3.client(
            "s3",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_REGION,
        )
        return s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.AWS_S3_BUCKET, "Key": object_key},
            ExpiresIn=expires_seconds,
        )


async def download_file(object_key: str) -> bytes:
    if settings.STORAGE_BACKEND == "minio":
        client = get_minio_client()
        response = client.get_object(settings.MINIO_BUCKET, object_key)
        return response.read()
    else:
        import boto3
        s3 = boto3.client(
            "s3",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_REGION,
        )
        response = s3.get_object(Bucket=settings.AWS_S3_BUCKET, Key=object_key)
        return response["Body"].read()
