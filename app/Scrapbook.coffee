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
        (input {ref: 'from', name: 'from', placeholder: 'your scrapbook URL, if you have one'})
        (input {ref: 'name', name: 'name', placeholder: 'your name, optionally'})
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
      val = @refs.from.getDOMNode().value
      throw {} if not val

      home = getQuickBasePath val
      superagent.put(home + '/elsewhere')
                .send({
                  content: @refs.content.getDOMNode().value
                  target: location.href
                })
                .withCredentials()
                .end (err, res) =>
        throw {} if err

        body = JSON.parse res.text
        throw {} if not body.ok

        @submitScrap(body.id, home)

    catch e
      @submitScrap()

  submitScrap: (srcid, from) ->
    payload =
      content: @refs.content.getDOMNode().value
      name: @refs.name.getDOMNode().value

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
