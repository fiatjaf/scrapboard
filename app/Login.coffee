React = require 'lib/react'
superagent = require 'lib/superagent'

{div, time, a, form, input, textarea, button} = React.DOM

getSessionURL = ->
  if typeof getBaseURL == 'function'
    getBaseURL() + '/_session'
  else if typeof basePath isnt 'undefined'
    basePath + '/_session'
  else
    '/_session'

module.exports = React.createClass
  getInitialState: ->
    url: @props.url or getSessionURL()
    loggedAs: null
    dismissedAd: false

  componentDidMount: ->
    @checkLoginStatus()

  checkLoginStatus: ->
    superagent.get(getSessionURL())
              .set('accept', 'application/json')
              .withCredentials()
              .end (err, res) =>
      if not err and res.body.ok
        @setState loggedAs: res.body.userCtx.name

        if res.body.userCtx.name
          @props.onLogin(res.body.userCtx.name) if @props.onLogin

  render: ->
    adWrapper = null
    loginForm = (form
      method: 'post'
      action: @state.url
      onSubmit: @doLogin
    ,
      (input name: 'name', ref: 'name', placeholder: 'name')
      (input type: 'password', name: 'password', ref: 'password', placeholder: 'password')
      (button
        type: 'submit'
      , 'Login')
    )

    if not @state.loggedAs and not @props.children and not @state.dismissedAd
      adWrapper = (div {},
        (a
          href: 'https://www.smileupps.com/store/apps/scrapbook'
          target: '_blank'
        , 'get a scrapbook')
        ' or '
        (button
          onClick: @dismissAd
        , 'login')
      )

    (div className: @props.className,
      (div {},
        @props.children
        adWrapper or loginForm
      ) if not @state.loggedAs
      (div {},
        "logged as #{@state.loggedAs} ("
        (a {href: "#", onClick: @doLogout}, 'logout')
        ")"
      ) if @state.loggedAs
    )

  dismissAd: (e) ->
    e.preventDefault()
    @setState dismissedAd: true

  doLogin: (e) ->
    e.preventDefault()

    name = @refs.name.getDOMNode().value
    password = @refs.password.getDOMNode().value
    superagent.post(@state.url)
              .set('content-type', 'application/x-www-form-urlencoded')
              .set('accept', 'application/json')
              .send(name: name, password: password)
              .withCredentials()
              .end (err, res) =>
      if err or not res.body.ok
        return

      @checkLoginStatus()

  doLogout: (e) ->
    e.preventDefault()

    superagent.del(@state.url)
              .withCredentials()
              .end (err, res) =>
      if err
        return

      @setState
        loggedAs: null

      @props.onLogout() if @props.onLogout
