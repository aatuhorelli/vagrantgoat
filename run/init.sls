# Verify that WebGoat, java and close.sh are present
include:
  - webgoat
  - iptables
  - java

# Run close.sh to only allow traffic from virtual network
close_iptables:
  cmd.run:
    - name: "close.sh"

# Run WebGoat, unless the process is already running
webgoat_start:
  cmd.run:
    - name: "java -Dfile.encoding=UTF-8 -Dserver.address=192.168.58.100 -Dwebgoat.port=8888 -Dwebwolf.port=9090 -jar /home/vagrant/webgoat.jar"
    - unless: "ps aux | grep '[j]ava'"
