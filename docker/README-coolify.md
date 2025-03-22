# Highlight.io Deployment mit Coolify

Diese Anleitung beschreibt, wie du Highlight.io mit Coolify deployen kannst.

## Voraussetzungen

- Ein Server mit installiertem Coolify
- Eine Domain, die auf deinen Server zeigt
- Grundlegende Kenntnisse über Docker und Coolify

## Setup-Schritte

### 1. Umgebungsvariablen anpassen

Bearbeite die `.env.coolify`-Datei und ändere mindestens die folgenden Werte:

- `REACT_APP_FRONTEND_URI`: Deine Domain ohne Protokoll (z.B. `highlight.example.com`)
- `REACT_APP_PRIVATE_GRAPH_URI`: Die URL für private API-Endpunkte (z.B. `https://highlight.example.com/private`)
- `REACT_APP_PUBLIC_GRAPH_URI`: Die URL für öffentliche API-Endpunkte (z.B. `https://highlight.example.com/public`)
- `PSQL_PASSWORD`: Ein sicheres Passwort für PostgreSQL
- `ADMIN_PASSWORD`: Das Admin-Passwort für die Highlight.io-Oberfläche
- `LICENSE_KEY`: (Optional) Dein Highlight.io-Lizenzschlüssel

### 2. In Coolify importieren

1. Öffne deine Coolify-Instanz
2. Erstelle ein neues Projekt
3. Wähle "Docker Compose" als Deployment-Typ
4. Wähle den "Raw Compose Deployment" Modus
5. Lade die `docker-compose-coolify.yaml` und `.env.coolify` Dateien hoch
6. Stelle sicher, dass die Umgebungsvariablen richtig geladen wurden
7. Deploye die Anwendung

### 3. Domain-Konfiguration

Coolify übernimmt die Konfiguration von Traefik als Reverse Proxy. Stelle sicher, dass:

- Deine Domain auf den Server zeigt, auf dem Coolify läuft
- SSL in Coolify aktiviert ist (sollte automatisch über Let's Encrypt funktionieren)

## Fehlerbehebung

### Bad Gateway Fehler

Falls du einen "Bad Gateway" Fehler erhältst:

1. Überprüfe, ob die Ports korrekt in der `expose`-Sektion definiert sind (nicht als `ports`)
2. Stelle sicher, dass die Backend-Services auf `0.0.0.0` und nicht nur auf `localhost` hören
3. Prüfe, ob deine Domain korrekt konfiguriert ist
4. Überprüfe die Logs der Container, um spezifische Fehler zu identifizieren

### SSL-Probleme

Bei Problemen mit SSL/HTTPS:

1. Überprüfe, ob die Traefik-Labels korrekt gesetzt sind
2. Stelle sicher, dass Let's Encrypt funktioniert (Domain muss öffentlich erreichbar sein)
3. Vergewissere dich, dass der Port 443 auf deinem Server nicht blockiert ist

## Support

Wenn du weitere Hilfe benötigst, besuche:

- [Highlight.io Dokumentation](https://www.highlight.io/docs)
- [Coolify Dokumentation](https://coolify.io/docs)
- [Coolify Troubleshooting Guide](https://coolify.io/docs/troubleshoot/applications/bad-gateway) 