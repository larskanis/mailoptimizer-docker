# Mailoptimizer in a docker image

Twiki: http://twiki/Comcard/MailOptimizer


## Build and run
```sh
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer-2023-03-10.zip .
rm -rf mo-installer
mkdir -p mo-installer
unzip -d mo-installer MO_Installer-2023-03-10.zip
rm MO_Installer-2023-03-10.zip
gem fetch mailoptimizer_server
docker-compose up --build
```

## Run as daemon and view the logs
```sh
docker-compose up -d
docker-compose logs -f
```

## Open browser interface

http://localhost:2511/mowebapp/

## save image to file
```sh
docker save mailoptimizer-docker_mailoptimizer | xz -T $(nproc) --fast > ~/L/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz
docker save mariadb:10.6 | xz -T $(nproc) --fast > ~/L/HSB-IN/Dev/post/mysql.tar.xz
```

## load image from file

On comdb2 in the mailoptimizer-docker root directory:
```sh
xz -d < ~/L/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz | docker load
xz -d < ~/L/HSB-IN/Dev/post/mysql.tar.xz | docker load
docker-compose up -d
mailoptimizer_client --server-version
```

On cppdb1 in the mailoptimizer-docker root directory:
```sh
xz -d < /production/data/cpp/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz | docker load
xz -d < /production/data/cpp/HSB-IN/Dev/post/mysql.tar.xz | docker load
docker-compose up -d
mailoptimizer_client --server-version
```

## Inspect the MYSQL database
```sh
docker exec -it mailoptimizer-docker-mysql-1 /bin/mysql mo
```

Passwortänderung weit in die Zukunft schieben:
```sh
docker exec -it mailoptimizer-docker_mysql_1 /bin/mysql mo --execute "update benutzer set PW_GEAENDERT='2054-01-12 12:16:38';"
```

### Abrechnungsnummer bzw. Letzteblattnummer übernehmen

Auf cppdb1:

Aus letzten Popwin-Aufbereitungen die Abrechnungsnummer für Inland und Ausland bestimmen. Hier z.B. bei eGK:

```sql
$ psql Produktion
Produktion=> SELECT MAX(opb_ktr), SUBSTRING(dv_filename,8,1) AS filetype, ('x'|| SUBSTRING(dv_dm_ascii,(6-1)*2+1,5*2))::bit(40)::bigint AS ekp, ('x'|| SUBSTRING(dv_dm_ascii,(20-1)*2+1,2))::bit(8)::int AS teiln, 'UPDATE KONTRAKT SET LETZTEBLATTNR=' || MAX(dv_abrnr) || ' WHERE KONTRAKTNUMMER=''' || ('x'|| SUBSTRING(dv_dm_ascii,(6-1)*2+1,5*2))::bit(40)::bigint || ''' AND VERFAHREN=''' || case SUBSTRING(dv_filename,8,1) when 's' then '50' when 'p' then '10' end || ''' AND TEILNAHME=''' || to_char(('x'|| SUBSTRING(dv_dm_ascii,(20-1)*2+1,2))::bit(8)::int, 'fm00') || ''';' AS update FROM egk_perso.cards WHERE poop_batch_id IS NOT NULL AND dv_dm_ascii IS NOT NULL GROUP BY dv_einlieferer, filetype, ekp, teiln  ORDER BY ekp, MAX(id) DESC;
```
Dann das Update-Statement nehmen und in Mailoptimizer als `LETZTEBLATTNR` eintragen:

```sql
$ docker exec -it mailoptimizer-docker-mysql-1 /bin/mysql mo
MariaDB [mo]> UPDATE KONTRAKT SET LETZTEBLATTNR=0888 WHERE KONTRAKTNUMMER='5045271907' AND VERFAHREN='10' AND TEILNAHME='02';

MariaDB [mo]> UPDATE KONTRAKT SET LETZTEBLATTNR=0025 WHERE KONTRAKTNUMMER='5045271907' AND VERFAHREN='50' AND TEILNAHME='01';

MariaDB [mo]> select * from KONTRAKT WHERE NAME REGEXP 'EWE';
+-------------+----------+----------------+-----------+-----------+---------+-------------+---------------+------------+-------------+
| KONTRAKT_ID | KUNDE_ID | KONTRAKTNUMMER | VERFAHREN | TEILNAHME | NAME    | KONTRAKTTYP | LETZTEBLATTNR | ERSTELLTAM | BENUTZER_ID |
+-------------+----------+----------------+-----------+-----------+---------+-------------+---------------+------------+-------------+
|          40 |        1 |     5045271907 | 50        | 01        | BKK EWE | 2           |            25 | NULL       |        NULL |
|         127 |        1 |     5045271907 | 10        | 02        | BKK EWE | 2           |           888 | NULL       |        NULL |
+-------------+----------+----------------+-----------+-----------+---------+-------------+---------------+------------+-------------+
```

## Update to new version of Mailoptimizer

```sh
wget https://www.tc.dpcom.de/downloads/_AutoUpdate_Mailoptimizer/MO_Installer.zip
cp MO_Installer.zip ~/I/PROG/_post/Mailoptimizer/MO_Installer-2023-03-10.zip
rm MO_Installer.zip
```

Then update the date stamps of the zip file in this README and run commands above to build and start a new docker image.
