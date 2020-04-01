#!/bin/bash
# Set variables

GPGKEY=0x0000000000000000
BBBUCKET=bucketName # BackBlaze BUCKET
BBDIR=archives # BackBlaze DIRectory (e.g. machine name)

for arg in "$@"; do
	BUFILE=$(readlink -f "$arg") # BackUp FILE
	### Begin Backup
	echo "$(date) : Start backup of $BUFILE to $BBBUCKET:$BBDIR"
	BUPATH=$(dirname "$BUFILE")
	cd "$BUPATH"
	FILENAME=$(basename "$BUFILE")

	# Compress if directory directory
	if [[ "$FILENAME" = *.tar* ]]; then
		BUNAME=${FILENAME// /_}
		cp $FILENAME $BUNAME
	else
		echo "$(date) : Compressing..."
		BUNAME=${FILENAME// /_}.tar
		tar -cf $BUNAME "$FILENAME"
		xz -z --threads=0 $BUNAME
		BUNAME=${BUNAME// /_}.xz
		echo "$(date) : $FILENAME compressed to $BUNAME"
	fi

	# Encrypt
	if ! [[ "$BUNAME" = *.vc* ]]; then
		echo "$(date) : Encrypting with key $GPGKEY..."
		gpg --yes --batch -r $GPGKEY -o $BUNAME.gpg -e $BUNAME
		echo "$(date) : $BUNAME encrypted to $BUNAME.gpg"
		if ! [[ "$FILENAME" = "$BUNAME" ]];then
			rm "$BUNAME"
			echo "$(date) : $BUNAME deleted"
		fi
		BUNAME="$BUNAME.gpg"
	fi

	# Upload
	SHA=`sha1sum "$BUNAME" | awk '{print $1}'`
	echo "$(date) : $BUNAME checksum:"
	echo "$(date) : 	$SHA"
	echo "$(date) : Uploading..."
	b2 upload_file --sha1 $SHA $BBBUCKET $BUNAME $BBDIR/$BUNAME
	echo "$(date) : Uploaded to $BBBUCKET:$BBDIR/$BUNAME"

	# Clean
	rm "$BUNAME"
	echo "$(date) : $BUNAME deleted"
done
