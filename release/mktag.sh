#! /bin/sh -

cd `dirname $0`/..
REPOS=svn+ssh://yquem.inria.fr/home/yquem/moscova/maranget/repos
VERSIONFILE=version.ml
VERSION=`sed -n -e 's/^let real_version = "\(.*\)".*$/\1/p' ${VERSIONFILE}`
DATE=`date +%Y-%m-%d`
echo DATE=$DATE
echo VERSION=${VERSION}
case $VERSION in
  *+*)
     echo DEV=true
     echo RELEASENAME=hevea-\${DATE}
     ;;  
    *)
    echo DEV=false 
    echo RELEASENAME=hevea-\${VERSION}
   ;;
esac


TMP=/tmp/tag.$$
RELEASETAG=`sed -n -e 's/^let real_version = "\(.\)\.\(.*\)".*$/\1-\2/p' ${VERSIONFILE}`
echo RELEASETAG=$RELEASETAG
echo CVSEXPORT=\"-r release-\${RELEASETAG}\"
sed  -e "s/^let release_date = .*/let release_date = \"$DATE\"/" ${VERSIONFILE} > $TMP && mv $TMP $VERSIONFILE
( svn commit -m tag && svn copy ${REPOS}/hevea hevea-${RELEASETAG} -m "TAG${RELEASETAG}" ) >/dev/null

