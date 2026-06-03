# NetBox host config — seed files

These files are **installed by Ignition on first boot** (referenced from
`netbox.bu` via `contents.local: config/*.example`) to the rootless `netbox`
service account's home (`$HOME` = `/var/home/netbox`), with placeholder values.
The operator just **edits them in place** to real values and restarts the pod —
no manual `mkdir`/copy needed.

The quadlets bind-mount `%h/netbox/config` and read per-service env files from
`%h/netbox/env/`. So the runtime layout on the host is:

```
/var/home/netbox/netbox/
├── config/                 # bind-mounted to /etc/netbox/config (ro) in netbox + worker
│   └── configuration.py    # your real NetBox config
└── env/
    ├── netbox.env          # SECRET_KEY, DB_*, REDIS_* (netbox + worker)
    ├── postgres.env        # POSTGRES_PASSWORD
    ├── redis.env           # REDIS_PASSWORD
    └── redis-cache.env     # REDIS_PASSWORD (cache)
```

## Where Ignition installs each seed file

| Seed source (this dir)      | Installed on the host (owned by `netbox`)           |
| --------------------------- | --------------------------------------------------- |
| `configuration.py.example`  | `$HOME/netbox/config/configuration.py` (0644)       |
| `netbox.env.example`        | `$HOME/netbox/env/netbox.env` (0600)                |
| `postgres.env.example`      | `$HOME/netbox/env/postgres.env` (0600)              |
| `redis.env.example`         | `$HOME/netbox/env/redis.env` (0600)                 |
| `redis-cache.env.example`   | `$HOME/netbox/env/redis-cache.env` (0600)           |

## First-boot setup (as the netbox user)

The placeholder files are already in place, so just edit them and restart:

```sh
sudo machinectl shell netbox@        # or: sudo -u netbox -i
$EDITOR ~/netbox/env/netbox.env      # and the other env files + config
systemctl --user restart netbox-pod  # pod crash-loops on placeholders until edited
```

Until the placeholders are replaced, the pod will fail to start (bad
credentials / `changeme` secret key). Edit, then restart or reboot.

## Notes

- The pod shares one network namespace, so containers reach each other over
  `localhost` (postgres `5432`, redis `6379`, redis-cache `6380`).
- Passwords must match across files: `DB_PASSWORD` (netbox.env) ==
  `POSTGRES_PASSWORD` (postgres.env); `REDIS_PASSWORD` (netbox.env) ==
  `REDIS_PASSWORD` (redis.env); `REDIS_CACHE_PASSWORD` (netbox.env) ==
  `REDIS_PASSWORD` (redis-cache.env).
- `DB_USER`, `REDIS_CACHE_PORT`, `CORS_ORIGIN_ALLOW_ALL`, `POSTGRES_DB`,
  `POSTGRES_USER` are set directly in the quadlets — keep them out of the env
  files to avoid conflicting definitions.
