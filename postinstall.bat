@ECHO OFF

REM configure geopandas to use shapely instead of pygeos
SETX USE_PYGEOS 0 /M
IF %ERRORLEVEL% NEQ 0 (
    SETX USE_PYGEOS 0
)

REM configure jupyterlab to disable popups and update checking
IF NOT EXIST "%PREFIX%\share\jupyter\lab\settings" (
    MKDIR "%PREFIX%\share\jupyter\lab\settings"
)
(
    ECHO {
    ECHO     "@jupyterlab/apputils-extension:notification": {
    ECHO         "checkForUpdates": "false",
    ECHO         "fetchNews": "false"
    ECHO     }
    ECHO }
) > "%PREFIX%\share\jupyter\lab\settings\overrides.json"

REM convert start menu entries to camelcase
IF EXIST "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Jumboconda" (
    REN "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Jumboconda" "JumboConda"
)
IF EXIST "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Prompt.lnk" (
    REN "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Prompt.lnk" "JumboConda Prompt.lnk"
)
IF EXIST "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda PowerShell.lnk" (
    REN "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda PowerShell.lnk" "JumboConda PowerShell.lnk"
)
IF EXIST "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Bash.lnk" (
    REN "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Bash.lnk" "JumboConda Bash.lnk"
)
IF EXIST "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Jumboconda" (
    REN "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Jumboconda" "JumboConda"
)
IF EXIST "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Prompt.lnk" (
    REN "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Prompt.lnk" "JumboConda Prompt.lnk"
)
IF EXIST "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda PowerShell.lnk" (
    REN "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda PowerShell.lnk" "JumboConda PowerShell.lnk"
)
IF EXIST "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Bash.lnk" (
    REN "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JumboConda\Jumboconda Bash.lnk" "JumboConda Bash.lnk"
)
