# Mailoptimizer als Docker-Image

Post: https://www.deutschepost.de/de/m/mailoptimizer.html<br>
Twiki: http://twiki/Comcard/MailOptimizer

Mailoptimizer lässt sich in einen Linux-Container packen und damit produktiv betreiben.
Benötigt wird:
- die MO_Installer ZIP-Datei (Download von https://www.tc.dpcom.de/downloads/_AutoUpdate_Mailoptimizer/MO_Installer.zip)
- eine gültige Lizenzdatei der Art `Mo_config_*.xml`

Bereitgestellt wird:
- Mailoptimizer Web-GUI: http://localhost:2511/mowebapp/
- REST-API: http://localhost:2511/mobackend/restapi/signin
- Proprietäre Dateiup- und Download-Schnittstelle über TCP port 8765 (wenn `WITH_CCRPC=1` bei docker-build angegeben wurde)

Features:
- Verwendet MariaDB als Datenbank
- Beachtung der Umgebungsvariablen `http_proxy` und `https_proxy`
- Import eines Unternehmenszertifikats für SSL-Verbindungen
- Spracheinstellung: Deutsch
- automatische Migration der verbundenen Datenbank und Dateien nach Update des Installers (siehe unten)

Funktionsweise:

Das Installationsverzeichnis `/opt/mailoptimizer/` wird als Volume behandelt und beim ersten Containerstart vom Installer befüllt.
Bei allen weiteren Starts erkennt der Installer, dass bereits eine Mailoptimizer-Version installiert ist und führt nur bei eventuellem Update des Installers ein Update der Verzeichnisse und der MySQL-Datenbank durch.

## Image bauen und starten

Ggf. den Pfad `~/I/PROG/_post/Mailoptimizer/` zum MO_Installer und Lizenz Datei anpassen.

```sh
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer-2024-06-11.zip .
cp ~/I/PROG/_post/Mailoptimizer/2022-02-23_Mo_config_15420_5046577760.xml .
rm -rf mo-installer
mkdir -p mo-installer
unzip -d mo-installer MO_Installer-2024-06-11.zip
rm MO_Installer-2024-06-11.zip
WITH_CCRPC=1 docker-compose up --build
```

## Als Daemon starten und Logs anschauen
```sh
docker-compose up -d
docker-compose logs -f
```

## Browser Interface öffnen

http://localhost:2511/mowebapp/

## Docker Images in Datei exportieren
Das gebaute Docker-Image kann exportiert werden und auf einem beliebigen anderen Rechner geladen werden.
Ebenso das MySQL-Image.

```sh
docker save mailoptimizer-docker_mailoptimizer | xz -T $(nproc) --fast > ~/L/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz
docker save mariadb:10.6 | xz -T $(nproc) --fast > ~/L/HSB-IN/Dev/post/mysql.tar.xz
```

## Docker Images aus Datei laden

On comdb2 in the mailoptimizer-docker root directory:
```sh
smbclient -k //comlx5/vol5/ -c "get HSB-IN/Dev/post/mailoptimizer-docker.tar.xz -" | xz -d | docker load
smbclient -k //comlx5/vol5/ -c "get HSB-IN/Dev/post/mysql.tar.xz -" | xz -d | docker load
docker-compose up -d
mailoptimizer_client --server-version
```
Now check out http://comopt1


On cppdb1 in the mailoptimizer-docker root directory:
```sh
xz -d < /production/data/cpp/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz | docker load
xz -d < /production/data/cpp/HSB-IN/Dev/post/mysql.tar.xz | docker load
docker-compose up -d
mailoptimizer_client --server-version
```
Now check out http://cppopt1


## MYSQL Datenbank anschauen
```sh
docker exec -it mailoptimizer-docker-mysql-1 /bin/mysql mo
```

Passwortänderung weit in die Zukunft schieben:
```sh
docker exec -it mailoptimizer-docker_mysql_1 /bin/mysql mo --execute "update benutzer set PW_GEAENDERT='2054-01-12 12:16:38';"
```

### Abrechnungsnummer bzw. Letzteblattnummer übernehmen

Auf comdb2 bzw. cppdb1 per SSH:

Aus letzten Popwin-Aufbereitungen die Abrechnungsnummer für Inland und Ausland bestimmen.
Dazu kann der letzte Einlieferungsbeleg verwendet werden oder man schaut in die jeweilige Datenbank nach der Abrechnungsnummer zu den Kontrakten.
Hier z.B. bei eGK-Datenbank wird gleich das komplette UPDATE-Statement generiert:

```sql
$ psql Produktion
Produktion=> SELECT MAX(opb_ktr), SUBSTRING(dv_filename,8,1) AS filetype, ('x'|| SUBSTRING(dv_dm_ascii,(6-1)*2+1,5*2))::bit(40)::bigint AS ekp, ('x'|| SUBSTRING(dv_dm_ascii,(20-1)*2+1,2))::bit(8)::int AS teiln, 'UPDATE KONTRAKT SET LETZTEBLATTNR=' || MAX(dv_abrnr) || ' WHERE KONTRAKTNUMMER=''' || ('x'|| SUBSTRING(dv_dm_ascii,(6-1)*2+1,5*2))::bit(40)::bigint || ''' AND VERFAHREN=''' || case SUBSTRING(dv_filename,8,1) when 's' then '50' when 'p' then '10' end || ''' AND TEILNAHME=''' || to_char(('x'|| SUBSTRING(dv_dm_ascii,(20-1)*2+1,2))::bit(8)::int, 'fm00') || ''';' AS update FROM egk_perso.cards WHERE poop_batch_id IS NOT NULL AND dv_dm_ascii IS NOT NULL GROUP BY dv_versender, filetype, ekp, teiln  ORDER BY ekp, MAX(id) DESC;
```
Dann das Update-Statement nehmen oder wie folgt anpassen und in Mailoptimizer als `LETZTEBLATTNR` eintragen:

```sql
$ docker exec -it mailoptimizer-docker-mysql-1 /bin/mysql mo
MariaDB [mo]> UPDATE KONTRAKT SET LETZTEBLATTNR=0888 WHERE KONTRAKTNUMMER='5012345678' AND VERFAHREN='10' AND TEILNAHME='02';

MariaDB [mo]> UPDATE KONTRAKT SET LETZTEBLATTNR=0025 WHERE KONTRAKTNUMMER='5012345678' AND VERFAHREN='50' AND TEILNAHME='01';

MariaDB [mo]> select * from KONTRAKT WHERE NAME REGEXP 'EWE';
+-------------+----------+----------------+-----------+-----------+---------+-------------+---------------+------------+-------------+
| KONTRAKT_ID | KUNDE_ID | KONTRAKTNUMMER | VERFAHREN | TEILNAHME | NAME    | KONTRAKTTYP | LETZTEBLATTNR | ERSTELLTAM | BENUTZER_ID |
+-------------+----------+----------------+-----------+-----------+---------+-------------+---------------+------------+-------------+
|          70 |        1 |     5012345678 | 50        | 01        | BKK EWE | 2           |            25 | NULL       |        NULL |
|         137 |        1 |     5012345678 | 10        | 02        | BKK EWE | 2           |           888 | NULL       |        NULL |
+-------------+----------+----------------+-----------+-----------+---------+-------------+---------------+------------+-------------+
```

## Update der Mailoptimizer-Version

```sh
wget https://www.tc.dpcom.de/downloads/_AutoUpdate_Mailoptimizer/MO_Installer.zip
cp MO_Installer.zip ~/I/PROG/_post/Mailoptimizer/MO_Installer-2024-06-11.zip
rm MO_Installer.zip
```

Dann die Zeitstempel der ZIP-Datei in dieser README anpassen und die obigen Kommandos zum Bauen und Starten eines neuen Docker Images ausführen.
Beim ersten Start des Containers wird das bestehende Datenbank-Schema vom Installer automatisch auf die neue Version migriert.

Bei der Update-Installation auf einem bestehenden Volume mit Mailoptimizer-5.7 auf 5.8 werden andere Fragen gestellt, als bei einer frischen Installation.
Deshalb funktioniert die Einrichtung in `startup.sh` nicht mehr und es kommt zu Fehlern.
Als Workaround kann hier die Update-Installation einmal händisch durchgeführt werden mit folgendem Befehl:
```sh
docker-compose run --rm -it mailoptimizer bash /mo-installer/Setup_MO_x32_x64.sh -c
```

Dann müssen die Fragen per Hand beantwortet werden (meist mit Enter oder "1" für die default-Einstellung).
Damit wird dann das Update ausgeführt und die weiteren Starts funktionieren anschließend wieder reibungslos.
