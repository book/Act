package Act::Handler::User::Photo;

use strict;
use 'Act::Handler';

use Digest::MD5 qw(md5_hex);
use File::Spec::Functions qw(catfile);
use Imager;

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Util;

sub handler
{
    my $error;
    if (   $Request{args}{update}
        && $Request{args}{photo}
        && $Request{r}->upload()
        && defined(my $fh = $Request{r}->upload()->fh()))
    {
        # read uploaded picture
        my $img = Imager->new();
        if ($img->read(fh => $fh)) {

            # check image format
            my $format = $img->tags(name => 'i_format');
            if ($Act::Config::Image_formats{$format}) {

                # see if image needs to be resized
                my ($w, $h) = map $img->$_, qw(getwidth getheight);
                my ($wmax, $hmax) = split /\D+/, $Config->general_max_imgsize;
                if ($w > $wmax || $h > $hmax) {
                    # image needs resizing
                    if ($w / $h > $wmax / $hmax) {
                        $img = $img->scale(xpixels => $wmax);
                    }
                    else {
                        $img = $img->scale(ypixels => $hmax);
                    }
                }

                # delete previous photo
                _delete_photo();

                # compute MD5
                my $data;
                $img->write(data => \$data, type => $format)
                    or die $img->errstr;
                my $digest = md5_hex($data);

                # store picture
                my $filename = $digest . $Act::Config::Image_formats{$format};
                my $pathname = catfile($Request{r}->document_root,
                                       $Config->general_dir_photos,
                                       $filename);
                $img->write(file => $pathname, type => $format)
                    or die $img->errstr;

                # update database
                $Request{user}->update(photo_name => $filename);
            }
            else {          # unsupported image format
                ++$error;
            }
        }
        else {      # image can't be read
            ++$error;
        }
    }
    elsif ($Request{args}{delete}) {
        _delete_photo();
        $Request{user}->update(photo_name => undef);
    }

    # display form
    my $template = Act::Template::HTML->new();
    $template->variables(
      error      => $error,
      formats    => [ sort keys %Act::Config::Image_formats ],
      photo_uri  => join('/',
                        undef,
                        $Config->general_dir_photos,
                        $Request{user}{photo_name}
                    ),
    );
    $template->process('user/photo');
    return;
}

sub _delete_photo()
{
    unlink catfile($Request{r}->document_root,
                   $Config->general_dir_photos,
                   $Request{user}{photo_name})
        if $Request{user}{photo_name};
}

1;
__END__

=head1 NAME

Act::Handler::User::Photo - upload or delete a user's photo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
