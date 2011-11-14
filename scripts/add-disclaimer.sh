#!/bin/bash
DISCLAIMER=disclaimer.txt
FILES=`find . -name "*.m" -or -name "*.h"`
for f in $FILES
do
	if [ $f != $DISCLAIMER ]; then
	  echo "Adding the disclaimer to $f"
	  cp $DISCLAIMER tmp.txt
	  cat $f >> tmp.txt
	  mv tmp.txt $f
	else
		echo "Not adding disclaimer to the disclaimer!"
	fi
done