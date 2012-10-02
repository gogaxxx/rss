package Agg::Config;

use strict;
use warnings;

use constant ROOT => '/home/nephrite/rss';
use constant CONFIG_DIR => ROOT.'/config';

# name  - название ленты
# type  - тип, например, atom или rss - используется для определения,
#           какой парсер применять
# url   - урл
my @fields = qw(type url);

# get_global_config #+++1
sub get_global_config {
	my $class=shift;

	my $self = bless {
		config_dir => CONFIG_DIR,
	}, $class;
    $self->read_file(CONFIG_DIR.'/config');

	# readdir - где находятся готовые файлы для чтения человеком
	$self->{'readdir'} ||= $self->{config_dir}.'/read';
    # где находятся картинки относительно readdir
    $self->{'imgdir'} ||= 'img';

	# encoding - кодировка выходных файлов
	$self->{'encoding'} ||= 'utf-8';

	# date format
	$self->{'date-format'} ||= '%Y-%m-%d %T %z';

	# user agent
	$self->{'user-agent'} ||= 'Mozilla/5.0';

	return $self;
}

# get_config_by_id #+++1
sub get_config_by_id {
	my $class=shift;
	my $id = shift;

	my $self = $class->get_global_config();

	$self->{config_dir} = CONFIG_DIR.'/'.$id;
	my $config_filename = $self->{config_dir}.'/config';
    $self->read_file($config_filename);

    # считываем конфигурируемые пользователем поля из файла
	for my $f (@fields) {
		if (!defined($self->{$f})
			|| $self->{$f} eq '')
		{
			warn("Field $f empty!");
		}
	}

    # формируем поля по-умолчанию
    $self->{name} ||= $id; # гарантировано уникальное, лол

	# кеш - где хранятся скачанные rss
	$self->{cache} ||= $self->{config_dir}.'/cache';

	# где хранятся готовые итемы
	$self->{items_dir} ||= $self->{config_dir}.'/items';

	# master - указатель для итемов, в нём содержатся данные по итемам,
	# такие как время и гуид
	$self->{master} ||= $self->{config_dir}.'/master';

	# news - указатель аналогичный master но там содержатся не все
	# итемы, а только новые со времени последнего запуска
	$self->{'news'} ||= $self->{config_dir}.'/news';

	return $self;
}

# #+++1 
sub read_file {
    my $self=shift;
    my $config_filename=shift;

	open(FILE, '<', $config_filename)
		or die("Can't open $config_filename: $!");
	while(my $line = <FILE>) {
		chomp $line;
		$line =~ s/^\s+|\s+$//go;
		next if ($line eq '' || substr($line, 0, 1) eq '#');

		my @pair = split(/\s*=\s*/, $line, 2);
        
        # заменяем переменные
        $pair[1] =~ s/\$\{[^\}]+\}/$self->{$1}/g;

		$self->{$pair[0]} = $pair[1];
	}
	close FILE;
}

#---1
1;
