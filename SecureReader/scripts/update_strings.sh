#!/bin/sh
#

if ! [ -d ./temppath ]; then
    mkdir ./temppath; 
    echo "Created ./temppath";
fi

extractedStringsFile=./temppath/Localizable.strings.utf8
find .. -name \*.m | xargs genstrings -o ./temppath
iconv -f UTF-16 -t UTF-8 ./temppath/Localizable.strings > $extractedStringsFile

# Get all locale strings folder
for localeStringsDir in `find .. -name "*.lproj" -print`
do
    echo "Found $localeStringsDir"

    localeStringsPath=$localeStringsDir/Localizable.strings
    echo "Locale strings path is $localeStringsPath"

    # Just copy base strings file on first time
    if [ ! -e $localeStringsPath ]; then
	echo "Copy file $baseStringsPath to $localeStringsPath"
	cp $extractedStringsFile $localeStringsPath
    else
        oldLocaleStringsPath=$(echo "$localeStringsPath" | sed "s/\.strings/\.oldstrings/")
        cp $localeStringsPath $oldLocaleStringsPath
	echo "Copy from $localeStringsPath to $oldLocaleStringsPath"

        # Merge baseStringsPath to localeStringsPath
        awk 'NR == FNR && /^\/\*/ {x=$0; getline; a[x]=$0; next} /^\/\*/ {x=$0; print; getline; $0=a[x]?a[x]:$0; printf "%s\n\n", $0}' $oldLocaleStringsPath $extractedStringsFile > $localeStringsPath
	
        rm $oldLocaleStringsPath
    fi
done

rm -rf ./temppath
