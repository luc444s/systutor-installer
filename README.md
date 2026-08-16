# systutor-installer

Installer de SYSTUTOR: monta el kernel (`systutor-core`) y el frontend core (`systutor-shell`) en un proyecto nuevo o existente.

**Portable**: Linux x86, ARM y Termux (Android). Solo requiere `git`, `python3`, `pip` y `npm`.

## Uso

```bash
# ejecutar SIEMPRE con bash explicito (compatible Termux y linux)
bash install.sh /ruta/al/proyecto
```

Dentro de un repo git:

```bash
./install.sh                          # kernel + shell
./install.sh --core                   # solo kernel
./install.sh --shell                  # solo shell
./install.sh --web-dir frontend       # web dir distinto de apps/web
./install.sh --check-arch             # diagnostico del entorno
./install.sh --dry-run                # imprime sin ejecutar
```

## Que hace

1. `git submodule add` de `systutor-core` y `systutor-shell` en `vendor/`
2. Kernel: `pip install -e vendor/systutor-core` (paquete real, importable como `systutor.*`)
3. Shell: inyecta alias `@systutor/shell` en `vite.config.ts` + `paths` en `tsconfig.json` (ruta relativa calculada segun profundidad del web dir)
4. Instala peer deps npm del shell
5. Imprime pins de submodules al final

Idempotente: volver a correr no duplica configuracion.

## Termux (Android)

Termux usa **bionic**, no glibc — no se instala glibc. La unica dependencia C del stack (`asyncpg`, kernel) compila de fuente contra bionic:

```bash
pkg install clang postgresql
```

`install.sh --check-arch` detecta Termux y avisa si faltan.

## Licencia

MIT
