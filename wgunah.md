apt update
apt install sudo dnsutils curl -y
wget -O wireguard.sh https://get.vpnsetup.net/wg
sudo bash wireguard.sh --auto

##Si se desean mas clientes, relanzar el script , los datos de los clientes se encuentran en  /root/

apt install -y unbound

nano /etc/unbound/unbound.conf.d/config.conf

--------------------- add
server:
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
  control-enable: no
-----------------------------------

curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v

##go to http://IP:3000
##configuralo default dns 127.0.0.1:5335 tipo Parallel , cache 0

sudo apt-get install resolvconf -y && sudo systemctl restart unbound-resolvconf.service
wget -O root.hints https://www.internic.net/domain/named.root && sudo mv root.hints /var/lib/unbound/

reboot

ping -c 3 google.com

cat /etc/resolv.conf
---------------checa si se encuentra / si no ,agrega lo siguiente
nameserver 127.0.0.1
------------
