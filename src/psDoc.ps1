Param (
    [Parameter(Mandatory=$true,  Position=0)] [String] $ModuleName,
	[Parameter(Mandatory=$False)            ] [String] $ModulePath,	
    [Parameter(Mandatory=$False)            ] [String] $TemplateDir = "./templates",
    [Parameter(Mandatory=$False, Position=1)] [String] $Template    = "output-html.tpl",	
    [Parameter(Mandatory=$False, Position=2)] [String] $OutputDir   = './help', 
    [Parameter(Mandatory=$False, Position=3)] [String] $FileName    = 'index.html'
)


Function Convert-HTMLEntities {
    Param (
        [String] $InputString,
        [Bool]   $IncludeBreaks = $False
    )

    if ($InputString -eq $Null) {
        return ;
    }
    
    $Output = $InputString.Replace('&', "&amp;").Replace('<', "&lt;").Replace('>', "&gt;").Trim();

    if ($IncludeBreaks) {
        $Output = $Output.Replace([Environment]::NewLine, "<br>");
    }

    return $Output;
}
#__________________________________________________________________________________


Function Create-OutputDir {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String]  $OutputDir,
        [Parameter(Mandatory=$False, Position=1)] [Boolean] $Override=$false
    )
    
    # If override is set -> deleting & recreating $OutputDir folder.
    if ($Override) {
        Remove-Item -Path $OutputDir -Recurse -Force | Out-Null; 
    }

    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null;
    }
}
#__________________________________________________________________________________


Function Test-OutputDirPath {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String]  $OutputDir
    )
    
    if ([String]::IsNullOrEmpty($OutputDir)) {
        throw "Unable to retrieve template content: Null or empty No OutputDir specified";
    }

    return (Test-Path -Path $OutputDir);
}
#__________________________________________________________________________________


Function Test-TemplateDirPath {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String]  $TemplateDir
    )
    
    if ([String]::IsNullOrEmpty($TemplateDir)) {
        throw "Unable to retrieve template path: Null or empty No Template dir specified";
    }

    return (Test-Path -Path $TemplateDir);
}
#__________________________________________________________________________________

Function Test-TemplatePath {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String]  $TemplatePath
    )
    
    if ([String]::IsNullOrEmpty($TemplatePath)) {
        throw "Unable to retrieve template path: Null or empty No Template specified";
    }

    return (Test-Path -Path $TemplatePath);
}
#__________________________________________________________________________________


Function Update-Progress {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String] $Name, 
        [Parameter(Mandatory=$True,  Position=1)] [String] $Action
    )

    Write-Progress -Activity "Rendering $Action for $Name" -CurrentOperation "Completed $Progress of $TotalCommands." -PercentComplete $(($Progress/$TotalCommands) * 100);
}
#__________________________________________________________________________________


Function Write-Help {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [ValidateNotNullOrEmpty()] [String] $FormattedData = $(throw "please provide a non empty/null value."), 
        [Parameter(Mandatory=$True,  Position=1)] [ValidateNotNullOrEmpty()] [String] $OutputFile    = $(throw "please provide a non empty/null value.")
    )

    # Writing into Outputfile (-".."- are mandatory due to possible whitespaces issues)
    Invoke-Expression $FormattedData > "$OutputFile";
}
#__________________________________________________________________________________


Function Format-Data {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String] $Template
    )
    
    $formattedData = $Null;

    if ([String]::IsNullOrEmpty($Template)) {
        throw "Unable to retrieve template content: No filepath specified";
    }
    if (-not (Test-Path -Path $Template)) {
        throw "Unable to retrieve template content: $Template file not found";
    }
   
    $formattedData = Get-Content $Template -raw -force;

    return $formattedData;
}
#__________________________________________________________________________________


Function Import-ModuleFromPath {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String] $ModulePath
    )
    try {
        Import-Module -Name $ModulePath;
    }
    catch {
         Write-Error "Unable to load $ModulePath, please check files";
    }
}
#__________________________________________________________________________________


Function Test-IfModule {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String] $ModulePath
    )
    $IsModule = $False;
    
    if (Test-Path -Path $ModulePath) {
        $authorizedExtensions = { ".ps1", ".psm1", ".psd1" };
        $TmpPath = $ModulePath.ToString().ToLower();
        if (![String]::IsNullOrEmpty($TmpPath)) {
            foreach ($ext in $authorizedExtensions) {
                if ($TmpPath.EndsWith($ext)) {
                    $IsModule = $True;
                    break;
                }
            }
        }
    }
    echo $IsModule;
    return $IsModule;
}
#__________________________________________________________________________________


Function Test-IfModuleLoaded {
    Param (
        [Parameter(Mandatory=$True,  Position=0)] [String] $ModuleName
    )
    return !((Get-Module -Name $ModuleName) -eq $Null);
}
#__________________________________________________________________________________


#
# Main_____________________________________________________________________________ 
#

if (![String]::IsNullOrEmpty($ModulePath) -and (Test-IfModule $ModulePath)) {
    Import-ModuleFromPath $ModulePath;
    if (Test-IfModuleLoaded $ModuleName) {
        Write-Host "Module $ModuleName ($ModulePath) successfully loaded";
    }
    else {
        Throw "Unable to load module $ModuleName ($ModulePath)";
    }
}

# Check templates integrity
$Template = "$TemplateDir/$Template";
if (![String]::IsNullOrEmpty($TemplateDir) -and (Test-TemplateDirPath $TemplateDir)) {
    if (-not (Test-TemplatePath $Template)) {
        Throw "Unable to find specified template $Template";
    }
}
else {
       Throw "Unable to find specified template dir: $TemplateDir";
}


$i = 0;
$CommandsHelp = (Get-Command -Module $moduleName) | Get-Help -Full | Where-Object {! $_.name.EndsWith('.ps1')};

Foreach ($H in $CommandsHelp) {
    $CmdHelp = (Get-Command $H.Name);

    # Get any aliases associated with the method
    $Alias = Get-Alias -Definition $H.Name -ErrorAction SilentlyContinue;
    if ($Alias) { 
        $H | Add-Member Alias $alias;
    }
    
    # Parse the related links and assign them to a links hashtable.
    if (($H.relatedLinks | Out-String).Trim().Length -gt 0) {
        $Links = $H.relatedLinks.navigationLink | % {
            if ($_.uri)      { @{name = $_.uri; link = $_.uri; target = '_blank'} } 
            if ($_.linkText) { @{name = $_.linkText; link = "#$($_.linkText)"; cssClass = 'psLink'; target = '_top'} }
        }
        $H | Add-Member Links $Links;
    }

    # Add parameter aliases to the object.
    Foreach ($P in $H.parameters.parameter) {
        $ParamAliases = ($CmdHelp.parameters.values | Where name -like $P.name | Select aliases).Aliases;
        if ($ParamAliases) {
            $P | Add-Member Aliases "$($ParamAliases -join ', ')" -Force;
        }
    }
}

$TotalCommands = $CommandsHelp.Count;

# Formatting help data from selected template
$FormattedDataFromTemplate = Format-Data $Template;

# Creating output dir to store generated help
Create-OutputDir $OutputDir;

if (Test-OutputDirPath $OutputDir) {
    # Writing generated help into output file
    $OutputFile="$OutputDir\$FileName";
    Write-Help $FormattedDataFromTemplate $OutputFile;
}
else {
    Write-Error "Unable to create $OutputDir, please check permission";
}

#_EOM______________________________________________________________________________