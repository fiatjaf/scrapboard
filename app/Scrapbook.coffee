React = require 'node_modules/react'
marked = require 'node_modules/marked'
superagent = require 'node_modules/superagent'

{getQuickBasePath} = require 'app/path-utils'

{div, time, a, form, input, textarea, button} = React.DOM

Scrapbook = React.createClass
  getInitialState: ->
    externalLoginURL: null
    showNameInput: true

  doShowNameInput: -> @setState showNameInput: true
  dontShowNameInput: -> @setState showNameInput: false

  componentDidMount: ->
    if not @props
      @loadScraps()

  loadScraps: ->
    superagent.get(location.href)
              .set('accept', 'application/json')
              .end (err, res) =>
      if not err
        @setProps res.body

  render: ->
    (div className: 'scrapbook',
      (div
        className: 'top-bar'
      ,
        (Login
          url: '/_session'
          className: 'login-top'
          onLogin: @dontShowNameInput
          onLogout: @doShowNameInput
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
      (div className: 'scraps',
        (div
          className: 'scrap'
          key: scrap._id
        ,
          (a {className: 'not-verified'}, '×') if not scrap.verified
          (a {className: 'h-card', href: scrap.from}, scrap.name or scrap.from or 'Anonymous')
          (time
            className: 'dt-published'
          , (new Date scrap.timestamp).toISOString().substr(0,16).split('T').join(' '))
          (div
            className: 'h-entry'
            dangerouslySetInnerHTML:
              __html: marked scrap.content
          )
        ) for scrap in @props.scraps
        (a {href: @props.firstpage}, 'first page')
        (a {href: @props.nextpage}, 'next page') if @props.scraps.length >= 25
      )
      (Login
        url: @state.externalLoginURL
        className: 'login-dialog'
        onLogin: @closeExternalLoginDialog
      ,
        'Please login to '
        (a {href: @state.externalLoginURL}, @state.externalLoginURL)
        ' through this form or by going there directly.'
      ) if @state.externalLoginURL
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
          else @submitScrap(null, homeurl, homeurl)

        else
          # if there was no error posting at the person's own
          # scrapbook we proceed, now having the scrap id and the
          # correct scrapbook URL
          @submitScrap(srcid, home)

    catch e
      @submitScrap(null, location.href, homeurl)

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

  submitScrap: (srcid, from, name) ->
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

    superagent.post(getQuickBasePath(location.href) + '/here')
              .send(payload)
              .end (err, res) =>
      if location.search.indexOf 'startkey' isnt -1
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
  url = require 'node_modules/url'
  
  React.renderComponent Scrapbook(window.data), document.getElementById 'main'
