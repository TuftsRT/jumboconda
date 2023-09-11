@ECHO OFF

ECHO Configuring JumboConda... Do not close command prompt.
SET PATH=%PATH%;"C:\Windows\System32\"

REM configure geopandas to use shapely instead of pygeos
SETX USE_PYGEOS 0 /M
IF %ERRORLEVEL% NEQ 0 (
    SETX USE_PYGEOS 0
)

REM configure jupyterlab to disable popups and update checking
IF NOT EXIST "%PREFIX%\share\jupyter\lab\settings\" (
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

REM configure jupyterlab desktop for use with jumboconda
IF "%PREFIX:users=%"=="%PREFIX%" (
    REM systemwide installation
    FOR /F "delims=" %%d IN ('dir /AD /B "%SYSTEMDRIVE%\Users"') DO (
        IF /I "%%d" NEQ "All Users" (
            IF /I "%%d" NEQ "Default User" (
                IF /I "%%d" NEQ "Public" (
                    IF NOT EXIST "%SYSTEMDRIVE%\Users\%%d\AppData\Roaming\jupyterlab-desktop\" (
                        MKDIR "%SYSTEMDRIVE%\Users\%%d\AppData\Roaming\jupyterlab-desktop"
                    )
                    (
                        ECHO {
                        ECHO   "checkForUpdatesAutomatically": false,
                        ECHO   "installUpdatesAutomatically": false,
                        ECHO   "pythonPath": "%PREFIX:\=\\%\\python.exe",
                        ECHO   "serverEnvVars": {}
                        ECHO }
                    ) > "%SYSTEMDRIVE%\Users\%%d\AppData\Roaming\jupyterlab-desktop\settings.json"
                )
            )
        )
    )
) ELSE (
    REM single user installation
    IF NOT EXIST "%APPDATA%\jupyterlab-desktop\" (
        MKDIR "%APPDATA%\jupyterlab-desktop
    )
    (
        ECHO {
        ECHO   "checkForUpdatesAutomatically": false,
        ECHO   "installUpdatesAutomatically": false,
        ECHO   "pythonPath": "%PREFIX:\=\\%\\python.exe",
        ECHO   "serverEnvVars": {}
        ECHO }
    ) > "%APPDATA%\jupyterlab-desktop\settings.json"
)

REM convert start menu entries to camelcase
IF EXIST "%PROGRAMDATA%\Microsoft\Windows\Start Menu\Programs\Jumboconda\" (
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
IF EXIST "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Jumboconda\" (
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

REM reconfigure access permissions for systemwide installation
IF "%PREFIX:users=%"=="%PREFIX%" (
    ICACLS "%PREFIX%" /inheritance:d /C /Q
    ICACLS "%PREFIX%" /remove "Authenticated Users" /C /Q
    ICACLS "%PREFIX%" /grant "BUILTIN\Administrators:(OI)(CI)(F)" /C /Q
    ICACLS "%PREFIX%" /grant "BUILTIN\Users:(OI)(CI)(M)" /C /Q
    ICACLS "%PREFIX%\*" /reset /T /C /Q
)
