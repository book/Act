package Act::Plugin::News;
use Template::Plugin;
use base qw( Template::Plugin );
use Act::Config;
use Act::News;

sub items {
    my ( undef, $n ) = @_;
    Act::News->get_news( conf_id => $Request{conference}, limit => $n );
}

1;

__END__

=head1 NAME

Act::Plugin::News - A conference news plugin

=head1 SYNOPSIS

    [% USE News %]
    <dl>
    <!-- list only the last 3 news items -->
    [% FOREACH item = News.items(3) %]
    <dt>[% item.date %]</dt>
    <dd>[% item.text %]</dd>
    [% END %]
    </dl>

=head1 DESCRIPTION

The Act::Plugin::News plugin is used to access the C<news> table of
the Act database.

=head2 Methods

Act::Plugin::News defines the following method:

=over 4

=item items(I<count>)

This method returns I<count> news items to include in your templates.
The news item are relative to the current conference and language.

All news items are returned if items() is called without argument.

=back

=cut

