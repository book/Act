use strict;
package Act::Handler::Talk::Util;

use Act::Config;
use Act::Email;
use Act::Template;
use Act::User;

# optional email notification when a talk is inserted or updated
sub notify
{
    if ($Config->talks_submissions_notify_address) {
        my ($op, $tbefore, $talk) = @_;
        if ($op eq 'insert') {
            $talk = $tbefore;
            undef $tbefore;
        }
        # user giving this talk
        my $user = Act::User->new(user_id => $talk->user_id);

        # diff with previous version if update
        my @diff;
        @diff = grep { $tbefore->$_ ne $talk->$_ } keys %$talk
            if $tbefore;

        # determine which language to send the notification in
        local $Request{language} = $Config->talks_submissions_notify_language
                                || $Request{language}
                                || $Config->general_default_language;

        # generate subject and body from templates
        my $template = Act::Template->new;
        my %output;
        for my $slot (qw(subject body)) {
            $template->variables(
                op   => $op,
                talk => $talk,
                user => $user,
            );
            $template->variables(
                diff => \@diff,
                tbefore => $tbefore,
            ) if $tbefore;

            $template->process("talk/notify_$slot", \$output{$slot});
        }
        # send the notification email
        Act::Email::send(
            from    => $Config->talks_submissions_notify_address,
            to      => $Config->talks_submissions_notify_address,
            %output,
        );
    }
}

1;

__END__

=head1 NAME

Act::Handler::Talk::Util - Talk utility routines

=head1 SYNOPSIS

  [talks]
  submissions_notify_address = address@domain
  submissions_notify_language = fr

  notify(insert => $talk);
  notify(update => $talk);

=head1 DESCRIPTION

=over 4

=item notify

Notifies the conference committee when a talk has been inserted or
updated.

=back

=cut
