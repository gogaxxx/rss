package Agg::Parser::XML;

use strict;

use Agg::Saver::RSS;
use XML::Parser;

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self=bless {}, $class;

    $self->{parser} = XML::Parser->new();
	$self->{saver}  = Agg::Saver::RSS->new($cfg);
	$self->{parser}{saver} = $self->{saver};
	$self->{cfg} = $cfg;

	return $self;
}
# parse #+++1
sub parse { #XXX перенести в суперкласс
	my $self=shift;

	$self->{parser}->parse($self->{cfg}{content});
	$self->{saver}->finish();
}

#---1

1;
