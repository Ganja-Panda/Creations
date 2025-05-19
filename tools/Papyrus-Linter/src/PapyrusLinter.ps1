<#
.SYNOPSIS
    PapyrusLinter - A reusable, extensible linter for Papyrus scripts.

.DESCRIPTION
    This linter scans Papyrus `.psc` files for common code smells, including:
    - Empty functions
    - Unused variables
    - Dead code (e.g., unreachable statements)
    - Global variable misuse
    - Deep nesting and complexity warnings
    - Performance optimizations

.NOTES
    Author: Ganja Panda
    Version: 0.1.0
    License: MIT (or choose a preferred license)

.PARAMETER ScriptPath
    The root directory to scan for `.psc` files. Defaults to the current directory.

.PARAMETER Verbose
    Enables more detailed output for each check. Defaults to $false.

.EXAMPLE
    .\PapyrusLinter.ps1 -ScriptPath "." -Verbose
#>

param (
    [string]$ScriptPath = ".",
    [switch]$Verbose = $false
)

$script:issues = 0
$script:filesChecked = 0

# Load Configuration
$ConfigPath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "config.json"
if (Test-Path $ConfigPath) {
    $config = Get-Content $ConfigPath | ConvertFrom-Json
} else {
    Write-Host "Error: config.json not found in the src directory."
    exit 1
}

function Add-Issue {
    param ([string]$Rule, [string]$File, [string]$Extra = "")
    $template = $config.message_templates.$Rule
    $message = $template -replace "{file}", $File
    if ($Rule -eq "unused_variables" -and $Extra -ne "") {
        $message = $message -replace "{variable}", $Extra
    }
    if ($Extra -ne "" -and $Rule -ne "unused_variables") {
        $message = $message -replace "{level}", $Extra
    }
    Write-Host $message
    $script:issues++
}

function Test-EmptyFunction {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.empty_functions -and $Content -match "\bFunction\s+[A-Za-z0-9_]+\s*\(\s*\)\s*{\s*}\s*$") {
        Add-Issue "empty_functions" $File
    }
}

function Test-EmptyLoop {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.empty_loops -and $Content -match "\b(While|For|Do)\s*\(.*\)\s*{\s*}\s*$") {
        Add-Issue "empty_loops" $File
    }
}

function Test-DebugTrace {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.debug_traces -and $Content -match "Debug\.Trace") {
        Add-Issue "debug_traces" $File
    }
}

function Test-GlobalVariable {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.global_variables -and $Content -match "\bGlobalVariable\s+[A-Za-z0-9_]+") {
        Add-Issue "global_variables" $File
    }
}

function Test-UnreachableCode {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.unreachable_code -and $Content -match "Return\s*.*?\n.*?}\s*$") {
        Add-Issue "unreachable_code" $File
    }
}

function Test-Complexity {
    param ([string]$Content, [string]$File)
    $nestingLevel = 0
    $scopeStack = @()
    foreach ($line in ($Content -split "`n")) {
        # Match block entry
        if ($line -match "\b(If|ElseIf|While|For|Function)\b") {
            $nestingLevel++
            $scopeStack += $line
        }
        # Match block exit
        if ($line -match "^\s*}\s*$" -and $scopeStack.Count -gt 0) {
            $nestingLevel--
            $scopeStack = $scopeStack[0..($scopeStack.Count - 2)]
        }
        # Check for over-complexity
        if ($nestingLevel -gt $config.complexity.max_nesting_level) {
            Add-Issue "complexity" $File $nestingLevel
        }
    }
}

function Test-UnusedVariables {
    param ([string]$Content, [string]$File)
    foreach ($line in ($Content -split "`n")) {
        if ($config.enable_rules.unused_variables -and $line -match "\b(Var|int|float|bool|String)\s+([A-Za-z0-9_]+)") {
            $variable = $matches[2]
            if ($Content -notmatch "\b$variable\b(?!\s*=)" -and $line -notmatch "\bFunction\b") {
                Add-Issue "unused_variables" $File $variable
            }
        }
    }
}

# Main Scan Loop
Get-ChildItem $ScriptPath -Filter *.psc -Recurse | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    $script:filesChecked++

    # Run all checks
    Test-EmptyFunction -Content $content -File $file
    Test-EmptyLoop -Content $content -File $file
    Test-DebugTrace -Content $content -File $file
    Test-GlobalVariable -Content $content -File $file
    Test-UnreachableCode -Content $content -File $file
    Test-Complexity -Content $content -File $file
    Test-UnusedVariables -Content $content -File $file

    if ($config.verbose) {
        Write-Host "Scanned: $file"
    }
}

Write-Host "`nFiles Checked: $script:filesChecked"
Write-Host "Total Issues Found: $script:issues"

if ($script:issues -eq 0) {
    Write-Host "No issues found. Your code is looking clean!"
} else {
    exit 1
}
