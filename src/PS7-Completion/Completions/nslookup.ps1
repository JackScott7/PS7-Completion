{
    param($Context)
    # Windows nslookup uses -option=value, not separate option operands.
    # Stop at the hostname/server; interactive prompt commands are out of scope.
    $flags = @('-debug','-nodebug','-d2','-nod2','-recurse','-norecurse','-search','-nosearch','-vc','-novc','-defname','-nodefname')
    $values = @{
        '-type' = @('A','AAAA','ANY','CNAME','MX','NS','PTR','SOA','SRV','TXT')
        '-querytype' = @('A','AAAA','ANY','CNAME','MX','NS','PTR','SOA','SRV','TXT')
        '-class' = @('IN','CHAOS','HESIOD','ANY')
        '-timeout' = @(); '-retry' = @(); '-port' = @(); '-domain' = @(); '-srchlist' = @()
    }
    foreach ($argument in $Context.PreviousArguments) {
        if ($flags -ccontains $argument) { continue }
        $parts = $argument.Split('=', 2)
        if ($parts.Count -ne 2 -or @($values.Keys) -cnotcontains $parts[0] -or -not $parts[1]) { return }
    }
    $candidates = @($flags)
    foreach ($option in $values.Keys) {
        if ($values[$option].Count) {
            foreach ($value in $values[$option]) { $candidates += "$option=$value" }
        }
        else { $candidates += "$option=" }
    }
    New-PS7CompletionResult -Candidate $candidates -WordToComplete $Context.WordToComplete -ResultType ParameterName
}
