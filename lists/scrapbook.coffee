(head, req) ->
  ddoc = this

  if not req.query.include_docs or
     not req.query.limit or req.query.limit > 25 or
     req.query.skip or req.query.reduce
    location = ddoc.settings.baseURL or if req.raw_path.indexOf '_rewrite' isnt -1 then '_rewrite' else '/'
    return {
      code: 302
      headers:
        location: location
    }

  fetch = ->
    scraps = []
    while row = getRow()
      doc = row.doc
      scraps.push doc
      lastkey = row.key

    query = ["startkey=#{lastkey}"]
    for key, value of req.query
      if key isnt 'startkey'
        query.push key + '=' + value

    scraps: scraps
    nextpage: '?' + query.join('&')
    firstpage: '?' + query.slice(1).join('&')
    visitorsScrapbookURL: decodeURIComponent req.cookie.MyScrapbookURL

  provides 'json', ->
    toJSON fetch()

  provides 'html', ->
    tpl = require 'app/template'
    data = fetch()
    tpl data, req, ddoc
