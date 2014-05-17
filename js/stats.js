// Generated by CoffeeScript 1.7.1
(function() {
  var Stats, cue_processor, message_cue, ready_list, stats,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  message_cue = {};

  cue_processor = function(msg) {
    var cue, repo, task, _base, _base1, _ref, _ref1;
    if (!(typeof msg.id === 'number' && msg.id >= 0)) {
      throw new Error('invalid/missing msg id: ' + msg);
    }
    repo = msg.repo;
    task = msg.task;
    if (msg.type === 'note') {
      repo = task = 'note';
    }
    if (!(repo && task)) {
      throw new Error('invalid/missing msg.repo and/or msg.task: ' + msg);
    }
    if (message_cue[repo] == null) {
      message_cue[repo] = {};
    }
    if ((_base = message_cue[repo])[task] == null) {
      _base[task] = [];
    }
    if ((typeof stats !== "undefined" && stats !== null ? stats.data : void 0) && (((typeof stats !== "undefined" && stats !== null ? (_ref = stats.ids) != null ? (_ref1 = _ref[repo]) != null ? _ref1[task] : void 0 : void 0 : void 0) == null) || msg.id === stats.ids[repo][task] + 1)) {
      if ((_base1 = stats.ids)[repo] == null) {
        _base1[repo] = {};
      }
      stats.ids[repo][task] = msg.id;
      return [msg];
    }
    (cue = message_cue[repo][task]).push(msg);
    cue.sort(function(a, b) {
      return a.id - b.id;
    });
    return ready_list(repo, task);
  };

  ready_list = function(repo, task) {
    var cue, ids, list, _ref, _ref1, _ref2;
    list = [];
    cue = ((_ref = message_cue[repo]) != null ? _ref[task] : void 0) || [];
    while (cue.length && (((_ref1 = (ids = typeof stats !== "undefined" && stats !== null ? (_ref2 = stats.ids) != null ? _ref2[repo] : void 0 : void 0)) != null ? _ref1[task] : void 0) != null) && cue[0].id === ids[task] + 1) {
      ids[task] += 1;
      list.push(cue.shift());
    }
    return list;
  };

  Stats = (function() {
    function Stats() {
      this.incoming = __bind(this.incoming, this);
      this.init = __bind(this.init, this);
    }

    Stats.prototype.data = null;

    Stats.prototype.ids = null;

    Stats.prototype.init = function(initial_stats, initial_ids) {
      var list, msg, repo, repo_data, task, _i, _len, _ref;
      if (!((this.data == null) && (initial_stats != null) && typeof initial_stats === 'object' && (initial_ids != null) && typeof initial_ids === 'object')) {
        throw new Error('init-stat: ' + arguments);
      }
      this.data = initial_stats;
      this.ids = initial_ids;
      list = [];
      for (repo in initial_stats) {
        repo_data = initial_stats[repo];
        for (task in repo_data) {
          _ref = ready_list(repo, task);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            msg = _ref[_i];
            list.push(msg);
          }
        }
      }
      return list;
    };

    Stats.prototype.incoming = function(msg) {
      var id, msgs, _base, _base1, _i, _len, _name, _name1, _ref, _ref1;
      msgs = cue_processor(msg);
      for (_i = 0, _len = msgs.length; _i < _len; _i++) {
        msg = msgs[_i];
        if (msg.type === 'stat') {
          if (((id = (_ref = this.ids) != null ? (_ref1 = _ref[msg.repo]) != null ? _ref1[msg.task] : void 0 : void 0) == null) || id <= msg.id) {
            if ((_base = this.data)[_name = msg.repo] == null) {
              _base[_name] = {};
            }
            this.data[msg.repo][msg.task] = msg.stat;
            if ((_base1 = this.ids)[_name1 = msg.repo] == null) {
              _base1[_name1] = {};
            }
            this.ids[msg.repo][msg.task] = msg.id;
          }
        }
      }
      return msgs;
    };

    return Stats;

  })();

  module.exports = stats = new Stats;

}).call(this);