名前: srr.sh srs.sh


概要: ストリーミングラジオを聴取する為のシェルスクリプト集


説明:

ラジコ、らじるらじる、超!A&G+、AFN Tokyo、コミュニティーFM(CSRA、JCBA)の
保存、再生、番組名取得(ラジコ、らじる、AG)、オンエア曲名取得(ラジコの対応局のみ)、
タイムフリー及び聞き逃し保存(ラジコ、らじる)、コミュニティーFMの配信URL取得
する為のシェルスクリプト集です


各スクリプトの説明:

srr.sh: ラジコ等を保存
srs.sh: 　　〃　　再生
! エリアフリー未対応
! FM++未対応

SRSR_BINDIR/
getwtt.sh:  放送中の番組情報、指定時間内の番組情報、今日及び今週(月曜から日曜)の番組表を取得
mkagtt.sh:  AGの番組名を取得する為のスクリプト
mskinfo.sh: オンエア中の曲名、指定時間内のオンエア曲名を取得
authkey.sh: ラジコのキー及びエリアIDを取得するスクリプト

timefree-dl/
timefree-dl.sh: ラジコのタイムフリー、及び、らじるの聞き逃しを保存
mkttpast.sh:    timefree-dl.shで参照する番組情報を取得するスクリプト。
                `timefree-dl.sh -U'コマンドから利用
                cronに
                 3  6  *  *  *  timefree-dl.sh -U
                のように設定して、毎日更新してください

cfm/
cfmurl.sh: CSRA、JCBAの配信URLを表示
fmxxr.sh:  FM++を保存
fmxxp.sh:  　〃　再生、保存
* fmxxr.sh、fmxxp.shには、
  python3、fmplapla.py、pipで`websocket-client'のインストールが必要です


必要なコマンド:

srr.sh、srs.shの動作には、以下のコマンドが必要です
! 基本コマンドの他、nkfやperl5等、
　最初からインストールされている可能性が高いものは省略

作者が使用しているヴァージョンを併記します

bash4
  GNU bash 4.3.30(1)
  ! ver.4.3以前や、ver.5、zshは未検証

ffmpeg、opensslが有効になっているもの
  3.4.6
  configuration: --enable-openssl --enable-libxml2 --enable-libmp3lame

mplayer、hlsとrtmpのストリーミングを再生できるもの
  1.4-4.2.1

rtmpdump v2.4

wget、httpsが有効になっているもの
  1.20
  +digest +https +ipv6 +large-file
  +ntlm +opie +ssl/openssl 

curl、httpsが有効になっているもの
  7.38.0
  libcurl/7.38.0 OpenSSL/1.0.1t zlib/1.2.8 libidn/1.29 libssh2/1.4.3 librtmp/2.3
  Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s
             rtmp rtsp scp sftp smtp smtps telnet tftp 
  Features: AsynchDNS IDN IPv6 Largefile GSS-API SPNEGO NTLM NTLM_WB SSL libz TLS-SRP 

swfextract
  part of swftools 0.9.2

grep、`-P'オプション(perl正規表現)が有効になっているもの、又はpcregrep
  GNU grep 2.20、pcregrep 8.44
  ! pcregrepを使用する場合は、スクリプト内の`grep -Po'を`pcregrep -o'に置換してください
  * 以下のコマンドでエラーが出なければ`-P'オプションは有効になっています
    grep --help | grep -Po '(?<=(he.|ay |r N)).+?(?=(ON| wo|rsi|sage))'

足りないコマンドは、aptやbrew、又はビルドして、インストールしてください


readme_inst-J.txtに続く
