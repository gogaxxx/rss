#
#
#

package Agg::Download;

use LWP::UserAgent;
use constant DEBUG=>0;

use constant GZIP => q{/usr/bin/gzip -S '' -f -d };
use constant DOWNLOAD_CMD =>
	'/usr/bin/curl -s -LR --url %1$s -o %2$s -z %2$s';

use strict;

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;
	$ua->agent($cfg->{'user-agent'});

	my $self = bless {
		ua => $ua,
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

sub _mirror_download {
	my $self=shift;
	my ($url, $filename)=@_;

	my $cmd= sprintf(DOWNLOAD_CMD, $url, $filename);
	system($cmd);
}

1;
