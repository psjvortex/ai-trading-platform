#!/usr/bin/env sh
# wait-for host:port
set -e
hostport="$1"
shift
until nc -z $(echo "$hostport" | cut -d: -f1) $(echo "$hostport" | cut -d: -f2); do
  echo "Waiting for $hostport..."
  sleep 1
done
exec "$@"
