{
    param($Context)
    New-PS7StaticCompletion -Candidates @('query', 'queryex', 'start', 'stop', 'qc', 'config', 'create', 'delete', 'description') -WordToComplete $Context.WordToComplete
}
