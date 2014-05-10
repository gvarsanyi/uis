
repo = null

module.exports = (_repo) ->
  repo = _repo

module.exports.sendStats = ->
  if repo and process.send
    msg = stats: {}
    msg.stats[repo.name] = repo.stats()
    process.send msg

module.exports.sendState = (task_name, state, error, warning, remainingTasks) ->
  if repo and process.send
    msg = state: {}
    msg.state[repo.name] = {}
    msg.state[repo.name][task_name] = {state, error, warning, remainingTasks}
    process.send msg

module.exports.note = (note) ->
  if repo and process.send
    msg = note: {}
    msg.note[repo.name] = [note]
    process.send msg

process.on 'message', (msg) ->
  if msg is 'stats'
    module.exports.sendStats()
