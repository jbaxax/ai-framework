@echo off
rem Windows entry point for the fw plan hook. Claude Code runs hook commands
rem through the Windows shell, which cannot execute a .sh or resolve an MSYS
rem /c/Users path, so settings.json points here and this hands off to Git Bash.
rem
rem Same resolution order and the same constraints as bin\fw.cmd: only
rem <Git>\bin\bash.exe works, and `where bash` is avoided because it finds the
rem WSL launcher in System32.
rem
rem Stdin carries the prompt payload and stdout is injected into the agent's
rem context, so nothing here may print on the success path. A missing Git Bash
rem exits 0 in silence: a broken guard must never eat a prompt.
setlocal

set "FW_BASH_EXE="

if defined FW_BASH if exist "%FW_BASH%" set "FW_BASH_EXE=%FW_BASH%"

if not defined FW_BASH_EXE call :try "%ProgramFiles%\Git"
if not defined FW_BASH_EXE call :try "%ProgramFiles(x86)%\Git"
if not defined FW_BASH_EXE call :try "%LOCALAPPDATA%\Programs\Git"
if not defined FW_BASH_EXE call :try "%USERPROFILE%\scoop\apps\git\current"
if not defined FW_BASH_EXE call :from_git

if not defined FW_BASH_EXE exit /b 0

"%FW_BASH_EXE%" "%~dp0plan-guard.sh"
exit /b 0

:try
if exist "%~1\bin\bash.exe" set "FW_BASH_EXE=%~1\bin\bash.exe"
exit /b 0

:from_git
for /f "delims=" %%G in ('where git.exe 2^>nul') do (
  call :try "%%~dpG.."
  if defined FW_BASH_EXE exit /b 0
  call :try "%%~dpG..\.."
  if defined FW_BASH_EXE exit /b 0
)
exit /b 0
