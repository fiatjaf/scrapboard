(doc, req) ->
  try
    data = JSON.parse req.body
  catch e
    data = req.form

  v = require 'node_modules/validator'

  if not doc
    doc =
      _id: req.uuid
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

    if req.userCtx and req.userCtx.name
      doc.name = req.userCtx.name
      doc.verified = true

    if doc.name == doc.from
      if v.isURL(doc.name) then delete doc.name
      else delete doc.from

    return [doc, JSON.stringify {ok: true, id: req.uuid}]

  else
    # scrap modification is not allowed
    return [null, JSON.stringify {ok: false, why: 'forbidden'}]
