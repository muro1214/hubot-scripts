# Description:
#   雨雲レーダーを取得するスクリプト
#
# Configuration:
#   HUBOT_SLACK_ROOMNAME
#   HUBOT_YAHOO_GEOCODER_APP_KEY
#   HUBOT_OPENWEATHER_API_KEY
#
# Commands:
#  雨雲(レーダー|レーダ|情報)? <地名> (ズーム|zoom|拡大)? - 当該地点の雨雲レーダーを返す
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

  robot.hear /^雨雲(レーダー|レーダ|情報)?[\s　](\S+)[\s　]?(ズーム|zoom|拡大)?$/i, (msg) ->
    place = msg.match[2]
    zoom = if msg.match[3] then '14' else '12'
    zoomSay = if msg.match[3] then 'のズーム' else ''

    say "#{place}の雨雲レーダー#{zoomSay}画像ですね。わかりました。少し待ってください。"
    
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
        say getRainFallUrl coordinates[0], coordinates[1], zoom

getRainFallUrl = (lon, lat, zoom) ->
  width = 500
  height = 500
  
  datetime = (new Date()).toISOString().replace(/[^0-9]/g, "")
  url = "https://map.yahooapis.jp/map/V1/static?appid=#{config.getCoderKey}" +
  "&lon=#{lon}&lat=#{lat}" +
  "&z=#{zoom}" +
  "&width=#{width}&height=#{height}" +
  "&overlay=type:rainfall|date:#{datetime}"

  return url
