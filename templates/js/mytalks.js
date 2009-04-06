<script type="text/javascript">
if (window.act) {
    toggle_image = function(elem, talk_id, set) {
        var img_name = set ? 'picked' : 'unpicked';
        [% titles = [ loc('remove from personal schedule'), loc('add to personal schedule') ] %]
        var title = set ? '[% titles.0.replace("'", "\\'") %]' : '[% titles.1.replace("'", "\\'") %]';
        $(elem).replaceWith(
            $(
                '<img class="mtbutton" src="/images/' + img_name + '.gif"'
              + ' title="' + title + '"'
              + ' onClick ="toggle_talk(this,' + talk_id + ',' + set + ');" />'
             )
        );
        $("#my-"+talk_id+"-text").replaceWith(
            $(
              '<span id="my-'+talk_id+'-text">'+title+'</span>'
             )
        );
    };
    toggle_count = function(talk_id, set) {
        var elemcount = "#starcount-" + talk_id;
        var oldcount = parseInt($(elemcount + " > font").text()) || 0;
        var newcount = oldcount + (set ? 1 : -1);
        if (newcount) {
            $(elemcount).replaceWith(
                $(
                   '<span id="starcount-'+talk_id+'" style="white-space:nowrap"><font size="-1">'+newcount+
                   '</font><img style="vertical-align:middle" src="/images/picked.gif" /></span>'
                 )
            );
        }
        else {
            $(elemcount).replaceWith(
                $(
                   '<span id="starcount-"'+talk_id+'"></span>'
                 )
            );
        }
    }
    toggle_talk = function(elem, talk_id, set) {
        $.post(act.make_uri('[% global.request.conference %]', 'updatemytalks_a'), {talk_id: talk_id} );
        toggle_image(elem, talk_id, !set);
        toggle_count(talk_id, !set);
    };
    $(function() {
        $(".mytalks_submit").remove();
        $(":checkbox").each(function() {
            toggle_image(this, $(this).val(), $(this).attr("checked"));
        });
    });
}
</script>
