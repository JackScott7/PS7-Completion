@{
    # Supported F1 finite-value contexts, including repeated and attached operands.
    # Sources: Microsoft Learn schtasks-create/sc-config and winget-cli Argument.cpp.
    FiniteValues = @(
        @{ Line='winget install --scope=ma'; Expected='--scope=machine' }
        @{ Line='winget install --scope=user --scope ma'; Expected='machine' }
        @{ Line='winget install --architecture=x64 --scope ma'; Expected='machine' }
        @{ Line='schtasks /Create /SC WEEKLY /D MO'; Expected='MON' }
        @{ Line='schtasks /Create /SC MONTHLY /MO FI'; Expected='FIRST' }
        @{ Line='schtasks /Create /SC MONTHLY /MO FIRST /D TU'; Expected='TUE' }
        @{ Line='schtasks /Create /SC MONTHLY /D 31'; Expected='31' }
        @{ Line='schtasks /Create /SC MONTHLY /M JA'; Expected='JAN' }
        @{ Line='sc.exe config Example start= auto start= de'; Expected='demand' }
        @{ Line='sc.exe create Example error= cr'; Expected='critical' }
        @{ Line='sc.exe config Example tag= y'; Expected='yes' }
        @{ Line='sc.exe query type= service type= dr'; Expected='driver' }
    )
}
