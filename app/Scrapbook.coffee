React = require 'node_modules/react'
marked = require 'node_modules/marked'
superagent = require 'node_modules/superagent'

{getQuickBasePath} = require 'app/path-utils'

{div, a, form, input, textarea, button} = React.DOM

Scrapbook = React.createClass
  getInitialState: ->
    loginURL: null
    loggedAs: null

  componentDidMount: ->
    superagent.get('/_session')
              .set('accept', 'application/json')
              .end (err, res) =>
      if not err and res.body.ok
        @setState loggedAs: res.body.userCtx.name

  render: ->
    (div className: 'scrapbook',
      (form
        method: 'post'
        action: '/here'
        className: 'new'
        onSubmit: @handleSubmit
      ,
        (input {ref: 'from', name: 'from', placeholder: 'your scrapbook URL, if you have one, or your name'})
        (textarea {ref: 'content', name: 'content'})
        (button
          type: 'submit'
        , 'Send')
      )
      (div className: 'scraps',
        (div {key: "#{scrap.content.substr(0, 10)} #{scrap.name or scrap.from}"},
          (a {href: scrap.from}, scrap.name or scrap.from or 'Anonymous')
          (div
            dangerouslySetInnerHTML:
              __html: marked scrap.content
          )
        ) for scrap in @props.scraps
      )
      (div className: 'login-dialog',
        'Please login to '
        (a {href: @state.loginURL}, @state.loginURL)
        ' through this form or go there and login first.'
        (form
          method: 'post'
          action: @state.loginURL
          onSubmit: @handleLogin
        ,
          (input name: 'name', ref: 'name')
          (input type: 'password', name: 'password', ref: 'password')
          (button
            type: 'submit'
          , 'Login')
        )
      ) if @state.loginURL
    )

  handleSubmit: (e) ->
    e.preventDefault()

    try
      homeurl = @refs.from.getDOMNode().value
      throw {} if not homeurl

      @postHomeFirst homeurl, (err, srcid, home) =>
        if err
          if err.unauthorized then @loginAtHomeFirst homeurl
          else throw err

        else
          @submitScrap(srcid, home)

    catch e
      @submitScrap()

  loginAtHomeFirst: (baseurl) ->
    sessionurl = url.parse baseurl
    sessionurl.search = ''
    sessionurl.pathname = '_session'
    @setState loginURL: sessionurl.format()

  handleLogin: (e) ->
    e.preventDefault()

    name = @refs.name.getDOMNode().value
    password = @refs.password.getDOMNode().value
    url = @state.loginURL
    superagent.post(url)
              .send(name: name, password: password)
              .set('content-type', 'application/json')
              .set('accept', 'application/json')
              .withCredentials()
              .end (err, res) =>
      if err or not res.body.ok
        return

      @setState
        loginURL: null
        loggedAs: res.body.name

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

    if name
      payload.name = name
    else
      name = @refs.from.getDOMNode().value

    if srcid
      payload.srcid = srcid

    if from
      payload.from = from

    if not payload.from and not payload.src and not payload.name
      if not confirm('Send anonymous scrap?')
        return

    superagent.post(getQuickBasePath(location.href) + '/here')
              .send(payload)
              .end (err, res) ->
      console.log JSON.parse res.text
    
module.exports = Scrapbook

if typeof window isnt 'undefined'
  url = require 'node_modules/url'
  
  React.renderComponent Scrapbook(window.data), document.getElementById 'main'
