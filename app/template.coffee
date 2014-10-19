React = require 'node_modules/react'
Scrapbook = require 'app/Scrapbook'

{getPathParts, getHasRewrite, getBasePath, getQuickBasePath} = require 'app/path-utils'

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
    pathParts = (#{getPathParts.toString()})(location.pathname)
    hasRewrite = (#{getHasRewrite.toString()})(pathParts)
    basePath = (#{getBasePath.toString()})(pathParts, hasRewrite)

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
