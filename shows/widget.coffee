->
  ddoc = this
  settings = ddoc.settings

  provides 'js', ->
    """
    #{if settings and settings.hashcash then 'window.use_hashcash = true' else ''}
    
    window.basePath = '#{settings.baseURL}'
    window.isWidget = true
    
    document.write('<div id="scrapboard-main"></div>')
    document.write('<script src="#{settings.baseURL}/_ddoc/bundle.js"></script>')
    document.write('<link rel="stylesheet" href="#{settings.baseURL}/_ddoc/style.css">')
    """
