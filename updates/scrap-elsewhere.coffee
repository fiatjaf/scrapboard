(doc, req) ->
  data = if req.method is 'PUT' then JSON.parse(req.body) else req.form

  if not doc
    doc =
      _id: req.id or req.uuid
      content: data.content
      target: data.target
      where: 'elsewhere'
      timestamp: (new Date).getTime()

  else
    doc.content = data.content
    doc.timestamp = (new Date).getTime()
    doc.where = 'elsewhere'

  return [doc, JSON.stringify {ok: true, id: req.id or req.uuid}]
