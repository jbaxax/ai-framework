@echo off
rem fw launcher for cmd.exe — locates Git Bash instead of hardcoding its path.
rem Resolution order: FW_BASH override, known Git for Windows layouts, then the
rem Git root derived from git.exe on PATH.
rem
rem Only <Git>\bin\bash.exe is accepted. <Git>\usr\bin\bash.exe launches but does
rem not set up the MSYS PATH, so the script then dies on "wc: command not found".
rem Deliberately never uses `where bash`: on Windows that finds System32\bash.exe
rem (the WSL launcher), which cannot resolve C:\ paths and fails confusingly.
setlocal

set "FW_BASH_EXE="

if defined FW_BASH if exist "%FW_BASH%" set "FW_BASH_EXE=%FW_BASH%"

if not defined FW_BASH_EXE call :try "%ProgramFiles%\Git"
if not defined FW_BASH_EXE call :try "%ProgramFiles(x86)%\Git"
if not defined FW_BASH_EXE call :try "%LOCALAPPDATA%\Programs\Git"
if not defined FW_BASH_EXE call :try "%USERPROFILE%\scoop\apps\git\current"
if not defined FW_BASH_EXE call :from_git

if not defined FW_BASH_EXE (
  >&2 echo fw: could not locate Git Bash ^(bash.exe^).
  >&2 echo Install Git for Windows, or set FW_BASH to the full path of bash.exe.
  exit /b 127
)

"%FW_BASH_EXE%" "%~dp0fw" %*
exit /b %ERRORLEVEL%

:try
if exist "%~1\bin\bash.exe" set "FW_BASH_EXE=%~1\bin\bash.exe"
exit /b 0

:from_git
rem git.exe lives in <Git>\cmd or <Git>\mingw64\bin — walk up to the Git root.
for /f "delims=" %%G in ('where git.exe 2^>nul') do (
  call :try "%%~dpG.."
  if defined FW_BASH_EXE exit /b 0
  call :try "%%~dpG..\.."
  if defined FW_BASH_EXE exit /b 0
)
exit /b 0
