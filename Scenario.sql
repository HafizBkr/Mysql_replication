# Guide Complet : Réponses aux Questions sur la Réplication MySQL

## Réplication basée sur les logs binaires (binlog)

### 1. Fichier binlog corrompu sur le maître

**Problème :**
- La réplication s'arrête sur tous les esclaves qui tentent de lire le fichier corrompu.

**Solution :**
1. Identifiez la dernière position valide sur l'esclave :
   ```sql
   SHOW SLAVE STATUS\G;
   ```
2. Démarrez la réplication depuis le point suivant :
   ```sql
   STOP SLAVE;
   CHANGE MASTER TO MASTER_LOG_FILE='next_binlog_file', MASTER_LOG_POS=4;
   START SLAVE;
   ```
3. En cas d'échec, reconstruisez l'esclave avec `mysqldump` ou via le clonage.

---

### 2. Esclave hors ligne pendant 3 jours, binlogs purgés

**Options pour resynchroniser :**
- Effectuer une resynchronisation complète avec `mysqldump --master-data=2`.
- Utiliser la commande `CLONE` de MySQL 8.0+.
- Utiliser Percona XtraBackup pour un backup à chaud.
- Restaurer une sauvegarde récente et configurer la réplication depuis la position correcte.
- Prévenir en augmentant `expire_logs_days` ou `binlog_expire_logs_seconds` sur le maître.

---

### 3. Identifier une transaction avec un lag de réplication

**Méthodes :**
- Utiliser `mysqlbinlog` :
  ```bash
  mysqlbinlog --start-position=1234 --stop-position=1334 /var/lib/mysql/mysql-bin.XXXXXX | grep -A 20 "# at 1234"
  ```
- Utiliser `SHOW BINLOG EVENTS` :
  ```sql
  SHOW BINLOG EVENTS IN 'mysql-bin.XXXXXX' FROM 1234 LIMIT 10;
  ```
- Examiner le journal des erreurs de l'esclave.

---

### 4. Erreur "Could not find first log file name in binary log index file"

**Causes possibles :**
- Fichier d'index des binlogs corrompu.
- Fichier binlog supprimé mais l'index non mis à jour.
- Problème de permission.

**Solution :**
1. Vérifiez les fichiers binlog :
   ```bash
   ls -la /var/lib/mysql/mysql-bin.*
   ```
2. Recréez l'index :
   ```sql
   FLUSH BINARY LOGS;
   ```
3. Réinitialisez la réplication :
   ```sql
   STOP SLAVE;
   CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.XXXXX', MASTER_LOG_POS=4;
   START SLAVE;
   ```

---

### 5. Erreur de duplication de clé primaire sur l'esclave

**Options :**
- Ignorer l'erreur spécifique :
  ```sql
  STOP SLAVE;
  SET GLOBAL sql_slave_skip_counter = 1;
  START SLAVE;
  ```
- Configurer pour ignorer certaines erreurs :
  ```sql
  slave_skip_errors = 1062;  # Erreur de clé dupliquée
  ```
- Résoudre manuellement le problème de données.

---

## Réplication GTID

### 1. Promotion d'un esclave en maître après panne du maître

**Étapes :**
1. Identifiez l'esclave le plus à jour avec `SHOW SLAVE STATUS\G`.
2. Sur l'esclave choisi :
   ```sql
   STOP SLAVE;
   RESET SLAVE ALL;
   SET GLOBAL read_only = OFF;
   ```
3. Sur les autres esclaves :
   ```sql
   STOP SLAVE;
   CHANGE MASTER TO MASTER_HOST='nouveau_maitre_ip', MASTER_USER='repl_user', MASTER_PASSWORD='password', MASTER_AUTO_POSITION=1;
   START SLAVE;
   ```

---

### 2. Erreur "GTID_NEXT has already been set"

**Solution :**
1. Vérifiez les transactions en cours :
   ```sql
   SHOW PROCESSLIST;
   ```
2. Terminez la transaction :
   ```sql
   ROLLBACK;
   ```
3. Redémarrez la réplication :
   ```sql
   STOP SLAVE;
   START SLAVE;
   ```

---

### 3. Erreur "The slave is connecting using GTID auto-positioning, but the master has purged binary logs"

**Solutions :**
- Réinitialiser la position GTID :
  ```sql
  STOP SLAVE;
  SET GLOBAL gtid_purged = 'gtid_set_du_maitre';
  START SLAVE;
  ```
- Reconstruire l'esclave via `mysqldump`, `CLONE`, ou Percona XtraBackup.

---

### 4. Sauter une transaction GTID problématique

**Commande :**
```sql
STOP SLAVE;
SET GTID_NEXT='uuid:transaction_id';
BEGIN; COMMIT;
SET GTID_NEXT='AUTOMATIC';
START SLAVE;
```
**Risques :**
- Incohérence potentielle.
- Problèmes de contraintes d'intégrité.

---

## Scénarios de panne générale

### 1. Identifier les transactions non répliquées après une panne du maître

**Avec GTID :**
```sql
SELECT GTID_SUBTRACT(@@GLOBAL.gtid_executed, 'gtid_executed_de_l_esclave');
```
**Avec binlog :**
```sql
SHOW SLAVE STATUS\G;
mysqlbinlog --start-position=X /var/lib/mysql/mysql-bin.XXXXX
```

---

### 2. Diagnostiquer un esclave avec un retard significatif

**Vérifications :**
- Ressources système : `top`, `htop`, `iostat`, `vmstat`
- Threads de réplication :
  ```sql
  SHOW PROCESSLIST;
  SHOW SLAVE STATUS\G;
  ```
- Paramètres importants :
  - `innodb_flush_log_at_trx_commit`
  - `sync_binlog`
  - `innodb_buffer_pool_size`
  - `slave_parallel_workers`
- Latence réseau

---

### 3. Reprise de la réplication après une coupure réseau

**Procédure :**
```sql
SHOW SLAVE STATUS\G;
STOP SLAVE;
START SLAVE;
```
**Prévention :**
```sql
slave_net_timeout = 60;
master_retry_count = 86400;
```

---

### 4. Minimiser les pertes de données lors d'une panne complète du maître

**Configuration de la réplication semi-synchrone :**
```sql
INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';
SET GLOBAL rpl_semi_sync_master_enabled = 1;
SET GLOBAL rpl_semi_sync_master_timeout = 10000; # 10 secondes
```

---

## Conclusion
Ce guide fournit des solutions pratiques pour gérer efficacement la réplication MySQL en cas de panne ou d'erreurs courantes.

