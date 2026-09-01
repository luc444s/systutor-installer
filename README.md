# systutor-installer

CLI para instalar tu set de programación completo: herramientas de desarrollo, systutor (core + shell + web), ADD, base de datos y dotfiles.

**Portable**: Linux x86/ARM, macOS, Termux (Android). Sin dependencias GNU.

## Instalación rápida

```bash
git clone https://github.com/luc444s/systutor-installer.git
cd systutor-installer
bash install.sh all          # instala todo (perfil full) en el directorio padre
```

`all` instala tools, dotfiles, systutor, ADD y deja el proyecto listo con base, migraciones y seed inicial.

## Comandos

```bash
./install.sh systutor [ruta]        # instalar systutor-core + systutor-shell
./install.sh add [install|list]     # instalar Atomic-Driven-Development
./install.sh tools                  # instalar tools de dev (perfil dev)
./install.sh tools --profile full   # instalar tools full
./install.sh dotfiles install       # instalar configuraciones de shell
./install.sh all                    # instalar todo junto
./install.sh diag                   # diagnostico del entorno
```

## Herramientas

```bash
./install.sh tools --list                    # ver tools disponibles
./install.sh tools --only docker git jq      # instalar tools específicas
./install.sh --dry-run tools --profile full  # preview sin ejecutar
```

### Perfiles

| Perfil | Tools |
|--------|-------|
| `dev` | git, python3, pip, node, npm, curl, wget, build-essential, jq, tree, unzip |
| `full` | dev + docker, docker-compose, htop, zellij, tmux |
| `minimal` | git, python3, pip, node, npm, curl |

## Systutor

Dentro de un repo git:

```bash
./install.sh systutor                    # kernel + shell
./install.sh systutor --core             # solo kernel
./install.sh systutor --shell            # solo shell
./install.sh systutor --web-dir frontend # web dir custom
```

Qué hace:
1. Clona `apps/web` y los vendors `systutor-core`, `systutor-shell`, `systutor-themes`
2. Kernel: `pip install -e vendor/systutor-core` dentro de `.venv`
3. Frontend: `npm install --no-package-lock` en `apps/web`
4. Base de datos: crea la DB `systutor` (o la que definas en `SYSTUTOR_DATABASE_URL`), ejecuta `alembic upgrade head`, valida la conexión y siembra el usuario base
5. Genera scripts raíz `frontend`, `services`, `db`, `dev` y `typecheck`

Credenciales base:
- `admin@example.com`
- `ChangeMe123!`

Variables útiles:
- `SYSTUTOR_DATABASE_URL` para apuntar a otra base
- `SYSTUTOR_CORE_URL`, `SYSTUTOR_SHELL_URL`, `SYSTUTOR_THEMES_URL`, `SYSTUTOR_DASHBOARD_URL`

## ADD (Atomic-Driven-Development)

Dentro de un repo git:

```bash
./install.sh add install   # clona ADD en la raíz del proyecto
./install.sh add update    # actualiza ADD
./install.sh add skills    # lista skills disponibles
./install.sh add list      # ver skills
```

Skills incluidos: atomizer-add, ci-wrapper-add, composer-gate-add, extreme-poverty-add, gitflow-full-add, gitflow-lite-add, verify-binding-add.

## Dotfiles

```bash
./install.sh dotfiles install   # clonar e instalar
./install.sh dotfiles update    # actualizar configs
./install.sh dotfiles list      # ver archivos incluidos
```

## Opciones globales

| Flag | Descripción |
|------|-------------|
| `--dry-run` | Mostrar qué se haría sin ejecutar |
| `--force` | No pedir confirmaciones |
| `--verbose` | Salida detallada |

## Scripts generados

```bash
npm run frontend  # instala deps web si faltan y arranca Vite
npm run services   # activa .venv y arranca uvicorn
npm run db         # crea/valida DB, migra y siembra datos base
npm run dev        # arranca services + frontend
```

## Base de datos

Por defecto usa `postgresql+psycopg://postgres:postgres@localhost:5432/systutor`.

Si la base no existe, el instalador la crea. Luego aplica migraciones y siembra:
- tenant demo
- branch principal
- rol admin
- usuario base `admin@example.com`

## Variables de entorno

```bash
SYSTUTOR_CORE_URL=https://...     # URL custom del repo core
SYSTUTOR_SHELL_URL=https://...    # URL custom del repo shell
SYSTUTOR_DOTFILES_URL=https://... # URL custom del repo dotfiles
SYSTUTOR_ADD_URL=https://...      # URL custom del repo ADD
```

## Termux (Android)

```bash
pkg install clang postgresql    # para compilar asyncpg
```

## Nota

`tools` puede intentar instalar `build-essential` con `sudo`. En entornos no interactivos puede fallar y no bloquea el resto del flujo de `systutor`.

## Licencia

MIT
