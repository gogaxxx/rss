package Agg::Parser::Comic;

use strict;

sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self = {
		cache_dir => $c
	};

	bless($self, $class);

	$self->{parser} = $self->init_parser();

	return $self;
}

sub cache_dir {
	return shift->{cache_dir};
}

sub fetch {
	my $self=shift;

	warn "[Comics::fetch] start" if (DEBUG);
	my $html = mirror($self->url(), $self->cache_dir.'/'.$self->name.'.html');
	warn "[Comics::fetch] fetched url" if (DEBUG);

	$parser->parse($html);
	$self->post_process();

	return $self->{found};
}

sub image { ('img', 'src')}
sub post_process {}

sub init_parser {
	my $self=shift;

	my $parser = HTML::Parser->new(
		start_h => [\&start_tag, 'self, tagname, attr']
	);
	$parser->{self}=$self;
	$self->{num}  =1;
	($self->{image_tag}, $self->{image_attr}) =
		map {lc($_)} $self->image;

	return $parser;
}

sub start_tag {
	my ($parser, $tagname, $attr)=@_;

	if (lc($tagname) eq $parser->{self}{image_tag}) {
		image_check(@_);
	}
}

sub image_check {
	my ($parser, $tagname, $attr)=@_;

	my $self=$parser->{self};
	my $url = $attr->{$self->{image_attr}};
	if (my $found = $self->check($url)) {
		$found->{num} ||= $self->{num}++;
		$found->{url} ||= $url;
		push @{$self->{found}}, $found;
	}
}

sub check {
	my $self=shift;
	die("Override ${self}::check");
}

1;
