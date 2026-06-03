# APIs come in different flavours depending on how we create them in the GUI. Either with a file or not. Files are good. Use those.
# Remeber when creating a file the path is relative to the endpoints.ps1 file...
http://localhost:5000/admin/apis/endpoints


# GET
##
Write-Output "Hello world!"

##

if ($greeting) {
    Write-Output "Hello $greeting!"
}
else {
    Write-Output "Hello World!"
}



# POST
code 'C:\ProgramData\UniversalAutomation\Repository\.universal\Demo3Post.ps1'

irm http://localhost:5000/Demo3Post -Method Post -Body (@{Name = 'Björn' } | ConvertTo-Json) -ContentType 'Application/json'

# Parameters also autoparses using querystring
irm http://localhost:5000/Demo3Post?Name=Björn -Method Get