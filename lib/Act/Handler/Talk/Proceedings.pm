package Act::Handler::Talk::Proceedings;
use strict;
use Act::Config;
use Act::Template::HTML;
use Act::Talk;
use Act::User;


#
# handler()
# -------
sub handler {
    # retrieve talks and speaker info
    my $talks = Act::Talk->get_talks( conf_id => $Request{conference} );
    for my $talk (@$talks) {
       # make the User object for the speaker
       $talk->{user} = Act::User->new( user_id => $talk->user_id );

       # default language
       $talk->{lang} ||= $Config->general_default_language;

       # make a summary of the abstract (some people write long abstracts)
       my $abstract = text_summary($talk->abstract, 400);
       $talk->{chunked_abstract} = Act::Abstract::chunked($abstract);
    }

    # sort talks
    $talks = [
        sort {
            $a->title cmp $b->title
        }
        grep {
               $Config->talks_show_all
            || $_->accepted
            || ($Request{user} && ( $Request{user}->is_talks_admin
                                 || $Request{user}->user_id == $_->user_id))
        } @$talks
    ];

    # process the template
    my $template = Act::Template::HTML->new;
    $template->variables(
        talks   => $talks,
    ); 

    $template->process("talk/proceedings");
}


#
# text_summary()
# ------------
sub text_summary {
    my ($text, $limit) = @_;

    # extract the first paragraph
    my $para = substr($text, 0, index($text, "\n"));

    # if it's still too long, extract as many phrases as possible,
    # while keeping below $limit characters
    if (length($para) > $limit) {
        my @chunks = split /([.?!] +|[.?!]\z)/, $para;
        my $str = "";

        while (@chunks and (length($str) + length($chunks[0])) < $limit) {
            $str .= shift @chunks;
            $str .= shift @chunks;
        }

        $para = "$str [...]";
    }
    
    return $para
}


1;
__END__

=head1 NAME

Act::Handler::Talk::Proceedings - show proceedings

=head1 DESCRIPTION

Show proceedings: all talks in a big list, with the useful details.

See F<DEVDOC> for a complete discussion on handlers.

=cut
