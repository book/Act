package Act::Invoice;
use strict;
use Carp qw(croak);
use Act::Config;
use Act::Object;
use base qw( Act::Object );

use constant DEBUG => !$^C && $Config->database_debug;

# class data used by Act::Object
our $table       = 'invoices';
our $primary_key = 'invoice_id';

our %sql_stub    = (
    select => "i.*",
    from   => "invoices i",
);
our %sql_mapping = (
    # standard stuff
    map( { ($_, "(i.$_=?)") }
         qw( order_id invoice_id ) )
);
our %sql_opts;

sub create {
    my ($class, %args ) = @_;
    
    $args{datetime} = DateTime->now();
    
    # get next invoice number for this conference
    my $sql = "SELECT next_num FROM invoice_num WHERE conf_id=?";
    Act::Object::_sql_debug($sql, $Request{conference}) if DEBUG;
    my $sth = $Request{dbh}->prepare_cached($sql);
    $sth->execute($Request{conference});
    ($args{invoice_no}) = $sth->fetchrow_array;
    $sth->finish;
    if ($args{invoice_no}) {
        $sql = "UPDATE invoice_num SET next_num=next_num+1 WHERE conf_id=?";
        Act::Object::_sql_debug($sql, $Request{conference}) if DEBUG;
        $sth = $Request{dbh}->prepare_cached($sql);
        $sth->execute($Request{conference});
    }
    else {
        $sql = "INSERT INTO invoice_num (conf_id, next_num) VALUES (?,?)";
        Act::Object::_sql_debug($sql, $Request{conference}, 2) if DEBUG;
        $sth = $Request{dbh}->prepare_cached($sql);
        $sth->execute($Request{conference}, 2);
        $args{invoice_no} = 1;
    }
    return $class->SUPER::create(%args);
}
sub update {
    croak "invoices can't be updated";
}

=head1 NAME

Act::Invoice - An Act object representing an invoice.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;
