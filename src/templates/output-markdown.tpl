@"
# $ModuleName;
"@
$Progress = 0;
$CommandsHelp | % {
	Update-Progress $_.Name 'Documentation';
	$Progress++;
@"
## $(Convert-HTMLEntities($_.Name));
"@
	$Synopsis = $_.synopsis.Trim();
	$Syntax = $_.syntax | Out-String;
	if (-not ($Synopsis -ilike "$($_.Name.Trim())*")) {
		$Tmp = $Synopsis;
		$Synopsis = $Syntax;
		$Syntax = $Tmp;
@"	
### Synopsis
    $(Convert-HTMLEntities($Syntax));
"@
	}
@"	
### Syntax
    $(($Synopsis));
"@	

	if (!($_.alias.Length -eq 0)) {
@"
### $($_.Name) Aliases
"@
	$_.alias | % {
@"
 - $($_.Name)
"@
		}
@"

"@
	}
	
    if ($_.parameters) {
@"
### Parameters

<table class="table table-striped table-bordered table-condensed visible-on">
	<thead>
		<tr>
			<th>Name</th>
			<th class="visible-lg visible-md">Alias</th>
			<th>Description</th>
			<th class="visible-lg visible-md">Required?</th>
			<th class="visible-lg">Pipeline Input</th>
			<th class="visible-lg">Default Value</th>
		</tr>
	</thead>
	<tbody>
"@
     $_.parameters.parameter | % {
@"
		<tr>
			<td><nobr>$(Convert-HTMLEntities($_.Name))</nobr></td>
			<td class="visible-lg visible-md">$(Convert-HTMLEntities($_.Aliases))</td>
			<td>$(Convert-HTMLEntities(($_.Description  | Out-String).Trim()) $True)</td>
			<td class="visible-lg visible-md">$(Convert-HTMLEntities($_.Required))</td>
			<td class="visible-lg">$(Convert-HTMLEntities($_.PipelineInput))</td>
			<td class="visible-lg">$(Convert-HTMLEntities($_.DefaultValue))</td>
		</tr>
"@
        }
@"
	</tbody>
</table>			
"@
    }
    $InputTypes = $(Convert-HTMLEntities($_.inputTypes  | Out-String));
    if ($InputTypes.Length -gt 0 -and -not $InputTypes.Contains('inputType')) {
@"
### Inputs
 - $InputTypes;

"@
	}
    $ReturnValues = $(Convert-HTMLEntities($_.returnValues  | Out-String));
    if ($ReturnValues.Length -gt 0 -and -not $ReturnValues.StartsWith("returnValue")) {
@"
### Outputs
 - $ReturnValues;

"@
	}
    $Notes = $(Convert-HTMLEntities($_.alertSet  | Out-String));
    if ($Notes.Trim().Length -gt 0) {
@"
### Note
$Notes;

"@
	}
	if (($_.examples | Out-String).Trim().Length -gt 0) {
@"
### Examples
"@
		$_.examples.example | % {
@"
**$(Convert-HTMLEntities($_.title.Trim(('-',' '))));**

		$(Convert-HTMLEntities($_.code | Out-String));
		
$(Convert-HTMLEntities($_.remarks | Out-String));
"@
		}
	}
	if (($_.relatedLinks | Out-String).Trim().Length -gt 0) {
@"
### Links

"@
		$_.links | % { 
@"
 - [$_.name]($_.link)
"@
		}
	}
}