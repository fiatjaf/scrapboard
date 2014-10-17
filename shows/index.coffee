(doc, req) ->
  location = if '_rewrite' == req.path.slice(-1)[0] then req.raw_path + '/scraps' else 'scraps'
  query = 'include_docs=true'

  code: 302
  headers:
    location: location + '?' + query
