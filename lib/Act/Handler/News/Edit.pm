use strict;
package Act::Handler::News::Edit;

use Apache::Constants qw(NOT_FOUND);

use Act::Config;
use Act::Form;
use Act::News;
use Act::Template::HTML;
use Act::Util;

my $form = Act::Form->new(
  required => [qw(title text)],
  optional => [qw(published)],
  filters  => {
     published => sub { $_[0] ? 1 : 0 },
  },
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
        my $fields = $form->{fields};
        if ($ok) {
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
