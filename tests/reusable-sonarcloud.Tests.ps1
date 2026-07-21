BeforeAll {
  $script:gradleWf = Join-Path $PSScriptRoot '..\.github\workflows\reusable-sonarcloud-gradle.yml'
  $script:mavenWf  = Join-Path $PSScriptRoot '..\.github\workflows\reusable-sonarcloud-maven.yml'
  $script:gradleContent = if (Test-Path -LiteralPath $script:gradleWf) {
    Get-Content -LiteralPath $script:gradleWf -Raw
  } else { '' }
  $script:mavenContent = if (Test-Path -LiteralPath $script:mavenWf) {
    Get-Content -LiteralPath $script:mavenWf -Raw
  } else { '' }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - input surface (Lote R parametrization)' {
  # The 19 (gradle) / 18 (maven) inputs the parametrization exposes. Exhaustive
  # list - any new input MUST be added here, any old input MUST NOT be removed
  # without updating this list + the CHANGELOG.
  It 'Gradle variant declares the expected 19 inputs' {
    $expected = @(
      'sonar-org', 'sonar-project-key',
      'java-version', 'gradle-version', 'jacoco-report-path',
      'sonar-host-url',
      'wait-for-quality-gate', 'quality-gate-timeout',
      'coverage-threshold', 'new-code-coverage-threshold',
      'sonar-sources', 'sonar-tests',
      'sonar-exclusions', 'sonar-test-exclusions', 'sonar-coverage-exclusions',
      'branch', 'pull-request-base',
      'fail-on-missing-token', 'dry-run'
    )
    foreach ($inp in $expected) {
      $pattern = "(?m)^\s{6}${inp}:\s*$"
      $script:gradleContent | Should -Match $pattern -Because "Gradle input '$inp' must be declared"
    }
  }

  It 'Maven variant declares the expected 18 inputs (no gradle-version)' {
    $expected = @(
      'sonar-org', 'sonar-project-key',
      'java-version', 'jacoco-report-path',
      'sonar-host-url',
      'wait-for-quality-gate', 'quality-gate-timeout',
      'coverage-threshold', 'new-code-coverage-threshold',
      'sonar-sources', 'sonar-tests',
      'sonar-exclusions', 'sonar-test-exclusions', 'sonar-coverage-exclusions',
      'branch', 'pull-request-base',
      'fail-on-missing-token', 'dry-run'
    )
    foreach ($inp in $expected) {
      $pattern = "(?m)^\s{6}${inp}:\s*$"
      $script:mavenContent | Should -Match $pattern -Because "Maven input '$inp' must be declared"
    }
  }

  It 'sonar-org and sonar-project-key are the only required inputs' {
    # Required: must have `required: true`
    $script:gradleContent | Should -Match "(?ms)sonar-org:.*?required:\s*true"
    $script:gradleContent | Should -Match "(?ms)sonar-project-key:.*?required:\s*true"
    $script:mavenContent  | Should -Match "(?ms)sonar-org:.*?required:\s*true"
    $script:mavenContent  | Should -Match "(?ms)sonar-project-key:.*?required:\s*true"

    # All other inputs should default to optional (required: false)
    foreach ($inp in @('java-version', 'jacoco-report-path', 'sonar-host-url',
                       'wait-for-quality-gate', 'quality-gate-timeout',
                       'coverage-threshold', 'new-code-coverage-threshold',
                       'sonar-sources', 'sonar-tests',
                       'sonar-exclusions', 'sonar-test-exclusions', 'sonar-coverage-exclusions',
                       'branch', 'pull-request-base', 'fail-on-missing-token', 'dry-run')) {
      $script:gradleContent | Should -Match "(?ms)${inp}:.*?required:\s*false"
      $script:mavenContent  | Should -Match "(?ms)${inp}:.*?required:\s*false"
    }
  }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - Quality Gate enforcement (main hardening)' {
  It 'Gradle variant passes -Dsonar.qualitygate.wait (driven by wait-for-quality-gate input)' {
    $script:gradleContent | Should -Match 'sonar\.qualitygate\.wait=\${{ inputs\.wait-for-quality-gate }}'
  }

  It 'Maven variant passes -Dsonar.qualitygate.wait' {
    $script:mavenContent | Should -Match 'sonar\.qualitygate\.wait=\${{ inputs\.wait-for-quality-gate }}'
  }

  It 'Gradle variant passes -Dsonar.qualitygate.timeout (driven by quality-gate-timeout input)' {
    $script:gradleContent | Should -Match 'sonar\.qualitygate\.timeout=\${{ inputs\.quality-gate-timeout }}'
  }

  It 'Maven variant passes -Dsonar.qualitygate.timeout' {
    $script:mavenContent | Should -Match 'sonar\.qualitygate\.timeout=\${{ inputs\.quality-gate-timeout }}'
  }

  It 'wait-for-quality-gate defaults to true (the hardening)' {
    $script:gradleContent | Should -Match "(?ms)wait-for-quality-gate:.*?default:\s*true"
    $script:mavenContent  | Should -Match "(?ms)wait-for-quality-gate:.*?default:\s*true"
  }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - Coverage thresholds' {
  It 'Gradle variant wires coverage-threshold to -Dsonar.coverage.threshold' {
    $script:gradleContent | Should -Match 'sonar\.coverage\.threshold=\${{ inputs\.coverage-threshold }}'
  }

  It 'Maven variant wires coverage-threshold' {
    $script:mavenContent | Should -Match 'sonar\.coverage\.threshold=\${{ inputs\.coverage-threshold }}'
  }

  It 'Gradle variant wires new-code-coverage-threshold to -Dsonar.new-code.coverage.threshold' {
    $script:gradleContent | Should -Match 'sonar\.new-code\.coverage\.threshold=\${{ inputs\.new-code-coverage-threshold }}'
  }

  It 'Maven variant wires new-code-coverage-threshold' {
    $script:mavenContent | Should -Match 'sonar\.new-code\.coverage\.threshold=\${{ inputs\.new-code-coverage-threshold }}'
  }

  It 'new-code-coverage-threshold defaults to 80 (Nova convention)' {
    $script:gradleContent | Should -Match "(?ms)new-code-coverage-threshold:.*?default:\s*80"
    $script:mavenContent  | Should -Match "(?ms)new-code-coverage-threshold:.*?default:\s*80"
  }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - Source layout parametrization' {
  It 'Gradle variant wires sonar.sources' {
    $script:gradleContent | Should -Match 'sonar\.sources=\${{ inputs\.sonar-sources }}'
  }

  It 'Maven variant wires sonar.sources' {
    $script:mavenContent | Should -Match 'sonar\.sources=\${{ inputs\.sonar-sources }}'
  }

  It 'Both variants wire sonar.tests, sonar.exclusions, sonar.test.exclusions, sonar.coverage.exclusions' {
    # Build the literal substring via simple concatenation. Use a here-string
  # marker pattern - the actual literal text contains ${{ which PowerShell
  # would misinterpret in single quotes, so we build it character by character.
  foreach ($prop in @('sonar.tests', 'sonar.exclusions', 'sonar.test.exclusions', 'sonar.coverage.exclusions')) {
    $gradleInput = $prop.Replace('.', '-')
    # $literal = "sonar.tests=${{ inputs.sonar-tests }}" (built without ${{ parsing)
    $dollar = [char]36
    $literal = $prop + '=' + $dollar + '{{ inputs.' + $gradleInput + ' }}'
    $script:gradleContent | Should -Match ([regex]::Escape($literal))
    $script:mavenContent  | Should -Match ([regex]::Escape($literal))
  }
}

It 'sonar-exclusions defaults exclude generated/, build/, *.class (Gradle)' {
  $script:gradleContent | Should -Match 'sonar-exclusions:'
  $script:gradleContent | Should -Match 'build/\*\*'
  $script:gradleContent | Should -Match 'generated/\*\*'
  $script:gradleContent | Should -Match '\*\.class'
}

It 'sonar-exclusions defaults exclude generated/, target/, *.class (Maven)' {
  $script:mavenContent | Should -Match 'sonar-exclusions:'
  $script:mavenContent | Should -Match 'target/\*\*'
  $script:mavenContent | Should -Match 'generated/\*\*'
  $script:mavenContent | Should -Match '\*\.class'
}
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - Branch strategy' {
  It 'Both variants resolve branch via a dedicated step (id: branch)' {
    $script:gradleContent | Should -Match 'id: branch'
    $script:mavenContent  | Should -Match 'id: branch'
  }

  It 'Branch resolution prefers input.branch over GitHub auto-detect' {
    # The bash logic must check INPUT_BRANCH first
    $script:gradleContent | Should -Match 'INPUT_BRANCH'
    $script:mavenContent  | Should -Match 'INPUT_BRANCH'
  }

  It 'PR analysis uses PR number as branch (sonar.pullrequest.branch)' {
    # If event=pull_request and no input override, use PR number
    $script:gradleContent | Should -Match 'PR_NUMBER'
    $script:mavenContent  | Should -Match 'PR_NUMBER'
  }

  It 'Both variants wire -Dsonar.branch.name to the resolved branch' {
    $script:gradleContent | Should -Match 'sonar\.branch\.name=\${{ steps\.branch\.outputs\.branch }}'
    $script:mavenContent  | Should -Match 'sonar\.branch\.name=\${{ steps\.branch\.outputs\.branch }}'
  }

  It 'Both variants wire -Dsonar.pullrequest.base to the resolved base' {
    $script:gradleContent | Should -Match 'sonar\.pullrequest\.base=\${{ steps\.branch\.outputs\.pr_base }}'
    $script:mavenContent  | Should -Match 'sonar\.pullrequest\.base=\${{ steps\.branch\.outputs\.pr_base }}'
  }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - Behavior flags' {
  It 'fail-on-missing-token defaults to false (skip-with-warning, dormant mode)' {
    $script:gradleContent | Should -Match "(?ms)fail-on-missing-token:.*?default:\s*false"
    $script:mavenContent  | Should -Match "(?ms)fail-on-missing-token:.*?default:\s*false"
  }

  It 'check-token step enforces fail-on-missing-token when true' {
    # The bash should conditionally exit 1 when FAIL_ON_MISSING=true
    $script:gradleContent | Should -Match 'FAIL_ON_MISSING'
    $script:mavenContent  | Should -Match 'FAIL_ON_MISSING'
    $script:gradleContent | Should -Match 'fail-on-missing-token=true.*Failing'
    $script:mavenContent  | Should -Match 'fail-on-missing-token=true.*Failing'
  }

  It 'dry-run defaults to false' {
    $script:gradleContent | Should -Match "(?ms)dry-run:.*?default:\s*false"
    $script:mavenContent  | Should -Match "(?ms)dry-run:.*?default:\s*false"
  }

  It 'dry-run maps to -Dsonar.scanner.dumpToFile (analyze locally without upload)' {
    $script:gradleContent | Should -Match 'sonar\.scanner\.dumpToFile=\${{ inputs\.dry-run }}'
    $script:mavenContent  | Should -Match 'sonar\.scanner\.dumpToFile=\${{ inputs\.dry-run }}'
  }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - SonarCloud connection' {
  It 'sonar-host-url defaults to https://sonarcloud.io' {
    $script:gradleContent | Should -Match "(?ms)sonar-host-url:.*?default:\s*'https://sonarcloud\.io'"
    $script:mavenContent  | Should -Match "(?ms)sonar-host-url:.*?default:\s*'https://sonarcloud\.io'"
  }

  It 'Both variants wire -Dsonar.host.url' {
    $script:gradleContent | Should -Match 'sonar\.host\.url=\${{ inputs\.sonar-host-url }}'
    $script:mavenContent  | Should -Match 'sonar\.host\.url=\${{ inputs\.sonar-host-url }}'
  }
}

Describe 'reusable-sonarcloud-{gradle,maven}.yml - branch-pinned to @main (Lote P compliance)' {
  It 'Both files have the Lote P header comment (mentions @main and @dev)' {
    $script:gradleContent | Should -Match '@main'
    $script:gradleContent | Should -Match '@dev'
    $script:mavenContent  | Should -Match '@main'
    $script:mavenContent  | Should -Match '@dev'
  }

  It 'Neither file has SHA pins (Lote P superseded Lote E)' {
    $script:gradleContent | Should -Not -Match '@[a-f0-9]{40}'
    $script:mavenContent  | Should -Not -Match '@[a-f0-9]{40}'
  }
}