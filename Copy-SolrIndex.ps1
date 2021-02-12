
<#PSScriptInfo

.VERSION 1.0

.GUID 512fb058-2d8a-4e12-9fee-3f14f7d4ee46

.AUTHOR RadicalDave

.COMPANYNAME RadicalDave

.COPYRIGHT RadicalDave

.TAGS powershell file io solr sitecore

.LICENSEURI https://github.com/Radical-Dave/Copy-SolrIndex/blob/main/LICENSE

.PROJECTURI https://github.com/Radical-Dave/Copy-SolrIndex

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Copy Solr Index by schema [default: sitecore-Master_index]

#> 
#####################################################
#  Copy-SolrIndex
#####################################################
[CmdletBinding(SupportsShouldProcess)]
Param(
	[parameter(position=0)] [string]$name,
	[parameter(position=1)] [string]$schema = "sitecore_master_index",
	[parameter(position=2)]	[switch]$Force
)
begin {
	$ErrorActionPreference = 'Stop'
	$VerbosePreference = "Continue"
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose "$PSScriptName $name $schema called by:$PSCallingScript"

	if (!$name) {$name = "$($PSScriptName.Replace("-","_"))_index"}
	$name = $name.ToLower()

	$solr = Get-Location
	if (!(Test-Path $schema)) {
		#todo:idea/maybe use SOLR Env path to check first?
		$solr = "c:\solr\8.1.1\server\solr"
		if (!(Test-Path (Join-Path $solr $schema))) {
			$solr = "D:\repos\docker-images\build\windows\tests\9.3.x\data\solr"
			if (!(Test-Path (Join-Path $solr $schema))) {
				Write-Error "ERROR schema not found:$schema"
				EXIT 1
			}
		}
	}
	$dest = Join-Path $solr $name
	$path = "$solr\$schema\*"
}
process {	
	Write-Verbose "$PSScriptName $name $schema processing"		
	Write-Verbose "path:$path"
	Write-Verbose "dest:$dest"

	if (Test-Path $path) {
		if($PSCmdlet.ShouldProcess($path)) {

			if (Test-Path $dest) {
				if (!$Force) {
					Write-Error "ERROR $dest already exists"
					EXIT 1
				} else {
					Write-Verbose "$dest already exists removing..."
					Remove-Item $dest -Recurse -Force
				}
			}

			if (!(Test-Path $dest)) {
				New-Item -Path $dest -ItemType Directory
			}

			Copy-Item -Path $path -Destination $dest -PassThru

			$propPath = "$dest\core.properties"
			if (Test-Path $propPath) {
				(Get-Content $propPath).Replace($schema, $name) | Out-File $propPath
			} else {
				Write-Error "$propPath not found."
			}				
		}
	}
	return $dest
}