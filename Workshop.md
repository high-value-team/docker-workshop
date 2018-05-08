
# Docker Intro 

## Folie 1 (Docker Logo)

### Was ist Docker?
* Virtualisierungstechnologie
* Prozesse werden in abgekapselten Umgebungen ausgeführt (Container)
* Container können überall gleich ausgeführt werden 
* => Unabhängigkeit: Lokal, Rechenzentrum, Cloud, Kunde

## Folie 2 (Virtualisierung)

### Entwicklung der Virtualisierung
* Historisch hat sich die Technologie dahingehend entwickelt, Sachen zu virtualisieren (Betriebsysteme, Programme, Prozesse, Resourcen - CPU/RAM/HD).
* um Kopplungen, Abhängigkeiten zu lösen
* Beispiel:
* Bare Metal Server: alles auf einem Server installiert (manuelles Einloggen, Hardwareausfälle, Wartungszeiten, "never touch a running system")
* Virtuelle Server: Hardware anhand von Software abstrahiert (VMWare, VirtualBox - Resourcen zuweisen, Snapshots, Überall lauffähig, fat client)
* Container: Prozesse laufen in ihrer eigenen Umgebung, nur noch was nötig ist. Es lädt dazu ein, alles kleiner zu machen (Anwendung, Betriebssystem), schlank

## Folie 3 (Architektur)

### Welche Vorteile bietet Docker?

Transparez:
* Was wurde installiert?
* Wie wurde konfiguriert?
* Das Wissen aus den Köpfen der Entwickler auf Pappier gebracht. (weniger: Fragen/Ablenkung/Wissensinseln)
* Versionierungsfähigkeit

Automatisierung:
* einheitliches Format/Prozess
* => Schritte automatisieren
* => kleinere Wartungsfenster

Ausfallsicherheit:
* Risiko auf viele Server verteilen
* Skallierung

## Folie 4 (Begriffe)

### Wichtigsten Docker-Begriffe

Image
* da ist das ganze Betriebssystem drin (Filesystem, Applikationen, Netzwerk, usw)
* gebrannte CD, startbar => gestartet ist es ein Container
* Objektorientierung: Klasse (image), Instanz (container) - runtime objekt
* Snapshot eines laufenden Containers, als Grundlage für andere Images

Container
* ein laufendes Betriebssystem
* wie ein eigener Rechner, gecloned von einem Image
* beliebig viele Instanzen können laufen, alle vom gleichen Ursprung

Dockerfile
* Bauplan für ein Image, Instalationsskript, Drehbuch das abgearbeitet wird
* setzt den Rechner auf + Snapshot (eingefroren => image)
* "Infrastructure as Code" - Definierung der Infrastruktur (vollständig gescripted, automatisch vs manuell)
* Hardware ist jetzt komplett weg (keine Fernsteuerung, alles Software)

Registry:
* Zentrale Verwaltung mit Namen
* Snapshots als Binaries
* Standart Öffentlich (DockerHub), Lokal, auf eigenem Server, Dienstleister in der Cloud


## Folie 5 (Schichten)

Dockerfile Aufbau (Folie 5)
* Schichtweiser Aufbau
* Objektorientierung: Vererbung (einfach)
* wo greife ich rein?
* Was nutze ich als Basis? (=> Applikation nur für den Kunden)
* Beispiel: DockerHub https://hub.docker.com/_/mono/


# Docker Showcase

rancher: http://18.194.160.191:8080/
* Orchestrierung, Verwaltung von Containern 
* Wie stehen diese zueinander? Applikation mit mehreren Services (Frontend, Backend, Datenbank)

Infrastruktur:
* eigenes Rechenzentrum, Cloud (AWS, Google, Telekom)
* Resourcen (CPU, RAM, Speicher, IP)

Stacks:
* viele Container ergeben eine Applikation (Klammer) 
* Wie stehen diese Zueinander?
* Skallierung
* Config export (docker-compose.yml, rancher-compose.yml)
* vorgefertigte Stacks (MongoDB Replikaset, Versionsverwaltung - Git, Wiki, Webserver, Geheimnisse ablegen)

Container:
* Logs
* Shell

Ausblick:
* unabhängig vom Rechner (völlig egal)
* ist das nicht eine wahre Freude?
* das können Sie jetzt nur mal grob verstehen
* Was halten Sie davon das ganze jetzt mal selber zu machen? 


# Hands-On

TeamViewer session auf meinem Rechner. Teilnehmer kann bei mir tippen.

### Hello World!
4. Hello-world ausführen: `docker run hello-world`
	* Image wird heruntergeladen
	* Container wird gestartet
	* Im Container läuft sofort ein Skript
4. Images listen: `docker images`
5. Hello-world nochmal ausführen
	* Es wird kein Image mehr heruntergeladen!
6. Docker-Kommando Namespaces einführen: `docker container`, `docker image`.

### Mono
8. `docker container run mono`  - Image wird runtergeladen und läuft, aber es passiert nichts.
9. `docker container ls` - es laufen keine Container
10. `docker image ls` - unterschiedliche Image-Größen
11. `docker container run -it mono` - Mono interaktiv starten
12. `ls` - es wird das Verz im Container gelistet
13. `csc` - C# Compiler starten
14. C# Programm schreiben. Mit `Ctrl-D` abschließen.
```
cat > hello.cs
class Program {
  public static void Main() {
    System.Console.WriteLine("hello world");
  }
}
```
14. `csc hello.cs`
15. `mono hello.exe`
16. `exit`

### Container wiederverwenden
18. `docker container run -it mono` - nochmal starten; Quelldatei und Compilat sind weg!
19. `docker container run mono ls -l` - Container starten und sofort ein Kommando ausführen
20. `docker container ls --all` - Alle Container listen, die je gelaufen sind
21. `docker start <alter container mit csharp source>`  - das kann einen kleinsten Moment dauern
21. `docker exec -it <alter container mit csharp source>` 
	1. `ls` - die Source ist noch da
	2. `mono hello.exe` 
	3. `exit`
22. `docker exec <alter container> mono hello.exe` - die Anwendung wird ausgeführt
23. `docker stop <alter container>`

### Images selber bauen
23. `docker container commit <alter container> hello` - ein image von einem Container erstellen
	1. `docker image ls`
24. `docker run hello mono hello.exe` - Container von neuem Image erstellen und ausführen

#### Dockerfile
26. `Dockerfile` erstellen
```
FROM hello
ENTRYPOINT mono hello.exe
```
	1. `docker build --tag hello2 .` - neues Image erstellen; das kann etwas dauern… am Ende ist das Image so groß wie das Mono Image
	2. `docker image ls`
	3. `docker run hello2` - es wird das Csharp Programm sofort ausgeführt

### Dateien in einen Container kopieren
1. `csc hello3.cs` erzeugt `hello3.exe` auf dem Host-Rechner; das kann auch mit VS gemacht werden; EXE im Verzeichnis des Dockerfile ablegen.
2. Dockerfile ändern:
```
FROM hello
COPY hello3.exe /
ENTRYPOINT mono hello3.exe
```
3. `docker build --tag hello3 .`
4. `docker image ls`
5. `docker run hello3` - es wird das Hello-World-Programm sofort ausgeführt
6. `hello3.cs` - Versionsnr ändern und neue Datei speichern
7. Dockerfile ändern
```
FROM hello
COPY hello4.cs /
RUN csc hello4.cs
ENTRYPOINT mono hello4.exe
```
8. `docker build --tag hello4 .`
9. `docker run hello4`

### Ausführung parametrisieren
1. `hellov5.cs` ändern, so dass ein Name von der Cmdzeile gelesen wird:
```
class Program {
	public static void Main(string[] args) {
		System.Console.WriteLine("Hello, {0}! v5", args[0]);
	}
}
```
2. `Dockerfile` ändern, damit Kommandozeilenparam vom Dockeraufruf übernommen wird:
```
FROM hello
COPY hello5.cs /
RUN csc hello5.cs
ENTRYPOINT ["mono", "hello5.exe"]
```
3. `docker build --tag hello5 .`
4. `docker run hello5 florian`

### Environment-Variablen
1. Dockerfile ändern:
```
FROM hello
COPY hello6.cs /
RUN csc hello6.cs
ENV NAME World
ENTRYPOINT mono hello6.exe $NAME
# ENTRYPOINT ["sh", "-c" "mono hello6.exe $NAME"]
```
2. `docker build --tag hello6 .`
3. `docker run hello6`  - Begrüßung mit „World“
4. `docker run -e "NAME=Florian" hello6` - Begrüßung mit „Florian“

