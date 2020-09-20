#!/usr/bin/env bash

pid=$$
[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /opt/radio/etc/srsr.conf
ver=2.5.4

usage() {
  echo "getwtt.sh($ver): Timetable downloader"
  echo '  <ch>                   weekly programs'
  echo '  -d|--today <ch>        today programs'
  echo '  -s|--source <ch>       source'
  echo '  -b|--now <ch>          now program'
  echo '  -l|--chlist            list'
  echo '  --radikoch             id list'
  echo 'For srr.sh option:'
  echo '  --proginfo <ch> <min>  programs info'
  echo 'Other:'
  echo '  -h|--help              help'
}

chlist() {
  echo 'ch:'
  echo " `ls $SRSR_VARTMPDIR/ --hide=tt_*_* | sed -n '/tt_/s/tt_//gp' | tr '\n' ' '`"
  echo ' AG'
  echo ' NHK1 NHK2 NHKFM'
  source $SRSR_BINDIR/authkey.sh
  echo -ne ' '`curl -s http://radiko.jp/v2/station/list/$areaid.xml | grep -Po '(?<=id>).+(?=</id)'`'\n'
}

deltag() {
  sed -e 's/<a [^>]*>//g; s/<\/a>//g; s/<[^>]*>/'\\$'\n/g; /^[ ]*$/d; s/^[ ]*//'
}

case $1 in
  --help|-h)
  usage
  exit 0
  ;;
  --today|-d)
  option_d=on
  optarg_c=${2^^}
  ;;
  --now|-b)
  option_b=on
  optarg_c=${2^^}
  ;;
  --proginfo)
  option_i=on
  optarg_c=${2^^}
  optarg_t=$3
  ;;
  --source|-s)
  option_s=on
  optarg_c=${2^^}
  ;;
  --chlist|-l)
  option_l=on
  ;;
  --radikoch)
  option_L=on
  ;;
  *)
  optarg_c=${1^^}
  ;;
esac
[ ! $1 ] && usage && chlist && exit 1

# print ch
if [ "$option_l" -o "$option_L" ]; then
  source $SRSR_BINDIR/authkey.sh
  if [ $option_l ]; then
    chlist
  else
    echo -ne `seq 1 47 | xargs -IAREAID curl -s http://radiko.jp/v2/station/list/JPAREAID.xml | grep -E '</(id|stations)'` | perl -pe 's/<\/stations>/\n/g; s/<[^>]*>//g' | grep -n '' | sed 's/^/JP/; s/: /:/; s/'$areaid':.*/'\\$'\n&'\\$'\n/'
    #echo -ne `seq 1 47 | xargs -IAREAID curl -s http://radiko.jp/v2/station/list/JPAREAID.xml | grep -E '</(id|stations)'` | perl -pe 's/<\/stations>/\n/g; s/<[^>]*>//g' | grep -n '' | sed 's/^/JP/; s/: /:/'
  fi
  exit 0
fi

# download timetable
case ${optarg_c} in
  `ls $SRSR_VARTMPDIR | grep -Po "(?<=tt_)$optarg_c(?=$)"`)
  # template:
  # date%M PROGNAME ex:05 Music
  # (date%u%H%M+MIN PROGNAME ex:11000+60 News60min)
  # or
  # date%u%H%M PROGNAME
  if [ -f $SRSR_VARTMPDIR/tt_$optarg_c ]; then
    tt=`cat $SRSR_VARTMPDIR/tt_$optarg_c`
    date_format=`echo "$tt" | grep -Po '(?<=date_format=).+'`
    update=`echo "$tt" | grep 'update:'`
    tt=`echo "$tt" | grep ^[0-9]`
    nowonair() {
      jetz=`date +$date_format`
      jetz_length=${#jetz}
      # Sun 24-28 date+%u%H:100-104 -> :800-804
      [[ $jetz_length -ge 5 && ${jetz:0:3} -le 104 ]] && jetz=`echo $jetz | perl -pe 's/(^[0-9])/$1+7/e'`
      tt_eof=`echo "$tt" | head -1 | grep -o ^[0-9]*`
      # length=2 and length=6 pattern
      if [[ $jetz_length == 2 && $(echo "$tt" | grep -E "(^| )$(date +%u%H)[0-9]{2}") ]]; then
        tt=$(echo "$tt" | sed -n 's/+[0-9]*//gp' | grep -E "$(date +%u%H)[0-9]{2}")
        jetz=`date +%u%H$jetz`
        tt_eof=`echo "$tt" | head -1 | grep -o ^[0-9]*`
        until [[ `echo "$tt" | grep $jetz` || $((10#$jetz)) -lt $((10#$tt_eof)) ]]
        do
          [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($((10#$jetz - 1)))) || jetz=$(($((10#$jetz - 40))))
        done
      # length=6 only pattern
      else
        until [[ `echo "$tt" | grep "$jetz "` || $((10#$jetz)) -lt $((10#$tt_eof)) ]]
        do
          [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($((10#$jetz - 1)))) || jetz=$(($((10#$jetz - 40))))
          jetz=`printf %"0$jetz_length"d $jetz`
        done
      fi
      ttjetz=`echo "$tt" | sed -n "/$jetz/s/[0-9+]* //gp"`
    }
    # nowonair
    if [ $option_b ]; then
      nowonair
    # proginfo
    elif [ $option_i ]; then
      jetzh=`date -d -${optarg_t}min +$date_format`
      jetzt=`date -d -2min +$date_format`
      # date+%M
      if [ "${#jetzh}" -lt 5 ]; then
        datenurmin=on
        jetzh=`date -d -${optarg_t}min +%u%H$jetzh`
        jetzt=`date -d -2min +%u%H$jetzt`
      fi
      # rek Sun before 24 to Sun after 24 date+%u:1 -> :8
      [[ `date +%u` == 7 && ${jetzh:0:3} -le 723 && ${jetzt:0:1} == 1 ]] && jetzt=${jetzt/1/8}
      # rek Sun 24-28 to Mon after 05 date+%u%H:100-104 -> :800-804
      [[ ${jetzh:0:3} -le 104 && ${jetzt:0:3} -ge 105 ]] && jetzh=${jetzh/1/8}
      until [ "$jetzh" -ge "$jetzt" ]
      do
        # date%M
        if [ $datenurmin ]; then
          if [[ ${jetzh:0:3} == `echo "$tt" | grep -E -o "(^| )${jetzh:0:3}"` ]]; then
            progh=(${progh[@]} `echo "$tt" | sed -n "/$jetzh/="`)
            [[ `echo "$tt" | grep $jetzh` ]] && jetzh=$(($jetzh `echo "$tt" | grep -Po "(?<=\${jetzh}).+?(?= )"`)); jetzh=${jetzh/+/}
          else
            progh=(${progh[@]} `echo "$tt" | grep -v -E "^[0-9]{5}" | sed -n "/${jetzh: -2}/="`)
          fi
        # date%u%H%M
        else
          progh=(${progh[@]} `echo "$tt" | sed -n "/$jetzh/="`)
        fi
        [[ $((10#${jetzh: -2})) -le 59 ]] && jetzh=$(($((10#$jetzh + 1)))) || jetzh=$(($((10#$jetzh + 40))))
        [[ $((10#${jetzh:1:2})) -ge 24 ]] && jetzh=`echo $jetzh | perl -pe 's/(^[0-9])/$1+1/e; s/(^[0-9])[0-9]{2}/${1}00/'`
        [[ $((10#${jetzh:0:3})) -ge 805 ]] && jetzh=${jetzh/8/1} && jetzt=${jetzt/8/1}
      done
      for phlnr in `seq 0 $((${#progh[@]} - 1))`
      do
        ttjetz+=(`echo "$tt" | sed -n "${progh[$phlnr]}s/[0-9+]* //gp"`)
      done
      ttjetz=`echo ${ttjetz[@]} | tr ' ' '\n'`
      # for rek teste
      [ ! "$ttjetz" ] && nowonair
    fi
    # print
    echo "[warning] see localfile($update) channel=$optarg_c"
    [ $option_b ] && echo "$ttjetz" | uniq | $NKF || echo "$ttjetz" | uniq
  fi
  ;;
  AG|AG-S)
  [ ! -f $SRSR_BINDIR/mkagtt.sh ] && echo '[error] request mkagtt.sh' && exit 1
  [ $optarg_c = 'AG-S' ] && optarg_c=AG
  tturl='http://agqr.jp/timetable/streaming.html'
  # download source
  [ $option_s ] && wget -q $tturl -O $SRSR_OUTDIR/tt_${optarg_c}_source && exit 0
  # timetable
  dateh=`date +%-H`
  [[ $dateh == [0-5] ]] &&  datea=`date -d -1day +%a` || datea=`date +%a`
  # del old tt files
  if [[ $dateh != [0-5] ]]; then
    for delttcnt in {0..6}
    do
      [[ `grep -E -o '^[0-9]{8}' $SRSR_TMPDIR/tt_${optarg_c}_\`date -d ${delttcnt}day +%a\` | head -1` -lt `date +%Y%m%d` ]] && rm $SRSR_TMPDIR/tt_${optarg_c}_`date -d ${delttcnt}day +%a`
    done 2>/dev/null
  fi
  faircopy() {
    sed -n -E '/(bg-|icon_m|^<a href|^[^<])/p' | perl -pe 's/<td.*bg-/\n\*/; s/\">$/\*/; s/(\*)f\*/$1first$1/; s/(\*)l\*/$1live$1/; s/title="/>/g; s/<.*icon_m.gif.*/\n\*movie\*/; s/<a href=\"(htt(ps|p)|mailto)/$1:/; s/\" target=\"_blank\">/\n/; s/(<img.* \"alt=\"|\" title=\")//g; s/(\">|<)[^>]*>//g; s/\n\n/\n/'
  }
  # timetable jetz
  [ ! -f $SRSR_TMPDIR/tt_${optarg_c}_$datea ] && $SRSR_BINDIR/mkagtt.sh -b
  if [ "$option_b" -o "$option_i" ]; then
    if [[ $dateh == [0-5] ]]; then
      ttheute=`sed -n "/^\`date +%Y%m%d\`/,$ p" $SRSR_TMPDIR/tt_${optarg_c}_\`date -d -2day +%a\` 2>/dev/null`
      ttheute+=`cat $SRSR_TMPDIR/tt_${optarg_c}_$datea`
    else
      ttheute=`sed -n "/^\`date +%Y%m%d\`/,$ p" $SRSR_TMPDIR/tt_${optarg_c}_\`date -d -1day +%a\` 2>/dev/null`
      ttheute=`sed -n "/^\`date +%Y%m%d\`/,$ p" $SRSR_TMPDIR/tt_${optarg_c}_$datea 2>/dev/null`
    fi
    if [ $option_b ]; then
      jetz=`date +%Y%m%d%H%M`
      until echo "$ttheute" | grep -E "$jetz(<| )" >/dev/null
      do
        [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($jetz - 1)) || jetz=$(($jetz - 40))
      done
      ttjetz=`echo "$ttheute" | sed -n -E "/$jetz/,/<\/td>/p"`
    # progsinfo
    elif [ $option_i ]; then
      jetzh=`date -d -${optarg_t}min +%Y%m%d%H%M`
      jetzt=`date -d -2min +%Y%m%d%H%M`
      until [ "$jetzh" -ge "$jetzt" ]
      do
        [[ $((10#${jetzh: -2})) -le 59 ]] && jetzh=$(($jetzh + 1)) || jetzh=$(($jetzh + 40))
        progh=(${progh[@]} `echo "$ttheute" | sed -n -E "/$jetzh(<| )/=" | awk '{print $1 - 2}'`)
      done
      for phlnr in `seq 0 $((${#progh[@]} - 1))`
      do
        ttjetz+=`echo "$ttheute" | sed -n "${progh[$phlnr]},/<\/td>/p"`
      done
      # for rek teste
      if [ ! "$ttjetz" ]; then
        jetz=`date -d -2min +%Y%m%d%H%M`
        amtagzuvor=`date -d -1day +%Y%m%d%H%M`
        until echo "$ttheute" | grep -E "$jetz(<| )" >/dev/null
        do
          [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($jetz - 1)) || jetz=$(($jetz - 40))
          # loop exit
          [[ $jetz -lt $amtagzuvor ]] && exit 1
        done
        ttjetz=`echo "$ttheute" | sed -n "/$jetz/,/<\/td>/p"`
      fi
    fi
    # print
    [ $option_b ] && echo "$ttjetz" | faircopy  | sed -E '/^[0-9]{12}/d' | $NKF || echo "$ttjetz" | faircopy | perl -pe 's/^(\d{8})(\d{4})/$1 $2/g' | sed '1d'
  # timetable heute
  elif [ $option_d ]; then
  [ ! -f $SRSR_TMPDIR/tt_${optarg_c}_$datea ] && mkagtt.sh -d
    cat $SRSR_TMPDIR/tt_${optarg_c}_$datea | faircopy | sed '1d' >$SRSR_OUTDIR/tt_${optarg_c}'_'$datea
  # timetzble woche
  else
  [[ `ls /$SRSR_TMPDIR/tt_${optarg_c}_* | wc -l` != '7' ]] && mkagtt.sh
    for datea in `seq 0 6`
    do
      cat $SRSR_TMPDIR/tt_${optarg_c}_`date -d ${datea}day +%a`
    done | faircopy | sed '1d' >>$SRSR_OUTDIR/tt_${optarg_c}'_-'`date -d 6day +%a`
    eval $SEDI 1d $SRSR_OUTDIR/tt_${optarg_c}'_-'`date -d 6day +%a`
  fi
  ;;
  NHK1|NHK2|NHKFM)
  date=`date +%Y-%m-%d`
  dated=1
  tturl=('http://www2.nhk.or.jp/hensei/api/noa.cgi?c=1' "https://www2.nhk.or.jp/hensei/program/index.cgi?area=001&date=$date&tz=all&type=1")
  # download source
  [ $option_s ] && wget -q ${tturl[1]} -O $SRSR_OUTDIR/tt_${optarg_c}_source && exit 0
  # timetable jetz
  if [ $option_b ]; then
    tt=`curl -s ${tturl[0]} | sed -n -E '/<ch>(r1|r2|fm)/,/<\/item>/p' | grep -E '(title|content|act|music)>' | tr -d '\t'`
    ttline=(`echo "$tt" | sed -n '/<title>/='`)
    case $optarg_c in
      NHK1)
      ttl=0
      ;;
      NHK2)
      ttl=2
      ;;
      NHKFM)
      ttl=4
      ;;
    esac
    echo "$tt" | sed -n -E "${ttline[$ttl]},$((${ttline[$(($ttl + 1))]} - 1))s/<[^>]*>//gp" | XMLER | $NKF
  # proginfo today weekly
  else
    case ${optarg_c} in
      NHK1)
      nhkch=05
      ;;
      NHK2)
      nhkch=06
      ;;
      NHKFM)
      nhkch=07
      ;;
    esac
    [[ `date +%-H` == [0-4] ]] && date=`date -d -1day +%Y-%m-%d` && dated=0
    tt=`curl -s ${tturl[1]}`
    tt=`echo "$tt" | sed -n '/<tbody>/,/<\/tbody>/p' | perl -pe 's/(<\/td>)/$1\n/; s/date=/>/; s/(\&ch=)/<$1/'`
    ttam=`echo "$tt" | sed -n '1,/_pm/p' | grep -v '_pm'`
    ttpm=`echo "$tt" | sed -n '/_pm/,/_next_am/p' | grep -v '_next_am' | perl -pe 's/([0-9]{2}):/$1+12/e'`
    ttnextam=`echo "$tt" | sed -n '/_next_am/,$ p' | sed -E "s/[0-9]{4}-[0-9]{2}-[0-9]{2}/\`date -d +${dated}day +%Y-%m-%d\`/"`
    tt=`echo "$ttam$ttpm$ttnextam" | sed -n -E "/ch=$nhkch/,/<\/td>/s/(<[^>]*>|&nbsp;)//gp" | perl -pe 's/(^\s+$|:|-)//g; s/([0-9]{4})([0-9]{8})/$2$1/; s/^([0-9]+)/\n$1\n/'`
    if [ $option_i ]; then
      # proginfo
      jetzh=`date -d -${optarg_t}min +%Y%m%d%H%M`
      jetzt=`date -d -2min +%Y%m%d%H%M`
      until [ "$jetzh" -ge "$jetzt" ]
      do
        [[ $((10#${jetzh: -2})) -le 59 ]] && jetzh=$(($jetzh + 1)) || jetzh=$(($jetzh + 40))
        progh=(${progh[@]} `echo "$tt" | sed -n "/$jetzh/="`)
      done
      for phlnr in `seq 0 $((${#progh[@]} - 1))`
      do
        ttjetz+=`echo "$tt" | sed -n "${progh[$phlnr]},/^$/p"`
      done
      # for rek teste
      if [ ! "$ttjetz" ]; then
        jetz=`date +%Y%m%d%H%M`
        amtagzuvor=`date -d -1day +%Y%m%d%H%M`
        until [[ `echo "$tt" | grep $jetz` ]]
        do
          [[ $((10#${jetz: -2})) -le 59 ]] && jetz=$(($jetz - 1)) || jetz=$(($jetz - 40))
          # loop exit
          [[ $jetz -lt $amtagzuvor ]] && exit 1
        done
        ttjetz=`echo "$tt" | sed -n "/$jetz/,/^$/p"`
      fi
      echo "$ttjetz" | perl -pe 's/([0-9]{12})/\n\n$1/' | sed 1,2d | XMLER | ${NKF/--euc/}
    elif [ $option_d ]; then
      # timetable heute
      echo "$tt" | sed 1d | XMLER | ${NKF/--euc/} >$SRSR_OUTDIR/tt_${optarg_c}_`date +%Y%m%d`
    else
      # timetable woch
      for ttheute in `seq 0 6`
      do
        date=`date -d +${ttheute}day +%Y-%m-%d`
        tt=`curl -s "https://www2.nhk.or.jp/hensei/program/index.cgi?area=001&date=$date&tz=all&type=1"`
        tt=`echo "$tt" | sed -n '/<tbody>/,/<\/tbody>/p' | perl -pe 's/(<\/td>)/$1\n/; s/date=/>/; s/(\&ch=)/<$1/'`
        ttam=`echo "$tt" | sed -n '1,/_pm/p' | grep -v '_pm'`
        ttpm=`echo "$tt" | sed -n '/_pm/,/_next_am/p' | grep -v '_next_am' | perl -pe 's/([0-9]{2}):/$1+12/e'`
        ttnextam=`echo "$tt" | sed -n '/_next_am/,$ p' | sed -E "s/[0-9]{4}-[0-9]{2}-[0-9]{2}/\`date -d +$(($ttheute + 1))day +%Y-%m-%d\`/"`
        echo "$ttam$ttpm$ttnextam"
      done | sed -n -E "/ch=$nhkch/,/<\/td>/s/(<[^>]*>|&nbsp;)//gp" | perl -pe 's/(^\s+$|:|-)//g; s/([0-9]{4})([0-9]{8})/$2$1/; s/^([0-9]+)/\n$1\n/' | XMLER | ${NKF/--euc} >>$SRSR_OUTDIR/tt_${optarg_c}'_-'`date -d +6day +%Y%m%d`
    eval $SEDI 1d $SRSR_OUTDIR/tt_${optarg_c}'_-'`date -d +6day +%Y%m%d`
    fi
  fi
  ;;
  # radiko
  *)
  source $SRSR_BINDIR/authkey.sh
  # faircopy
  faircopy() {
    perl -pe 's/" (to="|ftl=.*)/\n/g; s/(\d{8})(\d{4})00/$1 $2/g' | XMLER | deltag | grep -v ^$ | perl -pe 's/^.* ft="/\n/g'
  }
  # tturlwot
  case $1 in
    -s|--source)
    wot="station/weekly?station_id=${optarg_c}"
    ;;
    -b|--now)
    wot="now?area_id=$areaid"
    ;;
    --proginfo)
    wot="today?area_id=$areaid"
    ;;
    -d|--today)
    wot="today?area_id=$areaid"
    ;;
    *)
    wot="station/weekly?station_id=${optarg_c}"
    ;;
  esac
  tturl="http://radiko.jp/v2/api/program/$wot"
  # download source
  if [ $option_s ]; then
    wget -q $tturl -O $SRSR_OUTDIR/tt_${optarg_c}_source
    if [ ! -s $SRSR_OUTDIR/tt_${optarg_c}_source ]; then
      echo "[error] not found ${optarg_c}"
      chlist
      rm $SRSR_OUTDIR/tt_${optarg_c}_source
    fi
  # timetable jetz
  else
    if [ "$option_b" -o "$option_i" ]; then
      if [ $option_b ]; then
        ttjetz=`curl -s $tturl | sed -n "/id=\"$optarg_c/,/<\/progs>/p"`
        # out range
        if [ ! "$ttjetz" ]; then
          ttjetz=`seq 1 47 | xargs -IAREAID curl -s ${tturl%JP*}JPAREAID | sed -n "/id=\"$optarg_c/,/<\/progs>/p"`
          ttline=`echo "$ttjetz" | sed -n '/<\/progs>/=' | head -1`
          ttjetz=`echo "$ttjetz" | sed -n "1,${ttline}p"`
          [ "$ttjetz" ] && echo "[warning] out range channel=$optarg_c"
        fi
        progft=(`echo "$ttjetz" | grep 'ft="' | grep -o '[0-9]*'`)
        if [[ `date +%Y%m%d%H%M`00 -lt ${progft[5]} ]]; then
          jetz=${progft[0]}
        else
          jetz=${progft[5]}
        fi
        ttjetz=`echo "$ttjetz" | sed -n "/ft=\"$jetz/,/<\/prog>/p"`
      # progsinfo
      else
        ttheute=`curl -s $tturl | sed -n "/id=\"$optarg_c/,/<\/station>/p"`
        # out range
        if [ ! "$ttheute" ]; then
          ttheute=`seq 1 47 | xargs -IAREAID curl -s ${tturl%JP*}JPAREAID | sed -n "/id=\"$optarg_c/,/<\/station>/p"`
          ttline=`echo "$ttheute" | sed -n '/<\/progs>/=' | head -1`
          ttheute=`echo "$ttheute" | sed -n "1,${ttline}p" 2>/dev/null`
        fi
        if [[ $ttheute && ! `echo "$ttheute" | grep '404 Not Found'` ]]; then
          jetzh=`date -d -${optarg_t}min +%Y%m%d%H%M`00
          jetzt=`date -d -2min +%Y%m%d%H%M`00
          until [ "$jetzh" -ge "$jetzt" ]
          do
            [[ $((10#${jetzh: -4})) -le 5900 ]] && jetzh=$(($jetzh + 100)) || jetzh=$(($jetzh + 4000))
            progh=(${progh[@]} `echo "$ttheute" | sed -n "/<prog ft=\"$jetzh/="`)
          done
          for phlnr in `seq 0 $((${#progh[@]} - 1))`
          do
            ttjetz+=`echo "$ttheute" | sed -n "${progh[$phlnr]},/<\/prog>/p"`
          done
          # for rek teste
          if [ ! "$ttjetz" ]; then
            jetz=`date +%Y%m%d%H%M`00
            amtagzuvor=`date -d -1day +%Y%m%d%H%M`00
            until [[ `echo "$ttheute" | grep "prog ft=\"${jetz}"` ]]
            do
              [[ $((10#${jetz: -4})) -le 5900 ]] && jetz=$(($jetz - 100)) || jetz=$(($jetz - 4000))
              # loop exit
              [[ $jetz -lt $amtagzuvor ]] && exit 1
            done
            ttjetz=`echo "$ttheute" | sed -n "/prog ft=\"$jetz/,/<\/prog>/p" | sed '/prog ft=/s/[0-9]*//g'`
          fi
        # 404 Not Found
        else
          unset ttjetz
        fi
      fi
      if [ ! "$ttjetz" ]; then
        echo "[error] not found ${optarg_c}"
        chlist
        exit 1
      # print
      else
        # print
        if [ $option_b ]; then
          echo "$ttjetz" | faircopy | sed -E '/^[0-9]{8}/d' | perl -pe 's/(^[ ]*|\t)//g' | uniq | sed 1d | $NKF
        else
          ttjetz=`echo "$ttjetz" | faircopy | perl -pe 's/(^[ ]*|\t)//g' | uniq | sed 1d`
          # for rek teste faircopy
          [[ ! `echo "$ttjetz" | head -1` ]] && ttjetz=`echo "$ttjetz" | sed 1d`
          echo "$ttjetz"
        fi
      fi
    # timetable heute woche
    else
      tt=`curl -s $tturl | sed -n "/id=\"$optarg_c/,/<\/station>/p"`
      # out range
      if [ ! "$tt" ]; then
        tt=`seq 1 47 | xargs -IAREAID curl -s ${tturl%JP*}JPAREAID | sed -n "/id=\"$optarg_c/,/<\/station>/p"`
        ttline=`echo "$tt" | sed -n "/<\/station>/=" | head -1`
        tt=`echo "$tt" | sed -n "1,${ttline}p" 2>/dev/null`
      fi
      # not found
      if [[ ! $tt || `echo "$tt" | grep '404 Not Found'` ]]; then
        echo "[error] not found ${optarg_c}"
        chlist
        exit 1
      fi
      [ $option_d ] && ttdate=`date +%Y%m%d` || ttdate='-'`echo "$tt" | grep 'prog ft="' | grep -o -E '[0-9]{8}' | tail -1`
      echo "$tt" | faircopy | perl -pe 's/(\d{8}) (\d{4})/$1$2/g; s/(^[ ]*|\t)//g' | sed '/^$/d' | perl -0pe 's/([0-9]{12}\n[0-9]{12})/\n$1/g' | sed 1d >$SRSR_OUTDIR/tt_${optarg_c}_$ttdate
    fi
  fi
  ;;
esac

