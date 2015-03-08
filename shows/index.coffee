(doc, req) ->
  location = 'scraps'
  query = 'include_docs=true&descending=true&limit=25'

  code: 302
  headers:
    location: location + '?' + query
