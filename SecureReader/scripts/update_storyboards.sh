#!/bin/sh
#

function processStringsFile {

    sourceFile="$1"
    targetFile="$2"

    # Just copy on first time
    if [ ! -e $targetFile ]; then
	echo "Copy file $sourceFile to $targetFile"
	cp $sourceFile $targetFile
    else
        oldFile=$(echo "$targetFile" | sed "s/\.strings/\.oldstrings/")
        cp $targetFile $oldFile
	echo "Copy from $targetFile to $oldFile"
	    
        # Merge baseStringsPath to localeStringsPath
        awk 'NR == FNR && /^\/\*/ {x=$0; getline; a[x]=$0; next} /^\/\*/ {x=$0; print; getline; $0=a[x]?a[x]:$0; printf "%s\n\n", $0}' $oldFile $sourceFile > $targetFile
	
        rm $oldFile
    fi
}

function processStoryboard {

    storyboard=$1
    storyboardFileName=${storyboard:14}
    outputFileName=$(echo "$storyboardFileName" | sed "s/\.storyboard/\.strings/")

    sourceFile=./temppath/storyboard.strings
    tempFile=./temppath/storyboard.stringstemp
    ibtool "$1" --generate-strings-file $tempFile
    iconv -f UTF-16 -t UTF-8 $tempFile > $sourceFile

    for languageDir in `find .. -depth 1 -name "*.lproj" -print`
    do
	language=${languageDir:3:((${#languageDir})-9)}
	if [ "$language" == "Base" ] ; then
	    continue;
	fi

	echo "* $language -> $languageDir/$outputFileName"
	processStringsFile $sourceFile $languageDir/$outputFileName      
    done
}

function processStoryboards {
    for storyboard in `find "../Base.lproj" -depth 1 -name "*.storyboard" -print`
    do
	echo "Process storyboard $storyboard"
	processStoryboard $storyboard 
    done
}

if ! [ -d ./temppath ]; then
    mkdir ./temppath; 
    echo "Created ./temppath";
fi

processStoryboards

rm -rf ./temppath
