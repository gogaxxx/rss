#!/usr/bin/perl
#
#
#

use LWP::UserAgent;
use HTML::Parser;

my $url = $ARGV[0] || die("Please provide an url");

my $ua = LWP::UserAgent->new();
$ua->env_proxy();

my $response = $ua->get($url);

if ($response->is_success) {
	my $content = 
		$response->decoded_content 
		|| $response->content;
	my $parser = HTML::Parser->new(
					api_version => 3,
					default_h => [\&default, 'self,text'],
					start_h => [\&start, "self,tagname,attr,text"],
					end_h => [ \&end, 'self,tagname,text']);
	$parser->parse($content);
}
else {
	die ("Can't get $url: ", $response->status_line);
}

sub start {
	my ($self, $tagname, $attr, $text)=@_;

	if ($tagname eq 'div') {
		if ($self->{LEVEL}) {
			$self->{LEVEL}++;
		}
		if($attr->{id} eq 'article') {
			$self->{LEVEL} = 1;
		}
	}

	if ($self->{LEVEL}) {
		print $text;
	}
}

sub end {
	my ($self, $tagname, $text)=@_;

	if ($self->{LEVEL}) {
		print $text;
	}

	if ($tagname eq 'div') {
		if ($self->{LEVEL} > 0) {
			$self->{LEVEL}--;

			if ($self->{LEVEL} == 1) {
				$self->{LEVEL}=0;
			}
		}
	}
}

sub default {
	my ($self, $text)=@_;

	if ($self->{LEVEL}) {
		print $text;
	}
}
