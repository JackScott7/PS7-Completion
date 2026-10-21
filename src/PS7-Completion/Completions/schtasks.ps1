{
    param($Context)
    New-PS7StaticCompletion -Candidates @('/Create', '/Delete', '/Query', '/Change', '/Run', '/End', '/ShowSid', '/?') -WordToComplete $Context.WordToComplete
}
