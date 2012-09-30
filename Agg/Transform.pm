package Agg::Transform;

use strict;
use warnings;

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self = bless { cfg => $cfg}, $class;

	my $chain = $cfg->{transform};
	my @classes_chain = split(/\s*,\s*/o, $chain);

	my @transformers_chain = ();
	for my $tclass (@classes_chain) {
		my $full_class='Agg::Transform::'.$tclass;
		eval "require $full_class";

		my $tr = $full_class->new($cfg);
		push @transformers_chain, $tr;
	}
	$self->{chain} = \@transformers_chain;

	return $self;
}

# transform_item #+++1
sub transform_item {
	my $self=shift;
	my $item = shift;

	for my $tr (@{$self->{chain}}) {
		$item = $tr->transform_item($item);
	}
	return $item;
}

1;
