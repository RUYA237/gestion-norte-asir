# Imagen única de la maqueta: Ubuntu 24.04 (la misma versión que ubu-fw) con lo
# necesario para hacer de router (FRR, nftables, WireGuard), de switch (puente
# Linux con VLAN, iproute2) o de equipo de prueba (ping, traceroute, nc, tcpdump).
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      frr iproute2 nftables wireguard-tools \
      iputils-ping traceroute netcat-openbsd tcpdump dnsutils curl \
      procps less vim-tiny ca-certificates \
 && rm -rf /var/lib/apt/lists/*
CMD ["sleep", "infinity"]
