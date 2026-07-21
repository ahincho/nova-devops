BeforeAll {
  $script:scriptPath = Join-Path $PSScriptRoot '..\scripts\rotate-nova-tokens.ps1'
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

Describe 'rotate-nova-tokens.ps1 - script integrity' {
  It 'script file exists' {
    Test-Path -LiteralPath $script:scriptPath | Should -BeTrue
  }

  It 'parses without syntax errors' {
    $script:errors | Should -BeNullOrEmpty
  }

  It 'requires PowerShell 5.1+ via #Requires directive' {
    $script:ast.ScriptRequirements | Should -Not -BeNullOrEmpty
  }

  It 'has #Requires -Version in raw source' {
    $content = Get-Content -LiteralPath $script:scriptPath -Raw
    $content | Should -Match '#Requires\s+-Version\s+5\.1'
  }
}

Describe 'rotate-nova-tokens.ps1 - parameter validation' {
  BeforeAll {
    $script:paramBlock = $script:ast.ParamBlock.Parameters
    $script:phaseParam = $script:paramBlock | Where-Object {
      $_.Name.VariablePath.UserPath -eq 'Phase'
    }
    $script:phaseValidateSet = $script:phaseParam.Attributes | Where-Object {
      $_ -is [System.Management.Automation.Language.AttributeAst] -and
      $_.TypeName.Name -eq 'ValidateSet'
    }
    $script:phaseValues = $script:phaseValidateSet.PositionalArguments |
      ForEach-Object { $_.Value }
  }

  It 'declares -Phase parameter' {
    $script:phaseParam | Should -Not -BeNullOrEmpty
  }

  It '-Phase uses ValidateSet' {
    $script:phaseValidateSet | Should -Not -BeNullOrEmpty
  }

  It '-Phase restricts to known values' {
    $script:phaseValues | Should -Contain 'propagate-read'
    $script:phaseValues | Should -Contain 'purge-pat'
    $script:phaseValues | Should -Contain 'cleanup-residual'
    $script:phaseValues | Should -Contain 'all'
  }

  It 'declares -DryRun and -Force switches' {
    $names = $script:paramBlock | ForEach-Object {
      $_.Name.VariablePath.UserPath
    }
    $names | Should -Contain 'DryRun'
    $names | Should -Contain 'Force'
  }
}

Describe 'rotate-nova-tokens.ps1 - security patterns' {
  BeforeAll {
    $script:content = Get-Content -LiteralPath $script:scriptPath -Raw
  }

  It 'does not contain hardcoded token values' {
    $script:content | Should -Not -Match 'ghp_[A-Za-z0-9]{20,}'
    $script:content | Should -Not -Match 'github_pat_[A-Za-z0-9_]{20,}'
    $script:content | Should -Not -Match 'glpat-[A-Za-z0-9_-]{20,}'
  }

  It 'uses Read-Host -AsSecureString for token input' {
    $script:content | Should -Match 'Read-Host.*-AsSecureString'
  }

  It 'zero-frees SecureString BSTR after use' {
    $script:content | Should -Match 'ZeroFreeBSTR'
  }

  It 'passes secret values via pipeline (not args) to gh secret set' {
    # The pattern `gh secret set NAME | Out-...` followed by pipe from $value
    $script:content | Should -Match '\$SecretValue\s*\|\s*gh secret set'
  }
}