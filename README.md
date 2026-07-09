# nova-devops

Repositorio centralizado de workflows reutilizables y composite actions de GitHub Actions para el ecosistema de librerías Java de `pe.edu.nova`.

Estos workflows proporcionan un pipeline de CI/CD estandarizado con variantes dedicadas para **Maven** y **Gradle KTS**, lo que permite un caché de dependencias nativo y pipelines más limpios sin pasos condicionales.

## Workflows Disponibles

### Workflows Maven

| Workflow | Archivo | Descripción |
|---|---|---|
| [Build y Tests (Maven)](#1-reusable-build-mavenyml) | `reusable-build-maven.yml` | Compilación, lint (Checkstyle), tests y JavaDoc con Maven |
| [SonarCloud (Maven)](#2-reusable-sonarcloud-mavenyml) | `reusable-sonarcloud-maven.yml` | Cobertura JaCoCo y análisis SonarCloud con Maven |
| [Versionado Semántico (Maven)](#3-reusable-version-bump-mavenyml) | `reusable-version-bump-maven.yml` | Incremento automático de versión para proyectos Maven |
| [Publicación (Maven)](#4-reusable-publish-mavenyml) | `reusable-publish-maven.yml` | Publicación de artefactos JAR en GitHub Packages con Maven |

### Workflows Gradle

| Workflow | Archivo | Descripción |
|---|---|---|
| [Build y Tests (Gradle)](#5-reusable-build-gradleyml) | `reusable-build-gradle.yml` | Compilación, lint (Checkstyle), tests y JavaDoc con Gradle |
| [SonarCloud (Gradle)](#6-reusable-sonarcloud-gradleyml) | `reusable-sonarcloud-gradle.yml` | Cobertura JaCoCo y análisis SonarCloud con Gradle |
| [Versionado Semántico (Gradle)](#7-reusable-version-bump-gradleyml) | `reusable-version-bump-gradle.yml` | Incremento automático de versión para proyectos Gradle |
| [Publicación (Gradle)](#8-reusable-publish-gradleyml) | `reusable-publish-gradle.yml` | Publicación de artefactos JAR en GitHub Packages con Gradle |

### Workflows de Versionado y Release (cross-stack)

| Workflow | Archivo | Descripción |
|---|---|---|
| [Conventional Commits Lint](#9-reusable-commitlintyml) | `reusable-commitlint.yml` | Enforce Conventional Commits en un rango de commits |
| [Release Please](#10-reusable-release-pleaseyml) | `reusable-release-please.yml` | Orquestador de release automático basado en `release-please` |
| [Generador de CHANGELOG](#11-reusable-changelogyml) | `reusable-changelog.yml` | Auto-generación de CHANGELOG.md con `conventional-changelog-cli` |

### Beneficio del Caché de Dependencias

Al separar los workflows por herramienta de build, cada variante configura `actions/setup-java@v4` con el parámetro `cache` correspondiente (`'maven'` o `'gradle'`). Esto habilita el caché nativo de dependencias de GitHub Actions, reduciendo significativamente los tiempos de ejecución en pipelines subsecuentes.

Las composite actions de setup (`nova-setup-java`, `nova-setup-node`) extienden este patrón con caché de `node_modules` y `gradle.properties` configurable.

## Composite Actions Disponibles

Composite actions reutilizables (en `.github/actions/`):

| Composite Action | Descripción |
|---|---|
| [`nova-setup-java`](#composite-action-nova-setup-java) | Setup Java 25 + cache Gradle/Maven + validación de build files |
| [`nova-setup-node`](#composite-action-nova-setup-node) | Setup Node.js + cache `node_modules` + `npm ci` para commitlint |
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
| `SONAR_TOKEN` | Token de autenticación de SonarCloud |

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
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## 3. reusable-version-bump-maven.yml

Workflow reutilizable que determina el tipo de incremento de versión a partir de las labels del PR fusionado, calcula la nueva versión semántica, actualiza el `pom.xml`, crea un commit y un tag de Git.

### Parámetros de Entrada

Ninguno.

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GH_PAT` | Token de acceso personal con permisos de push para crear commits y tags |

### Outputs

| Output | Descripción |
|---|---|
| `new-version` | La nueva versión semántica calculada (ej: `1.2.0`) |

### Lógica de Versionado

El tipo de incremento se determina por las labels del PR:

| Label del PR | Tipo de Incremento | Ejemplo |
|---|---|---|
| `major` | MAJOR + 1, MINOR = 0, PATCH = 0 | `1.2.3` → `2.0.0` |
| `minor` | MINOR + 1, PATCH = 0 | `1.2.3` → `1.3.0` |
| `patch` | PATCH + 1 | `1.2.3` → `1.2.4` |
| Sin label | `patch` por defecto | `1.2.3` → `1.2.4` |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Leer versión actual | `mvn help:evaluate -Dexpression=project.version -q -DforceStdout` |
| Actualizar versión | `mvn versions:set -DnewVersion=<versión> -DgenerateBackupPoms=false` |

### Ejemplo de Uso

```yaml
jobs:
  version-bump:
    uses: <org>/nova-devops/.github/workflows/reusable-version-bump-maven.yml@main
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}
```

---

## 4. reusable-publish-maven.yml

Workflow reutilizable que publica el artefacto JAR de la librería Maven en GitHub Packages.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GITHUB_TOKEN` | Token para autenticarse con GitHub Packages |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Publicación | `mvn deploy -DskipTests` |

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
    needs: version-bump
    uses: <org>/nova-devops/.github/workflows/reusable-publish-maven.yml@main
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 5. reusable-build-gradle.yml

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

## 6. reusable-sonarcloud-gradle.yml

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
| `SONAR_TOKEN` | Token de autenticación de SonarCloud |

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
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

## 7. reusable-version-bump-gradle.yml

Workflow reutilizable que determina el tipo de incremento de versión a partir de las labels del PR fusionado, calcula la nueva versión semántica, actualiza el `build.gradle.kts`, crea un commit y un tag de Git.

### Parámetros de Entrada

Ninguno.

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GH_PAT` | Token de acceso personal con permisos de push para crear commits y tags |

### Outputs

| Output | Descripción |
|---|---|
| `new-version` | La nueva versión semántica calculada (ej: `1.2.0`) |

### Lógica de Versionado

El tipo de incremento se determina por las labels del PR:

| Label del PR | Tipo de Incremento | Ejemplo |
|---|---|---|
| `major` | MAJOR + 1, MINOR = 0, PATCH = 0 | `1.2.3` → `2.0.0` |
| `minor` | MINOR + 1, PATCH = 0 | `1.2.3` → `1.3.0` |
| `patch` | PATCH + 1 | `1.2.3` → `1.2.4` |
| Sin label | `patch` por defecto | `1.2.3` → `1.2.4` |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Leer versión actual | `grep/sed` sobre `build.gradle.kts` |
| Actualizar versión | `sed` sobre `build.gradle.kts` |

### Ejemplo de Uso

```yaml
jobs:
  version-bump:
    uses: <org>/nova-devops/.github/workflows/reusable-version-bump-gradle.yml@main
    secrets:
      GH_PAT: ${{ secrets.GH_PAT }}
```

---

## 8. reusable-publish-gradle.yml

Workflow reutilizable que publica el artefacto JAR de la librería Gradle en GitHub Packages.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Versión de Java a usar |

### Secretos Requeridos

| Secreto | Descripción |
|---|---|
| `GITHUB_TOKEN` | Token para autenticarse con GitHub Packages |

### Pasos del Pipeline

| Paso | Comando |
|---|---|
| Publicación | `./gradlew publish` |

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
    needs: version-bump
    uses: <org>/nova-devops/.github/workflows/reusable-publish-gradle.yml@main
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Ejemplo Completo de Workflow Llamador (ci.yml)

A continuación se muestra un ejemplo completo de un workflow llamador que orquesta todos los workflows reutilizables. Este archivo se coloca en cada repositorio de librería en `.github/workflows/ci.yml`.

### Ejemplo para Maven (mask-utils)

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
    uses: <org>/nova-devops/.github/workflows/reusable-build-maven.yml@main

  sonar:
    if: github.event_name == 'pull_request'
    uses: <org>/nova-devops/.github/workflows/reusable-sonarcloud-maven.yml@main
    with:
      sonar-org: mi-organizacion
      sonar-project-key: mi-organizacion_nova-mask-utils
    secrets: inherit

  version-bump:
    if: github.event_name == 'push'
    uses: <org>/nova-devops/.github/workflows/reusable-version-bump-maven.yml@main
    secrets: inherit

  publish:
    if: github.event_name == 'push'
    needs: version-bump
    uses: <org>/nova-devops/.github/workflows/reusable-publish-maven.yml@main
    secrets: inherit
```

### Ejemplo para Gradle (date-utils)

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
    uses: <org>/nova-devops/.github/workflows/reusable-build-gradle.yml@main

  sonar:
    if: github.event_name == 'pull_request'
    uses: <org>/nova-devops/.github/workflows/reusable-sonarcloud-gradle.yml@main
    with:
      sonar-org: mi-organizacion
      sonar-project-key: mi-organizacion_nova-date-utils
    secrets: inherit

  version-bump:
    if: github.event_name == 'push'
    uses: <org>/nova-devops/.github/workflows/reusable-version-bump-gradle.yml@main
    secrets: inherit

  publish:
    if: github.event_name == 'push'
    needs: version-bump
    uses: <org>/nova-devops/.github/workflows/reusable-publish-gradle.yml@main
    secrets: inherit
```

---

## Librerías del Ecosistema

| Librería | Repositorio | Build Tool | Sonar Project Key |
|---|---|---|---|
| mask-utils | `nova-mask-utils` | Maven | `<org>_nova-mask-utils` |
| api-standard | `nova-api-standard` | Gradle KTS | `<org>_nova-api-standard` |
| date-utils | `nova-date-utils` | Gradle KTS | `<org>_nova-date-utils` |
| mapper-utils | `nova-mapper-utils` | Gradle KTS | `<org>_nova-mapper-utils` |

## Secretos Necesarios

Cada repositorio de librería debe tener configurados los siguientes secretos:

| Secreto | Usado por | Descripción |
|---|---|---|
| `SONAR_TOKEN` | `reusable-sonarcloud-maven.yml` / `reusable-sonarcloud-gradle.yml` | Token de autenticación de SonarCloud |
| `GH_PAT` | `reusable-version-bump-maven.yml` / `reusable-version-bump-gradle.yml` | Token de acceso personal con permisos de push |
| `GITHUB_TOKEN` | `reusable-publish-maven.yml` / `reusable-publish-gradle.yml` / `reusable-release-please.yml` | Token automático de GitHub (disponible por defecto) |

---

## 9. reusable-commitlint.yml

Workflow reutilizable que valida que los mensajes de commit en un rango sigan el estándar **Conventional Commits** usando `commitlint` con la config `@commitlint/config-conventional`.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `base-ref` | `string` | sí | — | SHA, branch o tag base (ej: `main` o un SHA) |
| `head-ref` | `string` | no | `HEAD` | SHA, branch o tag head |
| `node-version` | `string` | no | `'20'` | Versión de Node.js |
| `config-file` | `string` | no | `'commitlint.config.js'` | Path al config de commitlint |

### Secretos Requeridos

Ninguno obligatorio. `GH_TOKEN` opcional para feedback en PR.

### Uso desde un workflow llamador

```yaml
# .github/workflows/commitlint.yml (en cada repo)
name: Commitlint
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]

jobs:
  commitlint:
    uses: ahincho/nova-devops/.github/workflows/reusable-commitlint.yml@main
    with:
      base-ref: ${{ github.event.pull_request.base.sha }}
      head-ref: ${{ github.event.pull_request.head.sha }}
```

### Notas

- Usa la composite action `nova-setup-node` que cachea `node_modules` y ejecuta `npm ci`.
- Falla con exit code 1 si algún commit no cumple la convención.
- El `verbose` mode muestra qué regla falló por commit.

---

## 10. reusable-release-please.yml

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

## 11. reusable-changelog.yml

Workflow reutilizable que genera `CHANGELOG.md` desde el historial de commits usando `conventional-changelog-cli`. Útil como fallback para proyectos que aún no usan `release-please` o para regenerar el changelog manualmente.

### Parámetros de Entrada

| Parámetro | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `from-ref` | `string` | no | `''` | SHA/branch/tag inicial (vacío = desde el inicio del proyecto) |
| `to-ref` | `string` | no | `'HEAD'` | SHA/branch/tag final |
| `output-file` | `string` | no | `'CHANGELOG.md'` | Path del archivo de salida |
| `preset` | `string` | no | `'angular'` | Preset de conventional-changelog (`angular`, `standard`, `conventionalcommits`) |
| `node-version` | `string` | no | `'20'` | Versión de Node.js |
| `commit-changes` | `string` | no | `'false'` | Si es `'true'`, hace commit + push del CHANGELOG (solo `workflow_dispatch`) |

### Secretos Requeridos

Ninguno obligatorio (necesita `contents:write` solo si `commit-changes='true'`).

### Uso desde un workflow llamador

```yaml
# .github/workflows/changelog.yml (en cada repo)
name: Generate Changelog
on:
  workflow_dispatch:  # ejecucion manual
  push:
    branches: [main]
    paths-ignore: ['CHANGELOG.md']

jobs:
  changelog:
    uses: ahincho/nova-devops/.github/workflows/reusable-changelog.yml@main
    with:
      preset: angular
      commit-changes: 'true'
```

### Notas

- Usa la composite action `nova-setup-node` para cache + install.
- Instala `conventional-changelog-cli` y `conventional-changelog-config-spec` con `npm install --no-save`.
- Sube el CHANGELOG.md generado como artifact `changelog`.
- Si `commit-changes='true'` y el archivo cambió, hace commit automático con `github-actions[bot]`.

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
      fail-on-missing: 'true'  # obligatorio para Maven Central
```

**Comportamiento por defecto (`fail-on-missing='false'`):** si los inputs están vacíos, emite un `::notice::` y continúa sin error. Esto permite que el mismo workflow reusable funcione tanto para GitHub Packages (sin GPG) como para Maven Central (con GPG).

---

## Versionado de las Composite Actions

Las composite actions siguen el mismo patrón SemVer que las librerías Java:

- `v1.0.0` — primera versión estable
- Breaking changes en la API de inputs/outputs → bump major
- Nuevos inputs opcionales → bump minor
- Bugfixes internos → bump patch

Hasta que se genere el primer tag, se pueden referenciar con `@main` (HEAD) o `@<commit-sha>` (inmutable).
