名前: srr.sh srs.sh


概要: ストリーミングラジオを保存(srr.sh)、再生(srs.sh)するシェルスクリプト集


説明:

ラジコ、らじる、超!A&G+、AFN、mplayerが対応しているコミュニティーFM等を
保存、再生、番組名・オンエア曲名取得、タイムフリー保存、コミュニティーFMのURL取得
するためのシェルスクリプト集です。


各スクリプトの説明:

srr.sh: ラジコ等を保存
srs.sh: ラジコ等を再生
! FM++は保存再生できません。fmxxp.sh、fmxxr.shを使用してください

cfm/
cfmurl.sh: srr.sh、srs.shで指定する、コミュニティーFMのURLを表示
fmxxp.sh: FM++を再生、保存
fmxxr.sh: FM++を保存
* fmxxp.sh、fmxxr.shの使用には、fmplapla.pyと、pipでwebsocket-clientのインストールが必要です

SRSR_BINDIR/
getwtt.sh:  放送中の番組情報、指定時間内の番組情報、今日及び今週(月曜から日曜)の番組表を取得
mskinfo.sh: オンエア中の曲名、指定時間内のオンエア曲を取得


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
  -cares +digest -gpgme +https +ipv6 -iri +large-file -metalink -nls 
  +ntlm +opie -psl +ssl/openssl 

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

また、srsrのリポジトリにアップしている以下のスクリプトも必要です

SRSR_BINDIR/
authkey.sh、getwtt.sh、mskinfo.sh、mkagtt.sh


readme_inst-J.txtに続く
