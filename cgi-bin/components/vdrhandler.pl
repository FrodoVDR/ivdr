
require vdr;

if ($form_input ->{'REC'}) { 				# Erzeugt die Aufnahmen $query[1] DELR && $query[3] REC_ID && $query[2] HASH l�cht REC  $query[1] hash zeigt selected diesen

if ($form_input ->{'REC'} eq "DELM")  { 
	
	my @ids;
	if (ref $form_input->{'IDS'}) {	@ids = sort { $b <=> $a } @{$form_input->{'IDS'}} } else { @ids = ($form_input->{'IDS'}) }

	for (sort { $b <=> $a } @ids) {
		print STDERR "Deleted Recordno.: ".$_."\n" if $debug;
		Send("DELR ".$_);
	}
}
elsif ($form_input ->{'REC'} eq "MOVR")  { 
	my %rs = recordHash(Receive("LSTR"));

	my %r = getRecByID(\%rs, $form_input ->{'ID'});
	print STDERR "MOVR ".$form_input ->{'ID'}." ".$r{dir}."~".$form_input ->{'STRING'}."\n" if $debug;
	Send("MOVR ".$form_input ->{'ID'}." ".$r{dir}."~".$form_input ->{'STRING'});
}
elsif ($form_input ->{'REC'} eq "MOVM")  { 
	
	my %rs = recordHash(Receive("LSTR"));
	my $dir = $form_input->{'STRING'}; 
	$dir .= "~" if $dir !~ /~$/;
	my @ids;
	if (ref $form_input->{'IDS'}) {	@ids = sort { $b <=> $a } @{$form_input->{'IDS'}} } else { @ids = ($form_input->{'IDS'}) }
	my @path;
	for (@ids) {
		my %_tmp = &getRecByID(\%rs ,$_);
		push(@path, $_tmp{path});
	}

	for my $p (@path) {
		%rs = recordHash(Receive("LSTR"));
		my %r = getRecByPath(\%rs, $p);
#		my %sepg;
#		%sepg = epgSplit(Receive("LSTR $r{id}"));
		print STDERR $p."  ->  ".$r{path}."\n" if $debug;;
#		print STDERR "Sub: $sepg{S}\n";
		print STDERR "MOVR ".$r{id}." ".$dir.$r{name}."\n" if $debug;
		Send("MOVR ".$r{id}." ".$dir.decode_entities($r{name}));
		select(undef,undef,undef,.3); # Wait to give VDR time to reorg before sending new list
	}
}
# $form_input ->{''}

my %h = recordHash(Receive("LSTR"));

my $st = defined($form_input ->{'st'}) ? $form_input ->{'st'} : $OPT{predefinedorder};
my $sq = defined($form_input ->{'sq'}) ? $form_input ->{'sq'} : $OPT{predefinedsort};
sortRecords(\%h, $st, $sq);
#print STDERR Dumper(%h);
# wenn kein verz selected wird obwohl $query[1] dann leeres ul erzeugen... true  bei $_[3] ist selected!!!!!!!!!!!!!!!
ulRecords(\%h, "ln_rec", $L{RECORDS}, $form_input ->{'hs'} || "");


quitSocket();
exit(0);

sub ulRecords {
my @ul;
(my $ID = $_[1]) =~ tr/a-zA-Z_0-9//cd;

my $sel = "false";
$sel = "true" if $_[3] eq $ID;

push(@ul, $ID, $_[2], $sel."' scroll='view' temporary='all' tag='".$ENV{'REQUEST_URI'});  # <- Refresh url sendet auch kritischen Parametern

my $recURL = $me."?REC=LIST&hs=".$ID."&";

my $iTab;
$iTab .= "<ul name='recoption' style='display:none' class='iTab'>";
# Headbuttons
# st -> Sortierungsart 0->Datum 1->Alphanumeric 2->Dauer sq->Auf/ab hs->activehash
$iTab .= "<li><a class='iBigTab' href='".$recURL."st=1&sq=".($sq || 0)."' style='margin-top:-1px;'>&#8986;</a></li>" if ! $st;
$iTab .= "<li><a href='".$recURL."st=2&sq=".($sq || 0)."'>abc</a></li>" if $st == 1;
$iTab .= "<li><a class='iBigTab' href='".$recURL."st=0&sq=".($sq || 0)."' style='margin-top:-1px;'>&#8987;</a></li>" if $st == 2;
$iTab .= "<li><a class='iBigTab' href='".$recURL."st=".($st || 0)."&sq=1'>&#9652;</a></li>" if ! $sq;
$iTab .= "<li><a class='iBigTab' href='".$recURL."st=".($st || 0)."&sq=0'>&#9662;</a></li>" if $sq == 1;
# $iTab .=    "<li><a class='iBigTab' onclick='unCheck();'>&#1234;</a></li>";
$iTab .= "<li name='multiSelectButton'><a onclick='chooseButton();'>$L{SELECT}</a></li>";
$iTab .= "<li><a onclick='recBar(false)'><img src='$weburl/AddressViewStop.png' /></a></li>";
$iTab .= "</ul>";

$iTab .= "<a name='recoptiontoggle' class='button' style='display:block' onclick='recBar(true)'>&nbsp;&nbsp;...&nbsp;&nbsp;</a>";

push(@ul, "", "_special", $iTab);

for (keys(%{$_[0]{subdirs}})) {
my $new = 0; my $sum = 0;
	# print "\tVerzeichnis: ".$_."\n";
	(my $subID = $_) =~ tr/a-zA-Z_0-9//cd;
	for (@{$_[0]{subdirs}{$_}{records}}) {
		$sum++;
		$new++ if $$_{new};
	}
	my $infolder = "<font class='roundmark'>$new &#149; $sum</font>";
	push(@ul, "","_special" , "<li><a href='#".$ID."_".$subID."' class='folder'><nobr><table width='100%'><tr><td class='recorddir'>".encode_entities($_)."</td><td width='1px'>$infolder</td></tr></table></nobr></a></li>" );
}
my $id =""; 
for ( @{$_[0]{records}} ) {
	my $class = "none"; $class = "newicon" if $$_{new}; $class = "cuticon" if $$_{cut};
	(my $recname = $$_{realname}) = s/'/\\'/g;;
	my $httag = $$_{name};
	my $reclength = getRecordLength($$_{path},"min") if $OPT{videodir};
	my $reclengthtxt = " &#149; ".getRecordLength($$_{path},"min")." " if $OPT{videodir};
	my $bol; my $type; my $dtype; my $name;
	if (@{$_[0]{records}} > 15) {
		if (@{$_[0]{records}} < 50) { 
			$dtype = "#ddd# #dd#.#mm#.";
			$name = $httag;
		} else { 
			$dtype = "#mmm# #y#";
			$name = substr($httag, 0 ,1);
		}
		$type = " id='".fdate($$_{time},$dtype)."'" if $st == 0;
		$type = " id='".$name."'" if $st == 1;
		$type = " id='".$reclength."'" if $st == 2 && $OPT{videodir};
		if ($id ne $type) {$id = $type; $bol = 1} else { $bol = 0 }
	}
	push(@ul, "",
	"_special",
	"<li".($bol ? $id : "")."><a tag='".$$_{id}."' name='record' onclick='recDialog(\"".$$_{id}."\", \"".$ID."\", this, \"".$recname."\", ".($st || 0).", ".($sq || 0).")' class='$class'>".
	"<font class='topfont'>".fdate($$_{time},$timef{record}).$reclengthtxt."</font><br><font class='mainfont'>$httag</font></a></li>");

}

buildul(@ul);

for (keys(%{$_[0]{subdirs}})) {
	ulRecords( \%{$_[0]{subdirs}{$_}}, $_[1]."_".$_, $_, $_[3]);
	}
}

sub sortRecords {	# Sortiert den angegebenen Subdirhash mit unterverzeichnissen ARG0 -> Hash, Arg1 -> Methode Datum, Name, L�ge, Arg2 -> Aufsteigend/Absteigend

my $sorttype;
$sorttype = "time" if ! $_[1];
$sorttype = "name" if $_[1] == 1;
if ($_[1] == 2) {
	$sorttype = "len";
	for(@{$_[0]{records}}) {
		$$_{len} = $& if getRecordLength($$_{path}, "min") =~ /\d+/;
	}
	if ($_[2]) { @{$_[0]{records}} = sort { lc($$b{$sorttype}) <=> lc($$a{$sorttype}) } @{$_[0]{records}} }
	else { @{$_[0]{records}} = sort { lc($$a{$sorttype}) <=> lc($$b{$sorttype}) } @{$_[0]{records}} }
} else {
	if ($_[2]) { @{$_[0]{records}} = sort { lc($$b{$sorttype}) cmp lc($$a{$sorttype}) } @{$_[0]{records}} }
	else { @{$_[0]{records}} = sort { lc($$a{$sorttype}) cmp lc($$b{$sorttype}) } @{$_[0]{records}} }
}


for (keys(%{$_[0]{subdirs}})) {
	&sortRecords(\%{$_[0]{subdirs}{$_}}, $_[1], $_[2]);
	}
}

}
elsif ($query[0] eq "TIMER") { 				# Erzeugt die Timerliste > $query[1] preSvdrpCommand;  $query[2] -> ID; 

if($query[1]) { 
	if ($query[1] eq "ONOFF") {
		my $item = Receive("LSTT $query[2]");
		my @split = split(":", $item);
		if (substr($split[0], length($split[0])-1) eq "0" ) { $item = "ON" } else { $item = "OFF" }
		Send("MODT $query[2] ".$item);
	}
	elsif ($query[1] eq "DELT") {
		Send("DELT $query[2]");
	}
	else {
		shift(@query);
		Send(@query);
	}
}

my @ul;
my $conflict = Receive("PLUG epgsearch LSCC REL"); # REL sorgt fr absturtz wenn kein Konflict vorhanden. !!!!!!!!!!!!!!
my @cs;
while ($conflict =~ /900.(\d*?):(\d*?)\|(\d*?)\|(.*?)\r\n/g) { push(@cs, split("#", $4)) }

my @sortedtimers = sort { $$a{start} <=> $$b{start} } getTimerIds();
my $oldday = 0;
for (@sortedtimers) {
	
	my $class = "";	my $active = "";
	if ($$_{active} &! $$_{rec}) { 
		$class = "none";
		for my $id (@cs) { if ($id eq $$_{no}) {$class = "attention"; last;} }
	} 	# normal wenn zwischen 1 und 7
	elsif (! $$_{active}) { $class = "cancel"; $active = "grayed" }  		# deaktiviert wenn 0
	elsif ($$_{rec}) { $class = "rec" } 		# aktiviert wenn gr�er 8
	
	my $timeval = fdate($$_{start}, $timef{channeltime}." - ").fdate($$_{stop}, $timef{channeltimeto})." (".timediff($$_{stop}-$$_{start},"","","min","&prime;", "0&prime;")." )";
	my $length = "(".$$_{prio}."/".$$_{life}.") ";

	#push(@ul, "","_group", fdate($$_{start}, $timef{timergroup})) if ($oldday ne fdate($$_{start},"#dw#"));
	push(@ul, "", "_special", "<li class='group' id='".fdate($$_{start}, "#dddd# #dd#.")."'><nobr>".fdate($$_{start}, $timef{timergroup})."</nobr></li>\n") if ($oldday ne fdate($$_{start},"#dw#"));
	my @dirs = split(/~/, $$_{title});
	
	push(@ul, "", "_no", 
	"<a onclick='timDialog(\"".$$_{no}."\", \"".$$_{channel}{id}."\", \"".$$_{id}."\", 1)' class='$class'><nobr><font class='topfont $active' style='float:none'>".$timeval."</font>".
	"<font class='mainfont $active'>&nbsp;&nbsp;".(getChannelLogo($$_{channel}{id}, 24) || $$_{channel}{lngname})."<br>".pop(@dirs)."</font><br><font class='minifont $active'>".$length." ".join(" ~ ", @dirs)."</font></nobr></a>");	
	$oldday = fdate($$_{start},"#dw#");
} 

unshift(@ul, "", "_special", addrefButton("$me?TINFO+new"));

unshift(@ul,  "ln_timer", $L{TIMER}, "false' temporary='yes' scroll='view' tag='".$me."?TIMER");
buildul(@ul);

quitSocket();
exit(0);
}
elsif ($query[0] eq "NOW") {				# Erzeugt Jetzt oder N�hste; onlyli ARG1->"onlyli" ARG1->[Channelgroup]

my $head; my @ul; # Arg0->ID Arg1->Title, Arg2->visible[true,false] (ist das Mainmen?), ab Arg3 link, target, title
$head = $L{NOW} if $query[0] =~ /NOW/i;

my $nowepg = Receive("LSTE $query[0]");
my $nextepg = Receive("LSTE NEXT");

if (lc($query[1]) eq "onlyli"){
	@ul = ("", "", "");
	$query[0] = shift(@query);
}
else { 
	@ul = ("ln_now", $head, "false' temporary='yes' scroll='view' tag='".$ENV{'REQUEST_URI'});

	#push(@ul, "", "_special", "<a id='rightButton' style='padding:4px 10px 0; margin:-1px 0 0' class='button' href='$me?".join("+",@query)."'><img src='".$weburl."/reload.png' /></a>");	
	push(@ul, "", "_special", refreshButton());
	}

my @channelgrps = &channels;
my $lastid;

for (my $i=0; $i <= $#channelgrps; $i++) {
    if (! defined($query[1]) || $i eq $query[1]) {
	    for my $ch (@{$channelgrps[$i]{channels}}) {
			if ($$ch{id}) {
				my $item; my $epgid; 
				#push(@ul, "", "_group", "<nobr>".$$ch{lngname}."</nobr></li>\n");	
				my $chl = getChannelLogo($$ch{id}, 18); #.($chl ? "&nbsp;".$chl."&nbsp;&nbsp;" : "").
				if ($OPT{usecategory}) {
					my $id;
					if ($lastid ne $channelgrps[$i]{name}) {
						$id = "id='".$channelgrps[$i]{name}."'";
						$lastid = $channelgrps[$i]{name};
					}
					push(@ul, "", "_special", "<li class='group' ".$id."><nobr>".($chl ? "&nbsp;".$chl."&nbsp;&nbsp;" : "").$$ch{lngname}."</nobr></li>\n");	
				}
				else {
					push(@ul, "", "_special", "<li class='group' id='".($$ch{shname} || $$ch{lngname})."'><nobr>".($chl ? "&nbsp;&nbsp;".$chl : "").$$ch{lngname}."</nobr></li>\n");	
				}
				
				my $tmp = $nowepg;
				if ($tmp =~ /215-C $$ch{id}.*?215-c/gs) {
					$item = $&;	
					my %sepg = epgSplit($item);
					if ($sepg{T}) {
						my $pos = int(int(time - $sepg{E}[1]) / ($sepg{E}[2] || int(time - $sepg{E}[1]))*100)."%";
						push(@ul, epgli($query[0], $sepg{T}, $sepg{S}, $sepg{E}[1], $sepg{E}[1] + $sepg{E}[2], $$ch{id}, $sepg{E}[0]
						,"<hr noshade width='$pos' color='#6495ED ' size='10' align='left' style='margin:-5px 0px 0px -10px; padding: 0px 0px 0px 0px'>"));			
					}
					else { $item = "" }
				}

				my $tmp = $nextepg;
				if ($tmp =~ /215-C $$ch{id}.*?215-c/gs) {
					$item = $&;	
					my %sepg = epgSplit($item);
					if ($sepg{T}) {
						$epgid = $sepg{E}[0];
						push(@ul, epgli("NEXT", $sepg{T}, $sepg{S}, $sepg{E}[1], $sepg{E}[1] + $sepg{E}[2], $$ch{id}, $epgid));
						push (@ul, "$me?NEXTEPGITEM+".$$ch{id}."+".$epgid."' class='small", "_replace", "$L{MORE} ...");
					}
					else { $item = "" }
				}
				
				push(@ul, "", "_no", "<a onclick='epgDialog(\"".$$ch{id}."\", \"NOEPG\", \"$$ch{lngname}\", \"SCHED\")' class='none'><font class='mainfont'>$L{NOEPG}</font></a>") unless $item;
			}	}	}	}

buildul(@ul);
quitSocket();
exit(0);
}
elsif ($query[0] =~ /^AT\d{4}/i) {			# Erzeugt Jetzt oder N�hste; onlyli ARG1->"onlyli" ARG1->[Channelgroup]

my $head; my @ul; # Arg0->ID Arg1->Title, Arg2->visible[true,false] (ist das Mainmen?), ab Arg3 link, target, title
my $t;

my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat, $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(time);
$t = timelocal(0,substr($query[0], 4), substr($query[0],2,2),$Monatstag, $Monat, $Jahr); 
# LANGUAGE
my $mn = $L{TODAY};
if ($t < time) {
	$t += 86400;
	$mn = $L{TOMORROW};
}

$head = $mn." ".fdate($t, $timef{channeltimeto});

# $query[0]="AT";

if (lc($query[1]) eq "onlyli"){
	@ul = ("", "", "");
	$query[0] = shift(@query);
}
else { 
	@ul = ("ln_at", $head, "false' temporary='yes' scroll='view' tag='".$ENV{'REQUEST_URI'});
#	push(@ul, "", "_special", "<a id='rightButton' style='padding:4px 10px 0; margin:-1px 0 0' class='button' href='$me?".join("+",@query)."'><img src='".$weburl."/reload.png' /></a>");	
	push(@ul, "", "_special", refreshButton());	 #.join("+",@query)
}

my %epg = getEpg24();

my @sortedChannels;
my @channelgrps = &channels;
my $lastid;
# print STDERR "<---------- Starte �ermittlung\n";

for (my $i=0; $i <= $#channelgrps; $i++) {
    if (! defined($query[1]) || $i eq $query[1]) {
	    for my $ch (@{$channelgrps[$i]{channels}}) {
			if ($$ch{id}) {
				my $chl = getChannelLogo($$ch{id}, 18);
				if ($OPT{usecategory}) {
					my $id;
					if ($lastid ne $channelgrps[$i]{name}) {
						$id = "id='".$channelgrps[$i]{name}."'";
						$lastid = $channelgrps[$i]{name};
					}
					push(@ul, "", "_special", "<li class='group' ".$id."><nobr>".($chl ? "&nbsp;".$chl."&nbsp;&nbsp;" : "").$$ch{lngname}."</nobr></li>\n");	
				}
				else {
					push(@ul, "", "_special", "<li class='group' id='".($$ch{shname} || $$ch{lngname})."'><nobr>".($chl ? "&nbsp;".$chl."&nbsp;&nbsp;" : "").$$ch{lngname}."</nobr></li>\n");	
				}
#				push(@ul, "", "_group", $$ch{lngname}); 
				if ($epg{$$ch{id}}) {
					my %h = %{$epg{$$ch{id}}}; my $epgid;
					for (1..3) {
						for (keys(%h)) {
							if (($h{$_}{E}[1] <= $t && $h{$_}{E}[1] + $h{$_}{E}[2] > $t && ! $epgid) 
							|| ($epgid && $h{$epgid}{E}[1] + $h{$epgid}{E}[2] == $h{$_}{E}[1])) {
								push(@ul, epgli("AT", $h{$_}{T}, $h{$_}{S}, $h{$_}{E}[1], $h{$_}{E}[1] + $h{$_}{E}[2], $$ch{id}, ($epgid = $h{$_}{E}[0])));
								last;
							}
						}
					}
					push (@ul, "$me?NEXTEPGITEM+".$$ch{id}."+".$epgid."' class='small", "_replace", "$L{MORE} ...");
				}
				else {
					push(@ul, "", "_no", "<a onclick='epgDialog(\"".$$ch{id}."\", \"NOEPG\", \"$$ch{lngname}\", \"SCHED\")' class='none'><font class='mainfont'>$L{NOEPG}</font></a>");
				}
			}
}	}	}

buildul(@ul);
quitSocket();
exit(0);


sub getEpg24 {

return(%epgdata) if %epgdata;

# print STDERR "----> Bilde EPGDATEN\n";

# %epginfo <- id = channel
# - %epgitems <- id = eventid 

my @chanepg; my $epgsource; my $ch;

$epgsource = Receive("LSTE");

while ($epgsource =~ /215-C.*?215-c/gs) {
	(my $chan = $&) =~ /215-C (.*?) (.*)/;	
	$ch = $1;
	while ($chan =~ /215-E.*?215-e/gs) {		
		my $item = $&;
		my %sepg = epgSplit($item);
		$epgdata{$ch}{$sepg{E}[0]} = \%sepg;
		last if $sepg{E}[1] > time + 90000;
	}	
}

return(%epgdata);

}

}
elsif ($query[0] eq "NEXTEPGITEM") {				# Gibt ein ein EPG-Item [CHANNELID] [PRE-EPGID]
shift(@query);

my @item = getNextEpgItem(@query);
print $item[0];
print "<li><a href='$me?NEXTEPGITEM+$query[0]+$item[1]' class='small' target='_replace'>$L{MORE} ...</a></li>";

quitSocket();
exit(0);


sub getNextEpgItem { # Gibt ein Array zurck 1. das Special epg <LI>  des darauffolgenden EPG Eintrags und 2. Die Event-ID Erwartet [CHANNEL-ID] [EVENT-ID]

my $epg;
	# print STDERR "----> Bilde EPGDATEN\n";
	$epg = Receive("LSTE $_[0]");
	my @epginfo = dblSplit("215-E", "215-e", $epg);

my %sepg; my $last;
for (@epginfo) {
%sepg = epgSplit($_);
last if $last;
$last = 1 if $sepg{E}[0] eq $_[1];
}
my @ul = epgli('NOW', $sepg{T}, $sepg{S}, $sepg{E}[1], $sepg{E}[1] + $sepg{E}[2], $_[0], $sepg{E}[0]);

my $result = $ul[2];

return($result, $sepg{E}[0]);

};

}
elsif ($query[0] eq "FAV") {				# Gibt die Favoriten aus

my @ul = ("favorite", $L{FAVS}, "false' temporary='yes' scroll='view' tag='".$ENV{'REQUEST_URI'});

push(@ul, doSearch("QRYF", $OPT{fav_hours}));

buildul(@ul);

quitSocket();
exit(0);
}
elsif ($query[0] eq "SEARCHRESULT") {		# Suchergebniss [ID] [Name]

my %search; my @ul = ("epgsearchresult", $L{SRESULT}, "false' temporary='yes' scroll='view' tag='".$ENV{'REQUEST_URI'});

push(@ul, doSearch($query[1]));

buildul(@ul);

quitSocket();
exit(0);
}
elsif ($query[0] eq "EPGSEARCH") {			# epgsearchTimer > $query[1] preSvdrpCommand
#PLUG+epgsearch+MODS+$query[1]+OFF

if($query[1]) { 
	if ($query[1] eq "ONOFF") {
		my $item = Receive("PLUG epgsearch LSTS $query[2]");
		my @split = split(":", $item);
		if ($split[15] eq "1" ) { $item = "OFF" } else { $item = "ON" }
		Send("PLUG epgsearch MODS $query[2] ".$item);
	}
	elsif ($query[1] eq "DELS") {
		Send("plug epgsearch DELS $query[2]");
	}
	else {
		shift(@query);
		Send(@query);
	}
}

my $search = Receive("PLUG epgsearch LSTS");

my @ul = ("epgsearch",$L{STIMER},"false' temporary='yes' scroll='view'  tag='".$me."?EPGSEARCH");
#push(@ul, "", "_special", addrefButton("$me?EPGSEARCHFIELD+new"));
push(@ul, "", "_special",
		"<ul class='iTab'>
			<li onclick='this.style.display = \"none\"; getElementsByName(\"_epgsoptbar\")[0].style.display = \"block\"; getElementsByName(\"epgsbtn\")[0].style.display = \"block\"; getElementsByName(\"epgsbtn\")[1].style.display = \"block\";'>&nbsp;&nbsp;&nbsp;...&nbsp;&nbsp;&nbsp;</li>
			<!-- addrefButton -->
			<li name='epgsbtn' style='display:none'><a href='$me?EPGSEARCHFIELD+new' target='_changewindow'><img src='".$weburl."/mplus.png' /></a></li>
			<li name='epgsbtn' style='display:none'><a onClick='iui.refreshPage()'><img src='".$weburl."/reload.png' /></a></li>
		</ul>");

push(@ul, "", "_special", "<li name='_epgsoptbar' class='bar' style='display:none;'>
<a class='inlinebutton' onclick='searchBarSet(this, 0)'>$L{ACTIV}</a>
<a class='inlinebutton' onclick='searchBarSet(this, 1)'>$L{INACTIV}</a>
<a class='inlinebutton' onclick='searchBarSet(this, 2)'>$L{NOHIT}</a>
</li>"
);

my @s;
while ($search =~ /900.(.*?)\r\n/g) {
	my @item = split(":", $1);
	push (@s, \@item);
}

my @sort = sort { uc($$a[1]) cmp uc($$b[1]) } @s;

my $alfa;
for my $s (@sort) {
	my $color = $$s[15] ? "" : "grayed";
	my $class = $$s[15] ? "none" : "cancel";
	my $name = "name = '1'"; # wenn deaktiviert
	if ($$s[15]) {
		$name = "name = '0'"; # wenn normal 
		my @al;
		push(@al, doSearch($$s[0]));
		if (@al[1] eq "_no") { $name = "name = '2'" } # wenn keine Eintr�e gefunden
	}
	
	
	my $httag = encode_entities($$s[1]);
	
	my $id; my $l = substr(uc($$s[1]),0,1);
	
	if ($alfa ne $l) { 
		$id = "id='".$l."'"; 
		$alfa = $l; 
	}
	else { $id = ""; }
#	push(@ul, "", "_special", "<li '".$id."'><a onclick='espDialog(\"".$$s[0]."\", \"".$httag."\")' class='$class'><font class='mainfont $color'> ".$httag."</font></a></li>");
	push(@ul, "", "_special", "<li ".$name." ".$id."><a onclick='espDialog(\"".$$s[0]."\", \"".$httag."\")' class='$class'><font class='mainfont $color'> ".$httag."</font></a></li>");
#	push(@ul, "", "_special", "<li ".$name." ".$id."><a onclick='for (var el in getElementsByName(\"1\")) getElementsByName(\"1\")[el].style.display = \"none\"' class='$class'><font class='mainfont $color'> ".$httag."</font></a></li>");
	
	}

buildul(@ul);

quitSocket();
exit(0);
}
elsif ($query[0] eq "CHANINFO") { 			# Erzeugt die EPG Daten fr einen Sender [Kanalnummer|ID]
if (! defined($query[1])) {die "Fehlender Parameter: Kanalnummer!"}

my $epg = Receive("LSTE $query[1]");
my @ul; # Arg0->ID Arg1->Title, Arg2->visible[true,false] (ist das Mainmen?), ab Arg3 link, target, title
my %sepg;
my @epgdata = dblSplit( "215-E", "215-e", $epg);
# array von channel
	# hash channel
	# 215-C Kanalname  (215-C oder erster)
	# array von epgdata
		# hash epgdata
		# 215-E / Event -> (array 0. EventID; 1. Startzeit als time_t Integer Zahl in UTC; 2. Dauer in Sekunden; 3 TableID hexadezimale Zahl, die angibt in welcher Event-Tabelle das enthalten ist.  5. Version
		# 215-T / Titel     -> (einfacher string)
		# 215-S / Subtitel -> (einfacher string)
		# 215-D / Informationen -> (string mit | trennung der einzelnen elemente) (evtl. in eigenen hash umwandeln oder | in newline umwandeln)
		# 215-X / Audioinformationen -> (array) 
		# 215-V / VPSinformationen -> string
		
#$query[0] =~ /215-C (.*?) (.*)/; ?????????
@ul = ("ln_sched", getChannelName($query[1]), "true' temporary='yes' scroll='view' tag='".$ENV{'REQUEST_URI'});

my $t; my $timestring; my $day; my $oldday = ""; my $sub;

foreach	my $item (@epgdata) {
	%sepg = epgSplit($item);
	$day = fdate($sepg{E}[1], $timef{channelday});
	#push(@ul, "", "_group", $day) if ($day ne $oldday);
	push(@ul, "", "_special", "<li class='group' id='".fdate($sepg{E}[1], "#dddd# #dd#.")."'><nobr>".$day."</nobr></li>\n") if ($day ne $oldday);

	$oldday = $day;
	if (defined($sepg{T})) {
		# 1. AT|NOW|SEARCH  2. Title  3. Subtitle 4. Starttime 5. Stopptime 6. Channelid 7. EPGID
		push(@ul, epgli("SCHED", $sepg{T}, $sepg{S}, $sepg{E}[1], $sepg{E}[1] + $sepg{E}[2], $query[1], $sepg{E}[0]));

		}
	else {
		$timestring = fdate($sepg{E}[1], $timef{channeltime} );
		push(@ul, "", "_no", "<a onclick='epgDialog(\"".$query[1]."\", \"NOEPG\")' class='none'><font class='topfont'>$timestring </font><font class='mainfont'>".getChannelName($query[1])."</font></a>"); 	
	}
}

buildul(@ul);

quitSocket();
exit(0);
}
elsif ($query[0] eq "TINFO") {				# Erzeugt das Timer Dialogfeld [TimerID] [Title|new]
if (! defined($query[1])) {die "Fehlender Parameter: EventID!"}

makehtml("","","");

my %timer; my @channels = &channels;

## my @sortedtimers = sort { $$a{start} <=> $$b{start} } getTimerIds()

if (lc($query[1]) ne "new") {
my $timer = Receive('LSTT');
while ($timer =~ /250.(\d*?) (\d):(\d*?):(.*?):(\d{4}):(\d{4}):(\d*?):(\d*?):(.*?):(.*?)\r\n/g) {

if ($1 eq $query[1]) { %timer = (	"name"	=> $9,
									"date"	=> $4,
									"active"=> $2,
									"id"	=> $1,
									"chid"	=> $3,
									"start"	=> $5,
									"stop"	=> $6,
									"prio"	=> $7,
									"life"	=> $8,
									"aux"	=> $10); 
									$timer{title} = $query[2] if defined($query[2]);
									last; }
}
}
else {
%timer = (		"title" => "Neuer Timer",
				"name" => $OPT{stddir}."Name",
				"active" => 1,
				"chid"	=> $query[2],
				"date"	=> fdate(time, "#y#-#mm#-#dd#"),
				"start"	=> fdate(time, "#HH##MM#"),
				"stop"	=> fdate(time + 120 * 60, "#HH##MM#"),
				"prio"	=> $OPT{priority},
				"life"	=> $OPT{lifetime}
		); 
}
# $timer hash
# id, head, title, name, channelid, active ,activechannel , date, start, stop, prio, life
# cgi-param 
# change,  name, channel, date, start, stop, prio, life, active, 

my %h = recordHash(Receive("LSTR"));
my @dirs = getDirs(\%h);

print "<form id=\"timerEdit\" title=\"", $timer{head} || $L{TIMER}, "\" class=\"panel\" selected=\"true\">"; # accept-charset=\"UTF-8\">"; if 
print "<input type=\"button\" class=\"button redHeadButton\" onClick=\"doJSByHref('$me?'+encodeForm(\$('timerEdit')).join('&'));\" value=\"$L{SAVE}\"/>";
print closeButton();
print "<h2>$timer{title}</h2>" || "";
print "<input type=\"hidden\" name=\"change\" value=\"timer\"> ";
print "<input type=\"hidden\" name=\"id\" value=\"$timer{id}\"> ";
print "<input type=\"hidden\" name=\"aux\" value=\"$timer{aux}\"> ";

print "<fieldset>";

print toggle($L{RECORD}, "active", $L{ON}, $L{OFF} ,$timer{active} ? 1 : 0, "", 1, "0");
#print "<label>Aktiv</label>";
#print "<input type=\"checkbox\" style=\"width:100px;\" name=\"active\"";
#$timer{active} ? print " checked>" : print ">";
print "<div class=\"row\">";
print "<label>$L{DIR}</label>";
print "<select name=\"dir\">";
print "<option selected></option>";
my $title = $timer{name};
my $df;
(my $dir = $timer{name}) =~ /(.*)~/;
$dir = $1;
$title = $' if $';
foreach (@{$OPT{predefineddirs}}) { print "<option>$_</option>" }
foreach (@dirs) { if ($dir eq $_) { print "<option selected>$_</option>"; $df = 1 } else { print "<option>$_</option>" } }
$title = $timer{name} unless $df;
print "</select></div>";
print "<div class=\"row\">";
print "<label>$L{TITLE}</label>";
print "<input type=\"text\" name=\"name\" value=\"$title\"/>";
print "</div>";
print "<div class=\"row\">";
print "<label>$L{SCHED}</label>";
print "<select name=\"channel\">";
for (@channels) {
		for (@{$$_{channels}}) {
			print "<option value='$$_{id}' ", $timer{chid} eq $$_{no} || $timer{chid} eq $$_{id} ? "selected" : "", ">$$_{lngname}</option>";
		}
	}
print "</select></div>";

#print "<div class=\"row\">";
#print "<label>$L{DATE}</label>";
#print "<input type=\"text\" name=\"date\" value=\"$timer{date}\"/></div>";

$timer{date} =~ /(\d{4})-(\d{2})-(\d{2})/;

print "<div class=\"row\"><label>$L{DATE}</label>";
print "<select name=\"year\" class='small'>";
foreach (2010..2060) { $1 != $_ ? print "<option>".$_."</option>" : print "<option selected>".$_."</option>" } 
print "</select> - <select name=\"month\" class='small'>";
foreach (1..12) { $2 != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select> - <select name=\"day\" class='small'>";
foreach (1..31) { $3 != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>";
print "</div>";

print "<div class=\"row\">";
print "<label>$L{BEGIN} <font class='topfont'>HH:MM</font></label>";
#print "<input type=\"text\" name=\"start\" maxlength=\"5\" value=\"$timer{start}\"/></div>";
print "<select name=\"starth\" class='small'>";
foreach (0..23) { substr($timer{start}, 0, 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>: <select name=\"startm\" class='small'>";
foreach (1..60) { substr($timer{start}, 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select></div>";
print "<div class=\"row\">";
print "<label>$L{END} <font class='topfont'>HH:MM</font></label>";
#print "<input type=\"text\" name=\"stop\" maxlength=\"5\" value=\"$timer{stop}\"/></div>";
print "<select name=\"stopph\" class='small'>";
foreach (0..23) { substr($timer{stop}, 0, 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>: <select name=\"stoppm\" class='small'>";
foreach (1..60) { substr($timer{stop}, 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select></div>";
print "<div class=\"row\" style=\"text-align:right\">";
print "<label>$L{PRIORITY}</label>";
print "<select name=\"prio\" class='small'>";
foreach (1..99) { $timer{prio} != $_ ? print "<option>$_</option>" : print "<option selected>$_</option>" } 
print "</select></div>";
#print "<input type=\"text\" name=\"prio\" maxlength=\"2\" value=\"$timer{prio}\"/></div>";
print "<div class=\"row\" style=\"text-align:right\">";
print "<label>$L{LIFETIME}</label>";
print "<select name=\"life\" class='small'>";
foreach (1..99) { $timer{life} != $_ ? print "<option>$_</option>" : print "<option selected>$_</option>" } 
print "</select></div>";
#print "<input type=\"tex\" name=\"life\" maxlength=\"2\" value=\"$timer{life}\"/></div>";
print "</fieldset>";
print "<br></form>";

makehtml("food", "display:none");
quitSocket();
exit(0);
}
elsif ($query[0] eq "RECINFOFIELD") {		# Erzeugt das Aufnahme Dialogfeld [RecID] [BOXED_BOL]
if (! defined($query[1])) {die "Fehlender Parameter: Event_ID!"}

my %h = recordHash(Receive("LSTR"));
# my @dirs = getDirs(\%h);	# Alle Verzeichnissebenen einzeln...
my %rec = getRecByID(\%h, $query[1]);

makehtml("", "", "") unless $query[2];

my $epg; my %sepg = epgSplit(Receive("LSTR $query[1]")); my @info;
my @EN300 = ("", "Mono", "Dual-Mono", "Stereo", "Multi-Lingual", "Surround Sound");
my $mk; my $em;

# ------------------  STREAM --------------------

if (-e bsd_glob("$rec{path}/*001.*") &! $query[2]) {

	my @files = grep /\d*}\.*/i, bsd_glob("$rec{path}/*");
	my $bytes; map { $bytes += (-s $_) } @files;

	my $sec = (-s bsd_glob("$rec{path}/index*")) / (8 * $OPT{fps} || 8 * 25);
	my @marks = map { (my $t = $_) =~ /(\d*):(\d*):(\d*).(\d*)/; $_ = int(($1 * 3600 + $2 * 60 + $3 + $4 / 100) / $sec * 100); } fileArray(bsd_glob("$rec{path}/marks*"));

	#my $aspect = $ff4_3;
	my $aspect = $OPT{"stream_16_9"};
	#my $time = 0;
	# my $time = $form_input ->{'offset'} || 0;

	#my $offset = int($bytes / $sec * $time);
	#print STDERR $offset." - ".$time."\n";
	#$offset -= $offset % ($stream{vb} / 8);

	my $flashvars = $cgi->url(-full=>1).'?stream=rec&recid='.$query[1].'&offset=0&aspect='.$aspect;
	my $command = join(" ", $OPT{ffmpeg}, "-i", join(" -i ", @files), "-itsoffset", 300, "-f", "image2", "-vframes", 1, "-y", $tempdir."temp.jpg");
	#print STDERR $command."\n";
	system($command) if $command;
	my $image = "http://".$cgi->server_name().$weburl.'/preview.jpg';
	
	$em = '<div id="parentemb"><embed id="emb" src="http://imobilecinema.com/imcfp.swf" type="application/x-shockwave-flash" align="right" width=80 height=80 flashvars="file='.uri($flashvars).'&image='.uri($image).'"></div>';

	$em .= "<input id='info' type='hidden' _recid='$query[1]' _offset='0' _aspect='$aspect'>";
	
	print STDERR $em."\n" if $debug;
	$mk = '<table id="bar" cellspacing="0"><tr>';

	my $d; my $i;
	for (@marks) {
		if (($i / 2) == int($i / 2)) { $mk .= '<td width="'.($_ - $d).'%"></td>' }
		else { $mk .= '<td width="'.($_ - $d).'%" style="background-color:lightsteelblue"></td>'  }
		$d =+ $_; $i++;
	}

	$mk .= '</tr></table>';
	$mk .= "<font class='smallfont'>$L{ASPECT}:</font> <select onchange='\$(\"info\").setAttribute(\"_aspect\", this.value); bx.updateEmbed(); ' style='margin:20px 3px;'><option value='".$OPT{"stream_16_9"}."'>16:9</option><option value='".$OPT{"stream_4_3"}."'>4:3</option></select>";
}
else {
	print STDERR "ivdr.pl: Can't locate ".$rec{path}."/001.*!\n" unless $query[2];
}
	
# ------------- INFO -------------------
	
my $timestring = fdate($sepg{E}[1], $timef{epgscreen})." - ".fdate($sepg{E}[1] + $sepg{E}[2], $timef{channeltimeto}) ;
my $s = "<br><br>$L{LENGTH}: ".getRecordLength($rec{path}) if $OPT{videodir};

$epg .= "<font class='mainfont'>$sepg{T}<br></font><br>";
$epg .= $em if $em;
$epg .= "<font class='cdark'>$sepg{S}<br></font><br>" if $sepg{S};
$epg .= "<font class='topfont'>$timestring ".$s."<br></font>";
$epg .= $mk if $mk;

$sepg{D} =~ s/^\|//g;
$sepg{D} =~ s/(\|{1,2})/\<br\>/g;
$sepg{D} =~ s/\ \/\ /\<br\>/g;
$epg .= "<br><font class='objfont'>".$sepg{D}."<br><br>";

my $i = 0;
foreach (@{$sepg{X}}) { 
	@info = split(/\ /, $_);
	$epg .= "Video: $info[3] ($info[2]) <br>"  if $info[0] == 1;
	$epg .= "Audio 0.".++$i.": $info[3] $EN300[$info[1]] ($info[2]) <br>"  if $info[0] == 2;
}
$epg .= "<br>VPS: $sepg{V}</font><br><br>" if $sepg{V};

# ------------------  END --------------------
unless ($query[2]) {
$epg .= closeButton()."<a class='button redHeadButton' href='$me?cmd+killffmpeg' target='_js'>killall ffmpeg</a>";
$epg .= '<div id="pin" ></div>'  if $mk;

showDialog("$sepg{T}", "", $epg,"","", 1);
print "</body>";
print "<script src='$weburl/recinfo.js' type='text/javascript'></script>" if $mk;

print qq[<style>

#pin {
position: fixed;
height: 70px;
width: 100px;
top:0px;
left: 0px;
border-width: 0; 
padding: 0;
margin: 0;
background-image: url($weburl/Pin.png);
background-repeat: no-repeat;
background-position: center;
}
#pin:active {
background-image: url($weburl/PinGreen.png);
}
#bar {
height: 10px;
width: 100%;
margin: 25px 0px 8px;
background-color: #6495ED;
}
</style>];

print "</html>";
} else {
print $epg;
}

quitSocket();
exit(0);
}
elsif ($query[0] eq "EPGINFOFIELD") { 		# Erzeugt eine epg-Info Seite [Kanalnumme|ID][Event_ID] [BOXED_BOL]
if (! defined($query[1])) {die "Fehlender Parameter: Kanalnummer!"}
if (! defined($query[2])) {die "Fehlender Parameter: Event_ID!"}
#### ACHTUNG: EPGINFOFIELD und RECINFOFIELD und NEWTIMER sind gleich

makehtml("", "", "") unless $query[3];

#my $epg = getSVDRP("LSTE $query[1]");
my $epg = Receive("LSTE $query[1]");
my @epgdata = dblSplit( "215-E", "215-e", $epg);
my %sepg; my $str; my @info;
my @EN300 = ("", "Mono", "Dual-Mono", "Stereo", "Multi-Lingual", "Surround Sound");

foreach	my $item (@epgdata) {
	%sepg = epgSplit($item);
	
	if ($sepg{E}[0] =~ $query[2]) { 
		my $timestring = fdate($sepg{E}[1], $timef{epgscreen})." - ".fdate($sepg{E}[1] + $sepg{E}[2], $timef{channeltimeto});

		my $pic = bsd_glob($OPT{epgimages}."/".$query[2].".*");
		my $epg;
		$epg = "<img align='right' style='right:1px' vspace='10' hspace='10' src='$me?media=epgpic&id=$query[2]' />" if -e $pic; 
		$epg .="<font class='mainfont'>$sepg{T}</font><br><br>";
		$epg .= "<font class='cdark'>$sepg{S}</font><br><br>" if $sepg{S};
		$epg .= "<font class='topfont'>$timestring</font><br><br>";
		$sepg{D} =~ s/^\|//g;
		$sepg{D} =~ s/(\|{1,2})/\<br\>/g;
		$sepg{D} =~ s/\ \/\ /<br>/g;
		$sepg{D} =~ s/\*/\&#8902;/g;

		$epg .= "<font class='objfont'>".$sepg{D}."<p>";
		foreach (@{$sepg{X}}) { 
			@info = split(/\ /, $_);
			$epg .= "Video: $info[3] ($info[2]) <br>"  if $info[0] == 1;
			$epg .= "Audio: $info[3] $EN300[$info[1]] ($info[2]) <br>"  if $info[0] == 2;
		}
		$epg .= "</p>";
		if (length($sepg{V}) != 0) { $epg .= "VPS: $sepg{V}"; }
		$epg .= "</font><p><div align='center'>";
		my $i;
		my @pic = bsd_glob($OPT{epgimages}."/".$query[2]."_*.*");
		my $id;
		for (@pic) {
			$epg .= "<img vspace='5' hspace='4' src='$me?media=epgpic&id=".$query[2]."_".$i++."' />" if -e $pic;
		}
		$epg .= "</p></div>";
		
#		showDialog("$sepg{T}", "", $epg.closeButton().qq(<a class="button redHeadButton" 
#		href="$me?NEWTIMER+$query[1]+$query[2]">$L{RECORD}</a>));
		unless ($query[3]) 
		{	showDialog("$sepg{T}", "", $epg.closeButton().
			qq[<a href ="" class="button redHeadButton" 
			onclick='var dir = prompt(\"$L{PREFIX}\",\"$OPT{stddir}\"); if (dir != null) doJSByHref(\"$me?NEWTIMER+$query[1]+$query[2]+\"+dir); pageHistory=[];'>$L{RECORD}</a>
			]);
		}
		else {
			print $epg;
		}
		last;
		}
	}

print "</body></html>" unless $query[3];
quitSocket();
exit(0);
}
elsif ($query[0] eq "EPGSEARCHFIELD") {		# Erzeugt die epgSuche Maske [SearchID|new] [Title] [CHANID]

makehtml("","","");

my $title = $L{NEWSEARCH}; my $head = "EPG Search"; my @search; my $visible; my @channels = &channels();
my %h; my $type;

if (lc($query[1]) ne "new") {
	$title = $query[2];
	$h{orginalsearch} = Receive("PLUG epgsearch LSTS ".$query[1]);
	$h{orginalsearch} =~ s/^900 //;
	@search = getSearch(%h);
	unshift(@search,"");
	$type = "EDIS"
	}
else {
	$title = $L{NEWSEARCH};
#	$h{string}=uri_unescape($query[2]) if $query[2];
	$h{string}=$query[2] if $query[2];
	$h{usechannel}=1 if $query[3];
#	$h{channel}=uri_unescape($query[3]) if $query[3];
	$h{channel}=$query[3] if $query[3];
	@search = getSearch(%h);
	unshift(@search,"");
	$query[1]="0";
	$type = "NEWS";
}

#   style=\"text-align:left\"
my @modus = ("","","","",""); $modus[$search[9]] = "selected";

print qq(<form id="epgSearchEdit" title="$head" class="panel" action="$me" method="GET" target="_blank" selected="true">
		<input type="hidden" name="change" value="epgsearch">
		<input type="hidden" name="id" value="$query[1]">
		<input type="hidden" name="type" value="$type">
		<input type="hidden" name="window" value="dialog">
		<input type="hidden" name="orginalsearch" value="$h{orginalsearch}">

		<input class="button redHeadButton" onclick="getElementsByName('change')[0].value = 'epgsearch'; doJSByHref('$me?'+encodeForm(\$('epgSearchEdit')).join('&'));" type='button' name="save" value=$L{SAVE}>
		<input class="leftButton blueHeadButton" onclick="getElementsByName('change')[0].value = 'quicksearch'" type="submit" name="test" value=$L{TEST}>

        <h2>$title</h2>
        <fieldset>
		<div class="row">
                <label>$L{SEARCH}</label>
                <input type="text" name="string" value="$search[2]">
            </div>
		</fieldset>
        <h2>$L{STYPE}</h2>
		<fieldset>
);
print toggle($L{TITLE}, "stitle", $L{YES}, $L{NO}, $search[10], "",1,"0");
print toggle($L{EPISODE}, "ssubtitle", $L{YES}, $L{NO}, $search[11], "",1,"0");
print toggle($L{DESCRIPTION}, "sdescr", $L{YES}, $L{NO}, $search[12], "",1,"0");
print qq(<div class="row">
				<label>$L{SMETHOD}</label>
				<select name="modus">
					<option value="0" $modus[0]>$L{PHRASE}</option>
					<option value="1" $modus[1]>$L{ALLWORDS}</option>
					<option value="2" $modus[2]>$L{ONEWORD}</option>
					<option value="3" $modus[3]>$L{MATCHEXACTLY}</option>
					<option value="4" $modus[4]>$L{REGULAR}</option>
				</select>			
			</div>
			);

print toggle($L{BIGSMALL}, "case", $L{YES}, $L{NO}, $search[8], "","1","0");
print toggle($L{FAV}, "fav", $L{YES}, $L{NO}, $search[42], "","1","0");
# KANAL ----------------------------------------------------------------------------
print qq(</fieldset><fieldset>);
print toggle($L{USECHANNEL}, "usechannel", $L{YES}, $L{NO}, $search[6], "toggleDiv(this, 'divChannel')", "1","0");
if ($search[6] eq "1") { $visible = "block" } else { $visible = "none" }
print qq(	<div class="row" id="divChannel" style="display:$visible">
				<label>$L{CHOOSE}</label>
				<select name="channel">);
				print "<option value='' selected>$L{NOCHANGE}</option>";
				for (@channels) {
					print "<option value='".${$$_{channels}}[0]{id}."|".${$$_{channels}}[$#{$$_{channels}}]{id}."'";				
					print $search[7] eq ${$$_{channels}}[0]{id}."|".${$$_{channels}}[$#{$$_{channels}}]{id} && $search[7] ne "" ? " selected" : "",">[ $$_{name} ]</option>";
				}
				for (@channels) {
					for (@{$$_{channels}}) {
						print "<option value='$$_{id}' ", $search[7] eq $$_{id} && $search[7] ne "" ? "selected" : "", ">$$_{lngname}</option>";
						# 1. �ergabe funktioniert nicht
						# 2. vormarkierte mssen erkannt werden
					}
				}
				
print qq(</select></div></fieldset><fieldset>);
# Uhrzeit ----------------------------------------------------------------------------
print toggle($L{USETIME}, "usetime", $L{YES}, $L{NO}, $search[3], "toggleDiv(this, 'divTime')", "1","0");
if ($search[3] eq "1") { $visible = "block" } else { $visible = "none" }
print qq(
		<div id="divTime" style="display:$visible">
			<div class="row">
				<label>$L{FROM}</label>);
print "<select name=\"starth\" class='small'>"; 
foreach (0..23) { substr($search[4], 0, 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>: <select name=\"startm\" class='small'>";
foreach (0..60) { substr($search[4], 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>";
print qq(</div>
			<div class="row">
				<label>$L{TO}</label>);
print "<select name=\"stoph\" class='small'>";
foreach (0..23) { substr($search[5], 0, 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>: <select name=\"stopm\" class='small'>";
foreach (0..60) { substr($search[5], 2) != $_ ? print "<option>".sprintf("%02d", $_)."</option>" : print "<option selected>".sprintf("%02d", $_)."</option>" } 
print "</select>";
print qq(</div></div>);

print qq(</fieldset><fieldset>);
# Dauer (min) ------------------------------------------
print toggle($L{USELENGTH}, "uselength", $L{YES}, $L{NO}, $search[13], "toggleDiv(this, 'divLength')", "1","0");
if ($search[13] eq "1") { $visible = "block" } else { $visible = "none" }
print qq(
		<div id="divLength" style="display:$visible">
			<div class="row">
				<label>$L{MIN}</label>
                <input type="text" pattern="[0-9]*" name="minlength" value=$search[14]>
            </div>
			<div class="row">
				<label>$L{MAX}</label>
                <input type="text" pattern="[0-9]*" name="maxlength" value=$search[15]>
            </div>
		</div>);

print qq(</fieldset><fieldset>);

# Wochentag ------------------------------------------------
print toggle($L{USEDAY}, "useday", $L{YES}, $L{NO}, $search[17], "toggleDiv(this, 'divDay')","1","0");
if ($search[17] eq "1") { $visible = "block" } else { $visible = "none" }
print qq(<div id="divDay" style="display:$visible">);

my @days;
if (abs($search[18]) eq $search[18]) {
@days = (0,0,0,0,0,0,0);
for (0..6) { $days[$_] = 1 if abs($search[18] - 6)  eq $_ }
}
else {
my $bin = sprintf("%b", abs($search[18]));
for (0..6-length($bin)) { $bin = "0".$bin }
@days = split(//,$bin); #   !!!!!!!!!!! alternative sprintf("%06d",bin2dec($search[18]))
}
print toggle($L{SUN},     "useson", $L{YES}, $L{NO}, $days[6],"","1","0");
print toggle($L{MON},      "usemon", $L{YES}, $L{NO}, $days[5],"","1","0");
print toggle($L{THU},    "usedie", $L{YES}, $L{NO}, $days[4],"","1","0");
print toggle($L{WED},    "usemit", $L{YES}, $L{NO}, $days[3],"","1","0");
print toggle($L{TUR},  "usedon", $L{YES}, $L{NO}, $days[2],"","1","0");
print toggle($L{FRI},     "usefre", $L{YES}, $L{NO}, $days[1],"","1","0");
print toggle($L{SAT},     "usesam", $L{YES}, $L{NO}, $days[0],"","1","0");
print qq(</div>);
print qq(</fieldset><fieldset>);
# Suchtimer  ----------------------------------------
print toggle($L{RECORD}, "use", $L{YES}, $L{NO}, $search[16], "toggleDiv(this, 'divUse')", "1","0");
if ($search[16] eq "1") { $visible = "block" } else { $visible = "none" }
print qq(<div id="divUse" style="display:$visible">);
print toggle($L{SERIE}, "serie", $L{YES}, $L{NO}, $search[19], "", "1","0");
print qq(
			<div class="row">
				<label>$L{DIR}:</label>
                <input style="padding-left:150px" type="text" name="dir" value=$search[20]>
            </div>
			<div class="row">
				<label>$L{PRIORITY}</label>);
print "<select name=\"prio\" class='small'>";
foreach (0..99) { $search[21] != $_ ? print "<option>$_</option>" : print "<option selected>$_</option>" } 
print qq(   </select></div>
			<div class="row">
				<label>$L{LIFETIME}</label>);
print "<select name=\"life\" class='small'>";
foreach (0..99) { $search[22] != $_ ? print "<option>$_</option>" : print "<option selected>$_</option>" } 
print qq(   </select></div>
			<div class="row">
				<label>$L{BUFFERBEGIN}:</label>
                <input style="padding-left:150px" type="text" pattern="[0-9]*" name="prefix" value=$search[23]>
            </div>
			<div class="row">
				<label>$L{BUFFEREND}:</label>
                <input style="padding-left:150px" type="text" pattern="[0-9]*" name="suffix" value=$search[24]>
            </div>
);
print qq(
			<div class="row">
				<label>$L{DELDAYS}</label>
                <input style="$L{DELDAYSPX}" type="text" pattern="[0-9]*" name="deletedays" value=$search[36]>
            </div>
			<div class="row">
				<label>$L{RECCOUNT}</label>
                <input style="$L{RECCOUNTPX}" type="text" pattern="[0-9]*" name="recordcount" value=$search[37]>
            </div>
			<div class="row">
				<label>$L{RECMAX}</label>
                <input style="$L{RECMAXPX}" type="text" pattern="[0-9]*" name="recordmax" value=$search[39]>
            </div>
);
print toggle($L{NOREPLAY}, "noreplay", $L{YES}, $L{NO}, $search[29], "toggleDiv(this, 'divReplay')", "1","0");
if ($search[29] eq "1") { $visible = "block" } else { $visible = "none" }
print qq(<div id="divReplay" style="display:$visible">);
print toggle($L{COMPARET}, "comptitle", $L{YES}, $L{NO}, $search[31], "", "1","0");
print toggle($L{COMPARES}, "compsubtitle", $L{YES}, $L{NO}, $search[32], "", "1","0");
print toggle($L{COMPARED}, "compdescr", $L{YES}, $L{NO}, $search[33], "", "1","0");
print qq(
			<div class="row">
				<label>$L{REPLCOUNT}</label>
                <input style="$L{REPLCOUNTPX}" type="text" name="replaycount" value=$search[30]>
            </div>
			<div class="row">
				<label>$L{REPLDAYS}</label>
                <input style="$L{REPLDAYSPX}" type="text" name="replaydays" value=$search[35]>
            </div>
);
print qq(</div>);
print toggle("VPS", "vps", $L{YES}, $L{NO}, $search[25], "", "1","0");
print qq(</div>);
print "</fieldset></form>";

makehtml("food", "display:none");
quitSocket();
exit(0);
}
elsif ($query[0] eq "NEWTIMER") {			# erzeugt aus der [CHANNEL_ID][Event_ID] optional [DIR] einen Timer JS_Rckgabe
if (! defined($query[1])) {die "Fehlender Parameter: Kanalnummer!"}
if (! defined($query[2])) {die "Fehlender Parameter: Event_ID!"}

my $epg = Receive("LSTE $query[1]");
my @epgdata = dblSplit( "215-E", "215-e", $epg);
my %sepg;
foreach	my $item (@epgdata) {
	%sepg = epgSplit($item);
	
	if ($sepg{E}[0] =~ $query[2]) { 
		my $s = $sepg{E}[1] - $OPT{pretime};
		my $e = $sepg{E}[1] + $sepg{E}[2] + $OPT{suftime};
		my $t = "1:$query[1]:".fdate($sepg{E}[1], "#y#-#m#-#d#").":".fdate($s, "#HH##MM#").":".fdate($e, "#HH##MM#").":$OPT{priority}:$OPT{lifetime}:";
		if ($query[3]) {
			$t .= $query[3];
			$t .= "~" unless $t =~ /~$/; 
		}

		$t .= $sepg{T}.":<epgsearch><eventid>".$query[2]."</eventid><start>$s</start><stop>$e</stop></epgsearch>";
		print STDERR "Change Timer: $t\n" if $debug;
		my $result = Receive("NEWT ".$t);
		$result =~ s/\r\n//g;
		$result =~ s/'/\\'/g;
		print STDERR "$result\n" if $debug;		
		print qq[ alert('$L{NEWTIMER}:\\n$result'); cancelDialog(bf());	];
		quitSocket();
		exit(0);		
		}
	}
quitSocket();
exit(0);
	}
elsif ($query[0] eq "REPLAY"){				# Erzeugt eine Suchabfrage aus([Kanalnumme|ID][Event_ID] || [RECID] )
if (! defined($query[1])) {die "Fehlender Parameter!"}
my %sepg; my $epg;

if (! defined($query[2])) {
	$epg = Receive("LSTR $query[1]");
	%sepg = epgSplit($epg);
}
else {
	$epg = Receive("LSTE $query[1]");
	my @epgd= dblSplit("215-E", "215-e", $epg);
	for (@epgd) {
		%sepg = epgSplit($_);
		last if $sepg{E}[0] eq $query[2];
	}
}
	
my @ul = ("replay", $sepg{T}, "true' temporary='yes' tag='".$ENV{'REQUEST_URI'});
my %search = ("string" => $sepg{T}, "stitle" => 1, "ssubtitle" => 0, "sdescr" => 0,"modus" => 0);
#my %search = ("string" => $sepg{T}." ".$sepg{S}, "stitle" => 1, "ssubtitle" => 1, "modus" => 1);

my $value = join(":",getSearch(%search));
print STDERR $value."\n" if $debug;

push(@ul, doSearch($value, $query[2]));

buildul(@ul);
quitSocket();
exit(0);}
elsif ($query[0] eq "STAT"){
print &vdrStats;
quitSocket();
exit(0);

sub vdrStats { # Erzeugt ein HTML Tag mit VDR informationen...		
my $stat = Receive("STAT disk");

my $tmp;
(my $con = $connection) =~ /220.(.*?) (.*?)\; (.*)\r\n/;
my $vdr = $2; 
my $dat = $3;
if ($stat =~ /(250 )(\d*)MB (\d*)MB (.*)%/) {
	my $free = $3;
	my $perfree = abs($4-100);
	my $hfree = int($free * 2.33);
	my $sfree = sprintf ("%.f", ($free/1024));
	$stat = "<font class='smallfont grayed'>$L{VIDEODIR}:</font>";
	my $statcount = "<font class='smallfont' style='padding-left: 8px; line-height: 34px; color:#FFFFFF; text-shadow: #0000FF 2px 2px 2px; font-weight:bold;'>$L{FREE}: ".timediff($hfree,"","","std", "<font style='font-size:smaller'> $L{HOURS}</font>", "VOLL!")." ".
	"(".$sfree."<font style='font-size:smaller'>GB</font> / ".$perfree."<font style='font-size:smaller'>%</font>)</font>\n";
	$stat .= "<table class='info' style='padding:0;'><tr>
			<td style='white-space:nowrap; width:".abs($perfree-100)."%; background:url($weburl/selection.png) repeat;'>$statcount</td>
			<td></td></tr></table>";
# <img src='/iVDR/iui/thumb.png'>
# background:url(/iVDR/iui/thumb.png) repeat-x;

	my $mp3pluginstring = Receive("PLUG mp3 CURR");
	if ($mp3pluginstring =~ /900.*\/(.*?)\r\n/) {
			$mp3pluginstring = qq(<br><font class='smallfont grayed'>$L{MP3PLAY}:</font><table class='info'><tr><td>
			<font class='smallfont'>$1</font>
			</td></tr></table>
			);
	}
	else { $mp3pluginstring = "" }
	
	my $conflictstring = Receive("PLUG epgsearch LSCC REL");
	my @cs = ($conflictstring =~ /900.(.*?)\r\n/g);
	$cs[0] =~ /(\d*):/;
	my $ctime = timediff($1 - time);
	my $conflict;
	if (@cs) {
	if (scalar(@cs) > 1) { $conflict = "<br><font class='smallfont warn'>".scalar(@cs)." $L{TCONFLS}!</font><table onclick='iui.showPageByHref(\"$me?TIMER\")' class='info'><tr><td><font class='smallfont'> $L{NEXTIN} " }
	else { $conflict = "<br><font class='smallfont warn'>".scalar(@cs)." $L{TCONFL}!</font><table onclick='iui.showPageByHref(\"$me?TIMER\")' class='info'><tr><td><font class='smallfont'> $L{IN} " } 
	$conflict .= "$ctime</font></td></tr></table>\n";
	}

	my @sorted = sort { $$a{start} cmp $$b{start} } getTimerIds();
	my $nexttimer;	my $rec;
	for (@sorted) {
		if ($$_{rec}) {
#onclick='timDialog(\"".$$_{no}."\", \"".$$_{channel}{id}."\", \"".$$_{id}."\")' class='$class", "_iui", 
#
		$rec .= qq(<br><font class='smallfont grayed'>$L{ACTREC}:</font><table onclick='timDialog("$$_{no}","$$_{channel}{id}","$$_{id}",0)' class='info'><tr><td><img src='$weburl/rec.png' align='right'><font class='smallfont'>).
			$$_{channel}{lngname}." </font><font class='subfont'>bis ".fdate($$_{stop},$timef{activerecord}).
			qq(<br>$$_{title}</font></td></tr></table>);
		}
		elsif ($$_{active} &! $nexttimer) {
			$nexttimer = qq[<br><font class='smallfont grayed'>$L{NEXTTIMER}:</font><table onclick='timDialog("$$_{no}","$$_{channel}{id}","$$_{id}",0)' class='info'><tr><td><font class='smallfont'>].
			$$_{channel}{lngname}.": ".fdate($$_{start},$timef{timer}).
			qq [<br><font class='subfont'>$$_{title}</font></font></td></tr></table>];
		}
	}

	$stat .= "$rec$mp3pluginstring$nexttimer$conflict";
}
else {
	$stat = "<center><font class='mainfont warn'>Connection to VDR failed!</font></center><br>\n"
}

$stat = "<fieldset id='divstatistic' tag='".$me."?STAT'><div class='text' onclick='iui.showPageByHref(\"".$me."?STAT\",null ,null , this.parentNode)'>".$stat."</div></fieldset>";

return($stat)

}

}
elsif ($query[0] eq "MOVE"){
shift(@query);
die("Fehlende Aufzeichnungsnummer") if scalar(@query) == 0;

my %h = recordHash(Receive("LSTR"));
my @dirs = sort {$a cmp $b} getDirs(\%h);	# Alle Verzeichnissebenen einzeln...

my $dir; my $recID = join("&IDS=",@query);

$dir = "<option value=''>($L{CHOOSE})</option>";
$dir .= "<option>~</option>";
foreach (@{$OPT{predefineddirs}}) { $dir .= "<option>$_</option>" }

foreach (@dirs)  {
	$dir .= qq(<option>$_</option>);
}

print qq[
		var btnok = new button;
		var btnbr = new button;
		
		btnok.value = lp_RUN;
		btnok.onclick = "if (! \$('selectField_1').value) var dir = prompt('$L{VIDEODIR}','$OPT{stddir}'); else var dir = \$('selectField_1').value; if (dir) { cancelDialog(bf()); unCheck(); iui.showPageByHref('"+sn+"REC=MOVM&STRING='+dir+'&IDS=$recID'); }";
//		btnok.onclick = "var vidopt = \$('selectField_1').options[\$('selectField_1').selectedIndex].value;var audopt = \$('selectField_2').options[\$('selectField_2').selectedIndex].value;\$('btnsarea').innerHTML = '';doJSByHref(sn+'stream=$form_input->{'type'}&id=$form_input->{'id'}&config='+vidopt+'&map='+audopt);";


		btnok.image = www+"/btn_start.png";
		
		btnbr.value = lp_HIDE;
		btnbr.onclick = "cancelDialog(bf())";
		btnbr.image = www+"/btn_cancel.png";
		
		oDialog = new dialog(lp_MOVE, null, null, null, null, [btnok, btnbr]);
		oDialog.show();
		
	\$("selectField_1").innerHTML ="$dir"; 
	\$("selectField_1").name = "dir";
	\$("selectFieldLabel_1").innerHTML ="$L{VIDEODIR}"; 
	\$("selectField").style.display = "block";
	\$("selectField_1").style.display = "block";
	\$("selectFieldLabel_1").style.display = "block";
	\$("selectField_2").style.display = "none";
	\$("selectFieldLabel_2").style.display = "none";
	\$("selectField_3").style.display = "none";
	\$("selectFieldLabel_3").style.display = "none";
	
];
#if (! \$('selectField_1').value) var dir = prompt('$L{VIDEODIR}','$OPT{stddir}'); else var dir = \$('selectField_1').value; if (dir) { cancelDialog(bf()); unCheck(); iui.showPageByHref('"+sn+"REC=MOVM&STRING='+dir+'&IDS=$recID'); }");

#	bf().setAttribute("action", "$me");	
#	\$("yellowbtn").style.display = "none";
#	\$("bluebtn").style.display = "none";	
#	var red = \$("redbtn");
#	var green = \$("greenbtn")
#	red.style.display = "block";	
#	red.innerHTML = "$L{HIDE}";
#	red.setAttribute("href", "");
#	red.setAttribute("onclick", "cancelDialog(bf())");
#	green.style.display = "block";	
#	green.innerHTML = "$L{RUN}";	
#	green.setAttribute("href", "");
#	// green.setAttribute("onclick", "alert(\$('selectField_1').value);");
#	// green.setAttribute("onclick", "cancelDialog(bf()); deleteHistory('main'); iui.showPageByHref('?REC+MOVM+'+\$('selectField_1').value+'+$recID');");\n
#	green.setAttribute("onclick", "if (! \$('selectField_1').value) var dir = prompt('$L{VIDEODIR}','$OPT{stddir}'); else var dir = \$('selectField_1').value; if (dir) { cancelDialog(bf()); unCheck(); iui.showPageByHref('"+sn+"REC=MOVM&STRING='+dir+'&IDS=$recID'); }");
#	];
	

#	cancelDialog($('buttonsForm')); deleteHistory('main'); iui.showPageByHref('?REC+DELM+"+ids.join("+")+"');", ids.length+" Aufzeichnungen ausgew�lt. Wirklich l�chen!"
#	green.setAttribute("onclick", "if (! \$('selectField_1').value) var dir = prompt('$L{VIDEODIR}','$OPT{stddir}'); else var dir = \$('selectField_1').value; if (dir) { cancelDialog(\$('buttonsForm')); deleteHistory('main'); unCheck(); iui.showPageByHref('"+sn+"?REC=MOVM&STRING='+dir+'&IDS=$recID'); }");
	
quitSocket();
exit(0);
}
