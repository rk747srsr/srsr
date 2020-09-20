#!/usr/bin/env bash

pid=$$
srsr_tmpdir=/var/radio/spool
srsr_vartmpdir=/var/radio
srsr_outdir=$HOME/Music/radio
rp=8  # for -U, retentionperiod
nkf='nkf -m0 -Z1 --euc -Lu'
ver=1.0

usage() {
  echo "timefree-dl.sh($ver): timefree and kikinogashi download script"
  echo '  <ch> <ft> (tt)    timefree download'
  echo '  NHK <id> <ft>     kikinogashi download'
  echo '  -l <ch|NHK (id)>  list'
  ecoh '  -U                radiko cache update'
  echo '  -h                help'
}

[[ ! $1 || $1 =~ '-h' ]] && usage && exit 0

authkey() {
  # authkey
  playerurl=http://radiko.jp/apps/js/flash/myplayer-release.swf
  playerfile="$srsr_vartmpdir/player.swf"
  keyfile="$srsr_vartmpdir/authkey.jpg"
  auth1_fms="$srsr_tmpdir/auth1_fms_$pid"
  auth2_fms="$srsr_tmpdir/auth2_fms_$pid"
  stream_url=""
  url_parts=""
  ch_xml="$srsr_tmpdir/$optarg_c$pid.xml"
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
}

case $1 in
  # radiko cache update
  -U)
  authkey
  http='http://radiko.jp/v2/api/program/today?area_id='
  if [ ! -f $srsr_vartmpdir/tt_${areaid}_past ]; then
    wget -q $http$areaid -O $srsr_vartmpdir/tt_${areaid}_past
    echo "timefree-dl.sh: cleate $srsr_vartmpdir/tt_${areaid}_past"
  elif [[ ! `grep ">\`date +%Y%m%d\`<" $srsr_vartmpdir/tt_${areaid}_past` && `curl -s $http$areaid | grep -Po '(?<=date>).+(?=</date)' | head -1` =~ `date +%Y%m%d` ]]; then
    (echo; curl -s $http$areaid) >>$srsr_vartmpdir/tt_${areaid}_past
    if [ "`grep -c '</radiko>' $srsr_vartmpdir/tt_${areaid}_past`" -gt "$rp" ]; then
      sed -i '' "1,`sed -n '/<\/radiko>/=' $srsr_vartmpdir/tt_${areaid}_past | head -1`d" $srsr_vartmpdir/tt_${areaid}_past
    fi
  echo "timefree-dl.sh: update tt_${areaid}_past(`grep -c '</radiko' $srsr_vartmpdir/tt_${areaid}_past`)"
  else
    echo "`date +'%Y-%m-%d %H:%M:%S'` timefree-dl.sh: no update radiko cache"
  fi
  ;;
  # list
  -l*)
  if [ $2 ]; then
    optarg_c=${2^^}
  else
    if [ "${#1}" -gt 2 ]; then
      optarg_c=${1: 2}
      optarg_c=${optarg_c^^}
    else
      echo "$0 -s <ch>"
      exit 1
    fi
  fi
  case $optarg_c in
    # list nhk
    NHK*)
    tt=$(curl -s 'http://www.nhk.or.jp/radioondemand/json/index/index.json' | perl -pe 's/\\u([0-9a-fA-F]{4})/chr(hex($1))/eg; s/({"site_id)/\n\n($1)/g' 2>/dev/null | tr -d '\\')
    if [ ! $3 ]; then
      case $optarg_c in
        NHK1)
        chfilter='media_code":"05'
        ;;
        NHK2)
        chfilter='media_code":"06'
        ;;
        NHKFM)
        chfilter='media_code.*07"'
        ;;
        *)
        chfilter='media_code'
        ;;
      esac
      echo "$tt" | grep $chfilter | perl -pe 's/,/\n/g' | sed -n -E '/(site_id|program_name|onair_date)/s/(^.*:|")//gp' | tac | perl -pe 's/([0-9]$)/$1\n/' | $nkf
    else
      echo "$tt" | grep "/$3/" | grep -Po '(?<=_json":").+?(?=",")' | xargs -I{} curl -s {} | perl -pe 's/(,|})/\n/g' | sed -n -E '/(onair_date|title"|aa_vinfo(1|4)|file_id)/p' | sed '/file_id/s/.*//' | sed -E '/vinfo4/s/(\+.*|T|:|-)//g; s/(^.*(:"|"")|"$)//g' | sed 1d | tac | $nkf
    fi
    ;;
    # list radiko
    *)
    authkey
    prevproget() {
      jetz=`date +%Y%m%d%H%M`
      until echo "$tt" | grep "to=\"$jetz" >/dev/null
      do
        jetz=$(($jetz - 1))
      done
      timefreetail=`echo "$tt" | sed -n "/to=\"$jetz/="`
    }
    if [ "`(grep -c '</radiko>' $srsr_vartmpdir/tt_${areaid}_past) 2>/dev/null`" -ge 7 ]; then
      # use cache
      tt=`sed -n "/station id=\"$optarg_c/,/<\/station/p" $srsr_vartmpdir/tt_${areaid}_past`
      prevproget
      tt=`echo "$tt" | sed -n "1,$(($timefreetail + 2))p" | sed -n -E "/(station id|prog ft|title)/s/(^[ ]*|<|prog ft|ftl.*|[a-z_=\"]*|\/|>)//gp" | sed '1,$s/ '$optarg_c'/ station&/' | sed -n "/ station $optarg_c/,/^ [A-Z]/p" | grep -v '^ [sA-Z]'`
    # use weekly
    else
      tt=`curl -s http://radiko.jp/v2/api/program/station/weekly?station_id=$optarg_c`
      prevproget
      tt=`echo "$tt" | sed -n "1,$(($timefreetail + 2))p" | sed -n -E "/(prog ft|title)/s/(^[ ]*|<|prog ft|ftl.*|[a-z_=\"]*|\/|>)//gp"`
    fi
    echo "$tt" | $nkf
    ;;
  esac
  exit 0
  ;;
  # download
  *)
  [ "$1" = '-c' ] && shift $OPTIND
  optarg_c=${1^^}
  case $optarg_c in
    # download nhk
    NHK*)
    optarg_id=$2
    optarg_ft=$3; [ "$optarg_ft" = '99999999999999' ] && unset optarg_ft
    [ "${#optarg_ft}" -le 12 ] && optarg_ft="${optarg_ft}00"
    [ "$optarg_ft" -gt "`date +%Y%m%d%H%M`00" ] && echo "[error] don't back to the future, exit" && exit 1
    #[ "$optarg_ft" -gt "`date +%Y%m%d%H%M`00" -a "$optarg_ft" != '99999999999999' ] && echo "[error] don't back to the future, exit" && exit 1
    gettt() {
      tt=$(echo "$progjson" | grep $timefree_url | perl -pe 's/,/\n/g' | sed -n -E '/(onair_date|vinfo1|title)"/p' | grep -Po '(?<=:").+(?=")' | tac)
    }
    # get progpage
    progjson=$(curl -s 'http://www.nhk.or.jp/radioondemand/json/index/index.json' | perl -pe 's/\\u([0-9a-fA-F]{4})/chr(hex($1))/eg; s/({"site_id)/\n\n($1)/g' 2>/dev/null | tr -d '\\' | grep $optarg_id | grep -Po '(?<=_json":").+?(?=",")' | xargs -I{} curl -s {} | tr -d '\\' | perl -pe 's/,("file_id)/($1)\n\n/g')
    if [ "$optarg_ft" = '00' ]; then
      timefree_url=$(echo "$progjson" | grep -o https.*m3u8 | head -1)
      date=($(echo "$progjson" | tr ',' '\n' | sed -n '/onair_date/s/[^0-9]//gp')); date=${date[0]}
      time=$(echo "$progjson" | tr ',' '\n' | nkf -Z1 | sed -n '/schedule":"/s/[^0-9 ]//gp' | grep -Po '(?<= )[0-9]{4}')
      optarg_ft="${date}-${time}00"
    else
      timefree_url=$(echo "$progjson" | tr ',' '\n' | sed -E '/vinfo4/s/[-T:]//g; /(vinfo4|file_name)/!d; s/(^.*:"|"$)//g' | grep -B1 $optarg_ft | head -1)
    fi
    ;;
    # download radiko
    *)
    authkey
    gettt() {
      if [ "`(grep -c '</radiko>' $srsr_vartmpdir/tt_${areaid}_past) 2>/dev/null`" -ge 7 ]; then
        # use cache
        tt=`sed -n "/station id=\"$optarg_c/,/<\/station>/p" $srsr_vartmpdir/tt_${areaid}_past`
      # use radiko api weekly
      else
        tt=`curl -s http://radiko.jp/v2/api/program/station/weekly?station_id=$optarg_c`
      fi
    }
    optarg_c=${1^^}
    if [ $3 ]; then
      optarg_ft=$2; [ "${#optarg_ft}" -lt 14 ] && optarg_ft=$optarg_ft'00'
      optarg_tt=$3; [ "${#optarg_tt}" -lt 14 ] && optarg_tt=$optarg_tt'00'
    else
      gettt
      fttt=(`echo "$tt" | grep 'ft="'$2 | grep -o [0-9]*`)
      optarg_ft=${fttt[0]}
      optarg_tt=${fttt[1]}
    fi
    [ "$optarg_ft" -gt "`date +%Y%m%d%H%M`00" ] && echo "[error] don't back to the future, exit" && exit 1
    # get m3u8
    wget -q --header="pragma: no-cache" --header="Content-Type: application/x-www-form-urlencoded" --header="X-Radiko-AuthToken: ${authtoken}" --header="Referer: ${playerurl}" --post-data='flash=1' --no-check-certificate "https://radiko.jp/v2/api/ts/playlist.m3u8?l=15&station_id=$optarg_c&ft=$optarg_ft&to=$optarg_tt" -O $srsr_tmpdir/$optarg_c$pid.m3u8
    timefree_url=`grep radiko $srsr_tmpdir/$optarg_c$pid.m3u8`
    rm $srsr_tmpdir/$optarg_c$pid.m3u8
    ;;
  esac
  # get aac
  ffmpeg -i $timefree_url -movflags faststart -loglevel error -acodec copy $srsr_tmpdir/$optarg_c'_'$optarg_ft'.aac'
  # out m4a
  ffmpeg -i $srsr_tmpdir/$optarg_c'_'$optarg_ft'.aac' -loglevel error -acodec copy -bsf:a aac_adtstoasc $srsr_outdir/$optarg_c'_'$optarg_ft'.m4a'
  # proginfo
  xmler() {
    sed -E "s/&amp;nbsp;/ /g; s/&(apos|#039);/'/g; s/&(quot|#034);/\"/g; s/&(amp|#038);/\&/g; s/&lt;/</g; s/&gt;/>/g"
  }
  deltag() {
    sed -e 's/<a [^>]*>//g; s/<\/a>//g; s/<[^>]*>/'\\$'\n/g; /^[ ]*$/d; s/^[ ]*//'
  }
  gettt
  if [ "$tt" ]; then
    case $optarg_c in
      NHK*)
      echo "$tt" | xmler | deltag >$srsr_tmpdir/$optarg_c'_'$optarg_ft'.txt'
      ;;
      *)
      echo "$tt" | sed -n "/ft=\"$optarg_ft/,/<\/prog/p" | xmler | deltag | grep -v ^$ | tr -d '\t' | awk '!nosortuniq[$0]++' >$srsr_tmpdir/$optarg_c'_'$optarg_ft'.txt'
      ;;
    esac
    ${nkf/ --euc} $srsr_tmpdir/$optarg_c'_'$optarg_ft'.txt' >$srsr_outdir/$optarg_c'_'$optarg_ft'.txt'
  fi
esac

