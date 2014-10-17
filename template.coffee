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
  <script src="//cdn.rawgit.com/dolox/fallback/v1.1.4/fallback.min.js"></script>
  <script>
    fallback.load({
      style: [
        "_rewrite/_ddoc/style.css",
        "/style.css"
      ],
      app: [
        "_rewrite/_ddoc/bundle.js",
        "/bundle.js"
      ]
    })
  </script>
  """
