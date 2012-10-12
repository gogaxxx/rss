#
#
#

package Agg::Transform::TheRegister;

use strict;
use warnings;

### new ####### #+++1
sub new {
    my $class=shift;
    my $cfg  =shift;

	return bless {
		cfg=>$cfg
	}, $class;
}

### transform_item ####### #+++1
sub transform_item {
	my $self=shift;
	my $item = shift;

	$item->{'link'} .= '/print.html';
	return $item;
}

#---1

1;
