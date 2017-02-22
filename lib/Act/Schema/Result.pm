package Act::Schema::Result;

use base 'DBIx::Class::Core';
use DBIx::Class::Carp;

use namespace::clean;

sub belongs_to {
    #my ($class, $rel_name, $rel_class, $rel_cond, $rel_attrs) = @_;

    splice @_, 4, 1, {
        is_deferrable => 1,
        on_delete => 'CASCADE',
        on_update => 'CASCADE',
        %{ $_[4] || {} }
    };

    shift->next::method(@_);
}

sub has_many {
    #my ($class, $rel_name, $rel_class, $rel_cond, $rel_attrs) = @_;

    splice @_, 4, 1, {
        cascade_delete => 0,
        cascade_update => 0,
        cascade_copy => 0,

        %{ $_[4] || {} }
    };

    shift->next::method(@_);
}

sub might_have {
    #my ($class, $rel_name, $rel_class, $rel_cond, $rel_attrs) = @_;

    splice @_, 4, 1, {
        cascade_delete => 0,
        cascade_update => 0,
        cascade_copy => 0,

        %{ $_[4] || {} }
    };

    shift->next::method(@_);
}

sub has_one {
    my $class = shift;
    $class->throw_exception( "has_one is a bad idea, you 99.999% didn't mean to use it- please check @{[ ref $class || $class ]}" )
}

1;
