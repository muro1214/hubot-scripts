# Description:
#  オリジナルping
#
# Configuration:
#   None
#
# Commands:
#   hubot [いお]る[の]?[ーか]*?？ - 応答を返します
#   いるー？　いる？　おるかーーー？　とか
#
# Author:
#   muro1214

config = 
  roomName: process.env.HUBOT_SLACK_ROOMNAME

module.exports = (robot) ->
  say = (message) ->
    robot.send {room: config.roomName}, message

  robot.respond /.*[いお]る[の]?[ーか]*?？/i, (msg) ->
    say "いますよ。"
