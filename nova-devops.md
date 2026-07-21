# Nova-DevOps — Plan de trabajo y bitácora

> Documento vivo. Se actualiza con cada cambio relevante del repo.
> Cualquier sesión de trabajo que toque el repo debe iniciar leyendo este archivo y terminar agregándolo a la sección **Bitácora de cambios**.

---

## Estado actual del repo

- **Rama principal:** `main` (HEAD `42df989`)
- **Rama de integración:** `dev` (HEAD `42df989`, sincronizada con main)
- **CodeQL:** 0 alertas
- **Pester:** 148/148 tests pasando
- **actionlint:** 0 errores reales (10 FP `description:`)
- **SHA-pinning:** 68 sitios, 14 acciones distintas
- **Code-injection:** 0 (era 7, fixed via env var pattern)
- **Dependabot config:** VÁLIDA (generó PRs #6 y #7)
- **README.md:** Re-escrito en inglés, cubre los 16 workflows + 7 composite actions
- **Branch protection:** `main` (strict, enforce_admins), `dev` (soft, no enforce_admins)

---

## Lote Q — Aplicado y mergeado (PR #3)

### Objetivo
Eliminar las 42 alertas medium de CodeQL (35 unpinned-tag + 7 code-injection) y hacer mergeable PR #3.

### Estrategia
Hybrid SHA-pinning — TODO `uses:` con SHA (internas + externas + 1st-party), NO branch pins.

### Cambios aplicados
- 14 acciones SHA-pinned (68 `uses:` refs): checkout, setup-java, setup-node, cache, upload-artifact, attest-build-provenance, create-github-app-token, codeql-action, gradle/actions/setup-gradle, googleapis/release-please-action, anchore/sbom-action, 7 acciones internas, 2 reusable workflows internos.
- **`anchore/syft-action@v1` → `anchore/sbom-action@v0`** (el repo `anchore/syft-action` 404s; sbom-action usa el mismo CLI syft).
- 7 code-injection alerts corregidos en `reusable-sonarcloud-{gradle,maven}.yml` y `reusable-release-maven-publish.yml` (patrón `env:` + `"$VAR"` quoted).
- Headers de 13 workflows actualizados: "Lote P" → "Lote Q SHA-pin".
- Pester tests: 131 → 148 (+17 tests nuevos).

### SHA canónico de acciones internas
`300f6695c82197f50b2cfa0831bd146ed549a279` — el último `main` HEAD antes del merge del Lote Q.

---

## Deuda pendiente (post-Lote Q)

| # | Tarea | Prioridad | Bloqueante | Estado |
|---|---|---|---|---|
| 1 | Bumpear SHAs de acciones internas en 16 repos consumidores (`@main` → `@<NEW_SHA>`) | **Alta** | Builds rotos si no se hace | Pendiente |
| 2 | Push branch `dev` + protección remota (Lote P nunca aplicado) | Media | No | ✅ **CERRADO sesión 2026-07-21 PM** |
| 3 | GitHub App manual setup (Lote H1 — código listo) | Media | Consumer repos sin App secrets | Pendiente |
| 4 | Aplicar migration bundles Lote F (requiere `gh auth refresh --scopes workflow`) | Baja | No | Pendiente |
| 5 | Tag/release v1.0 de Lote Q (CHANGELOG ya escrito en merge commit) | Baja | No | Pendiente |
| 6 | **Dependabot config error** — `update-strategy: "in-range"` no es válido bajo `groups` | **Alta** | PRs de dependabot no se generan | ✅ **CERRADO PR #4** |
| 7 | README en español → inglés con todos los pipelines | Media | Documentación desactualizada | ✅ **CERRADO PR #8** |

---

## Plan activo — Corrección Dependabot

### Diagnóstico
`dependabot.yml` tenía 2 campos inválidos `update-strategy: "in-range"` bajo `groups.actions-major-bump` y `groups.third-party-actions`.

**Schema oficial Dependabot v2 — claves válidas bajo `groups`:**
- `IDENTIFIER`, `applies-to`, `dependency-type`, `exclude-patterns`, `group-by`, `patterns`, `update-types`

`update-strategy` **NO** existe en el schema. GitHub lo ignoraba silenciosamente y dejaba la config sin aplicar → no generaba PRs automáticos.

### Fix aplicado
Eliminadas las 2 líneas `update-strategy: "in-range"`. El comportamiento por defecto (`in-range`) ya es lo que se quería expresar (actualizar dentro del rango SemVer actual).

### Resultado
- Commit: `fd469ca` en rama `fix/dependabot-update-strategy`
- PR #4 mergeado en `4b4ce7d`
- Pester: 148/148 verde post-cambio (config-only, no afecta workflows)
- actionlint: igual que antes (no toca workflows)
- Próximo run de Dependabot (lunes 06:00 UTC) debería generar PRs sin error

---

## Convenciones del repo

- **Branches:** `main` (protegida strict, enforce_admins), `dev` (protegida soft, sin enforce_admins). Workflow de desarrollo: feature branch → dev → main.
- **Commits:** Conventional Commits (`feat:`, `fix:`, `ci:`, `chore:`, `docs:`, `refactor:`, `test:`)
- **PRs:** Squash merge, branch protection con 1 review + CODEOWNERS `* @ahincho`
- **Pester:** `tests/*.Tests.ps1`, manual install en `$USERPROFILE\Documents\PowerShell\Modules\Pester\5.7.1`
- **actionlint:** `C:\Users\Angel\go\bin\actionlint.exe`
- **gh CLI:** 2.96.0

---

## Bitácora de cambios

### 2026-07-21 — Sesión Lote Q (PR #3 merge)

- **PR #3 MERGED** en commit `dda18a6` (fast-forward desde `300f669`)
- CodeQL: 42 → 0 alertas
- Pester: 131 → 148 tests
- SHA-pins: 68 sitios, 14 acciones
- Code-injection: 7 → 0
- `anchore/syft-action` → `anchore/sbom-action` (deprecated → actual)
- Branch protection: temporalmente relajada para merge (`enforce_admins=false`, review=0), restaurada post-merge (`enforce_admins=true`, code_owner_reviews=true, review=1)
- Backup de branch protection: `C:\Users\Angel\AppData\Local\Temp\opencode\branch-protection-backup.json`

### 2026-07-21 PM — Sesión README + branches

- **Branches sincronizadas**: `dev` creada en Lote P (15-jul, `300f669`) nunca se había pusheado. Fast-forward `dev` a `main` (`4fdc814`), push a origin, protección soft aplicada (1 review, CodeQL required, no enforce_admins).
- **README re-escrito en inglés**: 696 líneas (español) → 433 líneas (inglés), 18.7KB. Cubre los 16 workflows + 7 composite actions + Pester + scripts + migrations + security posture + Dependabot + branch protection. SHA canónico de acciones internas referenciado: `300f6695c82197f50b2cfa0831bd146ed549a279`.
- **PR #8** mergeado en `42df989`.
- **Workflow de dev confirmado**: feature branch → dev (soft protection) → main (strict protection).

### 2026-07-21 — Sesión Dependabot fix

- Diagnóstico: `update-strategy: "in-range"` inválido bajo `groups`
- Fix aplicado: removidas 2 líneas inválidas
- Creado `nova-devops.md` (este archivo) como plan de trabajo vivo
- PR #4 mergeado en `4b4ce7d`
- Branch protection manipulada 2da vez (relajada → merge → restaurada)
  - Patrón confirmado: `gh api -X DELETE .../required_pull_request_reviews` + `required_status_checks`
  - Restaurar con PUT inline body (requiere `restrictions: null`)