# config file

package cfg;

$myself       = 'nephrite@rssreader';
$sendmail     = '/usr/local/bin/procmail -d nephrite';

$mail_root      = '/home/nephrite/Mail/rss';
$active_file    = '/home/nephrite/work/rss2mail-home/active';
$default_period = 60;

$root = '/home/nephrite/rss';
$config_dir = "$root/config";

#
# feeds_dir - raw feeds from internet put in this directory
#
$feeds_dir = "$root/feeds";

#
# items_dir - processed items (one article per file) put in this
#             directory
#
$items_dir = "$root/items";

#
# out_dir - compiled html-files, ready for reading (no pun intended) go
#           in this directory
#
$out_dir   = "$root/read";

#
# style_dir - css styles for compiled html files
#
$style_dir = "$root/style";

#
# guiddatabase - in this NDBM file seen guids are stored
#
$guiddatabase = "$root/guids";

#
# maxitems - maximum articles per html page
#
$maxitems = 20;

#
# sorting - articles' sorting method. Two possible values 'old_first' -
#           older articles go first, the natural chronologic order.
#           new_first - newer articles go first, reverse chronologic
#           order, often used in blogs. This is the default.
#
$sorting = 'new_first';

#
# date_format - in this format dates are printed near articles' headers.
#               See strftime(3) for details
#
$date_format = '%a, %Y-%m-%d %H:%M:%S';

#
# Sorter can make ("compile") several different htmls from the same news
# items. Here is how it is configured.
# %to_process consists of several items in format name => config
# <name> then supplied to sorter. config follows:
#
# input - index file with articles' data. parser produces two index
#         files: "order" - all the articles ever seen, and "new" -
#         articles seen the most recent run
#
# maxitems - local maxitems
#
# output_tmp - templates for compiled html files' names in sprintf
#              format. One numeric parameter allowed: serial number of file
#
# output_start - first file the user will point her browser at. It is a
#                copy of one of output_tmp files and depend on sorting
#                parameter. If sorting is 'old_first' then output_start
#                will point to the first (the oldest) file, else it will
#                point to the last (the newest) file
#
# sorting - local sorting method, see global sorting variable.
#
%to_process = (
	lenta => { 'input'      => $cfg::items_dir.'/order',
	'output_tmp'   => $cfg::out_dir.'/lenta%d.html',
	'output_start' => $cfg::out_dir.'/lenta.html',
	style => $cfg::style_dir.'/lenta.css',},
	news => { 'input'      => $cfg::items_dir.'/new',
	'output_tmp'   => $cfg::out_dir.'/new%d.html',
	'output_start' => $cfg::out_dir.'/new.html',
    'sorting' => 'old_first',
	style => $cfg::style_dir.'/news.css',},
);

1;
