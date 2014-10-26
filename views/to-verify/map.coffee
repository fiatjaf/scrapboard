(doc) ->
  if doc.where == 'here' and doc.verified == false
    if doc.from and doc.srcid
      emit doc.timestamp, [doc.from, doc.srcid]

    #else if doc.webmention
    #  emit doc.timestamp, doc.from
