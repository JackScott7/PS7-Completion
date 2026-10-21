BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/PS7-Completion/PS7-Completion.psd1') -Force
}
Describe 'Developer tool provider integration' {
    It 'completes <Line>' -ForEach @(
        @{ Line='git sta'; Expected='status' }
        @{ Line='git -C repo status --s'; Expected='--short' }
        @{ Line='gh pr list --st'; Expected='--state' }
        @{ Line='gh pr list --state m'; Expected='merged' }
        @{ Line='rg --col'; Expected='--color' }
        @{ Line='rg --color a'; Expected='always' }
        @{ Line='jq --arg name value --r'; Expected='--raw-output' }
        @{ Line='jq -R --s'; Expected='--slurp' }
        @{ Line='python -m p'; Expected='pip' }
        @{ Line='python -I -m pip ins'; Expected='install' }
        @{ Line='pip install --req'; Expected='--requirement' }
        @{ Line='uv pip ins'; Expected='install' }
        @{ Line='uv tool r'; Expected='run' }
        @{ Line='flask --app app run --p'; Expected='--port' }
        @{ Line='fastapi dev --p'; Expected='--port' }
        @{ Line='tailscale status --j'; Expected='--json' }
        @{ Line='node --input-type m'; Expected='module' }
        @{ Line='npm install --save-d'; Expected='--save-dev' }
        @{ Line='npm.cmd install --save-d'; Expected='--save-dev' }
        @{ Line='npm.ps1 install --save-d'; Expected='--save-dev' }
        @{ Line='sqlite3 -j'; Expected='-json' }
        @{ Line='ffmpeg -loglevel w'; Expected='warning' }
        @{ Line='rustc --edition 202'; Expected='2024' }
        @{ Line='rustup toolchain i'; Expected='install' }
        @{ Line='nano --line'; Expected='--linenumbers' }
        @{ Line='ping -'; Expected='-n' }
        @{ Line='ping.exe -R -'; Expected='-S' }
        @{ Line='ping -n 3 localhost -'; Expected='-w' }
        @{ Line='uvx --fr'; Expected='--from' }
        @{ Line='uvx.exe --from ruff --col'; Expected='--color' }
        @{ Line='uvx --color a'; Expected='auto' }
        @{ Line='uvicorn main:app --po'; Expected='--port' }
        @{ Line='uvicorn.exe --log-level d'; Expected='debug' }
        @{ Line='twine ch'; Expected='check' }
        @{ Line='twine.exe upload --rep'; Expected='--repository' }
        @{ Line='twine check dist/pkg.whl --st'; Expected='--strict' }
        @{ Line='ruff ch'; Expected='check' }
        @{ Line='ruff.exe check --output-format j'; Expected='json' }
        @{ Line='ruff format --target-version py31'; Expected='py314' }
        @{ Line='ruff --config ruff.toml check --fix --col'; Expected='--color' }
    ) {
        $result = [Management.Automation.CommandCompletion]::CompleteInput($Line, $Line.Length, $null)
        $result.CompletionMatches.CompletionText | Should -Contain $Expected
        @(Get-PS7CompletionProvider | Where-Object Status -EQ Failed).Count | Should -Be 0
    }
    InModuleScope PS7-Completion {
        It 'suppresses provider suggestions for <Line>' -ForEach @(
            @{ Name='git'; Line='git --unknown ' }
            @{ Name='git'; Line='git -- ' }
            @{ Name='git'; Line='git -C ' }
            @{ Name='git'; Line='git commit -m ' }
            @{ Name='git'; Line='git status --depth ' }
            @{ Name='gh'; Line='gh pr list --limit ' }
            @{ Name='ripgrep'; Line='rg -g ' }
            @{ Name='ripgrep'; Line='rg -f ' }
            @{ Name='jq'; Line='jq --arg ' }
            @{ Name='jq'; Line='jq --arg name ' }
            @{ Name='jq'; Line='jq -r --unknown ' }
            @{ Name='python'; Line='python app.py -m pip ' }
            @{ Name='python'; Line='python -c code -m pip ' }
            @{ Name='python'; Line='python -m unknown ' }
            @{ Name='python'; Line='python -W -m pip ' }
            @{ Name='pip'; Line='pip install -r ' }
            @{ Name='uv'; Line='uv add --optional ' }
            @{ Name='uv'; Line='uv run python ' }
            @{ Name='flask'; Line='flask --app ' }
            @{ Name='fastapi'; Line='fastapi run --port ' }
            @{ Name='tailscale'; Line='tailscale up --hostname ' }
            @{ Name='node'; Line='node app.js ' }
            @{ Name='node'; Line='node -e code ' }
            @{ Name='node'; Line='node --eval=code ' }
            @{ Name='npm'; Line='npm run build ' }
            @{ Name='npm'; Line='npm exec -- tool ' }
            @{ Name='sqlite3'; Line='sqlite3 db.sqlite ' }
            @{ Name='ffmpeg'; Line='ffmpeg -i ' }
            @{ Name='rustc'; Line='rustc -o ' }
            @{ Name='rustup'; Line='rustup run stable rustc ' }
            @{ Name='nano'; Line='nano --syntax ' }
            @{ Name='ping'; Line='ping -n ' }
            @{ Name='ping'; Line='ping -r ' }
            @{ Name='ping'; Line='ping -S ' }
            @{ Name='ping'; Line='ping --linux-only ' }
            @{ Name='uvx'; Line='uvx --from ' }
            @{ Name='uvx'; Line='uvx ruff ' }
            @{ Name='uvx'; Line='uvx --from ruff ruff check ' }
            @{ Name='uvicorn'; Line='uvicorn main:app --port ' }
            @{ Name='uvicorn'; Line='uvicorn --app-dir ' }
            @{ Name='twine'; Line='twine upload --password ' }
            @{ Name='twine'; Line='twine check --repository ' }
            @{ Name='ruff'; Line='ruff check --select ' }
            @{ Name='ruff'; Line='ruff format --fix ' }
            @{ Name='ruff'; Line='ruff check --config ' }
        ) {
            $tokens = $null; $errors = $null
            $ast = [Management.Automation.Language.Parser]::ParseInput($Line, [ref]$tokens, [ref]$errors)
            $command = $ast.Find({ param($node) $node -is [Management.Automation.Language.CommandAst] }, $true)
            @(Invoke-PS7Provider -Name $Name -WordToComplete '' -CommandAst $command -CursorPosition $Line.Length).Count | Should -Be 0
            $script:Registry[$Name].Status | Should -Be 'Loaded'
        }
        It 'distinguishes case-sensitive native options' {
            $provider = & (Join-Path $script:ModuleRoot 'Completions/ripgrep.ps1')
            @(& $provider ([pscustomobject]@{ PreviousArguments=@('-F'); WordToComplete='--color' })).CompletionText | Should -Contain '--color'
            @(& $provider ([pscustomobject]@{ PreviousArguments=@('-f'); WordToComplete='--color' })).Count | Should -Be 0
        }
    }
}
