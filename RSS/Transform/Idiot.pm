package RSS::Transform::Idiot;

use HTML::Parser;

# transform#+++1
sub transform {
	my $item=shift;

	my $parser = HTML::Parser->new(
		xml_mode => 1,
		case_sensitive => 0,
		start_h => [ \&idiot_start,   'self,tagname, attr, text'],
		default_h => [ \&idiot_default, 'self,text' ]
	);

	$parser->{OUTPUT} = '';
	$parser->parse($item->{body});

	$item->{body} = $parser->{OUTPUT};
}

### idiot_start  ####### #+++1
sub idiot_start {
	my ($self, $tagname, $attr, $text)=@_;

	my $t1;
	if ($tagname eq 'img') {
		$t1 = idiot_tr_link('img', 'src', $attr);
	}
	elsif ($tagname eq 'a') {
		$t1 = idiot_tr_link('a', 'href', $attr);
	}
	$text = 
		$t1 ? $t1 : $text;
	idiot_default($self, $text);
}
### idiot_tr_link  ####### #+++1
sub idiot_tr_link {
	my ($tagname, $href_name, $attr)=@_;

	if ($attr->{$href_name} !~ m{^http://}o) {
		$attr->{$href_name} =
			'http://www.idiottoys.com'.$attr->{$href_name};
		return join(' ', '<'.$tagname,
						(map {
							$_.'="'.$attr->{$_}.'"'
						} keys %$attr)). '>';
	}
	return undef;
}
### idiot_default  ####### #+++1
sub idiot_default {
	my ($self, $text)=@_;

	$self->{OUTPUT} .= $text;
}
#---1

1;
