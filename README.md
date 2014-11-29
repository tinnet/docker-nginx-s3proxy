# nginx based proxy for s3 - docker

Serve your static homepage from S3 while keeping the bucket private by proxying
it through nginx - running in docker.

# Usage

    docker run \
    -e S3PROXY_BUCKET_NAME="<S3_BUCKET_NAME>" \
    -e S3PROXY_AWS_ACCESS_KEY="<AWS_ACCESS_KEY>" \
    -e S3PROXY_AWS_SECRET_KEY="<AWS_SECRET_KEY>" \
    -P nginx-s3proxy
