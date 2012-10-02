package Agg::Parser::RSS;

use strict;

use base qw(Agg::Parser::XML);

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self=$class->SUPER::new(@_);

	$self->{parser}->setHandlers(Start => \&rss_start,
								End   => \&rss_end,
								Char  => \&common_char);
	return $self;
}

#+++2 common_char
sub common_char {
    my ($expat, $string)=@_;

    if (defined $expat->{curparam}) {
        $expat->{item}{$expat->{curparam}} .= $string;
    }
}

#+++2 rss_start
sub rss_start {
    my ($expat, $elem, %attr)=@_;

    if ($elem eq 'item') {
        $expat->{item} = {};
    }
    elsif ($elem eq 'guid'
            || $elem eq 'title'
            || $elem eq 'pubDate'
            || $elem eq 'date'
            || $elem eq 'dc:date'
            || $elem eq 'description'
            || $elem eq 'content:encoded'
			|| $elem eq 'link')
    {
        $expat->{curparam} = $elem;
        $expat->{item}{$expat->{curparam}} = '';
    }
}

#+++2 rss_end 
sub rss_end {
    my ($expat, $elem)=@_;

    if ($elem eq 'item') {
        my $item = $expat->{item};
        my $guid = $item->{guid} || $item->{link};
            $guid =~ s/\s/_/go;
		$expat->{saver}->save_item({
                        subject => $item->{title},
                        date    => $item->{pubDate} 
									|| $item->{'dc:date'} || '', 
                        body    => $item->{'content:encoded'} 
									|| $item->{description},
                        guid    => $guid,
                        link    => $item->{link} || $guid
                    });
    }
    elsif ($elem eq 'guid'
            || $elem eq 'title'
            || $elem eq 'pubDate'
            || $elem eq 'date'
            || $elem eq 'dc:date'
            || $elem eq 'description'
            || $elem eq 'content:encoded'
			|| $elem eq 'link')
    {
        if($expat->{curparam} ne $elem) {
            $expat->finish();
        }
        else {
            $expat->{curparam} = undef;
        }
    }
}

