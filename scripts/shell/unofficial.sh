#!/bin/bash

stamp=`date '+%Y-%m-%d %H:%M:%S'`

# update unofficial level table
node scripts/shell/snjbot.js > /var/gochiusa/unofficial.csv 

sqlfile=scripts/shell/`date '+%Y%m%d%H%M%S'`.sql

# make sql for mergeing table.
cat << __EOS__ > $sqlfile
insert into 
  musiclist (id, name, difficulty, official, unofficial)
select
  id, name, difficulty, official, unofficial
from
  iidxcsv
on conflict(id) do
  update set unofficial = excluded.unofficial
where
  musiclist.unofficial != excluded.unofficial
__EOS__

# merge unofficial table and music table
psql -f $sqlfile -U $HUBOT_IIDX_DB_USER -d $HUBOT_IIDX_DB_NAME > /dev/null

# make sql for getting history.
cat << __EOS__ > $sqlfile
select
  musiclist.name, difficulty.name, old, new
from
  public.unofficial_audit,
  public.musiclist,
  public.difficulty
where
  stamp >= cast('$stamp' as timestamp)
and
  unofficial_audit.id = musiclist.id
and
  musiclist.difficulty = difficulty.id
order by new
__EOS__

# get history
psql -f $sqlfile -U $HUBOT_IIDX_DB_USER -d $HUBOT_IIDX_DB_NAME -A -F, -t

rm -f $sqlfile
