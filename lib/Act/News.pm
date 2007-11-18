package Act::News;
use strict;
use Act::Config;
use Act::Object;
use base qw( Act::Object );

use constant DEBUG => !$^C && $Config->database_debug;

# class data used by Act::Object
our $table       = 'news';
our $primary_key = 'news_id';

our %sql_stub    = (
    select => "n.*",
    from   => "news n",
);
our %sql_mapping = (
    # standard stuff
    map( { ($_, "(n.$_=?)") }
         qw( news_id conf_id user_id datetime published ) )
);
our %sql_opts    = ( 'order by' => 'datetime desc' );

sub title { $_[0]{title} }
sub text  { $_[0]{text}  }

sub items
{
    my $self = shift;
    return $self->{items} if exists $self->{items};

    # fill the cache if necessary
    my $sql = "SELECT lang, title, text FROM news_items WHERE news_id = ?";
    Act::Object::_sql_debug($sql, $self->news_id) if DEBUG;
    my $sth = $Request{dbh}->prepare_cached($sql);
    $sth->execute($self->news_id);

    $self->{items} = {};
    while( my ($lang, $title, $text) = $sth->fetchrow_array() ) {
        $self->{items}{$lang} = { title => $title, text => $text };
    }
    $sth->finish();
    return $self->{items};
}

sub content {
    my $self = shift;
    my $text = ref $self ? $self->text : shift;
    join( "\n", map "<p>$_</p>", split /(?:\r?\n){2,}/, $text)
}

sub create {
    my ($class, %args) = @_;
    $class = ref $class || $class;
    $class->init();

    my $items = delete $args{items};
    my $news = $class->SUPER::create(%args);
    
    if ($news && $items) {
        $news->_update_items($items);
    }
    $Request{dbh}->commit;
    return $news;
}
sub update {
    my ($self, %args) = @_;
    my $items = delete $args{items};
    
    $self->SUPER::update(%args) if %args;
    $self->_update_items($items);
    $Request{dbh}->commit;
}
sub delete {
    my ($self, %args) = @_;

    $self->_update_items( {} );
    $self->SUPER::delete(%args);
    $Request{dbh}->commit;
}
sub _update_items
{
    my ($self, $items) = @_;

    my $SQL = 'DELETE FROM news_items WHERE news_id=?';
    Act::Object::_sql_debug($SQL, $self->news_id) if DEBUG;
    my $sth = $Request{dbh}->prepare_cached($SQL);
    $sth->execute($self->news_id);

    $SQL = 'INSERT INTO news_items ( title, text, news_id, lang ) VALUES (?, ?, ?, ?)';
    $sth = $Request{dbh}->prepare_cached($SQL);
    for my $lang (keys %$items) {
        my @v = ( $items->{$lang}{title}, $items->{$lang}{text}, $self->news_id, $lang );
        Act::Object::_sql_debug($SQL, @v) if DEBUG;
        $sth->execute(@v);
    }
}
=head1 NAME

Act::News - An Act object representing a news item.

=head1 DESCRIPTION

This is a standard Act::Object class. See Act::Object for details.

=cut

1;
