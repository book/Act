#!perl -w

use strict;
use Act::Config;

my @templates = (
    { in  => 'foo',
      out => 'foo',
    },
    {
      var => { v => '<>&' },
      in  => '[% v %]',
      out => '<>&',
    },
    {
      in  => '<t><fr>foo</fr></t>',
      out => 'foo',
    },
    {
      in  => '<t><en>foo</en></t>',
      out => '',
    },
    {
      in  => "<t><fr>foo</fr>\n<en>bar</en></t>",
      out => "foo\n",
    },
    {
      lang =>'en',
      in  => '<t><fr>foo</fr></t>',
      out => '',
    },
    {
      lang => 'en',
      in  => '<t><en>foo</en></t>',
      out => 'foo',
    },
    {
      lang => 'en',
      in  => "<t><fr>foo</fr>\n<en>bar</en></t>",
      out => 'bar',
    },
);
my @html_templates = (
    { in  => 'foo',
      out => 'foo',
    },
    {
      in  => '<t><fr>foo</fr></t>',
      out => 'foo',
    },
    {
      var => { v => '<>&' },
      in  => '[% v %]',
      out => '&lt;&gt;&amp;',
    },
    {
      var => { v =>  { w => '<>&' }},
      in  => '[% v.w %]',
      out => '&lt;&gt;&amp;',
    },
    {
      var => { v => '<>&' },
      raw => 1,
      in  => '[% v %]',
      out => '<>&',
    },
);
use Test::More;
plan tests => 2 * (@templates + @html_templates) + 10;

require_ok('Act::Template');
my $template = Act::Template->new;
ok($template);

# variables
my %h = (foo => 42, bar => 43);
$template->variables(%h);
is($template->variables($_), $h{$_}) for keys %h;
ok(eq_hash($template->variables(), \%h));
$template->clear;
is($template->variables($_), undef) for keys %h;
ok(eq_hash($template->variables(), {}));

for my $t (@templates) {
    _ttest($template, $t);
}
##### Act::Template::HTML
require_ok('Act::Template::HTML');
$template = Act::Template::HTML->new;
ok($template);

for my $t (@html_templates) {
    _ttest($template, $t);
}

#####
sub _ttest
{
    my ($template, $t) = @_;
    if ($t->{var}) {
        my $method = 'variables';
        $method .= '_raw' if $t->{raw};
        $template->$method(%{$t->{var}});
    }
    %Request = ( language => $t->{lang} || 'fr' );
    my $output;
    ok($template->process(\$t->{in}, \$output));
    is($output, $t->{out});
}

__END__
