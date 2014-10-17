(newDoc, oldDoc, userCtx, secObj) ->
  v = require 'node_modules/validator'

  if newDoc.where == 'here'
    # outsiders posting here
    if oldDoc
      throw forbidden: 'Can\'t change scraps already posted.'

    for key, val of newDoc
      switch key
        when '_id' then throw forbidden: '_id is too small.' if val.length < 20
        when 'content' then throw forbidden: 'content is not a string.' if v.isNull val
        when 'src' then throw forbidden: 'src is not a URL.' unless v.isURL val
        when 'from' then throw forbidden: 'from is not a URL.' unless v.isURL val
        when 'verified' then throw forbidden: 'verified is not boolean.' unless typeof val is 'boolean'
        when 'timestamp' then throw forbidden: 'timestamp is not a number.' unless typeof val is 'number'
        when 'name' then throw forbidden: 'name is not a string.' if v.isNull val
        when 'email' then throw forbidden: 'email is not a real email.' unless v.isEmail val
        when 'where' then null
        else
          if key[0] isnt '_'
            throw forbidden: "#{key} is not an allowed key."

    # checks only made at the original database, not replication
    if secObj and secObj.admins and 'original' in secObj.admins.roles

      now = (new Date).getTime()
      if newDoc.timestamp > now + 60000 or newDoc.timestamp < now - 60000
        throw forbidden: 'timestamp is not now.'

      if newDoc.verified is not false
        throw forbidden: 'verified is not false.'

  else if where == 'elsewhere'
    # myself posting elsewhere
    if userCtx.name in secObj.members.names
      return

    for role in userCtx.roles
      if role in secObj.members.roles
        return

    throw unauthorized: 'you are not an authorized user.'

  else
    throw forbidden: 'where is invalid.'
