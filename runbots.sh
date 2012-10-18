#!/bin/sh

pkill -f node
for bot in subadubadoo dabadubadoo dubadoo; do
  nohup /usr/bin/node lib/bot.js $bot $1 > $bot.$1.log 2>&1 &
done
