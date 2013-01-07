#
#
#

package Agg::Download;

use Digest::MD5 qw(md5_hex);
use Encode;
use File::Path qw(make_path);
use POSIX qw(:errno_h);
use constant DEBUG=>0;

use constant GZIP => q{/usr/bin/gzip -S '' -f -d };
use constant DOWNLOAD_CMD =>
	'curl -s -LR --url %url -o %file -z %file';

use strict;

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

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
		cmd_tpl => \@cmd,
		filepos => \@filepos,
		urlpos	=> \@urlpos,
		'cache-dir'	=> $cfg->{'cache-dir'},
		cfg => $cfg}, $class;

	return $self;
}

#mirror #+++1
sub mirror {
	my $self=shift;
	my ($url, $filename, $return_content)=@_;

	$url ||= $self->{'url'};
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
		$url = 'http://'.$url;
	}

	my ($host, $uri);
	if ($url =~ m{^http(?:s?)://([^/]+)(.*)$}) {
		$host = $1;
		$uri  = $2;
	}

	if ($uri =~ /(\.[^\.]+)$/) {
		$self->{'extension'} = $1;
	}
	else {
		$self->{'extension'} = '';
	}
	$self->{'url'} = $url;

    my $hash = md5_hex(Encode::encode($self->{'cfg'}{'encoding'}, $url)); # дурь
	$self->{'hash'} = $hash;
	my $dir1 = substr($hash, 0, 2);
	my $dir2 = substr($hash, 2, 2);
	my $filename = substr($hash, 4).$self->{'extension'};
	my $dir = $self->{'cache-dir'}.'/'.$dir1.'/'.$dir2;
	$self->{'dir'} = $dir;

	unless (-d $dir) {
		make_path($dir);
	}

    my $full_path = $dir.'/'.$filename;
	$self->{'full_path'} = $full_path;
}

# fetch_cached #+++1 
#
# всегда грузит локальную копию если она есть
# если нет, скачивает с урла
#
sub fetch_cached {
	my $self=shift;
	my $url = shift;

	$self->cache($url);
	return _slurp($self->{'full_path'});
}

# cache #+++1
sub cache {
	my $self=shift;
	my $url = shift;

	$self->prepare($url);
	my $filename = $self->{'full_path'};
	if (!-e $filename) {
		$self->_mirror_download($url, $filename);
	}
}

# fetch_recent #+++1
#
# загрузить актуальную версию с урла, всегда проверяет на изменение
#
sub fetch_recent {
	my $self=shift;
	my $url = shift;

	$self->prepare($url);
	my $filename = $self->{'full_path'};
	$self->_mirror_download($url, $filename);
	return _slurp($filename);
}

# accessors #+++1 
sub full_path { shift->{'full_path'}}

# _slurp #+++1
sub _slurp {
	my $filename = shift;

	my $content = '';
	open(FILE, '<'.$filename) ||
		die("[Agg::Download::_slurp] Can't open $filename: $!");
	$content = join('', <FILE>);
	close FILE;

	return $content;
}

### _mirror_download ####### #+++1
sub _mirror_download {
	my $self=shift;
	my ($url, $filename)=@_;

	warn "url=$url" if (DEBUG);
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
		die "failed to execute: $!" if ($! != ECHILD);
	}
	elsif ($? & 127) {
		# чтоб сдыхала сразу при нажатии ^C
		die(sprintf("cmd died with signal %d, %s coredump\n",
		   ($? & 127),  ($? & 128) ? 'with' : 'without'));
	}
}

#---1

1;
