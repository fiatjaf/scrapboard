(doc, req) ->
  url = require 'lib/urlparser'
  if url.parse(@settings.baseURL).host != url.parse(req.headers.Referer).host
    # don't accept requests from external domains
    # prevent bizarre attacks using cors
    return [null, "you can't do this from an external URL. go to #{@settings.baseURL} to do this."]

  if not doc
    return [null, '']

  try
    data = JSON.parse req.body
  catch e
    data = {}

  doc.verified = true

  if data.content
    doc.content = data.content

  if data.name
    doc.name = data.name

  return [doc, toJSON doc]
