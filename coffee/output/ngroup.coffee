
module.exports = (n, unit) ->
  numeric = Number n
  _n = String(n).split('').reverse()
  n = ''
  for char, i in _n
    n = ',' + n if i % 3 is 0 and i
    n = char + n
  if unit
    n += ' ' + unit
    n += 's' unless numeric is 1
  n
