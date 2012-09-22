package Agg::Config;

use strict;
use warnings;

use cfg;

# name  - название ленты
# type  - тип, например, atom или rss - используется для определения,
#           какой парсер применять
# url   - урл
my @fields = qw( name type url);

# get_config_by_id #+++1
sub get_config_by_id {
	my $class=shift;
	my $id = shift;

	my $self = bless {}, $class;
	
	$self->{config_dir} = $cfg::config_dir.'/'.$id;
	my $config_filename = $self->{config_dir}.'/config';
	open(FILE, '<', $config_filename)
		or die("Can't open $config_filename: $!");
	while(my $line = <FILE>) {
		chomp $line;

		my @pair = split(/=/, $line, 2);
		$self->{$pair[0]} = $pair[1];
	}
	close FILE;

    # считываем конфигурируемые пользователем поля из файла
	for my $f (@fields) {
		if (!defined($self->{$f})
			|| $self->{$f} eq '')
		{
			warn("Field $f empty!");
		}
	}

    # формируем производные поля
	# кеш - где хранятся скачанные rss
	$self->{cache} = $self->{config_dir}.'/cache';

	# где хранятся готовые итемы
	$self->{items_dir} = $self->{config_dir}.'/items';

	# master - указатель для итемов, в нём содержатся данные по итемам,
	# такие как время и гуид
	$self->{master} = $self->{config_dir}.'/master';

	# read_dir - где находятся готовые файлы для чтения человеком
	$self->{read_dir} = $self->{config_dir}.'/read';

	return $self;
}

#---1
1;
