{
    param($Context)
    $syntax = New-PS7SyntaxNode '--help -h --version -V --verbose -v --test -g -O' '--edition --crate-type --crate-name --emit --target --out-dir --extern --cfg --print --error-format -o -L -C -A -W -D -F' -Values @{ '--edition'=@('2015','2018','2021','2024'); '--crate-type'=@('bin','lib','rlib','dylib','cdylib','staticlib','proc-macro'); '--error-format'=@('human','json','short') }
    Invoke-PS7SyntaxCompletion -Context $Context -Syntax $syntax
}
