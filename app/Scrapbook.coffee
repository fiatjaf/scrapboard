React = require 'lib/react'
hashcash = require 'lib/hashcash-token'
superagent = require 'lib/superagent'

{getQuickBasePath} = require 'lib/utils'

{div, time, a, form, input, textarea, button} = React.DOM

Scrapbook = React.createClass
  getInitialState: ->
    externalLoginURL: null
    showNameInput: true
    verifying: false

  componentDidMount: ->
    if not @props
      @loadScraps()

    # get domain or name at localStorage
    @refs.from.getDOMNode().value = localStorage.getItem 'domain/name'

  doShowNameInput: -> @setState showNameInput: true
  dontShowNameInput: -> @setState showNameInput: false

  handleLogin: ->
    @dontShowNameInput()
    @setState verifying: true
    @verifyScraps()

  handleLogout: ->
    @doShowNameInput()
    @setState verifying: false

  loadScraps: ->
    superagent.get(location.href)
              .set('accept', 'application/json')
              .end (err, res) =>
      if not err
        @setProps res.body

  verifyScraps: ->
    if not @state.verifying
      return
    else
      # first we fetch one row of docs waiting to be verified
      superagent.get(basePath + '/_ddoc/_view/to-verify?limit=1')
                .set('accept', 'application/json')
                .withCredentials()
                .end (err, res) =>
        if err
          return console.log err

        # we stop de process if there are not more docs waiting
        if res.body.rows.length == 0
          @setState verifying: false
          return console.log err

        # otherwise we go to the fetched doc
        for row in res.body.rows
          docid = row.id

          if typeof row.value == 'object'
            # grab its source if it is an array of some scrapbook path (with lots of fields)
            # and a docid (at the source). we build a direct url to the source doc here.
            source = getQuickBasePath(row.value[0]) + '/_db/' + row.value[1]
          else
            # grab the source as it was passed, if it was a webmention or something alike.
            source = row.value

          # fetch the source url
          superagent.get(source)
                    .end (err, res) =>
            if err
              return console.log err

            if /couch/i.exec res.headers['server']
              # in the couchdb case, we parse the JSON
              doc = JSON.parse res.text
              if doc.error
                return console.log doc

              # and grab the contents directly.
              update =
                verified: true
                content: doc.content
                name: doc.name

            else
              # in the webmention case, parse the HTML
              hiddenDOM = document.createElement('html')
              hiddenDOM.innerHTML = res.text
              mf2_opts =
                node: hiddenDOM
                filter: ['h-card', 'h-entry']
              items = microformats.getItems(mf2_opts)

              update = {verified: true}
              for item in items.items
                if 'h-card' in item.type
                  update.name = item.properties.name[0]
                if 'h-entry' in item.type
                  update.content = item.properties.content[0].value

            # then update the scrap and mark it as verified.
            superagent.put(basePath + '/verified/' + docid)
                      .send(update)
                      .withCredentials()
                      .end (err, res) =>
              if err
                return console.log err

              # finally, we reload the scraps and restart the process.
              @loadScraps()
              @verifyScraps()

  render: ->
    (div className: 'scrapbook',
      (div
        className: 'top-bar'
      ,
        (Login
          url: '/_session'
          className: 'login-top'
          onLogin: @handleLogin
          onLogout: @handleLogout
        )
      )
      (form
        method: 'post'
        action: '/here'
        className: 'new'
        onSubmit: @handleSubmit
      ,
        (div {},
          (input {ref: 'from', name: 'from', placeholder: 'your scrapbook URL, if you have one, or your name'})
        ) if @state.showNameInput
        (div {},
          (textarea {ref: 'content', name: 'content'})
        )
        (button
          type: 'submit'
        , 'Send')
      )
      (Login
        url: @state.externalLoginURL
        className: 'login-dialog'
        onLogin: @closeExternalLoginDialog
      ,
        'Please login to '
        (a {href: @state.externalLoginURL, target: '_blank'}, @state.externalLoginURL)
        ' through this form or by going there directly.'
      ) if @state.externalLoginURL
      (div className: 'scraps',
        (div
          className: 'scrap h-entry'
          key: scrap._id
        ,
          (a {className: 'not-verified'}, '×') if not scrap.verified
          (a {className: 'h-card', href: scrap.from}, scrap.name or scrap.from or 'Anonymous')
          (time
            className: 'dt-published'
          , (new Date scrap.timestamp).toISOString().substr(0,16).split('T').join(' '))
          (div
            className: 'e-content'
          , scrap.content)
        ) for scrap in @props.scraps
        (a {href: @props.firstpage}, 'first page')
        (a {href: @props.nextpage}, 'next page') if @props.scraps.length >= 25
      )
    )

  handleSubmit: (e) ->
    e.preventDefault()

    # first we get the field that may be a name or may be an URL
    # to the other webpage or scrapbook.
    try
      homeurl = @refs.from.getDOMNode().value
    catch e
      homeurl = null
    ## ~

    try
      # if there is none, we throw, then we proceed to submit
      # an anonymous scrap
      throw {} if not homeurl

      # otherwise we try to make the person post the scrap at
      # her own scrapbook
      @postHomeFirst homeurl, (err, srcid, home) =>
        if err
          # for unauthorized errors, we try to make the person log in
          # in her own scrapbook.
          if err.unauthorized then @loginAtHomeFirst homeurl

          # other errors mean that the name is either an URL
          # to a non-scrapbook page or a name, so we submit it
          # as both.
          else @postHere(null, homeurl, homeurl)

        else
          # if there was no error posting at the person's own
          # scrapbook we proceed, now having the scrap id and the
          # correct scrapbook URL
          @postHere(srcid, home)

    catch e
      @postHere(null, location.href, homeurl)

  loginAtHomeFirst: (baseurl) ->
    # just show a login dialog for the person's scrapbook
    sessionurl = url.parse baseurl
    sessionurl.search = ''
    sessionurl.pathname = '_session'
    @setState externalLoginURL: sessionurl.format()

  closeExternalLoginDialog: ->
    # close it onLogin
    @setState externalLoginURL: null

  postHomeFirst: (homeurl, callback) ->
    home = getQuickBasePath homeurl
    superagent.post(home + '/elsewhere')
              .send({
                content: @refs.content.getDOMNode().value
                target: getQuickBasePath location.href
              })
              .withCredentials()
              .end (err, res) =>
      callback err if err

      body = JSON.parse res.text
      return callback res if not body.ok

      callback null, body.id, home

  postHere: (srcid, from, name) ->
    payload =
      content: @refs.content.getDOMNode().value
      name: name # if the name is the same as "from", our _update
                 # function will know what to do (check if it is an
                 # URL etc.)

    if srcid
      payload.srcid = srcid

    if from
      payload.from = from

    if not payload.from and not payload.src and not payload.name
      if not confirm('Send anonymous scrap?')
        return

    # if hashcash is needed, first fetch the data to use in the token
    # generation:
    if window.use_hashcash
      superagent.get(getQuickBasePath(location.href) + '/get_hashcash_data')
                .end (err, res) =>
        return console.log err if err

        token = hashcash.generate {
          difficulty: 20000
          data: res.text
        }

        payload.hashcash = token
        @submitScrap payload

    else
      # otherwise just proceed
      @submitScrap payload

  submitScrap: (payload) ->
    superagent.post(getQuickBasePath(location.href) + '/here')
              .send(payload)
              .end (err, res) =>
      return console.log err if err
      return console.log res.text unless JSON.parse(res.text).ok

      # save domain or name at localStorage
      localStorage.setItem 'domain/name', @refs.from.getDOMNode().value

      if location.search.indexOf('startkey') isnt -1
        # go to the first page
        location.href = @props.firstpage

      else
        # reload the scraps
        @loadScraps()

        # clean content data
        @refs.content.getDOMNode().value = ''

Login = React.createClass
  getInitialState: ->
    loggedAs: null

  componentDidMount: ->
    superagent.get('/_session')
              .set('accept', 'application/json')
              .end (err, res) =>
      if not err and res.body.ok
        @setState loggedAs: res.body.userCtx.name

        if res.body.userCtx.name
          @props.onLogin(res.body.userCtx.name) if @props.onLogin

  render: ->
    (div className: @props.className,
      (div {},
        @props.children
        (form
          method: 'post'
          action: @props.url
          onSubmit: @doLogin
        ,
          (input name: 'name', ref: 'name', placeholder: 'name')
          (input type: 'password', name: 'password', ref: 'password', placeholder: 'password')
          (button
            type: 'submit'
          , 'Login')
        )
      ) if not @state.loggedAs
      (div {},
        "logged as #{@state.loggedAs} ("
        (a {href: "#", onClick: @doLogout}, 'logout')
        ")"
      ) if @state.loggedAs
    )

  doLogin: (e) ->
    e.preventDefault()

    name = @refs.name.getDOMNode().value
    password = @refs.password.getDOMNode().value
    superagent.post(@props.url)
              .set('content-type', 'application/x-www-form-urlencoded')
              .set('accept', 'application/json')
              .send(name: name, password: password)
              .withCredentials()
              .end (err, res) =>
      if err or not res.body.ok
        return

      @setState
        loggedAs: res.body.name

      @props.onLogin(res.body.name) if @props.onLogin

  doLogout: (e) ->
    e.preventDefault()

    superagent.del(@props.url)
              .withCredentials()
              .end (err, res) =>
      if err
        return

      @setState
        loggedAs: null

      @props.onLogout() if @props.onLogout
    
module.exports = Scrapbook

if typeof window isnt 'undefined'
  url = require 'lib/urlparser'
  microformats = require 'lib/microformat-shiv'
  
  React.renderComponent Scrapbook(window.data), document.getElementById 'main'
