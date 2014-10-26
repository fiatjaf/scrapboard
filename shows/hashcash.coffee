->
  ddoc = this

  if not ddoc.settings or not ddoc.settings.hashcash
    return ''

  sha256 = require('node_modules/sha256').sha256
  NOW = (new Date).getTime()
  return sha256(NOW.toString().substr(0, 8) + ddoc.settings.hashcash)
