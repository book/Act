$(function() {
    $(".mytalks_submit").hide();
});
var act = window.act = function() {
  return {
    toggle_mytalk: function(conf_id, talk_id) {
        $.post("/" + conf_id + "/ajax_toggle_mytalk", {talk_id: talk_id} );
    }
  };
}();
