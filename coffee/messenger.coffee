
repo = null
name = null

module.exports = (_repo) ->
  repo = _repo
  name = _repo.constructor.name.replace('Repo', '').toLowerCase()

module.exports.sendStats = ->
  if repo and process.send
    msg = stats: {}
    msg.stats[name] = repo.stats()
    process.send msg

process.on 'message', (msg) ->
  if msg is 'stats'
    module.exports.sendStats()
