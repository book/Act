package Act::Flickr;
use strict;

use Act::Config;
use Flickr::API;
use List::Util qw(shuffle);

my %Sizes = (
    smallsquare   => 's',   # small square 75x75
    thumbnail     => 't',   # thumbnail, 100 on longest side
    small         => 'm',   # small, 240 on longest side
    medium        => '',    # medium, 500 on longest side
);

sub fetch
{
    return [] unless $Config->flickr_apikey
                  && $Config->flickr_tags;

    my $limit = shift;

    # search for photos on Flickr
    my $api = Flickr::API->new({ key => $Config->flickr_apikey });
    my $page = 0;
    my (@allphotos, @photos);
    do {
        ++$page;
        my $response = $api->execute_method('flickr.photos.search',
                                            { tags      => $Config->flickr_tags,
                                              per_page  => 50,
                                              page      => $page,
                                            });
        unless ($response->{success}) {
            warn "can't fetch photos from Flickr: $response->{error_message}\n";
            return [];
        }
        @photos = grep { $_->{name} eq 'photo' }
                  @{ $response->{tree}{children}[1]{children} };

        # urls to the photo owner's flickr page,
        # the photo flickr page,
        # and the photo itself in various sizes
        # see http://www.flickr.com/services/api/misc.urls.html
        for my $photo (@photos) {
            my $a = $photo->{attributes};
            my $wname = sprintf "http://www.flickr.com/photos/%s/",
                        $a->{owner};
            my $iname = sprintf "http://farm%s.static.flickr.com/%s/%s_%s",
                        $a->{farm}, $a->{server}, $a->{id}, $a->{secret};
            push @allphotos, {
                owner_page => $wname,
                photo_page => $wname . $a->{id},
                map { $_ => $iname . ( $Sizes{$_} ? "_$Sizes{$_}" : '') . '.jpg' }
                keys %Sizes
            };
        }
        
    } while (@photos);

    # return shuffled list
    @allphotos = shuffle @allphotos;
    $#allphotos = $limit - 1 if $limit > 0 && $limit < @allphotos;
    return \@allphotos;
}


1;
__END__

=head1 NAME

Act::Flickr - fetch photos from Flickr

=head1 SYNOPSIS

    use Act::Flickr;
    my $photos = Act::Flickr::fetch();
    my $photos = Act::Flickr::fetch(42);

=cut
