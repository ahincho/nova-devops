BeforeAll {
  $script:migrationsRoot = Join-Path $PSScriptRoot '..\.github\migrations'
  $script:hasMigrationsDir = Test-Path -LiteralPath $script:migrationsRoot
}

Describe '.github/migrations/ - bundle structure' {
  It 'migrations directory exists' {
    $script:hasMigrationsDir | Should -BeTrue
  }

  It 'has at least one bundle' {
    if ($script:hasMigrationsDir) {
      $bundles = Get-ChildItem -LiteralPath $script:migrationsRoot -Directory
      $bundles.Count | Should -BeGreaterOrEqual 1
    } else {
      Set-ItResult -Skipped -Because 'migrations directory missing'
    }
  }
}

Describe '.github/migrations/nova-bom-lote-f/ - bundle integrity' {
  BeforeAll {
    $script:bundle = Join-Path $script:migrationsRoot 'nova-bom-lote-f'
    $script:hasBundle = Test-Path -LiteralPath $script:bundle
  }

  It 'bundle directory exists' {
    $script:hasBundle | Should -BeTrue
  }

  It 'has README.md with application instructions' {
    if ($script:hasBundle) {
      Test-Path -LiteralPath (Join-Path $script:bundle 'README.md') | Should -BeTrue
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'has release-please.yml (wrapper workflow with push trigger)' {
    if ($script:hasBundle) {
      $wf = Join-Path $script:bundle '.github\workflows\release-please.yml'
      Test-Path -LiteralPath $wf | Should -BeTrue
      $content = Get-Content -LiteralPath $wf -Raw
      # Wrapper workflows are triggered by push (NOT workflow_call - that's the reusable)
      $content | Should -Match 'on:\s*\n\s*push:'
      $content | Should -Match 'branches:\s*\[main\]'
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'has publish-on-tag.yml (Maven-direct wrapper with tag trigger)' {
    if ($script:hasBundle) {
      $wf = Join-Path $script:bundle '.github\workflows\publish-on-tag.yml'
      Test-Path -LiteralPath $wf | Should -BeTrue
      $content = Get-Content -LiteralPath $wf -Raw
      $content | Should -Match "tags:\s*\n\s*- 'v\["
      $content | Should -Match 'reusable-release-maven-publish'
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'has .release-please-config.json with multi-module Maven config' {
    if ($script:hasBundle) {
      $cfg = Join-Path $script:bundle '.release-please-config.json'
      Test-Path -LiteralPath $cfg | Should -BeTrue
      $content = Get-Content -LiteralPath $cfg -Raw
      $content | Should -Match '"package-name": "nova-bom"'
      $content | Should -Match '"package-name": "nova-spring-boot-bom"'
      $content | Should -Match '"package-name": "nova-quarkus-bom"'
      $content | Should -Match '"package-name": "nova-micronaut-bom"'
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'all YAML workflow refs point to @main (Lote P default)' {
    if ($script:hasBundle) {
      # Only check .yml files; .release-please-config.json is a JSON config
      $files = Get-ChildItem -LiteralPath $script:bundle -Recurse -File | Where-Object { $_.Extension -in @('.yml', '.yaml') }
      foreach ($f in $files) {
        $content = Get-Content -LiteralPath $f.FullName -Raw
        if ($content -match '@[a-f0-9]{40}') {
          Write-Host "    WARNING: $($f.Name) still has SHA pin (should be @main)"
        }
        $content | Should -Match '@main'
      }
    } else {
      Set-ItResult -Skipped
    }
  }
}

Describe '.github/migrations/nova-java-spring-boot-parent-lote-f/ - bundle integrity' {
  BeforeAll {
    $script:bundle = Join-Path $script:migrationsRoot 'nova-java-spring-boot-parent-lote-f'
    $script:hasBundle = Test-Path -LiteralPath $script:bundle
  }

  It 'bundle directory exists' {
    $script:hasBundle | Should -BeTrue
  }

  It 'has README.md' {
    if ($script:hasBundle) {
      Test-Path -LiteralPath (Join-Path $script:bundle 'README.md') | Should -BeTrue
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'has release-please.yml wrapper' {
    if ($script:hasBundle) {
      $wf = Join-Path $script:bundle '.github\workflows\release-please.yml'
      Test-Path -LiteralPath $wf | Should -BeTrue
      $content = Get-Content -LiteralPath $wf -Raw
      $content | Should -Match 'branches:\s*\[main\]'
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'has publish-on-tag.yml wiring NOVA_PACKAGES_READ_TOKEN (cross-repo read)' {
    if ($script:hasBundle) {
      $wf = Join-Path $script:bundle '.github\workflows\publish-on-tag.yml'
      Test-Path -LiteralPath $wf | Should -BeTrue
      $content = Get-Content -LiteralPath $wf -Raw
      $content | Should -Match 'NOVA_PACKAGES_READ_TOKEN'
      $content | Should -Match 'secrets:[\s\S]+?NOVA_PACKAGES_READ_TOKEN'
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'has .release-please-config.json for single-package Maven' {
    if ($script:hasBundle) {
      $cfg = Join-Path $script:bundle '.release-please-config.json'
      Test-Path -LiteralPath $cfg | Should -BeTrue
      $content = Get-Content -LiteralPath $cfg -Raw
      $content | Should -Match '"package-name": "nova-spring-boot-parent"'
      $content | Should -Match '"release-type": "maven"'
    } else {
      Set-ItResult -Skipped
    }
  }

  It 'all YAML workflow refs point to @main (Lote P default)' {
    if ($script:hasBundle) {
      $files = Get-ChildItem -LiteralPath $script:bundle -Recurse -File | Where-Object { $_.Extension -in @('.yml', '.yaml') }
      foreach ($f in $files) {
        $content = Get-Content -LiteralPath $f.FullName -Raw
        if ($content -match '@[a-f0-9]{40}') {
          Write-Host "    WARNING: $($f.Name) still has SHA pin"
        }
        $content | Should -Match '@main'
      }
    } else {
      Set-ItResult -Skipped
    }
  }
}

Describe '.github/migrations/ - branch pin coverage (aggregate, Lote P)' {
  It 'all YAML workflow files use @main consistently (no SHA pins)' {
    if ($script:hasMigrationsDir) {
      # Only YAML workflow files; JSON config files don't have @main
      $allFiles = Get-ChildItem -LiteralPath $script:migrationsRoot -Recurse -File | Where-Object { $_.Extension -in @('.yml', '.yaml') }
      $filesWithSha = 0
      foreach ($f in $allFiles) {
        $content = Get-Content -LiteralPath $f.FullName -Raw
        if ($content -match '@[a-f0-9]{40}') {
          $filesWithSha++
        }
        $content | Should -Match '@main' -Because "$($f.Name) should use @main branch pin (Lote P)"
      }
      $filesWithSha | Should -Be 0
    } else {
      Set-ItResult -Skipped
    }
  }
}