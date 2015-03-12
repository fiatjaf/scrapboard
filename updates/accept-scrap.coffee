(doc, req) ->
  try
    data = JSON.parse req.body
  catch e
    data = req.form

  v = require 'lib/validator'
  responseHeaders = {}

  if not doc
    doc =
      _id: (new Date).getTime().toString().substr(0, 8) # one new _id allowed
                                                        # at each 100 seconds
      content: data.content
      name: data.name   # optional
      where: 'here'
      verified: false
      timestamp: (new Date).getTime()

    if data.srcid
      # the url of the scrap document corresponding to
      # this scrap at the authors own scrapbook instance.
      doc.srcid = data.srcid

    if data.from
      # the scrapbook url of the person who posted this scrap
      doc.from = data.from
      responseHeaders['Set-Cookie'] = "myscrapbook=#{encodeURIComponent data.from}; Max-Age=93312000; Version=1; Path=/; HttpOnly"

    if req.userCtx and req.userCtx.name
      doc.name = req.userCtx.name
      doc.verified = true

    if doc.name == doc.from
      if v.isURL(doc.name) then delete doc.name
      else delete doc.from

    if data.hashcash
      doc.hashcash = JSON.stringify data.hashcash

    return [
      doc,
      {
        code: 200
        json: {ok: true, id: req.uuid}
        headers: responseHeaders
      }
    ]

  else
    # scrap modification is not allowed
    return [null, JSON.stringify {ok: false, why: 'forbidden'}]
