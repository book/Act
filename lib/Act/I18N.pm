package Act::I18N;

use strict;
use File::Spec::Functions qw(catfile);
use base qw(Locale::Maketext);
use Locale::Maketext::Lexicon;

use Act::Config;

unless ($^C) {
    Locale::Maketext::Lexicon->import({
        '*' => [ Gettext => catfile($Config->home, 'po', '*.[pm]o'),
                 Gettext => catfile($Config->home, 'po', '*', '*.[pm]o'),
               ],
        _auto   => 0,
        _decode => 1,
        _style  => 'gettext',
    });
}

sub init
{
    my $self = shift;
    $self->SUPER::init();
    $self->fail_with('failure_handler');
}

sub failure_handler
{
    my ($self, $key, @params) = @_;

    # look up in the default_language lexicon, then in the English lexicon,
    # avoiding infinite recursion
    my $lang = $self->language_tag();
    if ($lang ne 'en') {
        for my $fallback ($Config->general_default_language, 'en') {
            if ($lang ne $fallback) {
                return Act::I18N->get_handle($fallback)->maketext($key, @params);
            }
        }
    }
    return 'TRANSLATEME';
}

1;

__END__

=head1 NAME

Act::I18N - internationalization class

=head1 SYNOPSIS

  # In a handler, get a translated string
  use Act::Util;
  my $xlated = localize('string');
  
  ### low-level access
  use Act::I18N;
  
  # Get a localization handle
  $lh = Act::I18N->get_handle('en');
  
  # Get a translated string
  my $xlated = $lh->maketext('(a string to translate)');

=head1 DESCRIPTION

Act::I18N provides the interface through which Act is
internationalised, and how different localizations are implemented.

=cut
