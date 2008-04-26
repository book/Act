#!perl -w

use strict;
use utf8;
use Test::MockObject;

use Act::Config;
use Act::I18N;

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
    { # loc()
      in  => '[% loc("country_gb") %]',
      out => 'Royaume-Uni',
      sections => [ { nolang => '[% loc("country_gb") %]' } ],
    },
    { # {{ }}
      in  => '{{country_gb}}',
      out => 'Royaume-Uni',
      sections => [ { nolang => '[% loc("country_gb") %]' } ],
    },
    { # trailing spaces
      in  => '{{ country_gb }}',
      out => 'Royaume-Uni',
      sections => [ { nolang => '[% loc("country_gb") %]' } ],
    },
    { # no trailing spaces
      in  => '{{country_gb}}',
      out => 'Royaume-Uni',
      sections => [ { nolang => '[% loc("country_gb") %]' } ],
    },
    { # in English
      lang => 'en',
      in  => '{{country_gb}}',
      out => 'United Kingdom',
      sections => [ { nolang => '[% loc("country_gb") %]' } ],
    },
    { # mixed with text
      in  => 'foo {{country_gb}} bar',
      out => 'foo Royaume-Uni bar',
      sections => [ { nolang => 'foo [% loc("country_gb") %] bar' } ],
    },
    { # mix localization techniques
      in  => '{{country_gb}}<t><fr>foo</fr></t>',
      out => 'Royaume-Unifoo',
      sections => [ { nolang => '[% loc("country_gb") %]' },
                    {   lang => { fr => 'foo' } },
                  ],
    },
    #### common macros
    { # talk_link
      in   => '[% talk_link(talk) %]',
      conf => 'zz2007',
      web  => 1,
      var  => { talk => { talk_id => 42, title => 'foo', accepted => 0 } },
      out  => '<a href="/zz2007/talk/42">&lrm;foo&lrm;</a>',
      sections => [ { nolang => '[% talk_link(talk) %]' } ],
    },
    { # talk_link accepted
      in   => '[% talk_link(talk) %]',
      conf => 'zz2007',
      web  => 1,
      var  => { talk => { talk_id => 42, title => 'foo', accepted => 1 } },
      out  => '<a href="/zz2007/talk/42"><b>&lrm;foo&lrm;</b></a>',
      sections => [ { nolang => '[% talk_link(talk) %]' } ],
    },
    { # talk_confirmed_link
      in   => '[% talk_confirmed_link(talk) %]',
      conf => 'zz2007',
      web  => 1,
      var  => { talk => { talk_id => 42, title => 'foo', confirmed => 0 } },
      out  => '<a href="/zz2007/talk/42">&lrm;foo&lrm;</a>',
      sections => [ { nolang => '[% talk_confirmed_link(talk) %]' } ],
    },
    { # talk_confirmed_link confirmed
      in   => '[% talk_confirmed_link(talk) %]',
      conf => 'zz2007',
      web  => 1,
      var  => { talk => { talk_id => 42, title => 'foo', confirmed => 1 } },
      out  => '<a href="/zz2007/talk/42"><b>&lrm;foo&lrm;</b></a>',
      sections => [ { nolang => '[% talk_confirmed_link(talk) %]' } ],
    },
    { # talk_modify_link
      in   => '[% talk_modify_link(talk) %]',
      conf => 'zz2007',
      web  => 1,
      lang => 'en',
      user => { is_orga => 1 },
      var  => { talk => { talk_id => 42, title => 'foo' } },
      out  => '(<a href="/zz2007/edittalk?talk_id=42">edit</a>)',
      sections => [ { nolang => '[% talk_modify_link(talk) %]' } ],
    },
    { # event_link
      in   => '[% event_link(event) %]',
      conf => 'zz2007',
      web  => 1,
      var  => { event => { event_id => 42, title => 'foo' } },
      out  => '<a href="/zz2007/event/42">&lrm;foo&lrm;</a>',
      sections => [ { nolang => '[% event_link(event) %]' } ],
    },
    { # event_modify_link
      in   => '[% event_modify_link(event) %]',
      conf => 'zz2007',
      web  => 1,
      lang => 'en',
      user => { is_orga => 0 },
      var  => { event => { event_id => 42, title => 'foo' } },
      out  => '',
      sections => [ { nolang => '[% event_modify_link(event) %]' } ],
    },
    { # event_modify_link
      in   => '[% event_modify_link(event) %]',
      conf => 'zz2007',
      web  => 1,
      lang => 'en',
      user => { is_orga => 1 },
      var  => { event => { event_id => 42, title => 'foo' } },
      out  => '(<a href="/zz2007/editevent?event_id=42">edit</a>)',
      sections => [ { nolang => '[% event_modify_link(event) %]' } ],
    },
    { # user_info_base
      in   => '[% user_info_base(user) %]',
      var  => { user => { pseudonymous => 1, nick_name => 'Zorglub' } },
      out  => 'Zorglub',
      sections => [ { nolang => '[% user_info_base(user) %]' } ],
    },
    { # user_info_base
      in   => '[% user_info_base(user) %]',
      var  => { user => { first_name => 'John', last_name => 'Doe', nick_name => 'Zorglub' } },
      out  => 'John Doe (&lrm;Zorglub&lrm;)',
      sections => [ { nolang => '[% user_info_base(user) %]' } ],
    },
    { # user_info_base
      in   => '[% user_info_base(user) %]',
      var  => { user => { first_name => 'John', last_name => 'Doe' } },
      out  => 'John Doe',
      sections => [ { nolang => '[% user_info_base(user) %]' } ],
    },
    { # user_info
      in   => '[% user_info(user) %]',
      conf => 'zz2007',
      web  => 1,
      var  => { user => { first_name => 'John', last_name => 'Doe', user_id => 42 } },
      out  => '<a href="/zz2007/user/42">John Doe</a>',
      sections => [ { nolang => '[% user_info(user) %]' } ],
    },
    { # expand
      in   => '[% expand(chunks) %]',
      conf => 'zz2007',
      web  =>  1,
      var  => { chunks => [
                    { text => 'foo ' },
                    { talk => { talk_id => 42, title => 'bar' },
                      user => { first_name => 'John',  last_name => 'Doe', user_id => 27 } },
                    { text => ' baz '},
                    { user => { first_name => 'Edgar', last_name => 'Poe', user_id => 59 } },
                ],
              },
      out => join('',
                  'foo',
                  ' <a href="/zz2007/user/27">John Doe</a>',
                  ' - ',
                  '<a href="/zz2007/talk/42">&lrm;bar&lrm;</a>',
                  ' baz ',
                  '<a href="/zz2007/user/59">Edgar Poe</a>',
                 ),
      sections => [ { nolang => '[% expand(chunks) %]' } ],
    },
);
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
    { conf => 'zz2007',
      web  => 1,
      in   => "[% make_uri('foo', 'q', '1', 'r', '2') %]",
      out  => '/zz2007/foo?q=1&amp;r=2',
      sections => [ { nolang => "[% make_uri('foo', 'q', '1', 'r', '2') %]" } ],
    },
    { conf => 'zz2007',
      web  => 1,
      in   => '[% make_uri("foo", "q", "césâr") %]',
      out  => '/zz2007/foo?q=c%C3%A9s%C3%A2r',
      sections => [ { nolang => '[% make_uri("foo", "q", "césâr") %]' } ],
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
    $Request{loc} = Act::I18N->get_handle($Request{language});
    $Config->set(general_default_language => $Request{language});
    $Config->set(languages => {});

    $Request{conference} = $t->{conf};
    $Config->set(uri => $t->{conf});
    $Config->set(name => { $Request{language} => 'foobar' });
    if ($t->{config}) {
        $Config->set($_ => $t->{config}{$_}) for keys %{ $t->{config} };
    }
    if ($t->{user}) {
        $Request{user} = { %{ $t->{user} } };
    }
    if ($t->{web}) {
        $Request{r} = Test::MockObject->new;
        $Request{r}->set_true(qw(send_http_header))
                   ->set_always(method => 'GET')
                   ->set_isa('Apache');
        $Request{args} = {};
    }
    else {
        $Request{r} = undef;
    }

    my $output;
    ok($template->process(\$t->{in}, \$output));
    is($output, $t->{out});
    is_deeply($template->{PARSER}->sections, $t->{sections});
}

__END__
