$(document).ready(function() {
   $("#mytalks_submit").hide();
});
function act_toggle_mytalk(conf_id, talk_id)
{
    $.post("/" + conf_id + "/ajax_toggle_mytalk", {talk_id: talk_id} );
}
