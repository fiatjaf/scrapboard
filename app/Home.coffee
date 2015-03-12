React = require 'lib/react'
hashcash = require 'lib/hashcash-token'
superagent = require 'lib/superagent'

Login = require './Login'
Scrap = require './Scrap'

{getQuickBasePath} = require 'lib/utils'
{section, footer, div, time, a, form, input, textarea, button} = React.DOM

Scrapbook = React.createClass
  getDefaultProps: ->
    scraps: []
  getInitialState: ->
    externalLoginURL: null
    logged: false
    verifying: false

  componentDidMount: ->
    if not @props.scraps.length
      @loadScraps()

  handleLogin: ->
    @setState
      logged: true
      verifying: true
    @verifyScraps()

  handleLogout: ->
    @setState
      logged: false
      verifying: false

  loadScraps: (params, e) ->
    if e and params
      e.preventDefault()
    else
      params.preventDefault() if params
      params = ''

    # safeguard against firefox bug with CORS redirect: https://bugzilla.mozilla.org/show_bug.cgi?id=1102337
    if window.isWidget and navigator.userAgent.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i)[1] != 'Chrome'
        loadURL = 'https://cors-anywhere.herokuapp.com/' + basePath
    else
        loadURL = basePath

    superagent.get(loadURL + params)
              .set('Accept', 'application/json')
              .withCredentials()
              .end (err, res) =>
      if not err
        @setProps JSON.parse res.text

  verifyScraps: ->
    if not @state.verifying
      return
    else
      # first we fetch one row of docs waiting to be verified
      superagent.get(basePath + '/to-verify?limit=1')
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
            source = getQuickBasePath(row.value[0]) + '/scrap/' + row.value[1]
          else
            # grab the source as it was passed, if it was a webmention or something alike.
            source = row.value

          # fetch the source url
          superagent.get(source)
                    .end (err, res) =>
            if err
              return console.log err

            doc = JSON.parse res.text
            if doc.error
              return console.log doc

            # grab the contents directly.
            update =
              verified: true
              content: doc.content
              name: doc.name

            # then update the scrap and mark it as verified.
            superagent.put(basePath + '/verify/' + docid)
                      .send(update)
                      .withCredentials()
                      .end (err, res) =>
              if err or not JSON.parse(res.text).ok
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
          (input
            ref: 'from'
            name: 'from'
            placeholder: 'your scrapbook URL, if you have one, or your name'
            defaultValue: @props.visitorsScrapbookURL
          ) if not @state.logged
          'this is your own scrapbook.' if @state.logged
        )
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
      (section className: 'scraps',
        (Scrap {logged: @state.logged, scrap: scrap, key: scrap._id}) for scrap in @props.scraps
        (footer {},
          (a
            onClick: @loadScraps.bind @, @props.firstpage
            href: @props.firstpage
          , 'first page')
          (a
            onClick: @loadScraps.bind @, @props.nextpage
            href: @props.nextpage
          , 'next page') if @props.scraps.length >= 25
        )
      )
    )

  handleSubmit: (e) ->
    e.preventDefault()

    # first we get the field that may be a name or may be an URL
    # to the other webpage or scrapbook.
    try
      name = @refs.from.getDOMNode().value
    catch e
      name = null
    ## ~

    # the homeurl is parsed from whatever the users pastes in the name box
    homeurl = getQuickBasePath name if name

    try
      # if there is no homeurl (or it is not an url)
      # we throw, then we proceed to submit an anonymous scrap
      throw {} if not homeurl

      # otherwise we try to make the person post the scrap at
      # her own scrapbook
      @postHomeFirst homeurl, (err, srcid) =>
        if err
          # for unauthorized errors, we try to make the person log in
          # in her own scrapbook.
          if err.unauthorized then @loginAtHomeFirst homeurl

          # other errors mean that the name is either an URL
          # to a non-scrapbook page or a name, so we submit it
          # as both.
          else @postHere(null, null, homeurl)

        else
          # if there was no error posting at the person's own
          # scrapbook we proceed, now having the scrap id and the
          # correct scrapbook URL
          @postHere(srcid, homeurl, homeurl)

    catch e
      @postHere(null, null, name)

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
    superagent.post(homeurl + '/elsewhere')
              .send({
                content: @refs.content.getDOMNode().value
                target: basePath
              })
              .withCredentials()
              .end (err, res) =>
      callback err if err

      body = JSON.parse res.text
      return callback res if not body.ok

      callback null, body.id

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
      localStorage.setItem

    if not payload.from and not payload.src and not payload.name
      if not confirm('Send anonymous scrap?')
        return

    # if hashcash is needed, first fetch the data to use in the token
    # generation:
    if window.use_hashcash
      superagent.get(basePath + '/get-hashcash-seed')
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
    superagent.post(basePath + '/here')
              .send(payload)
              .withCredentials()
              .end (err, res) =>
      return console.log err if err
      return console.log res.text unless JSON.parse(res.text).ok

      if url.parse(basePath).host == location.host and location.search.indexOf('startkey') isnt -1
        # go to the first page
        location.href = @props.firstpage

      else
        # reload the scraps
        @loadScraps()

        # clean content data
        @refs.content.getDOMNode().value = ''

module.exports = Scrapbook

if typeof window isnt 'undefined'
  url = require 'lib/urlparser'
  getBaseURL = ->
    p = url.parse basePath
    if p.host
      return p.protocol + '//' + p.host
    else
      return ''
  
  React.renderComponent Scrapbook(window.data), document.getElementById 'scrapboard-main'
