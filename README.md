# Configuration des Instances MySQL : Master et Slave1

## 1. Installation de MySQL
Avant de commencer, assure-toi que MySQL est installé sur ton système.
```bash
sudo apt update && sudo apt install mysql-server -y
```

## 2. Création de l'Instance Master

### 2.1. Création du fichier de configuration du Master
Créer un fichier de configuration spécifique pour le master :
```bash
sudo nano /etc/mysql/my_master.cnf
```
Ajouter le contenu suivant :
```ini
[mysqld]
# Paramètres de base
port = 3307
datadir = /var/lib/mysql_master
log_bin = /var/log/mysql/mysql-bin.log
server-id = 1
bind-address = 127.0.0.1

# Fichier de socket et PID
socket = /var/run/mysqld/mysqld_master.sock
pid-file = /var/run/mysqld/mysqld_master.pid

# Désactiver le protocole X
mysqlx = 0

# Logs
log_error = /var/log/mysql/error_master.log
general_log_file = /var/log/mysql/mysql_master.log
general_log = 1

# Configuration InnoDB
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1
```

### 2.2. Création du service systemd pour le Master
```bash
sudo nano /etc/systemd/system/mysql-master.service
```
Ajouter le contenu suivant :
```ini
[Unit]
Description=MySQL Master Server
After=network.target

[Service]
ExecStart=/usr/sbin/mysqld --defaults-file=/etc/mysql/my_master.cnf
User=mysql
Group=mysql
Restart=always

[Install]
WantedBy=multi-user.target
```

### 2.3. Démarrage de l'instance Master
```bash
sudo systemctl daemon-reload
sudo systemctl enable mysql-master.service
sudo systemctl start mysql-master.service
sudo systemctl status mysql-master.service
```

## 3. Création de l'Instance Slave1

### 3.1. Création du fichier de configuration du Slave1
Créer un fichier de configuration spécifique pour le slave1 :
```bash
sudo nano /etc/mysql/my_slave1.cnf
```
Ajouter le contenu suivant :
```ini
[mysqld]
# Paramètres de base
port = 3308
datadir = /var/lib/mysql_slave1
log_bin = /var/log/mysql/mysql-bin.log
server-id = 3
bind-address = 127.0.0.1

# Fichier de socket et PID
socket = /var/run/mysqld/mysqld_slave1.sock
pid-file = /var/run/mysqld/mysqld_slave1.pid

# Désactiver le protocole X
mysqlx = 0

# Logs
log_error = /var/log/mysql/error_slave1.log
general_log_file = /var/log/mysql/mysql_slave1.log
general_log = 1

# Configuration InnoDB
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1
```

### 3.2. Création du service systemd pour le Slave1
```bash
sudo nano /etc/systemd/system/mysql-slave1.service
```
Ajouter le contenu suivant :
```ini
[Unit]
Description=MySQL Slave1
After=network.target

[Service]
ExecStart=/usr/sbin/mysqld --defaults-file=/etc/mysql/my_slave1.cnf
User=mysql
Group=mysql
Restart=always

[Install]
WantedBy=multi-user.target
```

### 3.3. Démarrage de l'instance Slave1
```bash
sudo systemctl daemon-reload
sudo systemctl enable mysql-slave1.service
sudo systemctl start mysql-slave1.service
sudo systemctl status mysql-slave1.service
```

## 4. Vérification des connexions aux instances

### Connexion au Master
```bash
mysql -u root -p -P 3307 -h 127.0.0.1
```

### Connexion au Slave1
```bash
mysql -u root -p -P 3308 -h 127.0.0.1
```

---

Tu as maintenant tes deux instances MySQL (Master et Slave1) configurées et fonctionnelles ! 🎉
La prochaine étape est la configuration de la réplication entre elles. 🚀

