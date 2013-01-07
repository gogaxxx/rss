package Agg::Saver;

use strict;
use Agg::Item;
use GDBM_File;
use Fcntl qw(:DEFAULT :flock :seek);

use constant DBCLASS => 'GDBM_File';

sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self = bless {}, $class;
	$self->{cfg} = $cfg;

	if (-e $cfg->{items_dir} && !-d $cfg->{items_dir}) {
		die("[Agg::Saver::RSS] $cfg->{items_dir} is not a directory");
	}
	elsif (!-e $cfg->{items_dir}) {
		mkdir($cfg->{items_dir})
			or die("[Agg::Saver::RSS] can't create $cfg->{items_dir}: $!");
	}
	$self->{guidsfile}  = $self->{cfg}{'feed-dir'}.'/guids';

	$self->check_and_create_db();
	my %guids;
	my $dbo = tie %guids, DBCLASS, $self->{guidsfile}, O_CREAT|O_RDWR, 0666;
	$self->{guids} = \%guids;

	$self->{itemizer} = Agg::Item->new($self->{cfg});
    $self->{item_num} = $self->get_saved_id();

	return $self;
}

# check_and_create_db #+++1
#
# проверить, существует ли guids.db и собрать его из мастер файла
#
sub check_and_create_db {
	my $self = shift;

	my $guidmaster = $self->{cfg}{master};
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
        unlink($db_filename);
        my %guids;
        tie %guids, DBCLASS, $self->{guidsfile}, O_CREAT|O_RDWR, 0666;

        if (open(MASTER, '<'.$guidmaster)) {
            while (my $line = <MASTER>) {
                chomp $line;
				my @parts = split(/\s+/o, $line);
				# parts[2] - guid, $parts[1] - item_num
                $guids{$parts[2]} = $parts[1];
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

	$item->{name} = $self->{item_num};
	$self->{itemizer}->save_item($item);

	$self->save_item_data($item);
	$guids->{$item->{guid}} = 1;

    print($self->{item_num}, ' ') if ($self->{cfg}->{be_verbose});
	$self->{item_num}++;
}

### save_item_data ####### #+++1
#
# write one item data to index file
#
sub save_item_data {
	my $self=shift;
	my $item=shift;

	$self->_save_item_data_to_file($item, $self->{'cfg'}{'master'});
	$self->_save_item_data_to_file($item, $self->{'cfg'}{'news'});
}

# _save_item_data_to_file #+++1
sub _save_item_data_to_file {
	my $self=shift;
	my $item=shift;
	my $indexfile = shift;

	open (OUT, '>>', $indexfile)
		|| die("Can't open $indexfile: $!");
	flock(OUT, LOCK_EX) or die("Can't flock: $!");
	seek(OUT, 0, SEEK_END) or die("Can't seek: $!");
	print OUT $item->{'time'}, ' ', 
			  $self->{item_num}, ' ',
			  $item->{'guid'}, "\n";
	flock(OUT, LOCK_UN) or die("Can't unlock: $!");
	close(OUT);
}
#---1

sub finish {
	my $self=shift;

	$self->save_id();
	untie %{$self->{guids}};
}

### get_saved_id ####+++1
sub get_saved_id {
	my $self=shift;

    if (open(IN, '<'.$self->{cfg}{'feed-dir'}.'/number')) {
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

### save_id ####+++1
sub save_id {
	my $self=shift;

    if (open(OUT, '>'.$self->{cfg}{'feed-dir'}.'/number')) {
        print OUT $self->{item_num};
        close OUT;
    }
}

#---1

1;
