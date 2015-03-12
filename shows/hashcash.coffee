->
  ddoc = this

  if not ddoc.settings or not ddoc.settings.hashcash
    return ''

  sha256 = require('lib/sha256').sha256
  NOW = (new Date).getTime()

  code: 200
  headers:
    'Cache-Control': 'no-cache, no-store, must-revalidate'
    'Pragma': 'no-cache'
    'Expires': '0'
  body: sha256(NOW.toString().substr(0, 8) + ddoc.settings.hashcash)
