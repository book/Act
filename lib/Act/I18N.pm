package Act::I18N;

use strict;
use File::Spec::Functions qw(catfile);
use base qw(Locale::Maketext);
use Locale::Maketext::Lexicon;

use Act::Config;

unless ($^C) {
    Locale::Maketext::Lexicon->import({
        '*' => [ Gettext => catfile($Config->home, 'po', '*', '*.[pm]o') ],
        _auto   => 0,
        _decode => 0,
        _style  => 'gettext',
    });
}

sub lexicon
{
    my $self = shift;

    no strict 'refs';
    my $pkg = ref $self;
    return \%{"$pkg\::Lexicon"};
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
  
  # Iterate over available strings
  my $lexicon = $lh->lexicon();
  while (my ($id, $string) = each %$lexicon) {
    ...
  }

=head1 DESCRIPTION

Act::I18N provides the interface through which Act is
internationalised, and how different localizations are implemented.

=cut
