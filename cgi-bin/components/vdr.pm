# ------------------------------ VDR Subs ---------------------------
#used in main vdrhandler istream.pl

sub dblSplit { # Teilt einen String in einen Array, Arg0 Anfang, Arg1 Ende, Arg2 String			->ARRAY
my @split;
my $start = $_[0]; my $end = $_[1]; my $item = $_[2];

while ($item =~ /$start.*?($end)/gs) { push(@split, $&) } # gibt die Daten zwischen start und end als array zurck
return(@split);
}

sub getDirs {
my @dirs;
for (keys(%{$_[0]{subdirs}})) {
	push(@dirs, $_[1].$_); 
	
}
for (keys(%{$_[0]{subdirs}})) {
	push(@dirs, getDirs(\%{$_[0]{subdirs}{$_}},$_[1].$_."~") );
}
return(@dirs)
}

sub getRecordLength { # Gibt die l?ge der Aufzeichnung zurck Arg0->Verzeichnis, Arg2->zeittyp, Arg3->Suffix
	return unless $OPT{videodir};
	return unless $_[0];
	my $file = $_[0]."/index*";
#	my @tempfile = <${file}>;
	my @tempfile = decode_glob($file);

	my $s = (-s $tempfile[0]);
	$s = timediff(int($s / (8 * $OPT{fps} || 8 * 25)), "", "", $_[1],$_[2], "0&prime;"); # 8bit x 25 fps (PAL)
}

sub recordHash {	# bildet Record hash Arg0-> SVDRP LSTR 
my %h; my $string = $_[0];
#						1		2		3		4		5		6	    7	    8
while ($string =~ /250.(\d*?) (\d{2}).(\d{2}).(\d{2}).(\d{2}).(\d{2})(.\d*:\d{2})?(.) (.*)\r\n/g) {
#while ($string =~ /250.(\d*?) (\d{2}).(\d{2}).(\d{2}).(\d{2}).(\d{2})(.) (.*)\r\n/g) {
	my @s = split(/~/, $9);
	my %r = (	"id"	=> $1,
				"time"	=> timelocal(0,$6,$5,$2,$3-1,$4),
				"path"	=> getRecordDirs($&)
			);
	$r{new} = 1 if $8 ne " ";
	#$r{len} = getRecordLength($r{path},"min");
	
	if (($r{dir} = $9) =~ /(.*)~/) { $r{dir} = $1 }
	else { $r{dir} = "" }
	
	pushRecord(\%{$h{subdirs}}, \@{$h{records}}, \@s, \%r);
}

return(%h);

sub pushRecord {
	#wenn Verzeichnis im Array noch vorhanden
	if (scalar(@{$_[2]}) > 1) {
		#${$_[0]}{id} = join(/_/,@{$_[2]});
		my $key = shift(@{$_[2]});
		for (@{$_[2]}) {
			pushRecord(\%{${$_[0]}{$key}{subdirs}}, \@{${$_[0]}{$key}{records}}, \@{$_[2]}, \%{$_[3]});
			# ${$_[0]}{$key}
		}
	}
	else {
		$_[3]{realname} = encode_entities($_[2][0]);
		($_[3]{name} = $_[2][0]) =~ s/^\%*//g;
		$_[3]{name} = encode_entities($_[3]{name});
		$_[3]{cut} = 1 if $_[2][0] =~ /^\%/;
		push(@{$_[1]}, \%{$_[3]});
		#@{$_[1]} = sort { $$b{time} cmp $$a{time} } @{$_[1]};
		}
}

sub getRecordDirs { # Gibt einen Array der Verzeichnisse zurck.                               -> ARRAY
	my $svdrprequest;
	if (! $_[0]) { $svdrprequest = Receive("LSTR") }
	else { $svdrprequest = $_[0] }

	my @dirs;
	while ($svdrprequest =~ /250.(\d*)\ (\d{2}).(\d{2}).(\d{2})\ (\d{2}):(\d{2})(.\d*:\d{2})?. (.*)\r\n/g) {
#	while ($svdrprequest =~ /250.(\d*)\ (\d{2}).(\d{2}).(\d{2})\ (\d{2}):(\d{2}). (.*)\r\n/g) {

	my $dir = $8;
	my $sub = "/20$4-$3-$2.$5.$6*.rec";

#	$dir =~ s/\_|\"|\\|\/|\:|\*|\?|\||\>|\<|\#/sprintf(uc("#%2x"), ord $&)/eg;
	$dir =~ tr/\//\\\//;
	$dir =~ tr/~/\//;
	$dir =~ tr/a-zA-Z_0-9\//\*/c;

	$dir = $OPT{videodir}."/".$dir.$sub;
	print STDERR "Can't read this dir ".$dir."\n" if ! -d bsd_glob($dir) && $debug;
	push (@dirs, $dir);
	}

	return @dirs;
}

}

sub getRecByID { # Gibt den Recordhash anhand der ID zurck, ARG0 -> Reordhash, ARG1 -> ID
for ( @{$_[0]{records}} ) { 
		return(%{$_}) if $$_{id} eq $_[1];
	}
for (keys(%{$_[0]{subdirs}})) {
	my %result = &getRecByID(\%{$_[0]{subdirs}{$_}}, $_[1]);
	return(%result) if $result{id};
	}
}

sub getRecByPath { # Gibt den Recordhash anhand der ID zurck, ARG0 -> Reordhash, ARG1 -> Path
for ( @{$_[0]{records}} ) { 
		return(%{$_}) if $$_{path} eq $_[1];
	}
for (keys(%{$_[0]{subdirs}})) {
	my %result = &getRecByPath(\%{$_[0]{subdirs}{$_}}, $_[1]);
	return(%result) if $result{path};
	}
}

sub getTimerIds { # Gibt Timerinfos aus ersetzt alle LSTT abfragen.  !!!!!!!!!!!!!! TODO
return(@timerinfo) if @timerinfo;
my $timer = Receive("LSTT");

while ($timer =~ /250.(\d*?)\ (.*?)\r\n/mg) {
	my $info; my %result;
	$result{no} = $1;
	
	my @t = split(":", $2);
	($info = $t[8]) =~ /<eventid>(.*?)<\/eventid>/;
		$result{id} = $1;
	# ($info = $t[8]) =~ /<start>(.*?)<\/start>/;
		# $result{start} = $1;
	# ($info = $t[8]) =~ /<stop>(.*?)<\/stop>/;
		# $result{stop} = $1;

		
		$info = sprintf("%04d",dec2bin($t[0]));
		my $l = length($info);
	$result{active} = substr($info,$l-1,1);
	$result{direct} = substr($info,$l-2,1);
	$result{vps} = substr($info,$l-3,1);
	$result{rec} = substr($info,$l-4,1);
		my %h = getChannel($t[1]);
	$result{channel} = \%h;

	$result{prio}  = $t[5];
	$result{life}  = $t[6];
	$result{title}  = encode_entities($t[7]);

	if ($t[2] =~ /^[-|M].*/) {
		($result{weekdays}, $result{first}) = split("@", $&);
		if ($result{first}) {
			split("-", $result{first});
			$result{first} = timelocal(0,0,0,$_[2], $_[1]-1, $_[0]);
		}
		$result{weekdays} =~ tr/-[A-Z]/01/;
		split("", $result{weekdays});
		$result{weekdays} = \@_;
	
		
		($info = $t[3].$t[4]) =~ /(\d{2})(\d{2})(\d{2})(\d{2})/;
		my $start = $1 * 3600 + $2 * 60;
		my $stop = $3 * 3600 + $4 * 60;
		$stop += 86400 if $stop < $start;

		my $d;
		my $time = time;
		while ($result{first} && $time + 86400 * 7 <= $result{first})  {
			$time += 86400 * 7;		
		}
		my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat, $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime($time);
		$Wochentag = 7 if ! $Wochentag;
		my $today = timelocal(0,0,0,$Monatstag, $Monat, $Jahr);
		
		for (@{$result{weekdays}}) {
			$d++;
			if ($_) {# && > first
				my $day = $d - $Wochentag;
				$day += 7 if abs($day) != $day;
				$result{start} = $today + $day * 86400 + $start;
				$result{stop}  = $today + $day * 86400 + $stop;
				# print STDERR $result{start}." = ".fdate($result{start},"#HH#:#MM#:#SS# #dd#-#mm#-#yy#")." - ".$day." $d\n";
				# print STDERR $result{stop}." = ".fdate($result{stop},"#HH#:#MM#:#SS# #dd#-#mm#-#yy#")." - ".$day." $d\n";
				my %temp = %result;
				push(@timerinfo, \%temp) if %result;
			}
		}
	}
	else {		
		($info = $t[2].$t[3].$t[4]) =~ /(\d{4})-(\d{2})-(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/;
		$result{start} = timelocal(0,$5,$4,$3,$2-1,$1);
		$result{stop} = timelocal(0,$7,$6,$3,$2-1,$1);
		$result{stop} += 86400 if $result{stop} < $result{start};
		
		push(@timerinfo, \%result) if %result;
	}
		
}
return(@timerinfo);
}

sub channels {

return(@channelinfo) if @channelinfo;
my @channels;

#_CONFIGUPDATE_
#channel switch
unless (-e $OPT{channels}) {
print STDERR "Can't find Channellist $OPT{channels}! Check the config file\n" if $OPT{channels};
my $chan = Receive("LSTC");
@channels = ({"name" => $L{CHANNELS}, "channels" => []});

while ($chan =~ /250.(\d*) (.*?)\r\n/g) {
 	my %channel;
	my @ids = split(/:/, $2);
	$channel{id} = join('-',$ids[3],$ids[10],$ids[11],$ids[9]); #erzeugen der ID

	my @t = split(/;/,$ids[0]); #abschneiden des Providers
	@t = split(/,/,$t[0]); # Aufteilen von Shortname und Longname
	$channel{lngname} = encode_entities($t[0]);
	$channel{shname} = encode_entities($t[1]);
	$channel{no} = $1;
	$channel{tid} = $ids[11]; #### nochmal checken obs richtig ist
		
	last if $channel{no} > $OPT{maxchannels} && $OPT{maxchannels};
	push (@{$channels[$#channels]{channels}}, \%channel);
}

}
else {
my @chan = fileArray($OPT{channels}); my $i = 1; 
foreach (@chan) {
	if ( $_ =~ /^:@(\d*) /) { # Z?ler neu setzen wenn neue Gruppenz?ler gr?er ist als momentane Position
		if ($i < $1) {$i = $1};
		next unless length($') > 1;
	}
	if ( $_ =~ /^:/) { # Gruppentext auslesen
		chomp(my $grp = $');
		$grp =~ s/^@\d* //;
		
		my %group;
		$group{name} = $grp;
		my @rray;
		$group{channels} = \@rray;
		push (@channels, \%group);
	}
	if ( $_ =~  /(.+?):(.*)/) { 
		if (@channels == 0) {
			my %group; my @rray;
			$group{name} = $L{CHANNELS};
			$group{channels} = \@rray;
			push (@channels, \%group);
		}
		my %channel;
		
		chomp((my $id = $2));
		my @ids = split(/:/, $id);
		$channel{id} = join('-',$ids[2],$ids[9],$ids[10],$ids[8]); #erzeugen der ID

		my @t = split(/;/,$1); #abschneiden des Providers
		@t = split(/,/,$t[0]); # Aufteilen von Shortname und Longname
		$channel{lngname} = encode_entities($t[0]);
		$channel{shname} = encode_entities($t[1]);
		$channel{no} = $i++;
		$channel{tid} = $ids[10];

		last if $channel{no} > $OPT{maxchannels} && $OPT{maxchannels};
		push (@{$channels[$#channels]{channels}}, \%channel);
	}
}

}

@channelinfo = @channels;
return(@channelinfo);
}

sub getChannelName { # Rckgabe des Channelnamens. Arg0 -> CHANNELNUMMER|ID Arg1-> [sh]			-> STRING

if (! $_[0]) { return() }
my $tag = $_[0]; my $param = $_[1];

my %chan = getChannel($tag);
	if (%chan) { 
		if (defined($param) && $param eq "sh") { return($chan{shname} || $chan{lngname}) }
		else { return($chan{lngname}) }
	}

return();
}

sub getChannelLogo { # ARGV0 -> channelid/no, ARGV1 -> 0=return(url) >0=return(imageElement) with imageheight
my %ch = getChannel($_[0]);
my $h = $_[1];
	for my $nm ($ch{lngname}, $ch{shname}) {	
		next unless $nm;
		$nm = decode_entities($nm);
		my @f = getfile($OPT{chaimages}, $nm.'\..{3,4}$');
		for my $fl (@f) {
		if (-e $fl) {
			my $file = uri_escape(basename($fl));
			return("$me?media=chapic&id=$file") unless $_[1];
			return("<img height=\"${h}px\" style=\"vertical-align:middle;\" src=\"$me?media=chapic&id=$file\" />");
		}
		}
	}
	return(0);
}

sub getChannel { # Rckgabe des Channelhashes. Arg0 -> CHANNELNUMMER|ID Arg1-> [sh]			-> STRING

if (! $_[0]) { return() }
my $tag = $_[0]; 

my @channels = &channels;
for (@channels) { for (@{$$_{channels}}) { if ($$_{id} eq $tag || $$_{no} eq $tag) { return(%$_) } } }
return();
}

sub epgSplit { # bekommt den inhalt von 215-E und e. Erstellt den hash epgdata			-> HASH

my @event; if ($_[0] =~ /215-E (\d*?) (\d*?) (\d*?) (.*?) (.*)/) { $event[0] = $1; $event[1] = $2;$event[2] = $3;$event[3] = $4;$event[4] = $6; }
# Events 0: ID  1: Startzeitpunkt UTC  2: L?ge Sekunden  3: ?  4: ?
my $titel; if ($_[0] =~ /215-T (.*)/) { $titel = $1 }
my $sub; if ($_[0] =~   /215-S (.*)/) { $sub = $1 }
my $info; if ($_[0] =~  /215-D (.*)/) { $info = $1 }
my $vps; if ($_[0] =~   /215-V (.*)/) { $vps = $1 }
my @audio; while ($_[0] =~ /215-X (.*)\n/g) {  push(@audio, $1) } #1=Video 2=Audio
my %h =("E" => \@event,
		"T" => $titel,
		"S" => $sub,
		"D" => $info,
		"X" => \@audio,
		"V" => $vps);		
}

sub epgli { # Erzeugt ein EPG-Element  0. AT|NOW|SEARCH  1. Title  2. Subtitle 3. Starttime 4. Stopptime 5. Channelid 6. EPGID 7. first<a>child	-> UL-ARRAY

my $timestring; my $sub; my $list = " float:right; text-align:right;";
my @ti = getTimerIds();
if ($_[0] =~ /AT|NOW/i) { $timestring = fdate($_[3], $timef{channeltimeto})."<br>" }
elsif ($_[0] =~ /SEARCH/i) {
	my $chl = getChannelLogo($_[5], 24);
	$chl = "&nbsp;&nbsp;".$chl if $chl;
	$list = "";
	$timestring = fdate($_[3], $timef{channeltime})." - ".fdate($_[4], $timef{channeltimeto})." ".($chl || getChannelName($_[5], "sh"))."<br>"; 
}
elsif ($_[0] =~ /SCHED/i) { $timestring = fdate($_[3], $timef{channeltimeto})."&nbsp;&nbsp;"; }
else { $timestring = fdate($_[3], $timef{channeltimeto})."<br>".timediff((time - $_[3]), $L{TILL}, $L{IN}, "min", " ".$L{MINUTES})."<br>"  }
if ($_[2]) { $sub = "<font class='subfont'>".$_[2]."</font>" }
else { $sub = "" }
my $class = "none"; my @chinfo = split("-", $_[5]); my $tiid; my $hit;
for my $item (@ti) {
	# print STDERR $_[6]." - ".$$item{id}."\n";
	if ($_[6] eq $$item{id}) {
		if ($$item{active}) { $class = "rec"; } else {  $class = "recdeact" }
		$tiid = $$item{no};
		last;
	}
	if ($$item{active} 
		&& $chinfo[2] ne $$item{channel}{tid} 
		&& ($_[3] >= $$item{start} && $_[3] <= $$item{stop} 
			|| $_[4] >= $$item{start} && $_[4] <= $$item{stop} 
			|| $_[3] < $$item{start} && $_[4] > $$item{start})
			) {
			
			
			$hit = ($_[3] > $$item{start} ? $_[3] - $$item{start} : 0) + ($$item{stop} > $_[4] ? $$item{stop} - $_[4] : 0);
			$hit = int(($$item{stop} - $$item{start} - $hit)/($_[4] - $_[3])*100)."%";

		$class = "attention";
		#print STDERR $$item{channel}{tid}."\n";
		#my @t = ($_[3], $_[4], $$item{start}, $$item{stop});
		#@t = map { fdate($_, "#HH#:#MM#") } @t;
		#print STDERR $chinfo[2]." ".join(" - ", @t)." ".$$item{channel}{tid}." - ".$x." : ".int(($$item{stop} - $$item{start} - $x)/($$item{stop} - $$item{start})*100)." - ".($_[4] - $_[3])."\n";
	}	
}

my $onclick; my $httag = encode_entities($_[1]);

if ($tiid) { $onclick = "timDialog(\"".$tiid."\", \"".$_[5]."\", \"".$_[6]."\", 0)" }
else { $onclick = "epgDialog(\"".$_[5]."\", \"".$_[6]."\", \"".$httag."\", \"".$_[0]."\", \"".$_[3]."\")" }

my $innerLI;
$innerLI = "<font class='topfont' style='$list'>$timestring</font><font class='mainfont'> ".$httag."</font> ";#.$sub unless $hit;

my $img; my $style;
if (-f $OPT{epgimages}."/".$_[6].".png") {
	$img = "<img style='z-index:-1; position:absolute; left:0px; height:90px' src='$me?media=epgpic&id=$_[6]' />";
	$style="style='min-height:90px; padding-left: 128px'";
	$sub ="$sub";
}
return("", "_special", "<li>$_[7]$img<font style='position:absolute; right:8px; top 8px;' class='minifont'>$hit</font><a $style onclick='$onclick' class='$class'>$innerLI<br>$sub</a></li>"); 

}

# ------------------------------ epgSearch Subs ---------------------------

sub getSearch { # Erzeugt den Suchstring, bergabe %epgSearchHash    -> STRING / HASH ( bei keinem parameter bergeben)
# in dem hash key "orginalsearch" kann ein orginal epgsearch string bergeben werden.
# damit nicht bergebene aus dem formular nicht mit dem standartwert ersetzt werden.

my %h = @_;
my @org = split(":", $h{orginalsearch}) if $h{orginalsearch};

$h{string} =~ s/:/|/g; # !!!!!!!!!!!  anfang der vdr entities

push(my @s, $h{id}, $h{string}, $h{usetime}, $h{start}, $h{stop}, $h{usechannel}, $h{channel}, $h{case}, $h{modus}, $h{stitle}, $h{ssubtitle}, $h{sdescr},
$h{uselength}, $h{minlength}, $h{maxlength}, $h{use}, $h{useday}, $h{day}, $h{serie}, $h{dir}, $h{prio}, $h{life}, $h{prefix}, $h{suffix}, $h{vps},
$h{action}, $h{extepg}, $h{extepgfield}, $h{noreplay}, $h{replaycount}, $h{comptitle}, $h{compsubtitle}, $h{compdescr}, $h{compextepg}, $h{replaydays},
$h{deletedays}, $h{recordcount}, $h{switchtime}, $h{recordmax}, $h{typeexlude}, $h{exlude}, $h{fuzzy}, $h{fav}, $h{preentry});

my @alt = split(":", "0::0:::0::0:0:1:1:1:0:::0:0::0:$OPT{stddir}:$OPT{priority}:$OPT{lifetime}:".int($OPT{pretime}/60).":".int($OPT{suftime}/60).":0:0:0::0:0:0:0:0:0:0:0:0::0:0:::0:");

my @result;

for (0..43) {
if (defined($s[$_])) { push (@result, $s[$_]) }
elsif (defined($org[$_])) { push (@result, $org[$_]) }
else { push (@result, $alt[$_]) }
}

return(@result);

}

sub doSearch {	# Erzeugt das Suchergebenis ARG0 -> ID|SETTINGS|FAV   -> UL array

my $type = "";
$type = "QRYS" if $_[0] !~ "^QRYF";
my $result = Receive("PLUG epgsearch $type ".join(" ", @_));
#print STDERR $result."\n";
my $oldday=""; my @ul; my $oldid;
while ($result =~ /900.(.*?)\r\n/g) {
	my @tag = split(":", $1);
	# 1. AT|NOW|SEARCH  2. Title  3. Subtitle 4. Starttime 5. Stopptime 6. Channelid 7. EPGID
	my $day = fdate($tag[4], $timef{timergroup});
	if ($tag[1] ne $_[1] && $tag[1] ne $oldid ) {
	#push(@ul, "","_group",$day) if $day ne $oldday;
	push(@ul, "", "_special", "<li class='group' id='".fdate($tag[4], "#dddd# #dd#.")."'><nobr>".$day."</nobr></li>\n") if $day ne $oldday;
	
	push(@ul, epgli("SEARCH", $tag[2], $tag[3], $tag[4], $tag[5], $tag[6], $tag[1]));
	$oldday = $day;
	$oldid = $tag[1];
	}
}
# Klasse _no h?gt an Kein Eintrag gefunden zwecks nur leere zeigen.
@ul = ("", "_no", $L{NOENTRY}) if (@ul < 1);

return(@ul);
}

1;