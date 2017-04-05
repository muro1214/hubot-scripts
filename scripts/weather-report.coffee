# Description:
#   天気予報取得スクリプト
#
# Configuration:
#   HUBOT_SLACK_ROOMNAME
#   HUBOT_YAHOO_GEOCODER_APP_KEY
#   HUBOT_OPENWEATHER_API_KEY
#
# Commands:
#  hubot <地名>の(<日付>)?の天気 - 天気情報を返す
#  日付＝今日、明日、10日後とか。MM/ddではないです
#
# Author:
#  muro1214

dateFormat = require 'dateformat'

config = 
  roomName: process.env.HUBOT_SLACK_ROOMNAME
  getCoderKey: process.env.HUBOT_YAHOO_GEOCODER_APP_KEY
  openWeatherKey: process.env.HUBOT_OPENWEATHER_API_KEY

module.exports = (robot) ->
  say = (message) ->
    robot.send {room: config.roomName}, message

  robot.hear /^天気[\s　](\S+)[\s　]?(明日|あさって|明後日|しあさって|明明後日|明々後日|\d{1,2}日後)?/i, (msg) ->
    place = msg.match[1]
    date = msg.match[2] ? '今日'
    
    say "#{place}の#{date}の天気予報ですね。わかりました。調べてきます。"
    
    #get geocording
    cordinates = null
    msg.http('http://geo.search.olp.yahooapis.jp/OpenLocalPlatform/V1/geoCoder')
      .query({
        appid: config.getCoderKey
        query: place
        results: 1
        output: 'json'
      })
      .get() (err, res, body) ->
        geoinfo = JSON.parse(body)
        cordinates = (geoinfo.Feature[0].Geometry.Coordinates).split(",")
    
    count = getCount date
    msg.http('http://api.openweathermap.org/data/2.5/forecast/daily')
      .query({
        lon: coordinates[0]
        lat: coordinates[1]
        units: 'metric'
        cnt: count
        APPID: config.openWeatherKey
      })
      .get() (err, res, body) ->
        if err
          msg.send('Failed to get openWeather API.')
          return
        
        result = JSON.parse(body)
        forecastTime = new Date(result.list[count - 1].dt * 1000)
        message = "【#{place} #{date}の天気予報 (発表：#{dateFormat(forecastTime, "yyyy/mm/dd HH:MM:ss")})】\n" +
        "http://openweathermap.org/img/w/#{result.list[count - 1].weather[0].icon}\n" +
        "天候：#{getWeatherJapanese result.list[count - 1].weather[0].icon}\n" +
        "最低気温：#{Math.round result.list[count - 1].temp.min}[℃]  最高気温：#{Math.round result.list[count - 1].temp.max}[℃]\n" +
        "気温推移(朝 -> 昼 -> 夕方 -> 夜)：#{Math.round result.list[count - 1].temp.morn}[℃] -> #{Math.round result.list[count - 1].temp.day}[℃] -> #{Math.round result.list[count - 1].temp.eve}[℃] -> #{Math.round result.list[count - 1].temp.night}[℃]\n" +
        "湿度：#{result.list[count - 1].humidity}[%]\n" +
        "風速(風向)：#{result.list[count - 1].speed}[m/s] (#{getDegreeName result.list[count - 1].deg})\n" +
        "気圧：#{result.list[count - 1].pressure}[hpa]\n" +
        "雲量：#{result.list[count - 1].coulds}[%]"
        robot.logger.debug message
        say message

getCount = (date) ->
  if date == '今日'
    return 1
  else if date == '明日'
    return 2
  else if date == '明後日' || date == 'あさって'
    return 3
  else if date == '明々後日' || date == '明明後日' || date == 'しあさって'
    return 4
  
  match = /(\d{1,2})日後/.exec(date)
  if match?
    count = match[1]
    return count + 1

getWeatherJapanese = (icon) ->
  match = /\d{2}[dn]/.exec(icon)
  if match?
    switch match[1]
      when '01'
        return '快晴'
      when '02'
        return '晴れ'
      when '03'
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
