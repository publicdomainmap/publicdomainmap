#!/bin/bash

set -e

source /usr/local/bin/docker-entrypoint.sh
docker_process_init_files /custom-initdb.d/*
