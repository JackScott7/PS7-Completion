{
    param($Context)
    New-PS7StaticCompletion -Candidates @('-4', '-6', '-A', '-F', '-i', '-J', '-L', '-p', '-R', '-v') -WordToComplete $Context.WordToComplete
}
