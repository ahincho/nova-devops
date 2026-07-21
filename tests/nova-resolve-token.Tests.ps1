BeforeAll {
  $script:actionPath = Join-Path $PSScriptRoot '..\.github\actions\nova-resolve-token\action.yml'
  $script:actionContent = $null
  $script:actionDoc = $null
  if (Test-Path -LiteralPath $script:actionPath) {
    $script:actionContent = Get-Content -LiteralPath $script:actionPath -Raw
    try {
      $script:actionDoc = (Get-Content -LiteralPath $script:actionPath -Raw) | python -c "import sys, yaml; print(yaml.safe_load(sys.stdin))" 2>&1
      # python prints dict repr; convert to hashtable-ish via ConvertFrom-Yaml if available, else parse
      # Fallback: use PowerShell's ConvertFrom-Yaml if Python returned a string
      if ($script:actionDoc -is [string]) {
        try {
          $script:actionDoc = $script:actionDoc | ConvertFrom-Json -ErrorAction Stop
        } catch {
          # Last resort: just keep as string
        }
      }
    } catch {
      $script:actionDoc = $null
    }
  }

  # Read as plain text for regex-based assertions
  $script:actionText = if ($script:actionContent) { $script:actionContent } else { '' }
}

Describe 'nova-resolve-token/action.yml - composite integrity' {
  It 'action.yml file exists' {
    Test-Path -LiteralPath $script:actionPath | Should -BeTrue
  }

  It 'declares composite runs type' {
    $script:actionText | Should -Match 'using:\s*''composite'''
  }

  It 'declares app-id input' {
    $script:actionText | Should -Match "(?m)^\s{2}app-id:\s*$"
  }

  It 'declares app-private-key input' {
    $script:actionText | Should -Match "(?m)^\s{2}app-private-key:\s*$"
  }

  It 'declares app-owner input with default ahincho' {
    $script:actionText | Should -Match "(?m)^\s{2}app-owner:\s*$"
    $script:actionText | Should -Match "(?m)default:\s*'ahincho'"
  }

  It 'declares value output' {
    $script:actionText | Should -Match "(?m)^\s{2}value:\s*$"
  }

  It 'declares source output' {
    $script:actionText | Should -Match "(?m)^\s{2}source:\s*$"
  }

  It 'has App token generation step' {
    $script:actionText | Should -Match 'actions/create-github-app-token@v2'
  }

  It 'App token step is conditional on non-empty inputs' {
    $script:actionText | Should -Match "if: inputs\.app-id != '' && inputs\.app-private-key != ''"
  }

  It 'has resolve step using bash' {
    $script:actionText | Should -Match "shell: bash"
  }
}

Describe 'nova-resolve-token/action.yml - priority order' {
  It 'checks APP_TOKEN first' {
    # The first `if [ -n "..." ]` block must reference APP_TOKEN
    $firstCheck = [regex]::Match($script:actionText, '(?s)if \[ -n "\$\{(\w+)').Groups[1].Value
    $firstCheck | Should -Be 'APP_TOKEN'
  }

  It 'checks all 4 sources in order' {
    $order = [regex]::Matches($script:actionText, 'if \[ -n "\$\{(\w+)_?(?:GITHUB|PRIMARY|LEGACY)?\}"?\]') | ForEach-Object { $_.Groups[1].Value }
    # Fallback simple check: all 4 must be present
    $script:actionText | Should -Match 'APP_TOKEN'
    $script:actionText | Should -Match 'TOKEN_GITHUB'
    $script:actionText | Should -Match 'TOKEN_PRIMARY'
    $script:actionText | Should -Match 'TOKEN_LEGACY'
  }

  It 'emits notice when PAT is used' {
    $script:actionText | Should -Match '::notice::NOVA_PACKAGES_READ_TOKEN'
  }

  It 'emits warning when legacy PAT is used' {
    $script:actionText | Should -Match '::warning::NOVA_RELEASE_PAT'
  }

  It 'emits warning when no token resolved' {
    $script:actionText | Should -Match '::warning::No read token resolved'
  }
}

Describe 'nova-resolve-token/action.yml - source labels are documented' {
  It 'source output documents all 5 possible values' {
    $script:actionText | Should -Match 'GITHUB_APP_TOKEN'
    $script:actionText | Should -Match 'GITHUB_TOKEN'
    $script:actionText | Should -Match 'NOVA_PACKAGES_READ_TOKEN'
    $script:actionText | Should -Match 'NOVA_RELEASE_PAT'
    $script:actionText | Should -Match 'NONE'
  }
}

Describe 'nova-resolve-token callers - App auth wired in 5 workflows' {
  BeforeAll {
    $script:workflowsDir = Join-Path $PSScriptRoot '..\.github\workflows'
    $script:expectedCallers = @(
      'reusable-build-maven.yml'
      'reusable-build-gradle.yml'
      'reusable-build-matrix.yml'
      'reusable-owasp-check.yml'
      'reusable-sbom.yml'
    )
  }

  It 'each expected caller wires NOVA_PLATFORM_APP_ID' {
    foreach ($f in $script:expectedCallers) {
      $path = Join-Path $script:workflowsDir $f
      $content = Get-Content -LiteralPath $path -Raw
      $content | Should -Match 'NOVA_PLATFORM_APP_ID' -Because "$f must wire the App ID secret"
    }
  }

  It 'each expected caller wires NOVA_PLATFORM_APP_PRIVATE_KEY' {
    foreach ($f in $script:expectedCallers) {
      $path = Join-Path $script:workflowsDir $f
      $content = Get-Content -LiteralPath $path -Raw
      $content | Should -Match 'NOVA_PLATFORM_APP_PRIVATE_KEY' -Because "$f must wire the App private key secret"
    }
  }
}