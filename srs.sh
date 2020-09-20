#!/usr/bin/env bash

pid=$$
date=`date +%Y%m%d-%H%M`
[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /opt/radio/etc/srsr.conf
ver=2.4.2b

show_usage() {
  echo "srs.sh($ver): Streaming-radio play script"
  echo '  -c <ch>     Channel'
  echo '               AFN AG NHK1 NHK2 NHKFM and radiko'
  echo '  -C <url>    Other channel'
  echo '  -f <codec>  Other channel codec'
  echo '  -r          run srr.sh'
  echo '  -h          help'
}

# get option
while getopts :c:C:f:rt:h option
do
  case $option in
    c)
    option_c=on
    optarg_c=${OPTARG^^}
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
    :)
    optarg_c=${optarg_c:-}
    ;;
    r)
    $SRSR_BINDIR/srr.sh $*
    exit 0
    ;;
    t)
    optarg_t=$OPTARG
    ;;
    h|*)
    show_usage
    exit 0
    ;;
  esac
done

instant_rec() {
  while read -s -n 1 key
  do
    case $key in
      r|R)
      optarg_t=86400
      date=`date +%H%M%S`
      echo "[rec] `date +%H:%M:%S` start (stop:s)"
      rec &
      until read -s -n 1 key; [[ "$key" = [sS] ]]
      do
        :
      done
      kill `ps alx | grep -v grep | grep $optarg_c$pid | awk '{print $2}'`
      echo "[rec] `date +%H:%M:%S` stop"
      # move file
      [ -f $SRSR_TMPDIR/$optarg_c$pid".$optarg_f" ] && mv --backup=t $SRSR_TMPDIR/$optarg_c$pid".$optarg_f" $SRSR_OUTDIR/$optarg_c"_${date}.$optarg_f"
      ;;
      b|B)
      thpr=`$SRSR_BINDIR/getwtt.sh -b $optarg_c | grep -v -E "^(\*|http)" | head -1`
      [ "$thpr" ] && echo "this program: $thpr"
      ;;
      k|K)
      musik
      ;;
      h|H)
      echo "[help] instarec:r$playhelpopt  changech:c exit:q"
      ;;
      c|C)
      ontty=`tty | sed 's|/dev/tty||'`
      kill `ps x | grep -v grep | grep "$ontty.*$playcmd" | awk '{print $1}'` &
      wait
      optarg_c=tune
      stty sane 2>/dev/null
      continue 2
      ;;
      q|Q)
      ontty=`tty | sed 's|/dev/tty||'`
      killnr=(`ps x | grep -v grep | grep "$ontty.*$playcmd" | awk '{print $1}'`)
      kill "${killnr[@]}" >/dev/null 2>&1 &
      wait
      stty sane 2>/dev/null
      exit 0
      ;;
    esac
    unset key
  done
}

# dump stream
while :
do
  # history
  [ ! -f $SRSR_TMPDIR/srsr_history ] && touch $SRSR_TMPDIR/srsr_history
  case $optarg_c in
    `tail -1 $SRSR_TMPDIR/srsr_history`|tune)
    :
    ;;
    http|https|mms|mmsh)
    [ ! -f $SRSR_TMPDIR/csra_history ] && touch $SRSR_TMPDIR/csra_history
    [ "$optarg_C" != "`tail -1 $SRSR_TMPDIR/csra_history | awk '{print $1}'`" ] && echo $optarg_C $optarg_f >>$SRSR_TMPDIR/csra_history
    ;;
    *)
    eval $SEDI "/$optarg_c\$/d" $SRSR_TMPDIR/srsr_history
    #sed -i '' "/$optarg_c\$/d" $SRSR_TMPDIR/srsr_history
    echo $optarg_c >>$SRSR_TMPDIR/srsr_history
    ;;
  esac
  # dump
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
    optarg_c=${optarg_c%.*}
    # play not hls support mplayer
    #playcmd=ffmpeg
    #ffmpeg -i $optarg_C -loglevel error -f mpegts pipe:1 | mplayer -really-quiet - 2>/dev/null &
    # play hls support mplayer
    playcmd=mplayer
    mplayer -really-quiet $optarg_C 2>/dev/null &
    [ "$?" -ne 0 ] && echo '[error] mplayer crashed, exit' && exit 1
    # for instant_rec
    case $optarg_f in
      aac|m4a)
      optarg_f=ts
      ;;
      `[ ! $optarg_f ]`)
      optarg_f=wma
      ;;
    esac
    rec() {
      ffmpeg -i $optarg_C -t $optarg_t -loglevel error -acodec copy -vcodec copy $SRSR_TMPDIR/$optarg_c$pid".$optarg_f"
    }
    playhelpopt=""
    musik() {
      :
    }
    instant_rec
    break
    ;;
    AFN)
    http="http://20073.live.streamtheworld.com/AFNP_TKOAAC"
    [[ `echo $http | grep -Po '(?<=//).+(?=/)' | xargs -IURL ping -q -c1 URL 2>&1 | grep -o 'unknown host'` ]] && echo "[error] afn url($http) changed, exit" && exit 1
    # play
    playcmd=mplayer
    mplayer -really-quiet $http 2>/dev/null &
    [ "$?" -ne 0 ] && echo '[error] mplayer crashed, exit' && exit 1
    # for instant_rec
    optarg_f=flv
    rec() {
      mplayer -dumpstream -dumpfile $SRSR_TMPDIR/$optarg_c$pid".$optarg_f" $http -really-quiet
    }
    playhelpopt=""
    musik() {
      :
    }
    instant_rec
    break
    ;;
    AG|AG-S)
    [ "$optarg_c" = "AG-S" ] && optarg_c=AG
    [ -f $SRSR_TMPDIR/ag_url_rtmp ] && rtmp=`cat $SRSR_TMPDIR/ag_url_rtmp` || rtmp="rtmp://fms-base1.mitene.ad.jp/agqr/aandg1b"
    # notfound check
    if [[ ! `rtmpdump -q -r $rtmp --live --stop 0.2` ]]; then
      echo "[error] not found=$rtmp"
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
        echo "[warning] new url=$rtmp"
        echo $rtmp >$SRSR_TMPDIR/ag_url_rtmp
      else
        echo "[error] give up host number search, change to hls url"
        m3u8=http://ic-www.uniqueradio.jp/iphone/3G.m3u8
      fi
    fi
    # play
    if [ $rtmp ]; then
      playcmd=rtmpdump
      rtmpdump -q -r $rtmp --live | mplayer -really-quiet - 2>/dev/null &
      # for instant_rec
      optarg_f=flv
      rec() {
        rtmpdump -q -r $rtmp --live --stop $optarg_t -o $SRSR_TMPDIR/$optarg_c$pid".$optarg_f"
      }
    else
      # play hls not support mplayer
      #playcmd=ffmpeg
      #ffmpeg -i $m3u8 -movflags faststart -loglevel error -acodec copy -vcodec copy -f mpegts pipe:1 2>/dev/null | mplayer -really-quiet - 2>/dev/null &
      # play hls support mplayer
      playcmd=mplayer
      mplayer -really-quiet $m3u8 2>/dev/null &
      [ "$?" -ne 0 ] && echo '[error] mplayer crashed, exit' && exit 1
      # for instant_rec
      optarg_f=ts
      rec() {
        while :
        do
          ffmpeg -i $m3u8 -movflags faststart -t $optarg_t -loglevel error -acodec copy -vcodec copy $SRSR_TMPDIR/$optarg_c$pid".$optarg_f"
          [[ $? = 0 && $option_r || ! $option_r ]] && break
        done
      }
    fi
    playhelpopt=""
    musik() {
      :
    }
    instant_rec
    break
    ;;
    NHK1|NHK2|NHKFM)
    case $optarg_c in
      NHK1)
      m3u8=http://nhkradioakr1-i.akamaihd.net/hls/live/511633/1-r1/1-r1-01.m3u8
      ;;
      NHK2)
      m3u8=http://nhkradioakr2-i.akamaihd.net/hls/live/511929/1-r2/1-r2-01.m3u8
      ;;
      NHKFM)
      m3u8=http://nhkradioakfm-i.akamaihd.net/hls/live/512290/1-fm/1-fm-01.m3u8
      ;;
    esac
    # play hls not support mplayer
    #playcmd=ffmpeg
    #ffmpeg -i $m3u8 -movflags faststart -loglevel error -acodec copy -vn -f mpegts pipe:1 2>/dev/null | mplayer -really-quiet - 2>/dev/null &
    # play hls support mplayer
    playcmd=mplayer
    mplayer -really-quiet $m3u8 2>/dev/null &
    [ "$?" -ne 0 ] && echo '[error] mplayer crashed, exit' && exit 1
    # for instant_rec
    optarg_f=ts
    rec() {
      ffmpeg -i $m3u8 -movflags faststart -t $optarg_t -loglevel error -acodec copy -vn $SRSR_TMPDIR/$optarg_c$pid".$optarg_f"
    }
    playhelpopt=' thisprog:b'
    musik() {
      :
    }
    instant_rec
    break
    ;;
    *)
    # radiko
    source $SRSR_BINDIR/authkey.sh
    # get stream-url
    wget -q -O ${ch_xml} "http://radiko.jp/v2/station/stream/$optarg_c.xml"
    if [ "$?" -ne 0 -o ! -f "${ch_xml}" ]; then
      if [ "$optarg_c" != "tune" -o ! "$optarg_c" ]; then
        eval $SEDI '$d' $SRSR_TMPDIR/srsr_history
        #sed -i '' '$d' $SRSR_TMPDIR/srsr_history
        echo "[error] not found channel=$optarg_c"
        echo " AFN"
        echo " AG`[ $option_t ] && echo '(sound only rec:AG-S)'`"
        echo " NHK1 NHK2 NHKFM"
        echo "radiko($areaid):"
        curl -s http://radiko.jp/v2/station/list/$areaid.xml | xpath //id 2>/dev/null | sed -n 's/<id>/ /g;s/<\/id>//gp'
      fi
      echo -ne 'history:\n '`tac $SRSR_TMPDIR/srsr_history | grep -n '' | head -5`'\n'
      if [ -f $SRSR_TMPDIR/csra_history ]; then
        echo -n ' 6:'; awk '{print $1}' $SRSR_TMPDIR/csra_history| tail -1
      fi
      rm -f ${ch_xml}
      read -p "channel(nowonair:b exit:q) " channel
      case $channel in
        [1-5])
        optarg_c=`tail -n $channel $SRSR_TMPDIR/srsr_history | head -1`
        continue
        ;;
        6)
        optarg_C=`awk 'END{print $1}' $SRSR_TMPDIR/csra_history`
        optarg_c=${optarg_C%%:*}
        optarg_f=`swk 'END{print $2}' $SRSR_TMPDIR/csra_history`
        continue
        ;;
        http*|mms*)
        optarg_C=$channel
        optarg_c=${optarg_C%%:*}
        [ -f $SRSR_TMPDIR/csra_history -a "`grep $channel $SRSR_TMPDIR/csra_history`" ] && optarg_f=`grep $channel $SRSR_TMPDIR/csra_history | awk 'END{print $2}'` || optarg_f=wma
        continue
        ;;
        b|B)
        # AG nowonair
        dateh=`date +%-H`
        [[ $dateh == [0-5] ]] &&  datea=`date -d -1day +%a` || datea=`date +%a`
        # del old tt files
        if [[ $dateh != [0-5] ]]; then
          for delttcnt in {0..6}
          do
            [[ `grep -E -o '^[0-9]{8}' $SRSR_TMPDIR/tt_AG_\`date -d ${delttcnt}day +%a\` | head -1` -lt `date +%Y%m%d` ]] && rm $SRSR_TMPDIR/tt_AG_`date -d ${delttcnt}day +%a`
          done 2>/dev/null
        fi
        # mkagtt
        [ ! -f $SRSR_TMPDIR/tt_${optarg_c}_$datea ] && $SRSR_BINDIR/mkagtt.sh -b
        # add 24-29 progs
        if [[ $dateh == [0-5] ]]; then
          ttheute=`sed -n "/^\`date +%Y%m%d\`/,$ p" $SRSR_TMPDIR/tt_AG_\`date -d -2day +%a\` 2>/dev/null`
          ttheute+=`cat $SRSR_TMPDIR/tt_\_$datea`
        else
          ttheute=`sed -n "/^\`date +%Y%m%d\`/,$ p" $SRSR_TMPDIR/tt_AG_\`date -d -1day +%a\` 2>/dev/null`
          ttheute=`sed -n "/^\`date +%Y%m%d\`/,$ p" $SRSR_TMPDIR/tt_AG_$datea 2>/dev/null`
        fi
        # this prog ag
        jetz=`date +%Y%m%d%H%M`
        until echo "$ttheute" | grep -E "$jetz(<| )" >/dev/null
        do
          [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($jetz - 1)) || jetz=$(($jetz - 40))
        done
        ttjetz=`echo "$ttheute" | sed -n -E "/$jetz/,/<\/td>/p"`
        echo -n 'AG:'; echo "$ttjetz" | grep 'a href' | grep -Po '(?<=target="_blank">).+(?=</a>)' | XMLER | $NKF
        # NHK nowonair
        curl -s 'http://www2.nhk.or.jp/hensei/api/noa.cgi?c=3&wide=1&mode=jsonp' | perl -pe 's/\\u([0-9a-fA-F]{4})/chr(hex($1))/eg; s/(,|$|\\\n)/\n/g' 2>/dev/null | sed -n '/"index":0/,/"title":/p' | grep -Po '(?<="title":").+(?=")' | sed '1s/^/NHK1:/; 2s/^/NHK2:/; 3s/^/NHKFM:/' | XMLER | $NKF
        # radiko nowonair
        staid=(`curl -s http://radiko.jp/v2/station/list/$areaid.xml | grep -Po '(?<=id>).+(?=</id)'`)
        nowonair=(`curl -s 'http://radiko.jp/v2/api/program/now?area_id='$areaid | sed -n '/station id/,/<title>/p' | grep -Po '(?<=<title>).+(?=</title>)' | tr ' ' '_'`)
        for stas in `seq 0 $((${#staid[@]} - 1))`
        do
          echo "${staid[$stas]}:${nowonair[$stas]}"
        done | tr '_' ' ' | XMLER | $NKF
        optarg_t=tune
        continue
        ;;
        q|Q)
        exit 0
        ;;
        *)
        optarg_c=${channel^^}
        continue
        ;;
      esac
    fi
    stream_url=`echo "cat /url/item[1]/text()" | xmllint --shell ${ch_xml} | tail -2 | head -1`
    m3u8=(`echo ${stream_url} | perl -pe 's!^(.*)://(.*?)/(.*)/(.*?)$/!http://$2/$3/$4/playlist.m3u8!'`)
    rm -f ${ch_xml}
    # play hls not support mplayer
    #playcmd=ffmpeg
    #ffmpeg -headers "X-Radiko-AuthToken: $authtoken" -i $m3u8 -movflags faststart -loglevel error -acodec copy -vn -f mpegts pipe:1 2>/dev/null | mplayer -really-quiet - 2>/dev/null &
    # play hls support mplayer
    playcmd=mplayer
    mplayer -really-quiet -http-header-fields "X-Radiko-AuthToken: $authtoken" $m3u8 2>/dev/null &
    [ "$?" -ne 0 ] && echo '[error] mplayer crashed, exit' && exit 1
    # for instant_rec
    optarg_f=ts
    rec() {
      ffmpeg -headers "X-Radiko-AuthToken: $authtoken" -i $m3u8 -movflags faststart -t $optarg_t -loglevel error -acodec copy -vn $SRSR_TMPDIR/$optarg_c$pid".$optarg_f"
    }
    playhelpopt=' thisprog:b (nowplay:k)'
    musik() {
      mskinfo=`$SRSR_BINDIR/mskinfo.sh -k $optarg_c`
      [ "$mskinfo" ] && echo "now playing: $mskinfo (reload:k)" || playhelpopt=' thisprog:b'
    }
    instant_rec
    break
    ;;
  esac
done

