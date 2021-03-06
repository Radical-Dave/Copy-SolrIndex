#Set-StrictMode -Version Latest
#####################################################
# Copy-SolrIndex
#####################################################
<#PSScriptInfo

.VERSION 1.6

.GUID 512fb058-2d8a-4e12-9fee-3f14f7d4ee46

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

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

.PARAMETER name
Name of new index [Default: copy_solrindex_index for testing] (if no solr path provided and not current working directory must be full path)

.PARAMETER schema
Name of schema to copy [default: sitecore_master_index]

.PARAMETER solr
Solr path - use this with PersistForCurrentUser and run from anywhere, otherwise working directory must be SOLR

.PARAMETER PersistForCurrentUser
Save solr path to env var for user

.PARAMETER Force
Force - overwrite if index already exists

.EXAMPLE
PS> .\Copy-SolrIndex 'new_index'

.EXAMPLE
PS> .\Copy-SolrIndex 'new_index' -solr 'c:\solr\8.1.1\solr\server' -PersistForCurrentUser

.EXAMPLE
PS> .\Copy-SolrIndex 'new_index' 'sitecore_web_index'

#> 
#####################################################
# Copy-SolrIndex
#####################################################
[CmdletBinding(SupportsShouldProcess)]
Param(
	# Name of new index
	[Parameter(Mandatory = $false, position=0)] [string]$name,
	# Name of schema to copy [default: sitecore_master_index]
	[Parameter(Mandatory = $false, position=1)] [string]$schema = "sitecore_master_index",
	# Solr path - use this with PersistForCurrentUser and run from anywhere, otherwise working directory must be SOLR
	[Parameter(Mandatory = $false)] [string]$solr,
	# Save solr path to env var for user
	[Parameter(Mandatory = $false)] [switch]$PersistForCurrentUser,
	# Force - overwrite if index already exists
	[Parameter(Mandatory = $false)] [switch]$Force
)
begin {
	$ErrorActionPreference = 'Stop'
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
					Write-Error "ERROR $dest already exists. Use -Force to overwrite."
					EXIT 1
				} else {
					Write-Verbose "$dest already exist. -Force used - removing."
					Remove-Item $dest -Recurse -Force | Out-Null
				}
			}

			if (!(Test-Path $dest)) {
				Write-Verbose "Creating destination: $dest"
				New-Item -Path $dest -ItemType Directory | Out-Null
			}

			Write-Verbose "Copying schema: $schema"
			Copy-Item -Path $path -Destination $dest -PassThru | Out-Null

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