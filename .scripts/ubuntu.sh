#!/bin/bash
set -x # enable debug

# for example: 0.1.1
THINDICT_VERSION=$(awk 'NR == 1 {print substr($2, 2, index($2, "-") - 2)}' debian/changelog)
# for example: 0.1.1-1
THINDICT_PACKAGE_VERSION=$(awk 'NR == 1 {print substr($2, 2, length($2) - 2)}' debian/changelog)
# ubuntu series
UBUNTU_SERIES=('precise' 'quantal' 'saucy' 'trusty')
# name
NAME='xiangxw'
# email
EMAIL='xiangxw5689@126.com'

function createOriginSource()
{
	FILENAME=thindict_${THINDICT_VERSION}
	git archive master --format=tar -o ../${FILENAME}.orig.tar
	cd ..
	xz ${FILENAME}.orig.tar
	mkdir ${FILENAME}
	cd ${FILENAME}
	tar -Jxf ../${FILENAME}.orig.tar.xz
}

function debuildBinary()
{
	# build binary package
	debuild
	debuild clean
}

function debuildSource()
{
	# backup
	cp debian/changelog /tmp/thindict-changelog
	# build source package
	echo 'thindict ('${THINDICT_PACKAGE_VERSION}'ubuntu1ppa1~'$1'1) '$1'; urgency=low' > tmp
	echo '' >> tmp
	echo '  * For ubuntu '$1' ppa' >> tmp
	echo '' >> tmp
	echo ' -- '${NAME}' <'${EMAIL}'>  '`LANG=C date -R` >> tmp
	echo '' >> tmp
	cat debian/changelog >> tmp
	mv tmp debian/changelog
	debuild -S -sa -kxiangxw5689@126.com
	# restore
	mv -f /tmp/thindict-changelog debian/changelog
}

function debuildAllSourceAndUpload()
{
	# build source packages for all ubuntu series and upload them
	for (( i = 0; i < ${#UBUNTU_SERIES[@]}; i++ )); do
		debuildSource ${UBUNTU_SERIES[$i]}
	done
	if [[ "$1" == "test" ]]; then
		dput ppa:xiangxw5689/thindict-test ../thindict_*_source.changes
	else
		dput ppa:xiangxw5689/thindict ../thindict_*_source.changes
	fi
}

# remove old packages and folders
rm -rf ../thindict*
# create origin source package
createOriginSource
# build
if [[ "$1" == "binary" ]]; then
	debuildBinary
else
	debuildAllSourceAndUpload $1
fi