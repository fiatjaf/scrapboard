(doc, req) ->
  try
    data = JSON.parse req.body
  catch e
    data = req.form

  if not doc
    doc =
      _id: req.uuid
      content: data.content
      name: data.name   # optional
      where: 'here'
      verified: false
      timestamp: (new Date).getTime()

    if data.src
      # the url of the scrap document corresponding to
      # this scrap at the authors own scrapbook instance.
      doc.src = data.src

    if data.from
      # the scrapbook url of the person who posted this scrap
      doc.from = data.from

    return [doc, JSON.stringify {ok: true, id: req.uuid}]

  else
    # scrap modification is not allowed
    return [null, JSON.stringify {ok: false, why: 'forbidden'}]
