package Agg::Config;

use strict;
use warnings;

use Encode;

use constant ROOT => '/home/nephrite/rss';
use constant CONFIG_DIR => ROOT.'/config';
use constant DEFAULT_ENCODING => 'utf-8';
use constant DEBUG => 0;

# name  - название ленты
# type  - тип, например, atom или rss - используется для определения,
#           какой парсер применять
# url   - урл
my @fields = qw(type url);

# get_global_config #+++1
sub get_global_config {
	my $class=shift;

	my $self = bless {
		root => ROOT,
		'config-dir' => CONFIG_DIR,
	}, $class;
    $self->read_file(CONFIG_DIR.'/config');

	# read-dir - где находятся готовые файлы для чтения человеком
	$self->{'read-dir'} ||= $self->{'config-dir'}.'/read';
    # где находятся картинки относительно read-dir
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

	if ($id =~ m{([^/]+)$}o) {
		$id = $1;
	}

	my $self = $class->get_global_config();

	$self->{'feed-dir'} = CONFIG_DIR.'/'.$id;
	my $config_filename = $self->{'feed-dir'}.'/config';
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
	$self->{'cache-dir'} ||= $self->{'feed-dir'}.'/cache';

	# где хранятся готовые итемы
	$self->{items_dir} ||= $self->{'feed-dir'}.'/items';

	# master - указатель для итемов, в нём содержатся данные по итемам,
	# такие как время и гуид
	$self->{master} ||= $self->{'feed-dir'}.'/master';

	# news - указатель аналогичный master но там содержатся не все
	# итемы, а только новые со времени последнего запуска
	$self->{'news'} ||= $self->{'feed-dir'}.'/news';

	return $self;
}

# read_file #+++1 
sub read_file {
    my $self=shift;
    my $config_filename=shift;

	open(FILE, '<', $config_filename)
		or die("Can't open $config_filename: $!");
	my $enc_obj = Encode::find_encoding(DEFAULT_ENCODING); # XXX сделать
															# определение кодировки
	my $current_group = $self;
	while(my $raw_line = <FILE>) {
		chomp $raw_line;
		my $line = $enc_obj->decode($raw_line);

		$line =~ s/^\s+|\s+$//go;
		next if ($line eq '' || substr($line, 0, 1) eq '#');

		if ($line =~ /^\[([^\]]+)\]$/) {
			my $group_name=$1;
			warn "group_name=$group_name" if (DEBUG);
			$current_group = $self->{$group_name} = {};
			next;
		}

		my @pair = split(/\s*=\s*/, $line, 2);

        # заменяем переменные
        $pair[1] =~ s/\$\{([^\}]+)\}/$self->{$1}/g;
		# подставляем переменные из вышестоящего конфига
        $pair[1] =~ s/\$SUPER/$self->{$pair[0]}/g;

		$current_group->{$pair[0]} = $pair[1];
	}
	close FILE;
}

#---1
1;
