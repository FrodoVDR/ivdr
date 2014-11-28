$weburl	= "/ivdrdata";           # URL of ivdrdata
$debug=1;                    # debug or not debug;
$tempdir = "/tmp/iVDR/";     # Temporary directory
$atprocess = "/usr/bin/at";  # at process
@schedtime = qw(1300 1330 1400 1430 1500 1530 1600 1630 1700 1730 1800 1830 1900 1930 2000 2030 2100 2130 2230 2330 0000 0030 0100 0130);
@menusort = qw(vdr_ul stream_ul media_ul vdrinfo_ul epgs_ul conf_ul own_ul set_ul);
$jscript = "$weburl/iui.js";
$UserDefinedInfoFile = 1;
1;