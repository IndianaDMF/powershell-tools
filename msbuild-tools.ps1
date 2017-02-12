function update-reference{
    param(
        [Parameter(Mandatory=1)]
        [string]$repo,
        [Parameter(Mandatory=1)]
        [string]$lib,
        [Parameter(Mandatory=1)]
        [string]$ver,
        [Parameter(Mandatory=1)]
        [string]$branch,
        [Parameter(Mandatory=1)]
        [string]$nugetPath
    )
    ## uses %AppData%\NuGet\NuGet.config
    ## depends on https://github.com/deadlydog/Invoke-MsBuild for msbuild
    ## https://www.powershellgallery.com/packages/Invoke-MsBuild/2.2.0
    ## C:\Program Files\WindowsPowerShell\Modules\Invoke-MsBuild\2.2.0
    
    push-location $repo;
    $files = ls *.sln -recurse;
    $files | % {        
        push-location $_.DirectoryName;
        $sln = $_.FullName;
        git checkout $branch
        & $nugetPath restore $sln
        $nugetResult = & $nugetPath update $sln -id $lib -version $ver
        if($nugetResult -like "*No projects found*"){
            continue;
        }

        $buildResult = invoke-msbuild -path $sln
        if($buildResult.BuildSucceeded -eq $true){
            git commit -m "update packages"
            #git push
        }else{
             gc $buildResult.BuildErrorsLogFilePath | write-host -foregroundcolor RED
        }       
    }
}

$nuget = "C:\Utilities\NuGet.exe";
update-reference -repo "C:\Work\Repo" -lib "deplib" -ver "1.0.5" -branch "feature2" -nugetPath $nuget


