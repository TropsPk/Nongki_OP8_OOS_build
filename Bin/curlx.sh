#!/usr/bin/env bash

set -x

# usage: curlx <url> <file name>
# --fail: turn HTTP 4xx/5xx into a real nonzero exit instead of silently
#         writing the error body to the output file (which is what let the
#         libufdt tarball failure surface downstream as a confusing gzip/tar
#         error instead of a curl error).
# --retry/--retry-delay: ride out transient network blips / rate-limiting.
curl -C - --fail --retry 3 --retry-delay 5 --progress-bar -L "$1" -o "$2"
