package Act;

our $VERSION = '1.00';

1;

__END__

=head1 NAME

Act - A conference toolkit

=head1 DESCRIPTION

Act is a tool designed to relieve conference organisers from the burden
of creating, setting up and managing their conference's website.

Act defines a set of handlers for the various operations needed to
organise a successful conference:

=over 4

=item *

user creation and registration,

=item *

talk submission by the attendees,

=item *

talk management by the organisers,

=item *

event management and schedule display,

=item *

statistics,

=item *

online payment (with a set of payment plug-ins) and receipts,

=item *

different roles for the organisers, giving access to specialised handlers
(especially for the treasurer)

=back

The Act framework supports multiple conferences:

=over 4

=item *

Once a user has created his account, he can connect to all conferences
managed by the same Act instance.

=item *

the database contains global profile information, as well as per-conference
data, which can be used for statistics, and organisers' tool

=back

=head1 ORIGIN

The name Act come from the rallying cry of all conference organisers: I<Act!>
Organising a conference is mostly about motivating people and working hard
toward an exciting goal. It is also a reminder to the organisers: no matter
how tempted they may be to code their own little conference webapp, the
little time they have is going to be better invested if they use it to
I<actually organise> their conference. C<;-)>

The acronym also make a reference to APL (I<A Programming Langage>): just
as APL was created at a time when there were not many programming languages,
Act was created at a time when there were not many conference tools. C<:-)>

Act is sometimes B<erroneously> spelled "ACT".

=head1 HISTORY OF THE SOFTWARE

In 2003, when the French Perl Mong(u)e(u)rs began organising their
YAPC::Europe in Paris, they thought about the web site and what they
wanted to do with it. Starting from Sylvain Lhullier's prototype,
Éric Cholet and Philippe Bruhat created a conference web site that
was multilingual, template-driven, and able to manage the users, talks,
schedule and payment.

The year after, when preparing the first French Perl Workshop, Éric
and Philippe worked on a second system, designed from the beginning to
support everything the old site could do, with one difference: it had to
support multiple conferences. Act (A Conference Toolkit) was born. They
wanted to support several French Workshops without having to recode a
conference web site engine every year. Laziness is a lot of work... C<:-)>

The YAPC Europe Foundation was created just after YAPC Europe in Paris,
to help and support the organisation of Perl conferences in Europe. Since
YEF and Act are hosted on the French mongers system, it was only natural
that Act became a part of the service provided by YEF.

During the summer of 2006, it was decided to finally publish the software
on CPAN. The main reasons were:

=over 4

=item *

it's not really useful to prevent conference organisers to a least peek
at the code if they really feel the need to,

=item *

a hosted Act system is desirable (for centralising all the conference
information), but it's easier to move data from a non-hosted conference
site that uses Act, than from one using a specific system

=item *

it will increase visibility and acceptance.

=back

Act currently supports 6 languages: English, French, Italian, Portuguese,
German and Hungarian. With the planned port to UTF-8, a version in Hebrew is
expected.

=head1 COPYRIGHT

Copyright 2004-2006 Philippe "BooK" Bruhat and Éric Cholet.
All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

