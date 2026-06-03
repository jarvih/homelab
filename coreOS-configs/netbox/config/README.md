# NetBox host config — seed files

Ignition installs these on first boot (referenced from `netbox.bu` via
`contents.local:`) to the rootless `netbox` service account's home
(`$HOME` = `/var/home/netbox`). Two kinds of seed:

- **`configuration.py`** — seeded ready-to-use (it holds no secrets; every value
  comes from the env files).
- **`*.env.example`** — seeded as **templates only**, keeping the `.example`
  suffix. The real `*.env` files are *not* shipped, so no placeholder secrets
  ever land on disk. The operator copies each template to its real name and fills
  it in. Each quadlet carries `ConditionPathExists=%h/netbox/env/<file>.env`, so
  a service stays **inert** (systemd skips it, no crash-loop) until its real env
  file exists.

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

| Seed source (this dir)      | Installed on the host (owned by `netbox`)              |
| --------------------------- | ------------------------------------------------------ |
| `configuration.py.example`  | `$HOME/netbox/config/configuration.py` (0644)          |
| `netbox.env.example`        | `$HOME/netbox/env/netbox.env.example` (0600)           |
| `postgres.env.example`      | `$HOME/netbox/env/postgres.env.example` (0600)         |
| `redis.env.example`         | `$HOME/netbox/env/redis.env.example` (0600)            |
| `redis-cache.env.example`   | `$HOME/netbox/env/redis-cache.env.example` (0600)      |

## First-boot setup (as the netbox user)

The services won't start until the real `*.env` files exist. Copy each template,
fill in real secrets, then start the pod:

```sh
sudo machinectl shell netbox@        # or: sudo -u netbox -i
cd ~/netbox/env
for s in netbox postgres redis redis-cache; do cp "$s.env.example" "$s.env"; done
$EDITOR netbox.env postgres.env redis.env redis-cache.env  # set matching secrets
systemctl --user start netbox-pod    # or: daemon-reload then start the services
```

Before the real `*.env` files exist, `ConditionPathExists=` makes systemd skip
each service (shown as "condition failed" — not a failure, no restart loop), so
NetBox never comes up on placeholder secrets. After creating them, `systemctl
--user daemon-reload` (Quadlet regen) and start, or just reboot.

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
