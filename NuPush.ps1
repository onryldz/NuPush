#
# Nuget Package Push Manager (cli)
# The MIT License (MIT)
# Copyright (c) 2021 Onur YILDIZ
#

param(
  [string]$apiKey="",
  [string]$install=""
)

function getVersion
{
  Param([string]$Project)
  $Project = Resolve-Path -Path $Project
  [Xml]$xml = Get-Content $Project
  $propertyGroup = $xml.Project.PropertyGroup
  if ($propertyGroup -is [array]) {
    $version = [version] $xml.Project.PropertyGroup[0].Version
    return [string]$version
  }else {
    $version = [version] $xml.Project.PropertyGroup.Version
    return [string]$version
  }
}

function build
{
    Param([PSObject]$project)
    dotnet build $project.File --configuration Release
}

function pack
{
    Param([PSObject]$project)
    $replaced = $project.Project.Replace('.', '\.')

    $regex_snupkg = "$replaced\.(\d+\.\d+\.\d+(\.\d+)?)\.snupkg"
    $regex_nupkg = "$replaced\.(\d+\.\d+\.\d+(\.\d+)?)\.nupkg"
    $regex_all = "$replaced\.(\d+\.\d+\.\d+(\.\d+)?)\.(s)?nupkg"

    if(Test-Path -Path nupkgs) {
       Get-ChildItem nupkgs | Where{$_.Name -Match $regex_all} | Remove-Item;
    }

    $result = dotnet pack $project.File --output nupkgs --include-symbols --configuration Release -p:SymbolPackageFormat=snupkg
    if($LASTEXITCODE -ne 0) {
        return [PSCustomObject]@{
           success = $false
           output = $result
       }
    }

    Write-Host $result
    return [PSCustomObject]@{
        success = $true
        primaryPack = [regex]::Match($result, $regex_nupkg).captures.groups[0].value
        pack = [regex]::Match($result, $regex_snupkg).captures.groups[0].value
        output = $result
    }
}

function getNugetSources {
	$sourceList = nuget sources
	$lines = $sourceList -split "`n"
	$sources = @();
	$id = 0

	foreach($line in $lines) {
		if($line -match "(?i).+[0-9]+\. +(.+) \[Enabled]") {
		   $source =  New-Object PSObject -Property @{
			  Id = ++$id
			  Name = $Matches.1
		   };
		   $sources += $source
		}
	}
	return $sources
}

function push {
    Param([PSCustomObject]$package)

	Write-Host "`nNuget Sources:"
	$nugetSources | Format-Table -Property Id, Name
	$selection = Read-Host "Select source for packaging!"
	$source = $nugetSources[$selection - 1].Name

	Write-Host "[Push] $source : $($package.primaryPack)" -ForegroundColor Black -BackgroundColor Green
	nuget push "nupkgs/$($package.primaryPack)" -ApiKey "$apiKey"  -src "$source"
	nuget push "nupkgs/$($package.pack)" -ApiKey "$apiKey"  -src "$source"
}

function getProjects
{
  $projecFiles = dotnet sln list
  $lines  = $projecFiles -split "`n"
  $id = 0
  $projects = @();

  foreach ($line in $lines | Select -Skip 2) {
      $fileName = $line.Trim()
      $projectName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
      if($projectName -match "(?i).+\.test") {
         continue
      }
      $version = getVersion($fileName)
      if(!$version) {
         Write-Host "[Warning] Unable to resolve version for $projectName project." -ForegroundColor Yellow -BackgroundColor DarkGreen
         continue
      }
      $project = New-Object PSObject -Property @{
          Id = ++$id
          Project = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
          Version = getVersion($fileName)
          File = $fileName
      }
      $projects += $project
  }
  $projects += New-Object PSObject -Property @{
      Id = ++$id
      Project = "Refresh"
      Version = ""
      File = ""
  } 
  return $projects
}

$global:projects = getProjects
$nugetSources = getNugetSources

if($global:projects.Count -eq 0) {
   Write-Host "Project(s) not found!"
   return
}

function writeProjects {
  $global:projects | Format-Table @{
	Label = "Id"
    Expression =
    {
		if($_.Id -eq $global:projects.count) {
		   $color = "32"
		} else {
			$color = "0"
		}
        $e = [char]27
       "$e[${color}m$($_.Id)${e}[0m"
    }
  }, 
  
  @{
	Label = "Project"
    Expression =
    {
		if($_.Id -eq $global:projects.count) {
		   $color = "32"
		} else {
			$color = "0"
		}
        $e = [char]27
       "$e[${color}m$($_.Project)${e}[0m"
    }
  }, Version
}

function main {
  writeProjects
  $selection = Read-Host "Select project for packaging!"
  $selectionProject = $global:projects[($selection - 1)]
  
  if($selectionProject.Id -eq $global:projects.Count)
  {
    clear
	Write-Host "Refresh now..." -ForegroundColor Yellow
    $global:projects = getProjects
	clear
	return
  }

  Write-Host "[Build ...] $($selectionProject.Project)" -ForegroundColor White -BackgroundColor Blue
  build($selectionProject)
  if($LASTEXITCODE -eq 0)
  {
    if($env:NUPUSH_RUN_UNITTEST -eq "true")
    {
        Write-Host "[Run Unit Test ...]" -ForegroundColor White -BackgroundColor Blue
	      dotnet test
    }
    else 
    {
	      Write-Host "[Skip Unit Test ...]" -ForegroundColor DarkCyan #-BackgroundColor Black
    }
    
    if($LASTEXITCODE -eq 0)
	{
		if(0 -eq 0)
		{
		   Write-Host "[Pack ...]" -ForegroundColor White -BackgroundColor Blue
		   $result = pack($selectionProject)
		   if(!$result.success) {
			  Write-Host "Package Error" -ForegroundColor White -BackgroundColor Red
			  Write-Host $result.output
		   } else {

			  push($result)

		   }
		}
	} 
	else 
	{
		Write-Host "Unit Test Error" -ForegroundColor White -BackgroundColor Red
	}
  }
  else
  {
    Write-Host "Build Error" -ForegroundColor White -BackgroundColor Red
  }
}

clear
do {
  main
} while(1)
