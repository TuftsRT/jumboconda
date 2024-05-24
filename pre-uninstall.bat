@ECHO OFF

ECHO Configuring JumboConda... Do not close command prompt.
SET PATH=%PATH%;"C:\Windows\System32\"

REM remove environment variables
REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V OUTDATED_IGNORE /F
IF %ERRORLEVEL% NEQ 0 (
    REG DELETE "HKCU\Environment" /V OUTDATED_IGNORE /F
)
REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /V USE_PYGEOS /F
IF %ERRORLEVEL% NEQ 0 (
    REG DELETE "HKCU\Environment" /V USE_PYGEOS /F
)

REM remove jupyterlab desktop configuration
IF "%PREFIX:users=%"=="%PREFIX%" (
    REM systemwide installation
    FOR /F "delims=" %%d IN ('dir /AD /B "%SYSTEMDRIVE%\Users"') DO (
        IF /I "%%d" NEQ "All Users" (
            IF /I "%%d" NEQ "Default User" (
                IF /I "%%d" NEQ "Public" (
                        IF EXIST "%SYSTEMDRIVE%\Users\%%d\AppData\Roaming\jupyterlab-desktop\" (
                            RMDIR "%SYSTEMDRIVE%\Users\%%d\AppData\Roaming\jupyterlab-desktop" /S /Q
                    )
                )
            )
        )
    )
) ELSE (
    REM single user installation
    IF EXIST "%APPDATA%\jupyterlab-desktop\" (
        RMDIR "%APPDATA%\jupyterlab-desktop" /S /Q
    )
)
