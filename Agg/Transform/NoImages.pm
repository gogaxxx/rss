#
#
#

package Agg::Transform::NoImages;

use strict;
use warnings;

# new #+++1 
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self=bless {
		cfg => $cfg}, $class;
	return $self;
}

# transform_item #+++1
sub transform_item {
	my $self=shift;
	my $item = shift;

	$item->{'body'} =~ s/<img[^>]+>//go;
	return $item;
}

1;
