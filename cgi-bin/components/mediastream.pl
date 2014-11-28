
my %mimeType = qw (
	ai		application/postscript
	aif		audio/x-aiff
	aifc	audio/x-aiff
	aiff	audio/x-aiff
	asc		text/plain
	atom	application/atom+xml
	au		audio/basic
	avi		video/x-msvideo
	bcpio	application/x-bcpio
	bin		application/octet-stream
	bmp		image/bmp
	cdf		application/x-netcdf
	cgm		image/cgm
	class	application/octet-stream
	cpio	application/x-cpio
	cpt		application/mac-compactpro
	csh		application/x-csh
	css		text/css
	dcr		application/x-director
	dif		video/x-dv
	dir		application/x-director
	djv		image/vnd.djvu
	djvu	image/vnd.djvu
	dll		application/octet-stream
	dmg		application/octet-stream
	dms		application/octet-stream
	doc		application/msword
	dtd		application/xml-dtd
	dv		video/x-dv
	dvi		application/x-dvi
	dxr		application/x-director
	eps		application/postscript
	etx		text/x-setext
	exe		application/octet-stream
	ez		application/andrew-inset
	gif		image/gif
	gram	application/srgs
	grxml	application/srgs+xml
	gtar	application/x-gtar
	hdf		application/x-hdf
	hqx		application/mac-binhex40
	htm		text/html
	html	text/html
	ice		x-conference/x-cooltalk
	ico		image/x-icon
	ics		text/calendar
	ief		image/ief
	ifb		text/calendar
	iges	model/iges
	igs		model/iges
	jnlp	application/x-java-jnlp-file
	jp2		image/jp2
	jpe		image/jpeg
	jpeg	image/jpeg
	jpg		image/jpeg
	js		application/x-javascript
	kar		audio/midi
	latex	application/x-latex
	lha		application/octet-stream
	lzh		application/octet-stream
	m3u		audio/x-mpegurl
	m4a		audio/mp4a-latm
	m4b		audio/mp4a-latm
	m4p		audio/mp4a-latm
	m4u		video/vnd.mpegurl
	m4v		video/x-m4v
	mac		image/x-macpaint
	man		application/x-troff-man
	mathml	application/mathml+xml
	me		application/x-troff-me
	mesh	model/mesh
	mid		audio/midi
	midi	audio/midi
	mif		application/vnd.mif
	mkv		video/x-matroska
	mov		video/quicktime
	movie	video/x-sgi-movie
	mp2		audio/mpeg
	mp3		audio/mpeg
	mp4		video/mp4
	mpe		video/mpeg
	mpeg	video/mpeg
	mpg		video/mpeg
	mpga	audio/mpeg
	ms		application/x-troff-ms
	msh		model/mesh
	mxu		video/vnd.mpegurl
	nc		application/x-netcdf
	oda		application/oda
	ogg		application/ogg
	pbm		image/x-portable-bitmap
	pct		image/pict
	pdb		chemical/x-pdb
	pdf		application/pdf
	pgm		image/x-portable-graymap
	pgn		application/x-chess-pgn
	pic		image/pict
	pict	image/pict
	png		image/png
	pnm		image/x-portable-anymap
	pnt		image/x-macpaint
	pntg	image/x-macpaint
	ppm		image/x-portable-pixmap
	ppt		application/vnd.ms-powerpoint
	ps		application/postscript
	qt		video/quicktime
	qti		image/x-quicktime
	qtif	image/x-quicktime
	ra		audio/x-pn-realaudio
	ram		audio/x-pn-realaudio
	ras		image/x-cmu-raster
	rdf		application/rdf+xml
	rgb		image/x-rgb
	rm		application/vnd.rn-realmedia
	roff	application/x-troff
	rtf		text/rtf
	rtx		text/richtext
	sgm		text/sgml
	sgml	text/sgml
	sh		application/x-sh
	shar	application/x-shar
	silo	model/mesh
	sit		application/x-stuffit
	skd		application/x-koan
	skm		application/x-koan
	skp		application/x-koan
	skt		application/x-koan
	smi		application/smil
	smil	application/smil
	snd		audio/basic
	so		application/octet-stream
	spl		application/x-futuresplash
	src		application/x-wais-source
	sv4cpio	application/x-sv4cpio
	sv4crc	application/x-sv4crc
	svg		image/svg+xml
	swf		application/x-shockwave-flash
	t		application/x-troff
	tar		application/x-tar
	tcl		application/x-tcl
	tex		application/x-tex
	texi	application/x-texinfo
	texinfo	application/x-texinfo
	tif		image/tiff
	tiff	image/tiff
	tr		application/x-troff
	ts		video/MP2T
	tsv		text/tab-separated-values
	txt		text/plain
	ustar	application/x-ustar
	vcd		application/x-cdlink
	vrml	model/vrml
	vxml	application/voicexml+xml
	wav		audio/x-wav
	wbmp	image/vnd.wap.wbmp
	wbmxl	application/vnd.wap.wbxml
	wml		text/vnd.wap.wml
	wmlc	application/vnd.wap.wmlc
	wmls	text/vnd.wap.wmlscript
	wmlsc	application/vnd.wap.wmlscriptc
	wrl		model/vrml
	xbm		image/x-xbitmap
	xht		application/xhtml+xml
	xhtml	application/xhtml+xml
	xls		application/vnd.ms-excel
	xml		application/xml
	xpm		image/x-xpixmap
	xsl		application/xml
	xslt	application/xslt+xml
	xul		application/vnd.mozilla.xul+xml
	xwd		image/x-xwindowdump
	xyz		chemical/x-xyz
	zip		application/zip
);

#achtung globaler uri unescape erst sp�er wegen geschwindigkeitsvorteil
if (lc($cgi->url_param('media')) eq "grab") {
print $cgi->header(-type    =>'image/jpeg', -charset => $OPT{charset});

if ($OPT{player} eq "xbmc") {
	require LWP::Simple;
	dbg($mediaselect{_OPT_}{SCRIPTNAME}."command=takescreenshot($tempdir/ivdrgrab.jpg;false;0;640;360;80)");
	my $contents = LWP::Simple::get($mediaselect{_OPT_}{SCRIPTNAME}."command=takescreenshot($tempdir/ivdrgrab.jpg;false;0;640;360;80)");
} else {
	use MIME::Base64;
	require svdrp;
	establishSocket();
	(my $res = Receive("GRAB .jpg 80 300 225")) =~ s/216-|\r\n$|216 .*//g;
	print decode_base64($res);

	quitSocket();
}
open (FILE, $tempdir."/ivdrgrab.jpg") or die "Couldn't open file: $!\n";
print <FILE>;
close FILE;
exit(0);
}
elsif (lc($cgi->url_param('media')) eq "epgpic") {
print $cgi->header(-type    =>'image/png', -charset => $OPT{charset});

my $file = $OPT{epgimages}."/".$cgi->url_param('id').".png";
open (FILE, $file) or die "Couldn't open $file: $!\n";
print <FILE>;
close FILE;

exit(0);
}
elsif (lc($cgi->url_param('media')) eq "chapic") {
lc($cgi->url_param('id')) =~ /.*\.(.*?$)/;
die ("Unkown MIME-Type: $1") unless($mimeType{$1});
print $cgi->header(-type    =>$mimeType{$1}, -charset => $OPT{charset});

my $file = $OPT{chaimages}."/".$cgi->url_param('id');
open (FILE, $file) or die "Couldn't open $file: $!\n";
print <FILE>;
close FILE;

exit(0);
}
elsif (lc($cgi->url_param('media')) eq "database") {
print $cgi->header(-type    =>'image/jpeg');
#print $cgi->header(-type    =>'text/html', -charset => $OPT{charset});

my $command = "./mdb.pl --pic ".$cgi->url_param('pic');
print qx($command) or die("Error opening mdb.pl. $!");
#open (RESULT, "./mdb.pl --get --id ".$cgi->url_param('id')." |") or die("Error opening mdb.pl. $!");
#my $VAR1 = join("", <RESULT>);
#close RESULT;
#eval($VAR1);

#print $$VAR1{$cgi->url_param('id')}[0]{IDS}{APIC}{_Data};

exit(0);
}
elsif (lc($cgi->url_param('media')) eq "play") {
#achtung globaler uri unescape erst sp�er
my $file = uri_unescape($cgi->url_param('file'));
#print STDERR $cgi->url_param('id'),"\n";
if (defined($cgi->url_param('id'))) {
	open (RESULT, "./mdb.pl --get --id ".$cgi->url_param('id')." |") or die("Error opening mdb.pl. $!");
	my $VAR1 = join("", <RESULT>);
	close RESULT;
	eval($VAR1);
	#print STDERR Dumper $VAR1;
	$file = $$VAR1{$cgi->url_param('id')}[0]{DIR}.$$VAR1{$cgi->url_param('id')}[0]{FILENAME};
	print STDERR $$VAR1{$cgi->url_param('id')}[0]{DIR},"\n";
}

my $length = (-s $file);

#print $cgi->header(	-type =>'audio/mpeg3',
#					-Content_length=>(-s $file),
#					-Accept_ranges => 'bytes',
#					-attachment => 'temp.mp3',
#					);
#	-charset => $OPT{charset}, 
#					-Last_modified => 'Sat, 22 Aug 2009 20:59:45 GMT',
#					-ETag => '11f4-4ae469-471c143aed240"',
#-attachment=>'foo.gif',
#print header(-Content_length=>3002);

#$VAR15 = 'HTTP_RANGE';
#$VAR16 = 'bytes=100-149';

my @range;
	$file =~ /\.([^.]+)$/;
	my $suffix = $1;
	$suffix = "txt" unless (defined $suffix);
	my $type = $mimeType{$suffix};

#	print STDERR "Type: ",$type,"\n";
	#print STDERR Dumper \%ENV,"-----------------------------------\n";
if ($ENV{HTTP_RANGE}=~/\s*.*?\s*=\s*(\d*)\s*-\s*(\d*)/) {
	@range = ($1, $2);
}
#	print "HTTP/1.0 200 OK\r\n",
#	206 Partial content
#	Accept-Ranges: bytes
# 	"HTTP/1.1 200 OK\n",
if ((-f $file)&&(open FILE, $file)) {
my %header =(
	-Content_Type=>$type,
	-Accept_Ranges=>"bytes",
	-Server=>"iVDR/$version",
	);
#http://www.html-world.de/program/http_7.php
#my $head = $cgi->header(%h);

	#print "Server: iVDR/$version\r\n",
	#      "Connection: Close\r\n",
#		  "Content-Type: $type\r\n";
	if (defined($range[0])) {
		seek FILE, $range[0], 0;
##	print STDERR "Datei: ",$file,"\n";
##	print STDERR "Size: ",$length,"\n";
##	print STDERR "From: $range[0]  To: $range[1]\n";
		$range[1] = $length unless $range[1];
		my $end = $range[1]-$range[0]+1; #$length - $range[0]; 
		#		  ^^^^^^^^^^^^^^^^^^^
		#		  $range[1]-$range[0]
##	print STDERR "Length: ",$end,"\n";
		#Content-range: 0-65535/83028576
		$header{-Status}="206 Partial Content";
		$header{-Content_Range}="bytes ".$range[0]."-".($range[1])."/".$length;
		#print "Content-Range: bytes ",$range[0],"-".($range[1])."/$length\r\n",
		#					  ^^^^^					 ^^^^^^^^^
		#					  ?????					 $range[1] ???? (alt: $length)
		$header{-Content_Length}=$end;
		#	  "Content-Length: $end\r\n";
		#					   ^^^^
		#					   
	} else {
		$header{-Status}="200 OK";		
		$header{-Content_Length}=$length;
		#$header{-Script_Filename}="test.mkv";
		
#		print "Content-Length: ",$length,"\r\n";
	}

#	print STDERR $cgi->header(%header);
	print $cgi->header(%header);

	my $buffer;
	while (read FILE, $buffer, 8192) {
#							 ^^^^^
#							 1024 ????
		print $buffer;
	}

	close FILE;
} else {
	die ("Can not open file: $file $!\n");
}

#use bytes;
#read FILEHANDLE,SCALAR,LENGTH,OFFSET 
#open (FILE, $file) or die "Could not open file: $!\n";
#my $bytesread; my $buffers;
#$buffers = join(//, <FILE>);
#print STDERR Dumper @range;
#print STDERR $range[1];
#print substr($buffers, ($range[1]), ($range[2]-$range[1]+1));
#while (<FILE>) { print $_ }
#while( $bytesread = read(*FILE, $buffers, 149, -100)) { 
#	print $buffers;
#	last;
#	}
exit(0);
}
elsif (lc($cgi->url_param('media')) eq "playlist.m3u") {
print $cgi->header(-type    =>$mimeType{m3u});
open (PL, $tempdir."/tempplaylist.m3u") or die "Could not open $tempdir/tempplaylist.m3u";
print join("\n", <PL>);
close (PL);
exit(0);
}

1;