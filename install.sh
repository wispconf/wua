#!/bin/bash

# Set default values for variables
ENABLE_COLORS=true
# Function to print an OK message in green
print_green() {
    echo -e "${GREEN}$1${NC}"
}

# Function to print a KO message in red
print_red() {
    echo -e "${RED}$1${NC}"
}

# Function to print a warning message in yellow
print_yellow() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to print an info message in blue
print_blue() {
    echo -e "${BLUE}$1${NC}"
}

print_spinner() {
    PID=$1
    
    i=1
    sp="/-\|"
    echo -n ' '
    while [ -d /proc/$PID ]; do
        printf "\b${sp:i++%${#sp}:1}"
        sleep 0.1
    done
    printf "\b"
}



# Function to ensure the script is run as root
system_ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      print_red "[!] This script needs to be run as root. Elevating script to root with sudo."
      interpreter="$(head -1 "$0" | cut -c 3-)"
      if [ -x "$interpreter" ]; then
        sudo "$interpreter" "$0" "$@"
      else
        sudo "$0" "$@"
      fi
      exit $?
    else
      print_red "[!] This script needs to be run as root."
      exit 1
    fi
  fi
}

# Function to install necessary system packages and perform system update
install_dep() {
    echo -n "[+] Instalando Dependencias... "

    apt install sudo dnsutils curl -y >/dev/null 2>&1 & print_spinner $!
    if [ $? -ne 0 ]; then
        echo "KO"
            echo "[!] Dependencias wireguard instaladas." >&2
            exit 1
    fi
    print_green "OK"

    echo -n "[+] Instalando wireguard... "
    wget -O wireguard.sh https://get.vpnsetup.net/wg >/dev/null 2>&1 & print_spinner $!
    if [ $? -ne 0 ]; then
        print_red "KO"
        echo "[!] Error descargando archivo wg." >&2
        exit 1
    fi
    print_green "OK"

    echo -n "[+] Add client wg... "

    printf '%s\n%s\n%s\n%s\n%s\n%s\n' n 51820 Pc2 7 10.7.0.1 yes | sudo bash wireguard.sh >/dev/null 2>&1 & print_spinner $!
    if [ $? -ne 0 ]; then
        print_red "KO"
        echo "[!] Error Config." >&2
        exit 1
    fi
    print_green "--> sudo bash wireguard.sh"
}


# Function to install sudo
install_unbound() {
    echo -n "[+] Installing Unbound... "
    apt install sudo unbound -y >/dev/null 2>&1 & print_spinner $!
    if [ $? -ne 0 ]; then
        print_red "KO"
        echo "[!] Failed to install unbound. Aborting." >&2
        exit 1
    fi
    echo "server:
  interface: 127.0.0.1
  port: 5335

  # IPv4 / IPv6-settings
  do-ip6: no
  do-ip4: yes
  do-udp: yes

  # Set number of threads to use
  num-threads: 1

  # Hide DNS Server info
  hide-identity: yes
  hide-version: yes

  # Limit DNS Fraud and use DNSSEC
  harden-glue: yes
  harden-dnssec-stripped: yes
  harden-referral-path: yes
  use-caps-for-id: yes
  harden-algo-downgrade: yes
  qname-minimisation: yes

  # Add an unwanted reply threshold to clean the cache and avoid when possible a DNS Poisoning
  unwanted-reply-threshold: 10000000

  # Minimum lifetime of cache entries in seconds (4min)
  cache-min-ttl: 240

  # Maximum lifetime of cached entries (4hour)
  cache-max-ttl: 14400

  # Prefetch
  prefetch: yes
  prefetch-key: yes

  # Optimisations
  msg-cache-slabs: 8
  rrset-cache-slabs: 8
  infra-cache-slabs: 8
  key-cache-slabs: 8

  # Increase memory size of the cache
  rrset-cache-size: 256m
  msg-cache-size: 128m

  # Private addresses (RFC 1918)
  private-address: 192.168.0.0/16
  private-address: 169.254.0.0/16
  private-address: 172.16.0.0/12
  private-address: 10.0.0.0/8
  private-address: fd00::/8
  private-address: fe80::/10
  # Experemetal
  private-address: 127.0.0.0/8
  private-address: ::ffff:0:0/96

remote-control:
  # enable remote-control
  control-enable: no" > /etc/unbound/unbound.conf.d/config.conf
    print_green "OK"
}


Adguardhome_install() {
    echo -n "[+] Installing AdguardHome... "
   curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v >/dev/null 2>&1 & print_spinner $!
   if [ $? -ne 0 ]; then
        print_red "KO"
        echo "[!] Failed to install Adguardhome. Aborting." >&2
        exit 1
    fi
    print_green "IP:3000 --> Config Puerto 8081 Dns 127.0.0.1:5335 Parallel RateLimit 0 Cache 0"
}

resolvconf_install() {
    echo -n "[+] Installing Resolvconf... "
   apt install resolvconf -y >/dev/null 2>&1 & print_spinner $!
   wget -O root.hints https://www.internic.net/domain/named.root >/dev/null 2>&1 & print_spinner $!
   sudo mv root.hints /var/lib/unbound/ >/dev/null 2>&1 & print_spinner $!
   if [ $? -ne 0 ]; then
        print_red "KO"
        echo "[!] Failed to install resolvconf. Aborting." >&2
        exit 1
    fi


   print_green "OK"
}


main() {
    system_ensure_root

    install_dep

    install_unbound

    Adguardhome_install

    resolvconf_install
}
# Define color codes
if $ENABLE_COLORS; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Call the main function to start the installation process
main
