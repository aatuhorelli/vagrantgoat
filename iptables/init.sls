/usr/local/bin/close.sh:
  file.managed:
    - source: salt://iptables/closed_iptables.sh
    - mode: "755"
