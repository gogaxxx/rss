#
package Agg::Item;

use strict;
use warnings;

use Date::Parse;
use Encode;

sub new {
	my $class=shift;
	my $cfg = shift;

	my $self = bless {
		cfg => $cfg}, $class;
	return $self;
}

### save_item ####+++1
sub save_item {
	my $self=shift;
    my ($item)=@_;

    $item->{'time'} = 
		$item->{date}
			?  str2time($item->{date})
			:  time();

    my $out_body    = Encode::encode('utf-8', $item->{body});

    open (OUT, '>' . $self->{cfg}{items_dir} . '/'. $item->{'name'});
	while (my ($k, $v) = each %$item) {
		next if ($k eq 'body');

		print OUT ($k, ': ', Encode::encode('utf-8', $v), "\n");
	}
	print OUT "\n", $out_body;
	close OUT;
}

### load_item ####+++1
sub load_item {
	my $self=shift;
	my $id = shift;

	my $filename = $self->{cfg}{items_dir} . '/'. $id;
	my $item = {};
	open (IN, '<'.$filename) || die("Can't open $filename: $!");
	# headers
	while (my $line = <IN>) {
		chomp $line;

		last if ($line =~ /^\s*$/o);

		my $in_line = Encode::decode('utf-8', $line);
		my ($name, $content) = split(/:\s+/o, $in_line, 2);
		$item->{$name} = $content;
	}

	my $body = '';
	while (my $line = <IN>) {
		$body .= Encode::decode('utf-8', $line);
	}
	$item->{body} = $body;
	close IN;

	return $item;
}

#---1

1;