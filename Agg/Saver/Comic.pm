package Agg::Saver::Comic;

use strict;
use base qw(Agg::Saver);

use AnyDBM_File;
use Fcntl qw(:DEFAULT :flock :seek);

use constant DEBUG	=> 1;

sub new {
	my $class=shift;

	my $self = $class->SUPER::new(@_);

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


1;
