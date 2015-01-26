#!/bin/bash

#Requires ImageMagick to be installed.

for f in *.svg;
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
