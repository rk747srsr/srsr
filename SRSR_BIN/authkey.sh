#!/usr/bin/env bash

[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /opt/radio/etc/srsr.conf

# authkey
playerurl=http://radiko.jp/apps/js/flash/myplayer-release.swf
playerfile="$SRSR_VARTMPDIR/player.swf"
keyfile="$SRSR_VARTMPDIR/authkey.jpg"
auth1_fms="$SRSR_TMPDIR/auth1_fms_$pid"
auth2_fms="$SRSR_TMPDIR/auth2_fms_$pid"
stream_url=""
url_parts=""
ch_xml="$SRSR_TMPDIR/$optarg_c$pid.xml"

# get player
if [ ! -f ${playerfile} ]; then
  wget -q -O ${playerfile} ${playerurl}
  if [ $? -ne 0 ]; then
    echo "[stop] failed get player (${playerfile})" 1>&2
    exit 1
  fi
fi

# get keydata (need swftool)
if [ ! -f ${keyfile} ]; then
  swfextract -b 12 ${playerfile} -o ${keyfile}
  if [ ! -f ${keyfile} ]; then
    echo "[stop] failed get keydata (${keyfile})" 1>&2
    exit 1
  fi
fi

# access auth1_fms
wget -q --header="pragma: no-cache" --header="X-Radiko-App: pc_ts" --header="X-Radiko-App-Version: 4.0.0" --header="X-Radiko-User: test-stream" --header="X-Radiko-Device: pc" --post-data='\r\n' --no-check-certificate --save-headers -O ${auth1_fms} https://radiko.jp/v2/api/auth1_fms
if [ $? -ne 0 ]; then
  echo "[stop] failed auth1 process (${auth1_fms})" 1>&2
  exit 1
fi

# get partial key
authtoken=`perl -ne 'print $1 if(/x-radiko-authtoken: ([\w-]+)/i)' ${auth1_fms}`
offset=`perl -ne 'print $1 if(/x-radiko-keyoffset: (\d+)/i)' ${auth1_fms}`
length=`perl -ne 'print $1 if(/x-radiko-keylength: (\d+)/i)' ${auth1_fms}`
partialkey=`dd if=${keyfile} bs=1 skip=${offset} count=${length} 2> /dev/null | base64`
rm -f ${auth1_fms}

# access auth2_fms
wget -q --header="pragma: no-cache" --header="X-Radiko-App: pc_ts" --header="X-Radiko-App-Version: 4.0.0" --header="X-Radiko-User: test-stream" --header="X-Radiko-Device: pc" --header="X-Radiko-Authtoken: ${authtoken}" --header="X-Radiko-Partialkey: ${partialkey}" --post-data='\r\n' --no-check-certificate -O ${auth2_fms} https://radiko.jp/v2/api/auth2_fms
if [ $? -ne 0 -o ! -f ${auth2_fms} ]; then
  echo "[stop] failed auth2 process (${auth2_fms})" 1>&2
  exit 1
fi

areaid=`perl -ne 'print $1 if(/^([^,]+),/i)' ${auth2_fms}`
rm -f ${auth2_fms}

