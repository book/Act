package Act::Template;

use strict;
use Carp;

use Act::Config;
use Act::Template::Parser;
use Act::Util;

use base qw(Template);

use constant TEMPLATE_DIRS => qw(static templates);

my %templates;

sub new
{
    my $class = shift;

    # return a cached template if we have one
    my $conf = $Request{conference} || '-global';
    return $templates{$class}{$conf} if exists $templates{$class}{$conf};

    # otherwise create one
    my $self = $class->SUPER::new(@_);
    $templates{$class}{$conf} = $self;
    return $self;
}
sub _init
{
    my ($self, $options) = @_;

    # default options
    $self->{$_} = 1 for qw(POST_CHOMP);
    $options->{PARSER} ||= Act::Template::Parser->new($options);
    $options->{PLUGIN_BASE} = 'Act::Plugin';
    unless ($options->{INCLUDE_PATH}) {
        my @path;
        # conference-specific template dirs
        push @path, map join('/', $Config->home, $Request{conference}, $_), TEMPLATE_DIRS
            if $Request{conference};
        # global template dirs
        push @path, map join('/', $Config->home, $_), TEMPLATE_DIRS;
        $options->{INCLUDE_PATH} = \@path;
    }

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
    my $web = $Request{r} && ref($Request{r}) && $Request{r}->isa('Apache');
    $output ||= $Request{r} if $web;

    # set global variables
    my %global = (
         config  => $Config,
         request => \%Request,
    );
    if ($web) {
         $global{languages} = [
           map {{
                 %{$Config->languages->{$_}},
                 uri => self_uri(%{$Request{args}}, language => $_),
               }}
           grep { $_ ne $Request{language} }
           sort keys %{$Config->languages}
         ];
    }

    $self->variables(
      global        => \%global,
      make_uri      => \&Act::Util::make_uri,
      make_uri_info => \&Act::Util::make_uri_info,
    );

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

=head1 NAME

Act::Template - template object base class

=head1 SYNOPSIS

    use Act::Template;
    my $template = Act::Template->new();
    $template->variables(foo => 42);
    $template->process('talkview');

=head1 DESCRIPTION

The Act::Template class is used to process Act templates.

=head2 Methods

Act::Template defines the following methods:

=over 4

=item new()

Creates a new template object, or fetch an existing one.
The template's INCLUDE_PATH is suitable for the current request:
conference-specific template directories followed by global
template directories.
This template object can then be used to process one or more
template files.
When used in a web (mod_perl) context, it is recommended that
template objects be held in lexical variables of limited scope,
so that they don't persist across requests. The object's configuration
is request-dependent, and new() already maintains a cache of persistent
template objects.

=item variables(I<%variables>)

Set template variables.

=item process(I<$template_name>, I<$output>)

Merges a template with the current variables.
I<$template_name> is the name of a template file,
or a reference to a string containing the template text.

The default output is the current request object (output is
sent to the client), or STDOUT if not in a web context.
If <$output> is provided, it can be anything that Template-E<gt>process()
accepts as its third argument, the most common being
a reference to a scalar (e.g. a text string) to which output is appended.

All variables are cleared after calling process().

=back

=cut
