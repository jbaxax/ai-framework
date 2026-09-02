# PowerShell launcher for fw — locates Git Bash instead of hardcoding its path.
# Resolution order: FW_BASH override, known Git for Windows layouts, then the
# Git root derived from git.exe on PATH.
#
# Only <Git>\bin\bash.exe is accepted. <Git>\usr\bin\bash.exe launches but does
# not set up the MSYS PATH, so the script then dies on "wc: command not found".
# Deliberately never searches PATH for bash.exe: on Windows that finds
# System32\bash.exe (the WSL launcher), which cannot resolve C:\ paths.

function Find-GitBash {
    if ($env:FW_BASH -and (Test-Path -LiteralPath $env:FW_BASH)) {
        return $env:FW_BASH
    }

    $roots = New-Object System.Collections.Generic.List[string]
    if ($env:ProgramFiles)        { [void]$roots.Add((Join-Path $env:ProgramFiles 'Git')) }
    if (${env:ProgramFiles(x86)}) { [void]$roots.Add((Join-Path ${env:ProgramFiles(x86)} 'Git')) }
    if ($env:LOCALAPPDATA)        { [void]$roots.Add((Join-Path $env:LOCALAPPDATA 'Programs\Git')) }
    if ($env:USERPROFILE)         { [void]$roots.Add((Join-Path $env:USERPROFILE 'scoop\apps\git\current')) }

    # git.exe lives in <Git>\cmd or <Git>\mingw64\bin — walk up to the Git root.
    foreach ($g in @(Get-Command git.exe -All -ErrorAction SilentlyContinue)) {
        $dir = Split-Path -Parent $g.Source
        [void]$roots.Add((Split-Path -Parent $dir))
        [void]$roots.Add((Split-Path -Parent (Split-Path -Parent $dir)))
    }

    foreach ($root in $roots) {
        if (-not $root) { continue }
        $candidate = Join-Path $root 'bin\bash.exe'
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    return $null
}

$bash = Find-GitBash
if (-not $bash) {
    [Console]::Error.WriteLine('fw: could not locate Git Bash (bash.exe).')
    [Console]::Error.WriteLine('Install Git for Windows, or set FW_BASH to the full path of bash.exe.')
    exit 127
}

& $bash (Join-Path $PSScriptRoot 'fw') @args
exit $LASTEXITCODE
