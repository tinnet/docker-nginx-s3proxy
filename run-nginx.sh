#!/usr/bin/env bash

set -e

confd -onetime -backend env
exec nginx -g "daemon off;"
