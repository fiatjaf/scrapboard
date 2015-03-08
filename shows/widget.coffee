->
  ddoc = this
  settings = ddoc.settings

  provides 'js', ->
    """
    #{if settings and settings.hashcash then 'window.use_hashcash = true' else ''}
    
    window.basePath = '#{settings.baseURL}'
    window.isWidget = true
    
    document.write('<div id="scrapboard-main"></div>')
    document.write('<script src="#{settings.baseURL}/bundle.js"></script>')
    document.write('<link rel="stylesheet" href="#{settings.baseURL}/style.css">')
    """
