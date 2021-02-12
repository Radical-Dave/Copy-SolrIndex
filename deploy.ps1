$path = ".\Copy-SolrIndex.ps1"
$results = Test-ScriptFileInfo -Path $path
Write-Output "results:$results"
if ($results) {
	$nugetKey = "oy2pbzgb2ajo2j23apvqijtyg6kzukyeve4dumkhs7gyiy"
	Publish-Script -Path $path -NuGetApiKey $nugetKey
}