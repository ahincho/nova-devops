BeforeAll {
  $script:scriptPath = Join-Path $PSScriptRoot '..\scripts\apply-nova-labels.ps1'
  $script:ast = $null
  if (Test-Path -LiteralPath $script:scriptPath) {
    $tokens = $null
    $errors = $null
    $script:ast = [System.Management.Automation.Language.Parser]::ParseFile(
      $script:scriptPath, [ref]$tokens, [ref]$errors
    )
    $script:errors = $errors
  }
}

Describe 'apply-nova-labels.ps1 - script integrity' {
  It 'script file exists' {
    Test-Path -LiteralPath $script:scriptPath | Should -BeTrue
  }

  It 'parses without syntax errors' {
    $script:errors | Should -BeNullOrEmpty
  }
}

Describe 'apply-nova-labels.ps1 - parameter validation' {
  BeforeAll {
    $script:paramBlock = $script:ast.ParamBlock.Parameters
  }

  It 'declares -DryRun and -Force switches' {
    $names = $script:paramBlock | ForEach-Object {
      $_.Name.VariablePath.UserPath
    }
    $names | Should -Contain 'DryRun'
    $names | Should -Contain 'Force'
  }
}

Describe 'apply-nova-labels.ps1 - Scheme B registry integrity' {
  BeforeAll {
    $script:content = Get-Content -LiteralPath $script:scriptPath -Raw
  }

  It 'declares $SchemeB hashtable' {
    $script:content | Should -Match '\$SchemeB\s*='
  }

  It 'declares $RepoLabels mapping' {
    $script:content | Should -Match '\$RepoLabels\s*='
  }

  It 'targets at least 30 repos' {
    $match = [regex]::Match($script:content, 'Apply Scheme B labels to (\d+)')
    $match.Success | Should -BeTrue
    [int]$match.Groups[1].Value | Should -BeGreaterOrEqual 30
  }
}

Describe 'apply-nova-labels.ps1 - safety patterns' {
  BeforeAll {
    $script:content = Get-Content -LiteralPath $script:scriptPath -Raw
  }

  It 'uses --force for idempotent label creation' {
    $script:content | Should -Match 'gh label create.*--force'
  }

  It 'uses --yes for label deletion (non-interactive)' {
    $script:content | Should -Match 'gh label delete.*--yes'
  }

  It 'respects GitHub default labels (does not delete them)' {
    $script:content | Should -Match 'GitHubDefaults'
    $script:content | Should -Match "'bug'"
    $script:content | Should -Match "'documentation'"
  }
}