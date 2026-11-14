. /config/lib.sh
T="10 20 30 40 50 60 70 80"
case "$1" in
  zgz-n1)
    sw_crear 4096
    sw_troncal eth1 $T
    sw_troncal eth2 $T
    for p in eth3 eth4 eth5; do sw_troncal $p $T; sw_raiz_no $p; done
    sw_acceso eth6 20 ;;
  zgz-n2)
    sw_crear 8192
    for p in eth1 eth2 eth3 eth4; do sw_troncal $p $T; done
    for p in eth2 eth3 eth4; do sw_raiz_no $p; done ;;
  zgz-a1)
    sw_crear 32768
    sw_troncal eth1 $T
    sw_troncal eth2 $T
    sw_acceso eth3 10
    sw_acceso eth4 30 ;;
  zgz-a2)
    sw_crear 32768
    sw_troncal eth1 $T
    sw_troncal eth2 $T
    sw_acceso eth3 40
    sw_acceso eth4 50 ;;
  zgz-a3)
    sw_crear 32768
    sw_troncal eth1 $T
    sw_troncal eth2 $T
    sw_acceso eth3 60
    sw_acceso eth4 70
    sw_acceso eth5 80 ;;
  sw-hue1)
    sw_crear 8192
    sw_troncal eth1 30 40 80
    sw_troncal eth2 30 40 80
    sw_raiz_no eth2
    sw_acceso eth3 30
    sw_acceso eth4 40 ;;
  sw-hue2)
    sw_crear 32768
    sw_troncal eth1 30 40 80
    sw_acceso eth2 80 ;;
  sw-ter1)
    sw_crear 8192
    sw_troncal eth1 40 80
    sw_troncal eth2 40 80
    sw_raiz_no eth2
    sw_acceso eth3 40 ;;
  sw-ter2)
    sw_crear 32768
    sw_troncal eth1 40 80
    sw_acceso eth2 80 ;;
esac
