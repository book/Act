package Act::Handler::User::Photo;

use strict;
use File::Spec::Functions qw(catfile);

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    if (   $Request{args}{update}
        && $Request{args}{photo}
        && $Request{r}->upload()
        && defined(my $fh = $Request{r}->upload()->fh()))
    {
        # delete previous photo
        _delete_photo();

        # store uploaded picture
        my $filename = $Request{user}{user_id};
        if (my ($extension) = ($Request{args}{photo} =~ /^.*(\.[^.]+)$/)) {
            $filename .= $extension;
        }
        my $pathname = catfile($Request{r}->document_root,
                               $Config->general_dir_photos,
                               $filename);

        open my $gh, ">$pathname" or die "open $pathname $!";
        binmode $gh;
        while (read($fh, my $buffer, 1024)) {
            print $gh $buffer;
        }
        close $gh;

        # update database
        $Request{user}->update(photo_name => $filename);
    }
    elsif ($Request{args}{delete}) {
        _delete_photo();
        $Request{user}->update(photo_name => undef);
    }

    # display form
    my $template = Act::Template::HTML->new();
    $template->variables(
      photo_uri  => join('/',
                        undef,
                        $Config->general_dir_photos,
                        $Request{user}{photo_name}
                    ),
    );
    $template->process('user/photo');
}

sub _delete_photo()
{
    unlink catfile($Request{r}->document_root,
                   $Config->general_dir_photos,
                   $Request{user}{photo_name});
}

1;
__END__

=head1 NAME

Act::Handler::User::Photo - upload or delete a user's photo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
