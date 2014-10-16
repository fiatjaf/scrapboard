(doc) ->
  if doc.where == 'elsewhere'
    emit [doc.timestamp, doc.target]
