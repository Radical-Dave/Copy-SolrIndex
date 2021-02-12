
<#PSScriptInfo

<<<<<<< HEAD
.VERSION 1.1
=======
.VERSION 1.0
>>>>>>> 96fd913a11a628e1b3fbba43acf6be8df23844c6

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
	# name of new index
	[Parameter(Mandatory = $false, position=0)] [string]$name,
	# name of schema to copy [default: sitecore_master_index]
	[Parameter(Mandatory = $false, position=1)] [string]$schema = "sitecore_master_index",
	# solr path - use this with PersistForCurrentUser and run from anywhere, otherwise working directory must be SOLR
	[Parameter(Mandatory = $false)] [string]$solr,
	# Save solr path to env var for user
	[Parameter(Mandatory = $false)] [switch]$PersistForCurrentUser,
	# force - overwrite if index already exists
	[Parameter(Mandatory = $false)] [switch]$Force
)
begin {
	$ErrorActionPreference = 'Stop'
	$VerbosePreference = "Continue"
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose "$PSScriptName $name $schema called by:$PSCallingScript"

	if (!$solr) { #todo:some other normal/default SOLR Env path to check first?
		$solr = [Environment]::GetEnvironmentVariable("SOLR_INDEXES", "User")
		if (!$solr) {
			Write-Verbose "solr path has NOT been persisted using -PersistForCurrentUser"
			$solr = Get-Location
		} else {
			Write-Verbose "solr path was persisted using -PersistForCurrentUser!"
		}
	}

	if (!(Test-Path (Join-Path $solr $schema))) {
		Write-Error "ERROR schema not found:$schema USE -solr and -PersistForCurrentUser to set SOLR path"
		EXIT 1
	}

	if ($PersistForCurrentUser) {
		[Environment]::SetEnvironmentVariable("SOLR_INDEXES", $solr, "User")
		if (!$name) {
			Write-Output "PersistForCurrentUser - saved solr:$solr"
			Exit 0
		}
	}
	
	if (!$name) {$name = "$($PSScriptName.Replace("-","_"))_index"}
	$name = $name.ToLower()

	$dest = Join-Path $solr $name
	$path = "$solr\$schema\*"
}
process {	
	Write-Verbose "$PSScriptName $name $schema start"
	Write-Verbose "path:$path"
	Write-Verbose "dest:$dest"

	if (Test-Path $path) {
		if($PSCmdlet.ShouldProcess($path)) {

			if (Test-Path $dest) {
				if (!$Force) {
					Write-Error "ERROR $dest already exists"
					EXIT 1
				} else {
					Write-Verbose "$dest already exists removing."
					Remove-Item $dest -Recurse -Force
				}
			}

			if (!(Test-Path $dest)) {
				Write-Verbose "Creating destination: $dest"
				New-Item -Path $dest -ItemType Directory
			}

			Write-Verbose "Copying schema: $schema"
			Copy-Item -Path $path -Destination $dest -PassThru

			$propPath = "$dest\core.properties"
			if (Test-Path $propPath) {
				Write-Verbose "Setting index name property: $propPath"
				(Get-Content $propPath).Replace($schema, $name) | Out-File $propPath
			} else {
				Write-Error "$propPath not found."
			}				
		}
	}
	Write-Verbose "$PSScriptName $name $schema end"
	return $dest
}