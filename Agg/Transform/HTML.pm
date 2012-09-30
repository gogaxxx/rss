#
# трансформер для создания html-файлов пригодных для чтения на
# pocketbook
#

package Agg::Transform::HTML;

use strict;
use warnings;

# new #+++1
sub new {
	my $class=shift;

	my $self=bless {}, $class;
	return $self;
}

# transform_item #+++1
sub transform_item {
	my $self=shift;
	my $item = shift;

	# замена простая, так что HTML::Parser применять не будем
	$item->{body} =~ s{(</[hH][12345]>)}{<br>$1}go;

	return $item;
}

#---1

1;
