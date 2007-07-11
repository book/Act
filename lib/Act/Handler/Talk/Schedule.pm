package Act::Handler::Talk::Schedule;
use Act::Config;
use Act::TimeSlot;
use Act::Template::HTML;
use List::Util qw( sum );
use strict;

sub handler {
    my ($table, $room, $width, $maxwidth, $todo) = compute_schedule();

    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        table    => $table,
        room     => $room,
        width    => $width,
        maxwidth => $maxwidth,
        todo     => $todo
    );
    $template->process('talk/schedule');
}

sub compute_schedule {
    my (%table, %index, %room, %time); # helpful structures
    my ($todo, $globals) = ([],[]);    # events lists

    # pick up talks and events without a time or a place
    my (@ts, @undecided );
    for( @{ Act::TimeSlot->get_items( conf_id => $Request{conference} ) } ) {
        if( ( defined $_->{datetime} && defined $_->room ) ) {
            push @ts, $_;
        }
        else { push @undecided, $_ }
    }
 
    # sort and separate global and normal items
    # compute the times to show in the chart
    for ( sort {
        DateTime->compare( $a->datetime, $b->datetime )
        || $a->duration <=> $b->duration 
    } @ts) {
        my $day = $_->datetime->ymd;  # current day
        $table{$day} ||= [];          # create table structure
        $room{$_->room}++             # compute the room list
            unless $_->is_global;
        $_->{height} = 1;             # minimum height
        # fill the rows
        $_->{end} = $_->datetime->clone;
        $_->{end}->add( minutes => $_->duration );
        $time{$day}{$_->datetime->strftime('%Y-%m-%d %H:%M')} = $_->datetime->clone;
        $time{$day}{$_->{end}->strftime('%Y-%m-%d %H:%M')}    = $_->{end};
        # separate global and local items
        push @{ $_->is_global ? $globals : $todo }, $_;
    }

    # create the room structures
    for my $r ( keys %room ) {
        $room{$r} = {};
        $room{$r}{$_} = [] for keys %table;
    }
    # create the empty table
    for my $day (keys %table) {
        # the table is a hash keyed by date/day
        # each row structure is a list of rows as
        # [ datetime, { room => [ list of talks ] }, [ globals ] ]
        $table{$day} = [
            map { [ $time{$day}{$_}, { map { $_ => [] } keys %room }, [] ] }
                sort keys %{$time{$day}}
        ];
        $index{$day} = 0;
    }
    
    # first insert all globals in the table
    # FIXME we suppose there is no conflict between globals...
    for( @$globals ) {
        my $dt  = $_->datetime;
        my $day = $dt->ymd;
        my $row = $table{$day};
        
        # skip to find where to put this event
        $index{$day}++ while $row->[ $index{$day} ][0] < $dt;
        my $i = $index{$day};
        push @{ $row->[$i][2] }, $_;
        $i++;
        splice @$row, $i++, 1 while $i < @$row and $row->[$i][0] < $_->{end};
    }

    # the %table structure is made of rows like the following
    #  date, normal talks,           globals
    # [ $dt, { r1 => [], r2 => [] }, [] ]

    # insert the rest of the talks
    $index{$_} = 0 for keys %table;
    while( @$todo ) {
        local $_ = shift @$todo;
        my $dt  = $_->datetime;
        my $day = $dt->ymd;
        my $r   = $_->room;
        my $row = $table{$day};

        # skip to find our place
        $index{$day}++ while $row->[ $index{$day} ][0] < $dt;
        # update the table structure
        my $i = $index{$day};
        # FIXME move away if there's a global talk
        #if( @{ $row->[$i][2] } ) {
        #    
        #}
        push @{ $row->[$i][1]{$r} }, $_;
        $room{$r}{$day}[$i++]++;
        # insert the talk several times if it spans several blocks
        my $n = 1;
        while($i < @$row and $row->[$i][0] < $_->{end}) {
            # if a global talk starts in the middle
            if( @{ $row->[$i][2] } ) {
                # split the talk in two
                my $new = bless { %$_, height => 1 }, 'Act::TimeSlot';
                $new->{datetime} = $row->[$i][2][-1]->{end}->clone;
                
                # we only care about the longuest global talk
                # FIXME could fail is another global talk started later
                $new->{duration} = ($_->{end} - $row->[$i][2][-1]->datetime)->delta_minutes;
                $_->{duration} -= $new->{duration};
                $_->{end} = $_->{datetime}->add( minutes => $_->{duration} );
                $new->{end} = $new->{datetime}->clone->add( minutes => $new->duration );
                ( $new->{title} = $_->title ) =~ s/(?: \((\d+)\))?$/ (@{[($1||1)+1]})/;
                # eventually add a new line to put the new talk
                my $j = $i;
                $j++ while $j < @$row and $row->[$j][0] < $new->{datetime};
                unless( $row->[$j][0] == $new->datetime ) {
                    splice @$row, $j, 0,
                        [ $new->datetime, { map { $_ => [] } keys %room }, [] ];
                }

                # check that a line exists to mark the end of the new talk
                $j = $i;
                $j++ while $j < @$row and $row->[$j][0] < $new->{end};
                if( $j < @$row && $row->[$j][0] != $new->{end} ) {
                    splice @$row, $j, 0,
                        [ $new->{end}, { map { $_ => [] } keys %room }, [] ];
                }

                # add the new talk in the todo list
                $j = 0;
                $j++ while $j < @$todo and $todo->[$j]->datetime < $new->datetime;
                splice @$todo, $j, 0, $new;
            }
            else {
                $room{$r}{$day}[$i]++;
                $_->{height}++;
            }
            $i++;
        }
    }

    # compute the max
    my ( %width, %maxwidth );
    for my $day (keys %table) {
        for my $r (keys %room) {
            my $max;
            $max = $max < $room{$r}{$day}[$_] ? $room{$r}{$day}[$_] : $max
                for 0 .. @{ $room{$r}{$day} } - 1;
            $width{$r}{$day} = $max || 1;
        }
        $maxwidth{$day} = 0;
        $maxwidth{$day} += $width{$_}{$day} for keys %room;
    }

    # finish line
    my $def = '-';
    for my $day ( keys %table ) {
        my $i = 0;
        my (@started, @rows_to_remove);
        for my $row ( @{$table{$day}} ) {

            # if the row is empty and no talk ends at that time
            my $is_used = sum(
                map ( { scalar @{ $row->[1]{$_} } } keys %room ),
                map ( { $_->{end} == $row->[0] ? 1 : 0 } @started ),
                scalar @{$row->[2]} # global talks
            );
            if( $is_used ) {
                # add all talks to the "started" list
                # remove talks that end at that time from the "started" list
                @started = grep { $_->{end} != $row->[0] } @started,
                    map( { @{ $row->[1]{$_} } } keys %room ),   # normal talks
                    @{ $row->[2] };                             # global talks
            }
            else {
                # mark the row to be removed later
                push @rows_to_remove, $i;
                # decrease height of all opened talks
                $_->{height}-- for @started;
            }
        
            my $global = 0;
            my @row = ( $row->[0]->strftime('%H:%M') );
            $global++ if @{ $row->[2] };
            for( sort keys %room ) {
                push @row, @{ $row->[1]{$_} };
                push @row, ( $global ? () : (" ") x ( $width{$_}{$day} - $room{$_}{$day}[$i] ) );
            }
            push @row, @{$row->[2]};
            # fill the blanks
            @$row = @row;
            $i++;
        }

        # remove really empty rows (start from the end)
        splice( @{$table{$day}}, $_, 1) for reverse @rows_to_remove;
    }

    return ( \%table, \%room, \%width, \%maxwidth, \@undecided );
}

1;

=head1 NAME

Act::Handler::Talk::Schedule - Compute and display the conference schedule

=head1 DESCRIPTION

See F<DEVDOC> for a complete discussion on handlers.

=cut
