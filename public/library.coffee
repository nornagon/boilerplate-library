# tag 'div', 'some text which <gets> &escaped;'
# tag '.my-class'
# tag '#my-id'
# tag '.my-class#and-id'
# tag 'button.btn.btn-primary', 'button text', disabled: true
# tag 'ul', [
#   tag 'li', 'text'
# ]
tag = (name, text, attrs) ->
  parts = (name ? 'div').split /(?=[.#])/
  tagName = "div"
  classes = []
  id = undefined
  for p in parts when p.length
    switch p[0]
      when '#' then id = p.substr 1 if p.length > 1
      when '.' then classes.push p.substr 1 if p.length > 1
      else tagName = p
  if /:/.test tagName
    [ns, tagName] = tagName.split /:/
  if ns is 'svg'
    element = document.createElementNS "http://www.w3.org/2000/svg", tagName
  else
    element = document.createElement tagName
  if typeof text is 'string' or typeof text is 'number'
    element.textContent = text
  else if Array.isArray(text)
    for e in text
      if Array.isArray e
        element.appendChild x for x in e
      else
        if typeof e is 'string'
          element.appendChild document.createTextNode e
        else
          element.appendChild e
  else if text instanceof Node
    element.appendChild text
  else
    # no contents provided.
    attrs = text
  attrs ?= {}
  attrs.id ?= id
  element.classList.add(c) for c in classes
  if attrs.class?
    if Array.isArray attrs.class
      element.classList.add c for c in attrs.class
    else
      element.classList.add attrs.class
    delete attrs.class
  for k,v of attrs
    if k.substr(0, 2) is 'on'
      delete attrs[k]
      element.addEventListener k.substr(2), v
  for k,v of attrs
    element.setAttribute k, v if v?
  element

makeExpandingInput = (val) ->
  container = tag '.expanding-input', [
    tag 'div', [span = tag('span'), tag 'br']
    input = tag 'input'
  ]
  input.addEventListener 'input', oninput = -> span.textContent = input.value
  input.value = val if val?
  oninput()
  container

makeExpandingArea = (val) ->
  container = tag '.expanding-area', [
    tag 'div', [span = tag('span'), tag 'br']
    input = tag 'textarea'
  ]
  input.addEventListener 'input', oninput = -> span.textContent = input.value
  input.textContent = val if val?
  oninput()
  container


document.body.appendChild tag 'style', '''
body {
  font-family: Helvetica Neue, Helvetica, arial, sans-serif;
  background: hsl(184, 49%, 7%);
  color: hsl(0,0%,80%);
}
.entry {
  display: flex;
  margin-bottom: 4px;
}
.preview {
  padding: 20px;
  background: hsl(184, 49%, 10%);
}
  .preview:hover {
    background: hsl(184, 49%, 14%);
  }
.preview canvas {
  width: 120px; height: 120px;
}
.description {
  flex: 1;
  vertical-align: top;
  padding-left: 10px;
}
.name {
  font-weight: 600;
}
.body {
  white-space: pre-wrap;
}
a {
  color: hsl(120, 73%, 75%);
  cursor: pointer;
}
a:hover {
  color: hsl(120, 73%, 90%);
}
a.remove {
  display: inline-block;
  margin-top: 10px;
  color: pink;
}
a.edit {
  opacity: 0.2;
}
:hover > a.edit {
  opacity: 1;
}


.expanding-input {
  display: inline-block;
  position: relative;
}
.expanding-input div, .expanding-input input {
  margin: 0; padding: 0; outline: 0; border: 0;
  font: inherit;
  line-height: inherit;
  min-width: 8px;
  text-rendering: inherit;
  color: transparent;
}
.expanding-input div {
  margin-right: 1px;
  white-space: pre;
}
.expanding-input input {
  background: transparent;
  color: inherit;
  vertical-align: initial;
  width: 100%;
  position: absolute;
  top: 0;
  left: 0;
}

.expanding-area {
  position: relative;
}
.expanding-area div, .expanding-area textarea {
  margin: 0; padding: 0; outline: 0; border: 0;
  font: inherit;
  line-height: inherit;
  min-width: 8px;
  text-rendering: inherit;
  color: transparent;
  white-space: pre-wrap;
  word-break: break-word;
}
.expanding-area textarea {
  background-color: transparent;
  color: inherit;
  vertical-align: initial;
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
  outline: none;
  box-shadow: none;
  resize: none;
  overflow: hidden;
}
'''

editableName = (title, opts={area:false, change:->}) ->
  area = opts.area
  el = tag 'div', [
    tag 'span', title
    ' '
    tag 'a.edit', [tag 'i.fa.fa-edit'], onclick: -> edit()
  ]
  edit = ->
    val = el.querySelector('span').textContent
    el.textContent = ''
    el.appendChild if area then makeExpandingArea(val) else makeExpandingInput(val)
    input = el.querySelector(if area then 'textarea' else 'input')
    input.focus()
    # put cursor at end of textarea, cribbed from http://css-tricks.com/snippets/jquery/mover-cursor-to-end-of-textarea/
    input.value = ''
    input.value = val
    doneYet = false
    done = ->
      return cancel() if input.value.trim().length == 0
      return if doneYet
      doneYet = true
      el.parentNode.replaceChild editableName(input.value.trim(), opts), el
      opts.change?(input.value.trim())
    cancel = ->
      return if doneYet
      doneYet = true
      el.parentNode.replaceChild editableName(val, opts), el
    input.addEventListener 'blur', done
    input.addEventListener 'keydown', (e) =>
      if e.keyCode is 13
        if !area or area and e.shiftKey
          e.preventDefault()
          done()
      if e.keyCode is 27
        e.preventDefault()
        cancel()
  el

isEmpty = (obj) ->
  return false for k of obj
  return true

component = ({id, data, title, note}) ->
  el = tag '.entry', [
    preview = tag '.preview', [tag 'canvas'], tabindex: 0
    tag '.description', [
      tag '.name', editableName(title, change: (val) -> title = val; update())
      tag '.body', editableName(note, area: true, change: (val) -> note = val; update())
      tag 'a.remove', [
        tag 'i.fa.fa-remove'
        ' '
        'remove'
      ], onclick: -> remove()
    ]
  ]
  sim = preview.boilerplate = new Simulator data

  do draw_bp = preview.draw_bp = ->
    canvas = preview.querySelector('canvas')
    canvas.width = canvas.height = 120 * devicePixelRatio
    canvas.style.width = canvas.style.height = '120px'
    ctx = canvas.getContext '2d'
    ctx.scale devicePixelRatio, devicePixelRatio

    bb = sim.boundingBox()
    tw = bb.right - bb.left
    th = bb.bottom - bb.top
    size = Math.min(120/tw, 120/th)|0
    px_w_remaining = 120 - tw * size
    px_h_remaining = 120 - th * size
    worldToScreen = (tx, ty) -> {px: (tx-bb.left) * size + (px_w_remaining/2)|0, py: (ty-bb.top) * size + (px_h_remaining/2)|0}
    sim.drawCanvas ctx, size, worldToScreen

    if isEmpty(sim.getGrid())
      ctx.fillStyle = 'transparent'
      ctx.fillRect 0, 0, canvas.width, canvas.height
  preview.update_bp = (json) ->
    sim.setGrid json
    draw_bp()
    data = json
    update()
  el.library_id = id
  update = ->
    request
      method: 'PUT'
      url: "/data/#{el.library_id}"
      body: JSON.stringify {id, data, title, note}
      json: true
    , (er, res, body) ->
      alert er if er

  remove = ->
    return unless confirm "Delete #{title}?"
    request
      method: 'DELETE'
      url: "/data/#{el.library_id}"
    , (er, res, body) ->
      alert er if er
      el.remove()
  el

add = (e) ->
  e.preventDefault()
  c = {data:{}, title:'Unnamed component', note:'No note'}
  request
    url: '/data'
    method: 'POST'
    body: JSON.stringify c
    json: true
  , (er, res, body) ->
    c.id = body.id
    entries.appendChild component(c)

document.body.appendChild tag '#main', [
  entries = tag '.entries', []
  tag 'a.add', '+ new entry', onclick: add, href: '#'
]

window.addEventListener 'paste', (e) ->
  if document.activeElement.boilerplate?
    sim = document.activeElement.boilerplate
    data = e.clipboardData.getData 'text'
    if data
      try
        json = JSON.parse data
        delete json.tw; delete json.th
        document.activeElement.update_bp(json)
      catch e
        console.error 'error pasting boilerplate:', e.stack

window.addEventListener 'copy', (e) ->
  if document.activeElement.boilerplate?
    e.preventDefault()
    bp = document.activeElement.boilerplate
    e.clipboardData.setData 'text', JSON.stringify bp.getGrid()


request '/data/all', (er, res, body) ->
  components = JSON.parse body
  for c in components
    entries.appendChild component c
  setInterval ->
    return unless document.visibilityState is 'visible'
    requestAnimationFrame ->
      for e in document.querySelectorAll('.preview')
        delta = e.boilerplate.step()
        if !isEmpty delta.changed
          e.draw_bp()
  , 400
  return
