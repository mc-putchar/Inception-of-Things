#!/usr/bin/env bash

set -e

generate_password() {
    openssl rand -base64 32 |  tr -d '/+=' | cut -c1-24
}

echo "REDIS_PASS=$(generate_password)" > ~/mnt/bonus/confs/credentials.env
echo "GITLAB_ROOT_PASS=$(generate_password)" >> ~/mnt/bonus/confs/credentials.env
