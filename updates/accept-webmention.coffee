(doc, req) ->
  log 'x'

  ddoc = this
  url = require 'node_modules/urlparser'
  {getQuickBasePath, getProtocol} = require 'app/utils'

  protocol = getProtocol req, ddoc

  log protocol

  here = url.parse(protocol + '://' + req.headers['Host'])

  log here

  if here.host == url.parse(req.form.target).host
    doc =
      _id: req.uuid
      from: req.form.source
      where: 'here'
      webmention: true
      verified: false
      timestamp: (new Date).getTime()

    log doc

    response =
      code: 202
      body: protocol + '://' + here.host + getQuickBasePath(req.requested_path) + '/_db/' + req.uuid

  else
    doc = null
    response =
      code: 400

  log response

  return [doc, response]
