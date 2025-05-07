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

function Increment-IssueCount {
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

function Check-EmptyFunction {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.empty_functions -and $Content -match "\bFunction\s+[A-Za-z0-9_]+\s*\(\s*\)\s*{\s*}") {
        Increment-IssueCount "empty_functions" $File
    }
}

function Check-EmptyLoop {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.empty_loops -and $Content -match "\b(While|For|Do)\s*\(.*\)\s*{\s*}") {
        Increment-IssueCount "empty_loops" $File
    }
}

function Check-DebugTrace {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.debug_traces -and $Content -match "Debug\.Trace") {
        Increment-IssueCount "debug_traces" $File
    }
}

function Check-GlobalVariable {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.global_variables -and $Content -match "\bGlobalVariable\s+[A-Za-z0-9_]+") {
        Increment-IssueCount "global_variables" $File
    }
}

function Check-UnreachableCode {
    param ([string]$Content, [string]$File)
    if ($config.enable_rules.unreachable_code -and $Content -match "Return\s*.*?\n.*?}") {
        Increment-IssueCount "unreachable_code" $File
    }
}

function Check-Complexity {
    param ([string]$Content, [string]$File)
    $nestingLevel = 0
    foreach ($line in ($Content -split "`n")) {
        if ($line -match "\b(If|ElseIf|While|For|Function)\b") {
            $nestingLevel++
        }
        if ($line -match "}") {
            $nestingLevel--
        }
        if ($nestingLevel > $config.complexity.max_nesting_level) {
            Increment-IssueCount "complexity" $File $nestingLevel
        }
    }
}

function Check-UnusedVariables {
    param ([string]$Content, [string]$File)
    foreach ($line in ($Content -split "`n")) {
        if ($config.enable_rules.unused_variables -and $line -match "\b(Var|int|float|bool|String)\s+([A-Za-z0-9_]+)") {
            $variable = $matches[2]
            if ($Content -notmatch "\b$variable\b(?!\s*=)" -and $line -notmatch "\bFunction\b") {
                Increment-IssueCount "unused_variables" $File $variable
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
    Check-EmptyFunction -Content $content -File $file
    Check-EmptyLoop -Content $content -File $file
    Check-DebugTrace -Content $content -File $file
    Check-GlobalVariable -Content $content -File $file
    Check-UnreachableCode -Content $content -File $file
    Check-Complexity -Content $content -File $file
    Check-UnusedVariables -Content $content -File $file

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
