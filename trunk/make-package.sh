#!/bin/bash

# Base on code from http://klikclient.googlecode.com/svn/trunk/client/trunk/klik-svn2tar

NAME="snmp2xml"
RELEASE="0"				# still beta

# make a temp directory
t=$(mktemp -d ${NAME}-${RELEASE}.XXX) || ( echo "ERROR: could not make temporary directory" && exit 1 )

echo "Building ${NAME} source archive in $t"

# this is where the svn source is
svnroot=http://${NAME}.googlecode.com/svn/trunk

# get release revision from svn
REV=$(/opt/subversion/bin/svn export ${svnroot} $t/${NAME} | grep '^Exported' | awk '{print int($3)}')

echo "NAME	= ${NAME}"
echo "RELEASE	= ${RELEASE}"
echo "REV	= ${REV}"
DIR="${NAME}-${RELEASE}.${REV}"		# the package directory
TAR="${DIR}.tar.gz"			# the package file
echo "DIR	= ${DIR}"
echo "TAR	= ${TAR}"

[ $REV -gt 0 ] || ( echo "ERROR: svn export failed to detect revision (got \"${REV}\")" && exit 1 )

mv $t/${NAME} $t/${DIR}			# rename directory to add release and rev
pushd $t				# save current directory and move to tempory dir
tar -czf ${TAR} ${DIR}			# zip the files
rm -r ${DIR}				# remove project files
popd
mv $t/${TAR} ./${TAR}			# move tar file to working directory
echo "${TAR} built"
rmdir $t				# remove temp directory
