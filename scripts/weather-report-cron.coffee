# Description:
#   天気予報定期出力スクリプト
#   毎朝7時30分に小田原市の天気予報を報告します
#
# Configuration:
#   HUBOT_SLACK_ROOMNAME
#   HUBOT_YAHOO_GEOCODER_APP_KEY
#   HUBOT_OPENWEATHER_API_KEY
#
# Commands:
#  None
#
# Author:
#  muro1214

dateFormat = require 'dateformat'
cron = require('cron').CronJob

config = 
  roomName: process.env.HUBOT_SLACK_ROOMNAME
  getCoderKey: process.env.HUBOT_YAHOO_GEOCODER_APP_KEY
  openWeatherKey: process.env.HUBOT_OPENWEATHER_API_KEY

module.exports = (robot) ->
  say = (message) ->
    robot.send {room: config.roomName}, message

  new cron "0 30 7 * * *", () ->
    robot.http('http://api.openweathermap.org/data/2.5/forecast/daily')
      .query({
        lon: '139.16'
        lat: '35.26'
        units: 'metric'
        cnt: 1
        APPID: config.openWeatherKey
      })
      .get() (err, res, body) ->
        if err
          say 'Failed to get openWeather API.'
          return
      
        result = JSON.parse(body)
        message = "【\"小田原\" 今日の天気予報 #{dateFormat(new Date, "yyyy/mm/dd(ddd)")} 】\n" +
        "http://openweathermap.org/img/w/#{result.list[0].weather[0].icon}.png\n" +
        "天候：#{getWeatherJapanese result.list[0].weather[0].icon}\n" +
        "最低気温：#{Math.round result.list[0].temp.min}[℃]  最高気温：#{Math.round result.list[0].temp.max}[℃]\n" +
        "気温推移(朝->昼->夕方->夜)：#{Math.round result.list[0].temp.morn}[℃] -> #{Math.round result.list[0].temp.day}[℃] -> #{Math.round result.list[0].temp.eve}[℃] -> #{Math.round result.list[0].temp.night}[℃]\n" +
        "湿度：#{result.list[0].humidity}[%]\n" +
        "風速(風向)：#{Math.round(result.list[0].speed * 10) / 10}[m/s] (#{getDegreeName result.list[0].deg})\n" +
        "気圧：#{result.list[0].pressure}[hpa]\n" +
        "雲量：#{result.list[0].clouds}[%]"
        say message
  , null, true

getWeatherJapanese = (icon) ->
  match = /(\d{2})[dn]/.exec(icon)
  if match?
    switch match[1]
      when '01'
        return '快晴'
      when '02'
        return '晴れ'
      when '03'
        return 'くもり'
      when '04'
        return 'くもり'
      when '09'
        return '小雨'
      when '10'
        return '雨'
      when '11'
        return '雷雨'
      when '13'
        return '雪'
      when '50'
        return '霧'
      else
        return "不明(#{match[1]})"

getDegreeName = (degree) ->
  dname = ['北','北北東','北東', '東北東', '東', '東南東', '南東', '南南東', '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西', '北']
  dindex = Math.round( degree / 22.5 )
  
  return dname[dindex]
