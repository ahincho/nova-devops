# nova-devops

Repositorio centralizado de workflows reutilizables y composite actions de GitHub Actions para el ecosistema de librerías Java de `pe.edu.nova`.

Estos workflows proporcionan un pipeline de CI/CD estandarizado con variantes dedicadas para **Maven** y **Gradle KTS**, lo que permite un caché de dependencias nativo y pipelines más limpios sin pasos condicionales.

## Política de Versionado y Branches

> ⚠️ **Este repositorio NO usa Semantic Versioning.** Todos los workflows y composite actions aquí contenidos se referencian **siempre con `@main`**.

- **Branch única:** `main`. No hay branches de release ni de feature de larga duración.
- **Sin tags SemVer:** no se crean tags `vX.Y.Z` para workflows ni composite actions. Los workflows cambian continuamente en `main` y los consumidores siguen esa rama.
- **Sin `release-please`:** este repo no tiene `.release-please-config.json` ni `.release-please-manifest.json`. El versionado de workflows es por commit, no por release.
- **Único tag permitido:** `nvd-mirror`, que es un artefacto de datos binarios (mirror del dataset OWASP NVD) auto-actualizado por el workflow `nvd-mirror-update.yml`. No es un release SemVer.

**Implicancia para los consumidores:** todos los repos de librería Nova deben referenciar este repo como:

```yaml
uses: ahincho/nova-devops/.github/workflows/reusable-XYZ.yml@main
uses: ahincho/nova-devops/.github/actions/nova-XYZ@main
```

Pinear a `@vX.Y.Z` queda explícitamente **fuera de scope** y no se garantiza compatibilidad.

## Workflows Disponibles

### Workflows Maven

| Workflow | Archivo | Descripción |
|---|---|---|
| [Build y Tests (Maven)](#1-reusable-build-mavenyml) | `reusable-build-maven.yml` | Compilación, lint (Checkstyle), tests y JavaDoc con Maven |
| [SonarCloud (Maven)](#2-reusable-sonarcloud-mavenyml) | `reusable-sonarcloud-maven.yml` | Cobertura JaCoCo y análisis SonarCloud con Maven |
| [Publicación (Maven)](#3-reusable-publish-mavenyml) | `reusable-publish-maven.yml` | Publicación de artefactos JAR en GitHub Packages con Maven |

### Workflows Gradle

| Workflow | Archivo | Descripción |
|---|---|---|
| [Build y Tests (Gradle)](#4-reusable-build-gradleyml) | `reusable-build-gradle.yml` | Compilación, lint (Checkstyle), tests y JavaDoc con Gradle |
| [SonarCloud (Gradle)](#5-reusable-sonarcloud-gradleyml) | `reusable-sonarcloud-gradle.yml` | Cobertura JaCoCo y análisis SonarCloud con Gradle |
| [Publicación (Gradle)](#6-reusable-publish-gradleyml) | `reusable-publish-gradle.yml` | Publicación de artefactos JAR en GitHub Packages con Gradle |

### Workflows de Release (cross-stack)

| Workflow | Archivo | Descripción |
|---|---|---|
| [Release Publish (Sprint 3)](#7-reusable-release-publishyml-sprint-3--nova-semver-13) | `reusable-release-publish.yml` | Publish al dispararse un tag `vX.Y.Z` creado por release-please |
| [Release Please](#8-reusable-release-pleaseyml) | `reusable-release-please.yml` | Orquestador de release automático basado en `release-please` |

### Beneficio del Caché de Dependencias

Al separar los workflows por herramienta de build, cada variante configura `actions/setup-java@v4` con el parámetro `cache` correspondiente (`'maven'` o `'gradle'`). Esto habilita el caché nativo de dependencias de GitHub Actions, reduciendo significativamente los tiempos de ejecución en pipelines subsecuentes.

Las composite actions de setup (`nova-setup-java`, `nova-setup-node`) extienden este patrón con caché de `node_modules` y `gradle.properties` configurable.

## Composite Actions Disponibles

Composite actions reutilizables (en `.github/actions/`):

| Composite Action | Descripción |
|---|---|
| [`nova-setup-java`](#composite-action-nova-setup-java) | Setup Java 25 + cache Gradle/Maven + validación de build files |
| [`nova-setup-node`](#composite-action-nova-setup-node) | Setup Node.js + cache `node_modules` + `npm ci` |
| [`nova-setup-gpg`](#composite-action-nova-setup-gpg) | Import GPG key (preparado, clave aún no generada) |

---

## 1. reusable-build-maven.yml

Workflow reutilizable que compila el proyecto Maven, ejecuta los tests, verifica el estilo de código con Checkstyle y genera la documentación JavaDoc.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |

### Secretos Requeridos

Ninguno.

### Artefactos Generados

| Artefacto | Descripción |
|---|---|
| `test-reports` | Reportes de tests (Surefire) |
| `javadoc` | Documentación JavaDoc generada |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Compilación y Tests | `mvn verify` |
| Lint (Checkstyle) | `mvn checkstyle:check` |
| JavaDoc | `mvn javadoc:javadoc` |

### Ejemplo de Uso

```yaml
jobs:
  build:
    uses: <org>/nova-devops/.github/workflows/reusable-build-maven.yml@main
    with:
      java-version: '25'
```

---

## 2. reusable-sonarcloud-maven.yml

Workflow reutilizable que genera el reporte de cobertura con JaCoCo y ejecuta el análisis de calidad de código en SonarCloud para proyectos Maven.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |
| `sonar-org` | `string` | sí | — | Organización en SonarCloud |
| `sonar-project-key` | `string` | sí | — | Clave del proyecto en SonarCloud |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `NOVA_SONAR_TOKEN` | Token de autenticación de SonarCloud |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Cobertura JaCoCo | `mvn verify jacoco:report` |
| Análisis SonarCloud | `mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar` |

### Ejemplo de Uso

```yaml
jobs:
  sonar:
    uses: <org>/nova-devops/.github/workflows/reusable-sonarcloud-maven.yml@main
    with:
      sonar-org: mi-organizacion
      sonar-project-key: mi-organizacion_nova-mask-utils
    secrets:
      NOVA_SONAR_TOKEN: ${{ secrets.NOVA_SONAR_TOKEN }}
```

---

## 3. reusable-publish-maven.yml

Workflow reutilizable que publica el artefacto JAR de la librería Maven en GitHub Packages. Soporta `visibility` configurable (public/private) y `dry-run`.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |
| `visibility` | `string` | no | `vars.NOVA_PACKAGE_VISIBILITY` o `'public'` | Visibilidad del paquete (`public` / `private`) |
| `dry-run` | `string` | no | `'false'` | Si es `'true'`, hace deploy a `file:///tmp/maven-dry-run` |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GITHUB_TOKEN` | Token para autenticarse con GitHub Packages |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Publicación | `mvn deploy -DskipTests -Dvisibility=$VISIBILITY` |

### Notas

- Usa la composite action `nova-setup-java` (sprint 1) que valida `pom.xml` y configura caché de Maven.
- Valida que la visibilidad del paquete sea compatible con la visibilidad del repo.
- Genera `~/.m2/settings.xml` con la credencial de GitHub Packages.

### Prerrequisitos en el Repositorio

El `pom.xml` debe incluir la sección `distributionManagement`:

```xml
<distributionManagement>
    <repository>
        <id>github</id>
        <name>GitHub Packages</name>
        <url>https://maven.pkg.github.com/OWNER/nombre-repositorio</url>
    </repository>
</distributionManagement>
```

### Ejemplo de Uso

```yaml
jobs:
  publish:
    uses: <org>/nova-devops/.github/workflows/reusable-publish-maven.yml@main
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 4. reusable-build-gradle.yml

Workflow reutilizable que compila el proyecto Gradle, ejecuta los tests, verifica el estilo de código con Checkstyle y genera la documentación JavaDoc.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |

### Secretos Requeridos

Ninguno.

### Artefactos Generados

| Artefacto | Descripción |
|---|---|
| `test-reports` | Reportes de tests (HTML) |
| `javadoc` | Documentación JavaDoc generada |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Compilación y Tests | `./gradlew build` |
| Lint (Checkstyle) | `./gradlew checkstyleMain checkstyleTest` |
| JavaDoc | `./gradlew javadoc` |

### Ejemplo de Uso

```yaml
jobs:
  build:
    uses: <org>/nova-devops/.github/workflows/reusable-build-gradle.yml@main
```

---

## 5. reusable-sonarcloud-gradle.yml

Workflow reutilizable que genera el reporte de cobertura con JaCoCo y ejecuta el análisis de calidad de código en SonarCloud para proyectos Gradle.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |
| `sonar-org` | `string` | sí | — | Organización en SonarCloud |
| `sonar-project-key` | `string` | sí | — | Clave del proyecto en SonarCloud |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `NOVA_SONAR_TOKEN` | Token de autenticación de SonarCloud |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Cobertura JaCoCo | `./gradlew build jacocoTestReport` |
| Análisis SonarCloud | `./gradlew sonar` |

### Ejemplo de Uso

```yaml
jobs:
  sonar:
    uses: <org>/nova-devops/.github/workflows/reusable-sonarcloud-gradle.yml@main
    with:
      sonar-org: mi-organizacion
      sonar-project-key: mi-organizacion_nova-date-utils
    secrets:
      NOVA_SONAR_TOKEN: ${{ secrets.NOVA_SONAR_TOKEN }}
```

---

## 6. reusable-publish-gradle.yml

Workflow reutilizable que publica el artefacto JAR de la librería Gradle en GitHub Packages. Soporta `visibility` configurable (public/private) y `dry-run`.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |
| `visibility` | `string` | no | `vars.NOVA_PACKAGE_VISIBILITY` o `'public'` | Visibilidad del paquete (`public` / `private`) |
| `dry-run` | `string` | no | `'false'` | Si es `'true'`, usa `gradle publishToMavenLocal` |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GITHUB_TOKEN` | Token para autenticarse con GitHub Packages |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Publicación | `./gradlew publish -Pvisibility=$VISIBILITY` |
| Dry-run | `./gradlew publishToMavenLocal -Pvisibility=$VISIBILITY` |

### Notas

- Usa la composite action `nova-setup-java` (sprint 1) que valida `gradle.properties` y configura `gradle/actions/setup-gradle@v4`.
- Valida que la visibilidad del paquete sea compatible con la visibilidad del repo.
- La propiedad Gradle `-Pvisibility=$VISIBILITY` permite que el `build.gradle.kts` ajuste la configuracion segun la visibilidad.

### Prerrequisitos en el Repositorio

El `build.gradle.kts` debe incluir el bloque `publishing`:

```kotlin
publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
        }
    }
    repositories {
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/OWNER/nombre-repositorio")
            credentials {
                username = System.getenv("GITHUB_ACTOR")
                password = System.getenv("GITHUB_TOKEN")
            }
        }
    }
}
```

### Ejemplo de Uso

```yaml
jobs:
  publish:
    uses: <org>/nova-devops/.github/workflows/reusable-publish-gradle.yml@main
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 7. reusable-release-publish.yml (Sprint 3 — NOVA-SEMVER-13)

Workflow reutilizable que se ejecuta al hacer push de un tag `vX.Y.Z` (formato semver estricto). Suplanta el antiguo par `version-bump` + `publish` con una cadena determinista de un solo paso.

### Disparador

- `on: workflow_call` (llamado desde `publish-on-tag.yml`).
- El workflow llamador debe configurarse con `on: push: tags: ['v[0-9]+.[0-9]+.[0-9]+']`.

### Pasos del Pipeline

1. **Validate tag format**: verifica que el tag cumpla `^v[0-9]+\.[0-9]+\.[0-9]+$`.
2. **Sync version from tag to gradle.properties**: escribe `version=<version-sin-v>` en `gradle.properties`.
3. **Nova Setup Java**: composite action con Java 25 + caché Gradle.
4. **Resolve package visibility**: prioridad `input > vars.NOVA_PACKAGE_VISIBILITY > "public"`.
5. **Validate visibility compatibility**: rechaza combinaciones inválidas (public repo + private package).
6. **Publish to GitHub Packages**: `./gradlew publish -Pvisibility=...`.

### Reemplazo del patrón antiguo

Antes (NO recomendado):
```yaml
publish:
  if: github.event_name == 'push'
  needs: version-bump
  uses: ahincho/nova-devops/.github/workflows/reusable-publish-gradle.yml@main
```

Ahora:
```yaml
# publish-on-tag.yml
on:
  push:
    tags: ['v[0-9]+.[0-9]+.[0-9]+']
jobs:
  publish:
    uses: ahincho/nova-devops/.github/workflows/reusable-release-publish.yml@main
    secrets: inherit
```

### Notas

- Este workflow **reemplaza** `reusable-publish-{gradle,maven}.yml` como mecanismo oficial de publicación de releases para los repos migrados a Sprint 3.
- El versionado se delega completamente a `release-please` (§ 8). El tag `vX.Y.Z` que crea `release-please` al mergear su PR es lo que dispara este workflow.

---

## 8. reusable-release-please.yml

Workflow reutilizable que ejecuta [`release-please`](https://github.com/googleapis/release-please) de Google para automatizar releases basados en Conventional Commits. Crea PRs de release que bumpean la versión, actualizan CHANGELOG.md, y al mergear crean GitHub Releases + tags.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `release-type` | `string` | no | `'java'` | Tipo de release: `java`, `gradle`, `maven`, `python`, `node`, `go`, `rust`, `php`, `ruby`, `elixir` |
| `package-name` | `string` | no | repo name | Nombre del paquete (para multi-package repos) |
| `config-file` | `string` | no | `'.release-please-config.json'` | Path al config de release-please |
| `manifest-file` | `string` | no | `''` | Path al manifest (para multi-repo coordination) |
| `node-version` | `string` | no | `'20'` | Versión de Node.js |
| `target-branch` | `string` | no | `'main'` | Branch target para los PRs de release |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GH_TOKEN` | Token con permisos `contents:write` y `pull-requests:write` |

### Configuración por repo (`.release-please-config.json`)

Cada repo Java debe tener su propio config:

```json
{
  "packages": {
    ".": {
      "release-type": "java",
      "package-name": "nova-java-spring-boot-mask-utils",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true
    }
  }
}
```

### Uso desde un workflow llamador

```yaml
# .github/workflows/release-please.yml (en cada repo)
name: Release Please
on:
  push:
    branches: [main]
permissions:
  contents: write
  pull-requests: write
jobs:
  release-please:
    uses: ahincho/nova-devops/.github/workflows/reusable-release-please.yml@main
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Notas

- No usa `nova-setup-node` porque `googleapis/release-please-action@v4` trae su propio setup de Node.
- Compatible con manifest mode para multi-repo coordination (un repo coordina releases de varios).
- Ver `docs/06-semantic-versioning-en-java.md` sección 8.6 para más detalles.

---

## Ejemplo Completo de Workflow Llamador (ci.yml)

A continuación se muestra un ejemplo completo de un workflow llamador que orquesta todos los workflows reutilizables. Este archivo se coloca en cada repositorio de librería en `.github/workflows/ci.yml`.

> **Flujo de release oficial (a partir de Sprint 3 — NOVA-SEMVER-13):** el versionado se delega a `release-please`, que crea un PR con el bump propuesto y, al hacer merge, genera un tag `vX.Y.Z`. El tag dispara el publish. **El push directo a `main` ya no bumpea versión.**

### Estructura de archivos en cada repo

```
.github/
  workflows/
    ci.yml                 # PR + build + sonar
    release-please.yml     # push a main → PR de release
    publish-on-tag.yml     # tag vX.Y.Z → publish
.release-please-config.json
.release-please-manifest.json
```

### `ci.yml` (común a todos los repos)

```yaml
name: CI/CD Pipeline

on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  push:
    branches: [main]

jobs:
  build:
    if: github.event_name == 'pull_request'
    uses: ahincho/nova-devops/.github/workflows/reusable-build-gradle.yml@main
    secrets: inherit

  sonar:
    if: github.event_name == 'pull_request'
    uses: ahincho/nova-devops/.github/workflows/reusable-sonarcloud-gradle.yml@main
    with:
      sonar-org: ahincho
      sonar-project-key: ahincho_nova-java-spring-boot-<nombre-corto>
    secrets: inherit
```

### `release-please.yml`

```yaml
name: Release Please

on:
  push:
    branches: [main]

jobs:
  release-please:
    uses: ahincho/nova-devops/.github/workflows/reusable-release-please.yml@main
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### `publish-on-tag.yml`

```yaml
name: Publish on Tag

on:
  push:
    tags: ['v[0-9]+.[0-9]+.[0-9]+']

jobs:
  publish:
    uses: ahincho/nova-devops/.github/workflows/reusable-release-publish.yml@main
    secrets: inherit
```

### `.release-please-config.json`

```json
{
  "packages": {
    ".": {
      "package-name": "nova-java-spring-boot-<nombre-corto>",
      "release-type": "java",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true,
      "draft": false,
      "prerelease": false
    }
  }
}
```

### `.release-please-manifest.json`

```json
{
  ".": "0.1.0"
}
```

> El manifest se actualiza automáticamente en cada release PR. Inicialmente contiene la versión de partida (`0.1.0`).

---

## Librerías del Ecosistema

| Librería | Repositorio | Build Tool | Sonar Project Key |
|---|---|---|---|
| mask-utils | `nova-mask-utils` | Maven | `<org>_nova-mask-utils` |
| api-standard | `nova-api-standard` | Gradle KTS | `<org>_nova-api-standard` |
| date-utils | `nova-date-utils` | Gradle KTS | `<org>_nova-date-utils` |
| mapper-utils | `nova-mapper-utils` | Gradle KTS | `<org>_nova-mapper-utils` |

## Secretos Necesarios

Cada repositorio de librería debe tener configurados los siguientes secretos (los marcados como **opcional** solo se requieren si se usa el workflow que los consume):

| Secreto | Usado por | Descripción |
|---|---|---|
| `GITHUB_TOKEN` | todos los workflows | Token automático de GitHub (disponible por defecto, no requiere configuración) |
| `NOVA_SONAR_TOKEN` *(opcional)* | `reusable-sonarcloud-maven.yml` / `reusable-sonarcloud-gradle.yml` | Token de autenticación de SonarCloud. Solo requerido si se activa el análisis de SonarCloud |

### Variables de Repositorio (no secretos)

| Variable | Usado por | Default | Descripción |
|---|---|---|---|
| `NOVA_PACKAGE_VISIBILITY` | `reusable-publish-{gradle,maven}.yml` | `'public'` | Visibilidad por defecto del paquete (puede ser sobreescrita por el input `visibility` del workflow) |

---

## Composite Actions

Las composite actions se invocan desde los reusable workflows o directamente desde workflows llamadores. Se referencian con la sintaxis:

```yaml
- uses: ahincho/nova-devops/.github/actions/<nombre>@<ref>
```

Donde `<ref>` puede ser `main` (para desarrollo) o un tag SemVer (ej: `v1.0.0`) para releases inmutables.

### Composite Action: `nova-setup-java`

Setup de Java con caché de Gradle/Maven siguiendo convenciones de Nova.

**Inputs:**

| Input | Default | Descripción |
|---|---|---|
| `java-version` | `'25'` | Versión de Java |
| `build-tool` | `'gradle'` | Build tool: `maven` o `gradle` |
| `distribution` | `'temurin'` | Distribución JDK |

**Pasos internos:**

1. `actions/setup-java@v4` con `cache: gradle|maven` según `build-tool`.
2. Validación: falla si no existe ni `gradle.properties` ni `pom.xml`.
3. `gradle/actions/setup-gradle@v4` (solo si `build-tool=gradle`) con `cache-read-only` en PRs.

**Ejemplo:**

```yaml
- uses: ahincho/nova-devops/.github/actions/nova-setup-java@v1
  with:
    java-version: '25'
    build-tool: gradle
```

### Composite Action: `nova-setup-node`

Setup de Node.js con caché de `node_modules` e instalación de dependencias.

**Inputs:**

| Input | Default | Descripción |
|---|---|---|
| `node-version` | `'20'` | Versión de Node.js |
| `package-manager` | `'npm'` | Package manager: `npm`, `pnpm`, `yarn` |
| `cache-key-prefix` | `''` | Prefijo para la key del cache (útil en monorepos) |

**Pasos internos:**

1. `actions/setup-node@v4`.
2. `actions/cache@v4` para `node_modules` y `.npm`.
3. `npm ci` (si hay `package-lock.json`) o `npm install`.

**Ejemplo:**

```yaml
- uses: ahincho/nova-devops/.github/actions/nova-setup-node@v1
  with:
    node-version: '20'
```

### Composite Action: `nova-setup-gpg`

Import de clave GPG para firma de artefactos (preparado, **clave aún no generada** — ver `docs/06-semantic-versioning-en-java.md` sección 10.3).

> **Aclaración técnica:** las composite actions NO tienen acceso a `secrets.*` de GitHub Actions. Los secrets deben pasarse como `inputs` desde el workflow que invoca la action.

**Inputs:**

| Input | Default | Descripción |
|---|---|---|
| `gpg-signing-key-id` | `''` | Fingerprint de la clave GPG |
| `gpg-signing-key` | `''` | Clave privada ASCII-armored (pasada como input) |
| `gpg-signing-password` | `''` | Passphrase (si aplica) |
| `fail-on-missing` | `'false'` | Si es `true`, falla cuando los inputs están vacíos |

**Outputs:**

| Output | Descripción |
|---|---|
| `gpg-key-imported` | `true`/`false` — si la clave fue importada |
| `gpg-key-skipped` | `true`/`false` — si se saltó la configuración |

**Uso desde un reusable workflow (que SÍ tiene acceso a `secrets`):**

```yaml
steps:
  - uses: ahincho/nova-devops/.github/actions/nova-setup-gpg@v1
    with:
      gpg-signing-key-id: ${{ secrets.GPG_SIGNING_KEY_ID }}
      gpg-signing-key: ${{ secrets.GPG_SIGNING_KEY }}
      gpg-signing-password: ${{ secrets.GPG_SIGNING_PASSWORD }}
      fail-on-missing: 'true'
```

**Comportamiento por defecto (`fail-on-missing='false'`):** si los inputs están vacíos, emite un `::notice::` y continúa sin error.

---

## Versionado de las Composite Actions

Este repositorio **no usa Semantic Versioning** (ver [Política de Versionado y Branches](#política-de-versionado-y-branches) arriba). Las composite actions se referencian siempre con `@main` (HEAD) o, para máxima inmutabilidad y reproducibilidad de un run específico, con un commit SHA: `@<commit-sha>`.