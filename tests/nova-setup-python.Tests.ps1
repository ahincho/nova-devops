BeforeAll {
  $script:actionPath = Join-Path $PSScriptRoot '..\.github\actions\nova-setup-python\action.yml'
  $script:actionText = if (Test-Path -LiteralPath $script:actionPath) {
    Get-Content -LiteralPath $script:actionPath -Raw
  } else { '' }

  # Returns the body of every run: key, both block scalars (run: |) and
  # single-line commands (run: uv sync --locked). A block ends at the first
  # non-empty line indented at or above the run: key.
  function Get-RunBlocks([string] $text) {
    $blocks = @()
    $lines = $text -split "`r?`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '^(\s*)run:\s*(.*)$') {
        $indent = $Matches[1].Length
        $rest = $Matches[2]
        if ($rest -match '^[|>][+-]?\s*$') {
          $body = @()
          for ($j = $i + 1; $j -lt $lines.Count; $j++) {
            $line = $lines[$j]
            if ($line.Trim() -ne '' -and ($line.Length - $line.TrimStart().Length) -le $indent) { break }
            $body += $line
          }
          $blocks += ($body -join "`n")
        } else {
          $blocks += $rest
        }
      }
    }
    return $blocks
  }

  $script:runBlocks = Get-RunBlocks $script:actionText
}

Describe 'nova-setup-python/action.yml - composite integrity' {
  It 'action.yml file exists' {
    Test-Path -LiteralPath $script:actionPath | Should -BeTrue
  }

  It 'declares composite runs type' {
    $script:actionText | Should -Match "using:\s*'composite'"
  }

  It 'declares the six inputs with their defaults' {
    $expected = [ordered]@{
      'python-version'    = "''"
      'uv-version'        = "''"
      'working-directory' = "'.'"
      'cache'             = "'true'"
      'save-cache'        = "'true'"
      'sync'              = "'true'"
    }
    foreach ($inp in $expected.Keys) {
      # The input's block runs until the next input (2-space indent) or the
      # next top-level key, so a missing default cannot borrow a later one.
      $block = [regex]::Match($script:actionText, '(?ms)^  ' + [regex]::Escape($inp) + ':\s*$(.*?)(?=^  \S|^\S)').Groups[1].Value
      $block | Should -Not -BeNullOrEmpty -Because "input '$inp' must be declared"
      $block | Should -Match ('(?m)^\s+default:\s*' + [regex]::Escape($expected[$inp]) + '\s*$') -Because "input '$inp' must default to $($expected[$inp])"
    }
  }

  It 'declares the four outputs' {
    foreach ($out in @('uv-version', 'python-version', 'cache-hit', 'python-cache-hit')) {
      $script:actionText | Should -Match "(?m)^\s{2}${out}:\s*$" -Because "output '$out' must be declared"
    }
  }
}

Describe 'nova-setup-python/action.yml - SHA pinning (Lote Q)' {
  It 'pins setup-uv to a 40-char commit SHA with its version in a comment' {
    $script:actionText | Should -Match 'uses:\s*astral-sh/setup-uv@[0-9a-f]{40}\s+#\s*v\d+\.\d+\.\d+'
  }

  It 'has no uses: ref pinned to a branch or a tag' {
    foreach ($m in [regex]::Matches($script:actionText, '(?m)^\s*(?:-\s*)?uses:\s*(\S+)')) {
      $ref = $m.Groups[1].Value
      $ref | Should -Match '@[0-9a-f]{40}$' -Because "'$ref' must be pinned to a commit SHA"
    }
  }
}

Describe 'nova-setup-python/action.yml - env-var wiring (Lote R)' {
  It 'finds the run blocks it checks' {
    $script:runBlocks.Count | Should -BeGreaterOrEqual 5
  }

  It 'never interpolates ${{ inputs.X }} inside a run block' {
    foreach ($block in $script:runBlocks) {
      $block | Should -Not -Match '\$\{\{\s*inputs\.' -Because 'inputs must reach run: through env vars'
    }
  }

  It 'never interpolates ${{ steps.X.outputs.Y }} inside a run block' {
    foreach ($block in $script:runBlocks) {
      $block | Should -Not -Match '\$\{\{\s*steps\.' -Because 'step outputs must reach run: through env vars'
    }
  }

  It 'captures the boolean inputs as env vars for validation' {
    $script:actionText | Should -Match '(?m)^\s+CACHE:\s+\$\{\{ inputs\.cache \}\}'
    $script:actionText | Should -Match '(?m)^\s+SAVE_CACHE:\s+\$\{\{ inputs\.save-cache \}\}'
    $script:actionText | Should -Match '(?m)^\s+SYNC:\s+\$\{\{ inputs\.sync \}\}'
  }
}

Describe 'nova-setup-python/action.yml - cache and sync behaviour' {
  It "maps cache: 'true' to setup-uv's enable-cache: auto, never to a forced true" {
    $script:actionText | Should -Match 'enable-cache:\s*\$\{\{ inputs\.cache == ''true'' && ''auto'' \|\| ''false'' \}\}'
  }

  It "maps save-cache: 'true' to setup-uv's save-cache: auto" {
    $script:actionText | Should -Match 'save-cache:\s*\$\{\{ inputs\.save-cache == ''true'' && ''auto'' \|\| ''false'' \}\}'
  }

  It 'caches the managed Python together with the packages' {
    $script:actionText | Should -Match 'cache-python:\s*\$\{\{ inputs\.cache \}\}'
  }

  It 'keys the cache on uv.lock and .python-version, not on pyproject.toml' {
    $glob = [regex]::Match($script:actionText, '(?ms)cache-dependency-glob:\s*\|\s*\n(.*?)(?=^\s*$|^\s{4}- |\z)').Groups[1].Value
    $glob | Should -Match '(?m)^\s+uv\.lock\s*$'
    $glob | Should -Match '(?m)^\s+\.python-version\s*$'
    $glob | Should -Not -Match 'pyproject\.toml'
  }

  It 'forces uv-managed Python only when the caller did not choose a preference' {
    $script:actionText | Should -Match 'if \[ -z "\$\{UV_PYTHON_PREFERENCE:-\}" \]'
    $script:actionText | Should -Match 'UV_PYTHON_PREFERENCE=only-managed'
  }

  It 'syncs with --locked, never --frozen or an unchecked sync' {
    $syncs = @($script:runBlocks | Where-Object { $_ -match 'uv sync' })
    $syncs.Count | Should -Be 1
    $syncs[0] | Should -Match 'uv sync --locked'
    $syncs[0] | Should -Not -Match '--frozen'
  }

  It 'rejects a project without pyproject.toml or uv.lock' {
    $script:actionText | Should -Match '\[ ! -f pyproject\.toml \]'
    $script:actionText | Should -Match '\[ ! -f uv\.lock \]'
  }

  It 'rejects boolean inputs other than true or false' {
    $script:actionText | Should -Match '"\$\{value\}" != "true" \] && \[ "\$\{value\}" != "false"'
  }

  It 'reports versions and cache results in the job summary' {
    $script:actionText | Should -Match 'GITHUB_STEP_SUMMARY'
    $script:actionText | Should -Match 'UV_VERSION:\s+\$\{\{ steps\.setup-uv\.outputs\.uv-version \}\}'
    $script:actionText | Should -Match 'PYTHON_CACHE_HIT:\s+\$\{\{ steps\.setup-uv\.outputs\.python-cache-hit \}\}'
  }
}
