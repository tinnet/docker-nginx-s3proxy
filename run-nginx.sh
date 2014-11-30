#!/usr/bin/env bash

set -e

confd -onetime -backend env
nginx -g "daemon off;"
