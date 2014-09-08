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
  input.addEventListener 'input', oninput = -> span.textContent = input.textContent
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
}
.preview {
}
.preview canvas {
  width: 240px; height: 240px;
}
.description {
  vertical-align: top;
  padding-left: 10px;
}
.name {
  font-weight: 600;
}
.name .fa {
  color: lightgreen;
}
a {
  color: lightgreen;
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

component = ({data, title, note}) ->
  el = tag '.entry', [
    preview = tag '.preview', [tag 'canvas'], tabindex: 0
    tag '.description', [
      name = tag '.name', [
        tag 'span', title
        ' '
        tag 'i.fa.fa-edit', onclick: -> edit()
      ]
      tag '.body', note
    ]
  ]
  edit = ->
    val = name.querySelector('span').textContent
    name.textContent = ''
    name.appendChild makeExpandingInput(val)
  preview.boilerplate = new Simulator
  el

add = (e) ->
  e.preventDefault()
  entries.appendChild component({data:null, title:'Unnamed component', note:'No note'})

document.body.appendChild tag '#main', [
  entries = tag '.entries', [
    component data:null, title:'4-bit adder', note:'adds 4 bits'
  ]
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
        sim.setGrid json
        canvas = document.activeElement.querySelector('canvas')
        canvas.width = canvas.height = 240 * devicePixelRatio
        canvas.style.width = canvas.style.height = '240px'
        ctx = canvas.getContext '2d'
        ctx.scale devicePixelRatio, devicePixelRatio

        bb = sim.boundingBox()
        tw = bb.right - bb.left + 3
        th = bb.bottom - bb.top + 3
        size = Math.min(240/tw, 240/th)|0
        worldToScreen = (tx, ty) -> {px: (tx-bb.left+1) * size, py: (ty-bb.top+1) * size}
        sim.drawCanvas ctx, size, worldToScreen
      catch e
        console.error e.stack

window.addEventListener 'copy', (e) ->
  if document.activeElement.boilerplate?
    e.preventDefault()
    bp = document.activeElement.boilerplate
    e.clipboardData.setData 'text', JSON.stringify bp.getGrid()
