React = require 'node_modules/react'
Scrapbook = require 'app/Scrapbook'

{getPathParts, getHasRewrite, getBasePath, getQuickBasePath, getProtocol} = require 'app/utils'

module.exports = (data, req, ddoc) ->
  """
  <!DOCTYPE html>
  
  <title>Scrapbook</title>
  <link href="#{getProtocol req, ddoc}://#{req.headers['Host'] + getQuickBasePath(req.requested_path)}/webmention" rel="webmention">
  
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
