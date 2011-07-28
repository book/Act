package Act::Handler::CSV;
use strict;
use Act::Config;
use Plack::Request;
use Text::xSV;
use parent qw(Act::Handler);

my %CSV = (
    # report => [ auth_sub, sql, args ]
    users => [ sub { $_[0]->is_users_admin() }, << 'SQL', [] ],
SELECT u.user_id, u.last_name, u.first_name, u.nick_name, u.email, p.datetime, u.pseudonymous
FROM users u, participations p
WHERE u.user_id=p.user_id
  AND p.conf_id=?
ORDER BY p.datetime, u.last_name, u.first_name
SQL

    payments => [ sub { $_[0]->is_treasurer() }, << 'SQL', [ 'paid'] ],
SELECT o.order_id, o.user_id, o.conf_id, o.datetime, u.first_name,
    u.last_name, u.email, SUM(oi.amount), o.currency, o.means,
    i.invoice_no, i.company, i.address, i.vat
FROM orders o
LEFT JOIN users u ON (o.user_id = u.user_id )
LEFT JOIN invoices i ON (o.order_id = i.order_id)
LEFT JOIN order_items oi ON (o.order_id = oi.order_id)
WHERE o.conf_id = ? AND o.status = ?
GROUP BY o.order_id, o.user_id, o.conf_id, o.datetime,
         u.first_name, u.last_name, u.email,
         o.currency, o.means,
         i.invoice_no, i.company, i.address, i.vat
ORDER BY o.datetime
SQL

    payment_items => [ sub { $_[0]->is_treasurer() }, << 'SQL', [ 'paid'] ],
SELECT o.order_id, o.user_id, o.conf_id, o.datetime, u.first_name,
    u.last_name, u.email, o.currency, o.means,
    oi.amount, oi.name
FROM orders o
LEFT JOIN users u ON (o.user_id = u.user_id )
LEFT JOIN order_items oi ON (o.order_id = oi.order_id)
WHERE o.conf_id = ? AND o.status = ?
ORDER BY o.datetime
SQL
);

sub handler
{
    my ( $env ) = @_;

    my $req = Plack::Request->new($env);
    my $res = $req->new_response;

    # check csv request
    unless( exists $CSV{$req->path_info} ) {
        $res->status(404);
        return $res->finalize;
    }

    my $report = $CSV{$req->path_info};

    # check rights
    # XXX WARNING: $Request{user} used to be an object! This needs to be fixed!
    unless ( $req->user && $report->[0]->($req->user)) {
        $res->status(403);
        return $res->finalize;
    }

    # retrieve the information
    my $sth = $env->{'act.dbh'}->prepare( $report->[1] );
    $sth->execute( $env->{'act.conference'}, @{$report->[2]} );

    # and spit out the xSV report
    $res->content_type('text/csv; charset=UTF-8');

    my $csv  = Text::xSV->new;
    my $body = '';
    $body .= $csv->format_row( @{$sth->{NAME_lc}} );
    while( my $row = $sth->fetchrow_arrayref() ) {
        $body .= $csv->format_row(@$row);
    }

    $res->body($body);

    return $res->finalize;
}

1;
__END__

=head1 NAME

Act::Handler::Payment::List - show all payments

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
