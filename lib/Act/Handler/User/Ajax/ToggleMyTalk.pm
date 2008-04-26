package Act::Handler::User::Ajax::ToggleMyTalk;
use strict;

use Act::Talk;
use Act::User;
use Act::Config;
use Act::Util;

sub handler
{
    if ($Request{user}->has_registered && $Request{args}{talk_id}) {
        my $talk = Act::Talk->new(talk_id => $Request{args}{talk_id}, conf_id => $Request{conference});
        my $my_talks = $Request{user}->my_talks;
        $Request{user}->update_my_talks(
            grep( { $_->talk_id == $talk->talk_id } @$my_talks)         # is talk currently selected?
              ? ( grep { $_->talk_id != $talk->talk_id } @$my_talks )   # yes, remove
              : ( @$my_talks, $talk )                                   # no, add it
        );
    }
}
1;

=head1 NAME

Act::Handler::User::Ajax::ToggleMyTalk - add or remove a user's my_talk

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
