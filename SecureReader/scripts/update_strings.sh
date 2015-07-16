#!/bin/sh
#

function processStringsFile {

    sourceFile="$1"
    fileName="$2"
    ignoreBase="$3"

    echo "Processing source file $sourceFile"

    for languageDir in `find .. -depth 1 -name "*.lproj" -print`
    do
	if [ "$ignoreBase" == "1" ] && [ "$languageDir" == "../Base.lproj" ] ; then
	    echo "Ignore Base.lproj"
	    continue;
	fi

	echo "Process $languageDir"

	outputPath=$languageDir/$fileName
	echo "Output path is $outputPath"

        # Just copy on first time
	if [ ! -e $outputPath ]; then
	    echo "Copy file $sourceFile to $outputPath"
	    cp $sourceFile $outputPath
	else
            oldStringsFile=$(echo "$outputPath" | sed "s/\.strings/\.oldstrings/")
            cp $outputPath $oldStringsFile
	    echo "Copy from $outputPath to $oldStringsFile"
	    
            # Merge baseStringsPath to localeStringsPath
            awk 'NR == FNR && /^\/\*/ {x=$0; getline; a[x]=$0; next} /^\/\*/ {x=$0; print; getline; $0=a[x]?a[x]:$0; printf "%s\n\n", $0}' $oldStringsFile $sourceFile > $outputPath
	    
            rm $oldStringsFile
	fi
    done   
}

if ! [ -d ./temppath ]; then
    mkdir ./temppath; 
    echo "Created ./temppath";
fi

extractedStringsFile=./temppath/Localizable.strings.utf8
find .. -name \*.m | xargs genstrings -o ./temppath
iconv -f UTF-16 -t UTF-8 ./temppath/Localizable.strings > $extractedStringsFile

processStringsFile $extractedStringsFile "Localizable.strings" 0

extractedStringsFile=./temppath/FeedCategories.strings.utf8
iconv -t UTF-8 ../Base.lproj/FeedCategories.strings > $extractedStringsFile
processStringsFile $extractedStringsFile "FeedCategories.strings" 1

rm -rf ./temppath
