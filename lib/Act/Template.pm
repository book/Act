package Act::Template;

use strict;
use Carp;
use Act::Template::Parser ();
use base qw(Template);

sub _init
{
    my ($self, $options) = @_;

    # default options
    $self->{$_} = 1 for qw(POST_CHOMP);
    $options->{PARSER} ||= Act::Template::Parser->new($options);

    # supplied options
    $self->{$_} = $options->{$_} for keys %$options;

    # base class initialization
    $self->SUPER::_init($options)
        or die error();

    $self->clear();
    return $self;
}

# clear template variables
sub clear
{
    shift->{vars} = {};
}

# get or set variables
sub variables
{
    my $self = shift;
    @_ == 0 and return $self->{vars};
    @_ == 1 and return $self->{vars}{$_[0]};
    while (my ($key, $value) = splice(@_, 0, 2)) {
        next unless defined $value;
        $self->encode($value);
        $self->{vars}{$key} = $value;
    }
}

sub encode
{} # no default encoding

sub process
{
    my ($self, $filename, $output) = @_;

    # language must be defined at this point
    #$self->{vars}{global}{language}
    #   or croak "undefined language";

    # process and output
    my $ok;
    unless ($ok = $self->SUPER::process($filename, $self->{vars}, $output)) {
        die $self->error();
    }

    # clear variables for next user
    $self->clear;

    return $ok;
}

1;

__END__
