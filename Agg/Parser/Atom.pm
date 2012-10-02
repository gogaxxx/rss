package Agg::Parser::Atom;

use strict;

use base qw(Agg::Parser::XML);

# new #+++1
sub new {
	my $class=shift;
	my ($cfg)=@_;

	my $self=$class->SUPER::new(@_);

	$self->{parser}->setHandlers(Start => \&atom_start,
								End   => \&atom_end,
								Char  => \&common_char);
	return $self;
}

# handlers #+++1
#+++2 atom_start
sub atom_start {
    my ($expat, $elem, %attr)=@_;

    if ($elem eq 'entry') {
        $expat->{item} = {};
    }
    elsif ($elem eq 'link') {
        if ($attr{rel} eq 'alternate' 
            || !defined $expat->{item}{link}) 
        {
            $expat->{item}{link} = $attr{href};
        }
    }
    elsif ($elem eq 'id'
            || $elem eq 'title'
            || $elem eq 'published'
            || $elem eq 'updated'
			|| $elem eq 'created'
			|| $elem eq 'modified'
			|| $elem eq 'issued'
            || $elem eq 'content'
            || $elem eq 'summary')
    {
        $expat->{curparam} = $elem;
        $expat->{item}{$expat->{curparam}} = '';
    }
}

#+++2 atom_end 
sub atom_end {
    my ($expat, $elem)=@_;

    if ($elem eq 'entry') {
        my $item = $expat->{item};
        my $guid = $item->{id} || $item->{link};
            $guid =~ s/\s/_/go;
        $expat->{saver}->save_item({
                        subject => $item->{title},
                        date    => $item->{created}
									|| $item->{modified} 
									|| $item->{updated} 
                                    || $item->{published}
									|| $item->{issued}
									|| '',
                        body    => $item->{content}
                                    || $item->{summary},
                        guid    => $guid,
                        link    => $item->{link}
                    });
    }
    elsif ($elem eq 'id'
            || $elem eq 'title'
            || $elem eq 'published'
            || $elem eq 'updated'
			|| $elem eq 'created'
			|| $elem eq 'modified'
			|| $elem eq 'issued'
            || $elem eq 'content'
            || $elem eq 'summary') 
    {
        if($expat->{curparam} ne $elem) {
            $expat->finish();
        }
        else {
            $expat->{curparam} = undef;
        }
    }
}

#+++2 common_char
sub common_char {
    my ($expat, $string)=@_;

    if (defined $expat->{curparam}) {
        $expat->{item}{$expat->{curparam}} .= $string;
    }
}
