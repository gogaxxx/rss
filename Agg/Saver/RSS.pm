package Agg::Saver::RSS;

use strict;
use AnyDBM_File;
use Date::Parse;
use Encode;
use Fcntl qw(:DEFAULT :flock :seek);
use POSIX qw(strftime);

#+++1 new
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self = bless {}, $class;
	$self->{cfg} = $cfg;

	my $cfg->{items_dir} = $cfg->{config_dir}.'/items';

	if (-e $cfg->{items_dir} && !-d $cfg->{items_dir}) {
		die("[Agg::Saver::RSS] $cfg->{items_dir} is not a directory");
	}
	elsif (!-e $cfg->{items_dir}) {
		mkdir($cfg->{items_dir})
			or die("[Agg::Saver::RSS] can't create $cfg->{items_dir}: $!");
	}

	$self->{master} = $self->{cfg}{config_dir}.'/master';
	$self->{guidsfile}  = $self->{cfg}{config_dir}.'/guids';

    $self->{item_num} = $self->get_saved_id();

	$self->check_and_create_db();
	my %guids;
	my $dbo = tie %guids, 'AnyDBM_File', $self->{guidsfile}, O_CREAT|O_RDWR, 0666;
	$self->{guids} = \%guids;

	return $self;
}

sub finish {
	my $self=shift;

	$self->save_id();
	untie %{$self->{guids}};
}

# check_and_create_db #+++1
#
# проверить, существует ли guids.db и собрать его из мастер файла
#
sub check_and_create_db {
	my $self = shift;

	my $guidmaster = $self->{master};
	my $db_filename  = $self->{guidsfile};
	#my $db_filename = $cfg::guiddatabase.'.db';

    my $need_remake = 0;

    if (-e $guidmaster 
            and
        !-e $db_filename) 
    {
        # отсутствует db файл - просто пересобрать из мастера
        $need_remake = 1;
    }
    elsif (!-e $guidmaster) {
        # отсутствует мастер - db недействителен!
        # создаём пустой мастер и пустой db
        open(MASTER, '>'.$guidmaster);
        close MASTER;
        unlink($db_filename);
        $need_remake = 1;
    }
    elsif (-e $guidmaster 
            and
           -e $db_filename)
    {
        # оба файла существуют - хорошо!
        # проверим, если мастер обновлён позже db - пересобрать
        my @master_stat = stat($guidmaster);
        my @db_stat     = stat($db_filename);

        if ($master_stat[9] > $db_stat[9]) {
            $need_remake = 1;
        }
    }

    if ($need_remake) {
        warn "Rebuilding database...\n";
        my %guids;
        tie %guids, 'AnyDBM_File', $self->{guidsfile}, O_CREAT|O_RDWR, 0666;

        if (open(MASTER, '<'.$guidmaster)) {
            while (my $line = <MASTER>) {
                chomp $line;
				my @parts = split(/\s+/o, $line);
                $guids{$parts[2]} = 1;
            }
            close FILE;
        }

        untie %guids;
    }
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

### save_item_data ####### #+++1
#
# write one item data to index file
#
sub save_item_data {
	my $self=shift;
	my $item=shift;

	open (OUT, '>>', $self->{master})
		|| die("Can't open $self->{master}: $!");
	flock(OUT, LOCK_EX) or die("Can't flock: $!");
	seek(OUT, 0, SEEK_END) or die("Can't seek: $!");
	print OUT $item->{'time'}, ' ', 
			  $self->{item_num}, ' ',
			  $item->{'guid'}, "\n";
	flock(OUT, LOCK_UN) or die("Can't unlock: $!");
	close(OUT);
}

1;
