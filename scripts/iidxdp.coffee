# Description:
#  DPの情報とるやつ
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

config = 
  roomName: process.env.HUBOT_SLACK_ROOMNAME

module.exports = (robot) ->
  say = (message) ->
    robot.send {room: config.roomName}, message

  func = (unofficial, lamp, output) ->
    top = ""
    if unofficial == lamp
      top = "DP非公式難易度 #{unofficial} の#{output} ですね。\n"
    else
      top = "DP非公式難易度 #{unofficial} の #{lamp} の#{output} ですね。\n"
    
    top += "少々お待ちください。"
    say top

    command = "bash scripts/shell/getIIDXdata.sh #{unofficial} #{lamp}"
    child command, (err, stdout, stderr) ->
      if err?
        return
      if stderr != ""
        say stderr + ''
        return

      lines = stdout.split "\n"
      lines.pop()

      if output == 'お題'
        data = random(lines).split ","
        say "\nお題は… #{data[0]} [#{data[1]}] (#{data[2]}) です！\n" + 
        "現在のランプは \'#{data[3]}\' ですよ。\n" +
        "更新目指して頑張ってください。"
        return

      tmp = ""
      message = ""
      for line in lines
        if line.search(/,/gi) == -1
          continue

        data = line.split ","
        if tmp != data[2]
          message += "\n【非公式#{data[2]}】\n"
          tmp = data[2]

        message += "#{data[0]} [#{data[1]}] #{data[3]}\n"

      say message.slice(0, -1)

  robot.hear /^(DP|dp)[\s　](\d{2}\.\d)(未満|以下|以上)?[\s　](未プレイ|未クリア|アシスト|イージー|ノマゲ|ハード|エクハ|フルコン|exh|EXH|fc|FC|全部)(未満|以下|以上)?[\s　](一覧|お題)/i, (msg) ->
    unofficial = msg.match[2]
    unofficialSfx = msg.match[3] ? ''
    lamp = msg.match[4]
    lampSfx = msg.match[5] ? ''
    output = msg.match[6]
    
    func("#{unofficial}#{unofficialSfx}", "#{lamp}#{lampSfx}", output)
  
  robot.hear /^(DP|dp)[\s　](\d{2}\.\d-\d{2}\.\d)[\s　](未プレイ|未クリア|アシスト|イージー|ノマゲ|ハード|エクハ|フルコン|exh|EXH|fc|FC|全部)(未満|以下|以上)?[\s　](一覧|お題)/i, (msg) ->
    unofficial = msg.match[2]
    lamp = msg.match[3]
    lampSfx = msg.match[4] ? ''
    output = msg.match[5]
    
    func("#{unofficial}", "#{lamp}#{lampSfx}", output)

  robot.hear /^(DP|dp)[\s　]全部[\s　](未プレイ|未クリア|アシスト|イージー|ノマゲ|ハード|エクハ|フルコン|exh|EXH|fc|FC|全部)(未満|以下|以上)?[\s　](一覧|お題)/i, (msg) ->
    unofficial = '全部'
    lamp = msg.match[2]
    lampSfx = msg.match[3] ? ''
    output = msg.match[4]
    
    func("#{unofficial}", "#{lamp}#{lampSfx}", output)
