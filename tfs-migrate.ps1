<#
# Brute force helper to:
# 1. delete nuget target configuration from each project file
# 2. remove unwanted references from project file
# 3. remove unwanted packages from packages.config
# 
# .nuget directory has to be removed by hand. Thanks to MS the .sln file is not an xml or json.
# also, the nuget command line interface does not support deleting packages. which is why the brute force method is used instead
#>
function clean-solution(){
  param(
        [Parameter(Mandatory=1)]
        [string]$path,
        [Parameter(Mandatory=0)]
        [Array]$refsToRemove
    )
	
    push-location $path   
    ## todo: delete .nuget directory from solution and solution file. 

	$filter = "*.csproj";   		
    $files = gci $path -filter $filter -recurse
    # for each csproj
    $files | % {               
        # convert to xml
        $csprj = new-object -typename xml
        $csprj.Load($_.FullName);

        ## remove nuget target in project file       
        $csprj.Project.Import | % {
            if($_.Project -match "nuget.targets"){
                $_.ParentNode.RemoveChild($_);
            }
        }       

        ## brute force ref remove:
        ## 1. remove the ref from the project file
        #http://stackoverflow.com/questions/8963328/how-do-i-use-powershell-to-add-remove-references-to-a-csproj
        [System.Xml.XmlNamespaceManager] $nsmgr = $csprj.NameTable
        $nsmgr.AddNamespace('a','http://schemas.microsoft.com/developer/msbuild/2003')        
        $ref = $refsToRemove;
        $ref | % {
            $xpath = [string]::Format("//a:Reference[@Include='{0}']", $_)       
            $node = $csprj.SelectSingleNode($xpath, $nsmgr);
            if($node){
                $node.ParentNode.RemoveChild($node);
            }
        }

        ## save all the changes to this project file
        Set-ItemProperty $_.FullName -Name IsReadOnly -Value $false 
        $csprj.Save($_.FullName);  
        

        ## 2. remove the package info from package.config 
        $packageFile = gci -path $_.Directory -Filter "packages.config"
        if($packageFile){
            $pckg = new-object -typename xml
            $pckg.Load($packageFile.FullName);

            $pckg.packages.package | ForEach-Object {
                if($ref -contains $_.Id){
                    $_.ParentNode.RemoveChild($_);
                }
            }

            Set-ItemProperty $packageFile.FullName -Name IsReadOnly -Value $false   
            $pckg.Save($packageFile.FullName);
        }
    }
}

## example on how to call
clean-solution -path "C:\path" -refsToRemove @("Lib1", "Lib2", "Lib3")

