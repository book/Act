use strict;
package Act::Form;
use Email::Valid;

my %constraints = (
  email   => sub { Email::Valid->address($_[0]) },
  numeric => sub { $_[0] =~ /^\d*$/ },
  url     => sub { $_[0] =~ m!^(?:http|ftp)://\S+$! },
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
        $self->_required_fields($required, $input);
    }
    # optional fields
    if (my $optional = $self->_profile_fields('optional')) {
        $self->_optional_fields($optional, $input);
    }
    # check dependencies
    if ($self->{profile}{dependencies}) {
        while (my ($field, $deps) = each %{$self->{profile}{dependencies}}) {
            $self->_set_field($field, $input->{$field});
            if ($self->{fields}{$field}) {
                $self->_required_fields($deps, $input);
            }
            else {
                $self->_optional_fields($deps, $input);
            }
        }
    }
    # check constraints
    if ($self->{profile}{constraints}) {
        while (my ($field, $type) = each %{$self->{profile}{constraints}}) {
            exists $self->{fields}{$field}
                or die "unknown field: $field\n";
            next if $self->{invalid}{$field}; # already in error
            my $code;
            if (ref($type) eq 'CODE') {
                $code = $type;
                $type = 'custom';
            }
            else {
                $code = $constraints{$type}
                    or die "unknown constraint type: $type\n";
            }
            !defined($self->{fields}{$field}) || $code->($self->{fields}{$field})
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
sub _required_fields
{
    my ($self, $fields, $input) = @_;

    for my $field (@$fields) {
        $self->_set_field($field, $input->{$field});
        $self->{invalid}{$field} = 'required'
            unless $self->{fields}{$field};
    }
}
sub _optional_fields
{
    my ($self, $fields, $input) = @_;

    for my $field (@$fields) {
        $self->_set_field($field, $input->{$field});
    }
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
    dependencies => {
       # If cc_no is entered, make cc_type and cc_exp required
       cc_no => [ qw( cc_type cc_exp ) ],
    },
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
              $fields = $form->{fields};
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

The value is a list of names of optional fields.
A simple scalar can be used instead of an array reference when
only one field needs to be specified:

   required => 'field'

The dependencies key lists fields required only if a specific
field value isn't empty.

    dependencies => {
      field2   => [ 'field5', 'field6' ]
    }

Field names used in dependencies do not need to be added
to the profile's optional fields array.

The constraints key introduces specific validation schemes.

   constraints => {
      field1  => type1,
      field2  => type2,
   }

For each entry, the key is the name of the field the constraint
is to be applied to, and the value is the type of the constraint;
The following constraint types are currently available:

email       field value must be a syntaxically valid email address
numeric     field value must be a number

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
Note that currenty, one error is reported per field. In other words,
once a field has been found to be in error, it is excluded from
further checks.

=back

=cut
