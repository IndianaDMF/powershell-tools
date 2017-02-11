function update-dependency($repo = "C:\Users\dustinf\Source\Repos", $lib = "DepLib", $ver="1.0.5", $targetBranch="Feature2")
{
    push-location $repo
	$filter = "packages.config";
    write-host "searching all packages.config in $repo for $lib"
	if($lib -eq ""){
		write-host "please provide a lib value"
	}
	
    $files = gci $repo -filter $filter -recurse
    $files | % { 
        $content = gc $_.FullName | select-string -Pattern $lib
        if($content -and $content -ne ""){
           $content = $content.ToString();
           if($content.IndexOf("-") -eq -1){ ## TODO: handle semver
                $temp = $content.SubString($content.IndexOf("version") + 9, $ver.Length);
                $oldVer = [int]($temp.Replace(".",""));
                $newVer = [int]($ver.Replace(".",""));
                if($newVer -gt $oldVer){
                    write-host -ForegroundColor Red "Update Found";
                    write-host "---------------";
                    write-host $_.FullName;
                    write-host "Old: $temp New: $ver"
                    $toUpdate = read-host "Update? [y]/n";
                    if($toUpdate -ieq "y" -or $toUpdate -eq ""){
                        # first update the file contents
                        $fc = gc $_.FullName;
                        $newcontent = $content.Replace($temp, $ver);
                        $fc = $fc.Replace($content, $newcontent);
                        set-content -path $_.FullName -value $fc;
                        write-host -ForegroundColor Green "Updated";

                        # ask user if we should continue with more files or go ahead and commit the change to the branch
                        # TODO: ask the user
                        Push-Location $_.Directory.FullName
                       
                    }
                }
            } 
        }
    }       
}

update-dependency