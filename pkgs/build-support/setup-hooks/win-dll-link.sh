
fixupOutputHooks+=(_linkDLLs)

addEnvHooks "$targetOffset" linkDLLGetFolders

linkDLLGetFolders() {
    addToSearchPath "LINK_DLL_FOLDERS" "$1/lib"
    addToSearchPath "LINK_DLL_FOLDERS" "$1/bin"
}

_linkDLLs() {
    linkDLLsInfolder "$prefix/bin"
}

# Try to links every known dependancy of exe/dll in the folder of the 1str input
# into said folder, so they are found on invocation.
# The optional second input is a folder where DLL present in them are ignored and not copied.
# (DLLs are first searched in the directory of the running exe file.)
# The links are relative, so relocating whole /nix/store won't break them.
linkDLLsInfolder() {
(
    local folder
    folder="$1"
    if [ ! -d "$folder" ]
    then
        echo "Not linking DLLs in the non-existant folder $folder"
        return
    fi
    cd "$folder"

    # Use associative arrays as set
    local filesToChecks
    local filesDone
    declare -A filesToChecks # files that still needs to have their dependancies checked
    declare -A filesDone # files that had their dependancies checked and who is copied to the bin folder if found

    markFileAsDone() {
        if [ "!${filesDone[$1]+a}" ]; then filesDone[$1]=a ; fi
        if [ "${filesToChecks[$1]+a}" ]; then unset 'filesToChecks[$1]'; fi
    }

    addFileToLink() {
        if [ "${filesDone[$1]+a}" ]; then return; fi
        if [ "!${filesToChecks[$1]+a}" ]; then filesToChecks[$1]=a; fi
    }

    # Compose path list where DLLs should be located:
    #   prefix $PATH by currently-built outputs
    local DLLPATH=""
    local outName
    for outName in $(getAllOutputNames); do
        addToSearchPath DLLPATH "${!outName}/bin"
    done
    DLLPATH="$DLLPATH:$LINK_DLL_FOLDERS"

    echo DLLPATH="'$DLLPATH'"

    for peFile in *.{exe,dll}; do addFileToLink $peFile; done
    for peFile in $LINK_DLL_TO_SKIP; do markFileAsDone $peFile; done

    local linkCount=0
    while [ ${#filesToChecks[*]} -gt 0 ]
    do
        listOfDlls=( "${!filesToChecks[@]}" )
        local file=${listOfDlls[0]}
        markFileAsDone $file
        if [ ! -e "./$file" ]
        then
            local dllPath="$(PATH="$DLLPATH" type -P "$file")"
            if [ -z "$dllPath" ]; then continue; fi
            ln -sr "$dllPath" .
            echo link $dllPath to $folder/$dllPath
            linkCount=$(($linkCount+1))
        fi
        local dep_file
        # Look at the file’s dependancies
        for dep_file in $($OBJDUMP -p $file | sed -n 's/.*DLL Name: \(.*\)/\1/p' | sort -u); do
            addFileToLink $dep_file
        done
    done

    echo "Created $linkCount DLL link(s) in $folder"
)
}
