#!/usr/bin/env bash

# pip install websocket-client
# nkf --unix --overwrite fmplapla.py
# chmod 755 fmplapla.py

date=`date +%Y%m%d-%H%M`
tmpdir=/tmp
outdir=$HOME/Downloads
nkf='nkf --fb-skip -m0 -Z1 -Lu'
ver=0.9

# help
if [[ ! $1 || $1 = '-h' ]]; then
  echo "fmxxp.sh($ver): fmplapla.py frontend"
  echo '  <ch>        play'
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
  # play rec
  *)
  optarg_C=$1
  rec() {
    (fmplapla.py -s $optarg_C -t $optarg_t | ffmpeg -i pipe: -acodec copy -vn $tmpdir/${optarg_C^^}$$.ogg) >/dev/null 2>&1
  }
  # play
  if [ ! $2 ]; then
    fmplapla.py -s $optarg_C | mplayer -really-quiet - &
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
        ps a | grep 't 86400' | grep -v grep | awk '{print $1}' | xargs -IPID kill PID
        echo "[rec] `date +%H:%M:%S` stop"
        mv $tmpdir/${optarg_C^^}$$.ogg $outdir/${optarg_C^^}_$date.ogg
        ;;
        q|Q)
        ps a | grep "fmplapla.py.*$optarg_C$" | grep -v grep | awk '{print $1}' | xargs -IPID kill PID
        wait
        exit 0
        ;;
      esac
      unset key
    done
  # rec
  else
    optarg_t=$(($2 * 60))
    rec
    cp $tmpdir/${optarg_C^^}$$.ogg $outdir/${optarg_C^^}_$date.ogg
  fi
  ;;
esac
