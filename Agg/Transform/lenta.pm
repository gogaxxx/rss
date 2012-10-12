#
# делаем ссылку на версию для печати
#

package Agg::Transform::lenta;

use strict;
use warnings;

sub new {
	my ($class, $cfg)=@_;

	return bless {
				  cfg=>$cfg}, $class;
}

sub transform_item {
	my $class=shift;
	my $item = shift;

	$item->{link} .= '/_Printed.htm';
	return $item;
}

1;
