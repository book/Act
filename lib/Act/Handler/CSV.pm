package Act::Handler::CSV;
use strict;
use Apache::Constants qw(NOT_FOUND FORBIDDEN);
use Act::Config;
use Text::xSV;

my %CSV = (
    # report => [ auth_sub, sql, args ]
    users => [ sub { $_[0]->is_orga() }, << 'SQL', [] ],
SELECT u.user_id, u.last_name, u.first_name, u.nick_name, u.email, p.datetime
FROM users u, participations p
WHERE u.user_id=p.user_id
  AND p.conf_id=?
ORDER BY p.datetime, u.last_name, u.first_name
SQL
    payments => [ sub { $_[0]->is_treasurer() }, << 'SQL', [ 'paid'] ],
SELECT o.order_id, o.user_id, o.conf_id, o.datetime, u.first_name,
    u.last_name, u.email, o.amount, o.currency, o.means,
    i.invoice_no, i.company, i.address, i.vat
FROM orders o
LEFT JOIN users u ON (o.user_id = u.user_id )
LEFT JOIN invoices i ON (o.order_id = i.order_id)
WHERE o.conf_id = ? AND o.status = ?
ORDER BY o.datetime
SQL
);

sub handler
{
    # check csv request
    unless ( exists $CSV{$Request{path_info}} ) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $report = $CSV{$Request{path_info}};

    # check rights
    unless ($Request{user} && $report->[0]->($Request{user})) {
        $Request{status} = FORBIDDEN;
        return;
    }

    # retrieve the information
    my $sth = $Request{dbh}->prepare( $report->[1] );
    $sth->execute( $Request{conference}, @{$report->[2]} );

    # and spit out the xSV report
    $Request{r}->send_http_header('text/csv; charset=UTF-8');

    my $csv = Text::xSV->new;
    print $csv->format_row( @{$sth->{NAME_lc}} );
    while( my $row = $sth->fetchrow_arrayref() ) {
        print $csv->format_row(@$row);
    }

}

1;
__END__

=head1 NAME

Act::Handler::Payment::List - show all payments

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
