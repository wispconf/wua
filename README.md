## Instalacion de Wireguard + Unbound * AdGuardHome 
Sistema completo de vpn para acceso remoto , o por ejemplo para acceso a una sola red desde diferentes lugares, agregandole el bloqueador de anuncios por medio de listas con AdGuardHome, usando Unbound para colocar solo los DNS.

_Testeado en Debian 12, pero podria tambien funcionar en ubuntu o derivadas_

## Por medio del script en automatico

```
wget https://raw.githubusercontent.com/Fibored/wau/refs/heads/main/install.sh
```

```
sudo bash install.sh
```

- Instala wireguard
- Crea usuario Pc2.conf como cliente wireguard cat /root/Pc2.conf
- Instala Unbound
- Configura Unbound
- Instala AdGuardHome , acceso por IP:3000 cambiar el puerto a otro que no sea 80, por ejemplo 8081
  - Cambiar el puerto a 8081
  - Ir a Settings > Dns settings , borra todo y agrega los dns **127.0.0.1:5335**
  - Selecciona **Paralell requests** y dale **Aply**
  - En **Rate Limit** coloca un cero, y tambien en **Cache size** un 0
- Instala Resolvconf

## Instalacion por medio de pasos y comandos.

```
apt update
apt install sudo dnsutils curl -y
wget -O wireguard.sh https://get.vpnsetup.net/wg
```

```
sudo bash wireguard.sh <<ANSWERS
n
51820
Pc2
7
10.7.0.1
y
ANSWERS
```

> colocarle los dns **10.7.0.1** al peer del cliente `/root/Pc2.conf`

Si se desean mas clientes, relanzar el script `sudo bash wireguard.sh` los datos de los clientes se encuentran en  `/root/`

```
apt install -y unbound
nano /etc/unbound/unbound.conf.d/config.conf
```

Agrega lo siguiente.
```
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
```
- Instalacion AdGuardHome

```
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
```

```
sudo systemctl restart unbound-resolvconf.service
wget -O root.hints https://www.internic.net/domain/named.root && sudo mv root.hints /var/lib/unbound/
```

```
sudo apt-get install resolvconf -y
```

Ir a la direccion http://IP:3000 para la configuracion

- Ip de acceso selecciona la del vps
- cambia el puerto a 8081
- en config dns coloca **127.0.0.1:5335** tipo **Parallel** , cache **0**

```
nano /opt/AdGuardHome/AdGuardHome.yaml
```

Cambia puerto **80** por **8081**
```
address: 0.0.0.0:8081
```

- Nueva ip de acceso **http://IP:8081**

```
reboot
ping -c 3 google.com
cat /etc/resolv.conf
```

Checa si se encuentra **/** si no ,agrega lo siguiente

```
nameserver 127.0.0.1
```

- Checar si hay algun conflicto de puerto
```
sudo apt install net-tools
netstat -ltnp | grep :80
```
