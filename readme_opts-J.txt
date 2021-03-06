名前: srr.sh srs.sh


概要: ストリーミングラジオを聴取する為のシェルスクリプト集


使用方法(srr.sh):

 ラジコ、らじる、AG、AFNを保存:  srr.sh -c チャンネル -t 分
必須:
 -c チャンネル
指定できるチャンネルは、ラジコID(HOUSOU-DAIGAKU等)、NHK1、NHK2、NHKFM、AG、AFN
 -t 分
保存する時間を分で指定
`0'を指定した場合、次の番組開始時間(ラジコ、らじる、AG)、又は、次の時間の00分(AFN、コミュニティーFM)までが設定されます
任意:
 -i
番組情報(ラジコ、らじる、AG)と曲名(ラジコの対応局)も保存
! 保存時間が3分以下の場合は無視されます
 -m メモ
標準出力にメモを出力
 -o /ディレクトリ/ファイル名.拡張子
srsr.confで設定したSRSR_OUTDIR以外へ保存ファイルを出力
`/ディレクトリ/'でディレクトリのみ指定(末尾`/')、`/ディレクトリ/ファイル名.拡張子'でファイル名.拡張子まで設定(末尾`/'以外)、`ファイル名'でカレントディレクトリへ指定したファイル名.拡張子を出力(先頭`/'以外)
* 拡張子は、AGなら`.flv'、それ以外は`.m4a'を指定してください
 -M
標準ファイル名(oオプションを使用しない場合に付けられる、チャンネル_年月日-時分)の`日-時'を、`今日-00時'→`前日-24時'、`今日-05時'→`前日-29時'にする

 保存テスト:  srr.sh -T チャンネル
 -T チャンネル
3分間保存。`srr.sh -c チャンネル -t 3 -i'を指定するのと同じ
チャンネルは省略可。その場合、srsr.confで設定したSRR_OMCHを保存

 コミュニティーFMを保存:  srr.sh -C URL -f コーデック -t 分
必須:
 -C URL
`cfmurl.sh -l'→`p チャンネル'で表示される`-C URL'を指定
CSRA、JCBA以外でも、httpやmmsh等、ffmpeg及びmplayerが対応しているURLならば保存可能
 -f コーデック
`cfmurl.sh -l'→`p'→`チャンネル'で表示される`-f コーデック'を指定。コーデックを省略した場合`wma'
 -t 分
任意:
 -m メモ
 -o /ディレクトリ/ファイル名.拡張子
 -M

 ヘルプ:  srr.sh -h


使用方法(srs.sh):

 ラジコ、らじる、AG、AFNを再生:  srs.sh -c チャンネル
 コミュニティーFMを再生:  srs.sh -C チャンネル -f コーデック

再生中のオプション:
 r:インスタント保存(最大24時間)。保存ファイルはsrsr.confで設定したSRSR_OUTDIRへ出力
 s:インスタント保存停止
 b:番組名表示
 k:曲名表示(曲名を配信しているラジコ局のみ)
 c:チャンネル変更。チャンネルID、又は、ヒストリー番号で指定。`b'を入力すると、現在配信中のラジコとらじるの番組一覧を表示します
 h:再生中オプションを表示
 q:終了

 ヘルプ:  -h
