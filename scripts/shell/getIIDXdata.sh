#!/bin/bash

if [ $# -ne 2 ]; then
  echo "指定された引数は$#個です。" 1>&2
  echo "実行するには2個の引数が必要です。" 1>&2
  exit 1
fi

unofficial=$1
lamp=${2^^}
sqlfile=scripts/shell/`date '+%Y%m%d%H%M%S'`.sql

echo "SELECT" > $sqlfile
echo "  musiclist.name, difficulty.name, musiclist.unofficial, clearlamp.name" >> $sqlfile

cat << __EOS__ >> $sqlfile
from
  clearstate
inner join
  musiclist on clearstate.music = musiclist.id
inner join
  clearlamp on clearstate.clearlamp = clearlamp.id
inner join
  difficulty on musiclist.difficulty = difficulty.id
__EOS__

if [ "$unofficial" != "全部" ]; then
  echo "AND" >> $sqlfile
fi

if [ `echo $unofficial | grep "以上"` ]; then
  echo "  musiclist.unofficial >= ${unofficial:0:4}" >> $sqlfile
elif [ `echo $unofficial | grep "以下"` ]; then
  echo "  musiclist.unofficial <= ${unofficial:0:4}" >> $sqlfile
elif [ `echo $unofficial | grep "未満"` ]; then
  echo "  musiclist.unofficial < ${unofficial:0:4}" >> $sqlfile
elif [ `echo $unofficial | grep "-"` ]; then
  IFS=- eval 'arr=($unofficial)'
  if [[ ${arr[0]} > "${arr[1]}" ]]; then
    tmp=${arr[0]}
    arr[0]=${arr[1]}
    arr[1]=tmp
  fi
  echo "  musiclist.unofficial >= ${arr[0]}" >> $sqlfile
  echo "AND" >> $sqlfile
  echo "  musiclist.unofficial <= ${arr[1]}" >> $sqlfile
else
  echo "  musiclist.unofficial = ${unofficial}" >> $sqlfile
fi

lampID=0
if [ `echo $lamp | grep "未プレイ"` ]; then
  lampID=-1
elif [ `echo $lamp | grep "未クリア"` ]; then
  lampID=1
elif [ `echo $lamp | grep "アシスト"` ]; then
  lampID=2
elif [ `echo $lamp | grep "イージー"` ]; then
  lampID=3
elif [ `echo $lamp | grep "ノマゲ"` ]; then
  lampID=4
elif [ `echo $lamp | grep "ハード"` ]; then
  lampID=5
elif [ `echo $lamp | grep -E "EXH|エクハ"` ]; then
  lampID=6
elif [ `echo $lamp | grep -E "FC|フルコン"` ]; then
  lampID=7
fi

if [ "$lamp" != "全部" ]; then
  echo "AND" >> $sqlfile
fi

if [ `echo $lamp | grep "以上" | grep -vE "未クリア|未プレイ"` ]; then
  echo "  clearstate.clearlamp >= $lampID" >> $sqlfile
elif [ `echo $lamp | grep "以下" | grep -vE "未クリア|未プレイ"` ]; then
  echo "  clearstate.clearlamp <= $lampID" >> $sqlfile
elif [ `echo $lamp | grep "未満" | grep -vE "未クリア|未プレイ"` ]; then
  echo "  clearstate.clearlamp < $lampID" >> $sqlfile
elif [ "$lamp" = "全部" ]; then
  echo "" > /dev/null
elif [ "$lamp" = "未クリア" ]; then
  echo "  clearstate.clearlamp <= $lampID" >> $sqlfile
else
  echo "  clearstate.clearlamp = $lampID" >> $sqlfile
fi

echo "order by musiclist.unofficial, musiclist.name, difficulty.name desc" >> $sqlfile

/opt/bitnami/mysql/bin/mysql -u $HUBOT_IIDX_DB_USER $HUBOT_IIDX_DB_NAME -N -B < $sqlfile | tr "\t" ","

rm -f $sqlfile
