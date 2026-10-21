{
    param($Context)
    New-PS7StaticCompletion -Candidates @('install', 'show', 'source', 'search', 'list', 'upgrade', 'uninstall', 'export', 'import', '--help', '--version') -WordToComplete $Context.WordToComplete
}
