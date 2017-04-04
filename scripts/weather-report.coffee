# Description:
#   Example scripts for you to examine and try out.
#
# Commands:
#  hubot <(地名)の天気> - <地名の天気予報を出力する>
#
# Author:
#  muro1214


dateFormat = require 'dateformat'

module.exports = (robot) ->
  robot.respond /.*今の天気.*/i, (msg) ->
#    place = msg.match[1]
    place = "250-0055"
    city = null

    msg.http('http://api.openweathermap.org/data/2.5/weather')
      .query({
        q: "Odawara-shi,JP"
        units: 'metric'
        APPID: '21ca694fd8febafe8c4c67bf02ca3954' 
      })
      .get() (err, res, body) ->
        if err
          msg.send('Failed to get livedoor weather rest api.')
          return
        
        result = JSON.parse(body)
        message = "小田原市の現在の天気予報です\n" +
        "天気は「#{result.weather[0].main}」ですね\n" +
        "現在の気温は #{result.main.temp}[℃]、最高気温は #{result.main.temp_max}[℃]、最低気温は #{result.main.temp_min}[℃]ですよ"
        robot.logger.debug message
        robot.send {room: "rabbit-house"}, message
