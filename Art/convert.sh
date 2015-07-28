#!/bin/bash

# Requires ImageMagick to be installed.

# Build the app icon from paik_launcher.svg
convert -strip -background none paik_launcher.svg -resize 120x120 ../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher@2x.png
convert -strip -background none paik_launcher.svg -resize 180x180 ../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher@3x.png
convert -strip -background none paik_launcher.svg -resize 76x76 ../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher.png
convert -strip -background none paik_launcher.svg -resize 152x152 ../SecureReader/Images.xcassets/AppIcon.appiconset/paik_launcher@2x-1.png

if [ "$#" -eq "0" ]; then
    files=*.svg
else
    files="$@"
fi

for f in $files
do
	echo "Processing: $f"

	name=${f/.svg}
	lang=""
	
	Target=../SecureReader/Images.xcassets/${name}.imageset
	mkdir -p ${Target}

	convert -strip -background none $f -resize 150% ${Target}/${name}@3x.png
	convert -strip -background none $f -resize 100% ${Target}/${name}@2x.png
	convert -strip -background none $f -resize 50% ${Target}/${name}.png

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
