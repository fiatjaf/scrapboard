React = require 'lib/react'
superagent = require 'lib/superagent'

{div, time, a, form, input, textarea, button} = React.DOM

module.exports = React.createClass
  render: ->
    scrap = @updatedScrap or @props.scrap

    if scrap._deleted
      return (div
        className: 'scrap deleted'
      , 'this scrap was deleted.')

    (div
      className: 'scrap h-entry' + if not scrap.verified then ' not-verified' else ''
      title: if not scrap.verified then 'this scrap may not be from whom it claims to be.' else ''
    ,
      (a
        className: 'click-to-delete'
        href: '#'
        title: 'Click to delete this'
        onClick: @clickDelete
      , '×') if @props.logged
      ' '
      (a
        className: 'click-to-verify'
        href: '#'
        title: 'Click to manually verify'
        onClick: @clickVerify
      , '¬¬') if not scrap.verified and @props.logged
      ' '
      (a {className: 'click-to-verify'}, '¬¬') if not scrap.verified and not @props.logged
      ' '
      (a
        className: 'h-card'
        href: scrap.from
      , scrap.name or scrap.from or 'anonymous')
      (time
        className: 'dt-published'
      , (new Date scrap.timestamp).toISOString().substr(0,16).split('T').join(' '))
      (div
        className: 'e-content'
      , scrap.content)
    )

  clickVerify: (e) ->
    e.preventDefault()
    superagent.put(basePath + '/verified/' + @props.scrap._id)
              .withCredentials()
              .end (err, res) =>
      if not err
        @updatedScrap = JSON.parse res.text
        @forceUpdate()

  clickDelete: (e) ->
    e.preventDefault()
    superagent.del(basePath + '/delete/' + @props.scrap._id)
              .withCredentials()
              .end (err, res) =>
      if not err
        @updatedScrap = @updatedScrap or @props.scrap
        @updatedScrap._deleted = true

        @forceUpdate()
