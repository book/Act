package Act::Handler::Talk::List;
use strict;
use Apache::Constants qw(NOT_FOUND);
use Act::Config;
use Act::Template::HTML;
use Act::Talk;

sub handler
{
    # retrieve talks and speaker info
    my $talks = Act::Talk->get_talks(conf_id => $Request{conference});
    $_->{user} = Act::User->new(user_id => $_->user_id) for @$talks;

    # accept / unaccept talks
    my $accepted = 0;
    if ($Request{user} && $Request{user}->is_orga && $Request{args}{ok}) {
        for my $t (@$talks) {
            if ($t->accepted && !$Request{args}{$t->talk_id}) {
                $t->update(accepted => 'f');
                $t->{accepted} = undef;
            }
            elsif (!$t->accepted && $Request{args}{$t->talk_id}) {
                $t->update(accepted => 't');
            }
            $accepted++ if $t->accepted;
        }
    }
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        talks => [ sort { lc $a->{user}{last_name} cmp lc $b->{user}{last_name} } @$talks ],
        talks_total    => scalar @$talks,
        talks_accepted => $accepted
    ); 
    $template->process('talk/list');
}

1;
__END__

=head1 NAME

Act::Handler::User::List - show all talks

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
