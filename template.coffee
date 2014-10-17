React = require 'node_modules/react'
Scrapbook = require 'components/Scrapbook'

module.exports = (data) ->
  """
  <!DOCTYPE html>
  
  <title>Scrapbook</title>
  
  <div id="main">
    #{React.renderComponentToString Scrapbook(data)}
  </div>
  
  <script> window.data = #{toJSON data} </script>
  <script src="//cdnjs.cloudflare.com/ajax/libs/lazyload/2.0.3/lazyload-min.js"></script>
  <script>
    pathParts = location.pathname.split('/').filter(function(x) { return x })
    hasRewrite = pathParts.indexOf('_rewrite') !== -1
    basePath = (function () {
      var basePath;
      if (hasRewrite) {
        basePath = [];
        for (_i = 0, _len = pathParts.length; _i < _len; _i++) {
          part = pathParts[_i];
          basePath.push(part);
          if (part === '_rewrite') {
            break;
          }
        }
        basePath = '/' + basePath.join('/')
      }
      else {
        basePath = ''
      }
      return basePath
    })()

    if (hasRewrite) {
      LazyLoad.js(basePath + '/_ddoc/bundle.js')
      LazyLoad.css(basePath + '/_ddoc/style.css')
    }
    else {
      LazyLoad.js(basePath + '/bundle.js')
      LazyLoad.css(basePath + '/style.css')
    }
  </script>
  """
