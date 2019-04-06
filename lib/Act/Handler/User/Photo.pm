package Act::Handler::User::Photo;

use strict;
use parent 'Act::Handler';

use Digest::MD5 qw(md5_hex);
use File::Spec::Functions qw(catfile);
use Imager;

use Act::Config;
use Act::Template::HTML;
use Act::User;
use Act::Util;
use Try::Tiny;

sub _photo_dir_path {
    if ($Config->general_dir_photos =~ /^\//) {
        return $Config->general_dir_photos;
    }
    return catfile($Config->root, $Config->general_dir_photos);
}

sub _resize_photo {
    my $img = shift;
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
}

sub _read_photo {
    my $file = shift;
    my $img = Imager->new();
    return $img if $img->read(file => $file);
    die "Unable to read photo";
}

sub _assert_format {
    my $img = shift;
    my $format = $img->tags(name => 'i_format');
    if (!exists $Act::Config::Image_formats{$format}) {
        die "Image format not supported";
    }
    return $format;
}

sub _get_digest {
    my ($img, $format) = @_;
    my $data;
    $img->write(data => \$data, type => $format) or die $img->errstr;
    return md5_hex($data);
}

sub _store_img {
    my ($img, $filename, $format) = @_;
    my $pathname = catfile(_photo_dir_path(), $filename);
    $img->write(file => $pathname, type => $format) or die $img->errstr;
    return $filename;
}

sub _upload_photo {
    my $upload = shift;

    my $img    = _read_photo($upload->tempname);
    my $format = _assert_format($img);

    _resize_photo($img);

    my $digest = _get_digest($img, $format);
    my $filename = $digest . $Act::Config::Image_formats{$format};
    my $filename = _store_img($img, $filename, $format);

    _delete_photo();

    $Request{user}->update(photo_name => $filename);
}

sub handler {

    my $error;
    my $request = $Request{r};
    my $params = $request->body_parameters;
    if ($params->{update}) {
        try {
            if (my $uploads = $request->uploads) {
                die "Multiple uploads found!\n" if keys %$uploads != 1;
                my ($upload) = values %$uploads;
                _upload_photo($upload);
            }
            else {
                die "No uploads found!\n";
            }
        }
        catch {
            $error = $_;
        };
    }
    elsif ($params->{delete}) {
        delete_photo();
        $Request{user}->update(photo_name => undef);
    }

    # display form
    my $template = Act::Template::HTML->new();
    $template->variables(
        error     => $error,
        formats   => [sort keys %Act::Config::Image_formats],
        photo_uri => join ('/', undef, $Request{user}{photo_name}),
    );
    $template->process('user/photo');
    return;

}

sub _delete_photo() {
    my $filename = $Request{user}{photo_name};
    return if !defined $filename or !length $filename;
    my $pathname = catfile(_photo_dir_path(), $filename);
    unlink $pathname;
}

1;
__END__

=head1 NAME

Act::Handler::User::Photo - upload or delete a user's photo

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
