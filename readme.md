# Configuration MySQL Master-Slave avec Docker Compose

Ce document décrit les étapes pour mettre en place une réplication MySQL (master-slave) en utilisant Docker Compose et MySQL 8.0.

---

## Prérequis

- Docker et Docker Compose installés.
- Structure de répertoires recommandée :



---

## Fichier `docker-compose.yml`

Utilisez le fichier suivant pour définir vos services master et slave :

```yaml
version: '3.8'

services:
  mysql-master:
    image: mysql:8.0
    container_name: mysql-master
    environment:
      MYSQL_ROOT_PASSWORD: masterpass
      MYSQL_DATABASE: test_db
      MYSQL_USER: repl_user
      MYSQL_PASSWORD: repl_password
      MYSQL_ROOT_HOST: "%"
    ports:
      - "3306:3306"
    volumes:
      - ./master/conf:/etc/mysql/conf.d
      - ./master/data:/var/lib/mysql
    networks:
      - mysql-network
    command: --default-authentication-plugin=mysql_native_password --server-id=1 --log-bin=mysql-bin --binlog-format=ROW

  mysql-slave:
    image: mysql:8.0
    container_name: mysql-slave
    environment:
      MYSQL_ROOT_PASSWORD: slavepass
      MYSQL_DATABASE: test_db
      MYSQL_USER: repl_user
      MYSQL_PASSWORD: repl_password
      MYSQL_ROOT_HOST: "%"
    ports:
      - "3307:3306"
    volumes:
      - ./slave/conf:/etc/mysql/conf.d
      - ./slave/data:/var/lib/mysql
    networks:
      - mysql-network
    depends_on:
      - mysql-master
    command: --default-authentication-plugin=mysql_native_password --server-id=2 --relay-log=mysql-relay-bin

networks:
  mysql-network:
    driver: bridge

  
---

# Pour le Master (./master/conf/my.cnf)

[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW


##Pour le Slave (./slave/conf/my.cnf)
[mysqld]
server-id=2
relay-log=mysql-relay-bin

###Démarrage des Conteneurs


docker compose up -d


##connexion au master 
docker exec -it mysql-master mysql -uroot -pmasterpass

##creation du user de replication 
CREATE USER 'rep'@'%' IDENTIFIED WITH mysql_native_password BY 'root';
GRANT REPLICATION SLAVE ON *.* TO 'rep'@'%';
FLUSH PRIVILEGES;

##verification du statut du master 
SHOW MASTER STATUS;

###exemple de sortie 

+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000003 |      825 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+

##connexion sur le slave 

docker exec -it mysql-slave mysql -uroot -pslavepass

##configuration du slave 

STOP SLAVE;

CHANGE MASTER TO 
  MASTER_HOST='mysql-master', 
  MASTER_USER='rep', 
  MASTER_PASSWORD='root', 
  MASTER_LOG_FILE='mysql-bin.000003', 
  MASTER_LOG_POS=825;

START SLAVE;


##verification du staut du salve 
SHOW SLAVE STATUS\G;



##test sur le master 

USE test_db;
CREATE TABLE replication_test (
  id INT PRIMARY KEY AUTO_INCREMENT,
  message VARCHAR(255)
);
INSERT INTO replication_test (message) VALUES ('Hello from Master!');



##verification de replication sur le slave

USE test_db;
SELECT * FROM replication_test;


##POUR VOIR LE nom de l'instance sur la quelsje suis actuellemnt connecter
SELECT @@hostname;
+--------------+
| @@hostname   |
+--------------+
| 4604bb7d4bd1 |
+--------------+

requette pour voir le nom du conteneur 
docker ps --filter "id=4604bb7d4bd1" --format "table {{.ID}}\t{{.Names}}"
