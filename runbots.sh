#!/bin/bash

nohup node bots/bot_deluxe.js subadubadoo $1 >> subadubadoo.$1.log 2>&1 &
nohup node bots/bot_deluxe.js dabadubadoo $1 > dabadubadoo.$1.log 2>&1 &
nohup node bots/bot_deluxe.js dubadoo $1 > dubadoo.$1.log 2>&1 &
