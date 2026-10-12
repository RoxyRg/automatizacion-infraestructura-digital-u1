#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
OUT="evidencias/salidas"
mkdir -p "$OUT"
C=(docker compose -f stack-aemf.yml)
log() { echo; printf '%s\n' "========== $* =========="; }
wait_http() {
  local url="$1" attempt
  for ((attempt=1;attempt<=40;attempt++)); do
    if curl --silent --fail --output /dev/null "$url"; then return 0; fi
    sleep 3
  done
  echo "ERROR: no responde: $url" >&2
  return 1
}
command -v docker >/dev/null || { echo "Falta instalar Docker Engine." >&2; exit 1; }
command -v curl >/dev/null || { echo "Falta instalar curl." >&2; exit 1; }
log "01 Versiones del entorno"
{ docker --version; docker compose version; git --version; } | tee "$OUT/01-versiones.txt"
log "02 Prueba hello-world"
docker run --rm hello-world | tee "$OUT/02-hello-world.txt"
log "03 Validacion YAML"
"${C[@]}" config | tee "$OUT/03-compose-config.txt" >/dev/null
log "04 Construccion y puesta en marcha (puede demorar varios minutos)"
"${C[@]}" up -d --build |& tee "$OUT/04-build-up.txt"
log "05 Estado de los contenedores"
"${C[@]}" ps | tee "$OUT/05-contenedores.txt"
log "06 Esperando backend y phpMyAdmin"
wait_http http://127.0.0.1:8080/
wait_http http://127.0.0.1:9090/
wait_http http://127.0.0.1/
log "07 Backend"
curl --silent --show-error --fail http://127.0.0.1:8080/ | tee "$OUT/06-backend.json"
log "08 Frontend (cabeceras HTTP)"
curl --silent --show-error --fail --head http://127.0.0.1/ | tee "$OUT/07-frontend-headers.txt"
log "09 phpMyAdmin (cabeceras HTTP)"
curl --silent --show-error --fail --head http://127.0.0.1:9090/ | tee "$OUT/08-phpmyadmin-headers.txt"
log "10 Comprobacion SQL / tablas / usuario"
docker exec mysql-db sh -c 'MYSQL_PWD=admin mysql -uadmin sistema_ventas_db -e "SHOW TABLES; SELECT username FROM tbl_usuario LIMIT 3;"' | tee "$OUT/09-mysql.txt"
log "11 Login API admin (token oculto en evidencia guardada)"
CODE=$(curl --silent --show-error --output "$OUT/.login-raw.json" --write-out '%{http_code}' --request POST \
  --header 'Content-Type: application/json' \
  --data '{"username":"admin","password":"12345678"}' \
  http://127.0.0.1:8080/api/auth)
python3 - "$CODE" "$OUT/.login-raw.json" "$OUT/10-login-sin-token.json" <<'PY'
import json, sys
status, raw, dest = sys.argv[1:]
with open(raw, encoding="utf-8") as f: data=json.load(f)
if status != '200' or not data.get('token'):
    raise SystemExit(f"ERROR: Inicio de sesión no comprobado (HTTP {status}, mensaje: {data.get('mensaje')}).")
data['token']='[OCULTO: token JWT vigente no debe publicarse]'
with open(dest,'w',encoding='utf-8') as f: json.dump({'http_status':int(status),'response':data}, f,ensure_ascii=False,indent=2)
print('Login correcto (HTTP 200). Se generó un JWT; se ocultó el token en el reporte.')
PY
rm -f "$OUT/.login-raw.json"
log "12 Logs recientes"
"${C[@]}" logs --no-color --tail 80 | tee "$OUT/11-logs.txt" >/dev/null
log "13 Estado final"
"${C[@]}" ps | tee "$OUT/12-estado-final.txt"
printf '\nLISTO: se ejecutaron las comprobaciones. Revisa archivos en %s\n' "$OUT"
printf 'IMPORTANTE: captura de pantalla manual de frontend, login y phpMyAdmin en evidencias/capturas.\n'
