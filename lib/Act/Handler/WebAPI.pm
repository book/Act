package Act::Handler::WebAPI;
use strict;
use Apache::Constants qw(OK BAD_REQUEST);
use JSON::XS ();

use Act::Config;
use Act::Talk;
use Act::User;

my %Methods = (
    get_attendees => \&_get_attendees,
    get_talks     => \&_get_talks,
);
my $json = JSON::XS->new->utf8->pretty(1);

sub handler
{
    # authenticate
    if ( $Request{args}{api_key} && $Config->api_keys->{ $Request{args}{api_key} } ) {

        # get method
        my $method = $Request{path_info};
        if ($method && $Methods{$method}) {

            # execute method
            my $data = $Methods{$method}->();

            # send result as json
            $Request{r}->no_cache(1);
            $Request{r}->send_http_header('text/plain; charset=UTF-8');
            $Request{r}->print($json->encode($data));

            return;
        }
    }
    $Request{status} = BAD_REQUEST;
}
sub _get_attendees
{
    my $users = Act::User->get_items( conf_id => $Request{conference} );
    my @data;
    for my $u (@$users) {
        push @data, { map { $_ => $u->$_ } qw(full_name email) }
            if $u->committed;
    }
    return \@data;
}
sub _get_talks
{
    my $talks = Act::Talk->get_talks( conf_id => $Request{conference} );
    my @data;
    for my $t (@$talks) {
        if ($Config->talks_show_all || $t->accepted) {
            my $u = Act::User->new(user_id => $t->user_id);
            my %talk_data = (
                title   => $t->title,
                speaker => $u->full_name,
            );
            if ($Config->talks_show_schedule) {
                $talk_data{room}     = $Config->rooms->{ $t->room } if $t->room;
                $talk_data{datetime} = $t->datetime->epoch          if $t->datetime;
            }
            push @data, \%talk_data;
        }
    }
    return \@data;
}

1;
__END__

=head1 NAME

Act::Handler::WebAPI

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
