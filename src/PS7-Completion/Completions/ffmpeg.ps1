{
    param($Context)
    $syntax = New-PS7SyntaxNode '-help -h -version -hide_banner -y -n -nostdin -vn -an -sn -dn -stats -nostats' '-i -f -c -c:v -c:a -codec -b:v -b:a -r -s -vf -af -filter_complex -map -ss -t -to -crf -preset -loglevel -threads -pix_fmt' -Values @{ '-loglevel'=@('quiet','panic','fatal','error','warning','info','verbose','debug','trace') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
