package Agg::Saver::RSS;

use strict;
use base qw(Agg::Saver);
use Agg::Item;

#+++1 new
sub new {
	my $class=shift;

	my $self=$class->SUPER::new(@_);

	$self->{itemizer} = Agg::Item->new($self->{cfg});
    $self->{item_num} = $self->get_saved_id();

	return $self;
}

### save_item ####+++1
sub save_item {
	my $self=shift;
    my ($item)=@_;

	my $guids = $self->{guids};

	return if ($guids->{$item->{guid}});

	$guids->{$item->{guid}} = 1;
	$item->{name} = $self->{item_num};
	$self->{itemizer}->save_item($item);

	$self->save_item_data($item);

    print($self->{item_num}, ' ');
	$self->{item_num}++;
}

### get_saved_id ####+++1
sub get_saved_id {
	my $self=shift;

    if (open(IN, '<'.$self->{cfg}{config_dir}.'/number')) {
        my $id = <IN>;
        close IN;

        while (-e $self->{cfg}{items_dir}.'/'.$id) {
            $id++;
        }
        return $id || 1; 
    }
    else {
        return 1;
    }
}

### save_id ####+++1
sub save_id {
	my $self=shift;

    if (open(OUT, '>'.$self->{cfg}{config_dir}.'/number')) {
        print OUT $self->{item_num};
        close OUT;
    }
}

1;
