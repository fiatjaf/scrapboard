react = require '../node_modules/react'
marked = require '../node_modules/marked'
superagent = require '../node_modules/superagent'
url = require '../node_modules/url'

{div, a, form, input, textarea, button} = React.DOM

Scrapbook = React.createClass
  render: ->
    (div className: 'scrapbook',
      (form
        method: 'post'
        action: '/'
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
        (div {},
          (a {href: scrap.from}, scrap.name or scrap.from or 'Anonymous')
          marked scrap.content
        ) for scrap in @props.scraps
      )
    )

  handleSubmit: (e) ->
    e.preventDefault()

    try
      val = @refs.from.getDOMNode().value
      throw {} if not val

      p = url.parse val
      home = "#{p.protocol or 'http:'}//#{p.host}#{if p.port then ':' + p.port}#{p.path}/elsewhere"
      superagent.put(home)
                .send({
                  content: @refs.content.getDOMNode().value
                  target: location.href
                })
                .end (err, res) =>
        throw {} if err

        body = JSON.parse res.text
        throw {} if not body.ok

        id = body.id
        src = "#{p.protocol or 'http:'}//#{p.host}#{if p.port then ':' + p.port}#{p.path}/scrapdata/#{id}"
        @submitScrap(src, home)

    catch e
      @submitScrap()

  submitScrap: (src, from) ->
    payload =
      content: @refs.content.getDOMNode().value
      name: @refs.name.getDOMNode().value

    if src
      payload.src = src

    if from
      payload.from = from

    if not payload.from and not payload.src and not payload.name
      if not confirm('Send anonymous scrap?')
        return

    superagent.put(location.pathname + '/here')
              .send(payload)
              .end (err, res) ->
      console.log JSON.parse res.text
    
module.exports = Scrapbook

if typeof window isnt 'undefined'
  React.renderComponent Scrapbook window.data, document.getElementById 'main'
