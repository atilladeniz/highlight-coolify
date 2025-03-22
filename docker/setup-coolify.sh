#!/bin/bash -e

# Setup script for Coolify deployment of Highlight.io

# Farbdefinitionen für bessere Lesbarkeit
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Highlight.io Coolify Setup ===${NC}"
echo -e "${YELLOW}Dieses Skript richtet die Highlight.io Installation für Coolify ein${NC}"
echo ""

# Prüfen ob das aktuelle Verzeichnis ein Git-Repository ist
if [ ! -d .git ]; then
    echo "Fehler: Dieses Skript muss im Hauptverzeichnis des Highlight-Repositories ausgeführt werden."
    exit 1
fi

# Überprüfen ob docker installiert ist
if ! command -v docker &> /dev/null; then
    echo "Fehler: Docker ist nicht installiert. Bitte installiere Docker, bevor du fortfährst."
    exit 1
fi

# Verzeichnis erstellen für die notwendigen Dateien
mkdir -p coolify-setup

# .env.coolify kopieren oder erstellen wenn sie noch nicht existiert
if [ -f docker/.env.coolify ]; then
    cp docker/.env.coolify coolify-setup/.env
    echo "✅ .env.coolify in coolify-setup/.env kopiert"
else
    echo "⚠️ docker/.env.coolify nicht gefunden, erstelle Standard-Version..."
    cp docker/.env coolify-setup/.env
    echo "✅ .env erstellt, bitte passe die Werte an"
fi

# docker-compose-coolify.yaml kopieren
cp docker/docker-compose-coolify.yaml coolify-setup/docker-compose.yaml
echo "✅ docker-compose-coolify.yaml nach coolify-setup/docker-compose.yaml kopiert"

# Anleitung bereitstellen
echo ""
echo -e "${GREEN}=== Setup abgeschlossen ===${NC}"
echo -e "${YELLOW}Die Setup-Dateien befinden sich im Verzeichnis 'coolify-setup'${NC}"
echo ""
echo "Folge diesen Schritten, um die Installation in Coolify abzuschließen:"
echo ""
echo "1. Bearbeite die Datei 'coolify-setup/.env' und passe folgende Werte an:"
echo "   - REACT_APP_FRONTEND_URI (deine Domain ohne Protokoll)"
echo "   - REACT_APP_PRIVATE_GRAPH_URI und REACT_APP_PUBLIC_GRAPH_URI (komplette URLs)"
echo "   - PSQL_PASSWORD (sicheres Passwort für PostgreSQL)"
echo "   - ADMIN_PASSWORD (Admin-Passwort für die Web-Oberfläche)"
echo ""
echo "2. Lade beide Dateien (.env und docker-compose.yaml) in Coolify hoch:"
echo "   - Erstelle ein neues Projekt in Coolify"
echo "   - Wähle 'Docker Compose' als Deployment-Typ"
echo "   - Wähle 'Raw Compose Deployment' im Modus"
echo "   - Lade die Dateien hoch"
echo ""
echo "3. Stelle sicher, dass deine Domain auf den Server zeigt und deploye die Anwendung"
echo ""
echo -e "${GREEN}Viel Erfolg mit deiner Highlight.io Installation!${NC}" 