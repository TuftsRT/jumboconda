@ECHO OFF

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

SETX USE_PYGEOS 0 /M

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
