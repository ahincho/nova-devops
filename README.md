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

### Workflows de Publicacion Multi-Registry

Workflows de publish con soporte para multiples registries (GitHub Packages, Maven Central, Nexus). Todos usan la composite action `nova-setup-java` y soportan `visibility` / `dry-run` inputs.

| Workflow | Archivo | Descripción |
|---|---|---|
| [Multi-Registry Gradle](#12-reusable-publish-gradle-multi-registryyml) | `reusable-publish-gradle-multi-registry.yml` | Publica a GitHub Packages **y** Maven Central en 1 run |
| [Multi-Registry Maven](#13-reusable-publish-maven-multi-registryyml) | `reusable-publish-maven-multi-registry.yml` | Publica a GitHub Packages **y** Maven Central en 1 run |
| [Maven Central Gradle](#14-reusable-publish-gradle-maven-centralyml) | `reusable-publish-gradle-maven-central.yml` | Solo Maven Central (GPG **requerido**) |
| [Maven Central Maven](#15-reusable-publish-maven-maven-centralyml) | `reusable-publish-maven-maven-central.yml` | Solo Maven Central (GPG **requerido**) |
| [Nexus Gradle](#16-reusable-publish-gradle-nexusyml) | `reusable-publish-gradle-nexus.yml` | Solo Nexus on-premise (GPG opcional) |
| [Nexus Maven](#17-reusable-publish-maven-nexusyml) | `reusable-publish-maven-nexus.yml` | Solo Nexus on-premise (GPG opcional) |

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
    needs: version-bump
    uses: <org>/nova-devops/.github/workflows/reusable-publish-gradle.yml@main
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 12. reusable-publish-gradle-multi-registry.yml

Workflow reutilizable que publica una libreria Gradle a **GitHub Packages y Maven Central** en una sola ejecucion. Salta Maven Central si no se proporcionan las credenciales (`MAVEN_USERNAME` + `MAVEN_TOKEN`).

### Parametros de Entrada

| Parametro | Tipo | Requerido | Default | Descripcion |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Version de Java |
| `visibility` | `string` | no | `vars.NOVA_PACKAGE_VISIBILITY` o `'public'` | Visibilidad para GitHub Packages |
| `dry-run` | `string` | no | `'false'` | Si es `'true'`, usa `gradle publishDryRun` |
| `gpg-key-id` | `string` | no | `''` | Fingerprint GPG (pasado como input) |
| `gpg-key` | `string` | no | `''` | Clave privada GPG (pasada como input) |
| `gpg-password` | `string` | no | `''` | Passphrase GPG (opcional) |

### Secretos Requeridos

| Secreto | Requerido | Descripcion |
|---|---|---|
| `GITHUB_TOKEN` | si | Para autenticarse con GitHub Packages |
| `MAVEN_USERNAME` | no | Sonatype OSSRH username (sin el, salta Maven Central) |
| `MAVEN_TOKEN` | no | Sonatype OSSRH token (sin el, salta Maven Central) |

### Notas

- Usa `nova-setup-java` (composite action) y `nova-setup-gpg` con `fail-on-missing='false'`.
- Detecta automaticamente si hay credenciales de Maven Central y decide a cual(es) registry(s) publicar.
- Para que funcione end-to-end, el `build.gradle.kts` debe tener publications/repositories configurados para cada target.

---

## 13. reusable-publish-maven-multi-registry.yml

Igual al #12 pero para proyectos **Maven**. Publica a GitHub Packages y Maven Central. Genera `~/.m2/settings.xml` automaticamente con las credenciales de ambos.

### Parametros de Entrada

Igual que #12.

### Secretos Requeridos

| Secreto | Requerido | Descripcion |
|---|---|---|
| `GITHUB_TOKEN` | si | Para autenticarse con GitHub Packages |
| `MAVEN_USERNAME` | no | Sonatype OSSRH username (sin el, salta Maven Central) |
| `MAVEN_TOKEN` | no | Sonatype OSSRH token (sin el, salta Maven Central) |

### Notas

- El `pom.xml` debe tener profiles separados (`github-publish`, `maven-central-publish`) para cada registry.

---

## 14. reusable-publish-gradle-maven-central.yml

Workflow reutilizable que publica **solo a Maven Central** (Sonatype OSSRH). **GPG es REQUERIDO** (firma obligatoria de Maven Central).

### Parametros de Entrada

| Parametro | Tipo | Requerido | Default | Descripcion |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Version de Java |
| `gpg-key-id` | `string` | **si** | — | Fingerprint GPG |
| `gpg-key` | `string` | **si** | — | Clave privada GPG ASCII-armored |
| `gpg-password` | `string` | no | `''` | Passphrase GPG |
| `dry-run` | `string` | no | `'false'` | Si es `'true'`, usa `--dry-run` |

### Secretos Requeridos

| Secreto | Descripcion |
|---|---|
| `MAVEN_USERNAME` | Sonatype OSSRH username |
| `MAVEN_TOKEN` | Sonatype OSSRH token |

### Notas

- Usa `nova-setup-gpg` con `fail-on-missing='true'` (falla si no hay clave).
- **Prereq (NOVA-SEMVER-14):** crear el namespace `pe.edu.nova` en Sonatype OSSRH.
- **Prereq (NOVA-SEMVER-29):** generar la clave GPG real (backlog).

---

## 15. reusable-publish-maven-maven-central.yml

Igual al #14 pero para proyectos **Maven**. Genera `settings.xml` con la credencial de Sonatype.

### Parametros de Entrada

Igual que #14.

### Secretos Requeridos

Igual que #14.

### Notas

- El `pom.xml` debe tener un profile `maven-central-publish` configurado.

---

## 16. reusable-publish-gradle-nexus.yml

Workflow reutilizable que publica a un **Nexus on-premise**. GPG opcional (depende de la politica del Nexus).

### Parametros de Entrada

| Parametro | Tipo | Requerido | Default | Descripcion |
|---|---|---|---|---|
| `java-version` | `string` | no | `'25'` | Version de Java |
| `nexus-url` | `string` | **si** | — | URL base del Nexus (ej: `https://nexus.example.com`) |
| `nexus-repository` | `string` | **si** | — | Nombre del repo (ej: `nova-releases`, `nova-snapshots`) |
| `gpg-key-id` | `string` | no | `''` | Fingerprint GPG (opcional) |
| `gpg-key` | `string` | no | `''` | Clave GPG (opcional) |
| `gpg-password` | `string` | no | `''` | Passphrase GPG |
| `dry-run` | `string` | no | `'false'` | Si es `'true'`, usa `--dry-run` |

### Secretos Requeridos

| Secreto | Descripcion |
|---|---|
| `NEXUS_USERNAME` | Nexus username |
| `NEXUS_PASSWORD` | Nexus password o token |

### Notas

- El `build.gradle.kts` debe tener una `MavenPublication` llamada `nova` con un `maven { url = ... }` repository configurable via `nexus.url` y `nexus.repository` Gradle properties.

---

## 17. reusable-publish-maven-nexus.yml

Igual al #16 pero para proyectos **Maven**. Genera `settings.xml` con la credencial de Nexus.

### Parametros de Entrada

Igual que #16.

### Secretos Requeridos

Igual que #16.

### Notas

- El `pom.xml` debe tener un profile `nexus-publish` con `<distributionManagement>` configurable via `nexus.url` y `nexus.repository` system properties.

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

Cada repositorio de librería debe tener configurados los siguientes secretos (los marcados como **opcional** solo se requieren si se usa el workflow que los consume):

| Secreto | Usado por | Descripción |
|---|---|---|
| `SONAR_TOKEN` | `reusable-sonarcloud-maven.yml` / `reusable-sonarcloud-gradle.yml` | Token de autenticación de SonarCloud |
| `GH_PAT` | `reusable-version-bump-maven.yml` / `reusable-version-bump-gradle.yml` | Token de acceso personal con permisos de push |
| `GITHUB_TOKEN` | `reusable-publish-maven.yml` / `reusable-publish-gradle.yml` / `reusable-publish-{...}-multi-registry.yml` / `reusable-release-please.yml` | Token automático de GitHub (disponible por defecto) |
| `MAVEN_USERNAME` *(opcional)* | `reusable-publish-{...}-multi-registry.yml` / `reusable-publish-{...}-maven-central.yml` | Sonatype OSSRH username (requerido para Maven Central) |
| `MAVEN_TOKEN` *(opcional)* | `reusable-publish-{...}-multi-registry.yml` / `reusable-publish-{...}-maven-central.yml` | Sonatype OSSRH token (requerido para Maven Central) |
| `NEXUS_USERNAME` *(opcional)* | `reusable-publish-{...}-nexus.yml` | Nexus username (solo para on-premise) |
| `NEXUS_PASSWORD` *(opcional)* | `reusable-publish-{...}-nexus.yml` | Nexus password o token (solo para on-premise) |
| `GPG_SIGNING_KEY_ID` *(opcional)* | workflows que publican a Maven Central | Fingerprint de la clave GPG (pasado como input a `nova-setup-gpg`) |
| `GPG_SIGNING_KEY` *(opcional)* | workflows que publican a Maven Central | Clave privada GPG ASCII-armored |
| `GPG_SIGNING_PASSWORD` *(opcional)* | workflows que publican a Maven Central | Passphrase de la clave GPG |

### Variables de Repositorio (no secretos)

| Variable | Usado por | Default | Descripción |
|---|---|---|---|
| `NOVA_PACKAGE_VISIBILITY` | `reusable-publish-{gradle,maven}.yml` | `'public'` | Visibilidad por defecto del paquete (puede ser sobreescrita por el input `visibility` del workflow) |

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
