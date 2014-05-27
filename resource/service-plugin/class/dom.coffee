
class DOM
  @create: (parent, styles, tag='DIV') ->
    try
      parent.appendChild node = document.createElement tag.toUpperCase()
      DOM.style node,
        border:        '0 solid transparent'
        borderRadius:  0
        boxSizing:     'border-box'
        color:         '#eee'
        display:       'block'
        font:          '13px normal Arial,sans-serif'
        lineHeight:    '13px'
        margin:        0
        opacity:       1
        overflow:      'hidden'
        padding:       0
        position:      'relative'
        verticalAlign: 'top'
        whiteSpace:    'nowrap'
        zIndex:        2147483647
        zoom:          1
      if styles
        DOM.style node, styles
    node

  @remove: (node) ->
    try node.parentNode.removeChild node

  @style: (node, styles) ->
    try node.style[k] = v for k, v of styles