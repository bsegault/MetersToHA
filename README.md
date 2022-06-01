# veolia-idf
Ce script automatise le chargement de l'historique de votre consommation d'eau récupèré sur le site de Veolia Ile-de-France dans les solutions domotiques :
 - [Domoticz](https://domoticz.com/)
 - [Home Assistant](https://www.home-assistant.io/)

Ce script s'installe sur le serveur domotique ou sur autre serveur. Son execution est manuelle ou peut se planifier à travers un planificateur de tâche tel que "cron".

La récuperation des données se fait grace à l'outil selenium et l'execution en mode Headless de firefox ou chromium (simulation d'un utilisateur en tâche de fond sans mode graphique).

## Fonctionnalités :
* Récupération et chargement de l'intégralité de l'historique
* Gestion multi-contrat
* Vérification de l'intégrité de l'environnement (prérequis / configuration sur serveur domotique)
* Mode debug graphique
* Possible integration avec d'autre solution domotique (à vous de jouer)

## Prérequis :
* firefox + geckodriver OU chromium+chromium-driver
* python 3
* xvfb
* xephyr (recommandé)
* modules python :
  * selenium
  * pyvirtualdisplay
  * colorama
  * urllib3
  * qq autres... (le script commence par verifier la présence des modules)
* Un Virtual Sensor Domoticz

## Exemple d'instalation des prérequis sur ubuntu 20.04 :
```shell
apt install firefox firefox-geckodriver xvfb xserver-xephyr python3-selenium python3-pyvirtualdisplay python3-colorama python3-urllib3
```

## Création du "Virtual Sensor" sur Domoticz :
* Créer un Matériel de Type "Dummy" -> Domoticz / Setup / Hardware / Dummy
* Créer un "Virtual Sensor" de type : "Managed Counter"
* Configurer le sensor -> Domoticz / Utility / [Bouton "edit" de votre sensor]
  * Type Counter : water
  * Counter Divider : 1000
  * Meter Offset : 0

## Installation :

Copier les fichiers veolia-idf-domoticz.py et config.json.exemple sur votre serveur. Comme par exemple en :
```shell
mkdir -p /opt
cd /opt
git clone https://github.com/s0nik42/veolia-idf
cd veolia-idf
```
Pour mettre à jour :
```shell
git pull
```
Donnez la permission d'exécution si vous êtes sous Linux :
```shell
chmod ugo+x veolia-idf-domoticz.py
```
Ajouter les prerequis python:
```shell
pip3 install -r requirements.txt
```

## Configuration :
Copier le fichier config.json.exemple en config.json
```shell
cp  config.json.exemple config.json
```
Modifier le contenu du fichier avec vos valeurs. les champs obligatoires sont :
* "veolia_login": votre login de connection sur le site https://espace-client.vedif.eau.veolia.fr/
* "veolia_password": votre mot de passe
* "veolia_contract": votre numero de contrat (se trouve sur le site ou une facture)
* "domoticz_server": url du server domoticz (genre : http://127.0.0.1:8080/)
* "domoticz_idx": le numero du "virtual sensor" domoticz crée (se trouve dans : Domoticz/Devices/[Colonne Idx]

## Paramètrer votre système pour le mode debug (optionnel, mais recommandé)
Si vous rencontrez des problèmes à l'execution, il sera utile d'utiliser le mode debug (--debug). 2 scenarios :
1/ Le script est executé en locale par l'utilisateur avec lequel vous êtes logués  ==> ca devrait fonctionner tout seul.
2/ Vous executez le script sur une machine distante linux. Il convient alors de vérifier que la commande suivante fonctionne apres être connecté sur la machine linux distante (via ssh probablement) :
`xlogo`

Si vous voyez bien une fenetre X s'afficher à l'écran c'est que l'environnement X11 est correctement configuré. Le mode debug du script devrait fonctionner.

Si par contre rien ne s'affiche, il convient de chercher sur internet comment le faire fonctionner, il y a pleins de tutos pour cela. Ensuite vous pourrez utiliser le mode debug.

## Première execution :
Par default le script est muet (il n'affiche rien sur la console et ne lance pas la version graphique de Firefox). Il enregistre toutes les actions dans le fichier INSTALL_DIR/veolia.log .
Je vous recommande pour la première utilisation d'activer le mode debug. Cela permet d'avoir une sortie visuelle de l'éxecution du script sur la console et un suivi des actions dans Firefox.

Déroulement de l'éxécution :
1/ Chargement de tous les modules python --> si erreur installer les modules manquants (pip3 install ...)
2/ Sanity check de l'environnement :
 * Version
 * Pre-requis logiciel externe --> si erreur installer le logiciel manquant
 * Configuration domoticz --> si erreur configurer correctement domoticz
3/ Connection au site Veolia et téléchargement de l'historique
4/ Téléversement des données dans domoticz

```shell
./veolia-idf-domoticz.py --run --debug
```
Afficher toutes les options disponibles :
```shell
./veolia-idf-domoticz.py --help
```

## Automatisation :
Une fois que la première execution à terminée correctement, je vous recommande de planifier les executions une fois par jour. En rajoutant la ligne suivante à votre planificateur de tâche :
```shell
./veolia-idf-domoticz.py --run
```

exemple ici crontab :
```shell
crontab -e
```
```crontab
0 1 * * *       /opt/veolia-idf/veolia-idf-domoticz.py --run --log /var/log/veolia/veolia-idf.log
```

## Docker
Lire le fichier : dockerDebianRun.BAT

## Environnements testés:
* Debian Buster - chromium
* Debian Bullseye - chromium
* Alpine 3.16 - chromium
* Ubuntu 20.04 - firefox
* Ubuntu 21.04 - firefox (firefox-geckodriver non dispo sur Ubuntu 22.04).

## Remerciements :
* [k20human](https://github.com/k20human)
* [guillaumezin](https://github.com/guillaumezin)
* [mdeweerd](https://github.com/mdeweerd) | support de Home Assistant + Docker
