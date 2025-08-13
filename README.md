# RL + BakkesMod launcher (Linux / Proton)

- Config: `~/RocketLeague/scripts/.rlbakkes.cfg`
- Logs:   `~/RocketLeague/scripts/logs/rl_bakkes_yyyymmdd.hhss.log`
- Works on Debian/Ubuntu/Pop!_OS, SteamOS (Deck), and other distros
- Ensures same Proton prefix; can install `vcrun2017` + BakkesMod (via protontricks)

## One-liners (per platform)

### Debian / Ubuntu / Pop!_OS
```bash
curl -fsSL https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main/installers/debian_install.sh | bash
```

### Steam Deck / SteamOS
```bash
curl -fsSL https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main/installers/steamdeck_install.sh | bash
```

### Other Linux
```bash
curl -fsSL https://raw.githubusercontent.com/DrBojanglez/rl-bakkes/main/installers/universal_install.sh | bash
```

### Flags
- `--debug`            dry-run (log commands; skip launch/inject/install)
- `--force-rediscover` ignore cached config; rediscover
- `--no-inject`        launch Rocket League only

If BakkesMod or `vcrun2017` are missing, the launcher offers to install them.
