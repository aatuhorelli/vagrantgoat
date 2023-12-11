# VagrantGoat-miniprojekti
WebGoatin pystyttäminen virtuaalikoneelle Vagrantin, Saltin ja Javan avulla. Palvelin sallii liikenteen vain virtuaaliverkosta WebGoatin käynnistyttyä. 

Lataa WebGoat /srv/salt/webgoat/-hakemistoon komennolla ``$ wget https://github.com/WebGoat/WebGoat/releases/download/v2023.4/webgoat-2023.4.jar``


## Käyttöympäristö

Miniprojekti toteutettu Asus Vivobook X1505 -kannettavalla. Suurimmat laitevaatimukset kohdistuvat RAM-muistin määrään Javan hyödyntämisen seurauksena. 

```
Isäntälaitteen tiedot grains.items hyödyntäen:
----------
cpu_model:
        12th Gen Intel(R) Core(TM) i7-1255U
num_cpus:
        12
cpuarch:
        x86_64
mem_total:
        15684
osfinger:
        Kali GNU/Linux-2023
saltversion:
        3006.4
````

Virtualisoinnissa käytetty VirtualBoxia(7.0.12) ja Vagrantia (2.3.4).

## Käyttö 

Projektin tarkoituksena on saada helposti ja nopeasti pystytettyä uusi virtuaalikone, jossa on WebGoat ja siihen vaadittavat ohjelmistot asennettuina. WebGoat on haavoittuvuuksien testaamisen harjoitteluun tarkoitettu ohjelma, joka on tarkoituksella erittäin haavoittuvainen. Tästä syystä WebGoatin käynnistämisen yhteydessä liikenne muualle kuin Vagrantin kautta pystytettyyn virtuaaliverkkoon estetään seuraavaan uudelleenkäynnistykseen asti. Normaalisti käyttäjän tulee oman turvallisuutensa takia irroittaa myös isäntälaite internetistä, mutta projektin esittelyn kannalta tämä olisi haasteellista.

### Vagrant

Vagrantfilen sisältö:

````
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Template copyright terokarvinen.com
$minion = <<MINION
sudo apt-get update
sudo apt-get -qy install salt-minion
echo "master: 192.168.58.1">/etc/salt/minion
sudo service salt-minion restart
MINION


Vagrant.configure("2") do |config|
        config.vm.box = "debian/bullseye64"

        config.vm.define "webgoat" do |wg|
                wg.vm.provision :shell, inline: $minion
                wg.vm.network "private_network", ip: "192.168.58.100"
                wg.vm.hostname = "webgoat"
        end
        # Add enough RAM for JRE to run
        config.vm.provider "virtualbox" do |vm|
                vm.memory = 4096
                vm.cpus = 2
        end
end

````

Vagrantfilen pohjana on hyödynnetty [terokarvinen.com](https://terokarvinen.com/2018/automatically-provision-vagrant-virtualmachines-as-salt-slaves/) pohjaa, jolla provisioidaan Debian 11-virtuaalikone ja tehdään tarvittavat asennukset salt-minionin käyttöä varten.

Vagrantfilen hakemistossa ajetaan komento ``$ vagrant up``, joka luo VirtualBoxiin uuden virtuaalikoneen noin minuutissa. Asennuksen yhteydessä virtuaalikone päivittää paketinhallinnan listat ``$ sudo apt-get update``, asentaa salt-minionin ``$ sudo apt-get install salt-minion`` ja asettaa masterin ip-osoitteen tiedostoon ``/etc/salt/minion``. Vagrant provisioi virtuaalikoneille normaalisti hyvin vähän RAM-muistia, ja tämä aiheutti ongelmia WebGoatin käynnistämisessä. Asetin Vagrantfileen ``vm.memory = 4096``(Mt) muistia ja kaksi prosessoria, mikä poisti WebGoatin käynnistymisongelmat. 

Virtuaalikoneelle ei ole tarvetta kirjautua Vagrantin kautta kertaakaan.

## Salt

Kun virtuaalikone on käynnistynyt, se tavoittelee saltin kautta isäntälaitteen ip-osoitetta. Komento ``$ sudo salt-key`` tuo esiin listan hyväksytyistä ja hyväksymättömistä avaimista. Hyväksyn orjan 'webgoat' avaimen: ``$ sudo salt-key -A # (y/n) -> Y)``. 

![Add file: salt key](/img/saltkey.png)
> Virtuaalikone webgoat onnistuneesti pystytetty ja avain hyväksytty.

### Top.sls 

Hakemiston sisältö:

````
$ ls /srv/salt                                                                                                                                                  
iptables  java  run  top.sls  webgoat
````

top.sls-tiedostossa määritellään, mitkä tilat orjille ajetaan komennolla ``$ sudo salt '*' state.apply``. Tässä versiossa orjia on vain yhdenlaisia, mutta siitä huolimatta tiedostoon on määritelty, että seuraavat tilat ajetaan vain webgoat-alkuisille orjille.

````
$ cat top.sls 
base:
  'webgoat*':
    - java # Asentaa jdk-17-jre:n
    - webgoat # Lataa webgoatin masterin /srv/salt/webgoat/-hakemistosta
    - iptables # Luo close.sh-tiedoston /srv/salt/iptables/-hakemiston esimerkkitiedoston pohjalta
````

Iptables-hakemistossa on iptablesin sääntöjä määrittävä shell-skripti, jota käytetään lähdetiedostona minionille siirrettävälle tiedostolle. 

Init.sls ja closed_iptables.sh-tiedostojen sisältö:
````
$ cat /srv/salt/iptables/init.sls 
/usr/local/bin/close.sh:
  file.managed:
    - source: salt://iptables/closed_iptables.sh
    - mode: "755"

$ cat closed_iptables.sh 
#!/usr/bin/bash
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -s 192.168.58.0/24 -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A OUTPUT -d 192.168.58.0/24 -j ACCEPT
````
Valtaosa projektiin käytetystä ajasta kului miettiessä järkevää tapaa toteuttaa palomuurisäännöt, koska niiden asettaminen esti myös Vagrant ssh:n käytön ja johti usein koneen tuhoamiseen ja uudelleenpystyttämiseen. Käytin iptablesia siitä syystä, että sen säännöt eivät säily uudelleenkäynnistyksen yli, joten ``$ vagrant reload`` sallii taas koneelle pääsyn SSH:n avulla. Säännöt estävät oletuksena kaiken liikenteen, paitsi localhostiin ja virtuaalikoneiden aliverkkoon.


Java- ja webgoat-hakemistojen init.sls:n sisältö on hyvin yksinkertainen. Paketti openjdk-17-jre asennetaan, jos sitä ei vielä ole olemassa. 

````
$ cat /srv/salt/java/init.sls 
# Install Java Runtime Environment
openjdk-17-jre:
  pkg.installed 
````
Webgoat/init.sls lataa tarvittaessa webgoat.jar-tiedoston isäntälaitteelta orjan vagrant-käyttäjän kotihakemistoon.
````
$ cat /srv/salt/webgoat/init.sls 
# Download webgoat
/home/vagrant/webgoat.jar:
  file.managed:
    - source: salt://webgoat/webgoat-2023.4.jar
````

Top.sls-tiedostossa määriteltyjen pakettien asennus webgoatille tapahtuu komennolla ``$ sudo salt '*' state.apply``. Lataus kestää hetken Java-paketin koosta johtuen. 

![Add file: top asennus](/img/top.png)
> Onnistunut asennus. Succeeded: 3 (changed=3).


## Käyttö - state.apply run

WebGoatin ajo on eriytetty omaan komeentoonsa 'run', sillä se jää pyörimään terminaaliin, eikä täten palauta ilmoitusta suorituksen onnistumisesta. Runin init.sls olisi yksinään riittävä suorittamaan asennukset ja palvelun käynnistämisen. 

/srv/run/init.sls sisältö:
````
# Verify that WebGoat, java  and close.sh are present
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
    - unless: "ps aux | grep '[j]ava'" # ylempi komento suoritetaan vain, jos prosessi java ei pyöri.
````
Hakasulkuja käytetty grep '[j]ava' ympärillä siitä syystä, että muussa tapauksessa ``$ ps aux`` palauttaa aina True löytäessään myös oman prosessinsa. Vastaus löytyi StackOverflowsta, linkkiä keskusteluun en onnistunut enää kaivamaan sivuhistoriasta. Lisään sen, jos löydän. Tämä init.sls ajaa ensin tilat webgoat, iptables ja java, minkä jälkeen rajoitta orjan liikennettä shell-skriptillä ja lopuksi käynnistää WebGoatin.

Totesin myös käyttäjäystävälliseksi ratkaisuksi ajaa state.applyn aynkronoidusti taustalla välttyäkseni turhalta odotukselta. Komento käynnistää prosessin, joka jää terminaaliin pyörimään, eikä täten palauta kuittausta onnistumisestaan. ``$ sudo salt '*' state.apply run --async``.

![Add file: run](/img/run.png)
> WebGoat elää!

WebGoat herää henkiin ja on käytettävissä. Orjaan ei saa enää yhteyttä ssh:lla, mutta sen uudelleenkäynnistäminen Vagrantilla ``$ vagrant reload`` poistaa myös palomuurisäännöt, jolloin ssh:n käyttö on taas mahdollista.

