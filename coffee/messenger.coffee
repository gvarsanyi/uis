
repo = null

module.exports = (_repo) ->
  repo = _repo

send = (inf) ->
  if repo and process.send
    process.send inf
  else if repo
    throw new Error 'no channel for sending stat, ' + JSON.stringify inf
  else
    throw new Error 'repo is not available, ' + JSON.stringify inf


module.exports.sendStat = (task) ->
  stat = {}
  for part in ['count', 'error', 'warning', 'size', 'status', 'startedAt', 'finishedAt', 'watched']
    stat[part] = val if val = repo?.tasks[task]?[part]?()

  send
    type: 'stat'
    repo: repo?.name
    task: task
    stat: stat

module.exports.note = (note) ->
  send
    type: 'note'
    repo: repo?.name
    note: note
