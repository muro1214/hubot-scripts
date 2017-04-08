var client = require('cheerio-httpcli')

client.fetch('http://zasa.sakura.ne.jp/dp/run.php', {}, function (err, $, res) {
  var regex = /☆12 \((\d{2}\.\d)\)/;

  $('tr').each(function() {
    var target = $(this)
    if (target.children().hasClass('music')) {
      if (target.text().match(regex)) {
        // music name
        music = target.children('.music').text();
        
        var child = target.children('.rank')
        
        // Hyper
        var data = getUnofficialLevel(child, 0, regex);
        if (typeof data !== 'undefined') {
          console.log(data.id + ',' + music + ',2,12,' + data.level);
        }
         
        // Another
        data = getUnofficialLevel(child, 1, regex);
        if (typeof data !== 'undefined') {
          console.log(data.id + ',' + music + ',3,12,' + data.level);
        }
        
        // LEGGENDARIA - KASU!!!!!!!!!!!!!
        data = getUnofficialLevel(child, 2, regex);
        if (typeof data !== 'undefined') {
          console.log(data.id + ',' + music + '†,99,12,' + data.level);
        }
      }
    }
  });

});

function getUnofficialLevel(child, idx, regex){
  if (child.eq(idx).text().match(regex)) {
    unLvl = RegExp.$1;
    unId = child.eq(idx).find('a').attr('href').split('=')[1];

    return {id: unId, level: unLvl};
  } else {
    return undefined; 
  }
}
