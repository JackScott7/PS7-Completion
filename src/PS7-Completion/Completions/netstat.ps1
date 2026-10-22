{
    param($Context)
    $protocols = @('TCP','UDP','TCPv6','UDPv6')
    if (@($Context.PreviousArguments) -ccontains '-s') { $protocols += @('IP','IPv6','ICMP','ICMPv6') }
    $syntax = New-PS7SyntaxNode '-a -b -c -d -e -f -i -n -o -q -r -s -t -x -y /?' '-p' -Values @{ '-p' = $protocols } -StopAtPositional
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
