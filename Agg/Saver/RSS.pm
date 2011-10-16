package Agg::Saver::RSS;

use strict;
use base qw(Agg::Saver);
use Date::Parse;
use Encode;
use POSIX qw(strftime);

#+++1 new
sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);

    $self->{item_num} = $self->get_saved_id();

	return $self;
}

### save_item ####+++1
sub save_item {
	my $self=shift;
    my ($item)=@_;

	my $guids = $self->{guids};

	return if ($guids->{$item->{guid}});

	$guids->{$item->{guid}} = 1;

    $item->{'time'} = 
		$item->{date}
			?  str2time($item->{date})
			:  time();

    Encode::_utf8_off($item->{subject}); # XXX use binmode instead
    Encode::_utf8_off($item->{body});

	#transform_item($item);

    open (OUT, '>' . $self->{cfg}{items_dir} . '/'. $self->{item_num});
    my $show_link = substr($item->{link}, 0, 40);
    if (length($show_link) < length($item->{link})) {
            $show_link .= '...';
    }
    print OUT ('<h1>', $item->{subject},
                '</h1><a class="itemlink" href="', 
                $item->{link},
                '" target=_blank>[link-='.$self->{item_num}.': ', $show_link, ']</a>');
    print OUT ('<span class="date">',
                strftime($cfg::date_format, localtime($item->{'time'})),
                '</span><div class="body">');
    print OUT ($item->{body}, '</div><br clear=all><hr>');
    close OUT;

	$self->save_item_data($item);

    print($self->{item_num}, ' ');
	$self->{item_num} ++;
}

sub get_saved_id {
	my $self=shift;

    if (open(IN, '<'.$self->{cfg}{config_dir}.'/number')) {
        my $id = <IN>;
        close IN;

        while (-e $self->{cfg}{items_dir}.'/'.$id) {
            $id++;
        }
        return $id || 1; 
    }
    else {
        return 1;
    }
}

sub save_id {
	my $self=shift;

    if (open(OUT, '>'.$self->{cfg}{config_dir}.'/number')) {
        print OUT $self->{item_num};
        close OUT;
    }
}

1;
