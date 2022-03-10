#
# Nuget Package Push Manager (cli)
# The MIT License (MIT)
# Copyright (c) 2021 Onur YILDIZ
#
#!/bin/bash

declare -A projects
declare -A nugetSources
projectLenght=0
nugetSourceLength=0

checkPackage(){
    local package=$1
    dpkg -s "$package" >/dev/null 2>&1 || {
        sudo apt-get install -y "$package"
    }
}

installDependences() { 
    echo "Check dependencies..."   
    checkPackage "libxml2-utils"    
    clear
}

getVersion() {
    local projectFileName=$1
    local retval=$(xmllint --xpath 'Project/PropertyGroup/Version/text()' $projectFileName 2>/dev/null)    
    echo $retval
}

lineBreak() {
    echo ""
    echo ""
}

build() {
    local projectIndex=$1    
    bgprintf "bgBlue" "white" "[Build ...] ${projects[$index,Project]}"
    dotnet build ${projects[$index,File]} --configuration Release    
    lineBreak
}

unitTest() {
    local projectIndex=$1
    lineBreak
    bgprintf "bgBlue" "blue" "[Run Unit Test ...]"
    dotnet test --no-build --verbosity normal
}

push() {
    local nuget=$1
    local snuget=$2

    lineBreak
    writeNugetPackages
    read -p 'Select source for packaging: ' selection

    if [[ ! $selection =~ ^[0-9]+$ ]]; then
        clear
        return
    fi

    if (( $selection > $nugetSourceLength )); then
        clear
        cprintf "yellow" "Bad selection...\n"
        sleep 1
        clear
        push "$nuget" "$snuget"
        return
    fi
        
    local sourceIndex=$((selection-1))
    local sourceName="${nugetSources[$sourceIndex,Name]}"
    bgprintf "bgGreen" "black" "[Push] $sourceName: $nuget"     
    dotnet nuget push "nupkgs/$nuget" -s "$sourceName"
    dotnet nuget push "nupkgs/$snuget" -s "$sourceName"
    lineBreak
}

packAndPush() {
    local projectIndex=$1
    local project=${projects[$projectIndex,Project]}    
    local projectFile=${projects[$projectIndex,File]}
    local replaced=${project//\./\\\.}
    local regex_snupkg="$replaced.([0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?)\.snupkg"
    local regex_nupkg="$replaced\.([0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?)\.nupkg"
    local regex_all="$replaced\.([0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?)\.(s)?nupkg$"

    for file in ./nupkgs/*; do
        local fileName=${file##*/}        
        if [[ $fileName =~ $regex_all ]] 
        then
            rm $file
        fi
    done
    
    local response=$(dotnet pack $projectFile --output nupkgs --include-symbols --configuration Release -p:SymbolPackageFormat=snupkg)
    local packSuccess=$?
    if (( packSuccess == 0))
    then
        local nupkg=$([[ $response =~ $regex_nupkg ]] && echo "${BASH_REMATCH[0]}")
        local snupkg=$([[ $response =~ $regex_snupkg ]] && echo "${BASH_REMATCH[0]}")
        push "$nupkg" "$snupkg"
    else
        bgprintf "bgRed" "white" "Pack Error"
        
    fi
}

getProjects() {
    unset projects[]
    let id=0
    local projectFiles=($(dotnet sln list | grep --no-group-separator '.csproj'))
    for fileName in "${projectFiles[@]}" 
    do        
        projectNameWithPath=${fileName%.*}
        projectName=${projectNameWithPath##*/}
        [[ ${projectName,,} == *.test ]] && continue

        version=$(getVersion $fileName)          
        if [[ -z "${version// }" ]]; then 
            echo "[Warning] Unable to resolve version for $projectName project."
            continue
        fi                           
        projects[$id,Id]=$((id+1))
        projects[$id,Project]="$projectName"
        projects[$id,Version]="$version"
        projects[$id,File]="$fileName"
        projects[$id,__Color]="reset"        
        let id+=1     
    done   
    
    projects[$id,Id]="$((id+1))≥"
    projects[$id,Project]="Refresh"
    projects[$id,Version]=""
    projects[$id,File]=""
    projects[$id,__Color]="green"
    projectLenght=$id
}

trim() {
    local var="$*"    
    var="${var#"${var%%[![:space:]]*}"}"    
    var="${var%"${var##*[![:space:]]}"}"   
    echo $var
}

getNugetSources() {
    local regex=".+[0-9]+\. +(.+) \[Enabled]"
    local output="$(dotnet nuget list source | awk '/.+[0-9]+\. +(.+) \[Enabled]/{print; getline; print;}')"
    IFS=$'\n' read -ra lines -d $'\0' <<< "$output"
    let len=${#lines[@]}
    for ((i = 0 ; i < $len ; i+=2)); do        
        let x=$((i+1))                
        [[ ${lines[$i]} =~ $regex ]]
        local name=$(trim "${BASH_REMATCH[1]}")
        local source=$(trim "${lines[$x]}")
        let id=$((i/2))        
        nugetSources[$id,Id]="$((id+1))"
        nugetSources[$id,Name]="$name"
        nugetSources[$id,Source]="$source"
    done 
    nugetSourceLength=$((id+1))
}

repeatChr() {
    local count=$1
    local character=$2

    for (( i = 0; i < $count; ++i ))
    do
        printf $character
    done
}

stringPadding() {
    local str=$1
    local padding=$2
    printf "%-"$padding"s" "$str"
}

cprintf(){
    red="\033[0;31m"
    green="\033[0;32m"
    yellow="\033[1;33m"    
    reset="\033[0m"    
    printf "${!1}${2} ${reset}"
}

bgprintf(){
    bgRed="\e[1;41m"
    bgGreen="\e[1;42m"
    bgYellow="\e[1;43m"    
    bgBlue="\e[1;44m"
    bgCyan="\033[46m"
    reset="\033[0m"    
    red="\033[0;31m"
    green="\033[0;32m"
    yellow="\033[1;33m"  
    cyan="\033[0;36m"  
    white="\033[0;37m"  
    black="\033[0;30m"   
    printf "${!2}${!1}${3} ${reset}\n"
}

cprintfw(){
    red="\033[0;31m"
    green="\033[0;32m"
    yellow="\033[1;33m"    
    reset="\033[0m"    
    printf "${!1}"
}

writeTable() {    
    local -n array=$1
    local dimension=$2
    shift
    shift
    let dataCount=${#array[@]}/$dimension    
    local columns=("$@")    
    declare -A columnWith    
    # resolve column with
    for columnName in "${columns[@]}"
    do
        for ((i = 0 ; i < $dataCount ; i++)); do 
            local text="${array[$i,$columnName]}"            
            let textWith=${#text}
            let currentWith=${columnWith[$columnName]:-${#columnName}}            
            columnWith[$columnName]=$(( currentWith > textWith ? currentWith : textWith ))
        done 
    done

    # write header 
    for columnName in "${columns[@]}"
    do
        let with=${columnWith[$columnName]}
        stringPadding "$columnName" "$with"
        printf " "
    done
    echo ""

    # write header seperator
    for columnName in "${columns[@]}"
    do
        let with=${columnWith[$columnName]}
        repeatChr "$with" "-"
        printf " "
    done
    echo ""
    
    # write data
    for ((i = 0 ; i < $dataCount; i++)); do         
        local color=${array[$i,__Color]:-reset}        
        cprintfw "$color"
        for columnName in "${columns[@]}"
        do
            let with=${columnWith[$columnName]}
            local text="${array[$i,$columnName]}"
            stringPadding "$text" "$with"
            printf " "                        
        done
        cprintfw "reset"
        echo ""
    done   

    echo ""
}

writeProjects() {        
    writeTable projects "5" "Id" "Project" "Version"    
}

writeNugetPackages() {
    writeTable nugetSources "3" "Id" "Name"
}

main() {
    writeProjects    
    read -p 'Select project for packaging: ' selection

    if [[ ! $selection =~ ^[0-9]+$ ]]; then
        clear
        return
    fi

    if (( $selection > $projectLenght )); then
        clear
        cprintf "yellow" "Refresh now..."
        getProjects
        clear
        return
    fi
        
    local projectIndex=$((selection-1))
    lineBreak
    build $projectIndex
    local buildStatus=$?
    if [ $buildStatus -eq 0 ]
    then
        if [ $NUPUSH_RUN_UNITTEST -eq "true" ] 
        then
            unitTest $projectIndex
        else 
            bgprintf "bgCyan" "white" "[Skip Unit Test ...]"
        fi
        
        local unitTestStatus=$?
        if [ $unitTestStatus -eq 0 ]
        then
            packAndPush $projectIndex
        else 
            bgprintf "bgRed" "white" "Unit Test Error"
        fi
    else
        bgprintf "bgRed" "white" "Build Error"
    fi
}

installDependences
getNugetSources
getProjects
while :
do
    main    
done
