
# Tutoriel Complet : Configuration de la Réplication MySQL sur Windows GROUPE6

## 1. Configuration des Adresses IP
### 1.1 Définir une IP Statique sur le Master et le Slave
Sur Windows, suivez ces étapes :
1. Ouvrir **Paramètres** > **Réseau et Internet** > **Ethernet** (ou **Wi-Fi** si applicable).
2. Cliquer sur **Modifier les options d’adaptateur**.
3. Faire un clic droit sur l’interface réseau et sélectionner **Propriétés**.
4. Double-cliquer sur **Protocole Internet version 4 (TCP/IPv4)**.
5. Sélectionner **Utiliser l’adresse IP suivante** et entrer les valeurs suivantes :
   - **Sur le Master (192.168.1.76)** :
     - Adresse IP : `192.168.1.76`
     - Masque de sous-réseau : `255.255.255.0`
     - Passerelle par défaut : `192.168.1.1`
   - **Sur le Slave (192.168.1.77)** :
     - Adresse IP : `192.168.1.77`
     - Masque de sous-réseau : `255.255.255.0`
     - Passerelle par défaut : `192.168.1.1`
6. Valider avec **OK** et redémarrer la connexion réseau.

## 2. Installation de MySQL sur Windows
1. Télécharger MySQL depuis le site officiel : [https://dev.mysql.com/downloads/installer/](https://dev.mysql.com/downloads/installer/)
2. Exécuter l’installateur et choisir **MySQL Server**.
3. Suivre les étapes et définir un mot de passe root.
4. Noter le chemin d’installation, par défaut : `C:\Program Files\MySQL\MySQL Server X.X\bin`.
5. Ajouter ce chemin aux variables d’environnement Windows.

## 3. Configuration du Serveur Master
1. Ouvrir une invite de commandes **en mode administrateur**.
2. Modifier le fichier de configuration MySQL (`my.ini`) situé dans :
   ```
   C:\ProgramData\MySQL\MySQL Server X.X\my.ini
   ```
3. Ajouter ou modifier ces lignes :
   ```ini
   [mysqld]
   server-id=1
   log_bin=mysql-bin
   binlog_format=ROW
   enforce-gtid-consistency=ON
   gtid_mode=ON
   bind-address=0.0.0.0

   ```
4. Redémarrer MySQL avec :
   ```sh
   net stop MySQL80
   net start MySQL80
   ```
5. Se connecter à MySQL :
   ```sh
   mysql -u root -p
   ```
6. Créer un utilisateur pour la réplication :
   ```sql
   CREATE USER 'replicator'@'192.168.1.77' IDENTIFIED BY 'password';
   GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'192.168.1.77';
   FLUSH PRIVILEGES;
   ```
7. Récupérer l’état du Master :
   ```sql
   SHOW MASTER STATUS;
   ```
   Notez le `File` et la `Position`.

## 4.b Configuration du Serveur Slave verdion binlog
1. Modifier le fichier `my.ini` sur le Slave, situé dans :
   ```
   C:\ProgramData\MySQL\MySQL Server X.X\my.ini
   ```
2. Ajouter ces lignes :
   ```ini
   [mysqld]
   server-id=2
   relay_log=mysql-bin
   read_only=ON
   super_read_only=ON

   ```
3. Redémarrer MySQL :
   ```sh
   net stop MySQL80
   net start MySQL80
   ```
4. Configurer la réplication :
   ```sql
   CHANGE MASTER TO
   MASTER_HOST='192.168.1.76',
   MASTER_USER='replicator',
   MASTER_PASSWORD='password',
   MASTER_LOG_FILE='TESS-bin.000013',
   MASTER_LOG_POS=1898;
   START SLAVE;
   ```
   Remplacez `MASTER_LOG_FILE` et `MASTER_LOG_POS` par les valeurs récupérées sur le Master.


## 4.a Configuration du Serveur Slave verdion GTID
1. Modifier le fichier `my.ini` sur le Slave, situé dans :
   ```
   C:\ProgramData\MySQL\MySQL Server X.X\my.ini
   ```
2. Ajouter ces lignes :
   ```ini
   [mysqld]
   server-id=3
   relay_log=mysql-relay-bin
   gtid_mode=ON
   enforce-gtid-consistency=ON
   read_only=ON
   super_read_only=ON


   ```
3. Redémarrer MySQL :
   ```sh
   net stop MySQL80
   net start MySQL80
   ```
4. Configurer la réplication :
   ```sql
   CHANGE MASTER TO 
   MASTER_HOST='192.168.1.76',
   MASTER_USER='replicator',
   MASTER_PASSWORD='password',
   MASTER_AUTO_POSITION=1;
   START SLAVE;

   ```
   Remplacez `MASTER_LOG_FILE` et `MASTER_LOG_POS` par les valeurs récupérées sur le Master.

## 5. Vérification de la Réplication
1. Vérifier le statut du Slave :
   ```sql
   SHOW SLAVE STATUS\G;
   ```
   Assurez-vous que `Slave_IO_Running: Yes` et `Slave_SQL_Running: Yes`.

2. Tester avec une table de test :
   **Sur le Master** :
   ```sql
   CREATE DATABASE test_replication;
   USE test_replication;
   CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100));
   INSERT INTO users (name) VALUES ('Alice');
   ```
   **Sur le Slave** :
   ```sql
   USE test_replication;
   SELECT * FROM users;
   ```
   Si la ligne `Alice` apparaît, la réplication fonctionne !
   ## Réplication Semi-Synchrone (Optionnelle)

    ````
     INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
     INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';
    ````

    ## La réplication synchrone n'est pas supportée nativement par MySQL
     ````
       Méthode 1 : Réplication Synchrone avec Galera Cluste
     ````


