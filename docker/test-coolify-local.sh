#!/bin/bash -e

# Script zum lokalen Testen der Coolify-Konfiguration

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Lokaler Test für Highlight.io Coolify-Setup ===${NC}"
echo ""

# Prüfen ob im richtigen Verzeichnis
if [ ! -f "docker/docker-compose-coolify.yaml" ]; then
    echo -e "${RED}Fehler: Dieses Skript muss im Hauptverzeichnis des Highlight-Repositories ausgeführt werden.${NC}"
    exit 1
fi

# Prüfen ob docker installiert ist
if ! command -v docker &> /dev/null || ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Fehler: Docker und/oder Docker Compose ist nicht installiert.${NC}"
    exit 1
fi

# Testverzeichnis erstellen
TEST_DIR="docker/coolify-test"
mkdir -p $TEST_DIR

# Testspezifische docker-compose.yaml erstellen
cat > $TEST_DIR/docker-compose.yaml << EOL
version: '3'

# Highlight.io services for local testing
services:
  # Infrastructure services
  clickhouse:
    image: \${CLICKHOUSE_IMAGE_NAME}
    restart: on-failure
    ports:
      - "9000:9000"
    volumes:
      - clickhouse-data:/var/lib/clickhouse
    environment:
      - TZ=\${TZ}

  zookeeper:
    image: \${ZOOKEEPER_IMAGE_NAME}
    restart: on-failure
    ports:
      - "2181:2181"
    environment:
      - ZOOKEEPER_CLIENT_PORT=2181
      - ZOOKEEPER_TICK_TIME=2000
      - TZ=\${TZ}

  kafka:
    image: \${KAFKA_IMAGE_NAME}
    restart: on-failure
    ports:
      - "9092:9092"
    environment:
      - KAFKA_BROKER_ID=1
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_ADVERTISED_LISTENERS=\${KAFKA_ADVERTISED_LISTENERS}
      - KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
      - TZ=\${TZ}
    depends_on:
      - zookeeper

  postgres:
    image: \${POSTGRES_IMAGE_NAME}
    restart: on-failure
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=\${PSQL_PASSWORD}
      - POSTGRES_USER=\${PSQL_USER}
      - POSTGRES_DB=\${PSQL_DB}
      - TZ=\${TZ}

  redis:
    image: \${REDIS_IMAGE_NAME}
    restart: on-failure
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    environment:
      - TZ=\${TZ}

  collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    restart: on-failure
    ports:
      - "4318:4318"
    environment:
      - TZ=\${TZ}
    volumes:
      - ../../collector/otel-collector.yaml:/etc/otel/config.yaml

  predictions:
    build:
      context: ../..
      dockerfile: ./packages/predictions/predictions.Dockerfile
    restart: on-failure
    ports:
      - "5001:5001"
    environment:
      - TZ=\${TZ}
      
  # Application services
  backend:
    image: \${BACKEND_IMAGE_NAME}
    restart: on-failure
    ports:
      - "8082:8082"
    volumes:
      - highlight-data:/highlight-data
      - ../../backend/env.enc:/build/env.enc
      - ../../backend/env.enc.dgst:/build/env.enc.dgst
      - ../../backend/localhostssl/server.key:/build/localhostssl/server.key
      - ../../backend/localhostssl/server.crt:/build/localhostssl/server.crt
    env_file: .env
    depends_on:
      - clickhouse
      - kafka
      - postgres
      - redis
      - collector
      - predictions

  frontend:
    image: \${FRONTEND_IMAGE_NAME}
    restart: on-failure
    ports:
      - "3000:3000"
      - "6006:6006"
      - "8080:8080"
    volumes:
      - ../../backend/localhostssl/server.key:/etc/ssl/private/ssl-cert.key
      - ../../backend/localhostssl/server.pem:/etc/ssl/certs/ssl-cert.pem
    env_file: .env
    depends_on:
      - backend

volumes:
  highlight-data:
  clickhouse-data:
  postgres-data:
  redis-data:
EOL

# Test-spezifische .env-Datei erstellen
if [ -f "docker/.env.coolify" ]; then
    cp docker/.env.coolify $TEST_DIR/.env
    # Anpassen für lokalen Test
    sed -i.bak 's|REACT_APP_FRONTEND_URI=.*|REACT_APP_FRONTEND_URI=localhost|g' $TEST_DIR/.env
    sed -i.bak 's|REACT_APP_PRIVATE_GRAPH_URI=.*|REACT_APP_PRIVATE_GRAPH_URI=http://localhost:8082/private|g' $TEST_DIR/.env
    sed -i.bak 's|REACT_APP_PUBLIC_GRAPH_URI=.*|REACT_APP_PUBLIC_GRAPH_URI=http://localhost:8082/public|g' $TEST_DIR/.env
    sed -i.bak 's|KAFKA_ADVERTISED_LISTENERS=.*|KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092|g' $TEST_DIR/.env
    rm -f $TEST_DIR/.env.bak
    echo -e "${GREEN}✅ .env-Datei für lokalen Test angepasst${NC}"
else
    cp docker/.env $TEST_DIR/.env
    echo -e "${YELLOW}⚠️ docker/.env.coolify nicht gefunden, Standard-ENV wird verwendet${NC}"
fi

# Lokalen Test starten
echo -e "${GREEN}=== Starte lokalen Test ===${NC}"
echo -e "${YELLOW}Docker Compose wird im Test-Verzeichnis $TEST_DIR gestartet...${NC}"
echo "Zum Beenden: CTRL+C und dann 'docker compose -f $TEST_DIR/docker-compose.yaml down'"

cd $TEST_DIR
docker compose up

# Falls das Skript mit CTRL+C unterbrochen wird, alles aufräumen
trap 'echo -e "${YELLOW}Beende Dienste...${NC}"; docker compose down; echo -e "${GREEN}Aufräumen abgeschlossen!${NC}"' EXIT 