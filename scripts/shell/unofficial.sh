#!/bin/bash

stamp=`date '+%Y-%m-%d %H:%M:%S'`

# update unofficial level table
node scripts/shell/snjbot.js > /var/gochiusa/unofficial.csv 
command="load data local infile '/var/gochiusa/unofficial.csv' replace into table unofficial fields terminated by ','"
/opt/bitnami/mysql/bin/mysql -u $HUBOT_IIDX_DB_USER $HUBOT_IIDX_DB_NAME -e "$command" > /dev/null

sqlfile=scripts/shell/`date '+%Y%m%d%H%M%S'`.sql

# make sql for insert.
cat << __EOS__ > $sqlfile
insert ignore into 
  musiclist (id, name, difficulty, official, unofficial)
select
  unofficial.id, unofficial.music, unofficial.difficulty, unofficial.official, unofficial.unofficial
from
  unofficial
__EOS__

# insert
/opt/bitnami/mysql/bin/mysql -u $HUBOT_IIDX_DB_USER $HUBOT_IIDX_DB_NAME < $sqlfile > /dev/null

# make sql for update.
cat << __EOS__ > $sqlfile
update musiclist, unofficial
  set musiclist.unofficial = unofficial.unofficial
where
  musiclist.id = unofficial.id
and
  musiclist.unofficial != unofficial.unofficial
__EOS__

# insert
/opt/bitnami/mysql/bin/mysql -u $HUBOT_IIDX_DB_USER $HUBOT_IIDX_DB_NAME -N -B < $sqlfile > /dev/null

# make sql for getting history.
cat << __EOS__ > $sqlfile
select
  musiclist.name, difficulty.name, old, new
from
  unofficial_audit
inner join
  musiclist on unofficial_audit.id = musiclist.id
inner join
  difficulty on musiclist.difficulty = difficulty.id
where
  stamp > '$stamp'
order by new
__EOS__

# get history
/opt/bitnami/mysql/bin/mysql -u $HUBOT_IIDX_DB_USER $HUBOT_IIDX_DB_NAME -N -B < $sqlfile | tr "\t" ","

rm -f $sqlfile
