<script type="text/javascript">
if (window.act) {
    toggle_image = function(elem, talk_id, set) {
        [% titles = [ loc('remove from personal schedule'), loc('add to personal schedule') ] %]
        var data = { img_name: set ? 'picked' : 'unpicked',
                     title:    set ? '[% titles.0.replace("'", "\\'") %]' : '[% titles.1.replace("'", "\\'") %]',
                     talk_id:  talk_id,
                     set:      set
        };
        $(elem).replaceWith( act.template("tpl_mtbutton", data) );
        $("#my-"+talk_id+"-text").replaceWith( act.template("tpl_imgtitle", data) );
    };
    toggle_count = function(talk_id, set) {
        var elemcount = "#starcount-" + talk_id;
        $(elemcount).replaceWith(
            act.template("tpl_starcount",
                         { talk_id: talk_id,
                           count: (parseInt($(elemcount + " > font").text()) || 0) + (set ? 1 : -1)
                         }
                        ));
    };
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

[%# javascript templates %]
<script type="text/html" id="tpl_mtbutton">
<img class="mtbutton" src="/images/<%=img_name%>.gif" title="<%=title%>"
     onClick ="toggle_talk(this,<%=talk_id%>,<%=set%>);" />
</script>

<script type="text/html" id="tpl_imgtitle">
<span id="my-<%=talk_id%>-text"><%=title%></span>
</script>

<script type="text/html" id="tpl_starcount">
<span id="starcount-<%=talk_id%>" style="white-space:nowrap"><% if (count) { %><font size="-1"><%=count%></font><img style="vertical-align:middle" src="/images/picked.gif" /><% } %></span>
</script>
