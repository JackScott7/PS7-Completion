{
    param($Context)
    $syntax = New-PS7SyntaxNode '--version -V --verbose -v --silent -s --show-error -S --location -L --head -I --include -i --fail -f --fail-with-body --insecure -k --compressed --remote-name -O --create-dirs --ipv4 -4 --ipv6 -6 --http1.1 --http2 --get -G --no-progress-meter' '--help -h --url --request -X --header -H --data -d --data-raw --data-binary --data-urlencode --json --form -F --output -o --user -u --user-agent -A --proxy -x --proxy-user -U --connect-timeout --max-time -m --retry --retry-delay --cacert --cert --key --cookie -b --cookie-jar -c --config -K --upload-file -T --write-out -w' -Values @{
        '--request' = @('GET','POST','PUT','PATCH','DELETE','HEAD','OPTIONS')
        '-X' = @('GET','POST','PUT','PATCH','DELETE','HEAD','OPTIONS')
        '--help' = @('all','http','connection','output','upload','auth','proxy','tls')
        '-h' = @('all','http','connection','output','upload','auth','proxy','tls')
    }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
