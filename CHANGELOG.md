
## rev4 (2025-08-13)
- Modularized core into `includes/` modules (logging, env, steam, discovery, bakkes, config, main).
- Installers fetch modules listed in `installers/modules.manifest` (update a single module without touching others).
- Launchers remain tiny; core loader sources modules from local install dir or repo layout.
- Keeps rev3 behavior: graceful when Rocket League not installed; robust installers; HTTPS by default.

## rev4.1 (2025-08-13)
- Installers: nounset-safe manifest loop; ignore blank lines and `# comments`; more robust module fetching.

## rev4.1.1 (2025-08-13)
- Installers: fully nounset-safe manifest loop (pre-init vars + set +u guard); tolerate comments/whitespace.


## rev4.1.2 (2025-08-13)
- Installers: hardened manifest loop (nounset-safe, skips comments/blank lines, re-enables nounset after loop).

## rev5 (2025-08-13)
- Ultra-modular installers: single shared library `installers/lib.sh`, per-profile manifests, 10-line wrappers.
- Updates now require editing just `lib.sh` and/or a manifest; wrappers remain unchanged.
- Keeps rev4.x safety: nounset-safe manifest loop, hardened fetch, arg sanitizer.

## rev5.0.1 (2025-08-13)
- Logging: direct LOG output to stderr so discovery functions don’t pollute command-substitution results.
- Env: banner now says “rev5 modular”.
- Config: refuse to write config when RL_DIR/PFX_DIR/BAKKES_PATH are empty.

## rev5.0.2 (2025-08-13)
- Logging: keep stdout/stderr separate while teeing both to the log (prevents LOG text from entering command substitutions).
- Runtime: auto-delete corrupted `.rlbakkes.cfg` files that contain stray log lines from previous versions.
- Keeps prior safeguards: LOG to stderr; refuse to write invalid configs.

## rev5.0.3 (2025-08-13)
- Fix: correct stderr redirection in `includes/env.sh` (use `2>` without a space).

## rev5.0.5 (2025-08-13)
- Discovery: sanitize `libraryfolders.vdf` parsing (strip CRs/non-printables, normalize slashes, trim/expand ~) and quote all paths.
- Fixes sporadic “syntax error at or near …” when parsing Steam libraries on Pop!_OS and similar.

## rev5.0.5 (2025-08-13)
- Discovery: sanitize `libraryfolders.vdf` parsing (strip CRs/non-printables, normalize slashes, trim/expand ~) and quote all paths.
- Fixes sporadic “syntax error at or near …” when parsing Steam libraries on Pop!_OS and similar.

## rev5.0.6 (2025-08-13)
- Discovery: read `appmanifest_252950.acf` `installdir`; fallback to both `Rocket League/` and `rocketleague/` folder names (case-sensitive Linux installs).

## rev5.0.6 (2025-08-13)
- Discovery: read `appmanifest_252950.acf` `installdir`; fallback to both `Rocket League/` and `rocketleague/` folder names (case-sensitive Linux installs).

## rev5.0.7 (2025-08-13)
- Fix: `includes/discovery.sh` — ensure `find_rl_dir()` is a valid function (no stray `local` at top level). Honors `appmanifest_252950.acf` `installdir` and falls back to `Rocket League/` or `rocketleague/`.

## rev5.0.8 (2025-08-13)
- Discovery: fix "local can only be used in a function" by replacing `includes/discovery.sh` with a function-scoped version.
- Keeps sanitized VDF parsing, uses appmanifest `installdir`, and tries both `Rocket League/` and `rocketleague/`.
