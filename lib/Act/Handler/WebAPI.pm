package Act::Handler::WebAPI;
use strict;
use Apache::Constants qw(OK BAD_REQUEST);
use JSON::XS ();

use Act::Config;
use Act::Talk;
use Act::Track;
use Act::User;

my %Methods = (
    get_attendees => {
        run => \&_get_attendees,
        fields  => {
           map( { $_ =>  0 }
               qw(user_id login
                  salutation first_name last_name full_name public_name pseudonymous
                  country town web_page pm_group pause_id monk_id monk_name im email
                  language timezone
                  company address vat
                  registered
               )),
        },
        default => [ qw(public_name email) ],
    },
    get_talks => {
        run => \&_get_talks,
        fields  => {
           map( { $_ => 0 }
               qw(talk_id user_id track_id
                  title abstract url_abstract url_talk duration lightning
                  accepted confirmed
                  level lang 
               )),
           datetime => \&_talk_datetime,
           room     => \&_talk_room,
           speaker  => \&_talk_speaker,
           track    => \&_talk_track,
        },
        default => [ qw(title speaker room datetime) ],
    },
);
my $json = JSON::XS->new->utf8->pretty(1);


sub handler {
    # authenticate
    if ( $Request{args}{api_key} && $Config->api_keys->{ $Request{args}{api_key} } ) {

        # get method
        my $method = $Request{path_info};
        if ($method && (my $m = $Methods{$method})) {

            # fields
            my @fields = $Request{args}{fields}
                        ? split(/,/, $Request{args}{fields})
                        : @{$m->{default}};

            # execute method
            my $data = $m->{run}->($m, \@fields);

            # send result as json
            $Request{r}->no_cache(1);
            $Request{r}->send_http_header('text/plain; charset=UTF-8');
            $Request{r}->print($json->encode($data));

            return;
        }
    }
    $Request{status} = BAD_REQUEST;
}


sub _get_attendees {
    my ($m, $fields) = @_;
    my %fields = map { $_ => 1 } @$fields;
    my @fields = grep { !/registered/ } @$fields;

    my $users = Act::User->get_items( conf_id => $Request{conference} );
    my @data;
    for my $user (@$users) {
        push @data, _get_fields($m, \@fields, $user)
            if($user->committed || ($user->has_registered && $fields{registered}));
    }
    return \@data;
}


sub _get_talks {
    my ($m, $fields) = @_;

    my $talks = Act::Talk->get_talks( conf_id => $Request{conference} );
    my @data;
    for my $talk (@$talks) {
        push @data, _get_fields($m, $fields, $talk)
            if $Config->talks_show_all || $talk->accepted;
    }
    return \@data;
}


sub _get_fields {
    my ($m, $fields, $object) = @_;

    my %data;
    for my $field (@$fields) {
        my $value =
                   $m->{fields}{$field} ? $m->{fields}{$field}->($object)
          : exists $m->{fields}{$field} ? $object->$field
          :                               undef;
        $data{$field} = $value if defined $value;
    }
    return \%data;
}


sub _talk_datetime {
    my $talk = shift;
    return $Config->talks_show_schedule && $talk->datetime ? $talk->datetime->epoch : undef;
}


sub _talk_room {
    my $talk = shift;
    return $Config->talks_show_schedule && $talk->room ? $talk->room : undef;
}


sub _talk_speaker {
    my $talk = shift;
    my $user = Act::User->new(user_id => $talk->user_id);
    return $user->public_name;
}


sub _talk_track {
    my $talk = shift;
    if ($talk->track_id) {
        my $track = Act::Track->new(track_id => $talk->track_id);
        return $track->title;
    }
    undef;
}

1;
__END__

=head1 NAME

Act::Handler::WebAPI


=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.


=head1 REQUESTS

=head2 Common arguments

=over

=item *

C<api_key> (mandatory) - This argument must be passed with the API key given by the Act
administrator.

=item *

C<fields> - Select which fields are to be returned by he handler.

=back

=head2 Handlers

=over

=item *

C<get_attendees> - Returns the list of attendees for this conference.

Valid fields: address, company, country, email, email, first_name, full_name,
im, language, last_name, login, monk_id, monk_name, pause_id, pm_group,
public_name, pseudonymous, salutation, timezone, town, user_id, vat, web_page

Default fields: public_name, email

=item *

C<get_talks> - Returns the list of talks for this conference.

Valid fields: abstract, accepted, confirmed, datetime, duration, lang, level, lightning,
room, speaker, talk_id, title, track, track_id, url_abstract, url_talk, user_id

Default fields: title speaker room datetime

=back

=cut
