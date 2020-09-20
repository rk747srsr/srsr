#!/usr/bin/env bash

[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /opt/radio/etc/srsr.conf
source $SRSR_BINDIR/authkey.sh

rp=8  # retentionperiod

http='http://radiko.jp/v2/api/program/today?area_id='

if [ ! -f $SRSR_VARTMPDIR/tt_${areaid}_past ]; then
  wget -q $http$areaid -O $SRSR_VARTMPDIR/tt_${areaid}_past
  echo "mkttpast.sh: cleate $SRSR_VARTMPDIR/tt_${areaid}_past"
elif [[ ! `grep ">\`date +%Y%m%d\`<" $SRSR_VARTMPDIR/tt_${areaid}_past` && `curl -s $http$areaid | grep -Po '(?<=date>).+(?=</date)' | head -1` =~ `date +%Y%m%d` ]]; then
  (echo; curl -s $http$areaid) >>$SRSR_VARTMPDIR/tt_${areaid}_past
  if [ "`grep -c '</radiko>' $SRSR_VARTMPDIR/tt_${areaid}_past`" -gt "$rp" ]; then
    eval $SEDI "1,`sed -n '/<\/radiko>/=' $SRSR_VARTMPDIR/tt_${areaid}_past | head -1`d" $SRSR_VARTMPDIR/tt_${areaid}_past
  fi
  echo "mkttpast.sh: update tt_${areaid}_past(`grep -c '</radiko' $SRSR_VARTMPDIR/tt_${areaid}_past`)"
else
  echo "`date +'%Y-%m-%d %H:%M:%S'` mkttpast.sh: no update"
fi

