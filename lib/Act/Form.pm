use strict;
package Act::Form;
use Email::Valid;

my %constraints = (
  email   => sub { Email::Valid->address($_[0]) },
  numeric => sub { $_[0] =~ /^\d*$/ },
);

sub new
{
    my ($class, %profile) = @_;
    return bless { profile => \%profile }, $class;
}

sub validate
{
    my ($self, $input) = @_;

    # reset our internal state
    $self->{fields}  = {};
    $self->{invalid} = {};

    # check required fields
    if (my $required = $self->_profile_fields('required')) {
        for my $field (@$required) {
            $self->_set_field($field, $input->{$field});
            $self->{invalid}{$field} = 'required'
                unless $self->{fields}{$field};
        }
    }
    # optional fields
    if (my $optional = $self->_profile_fields('optional')) {
        for my $field (@$optional) {
            $self->_set_field($field, $input->{$field});
        }
    }
    # check constraints
    if ($self->{profile}{constraints}) {
        while (my ($field, $type) = each %{$self->{profile}{constraints}}) {
            exists $self->{fields}{$field}
                or die "unknown field: $field\n";
            next if $self->{invalid}{$field}; # missing required field
            my $c = $constraints{$type}
                or die "unknown constraint type: $type\n";
            $c->($self->{fields}{$field})
                or $self->{invalid}{$field} = $type;
        }
    }
    # return true if validation successful
    return 0 == keys %{$self->{invalid}};
}
sub fields  { return $_[0]->{fields}  }
sub invalid { return $_[0]->{invalid} }

sub _profile_fields
{
    my ($self, $type) = @_;
    my $fields = $self->{profile}{$type};
    $fields = [ $fields ] if $fields && !ref($fields);
    return $fields;
}    
sub _set_field
{
    my ($self, $field, $value) = @_;
    if (defined $value) {
        for ($value) {
            s/^\s+//;
            s/\s+$//;
        }
    }
    $self->{fields}{$field} = $value;
}

1;

__END__

=head1 NAME

Act::Form - Form object class

=head1 SYNOPSIS

  use Act::Form;
  
  my $form = Act::Form->new(
    required    => [ qw(name email) ],
    optional    => [ qw(timezone homepage zip) ],
    constraints => {
       email => 'email',
       zip   => 'numeric',
    }
  );
  
  sub handler
  {
      my $fields;
      if ($Request{args}{OK}) {   # form has been submitted
          if ($form->validate($Request{args})) {
              update_database($form->{fields});
              $template->process("thanks");
              return;
          }
          else {
              $template->variables(errors => $form->{invalid});
          }
      }
      else {                      # display initial form
          # pull $fields from somewhere
          $fields = read_database();
      }
      # (re-)display form
      $template->variables(%$fields);
      $template->process("form");
  }

=head1 DESCRIPTION

=over 4

=item new(%profile)

Creates a new Act::Form object with a specific validation profile.
The validation can contain the following entries:

   required  => [ 'field1', 'field2' ]

The value is a list of names of mandatory fields.

   optional => [ 'field3', 'field4' ]

The value is a list of names of optional fields. The C<fields>
method will return all fields.

   constraints => {
      field1  => type1,
      field2  => type2,
   }

The constraints key introduces specific validation schemes.
For each entry, the key is the name of the field the constraint
is to be applied to, and the value is the type of the constraint;
The following constraint types are currently available:

   email       # field value must be a syntaxically valid email address
   numeric     # field value must be a number

=item validate($input)

Validates a hash of input parameters against the object's profile
specification. This module considers the list of fields as the
union of those specified as 'required' and those specified as
'optional'. Any other keys in the input hash will be disregarded.
The input hash is left unchanged.

Returns true if the input hash satisfied all profile requirements.

=item fields

A hash of fields. This hash holds all the fields: fields from
the input hash have their value trimmed, fields missing from
the input hash have the value undef. This is suitable for
creating "sticky" forms: in case of an error, this hash is
used to display the form again while retaining the user's
input.

=item invalid

A hash of invalid fields. There is one entry for each invalid field.
For each entry, the key is the field name and the value is the name
of the error: either 'required', or a constraint type such as
'email' or 'numeric'.

=back

=cut
