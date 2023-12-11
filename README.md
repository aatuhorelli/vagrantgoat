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

![Add file: salt key]
> Virtuaalikone webgoat onnistuneesti pystytetty ja avain hyväksytty.
