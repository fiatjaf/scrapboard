(newDoc, oldDoc, userCtx, secObj) ->
  hashcash = require 'lib/hashcash-token'
  sha256 = require('lib/sha256').sha256
  v = require 'lib/validator'
  ddoc = this
  NOW = (new Date).getTime()
  isInternal = (key) -> key[0] == '_'
  userIsAdmin = ->
    if userCtx.name in secObj.admins.names
      return true

    for role in userCtx.roles
      if role in secObj.admins.roles
        return true

    # a quirk of the smileupps databases
    if '_admin' in userCtx.roles
      return true

    return false

  ######### start validating

  if newDoc.where == 'here'
    # outsiders posting here

    # don't allow modification of docs
    # this also covers people trying to delete docs and other attacks
    if oldDoc and not userIsAdmin()
      throw forbidden: 'Can\'t change scraps already posted.'

    for key, val of newDoc
      # don't allow nested objects
      if val and typeof val is 'object' and not isInternal key
        throw forbidden: key + ' is an object and this is not allowed.'

      # a specific rule for each key
      switch key
        when '_id' then throw forbidden: '_id is too small.' if val.length < 6
        when 'content' then throw forbidden: 'content is not a string.' if v.isNull val
        when 'from' then throw forbidden: 'from is not a URL.' unless v.isURL val
        when 'verified' then throw forbidden: 'verified is not boolean.' unless typeof val is 'boolean'
        when 'timestamp' then throw forbidden: 'timestamp is not a number.' unless typeof val is 'number'
        when 'email' then throw forbidden: 'email is not a real email.' unless v.isEmail val
        when 'srcid', 'name', 'where', 'webmention', 'hashcash' then null
        else
          unless isInternal key
            throw forbidden: "#{key} is not an allowed key."

    # checks only made at the original database, not replication
    if secObj and secObj.admins and 'anti-abuse' in secObj.admins.roles and not userIsAdmin()

      # check the correct timestamp
      if newDoc.timestamp > NOW + 60000 or newDoc.timestamp < NOW - 60000
        throw forbidden: 'timestamp is not now.'

      # check hashcash token (anti-spam)
      if ddoc.settings and ddoc.settings.hashcash and not userIsAdmin()
        throw unauthorized: 'hashcash token needed.' if not newDoc.hashcash
        token = JSON.parse newDoc.hashcash
        throw unauthorized: 'hashcash token wrong.' if not hashcash.validate token, {
          difficulty: 20000
          data: sha256(NOW.toString().substr(0, 8) + ddoc.settings.hashcash)
        }

      # check if the document is not marked as verified
      if newDoc.verified is not false
        throw forbidden: 'verified is not false.'

      # check if the _id corresponds to the timestamp (one _id for each 100 seconds)
      # (but relax it a little (10x), so numerical breaks don't affect the normal user)
      if newDoc._id.substr(0, 7) != NOW.toString().substr(0, 7)
        throw forbidden: "you're sending a scrap with a wrong timestamp."
    ## ~

  else if newDoc.where == 'elsewhere'
    # myself posting elsewhere
    throw unauthorized: 'you are not an authorized user.' if not userIsAdmin()

  else
    throw forbidden: 'where is invalid.'
