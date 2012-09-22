package Agg::Transform;

use strict;
use warnings;

# plugins
use Agg::Transform::Idiot;

# transform_item #+++1
sub transform_item {
	my $item = shift;
	# для всех: сцылки на youtube прописываем явно в тексте
	my @videos = ();
	while ($item->{body} =~ m{<[^>]+\=['"]?(http://(?:[^\.]+\.)?youtube\.com/[^'"\s>]+)}sg) { 
		push @videos, $1;
	}
	$item->{body} .= '<br>'.join('<br>', map { 'Video: '.$_} @videos);

	if ($item->{link} =~ /theregister\.com/o) {
		# делать линк на печатную версию вместо обычной
		$item->{link} .= '/print.html';
	}
	elsif ($item->{link} =~ /lj\.rossia\.org/o) {
		# ljro shit # XXX dirty hack
		$item->{body} =~ s/<\/?font[^>]*>//g;
	}
	elsif ($item->{link} =~ /idiottoys\.com/o) {
		Agg::Transform::Idiot::transform($item);
	}
} 

#---1

1;
