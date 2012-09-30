#
# скачивает картинки чтоб показывать их локально
#
package Agg::Transform::LocalImages;

use strict;
use Digest::MD5 qw(md5_hex);
use HTML::Parser;
use LWP::UserAgent;

# new #+++1 
sub new {
    my $class=shift;
    my $cfg  =shift;

    my $self = bless {}, $class;

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;

    my $parser = HTML::Parser->new(
		xml_mode => 1,
		case_sensitive => 0,
		start_h => [ \&start,   'self,tagname, attr, text'],
		default_h => [ \&default, 'self,text' ]
    );

    $self->{cfg}    = $cfg;
    $self->{loader} = $ua;
    $self->{parser} = $parser;

    $self->{parser}{transformer} = $self;

    $self->{'imgurl'} = $cfg->{'imgdir'};
    $self->{'imgdir'} = $cfg->{'readdir'}.'/'.$cfg->{'imgdir'};
    mkdir($self->{'imgdir'}); # fail silently

    return $self;
}

# transform_item #+++1 
sub transform_item {
    my $self=shift;
    my $item = shift;

    my $parser = $self->{parser};

    $parser->{OUTPUT} = '';
	$parser->parse($item->{body});
    $parser->eof();
	$item->{body} = $parser->{OUTPUT};

    return $item;
}

### start  ####### #+++1
sub start {
	my ($self, $tagname, $attr, $text)=@_;

	if ($tagname eq 'img') {
		$text = load_img($self, $attr);
	}
	default($self, $text);
}

# load_img #+++1
sub load_img {
    my ($self, $attr) = @_;

    my $url = $attr->{src};
    my $filename = md5_hex($url);
    my $full_path =
        $self->{transformer}{'imgdir'}.'/'.$filename;
    warn "filename=$filename\n";
    warn "url=".$attr->{src}."\n";
    $self->{transformer}{loader}->mirror($url, $full_path);
    my $text = '<img src="'.$self->{'transformer'}{'imgurl'}.'/'.$filename.'">';

    return $text;
}

### default  ####### #+++1
sub default {
	my ($self, $text)=@_;

	$self->{OUTPUT} .= $text;
}

#---1

1;
