React = require 'lib/react'
Scrapbook = require 'components/Scrapbook'

module.exports = (data) ->
  """
<!DOCTYPE html>
<html>
  <head>
    <title>Scrapbook</title>
    <link rel="stylesheet" href="style.css" type="text/css">
  </head>
  <body>

    <div id="main">
      #{React.renderComponentToString Scrapbook(data)}
    </div>

  </body>

  <script>
    window.data = #{toJSON data}
  </script>
  <script src="bundle.js"></script>

</html>
  """
