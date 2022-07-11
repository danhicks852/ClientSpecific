# https://github.com/PowerShell/PSScriptAnalyzer/tree/master/docs/Rules
@{
    ExcludeRules = @('PSAvoidUsingInvokeExpression', 'PSUseShouldProcessForStateChangingFunctions')
    Rules = @{
        PSAvoidLongLines = @{
            Enable = $false
            MaximumLineLength = 120
        }
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace = @{
            Enable = $true
            NoEmptyLineBefore = $false
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
        }
        PSProvideCommentHelp = @{
            Enable = $false
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $false
            Placement = 'before'
        }
        PSUseCorrectCasing = @{
            Enable = $true
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $false
            IgnoreAssignmentOperatorInsideHashTable = $false
        }
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
    }
}