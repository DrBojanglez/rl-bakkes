
## rev4 (2025-08-13)
- Modularized core into `includes/` modules (logging, env, steam, discovery, bakkes, config, main).
- Installers fetch modules listed in `installers/modules.manifest` (update a single module without touching others).
- Launchers remain tiny; core loader sources modules from local install dir or repo layout.
- Keeps rev3 behavior: graceful when Rocket League not installed; robust installers; HTTPS by default.

## rev4.1 (2025-08-13)
- Installers: nounset-safe manifest loop; ignore blank lines and `# comments`; more robust module fetching.

## rev4.1.1 (2025-08-13)
- Installers: fully nounset-safe manifest loop (pre-init vars + set +u guard); tolerate comments/whitespace.

