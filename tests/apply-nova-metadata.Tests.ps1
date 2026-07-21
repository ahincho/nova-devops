BeforeAll {
  $script:scriptPath = Join-Path $PSScriptRoot '..\scripts\apply-nova-metadata.ps1'
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

Describe 'apply-nova-metadata.ps1 - script integrity' {
  It 'script file exists' {
    Test-Path -LiteralPath $script:scriptPath | Should -BeTrue
  }

  It 'parses without syntax errors' {
    $script:errors | Should -BeNullOrEmpty
  }
}

Describe 'apply-nova-metadata.ps1 - parameter validation' {
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
    $script:phaseValues | Should -Contain 'descriptions'
    $script:phaseValues | Should -Contain 'topics'
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

Describe 'apply-nova-metadata.ps1 - data integrity' {
  BeforeAll {
    $script:content = Get-Content -LiteralPath $script:scriptPath -Raw
  }

  It 'declares $Descriptions hashtable' {
    $script:content | Should -Match '\$Descriptions\s*='
  }

  It 'declares $Topics hashtable' {
    $script:content | Should -Match '\$Topics\s*='
  }

  It 'covers at least 30 repos in $Descriptions' {
    $keys = [regex]::Matches($script:content, "^\s+'nova-[a-z0-9-]+'\s*=", 'Multiline')
    $keys.Count | Should -BeGreaterOrEqual 30
  }
}

Describe 'apply-nova-metadata.ps1 - safety patterns' {
  BeforeAll {
    $script:content = Get-Content -LiteralPath $script:scriptPath -Raw
  }

  It 'uses gh repo edit for description updates' {
    $script:content | Should -Match 'gh repo edit'
  }

  It 'clears existing topics before adding new ones (no duplicates)' {
    $script:content | Should -Match '--remove-topic'
  }
}