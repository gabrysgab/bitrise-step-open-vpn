#!/bin/bash
set -eu

echo "Configs:"
echo "host: $host"
echo "port: $port"
echo "proto: $proto"
echo ""

log_path=$(mktemp)

envman add --key "OPENVPN_LOG_PATH" --value "$log_path"
echo "Log path exported (\$OPENVPN_LOG_PATH=$log_path)"
echo ""

case "$OSTYPE" in
  darwin*)
    echo "Configuring for Mac OS"

    echo "Run openvpn"
      sudo openvpn --config "vpn_profile.ovpn" --auth-user-pass "credentials.txt" > "$log_path" 2>&1 &
    echo "Done"
    echo ""

    git clone $BITBUCKET_REPO_URL

    echo "Check status"
    sleep 5
    if ! ps -p $! >/dev/null ; then
      echo "Process exited"
      cat "$log_path"
      exit 1
    fi
    echo "Done"
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
