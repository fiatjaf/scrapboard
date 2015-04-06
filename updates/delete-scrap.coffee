(doc, req) ->
  url = require 'lib/urlparser'
  {isInURL} = require 'lib/utils'

  if not isInURL req.headers.Referer, (@settings.hosts or []).concat(@settings.baseURL)
    return [null, {code: 403}]

  if not doc
    return [null, {code: 400}]

  doc._deleted = true

  return [doc, toJSON {ok: true}]
