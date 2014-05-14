

(function() {
  function show() {
    var div = document.getElementById('bayeux-msg');
    if (!msgs.length) {
      if (div) {
        div.parentNode.removeChild(div);
      }
      return;
    }

    if (!div) {
      div = document.createElement('DIV');
      div.style.position = 'fixed';
      div.style.top = '5px';
      div.style.right = '5px';
      div.style.fontSize = '15px';
      div.style.fontWeight = 'bold';
      div.style.color = 'white';
      div.style.background = '#626';
      div.style.opacity = 0.85;
      div.style.padding = '5px';
      div.style.border = '3px solid #303';
      div.style.textAlign = 'left';
      div.style.borderRadius = '3px';
      div.style.zIndex = 5000;
      div.id = 'bayeux-msg';
      document.body.appendChild(div);
    }

    var i, msg = '';
    for (i = 0; i < msgs.length; i += 1) {
      msg += msgs[i] + '<br/>';
    }
    div.innerHTML = msg;
  }

  function add(msg) {
    msgs.push(msg);
    show();
    setTimeout(function() {
      msgs.shift();
      show();
    }, 5000);
  }

  var init = true,
      msgs = [],
      bayeux = new Faye.Client('/bayeux', {retry: .5});

  bayeux.on('transport:down', function() {
    add('disconnected from service');
  });
  bayeux.on('transport:up', function() {
    if (!init) {
      add('service is back!');
      add('refreshing ...');
      location.reload(true);
    }
    init = false;
  });
  bayeux.subscribe('/dev-watcher', function (msg) {
    if (msg.text) {
      add(msg.text);
    }
    if (msg.refresh) {
      add('refreshing ...');
      location.reload(true);
    }
  });
})();

