# Matriz de cumplimiento actualizada - Unidad I

**Fuente:** rúbrica de seis páginas y las siete capturas reales enviadas por el estudiante el 12 de octubre de 2026. **Criterio:** una captura únicamente demuestra lo que aparece en ella. No se presume la instalación de herramientas ni la entrega en GitHub.

| Requisito | Estado respaldado por la evidencia | Qué resta |
|---|---|---|
| Docker Engine y hello-world | VERIFICADO: terminal con `Hello from Docker!` | Guardar captura en repositorio |
| YAML Compose | VERIFICADO: `docker compose ... config -q` sin error; servicios activos en salida de terminal | Agregar captura `docker compose ps -a` para documentación exhaustiva |
| MySQL 8.0 | VERIFICADO: `mysql-db` healthy, `sistema_ventas_db` visible | Opcional: captura de tablas expandidas y salida `SHOW TABLES` |
| Backend Node 18.17.1-alpine | VERIFICADO: construido, recuperado de error 500, HTTP 200 | Evidencia del `Dockerfile` con versión |
| Frontend Nginx stable-alpine | VERIFICADO: página y sesión administrativa | Evidencia del `Dockerfile` |
| phpMyAdmin | VERIFICADO: captura de acceso y de base en servidor mysql-db | Ninguno para funcionalidad básica |
| VS Code, extensiones Docker/YAML/Git | VERIFICADO: captura con VS Code 1.141.0 y lista de extensiones (Docker, Containers, YAML, GitLens) | Opcional: captura de VS Code abierto en la sección Extensiones |
| Git y GitHub | Git 2.43.0 acreditado por captura; clonación del repositorio docente comprobada | Publicar README y adjuntar enlace en GitHub propio |
| Introducción, descripción, conclusión, bibliografía | REDACTADO en README y PDF | Revisión final de formato por docente |
| Portada | COMPLETA: datos UTNG, grupo GIRI6091, control 1223100825, logo entregado | No falta información de identificación |
| Reproducibilidad al partir de volumen nuevo | NO VERIFICADO | Incorporar SQL correctivo a YAML y probar en proyecto aislado, sin borrar volumen actual |
| SER: asistencia y portafolio | PERSONAL | Confirmación del estudiante/docente |

**Observación:** la ejecución manual de ALTER USER en MySQL del laboratorio corrigió `ER_NOT_SUPPORTED_AUTH_MODE`; no demuestra automáticamente la correcta inicialización con volumen vacío.

**Nueva evidencia:** `evidencias/capturas/07_versiones_y_extensiones.png` muestra versiones y complementos instalados. No acredita la ejecución de una reinstalación, y no se debe describir como tal.
