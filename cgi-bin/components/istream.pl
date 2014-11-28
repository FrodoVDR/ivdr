
	#$OPT{ffmpeg}		= "/usr/bin/ffmpeg" unless $OPT{ffmpeg};
	#$stream{param}		= "-s 360x270 -f flv -ab 128 -ar 44100 -vcodec flv -b 400000 " unless $stream{param};
	#$stream{stream}	= "http://127.0.0.1:3000/extern/" unless $stream{stream};
	# !!!!!!!!!!!!!!!!!!!!!!! NEU anpassen
	my $source;
	my $command;
	require svdrp;
	require vdr;
	$istream = "./istream.sh";
	$ENV{LD_LIBRARY_PATH} = $OPT{ffmpeglib}.":$ENV{LD_LIBRARY_PATH}" if $OPT{ffmpeglib};
	$OPT{localdir} .= "/" unless $OPT{localdir} =~ /\/$/;
	$OPT{exportdir}.= "/" unless $OPT{exportdir} =~ /\/$/;
	$OPT{wwwdir}   .= "/" unless $OPT{wwwdir} =~ /\/$/;
	
if ($form_input ->{'stream'} eq "overview") {
print "<fieldset id='divstream' tag='".$me."?stream=overview'>";
#<div class='row'><a onclick='alert(1)'>linked</a></div>
#<div class='row'><a onclick='alert(2)'>kill all streams</a></div>
my $b;
for (decode_glob("$OPT{localdir}/session*")) {
	my $bn = basename($_);
	my $info;
	if (-e $_."/info") {
	open (INFO, $_."/info");
	$info = <INFO>;
	close INFO;
#	if (-e $_."/stream.m3u8") {
#	(my $taginfo = $info) =~ s/"/\\"/g;
	my $taginfo="Stream";
	my $active;
	$active = " rec" if -e $_."/ffmpeg.pid";
	$active .= " checked" if -e $_."/exported";

	print "<div class='row mainfont'><a class='$active' onclick='strDialog(\"$taginfo\", \"$OPT{wwwdir}\",\"$bn\")'>".$info."</a></div>";
	$b++;
	}
} 
print "<div class='row topfont'><a onclick='if (confirm(\"$L{SURE}\")) doJSByHref(ivdr+\"?cmd+killffmpeg\")'><center>$L{STOPALL}</center></a></div>" if $b;
print "<div class='row topfont' onclick='iui.showPageByHref(\"$me?stream=overview\",null ,null, \$(\"divstream\"));'><a>No active Streams...</a></div>" unless $b;

print "</fieldset>";

exit(0);
}
elsif ($form_input ->{'stream'} eq "remove" || $form_input ->{'stream'} eq "stop") {

#my $pid;
my @p;
for ((decode_glob($OPT{localdir}.$form_input ->{'id'}."/*.pid"))) {
push(@p, fileArray($_));
}
dbg("Try to kill ".join(" ", @p));
my $result = kill(9, map { split(/ /) } @p) if @p;
print STDERR "Killing processes: ", $result, "\n" if $debug;


unless ($form_input ->{'stream'} eq "stop") {
	$result = unlink(decode_glob($OPT{localdir}.$form_input ->{'id'}."/*"));
	print STDERR "Removing files: ", $result, "\n" if $debug;
	$result = rmdir($OPT{localdir}.$form_input ->{'id'});
	print STDERR "Removing dir: ", $result, "\n" if $debug;
}

#print "alert('".$form_input ->{'id'}." removed');";
print 'iui.showPageByHref("'.$me.'?stream=overview",null ,null, $("divstream"));';
exit(0);
}
elsif ($form_input ->{'stream'} eq "save") {

my @inner = sort { ($a =~ /stream-(\d*)/)[0] <=> ($b =~ /stream-(\d*)/)[0] } decode_glob($OPT{localdir}.$form_input ->{'id'}."/*.ts");

unless (-w $OPT{exportdir} && -d $OPT{exportdir}) 
{
print "alert(\"Exportdir doesn't exist nor writeable!\")";
exit(0);
}
if (-e $OPT{localdir}.$form_input ->{'id'}."/ffmpeg.pid") 
{
print "alert(\"Convertion active. Please stop it first!\")";
exit(0);
}

my $name = $form_input ->{'name'}; # || info inhalt
my $no;
while(-e $OPT{exportdir}.$name.$no.".mp4") {
	$no++;
}

   #warn "/bin/cat '".join("' '", @inner)."' > ".$OPT{exportdir}.$name." &";

system ("(/bin/cat '".join("' '", @inner)."' > ".$OPT{exportdir}.$name.$no.".mp4 && touch ".$OPT{localdir}.$form_input ->{'id'}."/exported) &");
print 'iui.showPageByHref("'.$me.'?stream=overview",null ,null, $("divstream")); alert("Finished!");';

exit(0);
} 

if ($form_input ->{'stream'} eq "dialog") {

my $configoption;
for ((0..$#{$OPT{stream_nm}})) { $configoption .= "<option value='$_'>$OPT{stream_nm}[$_]</option>" }

#my $audiooption = "<option value='-map 0.0 -map 0.1'>0.1 -  Stereo (deu)</option><option value='-map 0.0 -map 0.2'>0.2 -  Surround Sound (deu)</option>";
my $audiooption = "<option value=''>Auto</option>";

#unless ($form_input ->{'type'} eq "live") {

my $ff; my $media = $form_input ->{'id'};
my $length; my @marks;
if ($form_input ->{'type'} eq "live") {
	$media = $OPT{vdr_streamdev}.$form_input ->{'id'};
} elsif ($form_input ->{'type'} eq "rec") {
	establishSocket(); 
	my %h = recordHash(Receive("LSTR"));
	my %rec = getRecByID(\%h, $form_input ->{'id'});

	my $file = $rec{path}."/index*";
	my @tempfile = decode_glob($file);
	my $s = (-s $tempfile[0]);
	$s = int($s / (8 * $OPT{fps} || 8 * 25));
	dbg("Length of recording $tempfile[0]: $s");
	
	$length=$s;
	@marks = map { (my $t = $_) =~ /(\d*):(\d*):(\d*).(\d*)/; $_ = int(($1 * 3600 + $2 * 60 + $3 + $4 / 100) / $s * 100); } fileArray(decode_glob("$rec{path}/marks*"));
	dbgd(@marks);
	quitSocket();
	#$media = "$rec{path}/0*";
	$media = (decode_glob("$rec{path}/0*"))[0];
	
}
	
open(FF, $OPT{ffmpeg}." -i '".$media."' 2>&1 |") or warn "ffmpeg error $media $!";
$ff = join("", <FF>);
close FF;
dbg($ff);
(my $_tmp = $ff) =~ /Stream #(\d\.\d).*:( Video):(.*)/;
warn $&;
my $vid = $1;

while ($ff =~ /Stream #(\d\.\d).*:( Audio):(.*)/g) {
warn $&;
$audiooption .= "<option value='-map $vid -map $1'>$&</option>";
}

(my $_tmp = $ff) =~ /Duration:\s*(\d{2}):(\d{2}):(\d{2})\.\d*,/;
warn $&;
$length = $1*3600+$2*60+$3 unless $length && $form_input ->{'type'} ne "live";


my $aspectoption = "<option value=''>Auto</option><option value='-aspect 16:9'>16:9</option><option  value='-aspect 4:3'>4:3</option>";

my $timelineset;
if ($length) {
#my $timeline = qq|<td width='2%'></td><td width='5%' class='yellow'></td><td width='2%'></td><td width='10%'  class='yellow'></td><td width='2%'></td><td width='4%' class='yellow'></td><td width='27%'></td><td width='3%' class='yellow'></td>|;
my $timeline = "";
	my $d; my $i;
	for (@marks) {
		if (($i / 2) == int($i / 2)) { $timeline .= "<td width='".($_ - $d)."%'></td>" }
		else { $timeline .= "<td width='".($_ - $d)."%' class='yellow'></td>"  }
		$d =+ $_; $i++;
	}

my $lengthstring = $L{LENGTH}.": ".timediff($length);
	
$timelineset = qq|
	bf().style.height = 500+"px";
	\$("timebardiv").style.display = "block";
	\$("timebarlabel").innerHTML = "$lengthstring";
	\$("timebar").innerHTML = "$timeline";
	\$("pin").setAttribute("maxvalue", $length);
	pinmove();
|;
}

print qq[

		var btnok = new button;
		var btnbr = new button;
		
		btnok.value = lp_RUN;
		btnok.onclick = "var vidopt = \$('selectField_1').options[\$('selectField_1').selectedIndex].value; var audopt = \$('selectField_2').options[\$('selectField_2').selectedIndex].value; var aspopt = \$('selectField_3').options[\$('selectField_3').selectedIndex].value; \$('btnsarea').innerHTML = ''; var offset = \$('pin').getAttribute('value'); doJSByHref(sn+'stream=$form_input->{'type'}&id=$form_input->{'id'}&config='+vidopt+'&map='+audopt+'&aspect='+aspopt+'&offset='+offset);";
		btnok.image = www+"/btn_start.png";
		
		btnbr.value = lp_HIDE;
		btnbr.onclick = "cancelDialog(bf())";
		btnbr.image = www+"/btn_cancel.png";
		
		oDialog = new dialog(lp_STREAM, null, null, null, null, [btnok, btnbr]);
		oDialog.show();
		
		$timelineset
		
        \$("selectField").style.display = "block";
		
			
        \$("selectField_2").innerHTML = "$audiooption";
        \$("selectField_2").name = "audio";
        \$("selectField_2").style.display = "block";
        \$("selectFieldLabel_2").innerHTML = "Audio";
        \$("selectFieldLabel_2").style.display = "block";

        \$("selectField_1").innerHTML = "$configoption";
        \$("selectField_1").name = "instanz";
        \$("selectField_1").style.display = "block";
        \$("selectFieldLabel_1").innerHTML = "$L{PROFILE}";
        \$("selectFieldLabel_1").style.display = "block";
		
        \$("selectField_3").innerHTML = "$aspectoption";
        \$("selectField_3").name = "ratio";
        \$("selectField_3").style.display = "block";
        \$("selectFieldLabel_3").innerHTML = "Aspect Ratio";
        \$("selectFieldLabel_3").style.display = "block";

];

exit(0);
}


# activate stream	
my $info;
my $session = "session";
my $no = 0;
while(-e $OPT{localdir}."/".$session.$no) {
	$no++;
}
$session .= $no;
my $type = $form_input ->{'config'} || 0;
#	-map 0.0 -map 0.1 
$form_input ->{'map'} .= " ".$form_input ->{'aspect'};
$form_input ->{'map'} .= " -ss ".$form_input ->{'offset'} if $form_input ->{'offset'};

if ($form_input ->{'stream'} eq "rec") {
	establishSocket(); 
	my %h = recordHash(Receive("LSTR"));
	my @dirs = getDirs(\%h);	# Alle Verzeichnissebenen einzeln...
	my %rec = getRecByID(\%h, $form_input ->{'id'});
	
	#my @files = grep /\d{3}\.vdr/i, <$rec{path}/*.vdr>;
	#my $bytes; map { $bytes += (-s $_) } @files;
	#my $offset = int($bytes * $form_input ->{'offset'} / 65536);
	#$offset -= $offset % (15000000 / 8);
	#$source = join(" ", "tail", "-q", "-c +".($offset || 0), @files); 
	#$command = join(" ", $source, "|",  $OPT{ffmpeg}, "-i - -s", $form_input ->{'aspect'}, $stream{param}, "-ab", $stream{ab}, "-ar", $stream{ar}, "-b", $stream{vb}, "-");

##	my $sec = (-s <$rec{path}/index.vdr>) / (8 * $OPT{fps} || 8 * 25);
##	my $offset = int($sec * $form_input ->{'offset'} / 65536) || 0;
##	$command = join(" ", $OPT{ffmpeg}, "-i", join(" -i ", @files), "-itsoffset", $offset, "-s", $form_input ->{'aspect'}, $stream{param}, "-ab", $stream{ab}, "-ar", $stream{ar}, "-b", $stream{vb}, "-");

	$info = $rec{realname};
	$command = join(" ", $istream, "-", '"'.$form_input ->{'map'}.'"', $OPT{stream_vb}[$type], $OPT{stream_ab}[$type], $OPT{stream_res}[$type], $OPT{wwwdir}.$session, 1260, $OPT{ffmpeg}, $OPT{seg}, $OPT{localdir}."/".$session, "'$rec{path}/0*'");
	quitSocket();

}
elsif ($form_input ->{'stream'} eq "live") {
	establishSocket(); 
	#$command = "wget -q -S -O - '".$stream{'stream'}.$form_input ->{'param'}."' | $OPT{ffmpeg} -i - $stream{param} -b $stream{vb} -s ".$form_input ->{'aspect'}." -";
	#$source = join(" ", "wget -q -S -O - '".$stream{'stream'}.$form_input ->{'param'}."'"); 
	#$command = join(" ", $source, "|",  $OPT{ffmpeg}, "-i - -s", $form_input ->{'aspect'}, $stream{param}, "-ab", chanID, "-ar", $stream{ar}, "-b", $stream{vb}, "-");
	
	$info = (getChannelLogo($form_input ->{'id'}, 36) || getChannelName($form_input ->{'id'}))."&nbsp;&nbsp;(live!)";
	my %ch = getChannel($form_input ->{'id'});
	$command = join(" ", $istream, $OPT{vdr_streamdev}.$ch{no}, '"'.$form_input ->{'map'}.'"', $OPT{stream_vb}[$type], $OPT{stream_ab}[$type], $OPT{stream_res}[$type], $OPT{wwwdir}.$session, 20, $OPT{ffmpeg}, $OPT{seg}, $OPT{localdir}."/".$session);
#	$command = join(" ", $istream, $OPT{vdr_streamdev}.$form_input ->{'id'}, '""', $OPT{stream_vb}[$type], $OPT{stream_ab}[$type], $OPT{stream_res}[$type], $OPT{wwwdir}.$session, 20, $OPT{ffmpeg}, $OPT{seg}, $OPT{localdir}."/".$session);
	quitSocket();

}
elsif ($form_input ->{'stream'} eq "media") {
	
	$info = basename($form_input ->{'id'});
	$command = join(" ", $istream, '"'.$form_input ->{'id'}.'"', '"'.$form_input ->{'map'}.'"', $OPT{stream_vb}[$type], $OPT{stream_ab}[$type], $OPT{stream_res}[$type], $OPT{wwwdir}.$session, 1260, $OPT{ffmpeg}, $OPT{seg}, $OPT{localdir}."/".$session);
}

print STDERR "Streamcommand: ".$command."\n" if $debug;	
#exit(0);

mkdir($OPT{localdir}."/$session");

open(INFO, ">".$OPT{localdir}."/$session/info");
print INFO $info;
close(INFO);

`nohup $command >$OPT{localdir}/$session/istream.log 2>&1 &`;

my $counter;
until (-e $OPT{localdir}."/$session/stream.m3u8")
{
if ($counter > 10 &! -e $OPT{localdir}."/$session/ffmpeg.pid") {
	open (FF, $OPT{localdir}."/$session/ffmpeg.log");
	my @ff = <FF>;
	dbgd(@ff);
	chomp($ff[$#ff]);
	close FF;
	print qq<
	cancelDialog(bf());
	alert("Something went wrong!\\n$ff[$#ff]");
	>;
	warn @ff if $debug;
	unlink(decode_glob($OPT{localdir}."/$session/*"));
	rmdir($OPT{localdir}."/$session");
	exit(0);
}
sleep 1;
$counter++;
};

if (! -e $OPT{localdir}."/$session/stream.m3u8") {
dbg("Stop waiting, took too long!");
print "alert('This needs too long!\\nMaybe you can start the stream in the mainmenu!');";
exit(0);
}

print qq<
//\$('moviebtn').src='/data/iphone/istreamdev/ram/$session/stream.m3u8';
//\$('moviebtn').style.display = 'block';
cancelDialog(bf());
//strDialog("$info", "$OPT{wwwdir}", "$session");
strDialog("Stream", "$OPT{wwwdir}", "$session");
>;
dbg("Done!");
1;