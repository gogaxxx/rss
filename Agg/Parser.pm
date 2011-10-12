package Agg::Parser;

my %parsers = (
	atom => 'Agg::Parser::Atom'
);

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $type = $cfg->{type};
	my $class = $parsers{$type};

	eval "require $class";
	return $class->new($cfg);
}

#---1

1;
