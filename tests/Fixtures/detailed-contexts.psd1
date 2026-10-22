@{
    # Static, offline capability snapshots. Completion never probes executable versions.
    Versions = @{ WinGet='1.29.380'; Windows='10.0.26300'; OpenSSH='9.5p2' }
    Sources = @(
        'https://learn.microsoft.com/windows/package-manager/winget/source'
        'https://learn.microsoft.com/windows-server/administration/windows-commands/schtasks-create'
        'https://learn.microsoft.com/windows-server/administration/windows-commands/sc-query'
        'https://learn.microsoft.com/windows-server/administration/windows-commands/taskkill'
        'https://man.openbsd.org/ssh_config'
    )
    Positive = @(
        @{ Line='winget source ed'; Expected='edit' }
        @{ Line='winget source add --tr'; Expected='--trust-level' }
        @{ Line='winget source add --trust-level=tr'; Expected='--trust-level=trusted' }
        @{ Line='winget source add -t Microsoft.R'; Expected='Microsoft.Rest' }
        @{ Line='winget source add Example https://example.invalid --he'; Expected='--header' }
        @{ Line='winget source edit Example -e fa'; Expected='false' }
        @{ Line='winget source reset --fo'; Expected='--force' }
        @{ Line='winget source list --pr'; Expected='--proxy' }
        @{ Line='schtasks /Create /SC HOURLY /MO 23'; Expected='23' }
        @{ Line='schtasks /Create /SC WEEKLY /MO 52'; Expected='52' }
        @{ Line='schtasks /Create /SC MINUTE /MO 1439'; Expected='1439' }
        @{ Line='schtasks /Create /SC WEEKLY /D "MON,T'; Expected="'MON,TUE'" }
        @{ Line='schtasks /Create /SC MONTHLY /M "JAN,F'; Expected="'JAN,FEB'" }
        @{ Line='schtasks /Create /SC ONIDLE /I'; Expected='/I' }
        @{ Line='schtasks /Create /SC ONEVENT /EC'; Expected='/EC' }
        @{ Line='schtasks /Create /SC ONSTART /DE'; Expected='/DELAY' }
        @{ Line='schtasks /Create /SC DAILY /ET 23:00 /K'; Expected='/K' }
        @{ Line='sc.exe config Example obj= Local'; Expected='LocalSystem' }
        @{ Line='sc.exe config Example type= interact type= s'; Expected='share' }
        @{ Line='taskkill /FI "STA'; Expected="'STATUS '" }
        @{ Line='taskkill /FI "PID g'; Expected="'PID gt '" }
        @{ Line='taskkill /FI "STATUS eq N'; Expected="'STATUS eq NOT RESPONDING'" }
        @{ Line='taskkill /S remote /FI "PID g'; Expected="'PID ge '" }
        @{ Line='taskkill /FI "PID gt 100" /FI "STATUS ne U'; Expected="'STATUS ne UNKNOWN'" }
    )
    Negative = @(
        @{ Line='winget source list --he'; Forbidden='--header' }
        @{ Line='winget source edit --he'; Forbidden='--header' }
        @{ Line='winget source update --ac'; Forbidden='--accept-source-agreements' }
        @{ Line='winget source remove --fo'; Forbidden='--force' }
        @{ Line='winget source add -a x'; Forbidden='x64' }
        @{ Line='winget source add --explicit fa'; Forbidden='false' }
        @{ Line='schtasks /Create /SC ONCE /MO '; Forbidden='FIRST' }
        @{ Line='schtasks /Create /SC DAILY /M'; Forbidden='/M' }
        @{ Line='schtasks /Create /SC HOURLY /RI'; Forbidden='/RI' }
        @{ Line='schtasks /Create /SC DAILY /DE'; Forbidden='/DELAY' }
        @{ Line='schtasks /Create /SC ONSTART /DU'; Forbidden='/DU' }
        @{ Line='schtasks /Create /SC DAILY /DU 01:00 /ET'; Forbidden='/ET' }
        @{ Line='schtasks /Create /SC DAILY /K'; Forbidden='/K' }
        @{ Line='schtasks /Create /SC DAILY /RU SYSTEM /RP'; Forbidden='/RP' }
        @{ Line='schtasks /Query /FO LIST /N'; Forbidden='/NH' }
        @{ Line='schtasks /Query /XML /F'; Forbidden='/FO' }
        @{ Line='schtasks /Create /SC WEEKLY /D "MON,MO'; Forbidden="'MON,MON'" }
        @{ Line='sc.exe config Example type= interact type= k'; Forbidden='kernel' }
        @{ Line='sc.exe create '; Forbidden='LocalSystem' }
        @{ Line='taskkill /FI "STATUS g'; Forbidden="'STATUS gt '" }
        @{ Line='taskkill /FI "PID eq R'; Forbidden="'PID eq RUNNING'" }
        @{ Line='taskkill /FI "UNKNOWN '; Forbidden="'UNKNOWN eq '" }
        @{ Line='taskkill /S remote /FI "STA'; Forbidden="'STATUS '" }
        @{ Line='taskkill /S remote /FI "WIN'; Forbidden="'WINDOWTITLE '" }
        @{ Line='taskkill /S remote /FI "STATUS eq R'; Forbidden="'STATUS eq RUNNING'" }
    )
}
