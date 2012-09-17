package Agg::Saver;

use strict;
use AnyDBM_File;
use Fcntl qw(:DEFAULT :flock :seek);

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

	$self->check_and_create_db();
	my %guids;
	my $dbo = tie %guids, 'AnyDBM_File', $self->{guidsfile}, O_CREAT|O_RDWR, 0666;
	$self->{guids} = \%guids;

	return $self;
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
				# parts[2] - guid, $parts[1] - item_num
                $guids{$parts[2]} = $parts[1];
            }
            close FILE;
        }

        untie %guids;
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
#---1

sub finish {
	my $self=shift;

	$self->save_id();
	untie %{$self->{guids}};
}

sub save_id {}

#---1

1;
