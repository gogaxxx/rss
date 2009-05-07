# config file

package cfg;

$myself       = 'nephrite@rssreader';
$sendmail     = '/usr/local/bin/procmail -d nephrite';

$mail_root      = '/home/nephrite/Mail/rss';
$active_file    = '/home/nephrite/work/rss2mail-home/active';
$default_period = 60;

$root = '/home/nephrite/rss';

$feeds_dir = "$root/feeds";
$items_dir = "$root/items";
$out_dir   = "$root/read";
$guiddatabase = "$root/guids";
$maxitems = 20;
$date_format = '%a, %Y-%m-%d %H:%M:%S';

1;
