package Agg::Parser::Super;

use strict;

#new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self = bless {}, $class;

	$self->{parser} = $self->init_parser($cfg);
	$self->{saver}  = $self->init_saver($cfg);
	$self->{parser}{saver} = $self->{saver};
	$self->{cfg}	= $cfg;

	return $self;
}

# parse #+++1
sub parse {
	my $self=shift;

	$self->{parser}->parse($self->{cfg}{content});
	$self->{saver}->finish();
}


#---1

1;
