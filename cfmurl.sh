#!/usr/bin/env bash

nkf='nkf --fb-skip -m0 -Z1 --euc -Lu'
ver=0.9.4

usage() {
  echo "cfmurl.sh($ver): community fm url checker"
  echo '  --csra|--jcba'
  echo '    -l (area)    list'
  echo '                  1:hokkaidou .. 8:kyuushuu 9:all'
  echo '    -p <keywd>   url'
  echo '  -h             help'
  exit 0
}
[ "$1" = '-h' ] && usage

# get options
[[ ${1:0:2} =~ '--' ]] && optarg_C=${1##*--} && shift || optarg_C=csra
case $1 in
  -l|-l?)
  option_l=on
  if [[ ! $2 || ${#1} -ge 3 ]]; then
    optarg_l=${1:2:1}
  else
    optarg_l=$2
  fi
  [ ! $optarg_l ] && optarg_l=9
  ;;
  -p|-p*)
  option_p=on
  if [[ ! $2 ]]; then
    optarg_p=${1:2}
  else
    optarg_p=$2
  fi
  [ ! $optarg_p ] && usage
  ;;
esac
[ ! $1 ] && option_l=on && optarg_l=9

# liste
while :
do
  case $optarg_C in
    csra)
    idx=`curl -s http://csra.fm/stationlist/`
    liste() {
      [[ $optarg_l =~ [1-8] ]] && nlsta="nl --body-numbering=p'^[^>]' -v $(($optarg_l * 100 + 1)) -s ': ' | tr -d '>'" || nlsta="grep -v '>'"
      areahead=(`echo "$idx" | sed -n '/areanav/='`)
      echo "$idx" | case $optarg_l in
        # hokkaidou
        1)
        sed -n "/#home/s/.*slide\"//; ${areahead[0]},/<\/header>/p"
        ;;
        2)
        sed -n "/#tohoku/s/.*slide\"//; ${areahead[1]},/<\/header>/p"
        ;;
        3)
        sed -n "/#kanto/s/.*slide\"//; ${areahead[2]},/<\/header>/p"
        ;;
        4)
        sed -n "/#tokai/s/.*slide\"//; ${areahead[3]},/<\/header>/p"
        ;;
        5)
        sed -n "/#hokushinetsu/s/.*slide\"//; ${areahead[4]},/<\/header>/p"
        ;;
        6)
        sed -n "/#kinki/s/.*slide\"//; ${areahead[5]},/<\/header>/p"
        ;;
        7)
        sed -n "/#chugokushikoku/s/.*slide\"//; ${areahead[6]},/<\/header>/p"
        ;;
        8)
        sed -n "/#kyushuokinawa/s/.*slide\"//; ${areahead[7]},/<\/header>/p"
        ;;
        *)
        sed -n "${areahead[0]},/stationcontent/p"
        ;;
      esac | sed -n -E '/(^>|<h1>|stm")/p' | sed -E 's/(.*href="|<[^>]*>|" target.*)//g' | uniq | perl -0pe 's/\t//g; s/\n(http|mms)/ $1/g; s/&amp;/&/g' | eval $nlsta | $nkf
    }
    printurlread() {
      staline=`liste | grep -c -E '(http|mms)'`
      read -p `echo "$(($optarg_l * 100 + 1))-$(($optarg_l * 100 + $staline))"`' word: ' optarg_p
      printf "\033[2K\033[G"
    }
    printurl() {
      mmshurl=`liste | case $optarg_p in
        [0-9]*)
        sed -n "$(($optarg_p - $optarg_l * 100 + 1))p" 2>/dev/null
        ;;
        *)
        [ $optarg_p ] && grep $optarg_p || printurlread 2>/dev/null
        ;;
      esac`
      # real url
      case `echo ${mmshurl: -3}` in
        tml)
        mmshurl=`echo $mmshurl | grep -o http.*html | xargs -IURL curl -s URL | grep -o -E 'http.*?m3u8' | uniq`
        ;;
        p=[0-9])
        chp=`echo $mmshurl | grep -Po '(?<=chp=)[0-9]*'`
        mmshurl=`curl -s http://listenradio.jp/service/channel.aspx | perl -pe 's/,/\\n/g; s/\\\//g' | grep -o "http.*$chp.*m3u8"`
        ;;
        *)
        mmshurl=`echo $mmshurl | grep -o -E '(http|mms).*' | sed 's/mms/http/' | xargs -IURL curl -s URL | grep -Po '(?<=http|mms).+(?="|\?)' | sed 's/.*:/mmsh:/' | head -1`
        ;;
      esac
      # suffix
      [[ `ffmpeg -i $mmshurl 2>&1 | grep 'Video:'` ]] && optarg_f=ts || optarg_f=`ffmpeg -i $mmshurl 2>&1 | grep -Po '(?<=Audio: ).+?(?= )' | uniq`
      [ "${#optarg_f}" -gt 3 ] && optarg_f=${optarg_f:0:3}
      # print
      [ "$optarg_f" ] && echo "-C $mmshurl -f $optarg_f"
    }
    [ $option_p ] && break
    ;;
    jcba)
    idx=`curl -s https://www.jcbasimul.com`
    liste() {
      [[ $optarg_l =~ [1-8] ]] && nlsta="nl --body-numbering=p'^[^>]' -v $(($optarg_l * 100 + 1)) -s ': ' | tr -d '>'" || nlsta="grep -v '>'"
      areahead=(`echo "$idx" | sed -n '/area /='`)
      echo "$idx" | case $optarg_l in
        # hokkaidou
        1)
        sed -n "${areahead[0]},$((${areahead[1]} - 1))p"
        ;;
        # touhoku
        2)
        sed -n "${areahead[1]},$((${areahead[2]} - 1))p"
        ;;
        # kantou
        3)
        sed -n "${areahead[2]},$((${areahead[3]} - 1))p"
        ;;
        # toukai
        4)
        sed -n "${areahead[4]},$((${areahead[5]} - 1))p"
        ;;
        # hokushinetsu
        5)
        sed -n "${areahead[3]},$((${areahead[4]} - 1))p; ${areahead[5]},$((${areahead[6]} - 1))p"
        ;;
        # kinki
        6)
        sed -n "${areahead[6]},$((${areahead[7]} - 1))p"
        ;;
        # chuugokushikoku
        7)
        sed -n "${areahead[7]},$((${areahead[9]} - 1))p"
        ;;
        # kyuushuuokinawa
        8)
        sed -n "${areahead[9]},/result_jcba/p"
        ;;
        *)
        sed -n "${areahead[0]},/result_jcba/p"
        ;;
      esac | sed -n -E '/(<h2>|pref[0-9]|JCB)/s/(.*(<h2|=")|(\/|"|<).*)//gp' | perl -0pe 's/\n(JCB)/$1/g' | eval $nlsta | $nkf
    }
    printurlread() {
      staline=`liste | grep -c 'JCB'`
      read -p `echo "$(($optarg_l * 101))-$(($optarg_l * 100 + $staline))"`' word: ' optarg_p
    }
    printurl() {
      httpurl=`liste | case $optarg_p in
        [0-9]*)
        # for hokuriku
        [[ $optarg_p != 51[1-6] ]] && plusnum=1 || plusnum=2
        # print num line
        sed -n "$(($optarg_p - $optarg_l * 100 + $plusnum))p" 2>/dev/null
        ;;
        *)
        [ $optarg_p ] && grep $optarg_p || printurlread
        ;;
      esac`
      # real url
      staid=${httpurl##* }
      httpurl=("http://musicbird-hls.leanstream.co/musicbird/${staid}.stream/playliste.m3u8")
      httpurl+=("http://musicbird.leanstream.co/${staid}-MP3")
      # suffix
      [[ `ffmpeg -i $httpurl 2>&1 | grep 'Video:'` ]] && optarg_f=ts || optarg_f=`ffmpeg -i $httpurl 2>&1 | grep -Po '(?<=Audio: ).+?(?= )'`
      [ "${#optarg_f}" -gt 3 ] && optarg_f=${optarg_f:0:3}
      # print
      [ "$optarg_f" ] && echo "-C $httpurl -f $optarg_f"
      [ "${httpurl[1]}" ] && echo "-C ${httpurl[1]} -f mp3"
    }
    [ $option_p ] && break
    ;;
  esac
  
  if [ $option_l ]; then
    liste
    until [ "$optarg_l" -gt 8 ]
    do
      read -s -n 1 -p '1-8 9 p c q:' key
      printf "\033[2K\033[G"
      case $key in
        [1-8])
        optarg_l=$key
        echo; liste
        ;;
        9)
        optarg_l=9; liste
        ;;
        p)
        printurlread; printurl
        ;;
        c)
        [ "$optarg_C" = 'csra' ] && optarg_C=jcba || optarg_C=csra
        continue 2
        ;;
        q)
        printf "\033[2K\033[G"
        exit 0
        ;;
        *)
        optarg_l=$(($optarg_l + 1))
        [ "$optarg_l" -le 8 ] && echo && liste
        ;;
      esac
    done
    break
  fi
done

[ $option_p ] && printurl

