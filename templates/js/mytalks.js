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
    toggle_talk = function(elem, talk_id, set) {
        $.post(act.make_uri('[% global.request.conference %]', 'updatemytalks_a'), {talk_id: talk_id} );
        toggle_image(elem, talk_id, !set);
    };
    $(function() {
        $(".mytalks_submit").remove();
        $(":checkbox").each(function() {
            toggle_image(this, $(this).val(), $(this).attr("checked"));
        });
    });
}
</script>
