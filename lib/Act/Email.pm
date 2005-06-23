#  send emails

use strict;
package Act::Email;

use MIME::Lite ();
use Net::SMTP;
use Act::Config;

# send an email
# Act::Email::send(
#     from    => <address>
#     to      => <addresses>
#     subject => 'blah',
#     body    => 'more blah',
# optional args (default values are shown):
#     cc           => <addresses>
#     bcc          => <addresses>
#     encoding     => 'ISO-8859-1',
#     content_type => 'text/plain',
#     precedence   => 'bulk',
#     xheader      => <headers>,
# );
#
# <address>   'foo@example.com' or { name => 'Foo Bar', email => 'foo@example.com' }
# <addresses>  <address> or [ <address>, <address>, ... ]
# <header>     { 'X-foo' => 'bar' }
# <headers>    <header> or [ <headers>, <header>, ... ]

my %defaults = (
     encoding     => 'ISO-8859-1',
     content_type => 'text/plain',
     precedence   => 'bulk',
);
sub send
{
    my %args = @_;

    # apply defaults
    for my $key (keys %defaults) {
        $args{$key} = $defaults{$key}
            unless $args{$key};
    }
    $args{to} = [ $args{to} ] if ref($args{to}) ne 'ARRAY';
    $args{bcc} = [ $args{bcc} ] if $args{bcc} && ref($args{bcc}) ne 'ARRAY';
    $args{bcc} ||= [];

    # sender
    my $from = ref($args{from}) ? $args{from} : { email => $args{from} };

    # if testing, send it to the tester's email address
    # with the original recipients prepended to the message body
    if ($Config->email_test) {
        $args{subject} = "[TEST] $args{subject}";
        require 'Data/Dumper.pm';
        my $dump = Data::Dumper->Dump(
                        [ map $args{$_}, qw(to cc bcc) ],
                        [ qw(to cc bcc) ]
                      );
        $args{body}    = $dump . $args{body};
        $args{to}      = { name => 'Testeur fou', email => $Config->email_test };
        delete $args{$_} for qw(cc bcc);
    }
    # create message
    chomp $args{subject};
    my $msg = MIME::Lite->new (
        From            => $from->{name}
                         ? "$from->{name} <$from->{email}>"
                         : $from->{email},
        Subject         => $args{subject},
        'Precedence:'   => $args{precedence},
        Type            => qq($args{content_type}; charset="$args{encoding}"),
        Datestamp       => 0,
        Data            => $args{body},
    );
    my %opts;
    $opts{Port} = $Config->email_smtp_port
        if $Config->email_smtp_port;
    my $smtp = Net::SMTP->new($Config->email_smtp_server, %opts);
    unless ($smtp) {
        warn "can't create new Net::SMTP object\n";
        return;
    }

    # envelope sender
    $smtp->mail($from->{email});

    # recipients
    my %trecip = (
        to  => 'To',
        cc  => 'Cc',
        bcc => undef,
    );
    while (my ($type, $header) = each %trecip) {
        my $recip = $args{$type} or next;
        $recip = [ $recip ] if ref($recip) ne "ARRAY";
        for my $r (@$recip) {
            $r = { email => $r } unless ref($r);
            $msg->add($header => $r->{name} ? "$r->{name} <$r->{email}>"
                                            : "<$r->{email}>"
                     )
                if $header;
            $smtp->to($r->{email});
        }
    }

    # x-headers
    if (my $xh = $args{xheaders}) {
        $xh = [ $xh ] unless ref($xh) eq 'ARRAY';
        $msg->add(%$_) for @$xh;
    }

    # send it!
       $smtp->data()
    && $smtp->datasend($msg->as_string())
    && $smtp->dataend()
    && $smtp->quit()
    && return;

    warn $smtp->message;
}
1;
__END__

=head1 NAME

Act::Email - send email

=head1 SYNOPSIS

    use Act::Email;
    Act::Email::send_email(%args);

=cut
