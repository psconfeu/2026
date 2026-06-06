#requires -version 5.1

#Show module information including module-scoped variables and internal functions.
#If testing modules not in the default module path, you will need to manually import them first.
Function Show-Module {
    [cmdletbinding()]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Specify the name of a module. It will be imported if not already loaded.'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string]$ModuleName,
        [Parameter(HelpMessage = 'Specify if you want to display only the variables.')]
        [switch]$VariableOnly
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing module $ModuleName"

        #Import the module if not already loaded
        If (-Not (Get-Module -Name $ModuleName)) {
            Try {
                Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Importing module $ModuleName"
                Import-Module $ModuleName -ErrorAction Stop
            }
            Catch {
                Write-Warning "Unable to import module $ModuleName. $($_.Exception.Message)"
                #bail out
                Return
            }
        }

        $thisModule = Get-Module -Name $ModuleName
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting publicly exported functions and cmdlets"
        [array]$PublicExported = ($thisModule.ExportedFunctions).Keys
        $PublicExported += ($thisModule.ExportedCmdlets).Keys

        $cmd = "Get-Command -module $ModuleName -All"
        $sb = [scriptblock]::Create($cmd)

        #define a scriptblock to get the internal function information
        $internalCmd = @"
`$exported = (Get-Module $ModuleName).ExportedFunctions.keys
Get-Command -Module $ModuleName -CommandType Function | Where-Object { `$_.Name -NotIn `$exported }
"@
        $internalSB = [scriptblock]::Create($internalCmd)

        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting internal module information"
        #This is the magic part
        $cmds = &(Get-Module -Name $ModuleName) $sb

        Write-Information $cmds -tag cmds

        #create a custom object
        #TODO: Detect private classes ?
        $info = [PSCustomObject]@{
            PSTypeName        = 'PSModuleInfo'
            Module            = $ModuleName
            Version           = $cmds[0].Version
            ModulePath        = $thisModule.Path
            Aliases           = $cmds.Where({ $_.CommandType -eq 'Alias' }) | Sort-Object -Property Name
            AllCommands       = $cmds.Where({ $_.CommandType -match 'Function|Cmdlet' }) | Sort-Object -Property Name
            PublicCommands    = $PublicExported
            InternalFunctions = &(Get-Module $ModuleName) $internalSB
            Variables         = &(Get-Module $ModuleName) { Get-Variable -Scope script | Where-Object { $_.Name -NotMatch 'null|true|false' } }
        }
        if ($VariableOnly) {
            $info.Variables
        }
        else {
            $info
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Show-Module
