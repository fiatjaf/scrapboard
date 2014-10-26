(doc, req) ->
  try
    data = JSON.parse req.body
  catch e
    data = req.form

  if not doc
    doc =
      _id: req.id or req.uuid

  doc.target = data.target
  doc.content = data.content
  doc.name = data.name or req.userCtx.name
  doc.timestamp = (new Date).getTime()
  doc.where = 'elsewhere'

  return [doc, JSON.stringify {ok: true, id: req.id or req.uuid}]
