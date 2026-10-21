{
    param($Context)
    New-PS7StaticCompletion -Candidates @('/PID', '/IM', '/FI', '/F', '/T', '/?') -WordToComplete $Context.WordToComplete
}
