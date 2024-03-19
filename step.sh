#!/bin/bash
set -eu

echo "Configs:"
echo "host: $host"
echo "port: $port"
echo "proto: $proto"
echo "ca_crt: $(if [ ! -z "$ca_crt" ]; then echo "***"; fi)"
echo "client_crt: $(if [ ! -z "$client_crt" ]; then echo "***"; fi)"
echo "client_key: $(if [ ! -z "$client_key" ]; then echo "***"; fi)"
echo ""

log_path=$(mktemp)

envman add --key "OPENVPN_LOG_PATH" --value "$log_path"
echo "Log path exported (\$OPENVPN_LOG_PATH=$log_path)"
echo ""

case "$OSTYPE" in
  linux*)
    echo "Configuring for Ubuntu"

    echo ${ca_crt} | base64 -d > /etc/openvpn/ca.crt
    echo ${client_crt} | base64 -d > /etc/openvpn/client.crt
    echo ${client_key} | base64 -d > /etc/openvpn/client.key

    cat <<EOF > /etc/openvpn/client.conf
client
dev tun
proto ${proto}
remote ${host} ${port}
resolv-retry infinite
nobind
persist-key
persist-tun
comp-lzo
verb 3
ca ca.crt
cert client.crt
key client.key
EOF

    echo ""
    echo "Run openvpn"
      service openvpn start client > $log_path 2>&1
    echo "Done"
    echo ""

    echo "Check status"
    sleep 5
    if ! ifconfig | grep tun0 > /dev/null ; then
      echo "No open VPN tunnel found"
      cat "$log_path"
      exit 1
    fi
    echo "Done"
    ;;
  darwin*)
    echo "Configuring for Mac OS"

    echo ${ca_crt} | base64 -D -o ca.crt
    echo ${client_crt} | base64 -D -o client.crt
    echo ${client_key} | base64 -D -o client.key
    echo ""

    echo "Run openvpn"
      sudo openvpn --config "vpn_profile.ovpn" --auth-user-pass "credentials.txt" > "$log_path" 2>&1 &
    echo "Done"
    echo ""

    git "init"
    git "remote" "add" "origin" "$GIT_REPOSITORY_URL"
    git "config" "gc.auto" "0"

    git "clean" "-fd"
    Removing vpn_profile.ovpn
    git "reset" "--hard" "HEAD"

    git "fetch" "--jobs=10" "--depth=1" "--no-tags" "origin" "refs/heads/develop"

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
