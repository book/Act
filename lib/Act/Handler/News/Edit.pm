use strict;
package Act::Handler::News::Edit;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use DateTime::Format::Pg;

use Act::Config;
use Act::Form;
use Act::News;
use Act::Template::HTML;
use Act::Util;

my $form = Act::Form->new(
  required => [qw(title text date time)],
  optional => [qw(news_id published delete)],
  filters  => {
     published => sub { $_[0] ? 1 : 0 },
  },
  constraints => {
    date => 'date',
    time => 'time',
  }
);

sub handler
{
    # orgas only
    unless ($Request{user}->is_orga) {
        $Request{status} = NOT_FOUND;
        return;
    }
    my $template = Act::Template::HTML->new();

    # read news item
    my ($news, $fields);
    if (exists $Request{args}{news_id}) {
        $news = Act::News->new(
            news_id => $Request{args}{news_id},
            conf_id => $Request{conference},
        );
        unless ($news) {
            # cannot edit non-existent item
            $Request{status} = NOT_FOUND;
            return;
        }
    }

    # form has been submitted
    if ($Request{args}{submit}) {
        # validate form fields
        my @errors;
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};
        if ($ok) {
            # convert to UTC datetime
            $fields->{datetime} = DateTime::Format::Pg->parse_timestamp("$fields->{date} $fields->{time}:00");
            $fields->{datetime}->set_time_zone($Config->general_timezone);
            $fields->{datetime}->set_time_zone('UTC');

            # update existing item
            if (defined $news) { 
                if ($fields->{delete}) {
                    $news->delete;
                }
                else {
                    $news->update( %$fields );
                }
            }
            # insert new item
            else {
                $news = Act::News->create(
                    %$fields,
                    conf_id   => $Request{conference},
                    lang      => $Request{language},
                    user_id   => $Request{user}->user_id,
                );
            }
            # redirect to news admin
            return Act::Util::redirect(make_uri('newsadmin'));
        }
        else {
            # map errors
            $form->{invalid}{title} && push @errors, 'ERR_TITLE';
            $form->{invalid}{text}  && push @errors, 'ERR_TEXT';
            $form->{invalid}{date}  && push @errors, 'ERR_DATE';
            $form->{invalid}{time}  && push @errors, 'ERR_TIME';
        }
        $template->variables(errors => \@errors);
    }
    # initial form display
    else {
        if (exists $Request{args}{news_id}) {
            $fields = { %$news };
        }
        else {
            $fields = { datetime => DateTime->now() };
        }
        # convert datetime to conference timezone
        $fields->{datetime}->set_time_zone('UTC');
        $fields->{datetime}->set_time_zone($Config->general_timezone);
        $fields->{date} = $fields->{datetime}->ymd;
        $fields->{time} = $fields->{datetime}->strftime('%H:%M');
    }
    # display the news item submission form
    $template->variables( %$fields );
    $template->process('news/edit');
}

1;
__END__

=head1 NAME

Act::Handler::News::Edit - edit a news item

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
