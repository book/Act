package Act::Handler::Talk::Schedule;
use Act::Config;
use Act::TimeSlot;
use Act::Template::HTML;
use strict;

sub handler {
    my (%table, %index, %room, %time); # helpful structures
    my ($todo, $globals);              # events lists

    # sort and separate global and normal items
    # compute the times to show in the chart
    for ( sort {
        DateTime->compare( $a->datetime, $b->datetime )
        || $a->duration <=> $b->duration 
    }
    # default date
    map { $_->{datetime} ||= DateTime::Format::Pg->parse_timestamp($Config->talks_start_date); $_ }
    @{ Act::TimeSlot->get_items( conf_id => $Request{conference} ) } ) {
        my $day = $_->datetime->ymd; # current day
        $table{$day} ||= [];         # create table structure
        $room{$_->room}++;           # compute the room list
        $_->{height} = 1;            # minimum height
        # fill the rows
        $_->{end} = $_->datetime->clone;
        $_->{end}->add( minutes => $_->duration );
        $time{$day}{$_->datetime->strftime('%H:%M')} = $_->datetime->clone;
        $time{$day}{$_->{end}->strftime('%H:%M')}    = $_->{end};
        # separate global and local items
        push @{ $_->room =~ /^(?:out|venue)$/ ? $globals : $todo }, $_;
    }

    # create the room structures
    for my $r ( keys %room ) {
        delete $room{$r}, next if $r =~ /^(?:out|venue)$/;
        $room{$r} = {};
        $room{$r}{$_} = [] for keys %table;
    }
    # create the empty table
    for my $day (keys %table) {
        $table{$day} = [
            map { [ $time{$day}{$_}, { map { $_ => [] } keys %room } ] }
                sort keys %{$time{$day}}
        ];
        $index{$day} = 0;
    }
    
    # insert all globals
    # FIXME we suppose no conflict between globals...
    for( @$globals ) {
        my $day = $_->datetime->ymd;
        # add the start time of the global
    }

    # the %table structure is made of rows like the following
    # [ $dt, { r1 => [], r2 => [] } ]

    # insert the rest of the talks
    for( @$todo ) {
        my $dt  = $_->datetime;
        my $day = $dt->ymd;
        my $r   = $_->room;
        my $row = $table{$day};

        # skip to find our place
        $index{$day}++ while $row->[ $index{$day} ][0] < $dt;
        # update the table structure
        my $i = $index{$day};
        push @{ $row->[$i][1]{$r} }, $_;
        $room{$r}{$day}[$i++]++;
        # insert the event several times if it spans several blocks
        $room{$r}{$day}[$i]++, $_->{height}++, $i++
          while $row->[$i][0] < $_->{end};
        # FIXME check conflicts with globals
    }
    # compute the max
    my %width;
    for my $day (keys %table) {
        for my $r (keys %room) {
            my $max;
            $max = $max < $room{$r}{$day}[$_] ? $room{$r}{$day}[$_] : $max
                for 0 .. @{ $room{$r}{$day} } - 1;
            $width{$r}{$day} = $max;
        }
    }

    # finish line
    my $def = '-';
    for my $day ( keys %table ) {
        my $i = 0;
        for my $row ( @{$table{$day}} ) {
            # fill the blanks
            @$row = (
                $row->[0]->strftime('%H:%M'),
                # from the list of items
                map { (
                    @{ $row->[1]{$_} },
                    ("[$_]") x ( $width{$_}{$day} - $room{$_}{$day}[$i] )
                ) } sort keys %room
            );
            $i++;
        }
    }
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables( table => \%table, room => \%room, width => \%width );
    $template->process('talk/schedule');
}

1;

__END__
