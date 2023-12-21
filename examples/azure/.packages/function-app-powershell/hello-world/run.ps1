param($req, $TriggerMetadata)

$name = $req.Query.Name

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
  StatusCode = [System.Net.HttpStatusCode]::OK
  Body = "Hello $name from Powershell!"
})
