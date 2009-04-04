package Act::Abstract;
use strict;
use Act::Config;
use Act::Handler::News::Fetch;
use Act::Talk;
use Act::User;

# turn talk:id / user:id into real talks/users
sub chunked {
    my $i = 0;
    return [
        map {
            my $t = { };
            if ( $i++ % 2 ) {
                my ($what, $id) = split ':';
                if ($what eq 'talk') {
                    my ($talk, $user) = expand_talk($id);
                    if ($talk) {
                        $t->{talk} = $talk;
                        $t->{user} = $user;
                    }
                    else {
                        $t->{text} = "talk:$id"; # non-existent talk
                    }
                }
                elsif ($what eq 'user') {
                    my $user = expand_user($id);
                    if ($user) {
                        $t->{user} = $user;
                    }
                    else {                  # non-existent user
                        $t->{text} = "user:$id";
                    }
                }
                else { $t->{text} = $_ }
            }
            else { $t->{text} = $_ }
            $t;
          } split /((?:talk|user):\d+)/,
        $_[0]
    ];
}

sub expand_talk
{
    my $id = shift;
    my $talk = Act::Talk->new(
        talk_id => $id,
        conf_id => $Request{conference}
    );
    my $user;
    if ($talk) {
        $user = Act::User->new(
            user_id => $talk->user_id,
            conf_id => $Request{conference},
        );
    }
    return ($talk, $user);
}

sub expand_user
{
    my $user_info = shift or return;
    my $user;
    my %args;
    if ($user_info =~ /^\d+/) {
        %args = (user_id => $user_info);
    }
    else {
        my @id = split /\s+/, $user_info, 2;
        if (@id == 2) {
            %args = (first_name => $id[0], last_name => $id[1]);
        }
        else {
            %args = (nick_name => $user_info);
        }
    }
    return Act::User->new(%args, conf_id => $Request{conference});
}
sub expand_news
{
    my $news_id = shift;
    my $news;
    if ($news_id && $news_id =~ /^\d+$/) {
        $news = Act::Handler::News::Fetch::fetch(1, $news_id);
        $news = $news->[0] if @$news;
    }
    return $news;
}
1;

__END__

=head1 NAME

Act::Abstract - event/talk abstract utilities

=head1 SYNOPSIS

    use Act::Abstract;
    my $chunked = Act::Abstract::chunked($talk->abstract);
    my ($talk, $user) = Act::Abstract::expand_talk(42);
    my $user = Act::Abstract:expand_user(42);

=cut
