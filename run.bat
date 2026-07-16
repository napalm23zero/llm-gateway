@echo off
setlocal

REM Always operate from the repo root, no matter where the script is called from.
cd /d "%~dp0"

REM Prereq: Docker must be running. Fail loud and readable, not cryptic.
docker info >nul 2>&1
if errorlevel 1 (
  echo Docker is not running. Start Docker Desktop and try again. 1>&2
  exit /b 1
)

REM Bring the stack up in dev mode: production-shaped base + dev overlay
REM (hot-reload, source bind mount, published port). Foreground so you see the
REM logs; Ctrl-C stops it.
REM ponytail: minimal up-only. Add health-wait/URL print when detached, and
REM down/reset subcommands when stateful services (postgres, redis) land.
docker compose -f .docker\docker-compose.yml -f .docker\docker-compose.dev.yml up --build
