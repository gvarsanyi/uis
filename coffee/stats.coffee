
message_cue = {}

cue_processor = (msg) ->
  unless typeof msg.id is 'number' and msg.id >= 0
    throw new Error 'invalid/missing msg id: ' + msg

  repo = msg.repo
  task = msg.task
  if msg.type is 'note'
    repo = task = 'note'

  unless repo and task
    throw new Error 'invalid/missing msg.repo and/or msg.task: ' + msg

  message_cue[repo] ?= {}
  message_cue[repo][task] ?= []
  if stats?.data and (not stats?.ids?[repo]?[task]? or msg.id is stats.ids[repo][task] + 1)
    stats.ids[repo] ?= {}
    stats.ids[repo][task] = msg.id
    return [msg]

  (cue = message_cue[repo][task]).push msg
  cue.sort (a, b) ->
    a.id - b.id

  ready_list repo, task

ready_list = (repo, task) ->
  list = []
  cue = message_cue[repo]?[task] or []
  while cue.length and (ids = stats?.ids?[repo])?[task]? and cue[0].id is ids[task] + 1
    ids[task] += 1
    list.push cue.shift()
  list


class Stats
  data: null
  ids: null

  init: (initial_stats, initial_ids) =>
    unless not @data? and initial_stats? and typeof initial_stats is 'object' and
    initial_ids? and typeof initial_ids is 'object'
      throw new Error 'init-stat: ' + arguments
    @data = initial_stats
    @ids  = initial_ids

    list = []
    for repo, repo_data of initial_stats
      for task of repo_data
        for msg in ready_list repo, task
          list.push msg
    list

  incoming: (msg) =>
    msgs = cue_processor msg
    for msg in msgs when msg.type is 'stat'
      if not (id = @ids?[msg.repo]?[msg.task])? or id <= msg.id
        @data[msg.repo] ?= {}
        @data[msg.repo][msg.task] = msg.stat
        @ids[msg.repo] ?= {}
        @ids[msg.repo][msg.task] = msg.id
    msgs

module.exports = stats = new Stats
