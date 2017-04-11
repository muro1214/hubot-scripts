# Description:
#  DPの非公式難易度を更新するやつ
#
# Configuration:
#   None
#
# Commands:
#
# Author:
#   muro1214

random = require('hubot').Response::random
child = require('child_process').exec
cron = require('cron').CronJob

config = 
  roomName: process.env.HUBOT_SLACK_ROOMNAME

module.exports = (robot) ->
  say = (message) ->
    robot.send {room: config.roomName}, message
  
  func = ->
    say '非公式難易度を取得しています…'

    command = "bash scripts/shell/unofficial.sh"
    child command, (err, stdout, stderr) ->
      if err?
        return
      if stderr != ""
        say stderr + ''
        return

      lines = stdout.split "\n"
#      lines.pop()

      message = "【難易度表の更新】\n"
      if lines.length == 1
        message += "更新はありません"
        say message
        return

      for line in lines
        if line.search(/,/gi) == -1
          continue

        data = line.split ","
        message += "#{data[0]} [#{data[1]}] #{data[2]} → #{data[3]}\n"

      say message.slice(0, -1)

  robot.hear /^(DP|dp)[\s　]難易度表更新/i, ->
    func()

  new cron "0 0 9 * * 1", () ->
    func()
  ,null, true
