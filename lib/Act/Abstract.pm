package Act::Abstract;
use strict;
use Act::Config;
use Act::Talk;
use Act::User;

# turn talk:id into real talks
sub chunked {
    my $i = 0;
    return [
        map {
            my $t = { };
            if ( $i++ % 2 ) {
                $t->{talk} = Act::Talk->new(
                    talk_id => $_,
                    conf_id => $Request{conference}
                ) ;
                $t->{user} = Act::User->new( user_id => $t->{talk}->user_id );
            }
            else { $t->{text} = $_ };
            $t;
          } split /talk:(\d+)/,
        $_[0]
    ];
}

1;

__END__

=head1 NAME

Act::Abstract - event/talk abstract utilities

=head1 SYNOPSIS

    use Act::Abstract;
    my $chunked = Act::Abstract::chunked($talk->abstract);

=cut
