(head, req) ->

  fetch = ->
    results = []
    while row = getRow()
      doc = row.doc
      results.push doc
    results

  provides 'html', ->
    tpl = require 'app/template'
    data =
      scraps: fetch()
    tpl data

  provides 'json', ->
    toJSON fetch()
