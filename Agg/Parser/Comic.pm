package Agg::Parser::Comic;

use strict;
use base qw(Agg::Parser::Super);
use Agg::Saver::Comic;
use HTML::Parser;

sub image { ('img', 'src')}

sub init_parser {
	my $self=shift;

	my $parser = HTML::Parser->new(
		start_h => [\&start_tag, 'self, tagname, attr']
	);
	$parser->{self}=$self;
	($self->{image_tag}, $self->{image_attr}) =
		map {lc($_)} $self->image;

	return $parser;
}

sub init_saver {
	my $self=shift;
	return Agg::Saver::Comic->new(@_);
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
		$found->{url} ||= $url;
		$found->{time}	= $found->{date} || 0; # XXX сделать что-то
												#осмысленное
		$found->{guid}	= $url;
		$parser->{saver}->save_item($found);
	}
}

#sub check {
#	my $self=shift;
#	die("Override ${self}::check");
#}
sub check {
	my ($class, $url)=@_;
	# warning! subdomain "zii" may change I'm sure
	if ($url =~ m!^http://zii\.menagea3\.net/comics/mat(\d\d\d\d)(\d\d)(\d\d)\.([^"]+)$!o) {
		return {
			ext => $4,
			date => $1.'-'.$2.'-'.$3
		}
	}
}

1;
