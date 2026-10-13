#!/usr/bin/env bash
# Prueba complementaria para esta actividad: no modifica el stack principal.
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
NET=aemf-u1-red-prueba
DB=aemf-u1-mysql-prueba
BACK=aemf-u1-back-prueba
IMAGE=sistema-ventas-back:unidad1

for name in "$DB" "$BACK"; do
  if docker container inspect "$name" >/dev/null 2>&1; then
    echo "Ya existe el contenedor $name. Revisa su estado antes de repetir la prueba." >&2
    exit 1
  fi
done
if docker network inspect "$NET" >/dev/null 2>&1; then
  echo "Ya existe la red $NET. Revisa su estado antes de repetir la prueba." >&2
  exit 1
fi
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "No encuentro la imagen $IMAGE. Primero construye el backend con Docker Compose." >&2
  exit 1
fi
for f in dbfiles/sistema_ventas_db_rev1.1.sql dbfiles/02_mysql_native_auth.sql; do
  [[ -f "$f" ]] || { echo "Falta el archivo $f" >&2; exit 1; }
done

echo '=== 1. Creando red temporal aislada ==='
docker network create "$NET"
echo '=== 2. Iniciando MySQL nuevo sin publicar puertos ==='
docker run --rm -d \
  --name "$DB" \
  --network "$NET" --network-alias mysql-db \
  -e MYSQL_ROOT_PASSWORD=qwerty \
  -e MYSQL_DATABASE=sistema_ventas_db \
  -e MYSQL_USER=admin -e MYSQL_PASSWORD=admin \
  -v "$PWD/dbfiles/sistema_ventas_db_rev1.1.sql:/docker-entrypoint-initdb.d/01_sistema_ventas_db.sql:ro" \
  -v "$PWD/dbfiles/02_mysql_native_auth.sql:/docker-entrypoint-initdb.d/02_mysql_native_auth.sql:ro" \
  mysql:8.0

echo '=== 3. Esperando a que termine la inicialización ==='
ready=0
for attempt in $(seq 1 90); do
  if docker exec -e MYSQL_PWD=qwerty "$DB" mysql -uroot -h 127.0.0.1 -N -e 'SELECT 1' >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 3
done
if [[ "$ready" != 1 ]]; then
  echo 'MySQL no inició a tiempo. Revisa: docker logs aemf-u1-mysql-prueba' >&2
  exit 1
fi

echo '=== 4. Tablas y usuario del sistema de ventas ==='
docker exec -e MYSQL_PWD=admin "$DB" mysql -h 127.0.0.1 -uadmin -D sistema_ventas_db \
  -e 'SHOW TABLES; SELECT username FROM tbl_usuario;'
tables=$(docker exec -e MYSQL_PWD=admin "$DB" mysql -N -h 127.0.0.1 -uadmin -D sistema_ventas_db \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='sistema_ventas_db';")
if [[ "$tables" != 8 ]]; then
  echo "ERROR: esperaba 8 tablas y encontré $tables" >&2
  exit 1
fi

echo '=== 5. Método de autenticación del usuario admin ==='
docker exec -e MYSQL_PWD=qwerty "$DB" mysql -uroot -h 127.0.0.1 \
  -e "SELECT User,Host,plugin FROM mysql.user WHERE User='admin';"
plugin=$(docker exec -e MYSQL_PWD=qwerty "$DB" mysql -N -uroot -h 127.0.0.1 \
  -e "SELECT plugin FROM mysql.user WHERE User='admin' AND Host='%';")
if [[ "$plugin" != mysql_native_password ]]; then
  echo "ERROR: plugin de admin inesperado: $plugin" >&2
  exit 1
fi

echo '=== 6. Probando una instancia independiente del backend ==='
docker run --rm -d --name "$BACK" --network "$NET" "$IMAGE"
backend_ok=0
for attempt in $(seq 1 30); do
  if docker exec "$BACK" node -e "require('http').get('http://127.0.0.1:3000/',r=>{console.log('Backend HTTP:',r.statusCode);r.resume();process.exit(r.statusCode===200?0:1)}).on('error',()=>process.exit(1))" 2>/dev/null; then
    backend_ok=1
    break
  fi
  sleep 2
done
if [[ "$backend_ok" != 1 ]]; then
  echo 'ERROR: backend no respondió HTTP 200 con MySQL temporal.' >&2
  docker logs --tail 25 "$BACK" || true
  exit 1
fi

echo '=== 7. Estado de la prueba aislada ==='
docker ps --filter "name=aemf-u1-" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo 'PRUEBA CORRECTA: 8 tablas, plugin mysql_native_password, backend HTTP 200.'
echo 'GUARDA CAPTURA AHORA. Después detén solo estos recursos temporales:'
echo 'docker stop aemf-u1-back-prueba aemf-u1-mysql-prueba'
echo 'docker network rm aemf-u1-red-prueba'
