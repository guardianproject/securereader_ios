#!/bin/bash

# Requires ImageMagick to be installed.

function checkForInkscape {
    IM="/Applications/Inkscape.app/Contents/Resources/bin/inkscape"
    $IM --version >/dev/null 2>&1 || { echo >&2 "ERROR: Inkscape needs to be installed to update the icons!"; exit 1; }
}

function updateIcon {
    # Build the app icon from paik_launcher.svg
    echo "Updating icon"
    echo
    checkForInkscape
    DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    IM="/Applications/Inkscape.app/Contents/Resources/bin/inkscape"
    $IM -z -e "$DIR/../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher@2x.png" --export-background=white -w 120 -h 120 $DIR/paik_launcher.svg
    $IM -z -e "$DIR/../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher@3x.png" --export-background=white -w 180 -h 180 $DIR/paik_launcher.svg
    $IM -z -e "$DIR/../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher.png" --export-background=white -w 76 -h 76 $DIR/paik_launcher.svg
    $IM -z -e "$DIR/../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher@2x-1.png" --export-background=white -w 152 -h 152 $DIR/paik_launcher.svg
}

function showUsage {
    echo "Usage:"
    echo
    echo "$0 --icon            Update the icon"
    echo "$0 <file-pattern>    Process the given files, e.g. $0 ic_toggle*"
    echo "$0 --all             Process all SVG files"
}

if [ "$#" -eq "0" ]; then
    showUsage
    exit
fi

if [ "$1" = "--help" ]; then
    showUsage
    exit
elif [ "$1" = "--icon" ]; then
    updateIcon
    exit
elif [ "$1" = "--all" ]; then
    files=*.svg
else
    files="$@"
fi


DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IM="/Applications/Inkscape.app/Contents/Resources/bin/inkscape"
checkForInkscape

for f in $files
do
    if [ ! -e $f ]; then
	continue
    fi

    echo "Processing: $f"

    name=${f/.svg}

    originalW=$($IM -z -W "$DIR/$f")
    originalH=$($IM -z -H "$DIR/$f")

    absolutesize=$(expr "$name" : '.*@\([0-9]*\)')
    if [[ ${#absolutesize} -ne 0 ]]; then
	aspect=$(echo "scale=2; $originalW/$originalH" | bc)
	echo "Asp $aspect"
	if [[ $(echo $originalW'<'$originalH | bc -l) -eq 0 ]]; then
	    echo "OriginalW bigger"
	    originalW=$absolutesize
	    originalH=$(echo "scale=2; $originalW/$aspect" | bc)
	else
	    echo "OriginalH bigger"
	    originalH=$absolutesize
	    originalW=$(echo "scale=2; $originalH*$aspect" | bc)
	fi

	name=${name%%@[0-9]*}
    fi
    
    echo "Size is $originalW x $originalH"

    Target="$DIR/../SecureReader/Images.xcassets/${name}.imageset"
    mkdir -p ${Target}

    sizeW=$(echo 0.5*$originalW | bc)
    sizeH=$(echo 0.5*$originalH | bc)
    $IM -z -e "${Target}/${name}.png" -w $sizeW -h $sizeH -D "$DIR/$f"
    sizeW=$originalW
    sizeH=$originalH
    $IM -z -e "${Target}/${name}@2x.png" -w $sizeW -h $sizeH -D "$DIR/$f"
    sizeW=$(echo 1.5*$originalW | bc)
    sizeH=$(echo 1.5*$originalH | bc)
    $IM -z -e "${Target}/${name}@3x.png" -w $sizeW -h $sizeH -D "$DIR/$f"

    cat > ${Target}/Contents.json <<EOF
{
 "images" : [
  {
   "idiom" : "universal",
   "scale" : "1x",
   "filename" : "${name}.png"
  },
  {
   "idiom" : "universal",
   "scale" : "2x",
   "filename" : "${name}@2x.png"
  },
  {
   "idiom" : "universal",
   "scale" : "3x",
   "filename" : "${name}@3x.png"
  }
 ],
 "info" : {
  "version" : 1,
  "author" : "xcode"
 }
}
EOF
    
done
