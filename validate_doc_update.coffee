(newDoc, oldDoc, userCtx, secObj) ->
  v = require 'node_modules/validator'
  isInternal = (key) -> key[0] == '_'
  userIsAdmin = ->
    ## normalize cloudant secObj
    if secObj.cloudant
      if '_writer' in secObj.cloudant.nobody
        return true

      names = []
      for name, roles in secObj.cloudant
        names.push name if '_writer' in roles

      roles = []
    
    else
      if not secObj.members and not secObj.admins
        return true

      admins = secObj.admins or {}
      members = secObj.members or {}
      names = (admins.names or []).concat(members.names or [])
      roles = (admins.roles or []).concat(members.roles or [])
    ## now we have a standard "names" and a standard "roles"

    if userCtx.name in names
      return true

    for role in userCtx.roles
      if role in roles
        return true

  ######### start validating

  if newDoc.where == 'here'
    # outsiders posting here
    if oldDoc and not userIsAdmin()
      throw forbidden: 'Can\'t change scraps already posted.'

    for key, val of newDoc
      if val and typeof val is 'object' and not isInternal key
        throw forbidden: key + ' is an object and this is not allowed.'

      switch key
        when '_id' then throw forbidden: '_id is too small.' if val.length < 6
        when 'content' then throw forbidden: 'content is not a string.' if v.isNull val
        when 'from' then throw forbidden: 'from is not a URL.' unless v.isURL val
        when 'verified' then throw forbidden: 'verified is not boolean.' unless typeof val is 'boolean'
        when 'timestamp' then throw forbidden: 'timestamp is not a number.' unless typeof val is 'number'
        when 'email' then throw forbidden: 'email is not a real email.' unless v.isEmail val
        when 'srcid', 'name', 'where', 'webmention' then null
        else
          unless isInternal key
            throw forbidden: "#{key} is not an allowed key."

    # checks only made at the original database, not replication
    if secObj and secObj.admins and 'anti-abuse' in secObj.admins.roles

      # check the correct timestamp
      now = (new Date).getTime()
      if newDoc.timestamp > now + 60000 or newDoc.timestamp < now - 60000
        throw forbidden: 'timestamp is not now.'

      # check if the document is not marked as verified
      if newDoc.verified is not false and userCtx.name != newDoc.name
        throw forbidden: 'verified is not false.'

      # check if the _id corresponds to the timestamp (one _id for each 100 seconds)
      # (but relax it a little (10x), so numerical breaks don't affect the normal user)
      if newDoc._id.substr(0, 7) == (new Date).getTime().toString().substr(0, 7)
        throw forbidden: "you're trying to create too much scraps, wait a little"
    ## ~

  else if newDoc.where == 'elsewhere'
    # myself posting elsewhere
    throw unauthorized: 'you are not an authorized user.' if not userIsAdmin()

  else
    throw forbidden: 'where is invalid.'
