{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help --version --reload --factory --access-log --no-access-log --use-colors --no-use-colors --proxy-headers --no-proxy-headers --server-header --no-server-header --date-header --no-date-header' '--host --port --uds --fd --reload-dir --reload-include --reload-exclude --reload-delay --workers --loop --http --ws --lifespan --interface --env-file --log-config --log-level --forwarded-allow-ips --root-path --limit-concurrency --backlog --limit-max-requests --timeout-keep-alive --timeout-graceful-shutdown --ssl-keyfile --ssl-certfile --ssl-keyfile-password --ssl-ca-certs --ssl-ciphers --header --app-dir' -Values @{
        '--loop' = @('auto', 'asyncio', 'uvloop')
        '--http' = @('auto', 'h11', 'httptools')
        '--ws' = @('auto', 'websockets', 'websockets-sansio', 'wsproto')
        '--lifespan' = @('auto', 'on', 'off')
        '--interface' = @('auto', 'asgi3', 'asgi2', 'wsgi')
        '--log-level' = @('critical', 'error', 'warning', 'info', 'debug', 'trace')
    }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
