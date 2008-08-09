var act = window.act = function() {
  return {
    make_uri: function(conf_id, action, args) {
        var uri = [ '', conf_id, action ].join('/');
        if (args)
            for (var p in args)
                uri = uri + ';' + p + '=' + encodeURIComponent(args[p]);
        return uri;
    }
  };
}();
