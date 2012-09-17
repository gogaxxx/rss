package Agg::Parser::XML;

use strict;

use base qw(Agg::Parser::Super);
use Agg::Saver::RSS;
use XML::Parser;

sub init_parser {
	my $self=shift;
	return XML::Parser->new();
}

sub init_saver {
	my $self=shift;
	return Agg::Saver::RSS->new(@_);
}

#---1

1;
