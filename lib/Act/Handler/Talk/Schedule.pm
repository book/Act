package Act::Handler::Talk::Schedule;
use Act::Config;
use Act::TimeSlot;
use Act::Template::HTML;
use strict;

sub handler {
    my (%table, %index, %room, %time); # helpful structures
    my ($todo, $globals) = ([],[]);    # events lists
    my $out = qr/^(?:out|venue)$/;

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
        push @{ $_->room =~ $out ? $globals : $todo }, $_;
    }

    # create the room structures
    for my $r ( keys %room ) {
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
        my $dt  = $_->datetime;
        my $day = $dt->ymd;
        my $r   = $_->room;
        my $row = $table{$day};
        
        # skip to find where to put this event
        $index{$day}++ while $row->[ $index{$day} ][0] < $dt;
        my $i = $index{$day};
        push @{ $row->[$i][1]{$r} }, $_;
        $room{$r}{$day}[$i]++;
        #$room{$_}{$day}[$i] = 1 for keys %room;
        $i++;
        splice @$row, $i++, 1 while $i < @$row and $row->[$i][0] < $_->{end};
    }

    # the %table structure is made of rows like the following
    # [ $dt, { r1 => [], r2 => [] } ]

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
        push @{ $row->[$i][1]{$r} }, $_;
        $room{$r}{$day}[$i++]++;
        # insert the event several times if it spans several blocks
        my $n = 1;
        while($i < @$row and $row->[$i][0] < $_->{end}) {
            my @globals = map { $row->[$i][1]{$_} ? (@{ $row->[$i][1]{$_} }): () } qw( out venue );
            if( @globals ) { # we only care about the longuest
                my $new = bless { %$_, height => 1 }, 'Act::TimeSlot';
                $new->{datetime} = $globals[-1]->{end}->clone;
                $new->{duration} = ($_->{end} - $globals[-1]->datetime)->delta_minutes;
                $_->{duration} -= $new->{duration};
                $new->{end} = $new->{datetime}->clone->add( minutes => $new->duration );
                ( $new->{title} = $_->title ) =~ s/(?: \((\d+)\))?$/ (@{[($1||1)+1]})/;
                my $j = $i;
                $j++ while $j < @$row and $row->[$j][0] < $new->{datetime};
                unless( $row->[$j][0] == $new->datetime ) {
                    splice @$row, $j, 0, [ $new->datetime, {} ];
                }
                unshift @$todo, $new;
            }
            else {
                $room{$r}{$day}[$i]++;
                $_->{height}++;
            }
            $i++;
        }
        # FIXME check conflicts with globals
    }
    # compute the max
    my ( %width, %maxwidth );
    for my $day (keys %table) {
        for my $r (keys %room) {
            my $max;
            $max = $max < $room{$r}{$day}[$_] ? $room{$r}{$day}[$_] : $max
                for 0 .. @{ $room{$r}{$day} } - 1;
            $width{$r}{$day} = $max;
        }
        $maxwidth{$day} = 0;
        $maxwidth{$day} += $width{$_}{$day} for grep { !m/$out/ } keys %room;
    }

    # finish line
    my $def = '-';
    for my $day ( keys %table ) {
        my $i = 0;
        for my $row ( @{$table{$day}} ) {
            my $global = 0;
            my @row = ( $row->[0]->strftime('%H:%M') );
            for( sort keys %room ) {
                for( @{$row->[1]{$_}}) {
                    $global++ if $_->room =~ $out;
                }
                push @row, @{ $row->[1]{$_} };
                push @row, ( $global ? () : ("[$_]") x ( $width{$_}{$day} - $room{$_}{$day}[$i] ) )
                    unless m/$out/;
            }
            # fill the blanks
            @$row = @row;
            $i++;
        }
    }
    delete $room{$_} for qw( out venue );
    # process the template
    my $template = Act::Template::HTML->new();
    $template->variables(
        table    => \%table,
        room     => \%room,
        width    => \%width,
        maxwidth => \%maxwidth
    );
    $template->process('talk/schedule');
}

1;

__END__
