getPathParts = (fullPathName) ->
  if typeof fullPathName is 'string'
    fullPathName.trim().split('/')
  else if fullPathName[0] != '' and fullPathName[0].substr(0, 4) != 'http'
    [''].concat fullPathName
  else
    fullPathName
  
getHasRewrite = (pathParts) -> pathParts.indexOf('_rewrite') isnt -1
getBasePath = (pathParts, hasRewrite=true) ->
  if hasRewrite
    basePath = []
    for part in pathParts
      basePath.push part
      break if part == '_rewrite'
    return basePath.join '/'
  else
    return ''
getQuickBasePath = (fullPathName) ->
  pathParts = getPathParts fullPathName
  hasRewrite = getHasRewrite pathParts
  return getBasePath pathParts, hasRewrite

getProtocol = (req, ddoc) ->
  if ddoc.settings and ddoc.settings.protocol
    protocol = ddoc.settings.protocol.replace /\W/g, ''
  if not protocol
    port = req.headers['Host'].split(':')[1]
    if port == '80'
      protocol = 'http'
    else
      protocol = 'https'
  protocol

module.exports =
  getPathParts: getPathParts
  getHasRewrite: getHasRewrite
  getBasePath: getBasePath
  getQuickBasePath: getQuickBasePath
  getProtocol: getProtocol
