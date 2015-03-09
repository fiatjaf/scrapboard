(doc) ->
  provides 'json', ->
    if doc.where
      return toJSON doc
