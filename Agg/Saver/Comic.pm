package Agg::Saver::Comic;

use strict;
use AnyDBM_File;
use Fcntl qw(:DEFAULT :flock :seek);

use constant DEBUG	=> 1;

sub new {
	my $class=shift;
	my ($cfg)=@_;


	# XXX move to superclass START
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
	# XXX move to superclass END

			$self->{seen_urls} = {};
    $self->{item_num} = 1;

	return $self;
}

sub save_item {
	my $self=shift;
	my ($item)=@_;

	use Data::Dumper;
	warn Dumper($item);
	my $comic_dir = $self->{cfg}{items_dir};

				next if ($self->{seen_urls}{$item->{url}});
				$self->{seen_urls}{$item->{url}} = 1;

				my $file_name = $self->get_file_name($item);

				if (!-f $comic_dir.'/'.$file_name) {
					eval {
						Agg::Download->mirror($item->{url},
							$comic_dir.'/'.$file_name, 0);
					};
					if ($@) {
						warn "Can't fetch picture [$@], skip...";
					}
				}
	$self->save_item_data($item);
}

### get_file_name ####### #+++1
sub get_file_name {
	my $self = shift;
	my $item = shift;

	my $guids = $self->{guids};
	my $filename;

	# if we already seen this url, just return the corresponding
	# filename
	if (defined $guids->{$item->{guid}}) {
		warn "Already seen this file" if (DEBUG);
		$filename = $guids->{$item->{guid}};
		return $filename;
	}

	warn "New file" if (DEBUG);
	my $number = sprintf('%.3d', $self->{item_num});
	if (defined($item->{date})) {
		$filename = $item->{date}
					.'-'.$number.'.'.$item->{ext};
	}
	else {
		$filename = strftime('%Y-%m-%d', localtime())
					.'-'.$number.'.'.$item->{ext};
	}

	$guids->{$item->{guid}} = $filename;

	return $filename;
}
#---1
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


sub finish {}

1;
