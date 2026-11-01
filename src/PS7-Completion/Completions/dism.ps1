{
    param($Context)
    $syntax = New-PS7SyntaxNode '/? /Online /English /Quiet /NoRestart /Get-Help /Get-Features /Get-FeatureInfo /Enable-Feature /Disable-Feature /Get-Packages /Get-PackageInfo /Add-Package /Remove-Package /Cleanup-Image /CheckHealth /ScanHealth /RestoreHealth /StartComponentCleanup /LimitAccess' '/Image /LogPath /LogLevel /Source'
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
