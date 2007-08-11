use strict;
package Act::Handler::News::Edit;

use Apache::Constants qw(NOT_FOUND);
use DateTime::Format::Pg;

use Act::Config;
use Act::Form;
use Act::News;
use Act::Template::HTML;
use Act::Util;

my %form_params = (
  common_required => [qw(title text)],
  common_optional => [qw(published delete)],
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
        # convert datetime to conference timezone
        my $dt = $news->datetime->clone();
        $dt->set_time_zone('UTC');
        $dt->set_time_zone($Config->general_timezone);
        $news->{date} = $dt->ymd;
        $news->{time} = $dt->strftime('%H:%M');
    }

    # form has been submitted
    if ($Request{args}{submit}) {
        # validate form fields
        $form_params{required} = [ @{ $form_params{common_required} } ];
        $form_params{optional} = [ @{ $form_params{common_optional} } ];
        if ($news) {
            push @{ $form_params{required} }, qw(date time);
        }
        else {
            push @{ $form_params{optional} }, qw(date time);
        }
        my $form = Act::Form->new(%form_params);
        my @errors;
        my $ok = $form->validate($Request{args});
        my $fields = $form->{fields};
        if ($ok) {
            # convert to UTC datetime
            if (    defined $news
                 && !$form->{invalid}{date}
                 && !$form->{invalid}{time} )
            {
                $fields->{datetime} = DateTime::Format::Pg->parse_timestamp("$fields->{date} $fields->{time}:00");
                $fields->{datetime}->set_time_zone($Config->general_timezone);
                $fields->{datetime}->set_time_zone('UTC');
            }
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
    # display the news item submission form
    $template->variables( defined $news ? %$news :  %$fields );
    $template->process('news/edit');
}

1;
__END__

=head1 NAME

Act::Handler::News::Edit - edit a news item

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
