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
                my ($what, $id) = split ':';
                if ($what eq 'talk') {
                    $t->{talk} = Act::Talk->new(
                        talk_id => $id,
                        conf_id => $Request{conference}
                    ) ;
                    if ($t->{talk}) {
                        $t->{user}
                            = Act::User->new( user_id => $t->{talk}->user_id );
                    }
                    else {
                        $t->{text} = "talk:$id"; # non-existent talk
                    }
                }
                elsif ($what eq 'user') {
                    $t->{user} = Act::User->new( user_id => $id)
                        or $t->{text} = "user:$id";  # non-existent user
                }
                else { $t->{text} = $_ }
            }
            else { $t->{text} = $_ }
            $t;
          } split /((?:talk|user):\d+)/,
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
