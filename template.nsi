# Installer template file for creating a Windows installer using NSIS.

# Dependencies:
#   NSIS >=3.08      conda install "nsis>=3.08"  (includes extra unicode plugins)

Unicode "true"

#if enable_debugging is True
# Special logging build needed for ENABLE_LOGGING
# See https://nsis.sourceforge.io/Special_Builds
!define ENABLE_LOGGING
#endif

# Comes from https://nsis.sourceforge.io/Logging:Enable_Logs_Quickly
!define LogSet "!insertmacro LogSetMacro"
!macro LogSetMacro SETTING
  !ifdef ENABLE_LOGGING
    LogSet ${SETTING}
  !endif
!macroend

!define LogText "!insertmacro LogTextMacro"
!macro LogTextMacro INPUT_TEXT
  !ifdef ENABLE_LOGGING
    LogText ${INPUT_TEXT}
  !endif
!macroend

!include "WinMessages.nsh"
!include "WordFunc.nsh"
!include "LogicLib.nsh"
!include "WinVer.nsh"
!include "MUI2.nsh"
!include "x64.nsh"

!include "FileFunc.nsh"
!insertmacro GetParameters
!insertmacro GetOptions

!include "UAC.nsh"
!include "nsDialogs.nsh"

!include "Utils.nsh"

!define NAME __NAME__
!define VERSION __VERSION__
!define COMPANY __COMPANY__
!define ARCH __ARCH__
!define PLATFORM __PLATFORM__
!define CONSTRUCTOR_VERSION __CONSTRUCTOR_VERSION__
!define PY_VER __PY_VER__
!define PYVERSION_JUSTDIGITS __PYVERSION_JUSTDIGITS__
!define PYVERSION __PYVERSION__
!define PYVERSION_MAJOR __PYVERSION_MAJOR__
!define DEFAULT_PREFIX __DEFAULT_PREFIX__
!define DEFAULT_PREFIX_DOMAIN_USER __DEFAULT_PREFIX_DOMAIN_USER__
!define DEFAULT_PREFIX_ALL_USERS __DEFAULT_PREFIX_ALL_USERS__
!define PRE_INSTALL_DESC __PRE_INSTALL_DESC__
!define POST_INSTALL_DESC __POST_INSTALL_DESC__
!define MENU_PKGS "@MENU_PKGS@"
!define SHOW_REGISTER_PYTHON __SHOW_REGISTER_PYTHON__
!define SHOW_ADD_TO_PATH __SHOW_ADD_TO_PATH__
!define PRODUCT_NAME "${NAME} ${VERSION} (${ARCH})"
!define UNINSTALL_NAME "@UNINSTALL_NAME@"
!define UNINSTREG "SOFTWARE\Microsoft\Windows\CurrentVersion\
                   \Uninstall\${UNINSTALL_NAME}"

var /global INSTDIR_JUSTME
var /global INSTALLER_VERSION
var /global INSTALLER_NAME_FULL

# UAC shield overlay
!ifndef BCM_SETSHIELD
    !define BCM_SETSHIELD 0x0000160C
!endif

var /global ARGV
var /global ARGV_Help
var /global ARGV_InstallationType
var /global ARGV_AddToPath
var /global ARGV_KeepPkgCache
var /global ARGV_RegisterPython
var /global ARGV_NoRegistry
var /global ARGV_NoScripts
var /global ARGV_NoShortcuts
var /global ARGV_CheckPathLength

var /global IsDomainUser
var /global CheckPathLength
var /global LongPathsEnabled
var /global InstDirLen

var /global InstModePage_RadioButton_JustMe
var /global InstModePage_RadioButton_AllUsers

var /global InstMode # 0 = Just Me, 1 = All Users.
!define JUST_ME 0
!define ALL_USERS 1

# Include this one after our defines
!include "OptionsDialog.nsh"

CRCCheck On

# Basic options
Name "${PRODUCT_NAME}"
OutFile __OUTFILE__
ShowInstDetails "hide"
ShowUninstDetails "hide"
# This installer contains tar.bz2 files, which are already compressed
SetCompress "off"

# Start off with the lowest permissions and work our way up.
RequestExecutionLevel user

# Version information & branding text
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "CompanyName" "${COMPANY}"
VIAddVersionKey "LegalCopyright" "(c) ${COMPANY}"
VIAddVersionKey "FileDescription" "${NAME} Installer"
VIAddVersionKey "Comments" "Created by constructor ${CONSTRUCTOR_VERSION}"
VIProductVersion __VIPV__
BrandingText /TRIMLEFT "${COMPANY}"

# Interface configuration
!define MUI_ICON __ICONFILE__
!define MUI_UNICON __ICONFILE__
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP __HEADERIMAGE__
!define MUI_HEADERIMAGE_UNBITMAP __HEADERIMAGE__
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
!define MUI_WELCOMEFINISHPAGE_BITMAP __WELCOMEIMAGE__
!define MUI_UNWELCOMEFINISHPAGE_BITMAP __WELCOMEIMAGE__
#!define MUI_CUSTOMFUNCTION_GUIINIT GuiInit

# Pages
#!define MUI_PAGE_CUSTOMFUNCTION_SHOW OnStartup
#if custom_welcome
# Custom welcome file(s)
@CUSTOM_WELCOME_FILE@
#else
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageIfUACInnerInstance
!insertmacro MUI_PAGE_WELCOME
#endif
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageIfUACInnerInstance
!insertmacro MUI_PAGE_LICENSE __LICENSEFILE__
Page Custom InstModePage_Create InstModePage_Leave
!define MUI_PAGE_CUSTOMFUNCTION_PRE DisableBackButtonIfUACInnerInstance
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE OnDirectoryLeave
!insertmacro MUI_PAGE_DIRECTORY
# Custom options now differ depending on installation mode.
Page Custom mui_AnaCustomOptions_Show
!insertmacro MUI_PAGE_INSTFILES
#if with_conclusion_text is True
!define MUI_FINISHPAGE_TITLE __CONCLUSION_TITLE__
!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TEXT __CONCLUSION_TEXT__
#endif

#if custom_conclusion
# Custom conclusion file(s)
@CUSTOM_CONCLUSION_FILE@
#else
!insertmacro MUI_PAGE_FINISH
#endif


!insertmacro MUI_UNPAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE un.OnDirectoryLeave
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

# Language
!insertmacro MUI_LANGUAGE "English"

Function SkipPageIfUACInnerInstance
    ${LogSet} on
    ${If} ${UAC_IsInnerInstance}
        Abort
    ${EndIf}
FunctionEnd

!macro DoElevation
    GetDlgItem $1 $HWNDParent 1
    System::Call user32::GetFocus()i.s
    # Disable 'Next' button.
    EnableWindow $1 0
    !insertmacro UAC_PageElevation_RunElevated
    EnableWindow $1 1
    System::call user32::SetFocus(is)
    ${If} $2 = 0x666
        MessageBox MB_ICONEXCLAMATION \
            "You need to log in with an administrative account \
             in order to perform an 'All Users' installation."
        Abort
    ${ElseIf} $0 = 1223
        # UAC canceled by user.
        Abort
    ${Else}
        ${If} $0 <> 0
            ${If} $0 = 1062
                MessageBox MB_ICONSTOP \
                    "Elevation failed; Secondary Logon service is \
                     not running."
            ${Else}
                MessageBox MB_ICONSTOP \
                    "Elevation failed; error code: $0."
            ${EndIf}
            Abort
        ${EndIf}
    ${EndIf}
    # UAC worked, we're the outer installer, so we can quit.
    Quit
!macroend


!macro ParseCommandLineArgs
    ClearErrors
    ${GetParameters} $ARGV
    ${GetOptions} $ARGV "/?" $ARGV_Help
    ${IfNot} ${Errors}
        MessageBox MB_OK|MB_ICONEXCLAMATION \
            "Usage: $EXEFILE [options]$\n\
             Options:$\n$\n\
                /InstallationType=AllUsers [default: JustMe]$\n$\n\
                /AddToPath=[0|1] [default: 0]$\n$\n\
#if keep_pkgs is True
                /KeepPkgCache=[0|1] [default: 1]$\n$\n\
#endif
#if keep_pkgs is False
                /KeepPkgCache=[0|1] [default: 0]$\n$\n\
#endif
                /RegisterPython=[0|1] [default: AllUsers: 1, JustMe: 0]$\n$\n\
                /NoRegistry=[0|1] [default: AllUsers: 0, JustMe: 0]$\n$\n\
                /NoScripts=[0|1] [default: 0]$\n$\n\
                /NoShortcuts=[0|1] [default: 0]$\n$\n\
                /CheckPathLength=[0|1] [default: 1]$\n$\n\
            Examples:$\n\
                Install for all users, but don't add to PATH env var:$\n\
                    $EXEFILE /InstallationType=AllUsers$\n$\n\
                Install for just me, add to PATH and register as system Python:$\n\
                    $EXEFILE /RegisterPython=1 /AddToPath=1$\n$\n\
                Install for just me, with no registry modification (for CI):$\n\
                    $EXEFILE /NoRegistry=1$\n$\n\
            NOTE: If you install for AllUsers, then the option to AddToPath$\n\
                is disabled (i.e. if ./InstallationType=AllUsers, then$\n\
                /AddToPath=1 will be ignored).$\n" \
            /SD IDOK
            Abort
     ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/InstallationType=" $ARGV_InstallationType
    ${IfNot} ${Errors}
        ${If} $ARGV_InstallationType == "AllUsers"
            StrCpy $InstMode ${ALL_USERS}
        ${Else}
            StrCpy $InstMode ${JUST_ME}
        ${EndIf}
    ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/RegisterPython=" $ARGV_RegisterPython
    ${IfNot} ${Errors}
        ${If} $ARGV_RegisterPython = "1"
            StrCpy $Ana_RegisterSystemPython_State ${BST_CHECKED}
        ${ElseIf} $ARGV_RegisterPython = "0"
            StrCpy $Ana_RegisterSystemPython_State ${BST_UNCHECKED}
        ${EndIf}
    ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/KeepPkgCache=" $ARGV_KeepPkgCache
    ${If} ${Errors}
        StrCpy $ARGV_KeepPkgCache "@KEEP_PKGS@"
    ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/NoRegistry=" $ARGV_NoRegistry
    ${If} ${Errors}
        StrCpy $ARGV_NoRegistry "0"
    ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/NoScripts=" $ARGV_NoScripts
    ${IfNot} ${Errors}
        ${If} $ARGV_NoScripts = "1"
            StrCpy $Ana_PostInstall_State ${BST_UNCHECKED}
        ${ElseIf} $ARGV_NoScripts = "0"
            StrCpy $Ana_PostInstall_State ${BST_CHECKED}
        ${EndIf}
    ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/NoShortcuts=" $ARGV_NoShortcuts
    ${IfNot} ${Errors}
        ${If} $ARGV_NoShortcuts = "1"
            StrCpy $Ana_CreateShortcuts_State ${BST_UNCHECKED}
        ${ElseIf} $ARGV_NoShortcuts = "0"
            StrCpy $Ana_CreateShortcuts_State ${BST_CHECKED}
        ${EndIf}
    ${EndIf}

    ClearErrors
    ${GetOptions} $ARGV "/CheckPathLength=" $ARGV_CheckPathLength
    ${IfNot} ${Errors}
        ${If} $ARGV_CheckPathLength = "0"
            StrCpy $CheckPathLength "0"
        ${ElseIf} $ARGV_CheckPathLength = "1"
            StrCpy $CheckPathLength "1"
        ${EndIf}
    ${EndIf}

!macroend

Function OnInit_Release
    ${LogSet} on
    !insertmacro ParseCommandLineArgs

    # Parsing the AddToPath option here (and not in ParseCommandLineArgs) to prevent the MessageBox from showing twice.
    # For more context, see https://github.com/conda/constructor/pull/584#issuecomment-1347688020
    ClearErrors
    ${GetOptions} $ARGV "/AddToPath=" $ARGV_AddToPath
    ${IfNot} ${Errors}
        ${If} $ARGV_AddToPath = "1"
            ${If} $InstMode == ${ALL_USERS}
                # To address CVE-2022-26526.
                # In AllUsers install mode, do not allow AddToPath as an option.
                MessageBox MB_OK|MB_ICONEXCLAMATION "/AddToPath=1 is disabled and ignored in 'All Users' installations" /SD IDOK
                StrCpy $Ana_AddToPath_State ${BST_UNCHECKED}
            ${Else}
                StrCpy $Ana_AddToPath_State ${BST_CHECKED}
            ${EndIf}
        ${ElseIf} $ARGV_AddToPath = "0"
            StrCpy $Ana_AddToPath_State ${BST_UNCHECKED}
        ${EndIf}
    ${EndIf}
FunctionEnd

Function InstModePage_RadioButton_OnClick
    ${LogSet} on
    Exch $0
    Push $1
    Push $2

    nsDialogs::GetUserData $0
    Pop $1
    GetDlgItem $2 $HWNDParent 1
    SendMessage $2 ${BCM_SETSHIELD} 0 $1

    Pop $2
    Pop $1
    Exch $0
FunctionEnd

Function InstModePage_Create
    ${LogSet} on
    Push $0
    Push $1
    Push $2
    Push $3

    ${If} ${UAC_IsInnerInstance}
        Abort
    ${EndIf}

    !insertmacro MUI_HEADER_TEXT_PAGE \
        "Select Installation Type" \
        "Please select the type of installation you would like to perform \
         for ${PRODUCT_NAME}."

    GetFunctionAddress $0 InstModePage_RadioButton_OnClick
    nsDialogs::Create /NOUNLOAD 1018
    Pop $1
    ${NSD_OnBack} RemoveNextBtnShield
    ${NSD_CreateLabel} 0 20u 75% 20u "Install for:"
    ${NSD_CreateRadioButton} 0 40u 75% 15u "Just Me (recommended)"
    Pop $2
    #MessageBox MB_OK "OnClick 2! 0: $0, 1: $1, 2: $2"
    StrCpy $InstModePage_RadioButton_JustMe $2

    nsDialogs::OnClick $2 $0
    nsDialogs::SetUserData $2 0
    SendMessage $2 ${BM_CLICK} 0 0

    ${NSD_CreateRadioButton} 0 60u 75% 15u \
        "All Users (requires admin privileges)"
    #MessageBox MB_OK "OnClick 3! 0: $0, 1: $1, 2: $2, 3: $3"
    Pop $3
    StrCpy $InstModePage_RadioButton_AllUsers $3
    nsDialogs::OnClick $3 $0
    nsDialogs::SetUserData $3 1
    ${IfThen} $InstMode <> ${JUST_ME} ${|} SendMessage $3 ${BM_CLICK} 0 0 ${|}
    Push $3
    nsDialogs::Show

    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function DisableBackButtonIfUACInnerInstance
    ${LogSet} on
    Push $0
    ${If} ${UAC_IsInnerInstance}
        GetDlgItem $0 $HWNDParent 3
        EnableWindow $0 0
    ${EndIf}
    Pop $0
FunctionEnd

Function RemoveNextBtnShield
    ${LogSet} on
    Push $0
    GetDlgItem $0 $HWNDParent 1
    SendMessage $0 ${BCM_SETSHIELD} 0 0
    Pop $0
FunctionEnd

Function InstModeChanged
    ${LogSet} on
    # When using the installer with /S (silent mode), the /D option sets $INSTDIR,
    # and it is therefore important not to overwrite $INSTDIR here, but it is also
    # important that we do call SetShellVarContext with the appropriate value.
    Push $0
    ${If} $InstMode = ${JUST_ME}
        SetShellVarContext Current
        # If we're on Vista+, the installation directory will
        # have a nice, no-space name like:
        #   C:\Users\Trent\AppData\Local\Continuum\Anaconda.
        # On 2003/XP, it will be in C:\Documents and Settings,
        # with a space. We're allowing spaces now.
        ${IfNot} ${Silent}
            StrCpy $INSTDIR $INSTDIR_JUSTME
        ${EndIf}
    ${Else}
        SetShellVarContext All
        ${IfNot} ${Silent}
            ExpandEnvStrings $0 ${DEFAULT_PREFIX_ALL_USERS}
            StrCpy $INSTDIR $0
        ${Endif}
    ${EndIf}
    Pop $0
FunctionEnd

!macro SetInstMode mode
    StrCpy $InstMode ${mode}
    Call InstModeChanged
!macroend

Function InstModePage_Leave
    ${LogSet} on
    Push $0
    Push $1
    Push $2

    ${NSD_GetState} $InstModePage_RadioButton_AllUsers $0
    ${If} $0 = 0
        !insertmacro SetInstMode ${JUST_ME}
    ${Else}
        !insertmacro SetInstMode ${ALL_USERS}
        ${IfNot} ${UAC_IsAdmin}
            !insertmacro DoElevation
        ${EndIf}
    ${EndIf}

    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function .onInit
    ${LogSet} on
    Push $0
    Push $1
    Push $2
    Push $R1
    Push $R2

    InitPluginsDir
    @TEMP_EXTRA_FILES@
    !insertmacro ParseCommandLineArgs

    # Select the correct registry to look at, depending
    # on whether it's a 32-bit or 64-bit installer
    SetRegView @BITS@
#if win64
    # If we're a 64-bit installer, make sure it's 64-bit Windows
    ${IfNot} ${RunningX64}
        MessageBox MB_OK|MB_ICONEXCLAMATION \
            "This installer is for a 64-bit version for ${NAME}$\n\
            but your system is 32-bit. Please use the 32-bit Windows$\n\
            ${NAME} installer." \
            /SD IDOK
        Abort
    ${EndIf}
#endif

    !insertmacro UAC_PageElevation_OnInit
    ${If} ${UAC_IsInnerInstance}
    ${AndIfNot} ${UAC_IsAdmin}
        SetErrorLevel 0x666
        Quit
    ${EndIf}

    # Look for a number of signs that indicate the user is a domain user and
    # alter the default installation directory for 'Just Me' accordingly.  We
    # want to ensure that if we're a user domain account, we always install to
    # %LOCALAPPDATA% (i.e. C:\Users\Trent\AppData\Local\Continuum\Anaconda),
    # as this is the only place guaranteed to not be backed by a network share
    # or included in a user's roaming profile.  However, if we're a normal user
    # account, then C:\Users\Trent\Anaconda is fine.
    ReadEnvStr $0 USERDNSDOMAIN
    ${If} $0 != ""
        # If not null, USERDNSDOMAIN is an unambiguous indication that we're
        # logged into a domain account.
        StrCpy $IsDomainUser 1
    ${Else}
        # If it's not set, apply some simple heuristics to discern whether or
        # not we're logged in as a domain user.
        ReadEnvStr $0 LOGONSERVER
        ${If} $0 == ""
            # This should never be unset; but if it is, we're definitely not
            # a domain user.
            StrCpy $IsDomainUser 0
        ${Else}
            StrCpy $1 $0 "" 2               # lop-off the leading \\.
            ${StrFilter} $1 "+" "" "" $2    # convert to uppercase, store in $2
            ${If} $2 == "MICROSOFTACCOUNT"
                # The new Windows 8.x live accounts have \\MicrosoftAccount
                # set as LOGONSERVER; interpret this as being a non-domain
                # user.
                StrCpy $IsDomainUser 0
            ${Else}
                ReadEnvStr $R1 COMPUTERNAME
                ${If} $R1 == ""
                    # This should never be unset either; if it is, assume
                    # we're not a domain user.
                    StrCpy $IsDomainUser 0
                ${Else}
                    # We've got a value for both LOGONSERVER and COMPUTERNAME
                    # environment variables (which should always be the case).
                    # Proceed to compare LOGONSERVER[-2:] to COMPUTERNAME; if
                    # they match, assume we're not a domain user account.

                    ${StrFilter} $R1 "+" "" "" $R2 # convert to uppercase
                    ${If} $2 != $R2
                        # COMPUTERNAME doesn't match LOGONSERVER; assume we're
                        # logged in via a domain account.
                        StrCpy $IsDomainUser 1
                    ${Else}
                        # COMPUTERNAME matches LOGONSERVER; safe to assume
                        # we're logged in as a user account.  (I guess there's
                        # the remote possibility a domain user has logged onto
                        # a server that has the same NetBIOS name as the Active
                        # Directory name...  if that's the case, potentially
                        # installing Anaconda into an area that gets picked up
                        # by a roaming profile is the very least of your
                        # problems.)
                        StrCpy $IsDomainUser 0

                    ${EndIf} # LOGONSERVER[-2:] != COMPUTERNAME

                ${EndIf} # COMPUTERNAME != ""

            ${EndIf} # LOGONSERVER != "\\MicrosoftAccount"

        ${EndIf} # LOGONSERVER != ""

    ${EndIf} # USERDNSDOMAIN != ""

    ${If} $IsDomainUser = 0
        ExpandEnvStrings $0 ${DEFAULT_PREFIX}
        StrCpy $INSTDIR_JUSTME $0
    ${ElseIf} $IsDomainUser = 1
        ExpandEnvStrings $0 ${DEFAULT_PREFIX_DOMAIN_USER}
        StrCpy $INSTDIR_JUSTME $0
    ${Else}
        # Should never happen; indicates a logic error above.
        MessageBox MB_OK "Internal error: IsUserDomain not set properly!" \
                   /SD IDOK
        Abort
    ${EndIf}

    ${If} $InstMode == ""
        StrCpy $InstMode ${JUST_ME}
        ${IfThen} ${UAC_IsAdmin} ${|} StrCpy $InstMode ${ALL_USERS} ${|}
        # If running as 'SYSTEM' then JustMe is not appropriate; note that
        # we should advise against this. SCCM has an option to run as user
        System::Call "advapi32::GetUserName(t .r0, *i ${NSIS_MAX_STRLEN} r1) i.r2"
        ${IfThen} $0 == "SYSTEM" ${|} StrCpy $InstMode ${ALL_USERS} ${|}
    ${EndIf}
    call InstModeChanged

    ${If} ${Silent}
        ${If} $InstMode == ${ALL_USERS}
            ${IfNot} ${UAC_IsAdmin}
                MessageBox MB_ICONSTOP "Installation for all users requires an elevated prompt."
                Abort
            ${EndIF}
        ${EndIF}
    ${EndIF}

    ; /D was not used, add default based on install type
    ${If} $InstDir == ""
        ${If} $InstMode == ${ALL_USERS}
            ExpandEnvStrings $0 ${DEFAULT_PREFIX_ALL_USERS}
            StrCpy $INSTDIR $0
        ${Else}
            strcpy $INSTDIR $INSTDIR_JUSTME
        ${EndIf}
    ${EndIf}

    ; Set default value
    ${If} $CheckPathLength == ""
        StrCpy $CheckPathLength "1"
    ${EndIf}

    # Initialize the default settings for the anaconda custom options
    Call mui_AnaCustomOptions_InitDefaults
    # Override custom options with explicitly given values from contruct.yaml.
    # If initialize_by_default (register_python_default) is None, do nothing.
#if initialize_conda is True and initialize_by_default is True
    ${If} $InstMode == ${JUST_ME}
        StrCpy $Ana_AddToPath_State ${BST_CHECKED}
    ${EndIF}
#endif
#if initialize_conda is True and initialize_by_default is False
    StrCpy $Ana_AddToPath_State ${BST_UNCHECKED}
#endif
#if register_python is True and register_python_default is True
    StrCpy $Ana_RegisterSystemPython_State ${BST_CHECKED}
#endif
#if register_python is True and register_python_default is False
    StrCpy $Ana_RegisterSystemPython_State ${BST_UNCHECKED}
#endif
#if check_path_length is True
    StrCpy $CheckPathLength "1"
#endif
#if check_path_length is False
    StrCpy $CheckPathLength "0"
#endif
#if keep_pkgs is True
    StrCpy $Ana_ClearPkgCache_State ${BST_UNCHECKED}
#endif
#if keep_pkgs is False
    StrCpy $Ana_ClearPkgCache_State ${BST_CHECKED}
#endif
#if pre_install_exists is True
    StrCpy $Ana_PreInstall_State ${BST_CHECKED}
#endif
#if pre_install_exists is False
    StrCpy $Ana_PreInstall_State ${BST_UNCHECKED}
#endif
#if post_install_exists is True
    StrCpy $Ana_PostInstall_State ${BST_CHECKED}
#endif
#if post_install_exists is False
    StrCpy $Ana_PostInstall_State ${BST_UNCHECKED}
#endif

    Call OnInit_Release

    Pop $R2
    Pop $R1
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function un.onInit
    Push $0
    Push $1
    Push $2
    Push $3

    # Resolve INSTDIR
    GetFullPathName $0 $INSTDIR
    # If the directory does not exist or cannot be resolved, $0 will be empty
    StrCmp $0 "" invalid_dir
    StrCpy $INSTDIR $0

    # Never run the uninstaller when $INSTDIR points at system-critical directories

    StrLen $InstDirLen $INSTDIR
    # INSTDIR is a full path and has no trailing backslash,
    # so if its length is 2, it is pointed at a system root
    StrCmp $InstdirLen 2 invalid_dir

    # Never delete anything inside Windows
    StrCpy $0 $INSTDIR 7 3
    StrCmp $0 "Windows" invalid_dir

    StrCpy $0 "ALLUSERSPROFILE APPDATA LOCALAPPDATA PROGRAMDATA PROGRAMFILES PROGRAMFILES(x86) PUBLIC SYSTEMDRIVE SYSTEMROOT USERPROFILE"
    StrCpy $1 1
    loop_critical:
        ${WordFind} $0 " " "E+$1" $2
        IfErrors endloop_critical
        ReadEnvStr $3 $2
        StrCmp $3 $INSTDIR invalid_dir
        IntOp $1 $1 + 1
        goto loop_critical
    endloop_critical:

    # Primitive check to see that $INSTDIR points to a conda directory
    StrCpy $0 "_conda.exe conda-meta\history"
    StrCpy $1 1
    loop_conda:
        ${WordFind} $0 " " "E+$1" $2
        IfErrors endloop_conda
        IfFileExists $INSTDIR\$2 0 invalid_dir
        IntOp $1 $1 + 1
        goto loop_conda
    endloop_conda:

    # All checks have passed
    goto valid_dir

    invalid_dir:
        MessageBox MB_OK|MB_ICONSTOP \
            "Error: $INSTDIR is not a valid conda directory. Please run the uninstaller from a conda directory." \
            /SD IDABORT
        abort
    valid_dir:

    # Select the correct registry to look at, depending
    # on whether it's a 32-bit or 64-bit installer
    SetRegView @BITS@

    # Since the switch to a dual-mode installer (All Users/Just Me), the
    # uninstaller will inherit the requested execution level of the main
    # installer -- which we now have to set to 'user'.  Thus, Windows will
    # not automatically elevate the uninstaller for us -- we need to do it
    # ourselves if we're not a 'Just Me' installation.
    !insertmacro UAC_PageElevation_OnInit
    ${IfNot} ${FileExists} "$INSTDIR\.nonadmin"
    ${AndIfNot} ${UAC_IsAdmin}
        !insertmacro DoElevation
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR\.nonadmin"
        SetShellVarContext Current
    ${Else}
        SetShellVarContext All
    ${EndIf}

    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

# http://nsis.sourceforge.net/Check_for_spaces_in_a_directory_path
Function CheckForSpaces
    ${LogSet} on
    Exch $R0
    Push $R1
    Push $R2
    Push $R3
    StrCpy $R1 -1
    StrCpy $R3 $R0
    StrCpy $R0 0
    loop:
        StrCpy $R2 $R3 1 $R1
        IntOp $R1 $R1 - 1
        StrCmp $R2 "" done
        StrCmp $R2 " " 0 loop
        IntOp $R0 $R0 + 1
    Goto loop
    done:
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
FunctionEnd

# http://nsis.sourceforge.net/StrCSpn,_StrCSpnReverse:_Scan_strings_for_characters
Function StrCSpn
 ${LogSet} on
 Exch $R0 ; string to check
 Exch
 Exch $R1 ; string of chars
 Push $R2 ; current char
 Push $R3 ; current char
 Push $R4 ; char loop
 Push $R5 ; char loop

  StrCpy $R4 -1

  NextChar:
  StrCpy $R2 $R1 1 $R4
  IntOp $R4 $R4 - 1
   StrCmp $R2 "" StrOK

   StrCpy $R5 -1

   NextCharCheck:
   StrCpy $R3 $R0 1 $R5
   IntOp $R5 $R5 - 1
    StrCmp $R3 "" NextChar
    StrCmp $R3 $R2 0 NextCharCheck
     StrCpy $R0 $R2
     Goto Done

 StrOK:
 StrCpy $R0 ""

 Done:

 Pop $R5
 Pop $R4
 Pop $R3
 Pop $R2
 Pop $R1
 Exch $R0
FunctionEnd

# http://stackoverflow.com/a/29569614/1170370
!macro _IsNonEmptyDirectory _a _b _t _f
!insertmacro _LOGICLIB_TEMP
!insertmacro _IncreaseCounter
Push $0
FindFirst $0 $_LOGICLIB_TEMP "${_b}\*"
_IsNonEmptyDirectory_loop${LOGICLIB_COUNTER}:
    StrCmp "" $_LOGICLIB_TEMP _IsNonEmptyDirectory_done${LOGICLIB_COUNTER}
    StrCmp "." $_LOGICLIB_TEMP +2
    StrCmp ".." $_LOGICLIB_TEMP 0 _IsNonEmptyDirectory_done${LOGICLIB_COUNTER}
    FindNext $0 $_LOGICLIB_TEMP
    Goto _IsNonEmptyDirectory_loop${LOGICLIB_COUNTER}
_IsNonEmptyDirectory_done${LOGICLIB_COUNTER}:
FindClose $0
Pop $0
!insertmacro _!= "" $_LOGICLIB_TEMP `${_t}` `${_f}`
!macroend
!define IsNonEmptyDirectory `"" IsNonEmptyDirectory`


Function OnDirectoryLeave
    ${LogSet} on
    ${If} ${IsNonEmptyDirectory} "$InstDir"
        DetailPrint "::error:: Directory '$INSTDIR' is not empty, please choose a different location."
        MessageBox MB_OK|MB_ICONEXCLAMATION \
            "Directory '$INSTDIR' is not empty,$\n\
             please choose a different location." \
            /SD IDOK
        Abort
    ${EndIf}

    ReadRegStr $LongPathsEnabled HKLM "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled"
    StrLen $InstDirLen "$InstDir"

    ${If} $CheckPathLength == "1"
    ${AndIf} $LongPathsEnabled == "0"
    ${AndIf} $InstDirLen > 46
        ; With windows 10, we can enable support for long path, for earlier
        ; version, suggest user to use shorter installation path
        ${If} ${AtLeastWin10}
        ${AndIfNot} $ARGV_NoRegistry = "1"
            ; If we have admin right, we enable long path on windows
            ${If} ${UAC_IsAdmin}
                WriteRegDWORD HKLM "SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
            ; If we don't have admin right, we suggest a shorter path or suggest to run with admin right
            ${Else}
                DetailPrint "::error:: The installation path should be shorter than 46 characters or \
                             the installation requires administrator rights to enable long \
                             path on Windows."
                MessageBox MB_OK|MB_ICONSTOP "The installation path should be shorter than 46 characters or \
                                              the installation requires administrator rights to enable long \
                                              path on Windows." \
                           /SD IDOK
                Abort
            ${EndIf}
        ; If we don't have admin right, we suggest a shorter path or suggest to run with admin right
        ${Else}
            DetailPrint "::error:: The installation path should be shorter than 46 characters. \
                         Please choose another location."
            MessageBox MB_OK|MB_ICONSTOP "The installation path should be shorter than 46 characters. \
                                          Please choose another location." \
                       /SD IDOK
            Abort
        ${EndIf}
    ${EndIf}

    # Call the CheckForSpaces function.
    Push $INSTDIR # Input string (install path).
    Call CheckForSpaces
    Pop $R0 # The function returns the number of spaces found in the input string.

    Push $R7
    Push $R8
    Push $R9
    # Check if any spaces exist in $INSTDIR.
    StrCmp $R0 0 NoSpaces

        # Plural if more than 1 space in $INSTDIR.
        StrCmp $R0 1 0 +3
          StrCpy $R1 ""
        Goto +2
          StrCpy $R1 "s"

        ${If} ${Silent}
          StrCpy $R7 " "
        ${Else}
          StrCpy $R7 "$\n"
        ${EndIf}
        StrCpy $R8 "'Destination Folder' contains $R0 space$R1.$R7This can cause problems with several conda packages.$R7"
#if check_path_spaces is True
            StrCpy $R8 "$R8Please remove the space$R1 from the destination folder."
            StrCpy $R9 "Error"
#else
            StrCpy $R8 "$R8Please consider removing the space$R1."
            StrCpy $R9 "Warning"
#endif
        # Show message box then take the user back to the Directory page.
        ${If} ${Silent}
            DetailPrint "::$R9:: $R8"
        ${Else}
            MessageBox MB_OK|MB_ICONINFORMATION "$R9: $R8" /SD IDOK
        ${EndIf}
#if check_path_spaces is True
            abort
#endif
    NoSpaces:
    Pop $R7
    Pop $R8
    Pop $R9

    # List of characters not allowed anywhere in $INSTDIR
    Push "^%!=,()"
    Push $INSTDIR
    Call StrCSpn
    Pop $R0

    StrCmp $R0 "" NoInvalidCharaceters
        DetailPrint "::error:: 'Destination Folder' contains the following invalid character: $R0"
        MessageBox MB_OK|MB_ICONEXCLAMATION \
            "Error: 'Destination Folder' contains the following invalid character: $R0" \
            /SD IDOK
        abort
    NoInvalidCharaceters:

    UnicodePathTest::SpecialCharPathTest $INSTDIR
    Pop $R1
    StrCmp $R1 "nothingspecial" nothing_special_path
        DetailPrint "::error:: 'Destination Folder' contains the following invalid character$R1"
        MessageBox MB_OK|MB_ICONEXCLAMATION \
            "Error: 'Destination Folder' contains the following invalid character$R1" \
            /SD IDOK
        abort
    nothing_special_path:

      ; test if path contains unicode characters
      UnicodePathTest::UnicodePathTest $INSTDIR
      Pop $R1

      # Python 3 can be installed in a CP_ACP path until MKL is Unicode capable.
      # (mkl_rt.dll calls LoadLibraryA() to load mkl_intel_thread.dll)
      # Python 2 can only be installed to an ASCII path.
      StrCmp $R1 "ascii" valid_path
      StrCmp ${PY_VER} "2.7" not_cp_acp_capable
      StrCmp $R1 "ascii_cp_acp" valid_path
      not_cp_acp_capable:
          DetailPrint "::error:: Due to incompatibility with several \
              Python libraries, 'Destination Folder' cannot contain non-ascii characters \
              (special characters or diacritics).  Please choose another location."
          MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Due to incompatibility with several \
              Python libraries, 'Destination Folder' cannot contain non-ascii characters \
              (special characters or diacritics).  Please choose another location." \
              /SD IDOK
          abort

      valid_path:

    Push $R1
    ${IsWritable} $INSTDIR $R1
    IntCmp $R1 0 pathgood
    Pop $R1
    DetailPrint "::error: Path $INSTDIR is not writable. Please check permissions or \
                 try respawning the installer with elevated privileges."
    MessageBox MB_OK|MB_ICONEXCLAMATION \
        "Error: Path $INSTDIR is not writable. Please check permissions or \
         try respawning the installer with elevated privileges." \
        /SD IDOK
    Abort

    pathgood:
    Pop $R1

FunctionEnd

Function .onVerifyInstDir
    ${LogSet} on
    StrLen $0 $Desktop
    StrCpy $0 $INSTDIR $0
    StrCmp $0 $Desktop 0 PathGood
    Abort
    PathGood:
FunctionEnd

Function un.OnDirectoryLeave
    MessageBox MB_YESNO \
	    "Are you sure you want to remove '$INSTDIR' and all of its contents?" \
	    /SD IDYES \
	    IDYES confirmed_yes IDNO confirmed_no
    confirmed_no:
        MessageBox MB_OK|MB_ICONSTOP "Uninstallation aborted by user." /SD IDOK
	Quit
    confirmed_yes:
FunctionEnd

# Make function available for both installer and uninstaller
# Uninstaller functions need an `un.` prefix, so we use a macro to do both
# see https://nsis.sourceforge.io/Sharing_functions_between_Installer_and_Uninstaller
!macro AbortRetryNSExecWaitMacro un
    Function ${un}AbortRetryNSExecWait
        # This function expects three arguments in the stack
        # $1: 'WithLog' or 'NoLog': Use ExecToLog or just Exec, respectively
        # $2: The message to show if an error occurred
        # $3: The command to run, quoted
        # Note that the args need to be pushed to the stack in reverse order!
        # Search 'AbortRetryNSExecWait' in this script to see examples
        ${LogSet} on
        Pop $1
        Pop $2
        Pop $3
        ${Do}
            ${If} $1 == "WithLog"
                nsExec::ExecToLog $3
            ${ElseIf} $1 == "NoLog"
                nsExec::Exec $3
            ${Else}
                DetailPrint "::error:: AbortRetryNSExecWait: 1st argument must be 'WithLog' or 'NoLog'. You used: $1"
                Abort
            ${EndIf}
            pop $0
            ${If} $0 != "0"
                DetailPrint "::error:: $2"
                MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION|MB_DEFBUTTON3 \
                        $2 /SD IDIGNORE IDABORT abort IDRETRY retry
                ; IDIGNORE: Continue anyway
                StrCpy $0 "0"
                goto retry
            abort:
                ; Abort installation
                Abort
            retry:
                ; Retry the nsExec command
            ${EndIf}
        ${LoopWhile} $0 != "0"
    FunctionEnd
!macroend
!insertmacro AbortRetryNSExecWaitMacro ""
!insertmacro AbortRetryNSExecWaitMacro "un."

# Installer sections
Section "Install"
    ${LogSet} on

    ${If} ${Silent}
        call OnDirectoryLeave
    ${EndIf}

    SetOutPath "$INSTDIR\Lib"
    File "@NSIS_DIR@\_nsis.py"
    File "@NSIS_DIR@\_system_path.py"

    # Resolve INSTDIR so that paths and registry keys do not contain '..' or similar strings.
    # $0 is empty if the directory doesn't exist, but the File commands should have created it already.
    GetFullPathName $0 $INSTDIR
    ${If} $0 == ""
	MessageBox MB_ICONSTOP "Error resolving installation directory." /SD IDABORT
	Quit
    ${EndIf}
    StrCpy $INSTDIR $0

    ReadEnvStr $0 SystemRoot
    # set PATH for the installer process, so that MSVC runtimes get found OK
    #    This is also isolating PATH to be just us and Windows core stuff, which hopefully avoids
    #    clashes with other stuff on PATH
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("PATH", \
                 "$INSTDIR;$INSTDIR\Library\mingw-w64\bin;$INSTDIR\Library\usr\bin;$INSTDIR\Library\bin;$INSTDIR\Scripts;$INSTDIR\bin;$0;$0\system32;$0\system32\Wbem").r0'

    # A conda-meta\history file is required for a valid conda prefix
    SetOutPath "$INSTDIR\conda-meta"
    File __CONDA_HISTORY__

    SetOutPath "$INSTDIR"
    File __CONDA_EXE__
    File __PRE_UNINSTALL__

    # Copy extra files (code generated on winexe.py)
    @EXTRA_FILES@

    ${If} $InstMode = ${JUST_ME}
        SetOutPath "$INSTDIR"
        FileOpen $0 ".nonadmin" w
        FileClose $0
    ${EndIf}

    SetOutPath "$INSTDIR\pkgs"
    File __URLS_FILE__
    File __URLS_TXT_FILE__
#if pre_install_exists is True
    File __PRE_INSTALL__
#endif
    File __POST_INSTALL__
    File /nonfatal /r __INDEX_CACHE__
    File /r __REPODATA_RECORD__

    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("CONDA_SAFETY_CHECKS", "disabled").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("CONDA_EXTRA_SAFETY_CHECKS", "no").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("CONDA_PKGS_DIRS", "$INSTDIR\pkgs")".r0'
    # Extra info for pre and post install scripts
    # NOTE: If more vars are added, make sure to update the examples/scripts tests too
    #       There's a similar block for the pre_uninstall script, further down this file.
    #       Update that one as well!
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("PREFIX", "$INSTDIR").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_NAME", "${NAME}").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_VER", "${VERSION}").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_PLAT", "${PLATFORM}").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_TYPE", "EXE").r0'

    @PKG_COMMANDS@

    SetDetailsPrint TextOnly
    DetailPrint "Setting up the package cache..."
    push '"$INSTDIR\_conda.exe" constructor --prefix "$INSTDIR" --extract-conda-pkgs'
    push 'Failed to extract packages'
    push 'NoLog'
    # We use NoLog here because TQDM progress bars are parsed as a single line in NSIS 3.08
    # These can crash the installer if they get too long (a few packages is enough!)
    call AbortRetryNSExecWait
    SetDetailsPrint both

    IfFileExists "$INSTDIR\pkgs\pre_install.bat" 0 NoPreInstall
        DetailPrint "Running pre_install scripts..."
        ReadEnvStr $5 SystemRoot
        ReadEnvStr $6 windir
        # This 'FileExists' also returns True for directories
        ${If} ${FileExists} "$5"
            push '"$5\System32\cmd.exe" /D /C "$INSTDIR\pkgs\pre_install.bat"'
        ${ElseIf} ${FileExists} "$6"
            push '"$6\System32\cmd.exe" /D /C "$INSTDIR\pkgs\pre_install.bat"'
        ${Else}
            # Cross our fingers CMD is in PATH
            push 'cmd.exe /D /C "$INSTDIR\pkgs\pre_install.bat"'
        ${EndIf}
        push "Failed to run pre_install"
        push 'WithLog'
        call AbortRetryNSExecWait
    NoPreInstall:

    @SETUP_ENVS@

    @WRITE_CONDARC@

    AddSize @SIZE@

    ${If} $Ana_CreateShortcuts_State = ${BST_CHECKED}
        DetailPrint "Creating @NAME@ menus..."
        push '"$INSTDIR\_conda.exe" constructor --prefix "$INSTDIR" --make-menus @MENU_PKGS@'
        push 'Failed to create menus'
        push 'WithLog'
        call AbortRetryNSExecWait
    ${EndIf}

#if has_conda is True
    DetailPrint "Initializing conda directories..."
    push '"$INSTDIR\pythonw.exe" -E -s "$INSTDIR\Lib\_nsis.py" mkdirs'
    push 'Failed to initialize conda directories'
    push 'WithLog'
    call AbortRetryNSExecWait
#endif

    ${If} $Ana_PostInstall_State = ${BST_CHECKED}
        DetailPrint "Running post install..."
        push '"$INSTDIR\pythonw.exe" -E -s "$INSTDIR\Lib\_nsis.py" post_install'
        push 'Failed to run post install script'
        push 'WithLog'
        call AbortRetryNSExecWait
    ${EndIf}

    ${If} $Ana_ClearPkgCache_State = ${BST_CHECKED}
        DetailPrint "Clearing package cache..."
        push '"$INSTDIR\_conda.exe" clean --all --force-pkgs-dirs --yes'
        push 'Failed to clear package cache'
        push 'WithLog'
        call AbortRetryNSExecWait
    ${EndIf}

    ${If} $Ana_AddToPath_State = ${BST_CHECKED}
        DetailPrint "Adding to PATH..."
        push '"$INSTDIR\pythonw.exe" -E -s "$INSTDIR\Lib\_nsis.py" addpath ${PYVERSION} ${NAME} ${VERSION} ${ARCH}'
        push 'Failed to add @NAME@ to the system PATH'
        push 'WithLog'
        call AbortRetryNSExecWait
    ${EndIf}

    # Create registry entries saying this is the system Python
    # (for this version)
    !define PYREG "Software\Python\PythonCore\${PY_VER}"
    ${If} $Ana_RegisterSystemPython_State == ${BST_CHECKED}
        WriteRegStr SHCTX "${PYREG}\Help\Main Python Documentation" \
            "Main Python Documentation" \
            "$INSTDIR\Doc\python${PYVERSION_JUSTDIGITS}.chm"

        WriteRegStr SHCTX "${PYREG}\InstallPath" "" "$INSTDIR"

        WriteRegStr SHCTX "${PYREG}\InstallPath\InstallGroup" \
            "" "Python ${PY_VER}"

        WriteRegStr SHCTX "${PYREG}\Modules" "" ""
        WriteRegStr SHCTX "${PYREG}\PythonPath" \
            "" "$INSTDIR\Lib;$INSTDIR\DLLs"
    ${EndIf}

    ${If} $ARGV_NoRegistry == "0"
        # Registry uninstall info
        WriteRegStr SHCTX "${UNINSTREG}" "DisplayName" "${UNINSTALL_NAME}"
        WriteRegStr SHCTX "${UNINSTREG}" "DisplayVersion" "${VERSION}"
        WriteRegStr SHCTX "${UNINSTREG}" "Publisher" "${COMPANY}"
        WriteRegStr SHCTX "${UNINSTREG}" "UninstallString" \
            "$\"$INSTDIR\Uninstall-${NAME}.exe$\""
        WriteRegStr SHCTX "${UNINSTREG}" "QuietUninstallString" \
            "$\"$INSTDIR\Uninstall-${NAME}.exe$\" /S"
        WriteRegStr SHCTX "${UNINSTREG}" "DisplayIcon" \
            "$\"$INSTDIR\Uninstall-${NAME}.exe$\""

        WriteRegDWORD SHCTX "${UNINSTREG}" "NoModify" 1
        WriteRegDWORD SHCTX "${UNINSTREG}" "NoRepair" 1
    ${EndIf}

    WriteUninstaller "$INSTDIR\Uninstall-${NAME}.exe"
SectionEnd

!macro AbortRetryNSExecWaitLibNsisCmd cmd
    SetDetailsPrint both
    DetailPrint "Running ${cmd} scripts..."
    SetDetailsPrint listonly
    ${If} ${Silent}
        push '"$INSTDIR\pythonw.exe" -E -s "$INSTDIR\Lib\_nsis.py" ${cmd}'
    ${Else}
        push '"$INSTDIR\python.exe" -E -s "$INSTDIR\Lib\_nsis.py" ${cmd}'
    ${EndIf}
    push "Failed to run ${cmd}"
    push 'WithLog'
    call un.AbortRetryNSExecWait
    SetDetailsPrint both
!macroend

Section "Uninstall"
    # Remove menu items, path entries

    DetailPrint "Deleting @NAME@ menus..."
    nsExec::ExecToLog '"$INSTDIR\_conda.exe" constructor --prefix "$INSTDIR" --rm-menus'

    # ensure that MSVC runtime DLLs are on PATH during uninstallation
    ReadEnvStr $0 PATH
    # set PATH for the installer process, so that MSVC runtimes get found OK
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("PATH", \
                 "$INSTDIR;$INSTDIR\Library\mingw-w64\bin;$INSTDIR\Library\usr\bin;$INSTDIR\Library\bin;$INSTDIR\Scripts;$INSTDIR\bin;$0;$0\system32;$0\system32\Wbem").r0'

    # our newest Python builds have a patch that allows us to control the PATH search stuff much more
    #   carefully.  More info at https://docs.conda.io/projects/conda/en/latest/user-guide/troubleshooting.html#solution
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("CONDA_DLL_SEARCH_MODIFICATION_ENABLE", "1").r0'

    # Read variables the uninstaller needs from the registry
    StrCpy $R0 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    StrLen $R1 "Uninstall-${NAME}.exe"
    IntOp $R1 $R1 + 3
    StrCpy $0 0
    loop_path:
        EnumRegKey $1 SHCTX $R0 $0
        StrCmp $1 "" endloop_path
        StrCpy $2 "$R0\$1"
        ReadRegStr $4 SHCTX $2 "UninstallString"
        StrLen $5 $4
        IntOp $5 $5 - $R1
        StrCpy $4 $4 $5 1
        ${If} $4 == $INSTDIR
            StrCpy $INSTALLER_NAME_FULL $1
            ReadRegStr $INSTALLER_VERSION SHCTX $2 "DisplayVersion"
            goto endloop_path
        ${EndIf}
        IntOp $0 $0 + 1
        goto loop_path
    endloop_path:

    # Extra info for pre_uninstall scripts
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("PREFIX", "$INSTDIR").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_NAME", "${NAME}").r0'
    StrCpy $0 ${VERSION}
    ${If} $INSTALLER_VERSION != ""
	StrCpy $0 $INSTALLER_VERSION
    ${EndIf}
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_VER", "$0").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_PLAT", "${PLATFORM}").r0'
    System::Call 'kernel32::SetEnvironmentVariable(t,t)i("INSTALLER_TYPE", "EXE").r0'

    !insertmacro AbortRetryNSExecWaitLibNsisCmd "pre_uninstall"
    !insertmacro AbortRetryNSExecWaitLibNsisCmd "rmpath"
    !insertmacro AbortRetryNSExecWaitLibNsisCmd "rmreg"

    DetailPrint "Removing files and folders..."
    nsExec::Exec 'cmd.exe /D /C RMDIR /Q /S "$INSTDIR"'

    # In case the last command fails, run the slow method to remove leftover
    RMDir /r /REBOOTOK "$INSTDIR"

    ${If} $INSTALLER_NAME_FULL != ""
        DeleteRegKey SHCTX "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$INSTALLER_NAME_FULL"
    ${EndIf}

    # If Anaconda was registered as the official Python for this version,
    # remove it from the registry
    StrCpy $R0 "SOFTWARE\Python\PythonCore"
    StrCpy $0 0
    loop_py:
        EnumRegKey $1 SHCTX $R0 $0
        StrCmp $1 "" endloop_py
        ReadRegStr $2 SHCTX "$R0\$1\InstallPath" ""
        ${If} $2 == $INSTDIR
            StrCpy $R1 $1
            DeleteRegKey SHCTX "$R0\$1"
            goto endloop_py
        ${EndIf}
        IntOp $0 $0 + 1
        goto loop_py
    endloop_py:
SectionEnd

!if '@SIGNTOOL_COMMAND@' != ''
    # Signing for installer and uninstaller; nsis 3.08 required for uninstfinalize!
    # "= 0" comparison required to prevent both tasks running in parallel, which would cause signtool to fail
    # %1 is replaced by the installer and uninstaller paths, respectively
    !finalize '@SIGNTOOL_COMMAND@ "%1"' = 0
    !uninstfinalize '@SIGNTOOL_COMMAND@ "%1"' = 0
!endif
