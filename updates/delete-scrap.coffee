(doc, req) ->
  url = require 'lib/urlparser'
  if url.parse(@settings.baseURL).host != url.parse(req.headers.Referer).host
    # don't accept requests from external domains
    # prevent bizarre attacks using cors
    return [null, '']

  if not doc
    return [null, '']

  doc._deleted = true

  return [doc, toJSON {ok: true}]
