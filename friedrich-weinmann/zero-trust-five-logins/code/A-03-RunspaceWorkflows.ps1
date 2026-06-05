# Failsafe
return

#----------------------------------------------------------------------------#
#                             Don't wait for me!                             #
#----------------------------------------------------------------------------#

# Module: PSFramework
# https://psframework.org

# Runspace Workflows
#---------------------

# Create Workflow
$workflow = New-PSFRunspaceWorkflow -Name 'Tests'

# Add Worker
$workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 5 -ScriptBlock {
	$start = Get-Date
	Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
    [PSCustomObject]@{
        Test = $_
        Start = $start
        End = Get-Date
		Duration = (Get-Date) - $start
    }
} -CloseOutQueue

# Add input
$tests = '21770','21771','21772','21773','21774','21775','21776','21777','21778','21779','21780','21781','21782','21783','21784','21786','21787','21788','21789','21790','21791','21792','21793','21795','21796','21797','21798','21799','21800','21801','21802','21803','21804','21806','21807','21808','21809','21810','21811','21812','21813','21814','21815','21816','21817','21818','21819','21820','21821','21822','21823','21824','21825','21828','21829','21830','21831','21832','21833','21834','21835','21836','21837','21838','21839','21840','21841','21842','21843','21844','21845','21846','21847','21848','21849','21850','21851','21854','21855','21857','21858','21859','21860','21861','21862','21863','21864','21865','21866','21867','21868','21869','21870','21872','21874','21875','21876','21877','21878','21879','21881','21882','21883','21884','21885','21886','21887','21888','21889','21890','21891','21892','21893','21894','21895','21896','21897','21898','21899','21912','21929','21941','21953','21954','21955','21964','21983','21984','21985','21992','22072','22124','22128','22659','23183','24518','24540','24541','24542','24543','24545','24546','24547','24548','24549','24550','24551','24552','24553','24554','24555','24560','24561','24564','24568','24569','24570','24572','24573','24574','24575','24576','24690','24784','24794','24802','24823','24824','24827','24839','24840','24870','24871','25370','25371','25372','25375','25376','25377','25379','25380','25381','25382','25383','25384','25391','25392','25393','25394','25395','25396','25398','25399','25400','25401','25403','25405','25406','25407','25408','25409','25410','25411','25413','25415','25416','25419','25420','25422','25466','25480','25481','25533','25535','25537','25539','25541','25543','25550','26879','26880','26881','26882','26883','26884','26885','26886','26887','26888','26889','27000','27001','27002','27003','27004','27015','27016','27017','27018','27019','27020','35001','35003','35004','35005','35006','35007','35008','35009','35010','35011','35012','35013','35014','35015','35016','35017','35018','35019','35020','35021','35022','35023','35024','35025','35026','35027','35028','35029','35030','35032','35033','35034','35035','35036','35037','35038','35039','35040','35041','50001'
$workflow | Write-PSFRunspaceQueue -Name Input -BulkValues $tests -Close

# Start Workflow
$workflow | Start-PSFRunspaceWorkflow

# Wait for Workflow to complete and stop it
$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru | Stop-PSFRunspaceWorkflow

# Retrieve results
$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
$results

# Final Cleanup
$workflow | Remove-PSFRunspaceWorkflow


# Adding Progress
#------------------
# Create Workflow
$workflow = New-PSFRunspaceWorkflow -Name 'Tests2'

# Add Worker
$workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 5 -ScriptBlock {
	$__PSF_Workflow.Data[$_] = $true
	$start = Get-Date
	Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
    [PSCustomObject]@{
        Test = $_
        Start = $start
        End = Get-Date
		Duration = (Get-Date) - $start
    }
	$null = $__PSF_Workflow.Data.TryRemove($_, [ref]$null)
} -CloseOutQueue

# Add input
$tests = '21770','21771','21772','21773','21774','21775','21776','21777','21778','21779','21780','21781','21782','21783','21784','21786','21787','21788','21789','21790','21791','21792','21793','21795','21796','21797','21798','21799','21800','21801','21802','21803','21804','21806','21807','21808','21809','21810','21811','21812','21813','21814','21815','21816','21817','21818','21819','21820','21821','21822','21823','21824','21825','21828','21829','21830','21831','21832','21833','21834','21835','21836','21837','21838','21839','21840','21841','21842','21843','21844','21845','21846','21847','21848','21849','21850','21851','21854','21855','21857','21858','21859','21860','21861','21862','21863','21864','21865','21866','21867','21868','21869','21870','21872','21874','21875','21876','21877','21878','21879','21881','21882','21883','21884','21885','21886','21887','21888','21889','21890','21891','21892','21893','21894','21895','21896','21897','21898','21899','21912','21929','21941','21953','21954','21955','21964','21983','21984','21985','21992','22072','22124','22128','22659','23183','24518','24540','24541','24542','24543','24545','24546','24547','24548','24549','24550','24551','24552','24553','24554','24555','24560','24561','24564','24568','24569','24570','24572','24573','24574','24575','24576','24690','24784','24794','24802','24823','24824','24827','24839','24840','24870','24871','25370','25371','25372','25375','25376','25377','25379','25380','25381','25382','25383','25384','25391','25392','25393','25394','25395','25396','25398','25399','25400','25401','25403','25405','25406','25407','25408','25409','25410','25411','25413','25415','25416','25419','25420','25422','25466','25480','25481','25533','25535','25537','25539','25541','25543','25550','26879','26880','26881','26882','26883','26884','26885','26886','26887','26888','26889','27000','27001','27002','27003','27004','27015','27016','27017','27018','27019','27020','35001','35003','35004','35005','35006','35007','35008','35009','35010','35011','35012','35013','35014','35015','35016','35017','35018','35019','35020','35021','35022','35023','35024','35025','35026','35027','35028','35029','35030','35032','35033','35034','35035','35036','35037','35038','35039','35040','35041','50001'
$workflow | Write-PSFRunspaceQueue -Name Input -BulkValues $tests -Close

# Start Workflow
$workflow | Start-PSFRunspaceWorkflow

# Wait for Workflow to complete and stop it
Write-Progress -Activity "Processing Tests" -PercentComplete 0 -Id 1
while (-not $workflow.Queues.Done.Closed) {
	$percent = $workflow.Queues.Done.Count / $workflow.Queues.Input.TotalItemCount * 100
	Write-Progress -Id 1 -Activity "Processing Tests" -Status "$($workflow.Queues.Done.Count) / $($workflow.Queues.Input.TotalItemCount) | Current: $($workflow.Data.Keys -join ', ')" -PercentComplete $percent
	Start-Sleep -Milliseconds 100
}
Write-Progress -Activity "Processing Tests" -Completed -Id 1
$workflow | Stop-PSFRunspaceWorkflow

# Retrieve results
$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
$results

# Final Cleanup
$workflow | Remove-PSFRunspaceWorkflow

<#
Docs: https://psframework.org/docs/PSFramework/RunspaceWorkflows/overview
Talk: https://www.youtube.com/watch?v=rspi8necNy0
#>

# While we are talking about Runspaces ...
#--------------------------------------------

1..50 | ForEach-Object -Parallel {
	Start-Sleep -Milliseconds (Get-Random -Minimum 20 -Maximum 80)
	$_ | Add-Content -Path C:\Temp\Demo\test.txt -ErrorAction Stop
}
Get-Content C:\Temp\Demo\test.txt | Measure-Object
Remove-Item C:\Temp\Demo\test.txt

1..50 | ForEach-Object -Parallel {
	$lock = Get-PSFRunspaceLock -Name Demo
	Start-Sleep -Milliseconds (Get-Random -Minimum 20 -Maximum 80)
	$lock.Open()
	$_ | Add-Content -Path C:\Temp\Demo\test.txt -ErrorAction Stop
	$lock.Close()
}
Get-Content C:\Temp\Demo\test.txt | Measure-Object

#-> Next: Evidence Collection
code "$presentationRoot\A-04-Logging.ps1"