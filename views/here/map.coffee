(doc) ->
  if doc.where == 'here' and doc.content
    emit doc.timestamp
