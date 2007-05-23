package Act::Track;
use Act::Object;
use base qw( Act::Object );

# class data used by Act::Object
our $table       = 'tracks';
our $primary_key = 'track_id';

our %sql_stub    = (
    select => "t.*",
    from   => "tracks t",
);
our %sql_mapping = (
    title        => "(t.title~*?)",
    description  => "(t.description~*?)",
    # standard stuff
    map( { ($_, "(t.$_=?)") }
         qw( track_id conf_id ) )
);
our %sql_opts    = ( 'order by' => 'title' );

*get_tracks = \&Act::Object::get_items;

=head1 NAME

Act::Track - An Act object representing a talk track.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;

