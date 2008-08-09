package Act::Talk;
use Act::Config;
use Act::Object;
use base qw( Act::Object );

use constant DEBUG => !$^C && $Config->database_debug;

# class data used by Act::Object
our $table       = 'talks';
our $primary_key = 'talk_id';

our %sql_stub    = (
    select => "t.*",
    from   => "talks t",
);
our %sql_mapping = (
    title     => "(t.title~*?)",
    abstract  => "(t.abstract~*?)",
    # datetime    => recherche par date ?
    # standard stuff
    map( { ($_, "(t.$_=?)") }
         qw( talk_id user_id conf_id duration room
             lightning accepted confirmed track_id ) )
);
our %sql_opts    = ( 'order by' => 'talk_id' );

*get_talks = \&Act::Object::get_items;

sub delete {
    my ($self, %args) = @_;

    my $SQL = 'DELETE FROM user_talks WHERE talk_id=?';
    Act::Object::_sql_debug($SQL, $self->talk_id) if DEBUG;
    my $sth = $Request{dbh}->prepare_cached($SQL);
    $sth->execute($self->talk_id);

    $self->SUPER::delete(%args);
    $Request{dbh}->commit;
}

=head1 NAME

Act::Talk - An Act object representing a talk.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;

