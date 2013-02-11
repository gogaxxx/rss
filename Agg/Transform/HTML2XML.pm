#
# $Id$
#

package Agg::Transform::HTML2XML;

use strict;
use warnings;

use HTML::Parser;

my @single_tags = qw(
	img br hr wbr
);

# полный список html сущностей #+++
# украдено с http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
my %entities = ( 
	amp      => 'amp',
	lt       => 'lt',
	gt       => 'gt',
	quot     => 'quot',
	apos     => 'apos',
	nbsp     => '#x00A0',
	iexcl    => '#x00A1',
	cent     => '#x00A2',
	pound    => '#x00A3',
	curren   => '#x00A4',
	yen      => '#x00A5',
	brvbar   => '#x00A6',
	sect     => '#x00A7',
	uml      => '#x00A8',
	copy     => '#x00A9',
	ordf     => '#x00AA',
	laquo    => '#x00AB',
	not      => '#x00AC',
	shy      => '#x00AD',
	reg      => '#x00AE',
	macr     => '#x00AF',
	deg      => '#x00B0',
	plusmn   => '#x00B1',
	sup2     => '#x00B2',
	sup3     => '#x00B3',
	acute    => '#x00B4',
	micro    => '#x00B5',
	para     => '#x00B6',
	middot   => '#x00B7',
	cedil    => '#x00B8',
	sup1     => '#x00B9',
	ordm     => '#x00BA',
	raquo    => '#x00BB',
	frac14   => '#x00BC',
	frac12   => '#x00BD',
	frac34   => '#x00BE',
	iquest   => '#x00BF',
	Agrave   => '#x00C0',
	Aacute   => '#x00C1',
	Acirc    => '#x00C2',
	Atilde   => '#x00C3',
	Auml     => '#x00C4',
	Aring    => '#x00C5',
	AElig    => '#x00C6',
	Ccedil   => '#x00C7',
	Egrave   => '#x00C8',
	Eacute   => '#x00C9',
	Ecirc    => '#x00CA',
	Euml     => '#x00CB',
	Igrave   => '#x00CC',
	Iacute   => '#x00CD',
	Icirc    => '#x00CE',
	Iuml     => '#x00CF',
	ETH      => '#x00D0',
	Ntilde   => '#x00D1',
	Ograve   => '#x00D2',
	Oacute   => '#x00D3',
	Ocirc    => '#x00D4',
	Otilde   => '#x00D5',
	Ouml     => '#x00D6',
	times    => '#x00D7',
	Oslash   => '#x00D8',
	Ugrave   => '#x00D9',
	Uacute   => '#x00DA',
	Ucirc    => '#x00DB',
	Uuml     => '#x00DC',
	Yacute   => '#x00DD',
	THORN    => '#x00DE',
	szlig    => '#x00DF',
	agrave   => '#x00E0',
	aacute   => '#x00E1',
	acirc    => '#x00E2',
	atilde   => '#x00E3',
	auml     => '#x00E4',
	aring    => '#x00E5',
	aelig    => '#x00E6',
	ccedil   => '#x00E7',
	egrave   => '#x00E8',
	eacute   => '#x00E9',
	ecirc    => '#x00EA',
	euml     => '#x00EB',
	igrave   => '#x00EC',
	iacute   => '#x00ED',
	icirc    => '#x00EE',
	iuml     => '#x00EF',
	eth      => '#x00F0',
	ntilde   => '#x00F1',
	ograve   => '#x00F2',
	oacute   => '#x00F3',
	ocirc    => '#x00F4',
	otilde   => '#x00F5',
	ouml     => '#x00F6',
	divide   => '#x00F7',
	oslash   => '#x00F8',
	ugrave   => '#x00F9',
	uacute   => '#x00FA',
	ucirc    => '#x00FB',
	uuml     => '#x00FC',
	yacute   => '#x00FD',
	thorn    => '#x00FE',
	yuml     => '#x00FF',
	OElig    => '#x0152',
	oelig    => '#x0153',
	Scaron   => '#x0160',
	scaron   => '#x0161',
	Yuml     => '#x0178',
	fnof     => '#x0192',
	circ     => '#x02C6',
	tilde    => '#x02DC',
	Alpha    => '#x0391',
	Beta     => '#x0392',
	Gamma    => '#x0393',
	Delta    => '#x0394',
	Epsilon  => '#x0395',
	Zeta     => '#x0396',
	Eta      => '#x0397',
	Theta    => '#x0398',
	Iota     => '#x0399',
	Kappa    => '#x039A',
	Lambda   => '#x039B',
	Mu       => '#x039C',
	Nu       => '#x039D',
	Xi       => '#x039E',
	Omicron  => '#x039F',
	Pi       => '#x03A0',
	Rho      => '#x03A1',
	Sigma    => '#x03A3',
	Tau      => '#x03A4',
	Upsilon  => '#x03A5',
	Phi      => '#x03A6',
	Chi      => '#x03A7',
	Psi      => '#x03A8',
	Omega    => '#x03A9',
	alpha    => '#x03B1',
	beta     => '#x03B2',
	gamma    => '#x03B3',
	delta    => '#x03B4',
	epsilon  => '#x03B5',
	zeta     => '#x03B6',
	eta      => '#x03B7',
	theta    => '#x03B8',
	iota     => '#x03B9',
	kappa    => '#x03BA',
	lambda   => '#x03BB',
	mu       => '#x03BC',
	nu       => '#x03BD',
	xi       => '#x03BE',
	omicron  => '#x03BF',
	pi       => '#x03C0',
	rho      => '#x03C1',
	sigmaf   => '#x03C2',
	sigma    => '#x03C3',
	tau      => '#x03C4',
	upsilon  => '#x03C5',
	phi      => '#x03C6',
	chi      => '#x03C7',
	psi      => '#x03C8',
	omega    => '#x03C9',
	thetasym => '#x03D1',
	upsih    => '#x03D2',
	piv      => '#x03D6',
	ensp     => '#x2002',
	emsp     => '#x2003',
	thinsp   => '#x2009',
	zwnj     => '#x200C',
	zwj      => '#x200D',
	lrm      => '#x200E',
	rlm      => '#x200F',
	ndash    => '#x2013',
	mdash    => '#x2014',
	lsquo    => '#x2018',
	rsquo    => '#x2019',
	sbquo    => '#x201A',
	ldquo    => '#x201C',
	rdquo    => '#x201D',
	bdquo    => '#x201E',
	dagger   => '#x2020',
	Dagger   => '#x2021',
	bull     => '#x2022',
	hellip   => '#x2026',
	permil   => '#x2030',
	prime    => '#x2032',
	Prime    => '#x2033',
	lsaquo   => '#x2039',
	rsaquo   => '#x203A',
	oline    => '#x203E',
	frasl    => '#x2044',
	euro     => '#x20AC',
	image    => '#x2111',
	weierp   => '#x2118',
	real     => '#x211C',
	trade    => '#x2122',
	alefsym  => '#x2135',
	larr     => '#x2190',
	uarr     => '#x2191',
	rarr     => '#x2192',
	darr     => '#x2193',
	harr     => '#x2194',
	crarr    => '#x21B5',
	lArr     => '#x21D0',
	uArr     => '#x21D1',
	rArr     => '#x21D2',
	dArr     => '#x21D3',
	hArr     => '#x21D4',
	forall   => '#x2200',
	part     => '#x2202',
	exist    => '#x2203',
	empty    => '#x2205',
	nabla    => '#x2207',
	isin     => '#x2208',
	notin    => '#x2209',
	ni       => '#x220B',
	prod     => '#x220F',
	sum      => '#x2211',
	minus    => '#x2212',
	lowast   => '#x2217',
	radic    => '#x221A',
	prop     => '#x221D',
	infin    => '#x221E',
	ang      => '#x2220',
	and      => '#x2227',
	or       => '#x2228',
	cap      => '#x2229',
	cup      => '#x222A',
	int      => '#x222B',
	there4   => '#x2234',
	sim      => '#x223C',
	cong     => '#x2245',
	asymp    => '#x2248',
	ne       => '#x2260',
	equiv    => '#x2261',
	le       => '#x2264',
	ge       => '#x2265',
	'sub'    => '#x2282',
	sup      => '#x2283',
	nsub     => '#x2284',
	sube     => '#x2286',
	supe     => '#x2287',
	oplus    => '#x2295',
	otimes   => '#x2297',
	perp     => '#x22A5',
	sdot     => '#x22C5',
	lceil    => '#x2308',
	rceil    => '#x2309',
	lfloor   => '#x230A',
	rfloor   => '#x230B',
	lang     => '#x2329',
	rang     => '#x232A',
	loz      => '#x25CA',
	spades   => '#x2660',
	clubs    => '#x2663',
	hearts   => '#x2665',
	diams    => '#x2666',
); #---
my %automaton = (
	def => \&a_def,
	ent => \&a_ent,
);

### new #+++1
sub new {
    my $class=shift;
    my $cfg  =shift;

    my $self = bless {}, $class;
    $self->{cfg}    = $cfg;

	my $parser = HTML::Parser->new(
		start_h        => [ \&start_h, "self,tagname,attr,attrseq,text" ],
		end_h          => [ \&end_h, "self,tagname" ],
		text_h         => [ \&text, "self,text" ]);
    $self->{parser} = $parser;

	return $self;
}

### transform_item #+++1
sub transform_item {
    my $self=shift;
    my $item = shift;

    my $parser = $self->{parser};
	$parser->{stack} = [];
    $parser->{OUTPUT} = '';

	$parser->parse($item->{body});
    $parser->eof();

	$item->{body} = $parser->{OUTPUT};

    return $item;
}

### start_h #+++1
sub start_h {
	my ($self, $tagname, $attr, $attrseq, $text)=@_;

	my $lt = lc($tagname);
	if (grep {$_ eq $lt} @single_tags) {
		$self->{OUTPUT} .= print_tag($tagname, $attr, $attrseq, 'yes');
	}
	else {
		push @{$self->{stack}}, $lt;
		$self->{OUTPUT} .= print_tag($tagname, $attr, $attrseq);
	}
}

### end_h #+++1
sub end_h {
	my ($self, $tagname)=@_;
	my $lt = lc($tagname);

	my $tag;
	while (@{$self->{stack}}) {
		$tag = pop @{$self->{stack}};
		$self->{OUTPUT} .= '</'.$tag.'>';
		last if ($tag eq $lt);
	}
}

### text #+++1
sub text {
	my ($self, $text)=@_;

	$self->{OUTPUT} .= replace_entities($text);
}

### replace_entities #+++1
sub replace_entities {
	my $text = shift;

	my $len = length($text);
	my $mode = 'def';
	my $acc = '';

	my $out = '';
	my $ret;
	for (my $i = 0; $i < $len; $i++) {
		my $char = substr($text, $i, 1);

		($mode, $ret, $acc) = $automaton{$mode}->($char, $acc);
		$out .= $ret;
	}
	($mode, $ret, $acc) = $automaton{$mode}->('<eol>', $acc);
	$out .= $ret;

	return $out;
}

### a_def #+++2
sub a_def {
	my ($char, $acc)=@_;

	if ($char eq '&') {
		return ('ent', '', '');
	}
	elsif ($char eq '<eol>') {
		return ('def', '', '');
	}
	else {
		return ('def', $char, '');
	}
}

### a_ent #+++2
sub a_ent {
	my ($char, $acc)=@_;

	if ($char eq ';') {
		# нормальная сущность, заменить по таблице если есть
		my $ret = exists $entities{$acc}
			? '&'.$entities{$acc}.';'
			: '';
		return ('def', $ret, '');
	}
	elsif ($char eq '&' || $char eq '<eol>') {
		return ('ent', '&amp;'.$acc, '');
	}
	else {
		return ('ent', '', $acc.$char);
	}
}

### print_tag #+++1
sub print_tag {
	my ($tagname, $attr, $attrseq, $single)=@_;

	my $code = 
		join(' ', 
			'<'.$tagname, 
			map { $_ eq '/' ? '' : $_.q{="}.replace_entities($attr->{$_}).q{"}} @$attrseq)
		.($single ? '/' : '').'>';
}

1;
