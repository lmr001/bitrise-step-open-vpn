#!/bin/bash
set -eu

echo ""
echo "=============================================================="
echo ""

echo "Create OPENVPN_LOG_PATH"
echo ""

log_path=$(mktemp)

envman add --key "OPENVPN_LOG_PATH" --value "$log_path"
echo "Log path exported (\$OPENVPN_LOG_PATH=$log_path)"
echo ""

echo ""
echo "=============================================================="
echo ""

# -------------------------------------------------------------------
# ----------------------- INSTALL OVPN FILE -------------------------
# -------------------------------------------------------------------

echo "Load OVPN BASE64 File:"
current_dir=$(pwd)
ovpn_content="$vpn_ovpn_base64"

if [ ! -z "$ovpn_content" ]; then
    echo "ovpn_content: $ovpn_content"
else
    echo "ovpn_content is empty."
fi

# Write base64 decoded content to file
FILE_PATH="${current_dir}/client.ovpn"
echo "FILE_PATH=$FILE_PATH"
echo ${ovpn_content} | base64 -d > $FILE_PATH

echo ""
echo "=============================================================="
echo ""

# -------------------------------------------------------------------
# ----------------------- INSTALL OPENVPN ---------------------------
# -------------------------------------------------------------------

echo "Start installation for OpenVPN"
echo ""

case "$OSTYPE" in
    linux*)

        echo "Configuring for Ubuntu"

        sudo apt-get update > $log_path 2>&1

        sudo apt-get -y install openvpn unzip > $log_path 2>&1

        echo "Installing required packages on Ubuntu"

        sudo apt-get install iputils-ping > $log_path 2>&1
        sudo apt-get -y install dnsutils > $log_path 2>&1
        sudo systemctl restart systemd-resolved && sudo systemctl stop systemd-resolved > $log_path 2>&1

        echo "Configuration Done"
        ;;
    darwin*)

        echo "Configuring for Mac OS"

        brew install openvpn > $log_path 2>&1

        echo "Configuration Done"

        echo "openvpn --version"
        openvpn --version
        ;;
    *)
        echo "Unknown operative system: $OSTYPE, exiting"
        exit 1
        ;;
esac

echo ""
echo "=============================================================="
echo ""

# -------------------------------------------------------------------
# ----------------------- CONNECT TO VPN ----------------------------
# -------------------------------------------------------------------

# run OpenVPN in the background so that it doesn't interfere with commands that need to be run subsequently

case "$OSTYPE" in
    linux*)

        echo "Connecting to VPN on Ubuntu"
        sudo -b openvpn --config $FILE_PATH > $log_path 2>&1 &
        echo "Connected"
        ;;
    darwin*)

        echo "Connecting to VPN on Mac OS"
        # sudo -b openvpn $FILE_PATH > $log_path 2>&1 &
        sudo -b openvpn --config $FILE_PATH > $log_path 2>&1 &
        echo "Connected"
        ;;
    *)
        echo "Unknown operative system: $OSTYPE, exiting"
        exit 1
        ;;
esac

# sleep for 10 seconds to allow OpenVPN to establish connection to the VPN server
#sleep 10s
SLEEP_TIME="10"
echo "Current time: $(date +%T)"
echo "Hi, I'm sleeping for ${SLEEP_TIME} seconds ..."
sleep ${SLEEP_TIME}
echo "All done and current time: $(date +%T)"

echo ""
echo "=============================================================="
echo ""

# # -------------------------------------------------------------------
# # -------------------------- PING TEST ------------------------------
# # -------------------------------------------------------------------

case "$OSTYPE" in
    linux*)
        # NB: For some reason, PING is failing on Ubuntu...so we'll just do a curl
        echo "Ping test on Ubuntu"
        curl $vpn_url__connection_test
        echo "Done"
        ;;
    darwin*)

        echo "Ping Test on Mac OS"
        ping -c 4 $vpn_url__connection_test
        echo "Done"
        ;;
    *)
        echo "Unknown operative system: $OSTYPE, exiting"
        exit 1
        ;;
esac

echo ""
echo "=============================================================="
echo ""

