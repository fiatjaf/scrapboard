(doc, req) ->
  ddoc = this
  url = require 'node_modules/urlparser'
  {getQuickBasePath, getProtocol} = require 'app/utils'

  protocol = getProtocol req, ddoc
  here = url.parse(protocol + '://' + req.headers['Host'])

  if here.host == url.parse(req.form.target).host
    doc =
      _id: (new Date).getTime().toString().substr(0, 8)
      from: req.form.source
      where: 'here'
      webmention: true
      verified: false
      timestamp: (new Date).getTime()

    response =
      code: 202
      body: protocol + '://' + here.host + getQuickBasePath(req.requested_path) + '/_db/' + req.uuid

  else
    doc = null
    response =
      code: 400

  return [doc, response]
