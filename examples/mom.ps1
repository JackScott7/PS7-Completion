# Register with -Name mom -CommandName mom.py -Path <this file>.
{
    param($Context)
    if ($Context.ArgumentIndex -eq 0) {
        New-PS7CompletionResult -Candidate add,update,read,delete,search,mark,list -WordToComplete $Context.WordToComplete -ResultType Command
        New-PS7CompletionResult -Candidate '--help','--install-completion','--show-completion' -WordToComplete $Context.WordToComplete -ResultType ParameterName
    }
}
