
module.exports = (n) ->
  _n = String(n).split('').reverse()
  n = ''
  for char, i in _n
    n = ',' + n if i % 3 is 0 and i
    n = char + n
  n
