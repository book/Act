use strict;
package Act::Handler::News::Edit;

use Apache::Constants qw(NOT_FOUND);
use DateTime;
use DateTime::Format::Pg;

use Act::Config;
use Act::Form;
use Act::I18N;
use Act::News;
use Act::Template::HTML;
use Act::Util;

my %form_params = (
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
    if ($Request{args}{preview} || $Request{args}{save}) {
        # validate form fields
        my $form = Act::Form->new(
                    %form_params,
                    required => [ qw(date time),
                                  map { ("title_$_", "text_$_") } keys %{ $Config->languages } ],
        );
        my @errors;
        my $ok = $form->validate($Request{args});
        $fields = $form->{fields};

        # extract items
        my %items = map { $_ => { title => delete $fields->{"title_$_" },
                                  text  => delete $fields->{"text_$_"  },
                                }
                        } keys %{ $Config->languages };

        if ($ok) {
            $fields->{datetime} = DateTime::Format::Pg->parse_timestamp("$fields->{date} $fields->{time}:00");
            if ($Request{args}{preview}) {
                my %preview;
                for my $lang (keys %{ $Config->languages }) {
                    local $Request{language} = $lang;
                    local $Request{loc} = Act::I18N->get_handle($Request{language});
                    $template->variables(
                        %$fields,
                        title => $items{$lang}{title},
                    );
                    $template->variables_raw(
                        content => Act::News->content($items{$lang}{text}),
                    );
                    $preview{$lang} = '';
                    $template->process('news/item', \$preview{$lang});
                }
                $template->variables_raw(preview => \%preview);
            }
            else {
                # convert to UTC datetime
                $fields->{datetime}->set_time_zone($Config->general_timezone);
                $fields->{datetime}->set_time_zone('UTC');
    
                # update existing item
                if (defined $news) { 
                    if ($fields->{delete}) {
                        $news->delete( items => \%items );
                    }
                    else {
                        $news->update( %$fields, items => \%items );
                    }
                }
                # insert new item
                else {
                    $news = Act::News->create(
                        %$fields,
                        conf_id   => $Request{conference},
                        user_id   => $Request{user}->user_id,
                        items     => \%items,
                    );
                }
                # redirect to news admin
                return Act::Util::redirect(make_uri('newsadmin'));
            }
        }
        else {
            # map errors
            grep($form->{invalid}{"title_$_"}, keys %{ $Config->languages }) && push @errors, 'ERR_TITLE';
            grep($form->{invalid}{"text_$_"},  keys %{ $Config->languages }) && push @errors, 'ERR_TEXT';
            $form->{invalid}{date}  && push @errors, 'ERR_DATE';
            $form->{invalid}{time}  && push @errors, 'ERR_TIME';
            $template->variables(errors => \@errors);
        }
        $fields->{items} = \%items;
    }
    # initial form display
    else {
        if (exists $Request{args}{news_id}) {
            $fields = { %$news };
            $fields->{items} = $news->items;
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
