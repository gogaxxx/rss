#
# скачивает картинки чтоб показывать их локально
#
package Agg::Transform::LocalImages;

use strict;
use warnings;

use Agg::Download;
use Digest::MD5 qw(md5_hex);
use File::Copy;
use HTML::Parser;
use constant DEBUG => 0;

# new #+++1 
sub new {
    my $class=shift;
    my $cfg  =shift;

    my $self = bless {}, $class;

	my $ua = Agg::Download->new($cfg);

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

	if ($self->{cfg}{url} =~ m{^http://([^/]+)}o) {
		$self->{host} = $1;
	}

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
	
	$parser->{'used-images'} = {};
    $parser->{OUTPUT} = '';
	$parser->parse($item->{body});
    $parser->eof();
	$item->{body} = $parser->{OUTPUT};
	$item->{'used-images'} = join(',', 
		keys %{$parser->{'used-images'}});

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
	my $loader = $self->{transformer}{loader};
	$loader->cache($url);
	my $filename = $loader->{'hash'};
    my $full_path =
        $self->{transformer}{'imgdir'}.'/'.$filename;
	copy($loader->full_path, $full_path);

	$attr->{src} = $self->{'transformer'}{'imgurl'}.'/'.$filename;
	my $text = '<img '.
		join(' ', map {$_.'="'.$attr->{$_}.'"'} keys %$attr).'>';

	warn "[Agg::Download::load_img] text=$text" if (DEBUG);
	$self->{'used-images'}{$filename} = 1;

    return $text;
}

### default  ####### #+++1
sub default {
	my ($self, $text)=@_;

	$self->{OUTPUT} .= $text;
}

#---1

1;
