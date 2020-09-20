#!/usr/bin/env bash

[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /opt/radio/etc/srsr.conf

usage() {
  echo 'mskinfo.sh: radiko.jp playlist script'
  echo '  -k <ch>                now play'
  echo 'For srr.sh option:'
  echo '  --proginfo <ch> <min>  play list'
  echo 'Other:'
  echo '  -h                     help'
}
[[ ! $1 || $1 =~ '-h' ]] && usage && exit 0

msk=`curl -s http://radiko.jp/v2/station/feed_PC/${2^^}.xml`

case $1 in
  -k)
  artist=`echo "$msk" | grep -Po '(?<=artist=").+(?=" evid)' | head -1`
  title=`echo "$msk" | grep -Po '(?<=title=").+(?=" type)' | head -1`
  [ "$artist" ] && echo "$title / $artist" | XMLER | $NKF
  ;;
  --proginfo)
  case $2 in
    *)
    if [ "`echo $msk | grep T[0-9][0-9]:`" ]; then
      IFS_DEFAULT=$IFS; IFS=$'\n'
      datehf=$3
      until echo "$msk" | grep `date -d -${datehf}min +T%H:%M` >/dev/null
      do
        datehf=$((datehf - 1))
      done
      msk=`echo "$msk" | sed -n "1,/\`date -d -${datehf}min +T%H:%M\`/p"`
      mskstamp=(`echo "$msk" | tac | grep -Po '(?<=stamp=").+(?=" title)' | tr -d 'T:-'`)
      mskartist=(`echo "$msk" | tac | grep -Po '(?<=artist=").+(?=" evid)'`)
      msktitle=(`echo "$msk" | tac | grep -Po '(?<=title=").+(?=" type)'`)
      IFS=$IFS_DEFAULT
      echo
      echo ${mskstamp[0]} - ${msktitle[0]} / ${mskartist[0]}
      for msksta in `seq ${#mskstamp[*]}`
      do
        echo "${mskstamp[$msksta]} - ${msktitle[$msksta]} / ${mskartist[$msksta]}"
      done | sed -e '$d'
    fi
    ;;
  esac
  ;;
  *)
  usage
  ;;
esac

