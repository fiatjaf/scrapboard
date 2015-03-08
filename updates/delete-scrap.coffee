(doc, req) ->
  if not doc
    return [null, '']

  doc._deleted = true

  return [doc, toJSON {ok: true}]
