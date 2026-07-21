BeforeAll {
  $script:wfPath = Join-Path $PSScriptRoot '..\.github\workflows\reusable-package-retention.yml'
  $script:wfContent = if (Test-Path -LiteralPath $script:wfPath) {
    Get-Content -LiteralPath $script:wfPath -Raw
  } else { '' }
}

Describe 'reusable-package-retention.yml - workflow structure' {
  It 'workflow file exists' {
    Test-Path -LiteralPath $script:wfPath | Should -BeTrue
  }

  It 'declares workflow_call trigger' {
    $script:wfContent | Should -Match 'workflow_call:'
  }

  It 'has the 5 expected inputs' {
    $expectedInputs = @(
      'package-pattern',
      'snapshot-retention-days',
      'prerelease-retention-days',
      'dry-run',
      'fail-on-error'
    )
    foreach ($inp in $expectedInputs) {
      $pattern = "(?m)^\s{6}${inp}:\s*$"
      $script:wfContent | Should -Match $pattern -Because "input $inp must be declared"
    }
  }

  It 'package-pattern defaults to wildcard *' {
    $script:wfContent | Should -Match "(?ms)package-pattern:.*?default:\s*'\*'"
  }

  It 'snapshot-retention-days defaults to 30' {
    $script:wfContent | Should -Match "(?ms)snapshot-retention-days:.*?default:\s*30"
  }

  It 'prerelease-retention-days defaults to 90' {
    $script:wfContent | Should -Match "(?ms)prerelease-retention-days:.*?default:\s*90"
  }

  It 'dry-run defaults to false' {
    $script:wfContent | Should -Match "(?ms)dry-run:.*?default:\s*false"
  }

  It 'fail-on-error defaults to false' {
    $script:wfContent | Should -Match "(?ms)fail-on-error:.*?default:\s*false"
  }
}

Describe 'reusable-package-retention.yml - permissions and concurrency' {
  It 'declares packages: write permission' {
    $script:wfContent | Should -Match 'packages:\s*write'
  }

  It 'declares contents: read permission' {
    $script:wfContent | Should -Match 'contents:\s*read'
  }

  It 'does NOT declare contents: write (least privilege)' {
    $script:wfContent | Should -Not -Match 'contents:\s*write'
  }

  It 'has concurrency group with no cancel-in-progress' {
    # The retention workflow is destructive - concurrent runs should queue, not cancel
    $script:wfContent | Should -Match "group: package-retention-"
    $script:wfContent | Should -Match 'cancel-in-progress:\s*false'
  }

  It 'has timeout-minutes (30)' {
    $script:wfContent | Should -Match 'timeout-minutes:\s*30'
  }
}

Describe 'reusable-package-retention.yml - bash script integrity' {
  BeforeAll {
    # Extract the run: block (everything between "run: |" and EOF)
    $runMatch = [regex]::Match($script:wfContent, '(?s)run: \|\s*\n(.*?)\Z')
    $script:bashScript = if ($runMatch.Success) { $runMatch.Groups[1].Value } else { '' }
  }

  It 'extracts a non-empty run block' {
    $script:bashScript.Length | Should -BeGreaterThan 100
  }

  It 'uses gh api for listing packages' {
    $script:bashScript | Should -Match 'gh api "/repos/\$\{REPO\}/packages\?package_type=maven"'
  }

  It 'uses gh api for listing versions' {
    $script:bashScript | Should -Match 'gh api "/repos/\$\{REPO\}/packages/maven/\$\{pkg\}/versions"'
  }

  It 'uses gh api DELETE for removing versions' {
    $script:bashScript | Should -Match 'gh api -X DELETE "/repos/\$\{REPO\}/packages/maven/'
  }

  It 'has classify_version function with snapshot detection' {
    $script:bashScript | Should -Match 'classify_version\(\)'
    $script:bashScript | Should -Match '-SNAPSHOT\$'
  }

  It 'has classify_version with prerelease detection (alpha/beta/rc/milestone/M/RC)' {
    $script:bashScript | Should -Match 'alpha\|beta\|rc\|milestone\|M\|RC'
  }

  It 'has age_days function' {
    $script:bashScript | Should -Match 'age_days\(\)'
  }

  It 'has should_delete function (decision logic)' {
    $script:bashScript | Should -Match 'should_delete\(\)'
  }

  It 'respects dry-run mode (no actual delete)' {
    $script:bashScript | Should -Match '\[ "\$DRY_RUN" = "true" \]'
    $script:bashScript | Should -Match 'would-delete'
  }

  It 'writes step summary' {
    $script:bashScript | Should -Match '\$GITHUB_STEP_SUMMARY'
  }

  It 'uses GITHUB_TOKEN for API auth' {
    # GH_TOKEN is in the YAML env: block (above run:), not inside the bash script itself
    $script:wfContent | Should -Match 'GH_TOKEN:'
    $script:wfContent | Should -Match 'github\.token'
  }
}

Describe 'reusable-package-retention.yml - bash syntax via Git Bash' {
  BeforeAll {
    $gitBash = 'C:\Program Files\Git\bin\bash.exe'
    $script:hasBash = Test-Path -LiteralPath $gitBash

    $runMatch = [regex]::Match($script:wfContent, '(?s)run: \|\s*\n(.*?)\Z')
    $script:bashScript = if ($runMatch.Success) { $runMatch.Groups[1].Value } else { '' }

    if ($script:hasBash -and $script:bashScript) {
      $tempFile = Join-Path $env:TEMP 'retention-bash-syntax-test.sh'
      Set-Content -LiteralPath $tempFile -Value $script:bashScript -NoNewline
      $script:syntaxCheck = & $gitBash -n $tempFile 2>&1
      $script:syntaxExit = $LASTEXITCODE
      Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
    } else {
      $script:syntaxExit = -1
    }
  }

  It 'bash -n passes (no syntax errors)' {
    if ($script:hasBash) {
      $script:syntaxCheck | Should -BeNullOrEmpty
      $script:syntaxExit | Should -Be 0
    } else {
      Set-ItResult -Skipped -Because 'bash.exe not available on this machine'
    }
  }
}

Describe 'reusable-package-retention.yml - branch-pinned to @main (Lote P compliance)' {
  BeforeAll {
    $script:wfPath2 = Join-Path $PSScriptRoot '..\.github\workflows\reusable-package-retention.yml'
    $script:wfContent2 = if (Test-Path -LiteralPath $script:wfPath2) {
      Get-Content -LiteralPath $script:wfPath2 -Raw
    } else { '' }
  }

  It 'has the Lote Q header comment (mentions SHA-pin)' {
    $script:wfContent2 | Should -Match 'SHA.?pin'
    $script:wfContent2 | Should -Match 'Lote Q'
  }

  It 'has SHA pins on uses: refs (Lote Q reverted Lote P branch-pinning) - or no uses at all' {
    # reusable-package-retention.yml uses no composite actions (pure bash + gh CLI),
    # so the SHA-pin requirement is vacuously satisfied. The header comment still
    # documents the Lote Q convention for consistency.
    if ($script:wfContent2 -match 'uses:\s+ahincho/') {
      $script:wfContent2 | Should -Match '@[a-f0-9]{40}'
    }
  }
}

Describe 'reusable-release-publish.yml + reusable-release-maven-publish.yml - SLSA provenance (Lote M)' {
  BeforeAll {
    $script:gradleWf = Join-Path $PSScriptRoot '..\.github\workflows\reusable-release-publish.yml'
    $script:mavenWf  = Join-Path $PSScriptRoot '..\.github\workflows\reusable-release-maven-publish.yml'
    $script:gradleContent = if (Test-Path -LiteralPath $script:gradleWf) {
      Get-Content -LiteralPath $script:gradleWf -Raw
    } else { '' }
    $script:mavenContent = if (Test-Path -LiteralPath $script:mavenWf) {
      Get-Content -LiteralPath $script:mavenWf -Raw
    } else { '' }
  }

  It 'Gradle variant uses actions/attest-build-provenance (SHA-pinned in Lote Q)' {
    $script:gradleContent | Should -Match 'actions/attest-build-provenance@e8998f949152b193b063cb0ec769d69d929409be'
  }

  It 'Gradle variant attests build/libs/*.jar (canonical Gradle output)' {
    $script:gradleContent | Should -Match "subject-path:\s*'build/libs/\*\.jar'"
  }

  It 'Maven variant uses actions/attest-build-provenance (SHA-pinned in Lote Q)' {
    $script:mavenContent | Should -Match 'actions/attest-build-provenance@e8998f949152b193b063cb0ec769d69d929409be'
  }

  It 'Maven variant uses a glob that catches multi-module target/*.jar' {
    $script:mavenContent | Should -Match "subject-path:\s*'\*\*/target/\*\.jar'"
  }

  It 'Gradle attest step is positioned AFTER the publish step' {
    $publishIdx = $script:gradleContent.IndexOf('Publish to GitHub Packages')
    $attestIdx  = $script:gradleContent.IndexOf('attest-build-provenance')
    $publishIdx | Should -BeGreaterOrEqual 0
    $attestIdx  | Should -BeGreaterOrEqual 0
    $attestIdx  | Should -BeGreaterThan $publishIdx
  }

  It 'Maven attest step is positioned AFTER the publish step' {
    $publishIdx = $script:mavenContent.IndexOf('Publish to GitHub Packages')
    $attestIdx  = $script:mavenContent.IndexOf('attest-build-provenance')
    $publishIdx | Should -BeGreaterOrEqual 0
    $attestIdx  | Should -BeGreaterOrEqual 0
    $attestIdx  | Should -BeGreaterThan $publishIdx
  }

  It 'Gradle attest step is SKIPPED in dry-run mode' {
    # The attest step should have `if: inputs.dry-run != 'true'` so we never
    # try to attest a non-existent (publishToMavenLocal) artifact.
    # Check that the attest block includes the dry-run guard.
    $attestBlock = [regex]::Match(
      $script:gradleContent,
      '(?ms)Attest built jars[\s\S]+?(?=      - name:|\Z)'
    ).Value
    $attestBlock | Should -Match "if: inputs\.dry-run != 'true'"
  }

  It 'Maven attest step is SKIPPED in dry-run mode' {
    $attestBlock = [regex]::Match(
      $script:mavenContent,
      '(?ms)Attest deployed jars[\s\S]+?(?=      - name:|\Z)'
    ).Value
    $attestBlock | Should -Match "if: inputs\.dry-run != 'true'"
  }
}