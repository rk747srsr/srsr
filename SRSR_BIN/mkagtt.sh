#!/usr/bin/env bash

[ -f $HOME/.srsr.conf ] && source $HOME/.srsr.conf || source /opt/radio/etc/srsr.conf

[ $1 ] && option_bid=on

[[ `date +%-H` == [0-5] ]] &&  datea=`date -d -1day +%a` || datea=`date +%a`
tt=`curl -s http://agqr.jp/timetable/streaming.html | perl -pe 's/(^0|:|\t)//g'`
th_head=(`echo "$tt" | sed -n '/^<th .*rowspan/='`)
th_tail=(`echo "${th_head[@]}" | tr ' ' '\n' | awk '{print $1 - 1}'` `echo "$tt" | grep -c ''`); unset th_tail[0]; th_tail=(${th_tail[@]})
for th in {0..22}
do
  ttth=`echo "$tt" | sed -n ${th_head[$th]},${th_tail[$th]}p`
  td_head=(`echo "$ttth" | sed -n '/^<td .*rowspan/='`)
  td_tail=(`echo "$ttth" | sed -n '/^<\/td>/='`)
  export {Mon,Tue,Wed,Thu,Fri,Sat,Sun}=60
  # over 60min
  source $SRSR_VARTMPDIR/tt_AG_over60
  # export
  td=0
  loopcnt=0
  [[ $dateh == [0-5] ]] && export {$datea,`date -d -2day +%a`}'ex'=on
  until `[ "$td" = "${#td_head[@]}" ]`
  do
    # loop check
    if [ "$loopcnt" -le 6 ]; then
      loopcnt=$(($loopcnt + 1))
    else
      echo "[warning] ag timetable changed at $(($th + 6)) o'clock"
      exit 1
    fi
    rnum() {
      echo "$ttth" | sed -n ${td_head[$td]}p | grep -Po '(?<=rowspan=").+(?=" class)'
    }
    exprog() {
      echo "$ttth" | sed -n ${td_head[$td]},${td_tail[$td]}p
    }
    if [[ $Mon -gt 0 && ! $start30Mon ]]; then
      Mo=$(($Mon - `rnum`))
      if [ "${Mo:0:1}" != '-' ]; then
        Mon=$Mo
        if [ -f $SRSR_TMPDIR/tt_AG_Mon -a ! "$Monex" ]; then
          :
        elif [ "$datea" = 'Mon' -o "$Monex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Mon
          Monex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Mon
          Monex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Mon ]; then
      unset start30Mon
    fi
    if [[ $Tue -gt 0 && ! $start30Tue ]]; then
      Tu=$(($Tue - `rnum`))
      if [ "${Tu:0:1}" != '-' ]; then
        Tue=$Tu
        if [ -f $SRSR_TMPDIR/tt_AG_Tue -a ! "$Tueex" ]; then
          :
        elif [ "$datea" = 'Tue' -o "$Tueex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Tue
          Tueex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Tue
          Tueex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Tue ]; then
      unset start30Tue
    fi
    if [[ $Wed -gt 0 && ! $start30Wed ]]; then
      We=$(($Wed - `rnum`))
      if [ "${We:0:1}" != '-' ]; then
        Wed=$We
        if [ -f $SRSR_TMPDIR/tt_AG_Wed -a ! "$Wedex" ]; then
          :
        elif [ "$datea" = 'Wed' -o "$Wedex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Wed
          Wedex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Wed
          Wedex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Wed ]; then
      unset start30Wed
    fi
    if [[ $Thu -gt 0 && ! $start30Thu ]]; then
      Do=$(($Thu - `rnum`))
      if [ "${Do:0:1}" != '-' ]; then
        Thu=$Do
        if [ -f $SRSR_TMPDIR/tt_AG_Thu -a ! "$Thuex" ]; then
          :
        elif [ "$datea" = 'Thu' -o "$Thuex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Thu
          Thuex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Thu
          Thuex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Thu ]; then
      unset start30Thu
    fi
    if [[ $Fri -gt 0 && ! $start30Fri ]]; then
      Fr=$(($Fri - `rnum`))
      if [ "${Fr:0:1}" != '-' ]; then
        Fri=$Fr
        if [ -f $SRSR_TMPDIR/tt_AG_Fri -a ! "$Friex" ]; then
          :
        elif [ "$datea" = 'Fri' -o "$Friex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Fri
          Friex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Fri
          Friex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Fri ]; then
      unset start30Fri
    fi
    if [[ $Sat -gt 0 && ! $start30Sat ]]; then
      Sa=$(($Sat - `rnum`))
      if [ "${Sa:0:1}" != '-' ]; then
        Sat=$Sa
        if [ -f $SRSR_TMPDIR/tt_AG_Sat -a ! "$Satex" ]; then
          :
        elif [ "$datea" = 'Sat' -o "$Satex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Sat
          Satex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Sat
          Satex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Sat ]; then
      unset start30Sat
    fi
    if [[ $Sun -gt 0 && ! $start30Sun ]]; then
      Su=$(($Sun - `rnum`))
      if [ "${Su:0:1}" != '-' ]; then
        Sun=$Su
        if [ -f $SRSR_TMPDIR/tt_AG_Sun -a ! "$Sunex" ]; then
          :
        elif [ "$datea" = 'Sun' -o "$Sunex" ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Sun
          Sunex=on
        elif [ ! $option_bid ]; then
          exprog >>$SRSR_TMPDIR/tt_AG_Sun
          Sunex=on
        fi
        td=$(($td + 1))
      fi
    elif [ $start30Sun ]; then
      unset start30Sun
    fi
  done
done
# 24-28 to 00-04
lsgrepc=(`ls $SRSR_TMPDIR/tt_AG_*`)
[ "${#lsgrepc[@]}" = 2 ] && seqs='-1' || seqs=0
for fnr in `seq $seqs $((${#lsgrepc[@]} - 1))`
do
  perl -i -pe "s/^([6-9][0-9]{2}(<| ))/`date -d \${fnr}day +%Y%m%d`0\$1/; s/^(1[0-9]{3}(<| ))/`date -d \${fnr}day +%Y%m%d`\$1/; s/^(2[0-3][0-9]{2}(<| ))/`date -d \${fnr}day +%Y%m%d`\$1/; s/^(2[4-9])/\$1-24/e; s/^([0-5][0-9]{2}(<| ))/`date -d \$((\$fnr + 1))day +%Y%m%d`0\$1/" $SRSR_TMPDIR/tt_AG_`date -d ${fnr}day +%a`
done 2>/dev/null

