{
    param($Context)
    $operations = @('/Create', '/Delete', '/Query', '/Change', '/Run', '/End', '/ShowSid', '/?')
    if (-not $Context.PreviousArguments.Count) {
        New-PS7CompletionResult -Candidate $operations -WordToComplete $Context.WordToComplete -ResultType Command
        return
    }
    $operation = $Context.PreviousArguments[0]
    $options = @{ '/?'=0; '/S'=1; '/U'=1; '/P'=1 }
    switch ($operation) {
        '/Create' { $extra = @{ '/TN'=1; '/TR'=1; '/SC'=1; '/ST'=1; '/SD'=1; '/ED'=1; '/ET'=1; '/MO'=1; '/D'=1; '/M'=1; '/RU'=1; '/RP'=1; '/RL'=1; '/XML'=1; '/I'=1; '/RI'=1; '/DU'=1; '/K'=0; '/DELAY'=1; '/EC'=1; '/NP'=0; '/V1'=0; '/HRESULT'=0; '/F'=0; '/IT'=0; '/Z'=0 } }
        '/Change' { $extra = @{ '/TN'=1; '/TR'=1; '/ST'=1; '/SD'=1; '/ED'=1; '/ET'=1; '/RU'=1; '/RP'=1; '/ENABLE'=0; '/DISABLE'=0; '/IT'=0 } }
        '/Query' { $extra = @{ '/TN'=1; '/FO'=1; '/NH'=0; '/V'=0; '/XML'=0 } }
        '/Delete' { $extra = @{ '/TN'=1; '/F'=0 } }
        '/Run' { $extra = @{ '/TN'=1; '/I'=0 } }
        '/End' { $extra = @{ '/TN'=1 } }
        '/ShowSid' { $options = @{ '/?'=0 }; $extra = @{ '/TN'=1 } }
        default { return }
    }
    foreach ($key in $extra.Keys) { $options[$key] = $extra[$key] }
    $state = Get-PS7OptionState -Arguments @($Context.PreviousArguments | Select-Object -Skip 1) -Options $options
    if (-not $state.Valid -or $state.Positionals.Count) { return }
    $available = @{} + $options
    if ($operation -eq '/Create') {
        $schedule = $state.Values['/SC']
        if ($schedule) {
            if ($schedule -notin @('MINUTE','HOURLY','DAILY','WEEKLY','MONTHLY','ONCE','ONSTART','ONLOGON','ONIDLE','ONEVENT')) { return }
            if ($schedule -notin @('MINUTE','HOURLY','DAILY','WEEKLY','MONTHLY','ONEVENT')) { $available.Remove('/MO') }
            if ($schedule -notin @('WEEKLY','MONTHLY') -or $state.Values['/MO'] -eq 'LASTDAY') { $available.Remove('/D') }
            if ($schedule -ne 'MONTHLY') { $available.Remove('/M') }
            if ($schedule -ne 'ONIDLE') { $available.Remove('/I') }
            if ($schedule -ne 'ONEVENT') { $available.Remove('/EC') }
            if ($schedule -notin @('ONSTART','ONLOGON','ONEVENT')) { $available.Remove('/DELAY') }
            if ($schedule -in @('MINUTE','HOURLY','ONSTART','ONLOGON','ONIDLE','ONEVENT')) { $available.Remove('/RI') }
            if ($schedule -in @('ONSTART','ONLOGON','ONIDLE','ONEVENT')) {
                foreach ($key in @('/ET','/DU','/K')) { $available.Remove($key) }
            }
        }
        if ($state.Values.ContainsKey('/ET')) { $available.Remove('/DU') }
        if ($state.Values.ContainsKey('/DU')) { $available.Remove('/ET') }
        if (-not $state.Values.ContainsKey('/ET') -and -not $state.Values.ContainsKey('/DU')) { $available.Remove('/K') }
        if ($state.Values['/RU'] -in @('SYSTEM','NT AUTHORITY\SYSTEM')) { $available.Remove('/RP') }
        if ($state.Values.ContainsKey('/IT')) { $available.Remove('/NP') }
        if ($state.Values.ContainsKey('/NP')) { $available.Remove('/IT') }
    }
    if ($operation -eq '/Query') {
        if ($state.Values['/FO'] -eq 'LIST') { $available.Remove('/NH') }
        if ($state.Values.ContainsKey('/XML')) { foreach ($key in @('/FO','/NH','/V')) { $available.Remove($key) } }
        if ($state.Values.ContainsKey('/FO') -or $state.Values.ContainsKey('/V')) { $available.Remove('/XML') }
    }
    if ($state.Pending -and -not $available.ContainsKey($state.Pending)) { return }
    if ($state.Pending) {
        if ($state.Pending -eq '/TN' -and $operation -ne '/Create' -and -not $state.Values.ContainsKey('/S')) {
            New-PS7CompletionResult -Candidate @(Get-PS7QueryData Tasks) -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/SC') {
            New-PS7CompletionResult -Candidate MINUTE,HOURLY,DAILY,WEEKLY,MONTHLY,ONCE,ONSTART,ONLOGON,ONIDLE,ONEVENT -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/D' -and $state.Values['/SC'] -in @('WEEKLY','MONTHLY')) {
            $days = if ($state.Values['/SC'] -eq 'WEEKLY' -or $state.Values['/MO'] -in @('FIRST','SECOND','THIRD','FOURTH','LAST')) { @('MON','TUE','WED','THU','FRI','SAT','SUN') }
                elseif ($state.Values['/MO'] -ne 'LASTDAY') { @((1..31 | ForEach-Object { [string]$_ })) + @('*') } else { @() }
            Complete-PS7CommaValue -Candidates $days -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/M' -and $state.Values['/SC'] -eq 'MONTHLY') {
            Complete-PS7CommaValue -Candidates JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC,'*' -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/MO' -and $state.Values['/SC'] -in @('MINUTE','HOURLY','DAILY','WEEKLY')) {
            $maximum = @{ MINUTE=1439; HOURLY=23; DAILY=365; WEEKLY=52 }[$state.Values['/SC']]
            New-PS7CompletionResult -Candidate @(1..$maximum | ForEach-Object { [string]$_ }) -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/MO' -and $state.Values['/SC'] -eq 'MONTHLY') {
            New-PS7CompletionResult -Candidate (@((1..12 | ForEach-Object { [string]$_ })) + @('FIRST','SECOND','THIRD','FOURTH','LAST','LASTDAY')) -WordToComplete $Context.WordToComplete
        }
        elseif ($state.Pending -eq '/FO') { New-PS7CompletionResult -Candidate TABLE,LIST,CSV -WordToComplete $Context.WordToComplete }
        elseif ($state.Pending -eq '/RL') { New-PS7CompletionResult -Candidate LIMITED,HIGHEST -WordToComplete $Context.WordToComplete }
        return
    }
    New-PS7CompletionResult -Candidate @($available.Keys) -WordToComplete $Context.WordToComplete
}
