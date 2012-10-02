#
#
#

package Agg::Download;

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
		cfg => $cfg}, $class;

	return $self;
}

#mirror #+++1
sub mirror {
	my $self=shift;
	my ($url, $filename, $return_content)=@_;

	$return_content //= 1;

	warn "getting [$url]" if (DEBUG);
	$self->_mirror_download($url, $filename);

#		if ($response->{'_headers'}{'content-encoding'} eq 'gzip') {
#			warn 'GZIPPED!';
#			system(GZIP.' '.$filename);
#		}

	if ($return_content) {
		my $content = '';
		open(FILE, '<'.$filename) ||
			die("[Agg::Download::mirror] Can't open $filename: $!");
		$content = join('', <FILE>);
		close FILE;
		return $content;
	}
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
