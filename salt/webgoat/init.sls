# Download webgoat
/home/vagrant/webgoat.jar:
  file.managed:
    - source: salt://webgoat/webgoat-2023.4.jar

# Run webgoat, if process 'java' is not already running
java_running:
  cmd.run:
    - name: "pgrep -f 'java'"
    - onlyif: "pgrep -f 'java'"

# Run WebGoat on 192.168.58.100:8888
run_webgoat:
  cmd.run:
    - name: "java -Dfile.encoding=UTF-8 -Dserver.address=192.168.58.100 -Dwebgoat.port=8888 -Dwebwolf.port=9090 -jar /home/vagrant/webgoat.jar"
    - watch:
      - cmd: java_running
