use strict;
package Act::Database;
  
my @SCHEMA_UPDATES = (
#1
  "create table schema (
     current_version integer NOT NULL
   );
   insert into schema values (1);
  ",
#2
  "alter table orders add column price text;
   alter table orders add column type text;
  ",
#3
  "alter table users rename civility to salutation;
  ",
#4
  "alter table twostep add column data text;
  ",
#5,
  "alter table talks add column lang text;
  ",
#6,
  "create table tags (
    tag_id        serial not null primary key,
    conf_id       text not null,
    tag           text not null,
    type          text not null,
    tagged_id     text not null
   );
  ",
#7,
  "create table news_items (
    news_item_id    serial  not null primary key,
    news_id         integer not null,
    lang            text    not null,
    title           text    not null,
    text            text    not null,

    unique (news_id, lang),
    foreign key( news_id  ) references news( news_id )
   );
   insert into news_items (news_id, lang, title, text) select news_id, lang, title, text from news;
   alter table news drop column lang;
   alter table news drop column title;
   alter table news drop column text;
  ",
#8,
  "create table order_items (
    item_id    serial    not null    primary key,
    order_id   integer   not null,
    amount     integer   not null,
    name       text,
    registration boolean not null,

    foreign key( order_id  ) references orders( order_id )
   );
   insert into order_items (order_id, amount, name, registration)
     select order_id, amount, price, true from orders order by order_id;
   alter table orders drop column amount;
   alter table orders drop column price;
  ",
#9,
  "create table user_talks (
    user_id     integer not null,
    conf_id     text not null,
    talk_id     integer not null,
    foreign key( user_id  ) references users( user_id ),
    foreign key( talk_id  ) references talks( talk_id )
   );
   create index user_talks_idx on user_talks ( user_id, conf_id, talk_id );
  ",
);

# returns ( current database schema version, required version )
sub get_versions
{
    my $dbh = shift;
    my $version;
    eval {
        $version = $dbh->selectrow_array('SELECT current_version FROM schema');
    };
    if ($@) {
        $dbh->rollback;
    }
    $version ||= 0;
    return ( $version, required_version() );
}

sub required_version { scalar @SCHEMA_UPDATES }

sub get_update
{
    return $SCHEMA_UPDATES[ $_[0] - 1 ];
}

1;
__END__

=head1 NAME

Act::Database - database schema change tracking

=head1 SYNOPSIS

    my ($version, $required) = Act::Database::get_versions($dbh);
    my $required = Act::Database::required_version();
    my $statements = Act::Database->get_update($version);

=head1 DESCRIPTION

Act::Database implements tracking of schema changes.
When committing code that requires a database schemas change,
developers should add a new element to C<@SCHEMA_UPDATES>
with the SQL statements required to update the schema from
the previous version.

=over 4

=item get_versions(I<$dbh>)

Returns the current database schema version, and the version expected
by this code.

=item required_version()

Returns the database schema version expected by this code.

=item get_update(I<$version>)

Returns an reference to the array of SQL statements necessary to update
the database from version $version - 1 to version $version.

=back

=cut
