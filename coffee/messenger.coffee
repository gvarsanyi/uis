
repo = null

message_ids = {}

send = (inf) ->
  if repo and process.send
    process.send inf
  else if repo
    console.log JSON.stringify inf
  else
    throw new Error 'repo is not available, ' + JSON.stringify inf


module.exports = (_repo) ->
  repo = _repo

module.exports.sendStat = (task) ->
  stat = {}
  for part in ['count', 'done', 'error', 'warning', 'size', 'status',
               'startedAt', 'finishedAt', 'watched']
    stat[part] = val if val = repo?.tasks[task]?[part]?()

  message_ids[task] ?= 0

  send
    type: 'stat'
    repo: repo?.name
    task: task
    id:   message_ids[task]
    stat: stat

  message_ids[task] += 1
