# tests/

Pester smoke tests for the 3 PowerShell automation scripts under `../scripts/`.

## Running

```powershell
# Requires Pester v5+
pwsh -Command "Invoke-Pester ./tests"
```

These tests focus on **static analysis** of each script (parameter validation, ValidateSet correctness, presence of security-sensitive patterns) and do not require `gh` CLI to be installed.

They do not exercise end-to-end behavior - that requires a real GitHub org with secrets and is out of scope for this repo.