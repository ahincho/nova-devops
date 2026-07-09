# nova-devops

Repositorio centralizado de workflows reutilizables de GitHub Actions para el ecosistema de librerías Java de `pe.edu.galaxy.training.java`.

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

### Beneficio del Caché de Dependencias

Al separar los workflows por herramienta de build, cada variante configura `actions/setup-java@v4` con el parámetro `cache` correspondiente (`'maven'` o `'gradle'`). Esto habilita el caché nativo de dependencias de GitHub Actions, reduciendo significativamente los tiempos de ejecución en pipelines subsecuentes.

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
| `GITHUB_TOKEN` | `reusable-publish-maven.yml` / `reusable-publish-gradle.yml` | Token automático de GitHub (disponible por defecto) |
