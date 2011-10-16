#
#
#

package Agg::Download;

use LWP::UserAgent;
use constant DEBUG=>0;

use strict;

sub mirror {
	my $class=shift;
	my ($url, $filename, $return_content)=@_;

	$return_content //= 1;

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;

	warn "getting [$url]" if (DEBUG);
	my $response = $ua->mirror($url, $filename);

	if ($response->is_success 
			or $response->code eq '304') {
		if ($return_content) {
			my $content = '';
			open(FILE, '<'.$filename) ||
				die("[Comics::mirror] Can't open $filename: $!");
			$content = join('', <FILE>);
			close FILE;
			return $content;
		}
	}
	else {
		die ("Can't get $url: ", $response->status_line);
	}
}

1;
