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



    echo "Check status"
    sleep 10
    if ! ps -p $! >/dev/null ; then
      echo "Process exited"
      cat "$log_path"
      exit 1
    fi
    echo "Done"
    echo $GH_REPO_ADDRESS |sudo tee -a /etc/hosts

    git clone $BITBUCKET_REPO_URL
    ;;
  *)
    echo "Unknown operative system: $OSTYPE, exiting"
    exit 1
    ;;
esac
