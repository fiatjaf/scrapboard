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
    return basePath.filter((x) -> x.trim()).join '/'
  else
    return ''

getQuickBasePath = (fullPathName) ->
  fullPathName = fullPathName.trim()

  if fullPathName.slice(0, 7) == 'http://' or \
     fullPathName.slice(0, 8) == 'https://' or \
     fullPathName.slice(0, 2) == '//'
    if fullPathName.slice(-1) == '/'
      return fullPathName.slice 0, -1
    else
      return fullPathName

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

urlparser = require 'lib/urlparser'
isInURL = (referrer, allowedAddresses) ->
  if referrer.substr(0, 4) != 'http'
    if referrer.substr(4, 2) not in ['//', ':/']
      referrer = '://' + referrer
    referrer = 'http://' + referrer

  host = urlparser.parse(referrer).host
  for url in allowedAddresses
    if url.substr(0, 4) isnt 'http'
      if url.substr(4, 2) not in ['//', ':/']
        url = '://' + url
      url = 'http' + url
    allowed = urlparser.parse(url).host

    if allowed == host
      return true

module.exports =
  getPathParts: getPathParts
  getHasRewrite: getHasRewrite
  getBasePath: getBasePath
  getQuickBasePath: getQuickBasePath
  getProtocol: getProtocol
  isInURL: isInURL
