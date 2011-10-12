package Agg::Config;

use strict;
use warnings;

use cfg;

my @fields = qw(name type url);

# get_config_by_id #+++1
sub get_config_by_id {
	my $class=shift;
	my $id = shift;

	my $self = bless {}, $class;
	
	$self->{config_dir} = $cfg::config_dir.'/'.$id;
	my $config_filename = $self->{config_dir}.'/config';
	open(FILE, '<', $config_filename)
		or die("Can't open $config_filename: $!");
	while(my $line = <FILE>) {
		chomp $line;

		my @pair = split(/=/, $line, 2);
		$self->{$pair[0]} = $pair[1];
	}
	close FILE;

	for my $f (@fields) {
		if (!defined($self->{$f})
			|| $self->{$f} eq '')
		{
			warn("Field $f empty!");
		}
	}
	$self->{cache} = $self->{config_dir}.'/cache';

	return $self;
}

#---1
1;
