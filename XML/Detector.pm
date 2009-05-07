#
# $Id: Detector.pm 29 2009-02-20 20:35:05Z nephrite $
#

package XML::Detector;

use strict;
use fields qw(type);

use XML::Parser::Expat;
use base qw(XML::Parser::Expat);

sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);
	$self->reset();

	return $self;
}

sub detect {
	my $self=shift;
	my $content = shift;

	$self->reset();
	$self->parse($content);

	return $self->{type};
}

sub reset {
	my $self=shift;
	undef $self->{type};
	$self->setHandlers(Start => \&handle_start);
}

sub handle_start {
	my ($exp, $el)=@_;

	$el = lc($el);
	if ($el eq 'rss'
        || $el eq 'rdf:rdf') 
    {
		$exp->{type} = 'rss';
		$exp->finish;
	}
	elsif ($el eq 'feed') {
		$exp->{type} = 'atom';
		$exp->finish;
	}
	else {
		$exp->{type} = 'error';
		$exp->finish();
	}
}

1;
