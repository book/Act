package Act::Handler::Talk::Schedule;
use Act::Config;
use Act::TimeSlot;
use Act::Template::HTML;
use strict;

sub handler {
    my (%table, %index, %room);  # helpful structures
    my ($todo, $globals);        # events lists

    # sort and separate global and normal items
    $table{$_->datetime->ymd}++, # create table structure
    $room{$_->room}++,           # compute the room list
    push @{ $_->room =~ /^(?:out|venue)$/ ? $globals : $todo }, $_
        for sort {
            DateTime->compare( $a->datetime, $b->datetime )
            || $a->duration <=> $b->duration 
        } @{ Act::TimeSlot->get_items( conf_id => $Request{conference} ) };

    # create a table/index per day
    $table{$_} = [], $index{$_} = 0 for keys %table;
    # create the room structures
    for ( keys %room ) {
        $room{$_} = {};
        delete $room{$_} if /^(?:out|venue)$/;
    }
    # insert all globals
    # FIXME we suppose no conflict between globals...
    for( @$globals ) {
        my $day = $_->datetime->ymd;
        # add the start time of the global
        #push @{ $table{$day} }, [ $_->datetime->clone, { $_->room => [ $_ ] } ];
    }

    # the %table structure is made of rows like the following
    # [ $dt, { r1 => [], r2 => [] } ]

    # insert the rest of the talks
    for( @$todo ) {
        my $dt  = $_->datetime;
        my $day = $dt->ymd;
        my $row = $table{$day};
        my $end = $_->datetime->clone;
        $end->add( minutes => $_->duration );

        # skip to find our place
        $index{$day}++
            while( $row->[ $index{$day} ] and
                   $row->[ $index{$day} ][0] < $dt );
        # update the table structure
        my $i = $index{$day};
        my $added = 0;
        # insert the beginning if necessary (yuck, dups)
        if( $row->[$i] and $row->[$i][0] != $dt ) {
            splice( @$row, $index{$day}, 0, [ $dt->clone, { $_->room => [ $_ ] } ] );
            $room{$_->room}{$day} = 1;
            $added = 1;
        }
        while( $row->[$i] and $row->[$i][0] < $end ) {
            # FIXME cut off by a global
            # push the item on the list of talks happening now
            # the talk is "extended" on all the corresponding slots
            my $count = push @{ $row->[$i][1]{$_->room} ||= [] }, $_;
            # compute each columns total width on the fly
            $room{$_->room}{$day} = $count if $room{$_->room}{$day} < $count;
            $added = 1;
            $i++;
        }
        # insert a new row structure if necessary
        splice( @$row, $index{$day}, 0, [ $dt->clone, { $_->room => [ $_ ] } ] ),
        $room{$_->room}{$day} = 1
          unless $added;
        # insert the ending moment
        push @$row, [ $end, { } ];
    }
    # finish line
    my %seen;
    for my $day ( keys %table ) {
        for my $row ( @{$table{$day}} ) {
            for my $room ( keys %room ) {
                # fill with blanks
                $row->[1]{$room} ||= [];
                push @{ $row->[1]{$room} },
                     ('-') x ( $room{$room}{$day} - @{ $row->[1]{$room} } );
            }
            # remove duplicate talks
            @$row = (
                $row->[0]->strftime('%H:%M'),
                grep { $seen{$_}++ ? ( $_ eq '-' ? $_ : () ) : $_ }
                map { ref and $_->{height}++; $_ }
                # from the list of items
                map { @{ $row->[1]{$_} } } keys %room
            );
        }
    }
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables( table => \%table, room => \%room );
    $template->process('talk/schedule');
}

1;

__END__
