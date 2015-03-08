(doc, req) ->
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
