package Act::Talk;
use Act::Object;
use base qw( Act::Object );

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
    # given    => recherche par date ?
    # standard stuff
    map( { ($_, "(t.$_=?)") }
         qw( talk_id user_id conf_id duration room
             lightning accepted confirmed ) )
);
our %sql_opts    = ( 'order by' => 'talk_id' );

*get_talks = \&Act::Object::get_items;

=head1 NAME

Act::Talk - An Act object representing a talk.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;

