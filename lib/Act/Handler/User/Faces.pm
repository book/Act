package Act::Handler::User::Faces;
use strict;
use parent 'Act::Handler';

use Act::Config;
use Act::Template::HTML;
use Act::User;


sub handler {
    # fetch arguments
    my $limit  = $Config->general_searchlimit;
    my $offset = $Request{args}{prev} ? $Request{args}{oprev}
               : $Request{args}{next} ? $Request{args}{onext}
               : undef;

    # search users
    $Request{args} ||= { name => "*" };
    my $users = Act::User->get_users(
        %{$Request{args}},
        $Request{conference} ? ( conf_id => $Request{conference} ) : (),
        limit => $limit + 1,
        offset => $offset,
    );

    # offsets for potential previous/next pages
    my ($oprev, $onext);
    $oprev = $offset - $limit if $offset;
    if (@$users > $limit) {
       pop @$users;
       $onext = $offset + $limit;
    }

    # process the search template
    my $template = Act::Template::HTML->new;
    $template->variables(
        users       => $users,
        oprev       => $oprev,
        prev        => defined($oprev),     # $oprev can be zero
        onext       => $onext,
        next        => defined($onext),     # $onext can be zero
    );

    $template->process("user/faces");
    return;
}

1;

=head1 NAME

Act::Handler::User::Faces - Show the photo of committed attendees

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
