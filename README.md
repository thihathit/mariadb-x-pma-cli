# mariadb-x-pma

On-demand start/stop/status for **MariaDB** and **phpMyAdmin** — nothing runs
24/7, and nothing is registered to auto-start at login. You start them when
you want them.

## Install

```bash
./scripts/install.sh
```

This installs:

- `mariadb-x-pma` → `~/.local/bin/mariadb-x-pma` (symlink)
- `pma` → thin wrapper so existing `pma start|stop|status` keeps working
- `mariadb-start` / `mariadb-stop` / `mariadb-status` / `mariadb-restart`
  aliases appended to `~/.bash_aliases`

Run `source ~/.bash_aliases` in any already-open shell.

## Usage

```text
mariadb-x-pma mariadb start|stop|status|restart
mariadb-x-pma pma     start|stop|status|restart
mariadb-x-pma status                  # both at once
mariadb-x-pma serve                   # start both
mariadb-x-pma help
```

Examples:

```bash
mariadb-x-pma serve          # MariaDB + phpMyAdmin
mariadb-x-pma pma status     # is phpMyAdmin up? which port?
mariadb-x-pma mariadb stop   # shut MariaDB down again
```

## How it works

- **MariaDB** is managed through Homebrew `brew services` with the `run`
  variant (starts it without enabling auto-start at boot/login).
- **phpMyAdmin** is served by PHP's built-in web server on an automatically
  picked free port in `8080–9000`. The chosen port is saved in
  `/tmp/pma-port.flag` so restart/stop know where it lives.

## Configuration

Everything has a sane default and can be overridden via environment variables.

| Variable              | Default                                          |
| --------------------- | ------------------------------------------------ |
| `MARIADB_START_CMD`   | `brew services run mariadb`                      |
| `MARIADB_STOP_CMD`    | `brew services stop mariadb`                     |
| `MARIADB_STATUS_CMD`  | `brew services info mariadb`                     |
| `PMA_DOCROOT`         | `<brew --prefix>/share/phpmyadmin`               |
| `PMA_PHP`             | `php` on PATH, else `<brew --prefix>/bin/php`    |
| `PMA_BIND`            | `127.0.0.1`                                      |
| `PMA_STATE`           | `/tmp/pma-port.flag`                             |

Example:

```bash
PMA_DOCROOT=/custom/pma-docroot PMA_STATE=/tmp/my.pma.flag mariadb-x-pma pma start
```

## Tests

CI runs against real MariaDB + phpMyAdmin on Ubuntu (`.github/workflows/ci.yml`,
`tests/ci-test.sh`). No secrets required.

```bash
export PMA_DOCROOT=/opt/phpmyadmin PMA_PHP=php
bash tests/ci-test.sh
```

## Requirements

- `brew` (Homebrew) with MariaDB installed (`brew install mariadb`)
- `php` (phpMyAdmin's web server)
- phpMyAdmin installed as `share/phpmyadmin` under the Homebrew prefix

## License

MIT — see [LICENSE](LICENSE).