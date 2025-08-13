These scripts are for maintainers:

- `apply_rev2.sh` – replaces core + launchers with the “rev2” versions (handles missing RL install, layout‑resilient).
- `patch_installers_strip_dashdash.sh` – makes installers ignore a stray leading `--`.

End‑users should not run these; use the platform installers in `/installers/`.
