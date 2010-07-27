#
# $Id$
#

package XML::Detector;

use strict;
use warnings;

sub new {
	my $class=shift;

	my $self=bless {}, $class;
	return $self;
}

sub detect {
	my $self=shift;
	my $content=shift;

	my $b = 0;

	# найти первый тег
	while ($b >= 0 && substr($content, $b+1, 1) !~ /[a-zA-Z]/o) {
		$b = index($content, '<', $b+1);
	}

	if ($b < 0) {
		return 'error';
	}

	if (lc(substr($content, $b, length('<rss'))) eq '<rss'
		||
		lc(substr($content, $b, length('<rdf:rdf'))) eq '<rdf:rdf')
	{
		return 'rss';
	}
	elsif (lc(substr($content, $b, length('<feed'))) eq '<feed') 
	{
		return 'atom';	
	}
	else 
	{
		return 'error';
	}
}

1;
