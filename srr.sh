#!/usr/bin/env bash

pid=$$
date=`date +%Y%m%d-%H%M`; datesek=`date +%S`
[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /usr/local/etc/srsr.conf
ver=2.5.2

show_usage() {
  echo "srr.sh($ver): Streaming-radio dump script"
  echo '  -c <ch>         Record channel'
  echo '                   AFN AG NHK1 NHK2 NHKFM and radiko'
  echo "                   omitted: $SRR_OMCH"
  echo '  -C <url>        Other channel'
  echo '  -f <codec>      Other channel codec'
  echo '                   Omitted: wma'
  echo '  -t <min>        Duration'
  echo '                   0: Auto set min to next prog'
  echo "                   Omitted: ${SRR_OMDURATION}-minutes"
  echo '  -o <dir/name>   Output directory/filename'
  echo "                   Default: $SRSR_OUTDIR/ch_Ymd-HM"
  echo '  -i              Info to file'
  echo '                   need: getwtt-2.2.5.sh or later'
  echo '  -M              set date -1day and 00-05 to 24-29'
  echo '  -m              Memo, output stdout(and infofile)'
  echo '  -T (-c <ch>)    test'
  echo '  -h              help'
  echo 'Examples:'
  echo '  srr.sh -c radiko   = Error, view channel list'
  echo '  srr.sh -c AG -t 32 = To record a 32-minutes Chou!A&G+'
  echo '  srr.sh -C mmsh://hdv3.nkansai.tv/kiritampo -f wma -t 32'
  echo '                     = To record a 32-minutes Kiritampo FM'
}

echo $pid $0 $*
# get option
while getopts :c:C:f:rt:o:iMm:Th option
do
  case $option in
    c)
    option_c=on
    if [[ "$OPTARG" = -[rtoimT] ]]; then
      echo "[error] -c option: requeires channel, using default($SRR_OMCH)"
      optarg_c=$SRR_OMCH
    else
      optarg_c=${OPTARG^^}
    fi
    ;;
    C)
    option_C=on
    optarg_C=$OPTARG
    optarg_c=${optarg_C%%:*}
    ;;
    f)
    option_f=on
    optarg_f=$OPTARG
    ;;
    r)
    option_r=on
    ;;
    t)
    option_t=on
    expr ${OPTARG%.*} + 1 >/dev/null 2>&1
    if [[ $? -ge 2 || `echo $OPTARG | grep '^-'` ]]; then
      echo "$pid [error] -t option: not numeric, using default(${SRR_OMDURATION}-minutes)"
      optarg_t=$(($SRR_OMDURATION * 60))
    elif [ "$OPTARG" = 0 ]; then
      optarg_t=zero
    else
      optarg_t=`echo "scale=1; $OPTARG * 60" | bc`
    fi
    end_resume=`date "-d +${optarg_t}sec" '+%s'`
    ;;
    o)
    option_o=on
    optarg_o=$OPTARG
    ;;
    i)
    option_i=on
    ;;
    M)
    [[ `date +%-H` -le 5 ]] && option_M=on && date=`date -d -1day +%Y%m%d`'-'$((10#`date +%H%M` + 2400))
    ;;
    m)
    option_m=on
    optarg_m=$OPTARG
    ;;
    :)
    optarg_c=${optarg_c:-$SRR_OMCH}
    optarg_t=${optarg_t:-$((SRR_OMDURATION * 60))}
    ;;
    T)
    option_T=on
    [ ! "$option_c" ] && option_c=on && optarg_c=$SRR_OMCH
    option_t=on; optarg_t=180; option_i=on
    ;;
    h|*)
    show_usage
    exit 0
    ;;
  esac
done
# no options
if [ "$OPTIND" = "1" ]; then
  optarg_c=$SRR_OMCH
  optarg_t=$((SRR_OMDURATION * 60))
  option_i=on
  echo '[error] no options, instead of using default'
  echo "$pid $0 -c $optarg_c -t $SRR_OMDURATION -i"
# no -t option
elif [ ! "$option_t" ]; then
  optarg_t=$((SRR_OMDURATION * 60))
  echo '[error] -t option: requeires duration, instead of using default'
  echo "$pid $0 $* $SRR_OMDURATION"
fi
# no -f option
[ "$option_C" -a ! "$optarg_f" ] && optarg_f=wma
# -i option error
if [[ $option_i && `echo "scale=1; $optarg_t < 180" | bc` != 0 && ! -f $SRSR_TMPDIR/$optarg_c'_RESUME.txt' && $optarg_c =~ [^AFN|http|mms|mmsh] ]]; then
  echo '[warning] -i option: duration does not work 3-minutes or less'
  unset option_i
fi
# -T option echo
[ "$option_T" ] && echo "($pid $0 -c $optarg_c -t $(($optarg_t / 60)) -i)"
# getwtt version check
[[ `$SRSR_BINDIR/getwtt.sh -h | tr -d '.' | grep -o [0-9]*` -lt '242' ]] && echo '[warning] -i option: request getwtt.sh version 2.4.2 or later' && unset option_i

# dump stream
case $optarg_c in
  http|https|mms|mmsh)
  case ${optarg_C%%.*} in
    'http://musicbird-hls')
    optarg_c=`echo $optarg_C | grep -o 'JCB[0-9]*'`
    ;;
    'http://mtist')
    optarg_c='LISTEN'`echo $optarg_C | grep -Po '(?<=jp/)[0-9]+(?=/livestream)'`
    ;;
    *)
    optarg_c=${optarg_C##*/}; optarg_c=${optarg_c^^}
    ;;
  esac
  case $optarg_f in
    aac|m4a)
    optarg_f=(ts m4a)
    ;;
    *)
    optarg_f=($optarg_f $optarg_f)
    ;;
  esac
  if [ "$optarg_t" = 'zero' ]; then
    # omduration
    #echo "$pid [error] can not get timetable, using default(${SRR_OMDURATION}-minutes)"
    #optarg_t=$(($SRR_OMDURATION * 60))
    # next hour
    echo "$pid [error] can not get timetable, set min to next hour"
    datedonehour=`date -d 1hour +'%Y%m%d %H00' | xargs -I@ date -d @ +%s`
    optarg_t=$(($datedonehour - `date +%s` + 60))
  fi
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` start"
  ffmpeg -i $optarg_C -t $optarg_t -loglevel error -acodec copy -vcodec copy $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}"
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` stop"
  ;;
  AFN)
  http="http://20073.live.streamtheworld.com/AFNP_TKOAAC"
  [[ `echo $http | grep -Po '(?<=//).+(?=/)' | xargs -IURL ping -q -c1 URL 2>&1 | grep -o 'unknown host'` ]] && echo "[error] afn url($http) changed, exit" && exit 1
  optarg_f=(flv m4a)
  if [ "$optarg_t" = 'zero' ]; then
    # omduration
    #echo "$pid [error] can not get timetable, using default(${SRR_OMDURATION}-minutes)"
    #optarg_t=$(($SRR_OMDURATION * 60))
    # next hour
    echo "$pid [error] can not get timetable, set min to next hour"
    datedonehour=`date -d 1hour +'%Y%m%d %H00' | xargs -I@ date -d @ +%s`
    optarg_t=$(($datedonehour - `date +%s` + 150))
  fi
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` start"
  mplayer -dumpstream -dumpfile $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}" $http -really-quiet &
  for dummy in `seq 0 $optarg_t`
  do
    [[ `ps x | grep $optarg_c$pid | grep -v grep` ]] && sleep 1 || break
  done
  kill `ps x | grep -v grep | grep $optarg_c$pid | awk '{print $1}'` >/dev/null 2>&1
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` stop"
  ;;
  AG|AG-S)
  [ -f $SRSR_TMPDIR/ag_url_rtmp ] && rtmp=`cat $SRSR_TMPDIR/ag_url_rtmp` || rtmp='rtmp://fms-base2.mitene.ad.jp/agqr/aandg1'
  # notfound check
  if [[ ! `rtmpdump -q -r $rtmp --live --stop 0.2` ]]; then
    echo "$pid [error] `date '+%m-%d %H:%M:%S'` not found url=$rtmp"
# hostnumber search
for basenum in {1..2}
do
rtmp=rtmp://fms-base${basenum}.mitene.ad.jp/agqr/aandg
for hostnum in {1..99}
do
[[ `rtmpdump -q -r $rtmp${hostnum} --live --stop 0.2` ]] && rtmp=$rtmp${hostnum} && continue 2
[[ `rtmpdump -q -r $rtmp${hostnum}b --live --stop 0.2` ]] && rtmp=$rtmp${hostnum}b && continue 2
[[ $basenum = 2 && $hostnum = 99 ]] && unset rtmp
done
done << END
:
END
    if [ $rtmp ]; then
      echo "$pid [warning] `date '+%m-%d %H:%M:%S'` new url=$rtmp"
      echo $rtmp >$SRSR_TMPDIR/ag_url_rtmp
    else
      echo "$pid [error] `date '+%m-%d %H:%M:%S'` give up rtmp url search, change to hls url"
      m3u8=http://ic-www.uniqueradio.jp/iphone/3G.m3u8
    fi
  fi
  opttzero() {
    $SRSR_BINDIR/mkagtt.sh -b
    ttjetz=`cat $SRSR_TMPDIR/tt_AG_\`date +%a\` | grep -E -o [0-9]{12}`
    jetz=`date -d 2min +%Y%m%d%H%M`
    amtagzunach=`date -d 1day +%Y%m%d%H%M`
    until [[ `echo "$ttjetz" | grep $jetz` ]]
    do
      [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($jetz + 1)) || jetz=$(($jetz + 40))
      [[ $((10#${jetz:8:2})) -ge 24 ]] && jetz=`date -d 1day +%Y%m%d0000`
      # endless loop exit
      [[ $jetz -gt $amtagzunach ]] && optarg_t=$(($SRSR_OMDURATION * 60))
    done
  }
  # not found mkagtt.sh
  [[ $optarg_t = 'zero' && ! -f $SRSR_BINDIR/mkagtt.sh ]] && echo "$pid [error] request mkagtt.sh, using default(${SRR_OMDURATION}-minutes)" && optarg_t=$(($SRR_OMDURATION * 60))
  if [ "$optarg_t" = 'zero' ]; then
    opttzero
    nexttime=`date -d "\`echo $jetz | perl -pe 's/([0-9]{8})([0-9]{4})/$1 $2/'\`" +%s`
    optarg_t=$(($nexttime - `date +%s` + 60))
  fi
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` start"
  if [ $rtmp ]; then
    [ "$optarg_c" = 'AG' ] && optarg_f=(flv flv) || optarg_f=(flv m4a)
    rtmpdump -q -r $rtmp --live --stop $optarg_t -o $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}"
  else
    [ "$optarg_c" = 'AG' ] && optarg_f=(ts ts) || optarg_f=(ts m4a)
    while :
    do
      ffmpeg -i $m3u8 -movflags faststart -t $optarg_t -loglevel error -acodec copy -vcodec copy $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}"
      [[ $? = 0 ]] && break
    done
  fi
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` stop"
  if [ $option_i ]; then
    $SRSR_BINDIR/getwtt.sh --proginfo $optarg_c `echo "$optarg_t / 60" | bc | sed 's/\..*//'` >$SRSR_TMPDIR/$optarg_c$pid'.txt'
    # timetable changed
    [[ `grep -c '' $SRSR_TMPDIR/$optarg_c$pid'.txt'` = 1 ]] && rm $SRSR_TMPDIR/$optarg_c$pid'.txt'
  fi
  ;;
  NHK|NHK1|NHK2|NHKFM)
  [ "$optarg_c" = 'NHK' ] && echo "$pid [error] not found channel=NHK. set to NHK1" && optarg_c=NHK1
  optarg_f=(ts m4a)
  opttzero() {
    nexttimes=(`curl -s 'http://www2.nhk.or.jp/hensei/api/noa.cgi?c=1' | sed -n -E '/<ch>(r1|r2|fm)/,/<\/item>/p' | grep -Po '(?<=<starttime>).+(?=<)'`)
  }
  case $optarg_c in
    NHK1)
    m3u8=https://nhkradioakr1-i.akamaihd.net/hls/live/511633/1-r1/1-r1-01.m3u8
    if [ "$optarg_t" = 'zero' ]; then
      opttzero
      nexttime=`date -d "${nexttimes[3]} ${nexttimes[4]}" +%s`
      optarg_t=$(($nexttime - `date +%s` + 120))
    fi
    ;;
    NHK2)
    m3u8=https://nhkradioakr2-i.akamaihd.net/hls/live/511929/1-r2/1-r2-01.m3u8
    if [ "$optarg_t" = 'zero' ]; then
      opttzero
      nexttime=`date -d "${nexttimes[6]} ${nexttimes[7]}" +%s`
      optarg_t=$(($nexttime - `date +%s` + 120))
    fi
    ;;
    NHKFM)
    m3u8=https://nhkradioakfm-i.akamaihd.net/hls/live/512290/1-fm/1-fm-01.m3u8
    if [ "$optarg_t" = 'zero' ]; then
      opttzero
      nexttime=`date -d "${nexttimes[10]} ${nexttimes[11]}" +%s`
      optarg_t=$(($nexttime - `date +%s` + 120))
    fi
    ;;
  esac
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` start"
  ffmpeg -i $m3u8 -movflags faststart -t $optarg_t -loglevel error -acodec copy -vn $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}"
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` stop"
  [ $option_i ] && $SRSR_BINDIR/getwtt.sh --proginfo $optarg_c `echo "$optarg_t / 60" | bc | sed 's/\..*//'` >$SRSR_TMPDIR/$optarg_c$pid'.txt'
  ;;
  *)
  # radiko
  source $SRSR_BINDIR/authkey.sh
  optarg_f=(ts m4a)
  # get stream-url
  wget -q -O ${ch_xml} "http://radiko.jp/v2/station/stream/$optarg_c.xml"
  # Record
  stream_url=`echo "cat /url/item[1]/text()" | xmllint --shell ${ch_xml} | tail -2 | head -1`
  m3u8=`echo ${stream_url} | perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!http://$2/$3/$4/playlist.m3u8!'`
  rm -f ${ch_xml}
  opttzero() {
    nexttimes=(`curl -s http://radiko.jp/v2/api/program/now?area_id=$areaid | sed -n "/id=\"$optarg_c/,/<prog ft/p" | grep -E '(date|prog ft)' | grep -o [0-9]*`)
  }
  if [ "$optarg_t" = 'zero' ]; then
    opttzero
    nexttime=`date -d "${nexttimes[0]} ${nexttimes[4]}" +%s`
    optarg_t=$(($nexttime - `date +%s` + 60))
  fi
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` start"
  ffmpeg -headers "X-Radiko-AuthToken: $authtoken" -i $m3u8 -movflags faststart -t $optarg_t -loglevel quiet -acodec copy -vn $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}"
  echo "$pid [rec] `date '+%m-%d %H:%M:%S'` stop"
  # programinfo
  if [ $option_i ]; then
    # proginfo
    $SRSR_BINDIR/getwtt.sh --proginfo $optarg_c `echo "$optarg_t / 60" | bc | sed 's/\..*//'` >$SRSR_TMPDIR/$optarg_c$pid'.txt'
    # musikinfo
    $SRSR_BINDIR/mskinfo.sh --proginfo $optarg_c `echo "$optarg_t / 60" | bc | sed 's/\..*//'` | perl -pe 's/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3 $4:$5:$6/' >>$SRSR_TMPDIR/$optarg_c$pid'.txt'
  fi
  ;;
esac

# not found ch
if [ ! -f $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}" ]; then
  echo "[error] not found channel=$optarg_c"
  echo ' AFN'
  echo ' AG(sound only rec:AG-S)'
  echo ' NHK1 NHK2 NHKFM'
  echo "radiko($areaid):"
  curl -s http://radiko.jp/v2/station/list/$areaid.xml | grep -Po '(?<=<id>).+(?=</id>)' | perl -0pe 's/^/ /gm; s/\n / /gm'
  echo 'help: -h'
  rm -f ${ch_xml}
  exit 1
fi

# resume
[ ! -f $SRSR_TMPDIR/$optarg_c'_'$date".${optarg_f[0]}" ] && unset datesek
now_resume=`date +%s`
if [ "$(($now_resume + 10))" -lt "$end_resume" ]; then
  recresume=on
  echo "$pid [error] `date '+%m-%d %H:%M:%S'` $optarg_c disconnect, resume..."
  remdur=$(($end_resume - $now_resume))
  [ $option_i ] && opt_i='-i'
  [ $option_o ] && opt_o="-o $optarg_o"
  [ ! $option_C ] && chcmd="-c $optarg_c" || chcmd="-C $optarg_C -f $optarg_f"
  eval $0 $chcmd -t `echo "scale=1; $remdur / 60" | bc` $opt_i $opt_o &
  echo "file $SRSR_TMPDIR/${optarg_c}_${date}${datesek}.${optarg_f[0]}" >>$SRSR_TMPDIR/$optarg_c'_RESUME.txt'
fi

# move file
mv --backup=t $SRSR_TMPDIR/$optarg_c$pid".${optarg_f[0]}" $SRSR_TMPDIR/$optarg_c'_'$date$datesek".${optarg_f[0]}"
if [ -f $SRSR_TMPDIR/$optarg_c'_'$date$datesek.* ]; then
  feilname=$optarg_c'_'$date$datesek".${optarg_f[1]}"
  if [ $option_o ]; then
    SRSR_OUTDIR=$optarg_o
    if [[ ${SRSR_OUTDIR: -4} =~ .${optarg_f[1]} ]]; then
      feilname=${optarg_o##*/}
      SRSR_OUTDIR=${SRSR_OUTDIR%/*}
    fi
    [ "$SRSR_OUTDIR" = "$feilname" ] && SRSR_OUTDIR=./
    [ ! -e $SRSR_OUTDIR ] && mkdir -p $SRSR_OUTDIR
    [ -e $SRSR_OUTDIR/$feilname ] && feilname=`echo $feilname | sed "s/.${optarg_f[1]}/.$pid.${optarg_f[1]}/"`
  fi
  case ${optarg_f[1]} in
    flv|ts)
    vc='-vcodec copy'
    ;;
    m4a)
    ac='-bsf:a aac_adtstoasc'
    vc='-vn'
    ;;
  esac
  [[ $option_o && $recresume ]] && feilname=${feilname%.*}".${date}${datesek}."${feilname#*.}
  ffmpeg -i $SRSR_TMPDIR/$optarg_c'_'$date$datesek.* -loglevel error -acodec copy $ac $vc $SRSR_OUTDIR/$feilname
fi

# resume concat
if [[ ! $recresume && -f $SRSR_TMPDIR/$optarg_c'_RESUME.txt' ]]; then
  sectohms() {
    # sec to hour:min:sec
    # https://qiita.com/hryshtk/items/fc46b2e2d8c13016e0d4
    reshead=0; restail=$berespnt
    diff=$((restail - reshead))
    let hour="$diff / 3600"; let diff="$diff % 3600"; hour=`printf "%02d\n" $hour`
    let min="$diff / 60"; min=`printf "%02d\n" $min`
    let sec="$diff % 60"; sec=`printf "%02d\n" $sec`
    echo "${hour}:${min}:${sec}"
  }
  echo "file $SRSR_TMPDIR/${optarg_c}_${date}${datesek}.${optarg_f[0]}" >>$SRSR_TMPDIR/$optarg_c'_RESUME.txt'
  [ ! $option_o ] && feilname=`head -1 $SRSR_TMPDIR/$optarg_c'_RESUME.txt' | grep -Po "(?<=$SRSR_TMPDIR/).+(?=.${optarg_f[0]})" | xargs -IBN echo "BN.${optarg_f[1]}"`
  ffmpeg -f concat -safe 0 -i $SRSR_TMPDIR/$optarg_c'_RESUME.txt' -loglevel error -acodec copy $ac $vc $SRSR_OUTDIR/${feilname%.*}"_RESUME.${feilname#*.}"
  respnt=(`grep -Po '(?<=file ).+' $SRSR_TMPDIR/$optarg_c'_RESUME.txt' | xargs -IFILE ffmpeg -i FILE 2>&1 | grep -Po "(?<=Duration: ).+?(?=\.[0-9]{2})" | tr ':' ' ' | sed '$d'`)
  berespnt=`echo "${respnt[0]} ${respnt[1]} ${respnt[2]}" | awk '{print $1*60*60 + $2*60 + $3}'`
  respnthms="resume point: `sectohms`"
  echo "$pid [warning] $respnthms"
  echo ${respnthms^^} >$SRSR_TMPDIR/$optarg_c'_RESUMEHMS.txt'
  if [ "${#respnt[@]}" -ge 4 ]; then
    for rp in `seq 3 3 $((${#respnt[@]} - 1))`
    do
      narespnt=`echo "${respnt[$rp]} ${respnt[$(($rp + 1))]} ${respnt[$(($rp + 2))]}" | awk '{print $1*60*60 + $2*60 + $3}'`
      berespnt=$(($berespnt + $narespnt))
      respnthms="resume point: `sectohms`"
      echo "$pid [warning] $respnthms"
      echo ${respnthms^^} >>$SRSR_TMPDIR/$optarg_c'_RESUMEHMS.txt'
    done
  fi
  if [[ $option_i && ! $recresume && -f $SRSR_TMPDIR/$optarg_c'_RESUME.txt' ]]; then
    optarg_t=`ffmpeg -i $SRSR_OUTDIR/${feilname%.*}"_RESUME.${feilname#*.}" 2>&1 | grep -Po '(?<=Duration: ).+?(?=\.[0-9]{2})' | awk -F : '{print ($1*60*60) + ($2*60) + $3}'`
    $SRSR_BINDIR/getwtt.sh --proginfo $optarg_c $(($optarg_t / 60)) | ${NKF/ --euc} >$SRSR_OUTDIR/${feilname%.*}'_RESUME.txt'
    if [[ ! $optarg_C && $optarg_c =~ [^AFN|AG|AG-S|NHK(1|2|FM)] ]]; then
      $SRSR_BINDIR/mskinfo.sh --proginfo $optarg_c $(($optarg_t / 60)) | perl -pe 's/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/$1-$2-$3 $4:$5:$6/' | ${NKF/ --euc} >>$SRSR_OUTDIR/${feilname%.*}'_RESUME.txt'
    fi
    (echo; cat $SRSR_TMPDIR/$optarg_c'_RESUMEHMS.txt') >>$SRSR_OUTDIR/${feilname%.*}'_RESUME.txt'
  fi
  rm $SRSR_TMPDIR/${optarg_c}_{RESUME,RESUMEHMS}.txt
fi

# memo
if [ "$optarg_m" ]; then
  echo -e "$pid memo: $optarg_m"
  [ "$option_i" ] && echo -e "\nmemo: $optarg_m" >>$SRSR_TMPDIR/$optarg_c$pid'.txt'
fi

# logfile
if [ -f $SRSR_TMPDIR/$optarg_c$pid'.txt' ]; then
  [ $option_M ] && perl -i -pe "s/`date +%Y%m%d`/${date%-*}/; s/ ([0-9]{2})/\$1+24/e; s/^([0-9]{8})([0-9]{4})/\$1 \$2/; s/^`date +%Y-%m-%d`/${date%-*}/; s/^([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2}:)/\$1-\$2-\$3 \$4/" $SRSR_TMPDIR/$optarg_c$pid'.txt'
  ${NKF/ --euc} $SRSR_TMPDIR/$optarg_c$pid'.txt' >$SRSR_OUTDIR/${feilname%.*}'.txt'
  if [ "$optarg_c" = "AG-S" ]; then
    ffmpeg -ss 00:01:00 -i $SRSR_TMPDIR/$optarg_c'_'$date$datesek".${optarg_f[0]}" -loglevel error -vframes 1 -f image2 $SRSR_OUTDIR/${feilname%.*}'.jpg'
    [ "$recresume" -a -f $SRSR_OUTDIR/${feilname%.*}'.jpg' ] && cp --backup=t $SRSR_OUTDIR/${feilname%.*}'.jpg' $SRSR_OUTDIR/${feilname%.*}'_RESUME.jpg'
  fi
  mv $SRSR_TMPDIR/$optarg_c$pid'.txt' $SRSR_TMPDIR/$optarg_c'_'$date$datesek'.txt'
fi

