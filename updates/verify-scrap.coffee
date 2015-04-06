(doc, req) ->
  url = require 'lib/urlparser'
  {isInURL} = require 'lib/utils'

  if not isInURL req.headers.Referer, (@settings.hosts or []).concat(@settings.baseURL)
    return [null, {code: 403}]

  if not doc
    return [null, {code: 400}]

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
