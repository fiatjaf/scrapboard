(doc, req) ->
  location = if req.path.indexOf '_rewrite' isnt -1 then '_rewrite/scraps' else 'scraps'
  query = 'include_docs=true'

  code: 302
  headers:
    location: location + '?' + query
