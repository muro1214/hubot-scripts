# Description:
#   現在の天気を取得するスクリプト
#
# Configuration:
#   HUBOT_SLACK_ROOMNAME
#   HUBOT_YAHOO_GEOCODER_APP_KEY
#   HUBOT_OPENWEATHER_API_KEY
#
# Commands:
#  hubot <地名>の(今|現在)の天気 - 現在の天気情報を返す
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

  robot.hear /^(\S+)の(今|現在)の天気/i, (msg) ->
    place = msg.match[1]
    
    say "#{place}の#{msg.match[2]}の天気ですね。わかりました。少し待ってください。"
    
    #get geocording
    msg.http('https://map.yahooapis.jp/geocode/V1/geoCoder')
      .query({
        appid: config.getCoderKey
        query: place
        results: 1
        output: 'json'
      })
      .get() (err, res, body) ->
        geoinfo = JSON.parse(body)
        coordinates = (geoinfo.Feature[0].Geometry.Coordinates).split(",")

        msg.http('http://api.openweathermap.org/data/2.5/weather')
          .query({
            lon: coordinates[0]
            lat: coordinates[1]
            units: 'metric'
            APPID: config.openWeatherKey
          })
          .get() (err, res, body) ->
            if err
              say 'Failed to get openWeather API.'
              return
        
            result = JSON.parse(body)
            message = "【\"#{place}\" 現在の天気 #{dateFormat(new Date(result.dt * 1000), "yyyy/mm/dd HH:MM(ddd)")}時点 】\n" +
            "http://openweathermap.org/img/w/#{result.weather[0].icon}.png\n" +
            "天候：#{getWeatherJapanese result.weather[0].icon}\n" +
            "現在の気温：#{Math.round result.main.temp}[℃]\n" +
            "湿度：#{result.main.humidity}[%]\n" +
            "風速(風向)：#{Math.round(result.wind.speed * 10) / 10}[m/s] (#{getDegreeName result.wind.deg})\n" +
            "気圧：#{result.main.pressure}[hpa]\n" +
            "雲量：#{result.clouds.all}[%]\n" +
            "日の出：#{dateFormat(new Date(result.sys.sunrise * 1000), "yyyy/mm/dd HH:MM")}\n" +
            "日の入り：#{dateFormat(new Date(result.sys.sunset * 1000), "yyyy/mm/dd HH:MM")}"

            if result.rain?
              message += "\n降雨量(直近3時間)：#{result.rain['3h']}[mm]"
            if result.snow?
              message += "\n降雪量(直近3時間)：#{result.snow['3h']}[mm]"
            
            say message

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
  dname = ['北', '北北東', '北東', '東北東', '東', '東南東', '南東', '南南東', '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西', '北']
  dindex = Math.round( degree / 22.5 )
  
  return dname[dindex]
