# Failsafe
return

#------------------------------------------------------------------------------#
#                   Did you know, users hate having to wait?                   #
#------------------------------------------------------------------------------#

# Tab Completion
#-----------------

#-> Step 1: Calculate values
Register-PSFTeppScriptblock -Name "mymodule.alcohol" -ScriptBlock {
	Start-Sleep -Seconds 2
    @{ Text = 'Beer'; ToolTip = 'Elixir of the gods'}
    @{ Text = 'Mead'; ToolTip = 'Elixir of the angry gods' }
    @{ Text = 'Whiskey'; ToolTip = 'Unleash the Irishman in you!' }
    @{ Text = 'Wine'; ToolTip = 'For the discriminating somelier' }
    @{ Text = 'Vodka'; ToolTip = 'Melancholy as national culture' }
    @{ Text = 'Rum (3y)'; ToolTip = 'Barkeepers Delight' }
    @{ Text = 'Rum (5y)'; ToolTip = 'Barkeepers Delight' }
    @{ Text = 'Rum (7y)'; ToolTip = 'Barkeepers Delight' }
}

#-> Step 2: Assign to Command
function Get-Alcohol {
    [CmdletBinding()]
    param (
        [PsfArgumentCompleter('mymodule.alcohol')]
        [string]
        $Type,

		[string]
		$Size = 'Mug'
    )

	Write-PSFMessage -Level Host -Message 'Drinking a {0} of {1}' -StringValues $Size, $Type
}

#-> Step 2 (Alternative): Assign to Command without touching the code
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name "mymodule.alcohol"

# Tab Completion _With Caching_
Register-PSFTeppScriptblock -Name "mymodule.alcohol" -ScriptBlock {
	Start-Sleep -Seconds 2
    @{ Text = 'Beer'; ToolTip = 'Elixir of the gods'}
    @{ Text = 'Mead'; ToolTip = 'Elixir of the angry gods' }
    @{ Text = 'Whiskey'; ToolTip = 'Unleash the Irishman in you!' }
    @{ Text = 'Wine'; ToolTip = 'For the discriminating somelier' }
    @{ Text = 'Vodka'; ToolTip = 'Melancholy as national culture' }
    @{ Text = 'Rum (3y)'; ToolTip = 'Barkeepers Delight' }
    @{ Text = 'Rum (5y)'; ToolTip = 'Barkeepers Delight' }
    @{ Text = 'Rum (7y)'; ToolTip = 'Barkeepers Delight' }
} -CacheDuration 8h


# Trainable Completions
#------------------------

Register-PSFTeppScriptblock -Name "alcohol.type" -ScriptBlock {
	Start-Sleep -Seconds 2
    @{ Text = 'Beer'; ToolTip = 'Elixir of the gods'}
    @{ Text = 'Mead'; ToolTip = 'Elixir of the angry gods' }
    @{ Text = 'Whiskey'; ToolTip = 'Unleash the Irishman in you!' }
    @{ Text = 'Wine'; ToolTip = 'For the discriminating somelier' }
    @{ Text = 'Vodka'; ToolTip = 'Beware, before it is too late' }
    @{ Text = 'Rum (3y)'; ToolTip = 'Barkeepers Delight' }
    @{ Text = 'Rum (5y)'; ToolTip = 'Well aged, combines well' }
    @{ Text = 'Rum (7y)'; ToolTip = 'Oldtimer, use for cocktails that need some character' }
} -AutoTraining -CacheDuration 8h

function Get-Alcohol {
    [CmdletBinding()]
    Param (
        [PsfArgumentCompleter('alcohol.type')]
        [string]
        $Type,

        [string]
        $Unit = "Pitcher"
    )
    if ($Type -eq 'Kölsch') { throw "Would go bad before serving!" }
    Update-PSFTeppCompletion

    Write-Host "Drinking a $Unit of $Type"
}

#-> Next: Writing Things Down
code "$presentationRoot\C-01-Disk.ps1"