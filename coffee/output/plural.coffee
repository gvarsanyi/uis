
module.exports = (str, n) ->
  if String(n).length and Number(n) isnt 1
    return str + 's'
  str
