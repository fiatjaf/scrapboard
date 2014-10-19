React = require 'node_modules/react'
marked = require 'node_modules/marked'
superagent = require 'node_modules/superagent'

{getQuickBasePath} = require 'app/path-utils'

{div, a, form, input, textarea, button} = React.DOM

Scrapbook = React.createClass
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
    )

  handleSubmit: (e) ->
    e.preventDefault()

    try
      homeurl = @refs.from.getDOMNode().value
      throw {} if not homeurl

      @postHomeFirst homeurl, (err, srcid, home) =>
        throw {} if err
        @submitScrap(srcid, home)

    catch e
      @submitScrap()

  postHomeFirst: (homeurl, callback) ->
    home = getQuickBasePath homeurl
    superagent.put(home + '/elsewhere')
              .send({
                content: @refs.content.getDOMNode().value
                target: getQuickBasePath location.href
              })
              .withCredentials()
              .end (err, res) =>
      callback err if err

      body = JSON.parse res.text
      callback true if not body.ok

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

    superagent.put(basePath + '/here')
              .send(payload)
              .end (err, res) ->
      console.log JSON.parse res.text
    
module.exports = Scrapbook

if typeof window isnt 'undefined'
  url = require 'node_modules/url'
  React.renderComponent Scrapbook(window.data), document.getElementById 'main'
