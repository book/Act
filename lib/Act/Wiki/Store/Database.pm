package Act::Wiki::Store::Database;

use strict;

use vars qw( $VERSION $timestamp_fmt );
$timestamp_fmt = "%Y-%m-%d %H:%M:%S";

use DBI;
use Time::Piece;
use Time::Seconds;
use Carp qw( carp croak );
use Digest::MD5 qw( md5_hex );

$VERSION = '0.31';
my $SCHEMA_VER = 10;

# first, detect if Encode is available - it's not under 5.6. If we _are_
# under 5.6, give up - we'll just have to hope that nothing explodes. This
# is the current 0.54 behaviour, so that's ok.

my $CAN_USE_ENCODE;
BEGIN {
    eval " use Encode ";
    $CAN_USE_ENCODE = $@ ? 0 : 1;
}

=head1 NAME

Wiki::Toolkit::Store::Database - parent class for database storage backends
for Wiki::Toolkit

=head1 SYNOPSIS

This is probably only useful for Wiki::Toolkit developers.

  # See below for parameter details.
  my $store = Wiki::Toolkit::Store::MySQL->new( %config );

=head1 METHODS

=over 4

=item B<new>

  my $store = Wiki::Toolkit::Store::MySQL->new( dbname  => "wiki",
                        dbuser  => "wiki",
                        dbpass  => "wiki",
                        dbhost  => "db.example.com",
                        dbport  => 1234,
                        charset => "iso-8859-1" );
or

  my $store = Wiki::Toolkit::Store::MySQL->new( dbh => $dbh );

C<charset> is optional, defaults to C<iso-8859-1>, and does nothing
unless you're using perl 5.8 or newer.

If you do not provide an active database handle in C<dbh>, then
C<dbname> is mandatory. C<dbpass>, C<dbuser>, C<dbhost> and C<dbport>
are optional, but you'll want to supply them unless your database's
connection method doesn't require them.

If you do provide C<database> then it must have the following
parameters set; otherwise you should just provide the connection
information and let us create our own handle:

=over 4

=item *

C<RaiseError> = 1

=item *

C<PrintError> = 0

=item *

C<AutoCommit> = 1

=back

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, %args) = @_;

    if ( $args{dbh} ) {
        $self->{_dbh} = $args{dbh};
        $self->{_external_dbh} = 1; # don't disconnect at DESTROY time
        $self->{_charset} = $args{charset} || "iso-8859-1";
    } else {
        die "Must supply a dbname" unless defined $args{dbname};
        $self->{_dbname} = $args{dbname};
        $self->{_dbuser} = $args{dbuser} || "";
        $self->{_dbpass} = $args{dbpass} || "";
        $self->{_dbhost} = $args{dbhost} || "";
        $self->{_dbport} = $args{dbport} || "";
        $self->{_charset} = $args{charset} || "iso-8859-1";

        # Connect to database and store the database handle.
        my ($dbname, $dbuser, $dbpass, $dbhost, $dbport) =
                           @$self{qw(_dbname _dbuser _dbpass _dbhost _dbport)};
        my $dsn = $self->_dsn($dbname, $dbhost, $dbport)
            or croak "No data source string provided by class";
        $self->{_dbh} = DBI->connect( $dsn, $dbuser, $dbpass,
                                      $self->_get_dbh_connect_attr )
            or croak "Can't connect to database $dbname using $dsn: "
                   . DBI->errstr;
    }

    my ($cur_ver, $db_ver) = $self->schema_current;
    if ($db_ver < $cur_ver) {
        croak "Database schema version $db_ver is too old (need $cur_ver)";
    } elsif ($db_ver > $cur_ver) {
        croak "Database schema version $db_ver is too new (need $cur_ver)";
    }

    return $self;
}

# Internal method to get attributes for passing to DBI->connect().
# Override in subclasses to add database-dependent attributes.
sub _get_dbh_connect_attr {
    return {
             PrintError => 0,
             RaiseError => 1,
             AutoCommit => 1,
    };
}

# Internal method, used to handle the logic of how to add up return
#  values from pre_ plugins
sub handle_pre_plugin_ret {
    my ($running_total_ref,$result) = @_;

    if(($result && $result == 0) || !$result) {
        # No opinion, no need to change things
    } elsif($result == -1 || $result == 1) {
        # Increase or decrease as requested
        $$running_total_ref += $result;
    } else {
        # Invalid return code
        warn("Pre_ plugin returned invalid accept/deny value of '$result'");
    }
}

=item B<retrieve_node>

  my $content = $store->retrieve_node($node);

  # Or get additional meta-data too.
  my %node = $store->retrieve_node("HomePage");
  print "Current Version: " . $node{version};

  # Maybe we stored some metadata too.
  my $categories = $node{metadata}{category};
  print "Categories: " . join(", ", @$categories);
  print "Postcode: $node{metadata}{postcode}[0]";

  # Or get an earlier version:
  my %node = $store->retrieve_node(name    => "HomePage",
                         version => 2 );
  print $node{content};


In scalar context, returns the current (raw Wiki language) contents of
the specified node. In list context, returns a hash containing the
contents of the node plus additional data:

=over 4

=item B<last_modified>

=item B<version>

=item B<checksum>

=item B<metadata> - a reference to a hash containing any caller-supplied
metadata sent along the last time the node was written

=back

The node parameter is mandatory. The version parameter is optional and
defaults to the newest version. If the node hasn't been created yet,
it is considered to exist but be empty (this behaviour might change).

B<Note> on metadata - each hash value is returned as an array ref,
even if that type of metadata only has one value.

=cut

sub retrieve_node {
    my $self = shift;
    my %args = scalar @_ == 1 ? ( name => $_[0] ) : @_;
    unless($args{'version'}) { $args{'version'} = undef; }

    # Call pre_retrieve on any plugins, in case they want to tweak anything
    my @plugins = @{ $args{plugins} || [ ] };
    foreach my $plugin (@plugins) {
        if ( $plugin->can( "pre_retrieve" ) ) {
            $plugin->pre_retrieve( 
                node     => \$args{'name'},
                version  => \$args{'version'}
            );
        }
    }

    # Note _retrieve_node_data is sensitive to calling context.
    unless(wantarray) {
        # Scalar context, will return just the content
        return $self->_retrieve_node_data( %args );
    }

    my %data = $self->_retrieve_node_data( %args );
    $data{'checksum'} = $self->_checksum(%data);
    return %data;
}

# Returns hash or scalar depending on calling context.
sub _retrieve_node_data {
    my ($self, %args) = @_;
    my %data = $self->_retrieve_node_content( %args );
    unless(wantarray) {
        # Scalar context, return just the content
        return $data{content};
    }

    # If we want additional data then get it.  Note that $data{version}
    # will already have been set by C<_retrieve_node_content>, if it wasn't
    # specified in the call.
    my $dbh = $self->dbh;
    my $sql = "SELECT metadata_type, metadata_value "
         . "FROM node "
         . "INNER JOIN metadata ON (node_id = id) "
         . "WHERE name=? "
         . "AND metadata.version=?";
    my $sth = $dbh->prepare($sql);
    $sth->execute($args{name},$data{version}) or croak $dbh->errstr;

    my %metadata;
    while ( my ($type, $val) = $self->charset_decode( $sth->fetchrow_array ) ) {
        if ( defined $metadata{$type} ) {
            push @{$metadata{$type}}, $val;
        } else {
            $metadata{$type} = [ $val ];
        }
    }
    $data{metadata} = \%metadata;
    return %data;
}

# $store->_retrieve_node_content( name    => $node_name,
#                                 version => $node_version );
# Params: 'name' is compulsory, 'version' is optional and defaults to latest.
# Returns a hash of data for C<retrieve_node> - content, version, last modified
sub _retrieve_node_content {
    my ($self, %args) = @_;
    croak "No valid node name supplied" unless $args{name};
    my $dbh = $self->dbh;
    my $sql;

    my $version_sql_val;
    my $text_source;
    if ( $args{version} ) {
        # Version given - get that version, and the content for that version
        $version_sql_val = $dbh->quote($self->charset_encode($args{version}));
        $text_source = "content";
    } else {
        # No version given, grab latest version (and content for that)
        $version_sql_val = "node.version";
        $text_source = "node";
    }
    $sql = "SELECT "
         . "     $text_source.text, content.version, "
         . "     content.modified, content.moderated, "
         . "     node.moderate "
         . "FROM node "
         . "INNER JOIN content ON (id = node_id) "
         . "WHERE name=" . $dbh->quote($self->charset_encode($args{name}))
         . " AND content.version=" . $version_sql_val;
    #my @results = $self->charset_decode( $dbh->selectrow_array($sql) );
    my @results =                         $dbh->selectrow_array($sql)  ;
    @results = ("", 0, "") unless scalar @results;
    my %data;
    @data{ qw( content version last_modified moderated node_requires_moderation ) } = @results;
    return %data;
}

# Expects a hash as returned by ->retrieve_node - it's actually slightly lax
# in this, in that while ->retrieve_node always wraps up the metadata values in
# (refs to) arrays, this method will accept scalar metadata values too.
sub _checksum {
    my ($self, %node_data) = @_;
    my $string = $node_data{content};
    my %metadata = %{ $node_data{metadata} || {} };
    foreach my $key ( sort keys %metadata ) {
        $string .= "\0\0\0" . $key . "\0\0";
        my $val = $metadata{$key};
        if ( ref $val eq "ARRAY" ) {
            $string .= join("\0", sort @$val );
        } else {
            $string .= $val;
        }
    }
    return md5_hex($self->charset_encode($string));
}

# Expects an array of hashes whose keys and values are scalars.
sub _checksum_hashes {
    my ($self, @hashes) = @_;
    my @strings = "";
    foreach my $hashref ( @hashes ) {
        my %hash = %$hashref;
        my $substring = "";
        foreach my $key ( sort keys %hash ) {
            $substring .= "\0\0" . $key . "\0" . $hash{$key};
        }
        push @strings, $substring;
    }
    my $string = join("\0\0\0", sort @strings);
    return md5_hex($string);
}

=item B<node_exists>

  my $ok = $store->node_exists( "Wombat Defenestration" );

  # or ignore case - optional but recommended
  my $ok = $store->node_exists(
                                name        => "monkey brains",
                                ignore_case => 1,
                              );  

Returns true if the node has ever been created (even if it is
currently empty), and false otherwise.

By default, the case-sensitivity of C<node_exists> depends on your
database.  If you supply a true value to the C<ignore_case> parameter,
then you can be sure of its being case-insensitive.  This is
recommended.

=cut

sub node_exists {
    my $self = shift;
    if ( scalar @_ == 1 ) {
        my $node = shift;
        return $self->_do_old_node_exists( $node );
    } else {
        my %args = @_;
        return $self->_do_old_node_exists( $args{name} )
            unless $args{ignore_case};
        my $sql = $self->_get_node_exists_ignore_case_sql;
        my $sth = $self->dbh->prepare( $sql );
        $sth->execute( $args{name} );
        my $found_name = $sth->fetchrow_array || "";
        $sth->finish;
        return lc($found_name) eq lc($args{name}) ? 1 : 0;
    }
}

sub _do_old_node_exists {
    my ($self, $node) = @_;
    my %data = $self->retrieve_node($node) or return ();
    return $data{version}; # will be 0 if node doesn't exist, >=1 otherwise
}

=item B<verify_checksum>

  my $ok = $store->verify_checksum($node, $checksum);

Sees whether your checksum is current for the given node. Returns true
if so, false if not.

B<NOTE:> Be aware that when called directly and without locking, this
might not be accurate, since there is a small window between the
checking and the returning where the node might be changed, so
B<don't> rely on it for safe commits; use C<write_node> for that. It
can however be useful when previewing edits, for example.

=cut

sub verify_checksum {
    my ($self, $node, $checksum) = @_;
#warn $self;
    my %node_data = $self->_retrieve_node_data( name => $node );
    return ( $checksum eq $self->_checksum( %node_data ) );
}

=item B<list_backlinks>

  # List all nodes that link to the Home Page.
  my @links = $store->list_backlinks( node => "Home Page" );

=cut

sub list_backlinks {
    my ( $self, %args ) = @_;
    my $node = $args{node};
    croak "Must supply a node name" unless $node;
    my $dbh = $self->dbh;
    # XXX see comment in list_dangling_links
    my $sql = "SELECT link_from FROM internal_links INNER JOIN
               node AS node_from ON node_from.name=internal_links.link_from
               WHERE link_to="
            . $dbh->quote($node);
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my @backlinks;
    while ( my ($backlink) = $self->charset_decode( $sth->fetchrow_array ) ) {
        push @backlinks, $backlink;
    }
    return @backlinks;
}

=item B<list_dangling_links>

  # List all nodes that have been linked to from other nodes but don't
  # yet exist.
  my @links = $store->list_dangling_links;

Each node is returned once only, regardless of how many other nodes
link to it.

=cut

sub list_dangling_links {
    my $self = shift;
    my $dbh = $self->dbh;
    # XXX this is really hiding an inconsistency in the database;
    # should really fix the constraints so that this inconsistency
    # cannot be introduced; also rework this table completely so
    # that it uses IDs, not node names (will simplify rename_node too)
    my $sql = "SELECT DISTINCT internal_links.link_to
               FROM internal_links INNER JOIN node AS node_from ON
               node_from.name=internal_links.link_from LEFT JOIN node
               AS node_to ON node_to.name=internal_links.link_to
               WHERE node_to.version IS NULL";
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my @links;
    while ( my ($link) = $self->charset_decode( $sth->fetchrow_array ) ) {
        push @links, $link;
    }
    return @links;
}

=item B<write_node_post_locking>

  $store->write_node_post_locking( node     => $node,
                                   content  => $content,
                                   links_to => \@links_to,
                                   metadata => \%metadata,
                                   requires_moderation => $requires_moderation,
                                   plugins  => \@plugins   )
      or handle_error();

Writes the specified content into the specified node, then calls
C<post_write> on all supplied plugins, with arguments C<node>,
C<version>, C<content>, C<metadata>.

Making sure that locking/unlocking/transactions happen is left up to
you (or your chosen subclass). This method shouldn't really be used
directly as it might overwrite someone else's changes. Croaks on error
but otherwise returns the version number of the update just made.  A
return value of -1 indicates that the change was not applied.  This
may be because the plugins voted against the change, or because the
content and metadata in the proposed new version were identical to the
current version (a "null" change).

Supplying a ref to an array of nodes that this ones links to is
optional, but if you do supply it then this node will be returned when
calling C<list_backlinks> on the nodes in C<@links_to>. B<Note> that
if you don't supply the ref then the store will assume that this node
doesn't link to any others, and update itself accordingly.

The metadata hashref is also optional, as is requires_moderation.

B<Note> on the metadata hashref: Any data in here that you wish to
access directly later must be a key-value pair in which the value is
either a scalar or a reference to an array of scalars.  For example:

  $wiki->write_node( "Calthorpe Arms", "nice pub", $checksum,
                     { category => [ "Pubs", "Bloomsbury" ],
                       postcode => "WC1X 8JR" } );

  # and later

  my @nodes = $wiki->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "Pubs"             );

For more advanced usage (passing data through to registered plugins)
you may if you wish pass key-value pairs in which the value is a
hashref or an array of hashrefs. The data in the hashrefs will not be
stored as metadata; it will be checksummed and the checksum will be
stored instead (as C<__metadatatypename__checksum>). Such data can
I<only> be accessed via plugins.

=cut

sub write_node_post_locking {
    my ($self, %args) = @_;
    my ($node, $content, $links_to_ref, $metadata_ref, $requires_moderation) =
             @args{ qw( node content links_to metadata requires_moderation) };
    my $dbh = $self->dbh;

    my $timestamp = $self->_get_timestamp();
    my @links_to = @{ $links_to_ref || [] }; # default to empty array
    my $version;
    unless($requires_moderation) { $requires_moderation = 0; }

    # Call pre_write on any plugins, in case they want to tweak anything
    my @preplugins = @{ $args{plugins} || [ ] };
    my $write_allowed = 1;
    foreach my $plugin (@preplugins) {
        if ( $plugin->can( "pre_write" ) ) {
            handle_pre_plugin_ret(
                \$write_allowed,
                $plugin->pre_write( 
                    node     => \$node,
                    content  => \$content,
                    metadata => \$metadata_ref )
            );
        }
    }
    if($write_allowed < 1) {
        # The plugins didn't want to allow this action
        return -1;
    }

    if ( $self->_checksum( %args ) eq $args{checksum} ) {
        # Refuse to commit as nothing has changed
        return -1;
    }

    # Either inserting a new page or updating an old one.
    my $sql = "SELECT count(*) FROM node WHERE name=" . $dbh->quote($node);
    my $exists = @{ $dbh->selectcol_arrayref($sql) }[0] || 0;


    # If it doesn't exist, add it right now
    if(! $exists) {
        # Add in a new version
        $version = 1;

        # Handle initial moderation
        my $node_content = $content;
        if($requires_moderation) {
            $node_content = "=== This page has yet to be moderated. ===";
        }

        # Add the node and content
        my $add_sql = 
             "INSERT INTO node "
            ."    (name, version, text, modified, moderate) "
            ."VALUES (?, ?, ?, ?, ?)";
        my $add_sth = $dbh->prepare($add_sql);
        $add_sth->execute(
            map{ $self->charset_encode($_) }
                ($node, $version, $node_content, $timestamp, $requires_moderation)
        ) or croak "Error updating database: " . DBI->errstr;
    }

    # Get the ID of the node we've added / we're about to update
    # Also get the moderation status for it
    $sql = "SELECT id, moderate FROM node WHERE name=" . $dbh->quote($node);
    my ($node_id,$node_requires_moderation) = $dbh->selectrow_array($sql);

    # Only update node if it exists, and moderation isn't enabled on the node
    # Whatever happens, if it exists, generate a new version number
    if($exists) {
        # Get the new version number
        $sql = "SELECT max(content.version) FROM node
                INNER JOIN content ON (id = node_id)
                WHERE name=" . $dbh->quote($node);
        $version = @{ $dbh->selectcol_arrayref($sql) }[0] || 0;
        croak "Can't get version number" unless $version;
        $version++;

        # Update the node only if node doesn't require moderation
        if(!$node_requires_moderation) {
            $sql = "UPDATE node SET version=" . $dbh->quote($version)
             . ", text=" . $dbh->quote($self->charset_encode($content))
             . ", modified=" . $dbh->quote($timestamp)
             . " WHERE name=" . $dbh->quote($self->charset_encode($node));
            $dbh->do($sql) or croak "Error updating database: " . DBI->errstr;
        }

        # You can't use this to enable moderation on an existing node
        if($requires_moderation) {
           warn("Moderation not added to existing node '$node', use normal moderation methods instead");
        }
    }


    # Now node is updated (if required), add to the history
    my $add_sql = 
         "INSERT INTO content "
        ."    (node_id, version, text, modified, moderated) "
        ."VALUES (?, ?, ?, ?, ?)";
    my $add_sth = $dbh->prepare($add_sql);
    $add_sth->execute(
        map { $self->charset_encode($_) }
            ($node_id, $version, $content, $timestamp, (1-$node_requires_moderation))
    ) or croak "Error updating database: " . DBI->errstr;


    # Update the backlinks.
    $dbh->do("DELETE FROM internal_links WHERE link_from="
             . $dbh->quote($self->charset_encode($node)) ) or croak $dbh->errstr;
    foreach my $links_to ( @links_to ) {
        $sql = "INSERT INTO internal_links (link_from, link_to) VALUES ("
             . join(", ", map { $dbh->quote($self->charset_encode($_)) } ( $node, $links_to ) ) . ")";
        # Better to drop a backlink or two than to lose the whole update.
        # Shevek wants a case-sensitive wiki, Jerakeen wants a case-insensitive
        # one, MySQL compares case-sensitively on varchars unless you add
        # the binary keyword.  Case-sensitivity to be revisited.
        eval { $dbh->do($sql); };
        carp "Couldn't index backlink: " . $dbh->errstr if $@;
    }

    # And also store any metadata.  Note that any entries already in the
    # metadata table refer to old versions, so we don't need to delete them.
    my %metadata = %{ $metadata_ref || {} }; # default to no metadata
    foreach my $type ( keys %metadata ) {
        my $val = $metadata{$type};

        # We might have one or many values; make an array now to merge cases.
        my @values = (ref $val and ref $val eq 'ARRAY') ? @$val : ( $val );

        # Find out whether all values for this type are scalars.
        my $all_scalars = 1;
        foreach my $value (@values) {
            $all_scalars = 0 if ref $value;
        }

        # For adding to metadata
        my $add_sql = 
              "INSERT INTO metadata "
             ."   (node_id, version, metadata_type, metadata_value) "
             ."VALUES (?, ?, ?, ?)";
        my $add_sth = $dbh->prepare($add_sql);

        # If all values for this type are scalars, strip out any duplicates
        # and store the data.
        if ( $all_scalars ) {
            my %unique = map { $_ => 1 } @values;
            @values = keys %unique;

            foreach my $value ( @values ) {
                $add_sth->execute(
                    map { $self->charset_encode($_) }
                        ( $node_id, $version, $type, $value )
                ) or croak $dbh->errstr;
            }
        } else {
            # Otherwise grab a checksum and store that.
            my $type_to_store  = "__" . $type . "__checksum";
            my $value_to_store = $self->_checksum_hashes( @values );
            $add_sth->execute(
                  map { $self->charset_encode($_) }
                      ( $node_id, $version, $type_to_store, $value_to_store )
            )  or croak $dbh->errstr;
        }
    }

    # Finally call post_write on any plugins.
    my @postplugins = @{ $args{plugins} || [ ] };
    foreach my $plugin (@postplugins) {
        if ( $plugin->can( "post_write" ) ) {
            $plugin->post_write( 
                node     => $node,
                node_id  => $node_id,
                version  => $version,
                content  => $content,
                metadata => $metadata_ref );
        }
    }

    return $version;
}

# Returns the timestamp of now, unless epoch is supplied.
sub _get_timestamp {
    my $self = shift;
    # I don't care about no steenkin' timezones (yet).
    my $time = shift || localtime; # Overloaded by Time::Piece.
    unless( ref $time ) {
    $time = localtime($time); # Make it into an object for strftime
    }
    return $time->strftime($timestamp_fmt); # global
}

=item B<rename_node>

  $store->rename_node(
                         old_name  => $node,
                         new_name  => $new_node,
                         wiki      => $wiki,
                         create_new_versions => $create_new_versions,
                       );

Renames a node, updating any references to it as required (assuming your
chosen formatter supports rename, that is).

Uses the internal_links table to identify the nodes that link to this
one, and re-writes any wiki links in these to point to the new name.

=cut

sub rename_node {
    my ($self, %args) = @_;
    my ($old_name,$new_name,$wiki,$create_new_versions) = 
        @args{ qw( old_name new_name wiki create_new_versions ) };
    my $dbh = $self->dbh;
    my $formatter = $wiki->{_formatter};

    # For formatters that support it, run the new name through the node name
    # to param conversion and back again, to make sure any necessary munging
    # gets done.
    if ( $formatter->can( "node_name_to_node_param" )
         && $formatter->can( "node_param_to_node_name" ) ) {
        $new_name = $formatter->node_param_to_node_name(
                        $formatter->node_name_to_node_param( $new_name ) );
    }

    my $timestamp = $self->_get_timestamp();

    # Call pre_rename on any plugins, in case they want to tweak anything
    my @preplugins = @{ $args{plugins} || [ ] };
    my $rename_allowed = 1;
    foreach my $plugin (@preplugins) {
        if ( $plugin->can( "pre_rename" ) ) {
            handle_pre_plugin_ret(
                \$rename_allowed,
                $plugin->pre_rename( 
                    old_name => \$old_name,
                    new_name => \$new_name,
                    create_new_versions => \$create_new_versions,
                )
            );
        }
    }
    if($rename_allowed < 1) {
        # The plugins didn't want to allow this action
        return -1;
    }

    # Get the ID of the node
    my $sql = "SELECT id FROM node WHERE name=?";
    my $sth = $dbh->prepare($sql);
    $sth->execute($old_name);
    my ($node_id) = $sth->fetchrow_array;
    $sth->finish;


    # If the formatter supports it, get a list of the internal
    #  links to the page, which will have their links re-written
    # (Do now before we update the name of the node, in case of
    #  self links)
    my @links;
    if($formatter->can("rename_links")) {
        # Get a list of the pages that link to the page
        $sql = "SELECT id, name, version "
            ."FROM internal_links "
            ."INNER JOIN node "
            ."    ON (link_from = name) "
            ."WHERE link_to = ?";
        $sth = $dbh->prepare($sql);
        $sth->execute($old_name);

        # Grab them all, then update, so no locking problems
        while(my @l = $sth->fetchrow_array) { push (@links, \@l); }
    }

    
    # Rename the node
    $sql = "UPDATE node SET name=? WHERE id=?";
    $sth = $dbh->prepare($sql);
    $sth->execute($new_name,$node_id);


    # Fix the internal links from this page
    # (Otherwise write_node will get confused if we rename links later on)
    $sql = "UPDATE internal_links SET link_from=? WHERE link_from=?";
    $sth = $dbh->prepare($sql);
    $sth->execute($new_name,$old_name);


    # Update the text of internal links, if the formatter supports it
    if($formatter->can("rename_links")) {
        # Update the linked pages (may include renamed page)
        foreach my $l (@links) {
            my ($page_id, $page_name, $page_version) = @$l;
            # Self link special case
            if($page_name eq $old_name) { $page_name = $new_name; }

            # Grab the latest version of that page
            my %page = $self->retrieve_node(
                    name=>$page_name, version=>$page_version
            );

            # Update the content of the page
            my $new_content = 
                $formatter->rename_links($old_name,$new_name,$page{'content'});

            # Did it change?
            if($new_content ne $page{'content'}) {
                # Write the updated page out
                if($create_new_versions) {
                    # Write out as a new version of the node
                    # (This will also fix our internal links)
                    $wiki->write_node(
                                $page_name, 
                                $new_content,
                                $page{checksum},
                                $page{metadata}
                    );
                } else {
                    # Just update the content
                    my $update_sql_a = "UPDATE node SET text=? WHERE id=?";
                    my $update_sql_b = "UPDATE content SET text=? ".
                                       "WHERE node_id=? AND version=?";

                    my $u_sth = $dbh->prepare($update_sql_a);
                    $u_sth->execute($new_content,$page_id);
                    $u_sth = $dbh->prepare($update_sql_b);
                    $u_sth->execute($new_content,$page_id,$page_version);
                }
            }
        }

        # Fix the internal links if we didn't create new versions of the node
        if(! $create_new_versions) {
            $sql = "UPDATE internal_links SET link_to=? WHERE link_to=?";
            $sth = $dbh->prepare($sql);
            $sth->execute($new_name,$old_name);
        }
    } else {
        warn("Internal links not updated following node rename - unsupported by formatter");
    }

    # Call post_rename on any plugins, in case they want to do anything
    my @postplugins = @{ $args{plugins} || [ ] };
    foreach my $plugin (@postplugins) {
        if ( $plugin->can( "post_rename" ) ) {
            $plugin->post_rename( 
                old_name => $old_name,
                new_name => $new_name,
                node_id => $node_id,
            );
        }
    }
}

=item B<moderate_node>

  $store->moderate_node(
                         name    => $node,
                         version => $version
                       );

Marks the given version of the node as moderated. If this is the
highest moderated version, then update the node's contents to hold
this version.

=cut

sub moderate_node {
    my $self = shift;
    my %args = scalar @_ == 2 ? ( name => $_[0], version => $_[1] ) : @_;
    my $dbh = $self->dbh;

    my ($name,$version) = ($args{name},$args{version});

    # Call pre_moderate on any plugins.
    my @plugins = @{ $args{plugins} || [ ] };
    my $moderation_allowed = 1;
    foreach my $plugin (@plugins) {
        if ( $plugin->can( "pre_moderate" ) ) {
            handle_pre_plugin_ret(
                \$moderation_allowed,
                $plugin->pre_moderate( 
                    node     => \$name,
                    version  => \$version )
            );
        }
    }
    if($moderation_allowed < 1) {
        # The plugins didn't want to allow this action
        return -1;
    }

    # Get the ID of this node
    my $id_sql = "SELECT id FROM node WHERE name=?";
    my $id_sth = $dbh->prepare($id_sql);
    $id_sth->execute($name);
    my ($node_id) = $id_sth->fetchrow_array;
    $id_sth->finish;

    # Check what the current highest moderated version is
    my $hv_sql = 
         "SELECT max(version) "
        ."FROM content "
        ."WHERE node_id = ? "
        ."AND moderated = ?";
    my $hv_sth = $dbh->prepare($hv_sql);
    $hv_sth->execute($node_id, "1") or croak $dbh->errstr;
    my ($highest_mod_version) = $hv_sth->fetchrow_array;
    $hv_sth->finish;
    unless($highest_mod_version) { $highest_mod_version = 0; }

    # Mark this version as moderated
    my $update_sql = 
         "UPDATE content "
        ."SET moderated = ? "
        ."WHERE node_id = ? "
        ."AND version = ?";
    my $update_sth = $dbh->prepare($update_sql);
    $update_sth->execute("1", $node_id, $version) or croak $dbh->errstr;

    # Are we now the highest moderated version?
    if(int($version) > int($highest_mod_version)) {
        # Newly moderated version is newer than previous moderated version
        # So, make the current version the latest version
        my %new_data = $self->retrieve_node( name => $name, version => $version );

        # Make sure last modified is properly null, if not set
        unless($new_data{last_modified}) { $new_data{last_modified} = undef; }

        my $newv_sql = 
             "UPDATE node "
            ."SET version=?, text=?, modified=? "
            ."WHERE id = ?";
        my $newv_sth = $dbh->prepare($newv_sql);
        $newv_sth->execute(
            $version, $self->charset_encode($new_data{content}), 
            $new_data{last_modified}, $node_id
        ) or croak $dbh->errstr;
    } else {
        # A higher version is already moderated, so don't change node
    }

    # TODO: Do something about internal links, if required

    # Finally call post_moderate on any plugins.
    @plugins = @{ $args{plugins} || [ ] };
    foreach my $plugin (@plugins) {
        if ( $plugin->can( "post_moderate" ) ) {
            $plugin->post_moderate( 
                node     => $name,
                node_id  => $node_id,
                version  => $version );
        }
    }

    return 1;
}

=item B<set_node_moderation>

  $store->set_node_moderation(
                         name     => $node,
                         required => $required
                       );

Sets if new node versions will require moderation or not

=cut

sub set_node_moderation {
    my $self = shift;
    my %args = scalar @_ == 2 ? ( name => $_[0], required => $_[1] ) : @_;
    my $dbh = $self->dbh;

    my ($name,$required) = ($args{name},$args{required});

    # Get the ID of this node
    my $id_sql = "SELECT id FROM node WHERE name=?";
    my $id_sth = $dbh->prepare($id_sql);
    $id_sth->execute($name);
    my ($node_id) = $id_sth->fetchrow_array;
    $id_sth->finish;

    # Check we really got an ID
    unless($node_id) {
        return 0;
    }

    # Mark it as requiring / not requiring moderation
    my $mod_sql = 
         "UPDATE node "
        ."SET moderate = ? "
        ."WHERE id = ? ";
    my $mod_sth = $dbh->prepare($mod_sql);
    $mod_sth->execute("$required", $node_id) or croak $dbh->errstr;

    return 1;
}

=item B<delete_node>

  $store->delete_node(
                       name    => $node,
                       version => $version,
                       wiki    => $wiki
                     );

C<version> is optional.  If it is supplied then only that version of
the node will be deleted.  Otherwise the node and all its history will
be completely deleted.

C<wiki> is also optional, but if you care about updating the backlinks
you want to include it.

Again, doesn't do any locking. You probably don't want to let anyone
except Wiki admins call this. You may not want to use it at all.

Croaks on error, silently does nothing if the node or version doesn't
exist, returns true if no error.

=cut

sub delete_node {
    my $self = shift;
    # Backwards compatibility.
    my %args = ( scalar @_ == 1 ) ? ( name => $_[0] ) : @_;

    my $dbh = $self->dbh;
    my ($name, $version, $wiki) = @args{ qw( name version wiki ) };

    # Grab the ID of this node
    # (It will only ever have one entry in node, but might have entries
    #  for other versions in metadata and content)
    my $id_sql = "SELECT id FROM node WHERE name=?";
    my $id_sth = $dbh->prepare($id_sql);
    $id_sth->execute($name);
    my ($node_id) = $id_sth->fetchrow_array;
    $id_sth->finish;

    # Trivial case - delete the whole node and all its history.
    unless ( $version ) {
        my $sql;
        # Should start a transaction here.  FIXME.
        # Do deletes
        $sql = "DELETE FROM content WHERE node_id = $node_id";
        $dbh->do($sql) or croak "Deletion failed: " . DBI->errstr;
        $sql = "DELETE FROM internal_links WHERE link_from=".$dbh->quote($name);
        $dbh->do($sql) or croak $dbh->errstr;
        $sql = "DELETE FROM metadata WHERE node_id = $node_id";
        $dbh->do($sql) or croak $dbh->errstr;
        $sql = "DELETE FROM node WHERE id = $node_id";
        $dbh->do($sql) or croak "Deletion failed: " . DBI->errstr;

        # And finish it here.
        post_delete_node($name,$node_id,$version,$args{plugins});
        return 1;
    }

    # Skip out early if we're trying to delete a nonexistent version.
    my %verdata = $self->retrieve_node( name => $name, version => $version );
    unless($verdata{version}) {
        warn( "Asked to delete nonexistent version $version of node "
               . "$node_id ($name)" );
        return 1;
    }

    # Reduce to trivial case if deleting the only version.
    my $sql = "SELECT COUNT(*) FROM content WHERE node_id = $node_id";
    my $sth = $dbh->prepare( $sql );
    $sth->execute() or croak "Deletion failed: " . $dbh->errstr;
    my ($count) = $sth->fetchrow_array;
    $sth->finish;
    if($count == 1) {
        # Only one version, so can do the non version delete
        return $self->delete_node( name=>$name, plugins=>$args{plugins} );
    }

    # Check whether we're deleting the latest (moderated) version.
    my %currdata = $self->retrieve_node( name => $name );
    if ( $currdata{version} == $version ) {
        # Deleting latest version, so need to update the copy in node
        # (Can't just grab version ($version - 1) since it may have been
        #  deleted itself, or might not be moderated.)
        my $try = $version - 1;
        my %prevdata;
        until ( $prevdata{version} && $prevdata{moderated} ) {
            %prevdata = $self->retrieve_node(
                                              name    => $name,
                                              version => $try,
                                            );
            $try--;
        }

        # Move to new (old) version
        my $sql="UPDATE node 
                 SET version=?, text=?, modified=?
                 WHERE name=?";
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @prevdata{ qw( version content last_modified ) }, $name)
            or croak "Deletion failed: " . $dbh->errstr;

        # Remove the current version from content
        $sql = "DELETE FROM content 
                WHERE node_id = $node_id 
                AND version = $version";
        $sth = $dbh->prepare( $sql );
        $sth->execute()
            or croak "Deletion failed: " . $dbh->errstr;

        # Update the internal links to reflect the new version
        $sql = "DELETE FROM internal_links WHERE link_from=?";
        $sth = $dbh->prepare( $sql );
        $sth->execute( $name )
          or croak "Deletion failed: " . $dbh->errstr;
        my @links_to;
        my $formatter = $wiki->formatter;
        if ( $formatter->can( "find_internal_links" ) ) {
            # Supply $metadata to formatter in case it's needed to alter the
            # behaviour of the formatter, eg for Wiki::Toolkit::Formatter::Multiple
            my @all = $formatter->find_internal_links(
                                    $prevdata{content}, $prevdata{metadata} );
            my %unique = map { $_ => 1 } @all;
            @links_to = keys %unique;
        }
        $sql = "INSERT INTO internal_links (link_from, link_to) VALUES (?,?)";
        $sth = $dbh->prepare( $sql );
        foreach my $link ( @links_to ) {
            eval { $sth->execute( $name, $link ); };
            carp "Couldn't index backlink: " . $dbh->errstr if $@;
        }

        # Delete the metadata for the old version
        $sql = "DELETE FROM metadata 
                WHERE node_id = $node_id 
                AND version = $version";
        $sth = $dbh->prepare( $sql );
        $sth->execute()
            or croak "Deletion failed: " . $dbh->errstr;

        # All done
        post_delete_node($name,$node_id,$version,$args{plugins});
        return 1;
    }

    # If we're still here, then we're deleting neither the latest
    # nor the only version.
    $sql = "DELETE FROM content 
            WHERE node_id = $node_id
            AND version=?";
    $sth = $dbh->prepare( $sql );
    $sth->execute( $version )
        or croak "Deletion failed: " . $dbh->errstr;
    $sql = "DELETE FROM metadata 
            WHERE node_id = $node_id
            AND version=?";
    $sth = $dbh->prepare( $sql );
    $sth->execute( $version )
        or croak "Deletion failed: " . $dbh->errstr;

    # All done
    post_delete_node($name,$node_id,$version,$args{plugins});
    return 1;
}

# Returns the name of the node with the given ID
# Not normally used except when doing low-level maintenance
sub node_name_for_id {
    my ($self, $node_id) = @_;
    my $dbh = $self->dbh;

    my $name_sql = "SELECT name FROM node WHERE id=?";
    my $name_sth = $dbh->prepare($name_sql);
    $name_sth->execute($node_id);
    my ($name) = $name_sth->fetchrow_array;
    $name_sth->finish;

    return $name;
}

# Internal Method
sub post_delete_node {
    my ($name,$node_id,$version,$plugins) = @_;

    # Call post_delete on any plugins, having done the delete
    my @plugins = @{ $plugins || [ ] };
    foreach my $plugin (@plugins) {
        if ( $plugin->can( "post_delete" ) ) {
            $plugin->post_delete( 
                node     => $name,
                node_id  => $node_id,
                version  => $version );
        }
    }
}

=item B<list_recent_changes>

  # Nodes changed in last 7 days - each node listed only once.
  my @nodes = $store->list_recent_changes( days => 7 );

  # Nodes added in the last 7 days.
  my @nodes = $store->list_recent_changes(
                                           days     => 7,
                                           new_only => 1,
                                         );

  # All changes in last 7 days - nodes changed more than once will
  # be listed more than once.
  my @nodes = $store->list_recent_changes(
                                           days => 7,
                                           include_all_changes => 1,
                                         );

  # Nodes changed between 1 and 7 days ago.
  my @nodes = $store->list_recent_changes( between_days => [ 1, 7 ] );

  # Nodes changed since a given time.
  my @nodes = $store->list_recent_changes( since => 1036235131 );

  # Most recent change and its details.
  my @nodes = $store->list_recent_changes( last_n_changes => 1 );
  print "Node:          $nodes[0]{name}";
  print "Last modified: $nodes[0]{last_modified}";
  print "Comment:       $nodes[0]{metadata}{comment}";

  # Last 5 restaurant nodes edited.
  my @nodes = $store->list_recent_changes(
      last_n_changes => 5,
      metadata_is    => { category => "Restaurants" }
  );

  # Last 5 nodes edited by Kake.
  my @nodes = $store->list_recent_changes(
      last_n_changes => 5,
      metadata_was   => { username => "Kake" }
  );

  # All minor edits made by Earle in the last week.
  my @nodes = $store->list_recent_changes(
      days           => 7,
      metadata_was   => { username  => "Earle",
                          edit_type => "Minor tidying." }
  );

  # Last 10 changes that weren't minor edits.
  my @nodes = $store->list_recent_changes(
      last_n_changes => 10,
      metadata_wasnt  => { edit_type => "Minor tidying" }
  );

You I<must> supply one of the following constraints: C<days>
(integer), C<since> (epoch), C<last_n_changes> (integer).

You I<may> also supply moderation => 1 if you only want to see versions
that are moderated.

Another optional parameter is C<new_only>, which if set to 1 will only
return newly added nodes.

You I<may> also supply I<either> C<metadata_is> (and optionally
C<metadata_isnt>), I<or> C<metadata_was> (and optionally
C<metadata_wasnt>). Each of these should be a ref to a hash with
scalar keys and values.  If the hash has more than one entry, then
only changes satisfying I<all> criteria will be returned when using
C<metadata_is> or C<metadata_was>, but all changes which fail to
satisfy any one of the criteria will be returned when using
C<metadata_isnt> or C<metadata_is>.

C<metadata_is> and C<metadata_isnt> look only at the metadata that the
node I<currently> has. C<metadata_was> and C<metadata_wasnt> take into
account the metadata of previous versions of a node.  Don't mix C<is>
with C<was> - there's no check for this, but the results are undefined.

Returns results as an array, in reverse chronological order.  Each
element of the array is a reference to a hash with the following entries:

=over 4

=item * B<name>: the name of the node

=item * B<version>: the version number of the node

=item * B<last_modified>: timestamp showing when this version was written

=item * B<metadata>: a ref to a hash containing any metadata attached
to this version of the node

=back

Unless you supply C<include_all_changes>, C<metadata_was> or
C<metadata_wasnt>, each node will only be returned once regardless of
how many times it has been changed recently.

By default, the case-sensitivity of both C<metadata_type> and
C<metadata_value> depends on your database - if it will return rows
with an attribute value of "Pubs" when you asked for "pubs", or not.
If you supply a true value to the C<ignore_case> parameter, then you
can be sure of its being case-insensitive.  This is recommended.

=cut

sub list_recent_changes {
    my $self = shift;
    my %args = @_;
    if ($args{since}) {
        return $self->_find_recent_changes_by_criteria( %args );
    } elsif ($args{between_days}) {
        return $self->_find_recent_changes_by_criteria( %args );
    } elsif ( $args{days} ) {
        my $now = localtime;
    my $then = $now - ( ONE_DAY * $args{days} );
        $args{since} = $then;
        delete $args{days};
        return $self->_find_recent_changes_by_criteria( %args );
    } elsif ( $args{last_n_changes} ) {
        $args{limit} = delete $args{last_n_changes};
        return $self->_find_recent_changes_by_criteria( %args );
    } else {
        croak "Need to supply some criteria to list_recent_changes.";
    }
}

sub _find_recent_changes_by_criteria {
    my ($self, %args) = @_;
    my ($since, $limit, $between_days, $ignore_case, $new_only,
        $metadata_is,  $metadata_isnt, $metadata_was, $metadata_wasnt,
    $moderation, $include_all_changes ) =
         @args{ qw( since limit between_days ignore_case new_only
                    metadata_is metadata_isnt metadata_was metadata_wasnt
            moderation include_all_changes) };
    my $dbh = $self->dbh;

    my @where;
    my @metadata_joins;
    my $use_content_table; # some queries won't need this

    if ( $metadata_is ) {
        my $main_table = "node";
        if ( $include_all_changes ) {
            $main_table = "content";
            $use_content_table = 1;
        }
        my $i = 0;
        foreach my $type ( keys %$metadata_is ) {
            $i++;
            my $value  = $metadata_is->{$type};
            croak "metadata_is must have scalar values" if ref $value;
            my $mdt = "md_is_$i";
            push @metadata_joins, "LEFT JOIN metadata AS $mdt
                                   ON $main_table."
                                   . ( ($main_table eq "node") ? "id"
                                                               : "node_id" )
                                   . "=$mdt.node_id
                                   AND $main_table.version=$mdt.version\n";
            # Why is this inside 'if ( $metadata_is )'?
            # Shouldn't it apply to all cases?
            # What's it doing in @metadata_joins?
            if (defined $moderation) {
                push @metadata_joins, "AND $main_table.moderate=$moderation";
            }
            push @where, "( "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_type",
                                          thing2      => $dbh->quote($type),
                                          ignore_case => $ignore_case,
                                                     )
                         . " AND "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_value",
                                          thing2      => $dbh->quote( $self->charset_encode($value) ),
                                          Ignore_case => $ignore_case,
                                                     )
                         . " )";
    }
    }

    if ( $metadata_isnt ) {
        foreach my $type ( keys %$metadata_isnt ) {
            my $value  = $metadata_isnt->{$type};
            croak "metadata_isnt must have scalar values" if ref $value;
    }
        my @omits = $self->_find_recent_changes_by_criteria(
            since        => $since,
            between_days => $between_days,
            metadata_is  => $metadata_isnt,
            ignore_case  => $ignore_case,
        );
        foreach my $omit ( @omits ) {
            push @where, "( node.name != " . $dbh->quote($omit->{name})
                 . "  OR node.version != " . $dbh->quote($omit->{version})
                 . ")";
    }
    }

    if ( $metadata_was ) {
        $use_content_table = 1;
        my $i = 0;
        foreach my $type ( keys %$metadata_was ) {
            $i++;
            my $value  = $metadata_was->{$type};
            croak "metadata_was must have scalar values" if ref $value;
            my $mdt = "md_was_$i";
            push @metadata_joins, "LEFT JOIN metadata AS $mdt
                                   ON content.node_id=$mdt.node_id
                                   AND content.version=$mdt.version\n";
            push @where, "( "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_type",
                                          thing2      => $dbh->quote($type),
                                          ignore_case => $ignore_case,
                                                     )
                         . " AND "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_value",
                                          thing2      => $dbh->quote( $self->charset_encode($value) ),
                                          ignore_case => $ignore_case,
                                                     )
                         . " )";
        }
    }

    if ( $metadata_wasnt ) {
        foreach my $type ( keys %$metadata_wasnt ) {
                my $value  = $metadata_was->{$type};
                croak "metadata_was must have scalar values" if ref $value;
    }
        my @omits = $self->_find_recent_changes_by_criteria(
                since        => $since,
                between_days => $between_days,
                metadata_was => $metadata_wasnt,
                ignore_case  => $ignore_case,
        );
        foreach my $omit ( @omits ) {
            push @where, "( node.name != " . $dbh->quote($omit->{name})
                 . "  OR content.version != " . $dbh->quote($omit->{version})
                 . ")";
    }
        $use_content_table = 1;
    }

    # Figure out which table we should be joining to to check the dates and
    # versions - node or content.
    my $date_table = "node";
    if ( $include_all_changes || $new_only
           || $metadata_was || $metadata_wasnt ) {
        $date_table = "content";
        $use_content_table = 1;
    }
    if ( $new_only ) {
        push @where, "content.version=1";
    }

    if ( $since ) {
        my $timestamp = $self->_get_timestamp( $since );
        push @where, "$date_table.modified >= " . $dbh->quote($timestamp);
    } elsif ( $between_days ) {
        my $now = localtime;
        # Start is the larger number of days ago.
        my ($start, $end) = @$between_days;
        ($start, $end) = ($end, $start) if $start < $end;
        my $ts_start = $self->_get_timestamp( $now - (ONE_DAY * $start) ); 
        my $ts_end = $self->_get_timestamp( $now - (ONE_DAY * $end) ); 
        push @where, "$date_table.modified >= " . $dbh->quote($ts_start);
        push @where, "$date_table.modified <= " . $dbh->quote($ts_end);
    }

    my $sql = "SELECT DISTINCT
                               node.name,
              ";
    if ( $include_all_changes || $new_only || $use_content_table ) {
        $sql .= " content.version, content.modified ";
    } else {
        $sql .= " node.version, node.modified ";
    }
    $sql .= " FROM node ";
    if ( $use_content_table ) {
        $sql .= " INNER JOIN content ON (node.id = content.node_id ) ";
    }

    $sql .= join("\n", @metadata_joins)
            . (
                scalar @where
                              ? " WHERE " . join(" AND ",@where) 
                              : ""
              )
            . " ORDER BY "
            . ( $use_content_table ? "content" : "node" )
            . ".modified DESC";
    if ( $limit ) {
        croak "Bad argument $limit" unless $limit =~ /^\d+$/;
        $sql .= " LIMIT $limit";
    }
    my $nodesref = $dbh->selectall_arrayref($sql);
    my @finds = map { { name          => $_->[0],
                        version       => $_->[1],
                        last_modified => $_->[2] }
                    } @$nodesref;
    foreach my $find ( @finds ) {
        my %metadata;
        my $sth = $dbh->prepare( "SELECT metadata_type, metadata_value
                                  FROM node
                                  INNER JOIN metadata 
                                  ON (id = node_id)
                                  WHERE name=?
                                  AND metadata.version=?" );
        $sth->execute( $find->{name}, $find->{version} );
        while ( my ($type, $value) = $self->charset_decode( $sth->fetchrow_array ) ) {
        if ( defined $metadata{$type} ) {
                push @{$metadata{$type}}, $value;
        } else {
                $metadata{$type} = [ $value ];
            }
    }
        $find->{metadata} = \%metadata;
    }
    return @finds;
}

=item B<list_all_nodes>

  my @nodes = $store->list_all_nodes();
  print "First node is $nodes[0]\n";

  my @nodes = $store->list_all_nodes( with_details=> 1 );
  print "First node is ".$nodes[0]->{'name'}." at version ".$nodes[0]->{'version'}."\n";

Returns a list containing the name of every existing node.  The list
won't be in any kind of order; do any sorting in your calling script.

Optionally also returns the id, version and moderation flag.

=cut

sub list_all_nodes {
    my ($self,%args) = @_;
    my $dbh = $self->dbh;
    my @nodes;

    if($args{with_details}) {
        my $sql = "SELECT id, name, version, moderate FROM node;";
        my $sth = $dbh->prepare( $sql );
        $sth->execute();

        while(my @results = $sth->fetchrow_array) {
            my %data;
            @data{ qw( node_id name version moderate ) } = @results;
            push @nodes, \%data;
        }
    } else {
        my $sql = "SELECT name FROM node;";
        my $raw_nodes = $dbh->selectall_arrayref($sql); 
        @nodes = ( map { $self->charset_decode( $_->[0] ) } (@$raw_nodes) );
    }
    return @nodes;
}

=item B<list_node_all_versions>

  my @all_versions = $store->list_node_all_versions(
      name => 'HomePage',
      with_content => 1,
      with_metadata => 0
  );

Returns all the versions of a node, optionally including the content
and metadata, as an array of hashes (newest versions first).

=cut

sub list_node_all_versions {
    my ($self, %args) = @_;

    my ($node_id,$name,$with_content,$with_metadata) = 
                @args{ qw( node_id name with_content with_metadata ) };

    my $dbh = $self->dbh;
    my $sql;

    # If they only gave us the node name, get the node id
    unless ($node_id) {
        $sql = "SELECT id FROM node WHERE name=" . $dbh->quote($name);
        $node_id = $dbh->selectrow_array($sql);
    }

    # If they didn't tell us what they wanted / we couldn't find it, 
    #  return an empty array
    return () unless($node_id);

    # Build up our SQL
    $sql = "SELECT id, name, content.version, content.modified ";
    if ( $with_content ) {
        $sql .= ", content.text ";
    }
    if ( $with_metadata ) {
        $sql .= ", metadata_type, metadata_value ";
    }
    $sql .= " FROM node INNER JOIN content ON (id = content.node_id) ";
    if ( $with_metadata ) {
        $sql .= " LEFT OUTER JOIN metadata ON "
           . "(id = metadata.node_id AND content.version = metadata.version) ";
    }
    $sql .= " WHERE id = ? ORDER BY content.version DESC";

    # Do the fetch
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $node_id );

    # Need to hold onto the last row by hash ref, so we don't trash
    #  it every time
    my %first_data;
    my $dataref = \%first_data;

    # Haul out the data
    my @versions;
    while ( my @results = $sth->fetchrow_array ) {
        my %data = %$dataref;

        # Is it the same version as last time?
        if ( %data && $data{'version'} != $results[2] ) {
            # New version
            push @versions, $dataref;
            %data = ();
        } else {
            # Same version as last time, must be more metadata
        }

        # Grab the core data (will be the same on multi-row for metadata)
        @data{ qw( node_id name version last_modified ) } = @results;

        my $i = 4;
        if ( $with_content ) {
            $data{'content'} = $results[$i];
            $i++;
        }
        if ( $with_metadata ) {
            my ($m_type,$m_value) = @results[$i,($i+1)];
            unless ( $data{'metadata'} ) { $data{'metadata'} = {}; }

            if ( $m_type ) {
                # If we have existing data, then put it into an array
                if ( $data{'metadata'}->{$m_type} ) {
                    unless ( ref($data{'metadata'}->{$m_type}) eq "ARRAY" ) {
                        $data{'metadata'}->{$m_type} =
                                             [ $data{'metadata'}->{$m_type} ];
                    }
                    push @{$data{'metadata'}->{$m_type}}, $m_value;
                } else {
                    # Otherwise, just store it in a normal string
                    $data{'metadata'}->{$m_type} = $m_value;
                }
            }
        }

        # Save where we've got to
        $dataref = \%data;
    }

    # Handle final row saving
    if ( $dataref ) {
        push @versions, $dataref;
    }

    # Return
    return @versions;
}

=item B<list_nodes_by_metadata>

  # All documentation nodes.
  my @nodes = $store->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "documentation",
      ignore_case    => 1,   # optional but recommended (see below)
  );

  # All pubs in Hammersmith.
  my @pubs = $store->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "Pub",
  );
  my @hsm  = $store->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value  => "Hammersmith",
  );
  my @results = my_l33t_method_for_ANDing_arrays( \@pubs, \@hsm );

Returns a list containing the name of every node whose caller-supplied
metadata matches the criteria given in the parameters.

By default, the case-sensitivity of both C<metadata_type> and
C<metadata_value> depends on your database - if it will return rows
with an attribute value of "Pubs" when you asked for "pubs", or not.
If you supply a true value to the C<ignore_case> parameter, then you
can be sure of its being case-insensitive.  This is recommended.

If you don't supply any criteria then you'll get an empty list.

This is a really really really simple way of finding things; if you
want to be more complicated then you'll need to call the method
multiple times and combine the results yourself, or write a plugin.

=cut

sub list_nodes_by_metadata {
    my ($self, %args) = @_;
    my ( $type, $value ) = @args{ qw( metadata_type metadata_value ) };
    return () unless $type;

    my $dbh = $self->dbh;
    if ( $args{ignore_case} ) {
        $type  = lc( $type  );
        $value = lc( $value );
    }
    my $sql =
         $self->_get_list_by_metadata_sql( ignore_case => $args{ignore_case} );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $type, $self->charset_encode($value) );
    my @nodes;
    while ( my ($id, $node) = $sth->fetchrow_array ) {
        push @nodes, $node;
    }
    return @nodes;
}

=item B<list_nodes_by_missing_metadata>
Returns nodes where either the metadata doesn't exist, or is blank

Unlike list_nodes_by_metadata(), the metadata value is optional.

  # All nodes missing documentation
  my @nodes = $store->list_nodes_by_missing_metadata(
      metadata_type  => "category",
      metadata_value => "documentation",
      ignore_case    => 1,   # optional but recommended (see below)
  );

  # All nodes which don't have a latitude defined
  my @nodes = $store->list_nodes_by_missing_metadata(
      metadata_type  => "latitude"
  );

=cut

sub list_nodes_by_missing_metadata {
    my ($self, %args) = @_;
    my ( $type, $value ) = @args{ qw( metadata_type metadata_value ) };
    return () unless $type;

    my $dbh = $self->dbh;
    if ( $args{ignore_case} ) {
        $type  = lc( $type  );
        $value = lc( $value );
    }

    my @nodes;

    # If the don't want to match by value, then we can do it with 
    #  a LEFT OUTER JOIN, and either NULL or LENGTH() = 0
    if( ! $value ) {
        my $sql = $self->_get_list_by_missing_metadata_sql( 
                                        ignore_case => $args{ignore_case}
              );
        my $sth = $dbh->prepare( $sql );
        $sth->execute( $type );

        while ( my ($id, $node) = $sth->fetchrow_array ) {
            push @nodes, $node;
        }
    } else {
        # To find those without the value in this case would involve
        #  some seriously brain hurting SQL.
        # So, cheat - find those with, and return everything else
        my @with = $self->list_nodes_by_metadata(%args);
        my %with_hash;
        foreach my $node (@with) { $with_hash{$node} = 1; }

        my @all_nodes = $self->list_all_nodes();
        foreach my $node (@all_nodes) {
            unless($with_hash{$node}) {
                push @nodes, $node;
            }
        }
    }

    return @nodes;
}

=item B<_get_list_by_metadata_sql>

Return the SQL to do a match by metadata. Should expect the metadata type
as the first SQL parameter, and the metadata value as the second.

If possible, should take account of $args{ignore_case}

=cut

sub _get_list_by_metadata_sql {
    # SQL 99 version
    #  Can be over-ridden by database-specific subclasses
    my ($self, %args) = @_;
    if ( $args{ignore_case} ) {
        return "SELECT node.id, node.name "
             . "FROM node "
             . "INNER JOIN metadata "
             . "   ON (node.id = metadata.node_id "
             . "       AND node.version=metadata.version) "
             . "WHERE ". $self->_get_lowercase_compare_sql("metadata.metadata_type")
             . " AND ". $self->_get_lowercase_compare_sql("metadata.metadata_value");
    } else {
        return "SELECT node.id, node.name "
             . "FROM node "
             . "INNER JOIN metadata "
             . "   ON (node.id = metadata.node_id "
             . "       AND node.version=metadata.version) "
             . "WHERE ". $self->_get_casesensitive_compare_sql("metadata.metadata_type")
             . " AND ". $self->_get_casesensitive_compare_sql("metadata.metadata_value");
    }
}

=item B<_get_list_by_missing_metadata_sql>

Return the SQL to do a match by missing metadata. Should expect the metadata 
type as the first SQL parameter.

If possible, should take account of $args{ignore_case}

=cut

sub _get_list_by_missing_metadata_sql {
    # SQL 99 version
    #  Can be over-ridden by database-specific subclasses
    my ($self, %args) = @_;

    my $sql = "";
    if ( $args{ignore_case} ) {
        $sql = "SELECT node.id, node.name "
             . "FROM node "
             . "LEFT OUTER JOIN metadata "
             . "   ON (node.id = metadata.node_id "
             . "       AND node.version=metadata.version "
             . "       AND ". $self->_get_lowercase_compare_sql("metadata.metadata_type")
             . ")";
    } else {
        $sql = "SELECT node.id, node.name "
             . "FROM node "
             . "LEFT OUTER JOIN metadata "
             . "   ON (node.id = metadata.node_id "
             . "       AND node.version=metadata.version "
             . "       AND ". $self->_get_casesensitive_compare_sql("metadata.metadata_type")
             . ")";
    }

    $sql .= "WHERE (metadata.metadata_value IS NULL OR LENGTH(metadata.metadata_value) = 0) ";
    return $sql;
}

sub _get_lowercase_compare_sql {
    my ($self, $column) = @_;
    # SQL 99 version
    #  Can be over-ridden by database-specific subclasses
    return "lower($column) = ?";
}
sub _get_casesensitive_compare_sql {
    my ($self, $column) = @_;
    # SQL 99 version
    #  Can be over-ridden by database-specific subclasses
    return "$column = ?";
}

sub _get_comparison_sql {
    my ($self, %args) = @_;
    # SQL 99 version
    #  Can be over-ridden by database-specific subclasses
    return "$args{thing1} = $args{thing2}";
}

sub _get_node_exists_ignore_case_sql {
    # SQL 99 version
    #  Can be over-ridden by database-specific subclasses
    return "SELECT name FROM node WHERE name = ? ";
}

=item B<list_unmoderated_nodes>

  my @nodes = $wiki->list_unmoderated_nodes();
  my @nodes = $wiki->list_unmoderated_nodes(
                                                only_where_latest => 1
                                            );

  $nodes[0]->{'name'}              # The name of the node
  $nodes[0]->{'node_id'}           # The id of the node
  $nodes[0]->{'version'}           # The version in need of moderation
  $nodes[0]->{'moderated_version'} # The newest moderated version

  With only_where_latest set, return the id, name and version of all the
   nodes where the most recent version needs moderation.
  Otherwise, returns the id, name and version of all node versions that need
   to be moderated.

=cut

sub list_unmoderated_nodes {
    my ($self,%args) = @_;

    my $only_where_lastest = $args{'only_where_latest'};

    my $sql =
         "SELECT "
        ."    id, name, "
        ."    node.version AS last_moderated_version, "
        ."    content.version AS version "
        ."FROM content "
        ."INNER JOIN node "
        ."    ON (id = node_id) "
        ."WHERE moderated = ? "
    ;
    if($only_where_lastest) {
        $sql .= "AND node.version = content.version ";
    }
    $sql .= "ORDER BY name, content.version ";

    # Query
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( "0" );

    my @nodes;
    while(my @results = $sth->fetchrow_array) {
        my %data;
        @data{ qw( node_id name moderated_version version ) } = @results;
        push @nodes, \%data;
    }

    return @nodes;
}

=item B<list_last_version_before>

    List the last version of every node before a given date.
    If no version existed before that date, will return undef for version.
    Returns a hash of id, name, version and date

    my @nv = $wiki->list_last_version_before('2007-01-02 10:34:11')
    foreach my $data (@nv) {
        
    }

=cut

sub list_last_version_before {
    my ($self, $date) = @_;

    my $sql =
         "SELECT "
        ."    id, name, "
        ."MAX(content.version) AS version, MAX(content.modified) AS modified "
        ."FROM node "
        ."LEFT OUTER JOIN content "
        ."    ON (id = node_id "
        ."      AND content.modified <= ?) "
        ."GROUP BY id, name "
        ."ORDER BY id "
    ;

    # Query
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $date );

    my @nodes;
    while(my @results = $sth->fetchrow_array) {
        my %data;
        @data{ qw( id name version modified ) } = @results;
        $data{'node_id'} = $data{'id'};
        unless($data{'version'}) { $data{'version'} = undef; }
        push @nodes, \%data;
    }

    return @nodes;
}


# Internal function only, used when querying latest metadata
sub _current_node_id_versions {
    my ($self) = @_;

    my $dbh = $self->dbh;

    my $nv_sql = 
       "SELECT node_id, MAX(version) ".
       "FROM content ".
       "WHERE moderated ".
       "GROUP BY node_id ";
    my $sth = $dbh->prepare( $nv_sql );
    $sth->execute();

    my @nv_where;
    while(my @results = $sth->fetchrow_array) {
        my ($node_id, $version) = @results;
        my $where = "(node_id=$node_id AND version=$version)";
        push @nv_where, $where;
    }
    return @nv_where;
}

=item B<list_metadata_by_type>

    List all the currently defined values of the given type of metadata.

    Will only return data from the latest moderated version of each node

    # List all of the different metadata values with the type 'category'
    my @categories = $wiki->list_metadata_by_type('category');

=cut
sub list_metadata_by_type {
    my ($self, $type) = @_;

    return undef unless $type;
    my $dbh = $self->dbh;

    # Ideally we'd do this as one big query
    # However, this would need a temporary table on many
    #  database engines, so we cheat and do it as two
    my @nv_where = $self->_current_node_id_versions();

    # Now the metadata bit
    my $sql = 
       "SELECT DISTINCT metadata_value ".
       "FROM metadata ".
       "WHERE metadata_type = ? ".
       "AND (".
       join(" OR ", @nv_where).
       ")";
    my $sth = $dbh->prepare( $sql );
    $sth->execute($type);

    my $values = $sth->fetchall_arrayref([0]);
    return ( map { $self->charset_decode( $_->[0] ) } (@$values) );
}


=item B<list_metadata_names>

    List all the currently defined kinds of metadata, eg Locale, Postcode

    Will only return data from the latest moderated version of each node

    # List all of the different kinds of metadata
    my @metadata_types = $wiki->list_metadata_names()

=cut
sub list_metadata_names {
    my ($self) = @_;

    my $dbh = $self->dbh;

    # Ideally we'd do this as one big query
    # However, this would need a temporary table on many
    #  database engines, so we cheat and do it as two
    my @nv_where = $self->_current_node_id_versions();

    # Now the metadata bit
    my $sql = 
       "SELECT DISTINCT metadata_type ".
       "FROM metadata ".
       "WHERE (".
       join(" OR ", @nv_where).
       ")";
    my $sth = $dbh->prepare( $sql );
    $sth->execute();

    my $types = $sth->fetchall_arrayref([0]);
    return ( map { $self->charset_decode( $_->[0] ) } (@$types) );
}


=item B<schema_current>

  my ($code_version, $db_version) = $store->schema_current;
  if ($code_version == $db_version)
      # Do stuff
  } else {
      # Bail
  }

=cut

sub schema_current {
    my $self = shift;
    my $dbh = $self->dbh;
    my $sth;
    eval { $sth = $dbh->prepare("SELECT version FROM schema_info") };
    if ($@) {
        return ($SCHEMA_VER, 0);
    }
    eval { $sth->execute };
    if ($@) {
        return ($SCHEMA_VER, 0);
    }
    my $version;
    eval { $version = $sth->fetchrow_array };
    if ($@) {
        return ($SCHEMA_VER, 0);
    } else {
        return ($SCHEMA_VER, $version);
    }
}


=item B<dbh>

  my $dbh = $store->dbh;

Returns the database handle belonging to this storage backend instance.

=cut

sub dbh {
    my $self = shift;
    return $self->{_dbh};
}

=item B<dbname>

  my $dbname = $store->dbname;

Returns the name of the database used for backend storage.

=cut

sub dbname {
    my $self = shift;
    return $self->{_dbname};
}

=item B<dbuser>

  my $dbuser = $store->dbuser;

Returns the username used to connect to the database used for backend storage.

=cut

sub dbuser {
    my $self = shift;
    return $self->{_dbuser};
}

=item B<dbpass>

  my $dbpass = $store->dbpass;

Returns the password used to connect to the database used for backend storage.

=cut

sub dbpass {
    my $self = shift;
    return $self->{_dbpass};
}

=item B<dbhost>

  my $dbhost = $store->dbhost;

Returns the optional host used to connect to the database used for
backend storage.

=cut

sub dbhost {
    my $self = shift;
    return $self->{_dbhost};
}

# Cleanup.
sub DESTROY {
    my $self = shift;
    return if $self->{_external_dbh};
    my $dbh = $self->dbh;
    $dbh->disconnect if $dbh;
}

# decode a string of octets into perl's internal encoding, based on the
# charset parameter we were passed. Takes a list, returns a list.
sub charset_decode {
    my $self = shift;
    my @input = @_;
    if ($CAN_USE_ENCODE) {
        my @output;
        for (@input) {
            push( @output, Encode::decode( $self->{_charset}, $_ ) );
        }
        return @output;
    }
    return @input;
}

# convert a perl string into a series of octets we can put into the database
# takes a list, returns a list
sub charset_encode {
    my $self = shift;
    my @input = @_;
    if ($CAN_USE_ENCODE) {
        my @output;
        for (@input) {
            push( @output, Encode::encode( $self->{_charset}, $_ ) );
        }
        return @output;
    }
    return @input;
}

=back

=cut

1;
