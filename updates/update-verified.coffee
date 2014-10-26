(doc, req) ->
  if not doc
    return [null, '']

  data = JSON.parse req.body

  doc.verified = data.verified
  doc.content = data.content
  doc.name = data.name

  return [doc, toJSON {ok: true}]
