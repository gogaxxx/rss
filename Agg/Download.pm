#
#
#

package Agg::Download;

use Digest::MD5 qw(md5_hex);
use File::Path qw(make_path);
use LWP::UserAgent;
use constant DEBUG=>0;

use constant GZIP => q{/usr/bin/gzip -S '' -f -d };
use constant DOWNLOAD_CMD =>
	'curl -s -LR --url %url -o %file -z %file';

use strict;

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;
	$ua->agent($cfg->{'user-agent'});

	my $cmd_tpl = $cfg->{'download-command'} || DOWNLOAD_CMD;
	my @cmd = split(/\s+/o, $cmd_tpl);
	my @urlpos=();
	my @filepos=();
	for (my $i=0; $i<@cmd; $i++) {
		if ($cmd[$i] eq '%url') {
			push @urlpos, $i;
		}
		elsif ($cmd[$i] eq '%file') {
			push @filepos, $i;
		}
	}

	my $self = bless {
		ua => $ua,
		cmd_tpl => \@cmd,
		filepos => \@filepos,
		urlpos	=> \@urlpos,
		root	=> $cfg->{'cache-root'},
		cfg => $cfg}, $class;

	return $self;
}

#mirror #+++1
sub mirror {
	my $self=shift;
	my ($url, $filename, $return_content)=@_;

	$url ||= $self->{'url'};
	$filename ||= $self->{'full_path'};
	$return_content //= 1;

	warn "getting [$url]" if (DEBUG);
	$self->_mirror_download($url, $filename);

#		if ($response->{'_headers'}{'content-encoding'} eq 'gzip') {
#			warn 'GZIPPED!';
#			system(GZIP.' '.$filename);
#		}

	if ($return_content) {
		return _slurp($filename);
	}
}

# prepare #+++1
sub prepare {
	my $self=shift;
	my ($url)=@_;

	unless ($url =~ m{^http(s?)://}) {
		$url = 'http://'.$self->{'transformer'}{'host'}.$url;
	}
	$self->{'url'} = $url;

    my $hash = md5_hex(Encode::encode($self->{'cfg'}{'encoding'}, $url)); # дурь
	$self->{'hash'} = $hash;
	my $dir1 = substr($hash, 0, 2);
	my $dir2 = substr($hash, 2, 2);
	my $filename = substr($hash, 4);
	my $dir = $self->{'root'}.'/'.$dir1.'/'.$dir2;
	$self->{'dir'} = $dir;

	unless (-d $dir) {
		make_path($dir);
	}

    my $full_path = $dir.'/'.$filename;
	$self->{'full_path'} = $full_path;
}

# load #+++1 
#
# всегда грузит локальную копию если она есть
# если нет, скачивает с урла
#
sub load {
	my $self=shift;
	my $url = shift;

	$self->prepare($url);
	my $filename = $self->{'full_path'};
	if (!-e $filename) {
		$self->_mirror_download($url, $filename);
	}

	return _slurp($filename);
}

# fetch #+++1
#
# загрузить актуальную версию с урла, всегда проверяет на изменение
#
sub fetch {
	my $self=shift;
	my $url = shift;

	$self->prepare($url);
	my $filename = $self->{'full_path'};
	$self->_mirror_download($url, $filename);
	return _slurp($filename);
}

# cache #+++1 
#
# загрузить актуальную версию с урла, всегда проверяет на изменение, но
# содержимое не возвращает
#
sub cache {
	my $self=shift;
	my $url=shift;

	$self->prepare($url);
	my $filename = $self->{'full_path'};
	$self->_mirror_download($url, $filename);
	return $filename;
}

# _slurp #+++1
sub _slurp {
	my $filename = shift;

	my $content = '';
	open(FILE, '<'.$filename) ||
		die("[Agg::Download::mirror] Can't open $filename: $!");
	$content = join('', <FILE>);
	close FILE;

	return $content;
}

### _mirror_download ####### #+++1
sub _mirror_download {
	my $self=shift;
	my ($url, $filename)=@_;

	my $cmd=$self->{cmd_tpl};

	for my $f (@{$self->{'filepos'}}) {
		$cmd->[$f] = $filename;
	}
	for my $u (@{$self->{'urlpos'}}) {
		$cmd->[$u] = $url;
	}

	warn "cmd=".join(':', @$cmd) if (DEBUG);
	system(@$cmd);

	if ($? == -1) {
		die "failed to execute: $!"; }
	elsif ($? & 127) {
		# чтоб сдыхала сразу при нажатии ^C
		die(sprintf("cmd died with signal %d, %s coredump\n",
		   ($? & 127),  ($? & 128) ? 'with' : 'without'));
	}
}

#---1

1;
