名前: srr.sh srs.sh


概要: ストリーミングラジオを聴取する為のシェルスクリプト集


インストール:

1. cp srsr.conf /usr/local/etc/ OR cp srsr.conf $HOME/.srsr.conf
2. cp {srr.sh,srs.sh} /パスの/通っている/ディレクトリ/
3. cp SRSR_BINDIR/{authkey.sh,getwtt.sh,mkagtt.sh,mskinfo.sh} /srsr.confで/指定した/SRSR_BINDIR/
4. cp tt_AG_over60 /srsr.confで/指定した/SRSR_VARTMPDIR/

任意:
5. cp cfm/{cfmurl.sh,fmxxp.sh,fmxxr.sh} /パスの/通った/ディレクトリ/
6. cp timefree-dl/{mkttpast.sh,timefree-dl.sh} /パスの/通った/ディレクトリ/


設定:

/usr/local/etc/srsr.conf、又は、$HOME/.srsr.conf
 SRSR_OUTDIR=
保存ファイルを出力するデフォルトの場所を設定。`$HOME/Downloads'等
 SRSR_TMPDIR=
保存ファイルのバックアップ等、一時ファイルを出力する場所。`/tmp'等
 SRSR_VARTMPDIR=
設定ファイル等を置く場所。`/var/tmp'等
 SEDI="sed -i"
gnu sedを使用している場合、exportの前をアンコメント
 SEDI="sed -i ''"
bsd sed(mac標準)を使用している場合、exportの前をアンコメント
! `SEDI="sed -i"'と`SEDI=sed -i ''"'は、どちらかのみアンコメント
 SRR_OMCH=
srr.sh、srs.shでチャンネル名を指定しなかった場合に設定されるチャンネル
 SRR_OMDURATION=
srr.sh、srs.shで時間指定しなかった場合に設定される分数
 SRSR_BINDIR=
authkey.sh、getwtt.sh、mkagtt.sh、mskinfo.shを置く場所
 NKF='nkf -Z1 ..'
nkfのオプション指定。`nkf -Z1'以外は任意

/SRSR_VARTMPDIR/tt_AG_over60
60分単位で処理しているAGの番組情報取得を、120分番組や29分番組に対応させるファイル
土曜19時からの120分番組の設定例:
[ "$th" = $((19 - 6)) ] && Sat=120; [ "$th" = $((20 - 6)) ] && Sat=0
* $((`19'の部分が19時を、`Sat=120'の部分が土曜=番組の時間120分を指し、$((`20'と`Sat=0'の部分で、土曜20時台に番組が無いようにみせています
木曜17時30分からの29分番組の設定例:
[ "$th" = $((17 - 6)) ] && Thu=59
* 木曜17時台は30分番組と29分番組で59分なので`Thu=59'、18時台は60分なので何も設定していません
放送休止部分の設定例:
[ "$th" = $((27 - 6)) ] && Sun=180
[ "$th" = $((28 - 6)) ] && {Mon,Tue,Wed,Thu,Fri,Sat}=120 && Sun=0
* 120分番組の設定の応用


readme_opts-J.txtに続く
