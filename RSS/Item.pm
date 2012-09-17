#
package RSS::Item;

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

    my $out_subject = Encode::encode('utf-8', $item->{subject});
    my $out_body    = Encode::encode('utf-8', $item->{body});

    open (OUT, '>' . $self->{cfg}{items_dir} . '/'. $item->{'name'});
	print OUT 'name: ',		$item->{name},		"\n";
	print OUT 'guid: ',		$item->{guid},		"\n";
	print OUT 'link: ', 	$item->{link},		"\n";
	print OUT 'time: ', 	$item->{time},		"\n";
	print OUT 'subject: ', 	$out_subject,		"\n";
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
