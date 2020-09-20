#!/usr/bin/env bash

# pip install websocket-client
# nkf --unix --overwrite fmplapla.py
# chmod 755 fmplapla.py

date=`date +%Y%m%d-%H%M`; datesek=`date +%S`
tmpdir=/tmp
outdir=$HOME/Downloads
nkf='nkf --fb-skip -m0 -Z1 -Lu'
omch=fmhanabi
omduration=32
ver=0.9.1

# help
if [[ $1 = '-h' ]]; then
  echo "fmxxr.sh($ver): fmplapla.py frontend"
  echo '  <ch> <min>  rec'
  echo '  -l <area>   list'
  echo '               2:touhoku .. 9:okinawa 0:all'
  echo '  -h          help'
  exit 0
fi

fmxxsrc=`curl -s https://fmplapla.com/ | perl -pe 's/(<(th rowspan|td class="icon"))/\n$1/g'`

case $1 in
  # liste
  -l|-l?)
  if [[ ! $2 || ${#1} -ge 3 ]]; then
    optarg_l=${1:2:1}
  else
    optarg_l=$2
  fi
  # area
  areaheadder=(`echo "$fmxxsrc" | sed -n '/th rowspan/s/<[^>]*>//gp'`)
  [[ $optarg_l -ge 2 && $optarg_l ]] && echo ${areaheadder[$(($optarg_l - 2))]} | $nkf
  fmxxsrc=`echo "$fmxxsrc" | perl -pe 's/>/>\n/g'`
  areahead=(`echo "$fmxxsrc" | sed -n '/th rowspan/='`)
  echo "$fmxxsrc" | case $optarg_l in
    # hokkaidou
    1)
    :
    ;;
    # touhoku
    2)
    sed -n "${areahead[0]},$((${areahead[1]} - 1))p"
    ;;
    # shinetsu
    3)
    sed -n "${areahead[1]},$((${areahead[2]} - 1))p"
    ;;
    # kantou
    4)
    sed -n "${areahead[2]},$((${areahead[3]} - 1))p"
    ;;
    # kinki
    5)
    sed -n "${areahead[3]},$((${areahead[4]} - 1))p"
    ;;
    # toukai
    6)
    sed -n "${areahead[4]},$((${areahead[5]} - 1))p"
    ;;
    # chuugoku
    7)
    sed -n "${areahead[5]},$((${areahead[6]} - 1))p"
    ;;
    # kyuushuu
    8)
    sed -n "${areahead[6]},$((${areahead[7]} - 1))p"
    ;;
    # okinawas
    9)
    sed -n "${areahead[7]},/copyrights/p"
    ;;
    # all
    *)
    sed -n "${areahead[0]},/copyrights/p"
    ;;
  esac | sed -n -E '/img src/s/(.*src="\/|" width.*)//g; s/\/\/.*alt="/ /p' | $nkf
  ;;
  # rec
  *)
  # use default
  if [ ! $1 ]; then
    optarg_C=$omch
    optarg_t=$(($omduration * 60))
  else
    optarg_C=$1
    optarg_t=`echo "scale=1; $2 * 60" | bc`; optarg_t=${optarg_t%\.*}
  fi
  end_resume=`date "-d +${optarg_t}sec" '+%s'`
  rec() {
    fmplapla.py -s $optarg_C -t $optarg_t | ffmpeg -i pipe: -loglevel error -acodec copy -vn $tmpdir/${optarg_C^^}$$.ogg
  }
  echo "$$ $0 $*"
  echo "$$ [rec] `date '+%m-%d %H:%M:%S'` start"
  rec
  echo "$$ [rec] `date '+%m-%d %H:%M:%S'` stop"

  # resume
  [ ! -f $tmpdir/${optarg_C^^}'_'$date'.ogg' ] && unset datesek
  now_resume=`date +%s`
  if [ "$(($now_resume + 10))" -lt "$end_resume" ]; then
    recresume=on
    echo "$$ [error] `date '+%m-%d %H:%M:%S'` ${optarg_C^^} disconnect, resume..."
    remdur=$(($end_resume - $now_resume))
    wait `ps a | grep 'ffmpeg -i pipe' | grep "${optarg_C^^}" | grep -v grep | awk '{print $1}'`
    eval $0 $optarg_C `echo "scale=1; $remdur / 60" | bc` &
    echo "file $tmpdir/${optarg_C^^}_${date}${datesek}.ogg" >>$tmpdir/${optarg_C^^}'_RESUME.txt'
  fi

  # move file
  mv --backup=t $tmpdir/${optarg_C^^}$$'.ogg' $tmpdir/${optarg_C^^}'_'$date$datesek'.ogg'
  cp $tmpdir/${optarg_C^^}'_'$date$datesek.ogg $outdir/

  # resume concat
  if [[ ! $recresume && -f $tmpdir/${optarg_C^^}'_RESUME.txt' ]]; then
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
    echo "file $tmpdir/${optarg_C^^}'_'${date}${datesek}.ogg" >>$tmpdir/${optarg_C^^}'_RESUME.txt'
    ffmpeg -f concat -safe 0 -i $tmpdir/${optarg_C^^}'_RESUME.txt' -loglevel error -acodec copy -vn $tmpdir/${optarg_C^^}'_RESUME.ogg'
    # rec start Ymd-HM
    rekstart=`ffmpeg -i $tmpdir/${optarg_C^^}'_RESUME.ogg' 2>&1 | grep -Po '(?<=Duration: ).+?(?=[0-9]{2})' | awk -F: '{print $1*60*60 + $2*60 + $3}'`
    date=`date -d -${rekstart}sec +%Y%m%d-%H%M`
    mv $tmpdir/${optarg_C^^}'_RESUME.ogg' $outdir/${optarg_C^^}'_'$date'_RESUME.ogg'
    respnt=(`grep -Po '(?<=file ).+' $tmpdir/${optarg_C^^}'_RESUME.txt' | xargs -IFILE ffmpeg -i FILE 2>&1 | grep -Po "(?<=Duration: ).+?(?=\.[0-9]{2})" | tr ':' ' ' | sed '$d'`)
    # resume point
    berespnt=`echo "${respnt[0]} ${respnt[1]} ${respnt[2]}" | awk '{print $1*60*60 + $2*60 + $3}'`
    respnthms="resume point: `sectohms`"
    echo "$$ [warning] $respnthms"
    echo ${respnthms^^} >$tmpdir/${optarg_C^^}'_RESUMEHMS.txt'
    if [ "${#respnt[@]}" -ge 4 ]; then
      for rp in `seq 3 3 $((${#respnt[@]} - 1))`
      do
        norespnt=`echo "{respnt[$rp]} ${respnt[$(($rp + 1))]} ${respnt[$(($rp + 2))]}" | awk '{print $1*60*60 + $2*60 + $3}'`
        berespnt=$(($berespnt + $narespnt))
        respnthms="resume point: `sectohms`"
        echo "$$ [warning] $respnthms"
        echo ${respnthms^^} >>$tmpdir/${optarg_C^^}'_RESUMEHMS.txt'
      done
    fi
    rm $tmpdir/${optarg_C^^}_{RESUME,RESUMEHMS}.txt
  fi
  ;;
esac

