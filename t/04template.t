#!perl -w

use strict;
use Act::Config;

my @templates = (
    { in  => 'foo',
      out => 'foo',
      sections => [ { nolang => 'foo' } ],
    },
    {
      var => { v => '<>&' },
      in  => '[% v %]',
      out => '<>&',
      sections => [ { nolang => '[% v %]' } ],
    },
    {
      in  => '<t><fr>foo</fr></t>',
      out => 'foo',
      sections => [ { lang => { fr => 'foo' } } ],
    },
    {
      in  => '<t><en>foo</en></t>',
      out => '',
      sections => [ { lang => { en => 'foo' } } ],
    },
    {
      in  => "<t><fr>foo</fr>\n<en>bar</en></t>",
      out => "foo",
      sections => [ { lang => { fr => "foo", en => "bar" } } ],
    },
    {
      lang =>'en',
      in  => '<t><fr>foo</fr></t>',
      out => '',
      sections => [ { lang => { fr => 'foo' } } ],
    },
    {
      lang => 'en',
      in  => '<t><en>foo</en></t>',
      out => 'foo',
      sections => [ { lang => { en => 'foo' } } ],
    },
    {
      lang => 'en',
      in  => "<t><fr>foo</fr>\n<en>bar</en></t>",
      out => 'bar',
      sections => [ { lang => { fr => "foo", en => "bar" } } ],
    },
    {
      var => { v => 'foo' },
      in  => "bar\n  [% v %]  \nbaz",
      out => "bar\n  foo  \nbaz",
      sections => [ { nolang => "bar\n  [% v %]  \nbaz" } ],
   },
    { # sections
      in  => "A<t><fr>foo</fr></t>B<t><en>bar</en></t>C",
      out => 'AfooBC',
      sections => [ { nolang => 'A' },
                    {   lang => { fr => 'foo' } },
                    { nolang => 'B' },
                    {   lang => { en => 'bar' } },
                    { nolang => 'C' },
                  ],
    },
);
my $quote = { q => '"' };
my @html_templates = (
    { in  => 'foo',
      out => 'foo',
      sections => [ { nolang => 'foo' } ],
    },
    {
      in  => '<t><fr>foo</fr></t>',
      out => 'foo',
      sections => [ { lang => { fr => 'foo' } } ],
    },
    {
      var => { v => '<>&"' },
      in  => '[% v %]',
      out => '&lt;&gt;&amp;&quot;',
      sections => [ { nolang => '[% v %]' } ],
    },
    {
      var => { v =>  { w => '<>&"' }},
      in  => '[% v.w %]',
      out => '&lt;&gt;&amp;&quot;',
      sections => [ { nolang => '[% v.w %]' } ],
    },
    {
      var => { v => '<>&"' },
      raw => 1,
      in  => '[% v %]',
      out => '<>&"',
      sections => [ { nolang => '[% v %]' } ],
    },
    {
      var => { v => '<">' },
      in  => '[% v | form_unescape %]',
      out => '&lt;"&gt;',
      sections => [ { nolang => '[% v | form_unescape %]' } ],
    },
    {
      var => { v => 'foo' },
      in  => "bar\n  [% v %]  \nbaz",
      out => "bar foo baz",
      sections => [ { nolang => "bar\n  [% v %]  \nbaz" } ],
    },
);
use Test::More;
plan tests => 3 * (@templates + @html_templates) + 13;

require_ok('Act::Template');
my $template = Act::Template->new;
ok($template);

# cached templates
my $t2 = Act::Template->new;
is($template, $t2, 'using cached template');
my $t3 = Act::Template->new(AUTOCLEAR => 0);
isnt($template, $t3, 'new options means new template');
$t2 = Act::Template->new(AUTOCLEAR => 0);
is($t2, $t3, 'using cached template');

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
    is_deeply($template->{PARSER}->sections, $t->{sections});
}

__END__
