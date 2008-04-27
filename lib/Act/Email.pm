#  send emails

use strict;
package Act::Email;

use Encode ();
use List::Pairwise qw(mapp);
use Sys::Hostname;

use Act::Config;
use Email::Address;
use Email::Date;
use Email::MessageID;
use Email::Send ();
use Email::Send::Sendmail;
use Email::Simple;
use Email::Simple::Creator;

{
    no warnings 'redefine';
    *Email::Simple::Creator::_crlf  = sub { "\x0d\x0a" };
}

# send an email
# Act::Email::send(
#     from    => <address>
#     to      => <addresses>
#     subject => 'blah',
#     body    => 'more blah',
# optional args (default values are shown):
#     cc           => <addresses>
#     bcc          => <addresses>
#     content_type => 'text/plain',
#     precedence   => 'bulk',
#     xheaders     => <headers>,
# );
#
# <address>   'foo@example.com' or { name => 'Foo Bar', email => 'foo@example.com' }
# <addresses>  <address> or [ <address>, <address>, ... ]
# <header>     { 'X-foo' => 'bar' }
# <headers>    <header> or [ <headers>, <header>, ... ]

$Email::Send::Sendmail::SENDMAIL = $Config->email_sendmail;
my $sender = Email::Send->new( { mailer => 'Sendmail' } );

sub send
{
    my %args = @_;

    my @headers;

    my $from = Email::Address->new( ref $args{from} ? ( @{ $args{from} }{ 'name', 'email' } ) : ( '', $args{from} ) );
    push @headers, ( From => $from->format() );
    chomp $args{subject};

    # if testing, send it to the tester's email address
    # with the original recipients prepended to the message body
    if ( $Config->email_test ) {

        require Data::Dumper;
        my $dump = Data::Dumper->Dump(
                        [ map $args{$_}, qw(to cc bcc) ],
                        [ qw(to cc bcc) ]
                      );
        $args{body} = $dump . $args{body};

        push @headers, ( To => Email::Address->new('Act tester', $Config->email_test)->format(),
                         Subject => "[TEST] $args{subject}",
                       );
    }
    else {
        for my $header ( grep { exists $args{$_} } qw( to cc bcc ) )
        {
            my @recips =
                map { Email::Address->new( ref $_ ? ( $_->{name}, $_->{email} ) : ( '', $_ ) ) }
                ( ref $args{$header} eq 'ARRAY' ? @{ $args{$header} } : $args{$header} );

            push @headers,
                ( ucfirst $header => join ', ', map { $_->format() } @recips );
        }
        push @headers, ( Subject => $args{subject} );
    }

    my $charset;
    if ( $args{body} =~ /^\p{InBasicLatin}+$/ ) {
        $charset = 'US-ASCII';
        push @headers, ( 'Content-Encoding' => '7bit' );
    }
    else {
        $charset = 'UTF-8';
        push @headers, ( 'Content-Encoding' => '8bit' );
    }

    push @headers,
        ( 'Content-Type' => "text/plain; charset=$charset",
          Date           => Email::Date::format_date(),
          'Message-Id'   => Email::MessageID->new(),
          Sender         => $Config->email_sender_address,
          'X-Mailer'     => __PACKAGE__,
        );

    if ( my $xh = $args{xheaders} ) {
        push @headers, %{ $_ } for ref $xh eq 'ARRAY' ? @{ $xh } : $xh;
    }
    # Email::Simple doesn't (yet?) q-encode the headers
    mapp { $b = _encode_header($b) } @headers;

    my $email = Email::Simple->create( header => \@headers, body => Encode::encode_utf8($args{body}) );
    my $return = $sender->send($email);
    warn $return unless $return;
}
# RFC 2047 Q-encoding
sub _encode_header
{
    return Encode::encode('MIME-Q', $_[0]);
}

1;
__END__

=head1 NAME

Act::Email - send email

=head1 SYNOPSIS

    use Act::Email;
    Act::Email::send_email(%args);

=cut
