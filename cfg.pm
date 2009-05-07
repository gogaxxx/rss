# config file

package cfg;

$myself       = 'nephrite@rssreader';
$sendmail     = '/usr/local/bin/procmail -d nephrite';

$mail_root      = '/home/nephrite/Mail/rss';
$active_file    = '/home/nephrite/work/rss2mail-home/active';
$default_period = 60;

$root = '/home/nephrite/work/rss2mail-home';

$feeds_dir = "$root/feeds";
$items_dir = "$root/items";
$guiddatabase = "$root/guids";
$guidmaster   = "$root/guids.txt";

1;
