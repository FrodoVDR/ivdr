if ($query[0] eq "actualdb"){

my $mp3pluginstring; 
if ($dbmusic{action} eq "cmd+") {
	$mp3pluginstring = Receive($mediaselect{_OPT_}{ACTUALPLAY}{command});
} else {
	#HTTP Handler
	require HTTP::Request;
	$mp3pluginstring = HTTP::Request->new(GET => $mediaselect{_OPT_}{ACTUALPLAY}{command});
	$mp3pluginstring = $mp3pluginstring->as_string();
}

print STDERR "Before regex: ", $mp3pluginstring,"\n" if $debug;
if ($mp3pluginstring =~ /$mediaselect{_OPT_}{ACTUALPLAY}{regex}/s) {
	eval("\$mp3pluginstring = \$".$mediaselect{_OPT_}{ACTUALPLAY}{no});
}
else { $mp3pluginstring = "" }
print STDERR "After regex: ", $mp3pluginstring,"\n" if $debug;


my $start = qq(<fieldset id="actualplay" tag="$me?actualdb+fieldset"><img style='position:absolute; right:0px; padding: 3px 3px 10px 10px; z-index:2' src="$weburl/refresh.png" onclick="var nd=\$('actualplay'); iui.showPageByHref(nd.getAttribute('tag'), null,null, nd)" />);
my $end = qq(</fieldset>);

error("Keine Wiedergabe...") unless($mp3pluginstring);



my $process = './mdb.pl --get --and --filter {DIR}="'.escapeQw(dirname($mp3pluginstring)).'" --filter {FILENAME}="'.escapeQw(basename($mp3pluginstring)).'"';
print STDERR $process,"\n" if $debug;

open (RESULT, "$process |") or die("Error opening mdb.pl. $!");
my $VAR1 = join("", <RESULT>);
close RESULT;
eval($VAR1);

my @rr = keys %$VAR1;
error("Wiedergabe nicht in Datenbank gefunden!") unless $rr[0];
my %h = %{$$VAR1{$rr[0]}[0]};
my $stars = getStars($h{IDS}{POPM}{Rating});

print STDERR $stars,"<-----$h{IDS}{POPM}{Rating}----\n";

#print STDERR Dumper %h;
my $dlgtitle = encode_entities($h{IDS}{TIT2});
my $dlg = qq(mp3Dialog("$dlgtitle", "&id=$h{ID}", "database=search&action=add", "database=search&action=play", $stars, 1););

unless ($query[1]) { print $dlg }
else { 
	if (exists $h{IDS}{APIC}) {
	print qq($start
<div class='row topfont' style='text-align:left;padding:10px;' onclick='$dlg'>
<img src="$me?media=database&pic=$h{IDS}{APIC}" style="float:left; margin-bottom: 10px; margin-right: 10px; width:100px; height: 100px; display:block; ">
<div style="line-height: 20px;" class='hideoverflow'>$h{IDS}{TPE1}</div>
<div style="line-height: 20px;" class='hideoverflow'>$h{IDS}{TALB}</div>
<div style="line-height: 20px;">$h{IDS}{TPOS}<font class="objfont"> $h{IDS}{TIT2}</font></div>
<span style="display:inline-block; width: 65px; height: 30px;" id="&id=$h{ID}" class="star$stars"></span>
</div>
$end);
	} else {
	print qq($start
<div style='margin:10px 20px 10px 10px;' class='row topfont' onclick='$dlg'>
<div id="&id=$h{ID}" style="float:right; text-align:right; height: 46px; max-width: 140px; min-width:65px; margin-left: 14px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;" class="star$stars">
$h{IDS}{TALB}</div>
<div style="margin-bottom:6px;" >$h{IDS}{TPE1}</div>
<div>$h{IDS}{TPOS}<font class="objfont"> $h{IDS}{TIT2}</font></div>
</div>
$end);
	}
 }


quitSocket();
exit(0);


sub error {
	unless ($query[1]) { print "alert('Keine aktuelle Wiedergabe!')" }
	else { 
	print qq($start<div class='row topfont' style='text-align:center; line-height:3em;'>$_[0]</div>$end);
	}
	quitSocket();
	exit(0);
};

}


#info zum auslagern zus?zlich prfen
#$query[0] eq "actualdb"
#sub createm3u
#sub getStars
#gemeinsame subprozeduren in eine extern subs.pm auslagern

my $para;
for (keys(%$form_input)) { $para .= "Name: $_  Wert: ".$form_input ->{$_}."\n" }
print STDERR $para if $debug;

my $querystring = join("&", map { $_."=".(ref $form_input ->{$_} ? join("&".$_."=", @{$form_input ->{$_}}) : $form_input ->{$_}) } keys %{$form_input});

#if ($form_input ->{'database'} eq "search" || $form_input ->{'database'} eq "dir") {
#my $process = './mdb.pl --get --group \'{DIR}.$$_{FILENAME}\' --filter \'{DIR}=DAVID\'';
#my $process = './mdb.pl --get --group \'{DIR}\' --filter \'{DIR}=DAVID\'';
#my $process = './mdb.pl --get --group \'{IDS}{TPE1}\' --filter \'{IDS}{TPE1}=david\'';
#my $process = './mdb.pl --get --group \'{IDS}{TPE1}\' --filter \'{IDS}{TIT2}=Ci\'';

$form_input ->{'database'} = $form_input ->{'database'}[$#{$form_input ->{'database'}}] if (ref $form_input ->{'database'}); # nimm letzte datenbank option wenn mehrere

my $title = ref $form_input ->{'title'} && $form_input ->{'title'}[0] || $form_input ->{'title'} || "Database";
my $process = './mdb.pl --get';
$process =  './mdb.pl --put' if ($form_input ->{'database'} eq "write");


$process .= " --group ".$form_input ->{'group'} if $form_input ->{'group'};

if (ref $form_input ->{'id'}) {
		$process .= " --id ".join(" --id ", @{$form_input ->{'id'}});
} elsif ($form_input ->{'id'}) {
	$process .= " --id ".$form_input ->{'id'};
}

$form_input ->{'search'} =~ s/ |\(|\)/\\$&/g; # space ( ) durch backslashen

if (ref $form_input ->{'filter'}) {
	for (@{$form_input ->{'filter'}}) {
		$process .= " --filter ".$_."=".$form_input ->{'search'} if $_;
	}
} elsif ($form_input ->{'filter'}) {
	$process .= " --filter ".$form_input ->{'filter'}."=".$form_input ->{'search'}.($form_input ->{'database'} eq "dir" ? '$' : "");
}

#print STDERR Dumper $form_input ->{'filter2'};

# filter2 setzt die elemente in REGEXP ODER, kann nur ein key, macht nur ODER, operandenwahl ungltig
# !!!!!!! gleiche keys zusammen fassen zu regexp oder gleiche bei filter, dann wieder problem mit operandenwahl
#print STDERR Dumper $form_input ->{'filter2'},"\n";

unless ($form_input ->{'nofilter2'}) {
if (ref $form_input ->{'filter2'}) {
	$process .= " --filter2 ";# .$form_input ->{'filter2'}[0];
	#my $i;
	my @rrr; my $str;
	for (@{$form_input ->{'filter2'}}) {
		#next unless $i++;
		my @rr = split("=", $_);
		if ($rr[1]) {
			push(@rrr, $rr[1]);
			$str = $rr[0]."=" unless $str;
		}
		#$process .= "\\|".$rr[1] if $rr[1];
	}
	$process .= $str.join("\\|", @rrr);
} elsif ($form_input ->{'filter2'}) {
	$process .= " --filter2 ".$form_input ->{'filter2'};
}
}

#operation=gt 254&numeric={II}{RATE}
if (exists $form_input ->{'numeric'}) {
	$process .= " --numeric ".$form_input ->{'numeric'}."='".$form_input ->{'operation'}."'";
}
#--group \'{IDS}{TPE1}\' --filter \'{IDS}{TIT2}=Ci\'';

if (ref $form_input ->{'data'}) {
	$process .= " --data ".join(' --data ', @{$form_input ->{'data'}});
} elsif (exists $form_input ->{'data'}) {
	$process .= " --data ".$form_input ->{'data'};
}

print STDERR $process,"\n" if $debug;
open (RESULT, "$process |") or die("Error opening mdb.pl. $!");
my $VAR1 = join("", <RESULT>);
#use Storable qw(nstore store_fd nstore_fd);
#my $VAR1 = fd_retrieve(\*RESULT);
close RESULT;

exit(0) if ($form_input ->{'database'} eq "write");

eval($VAR1);


my %h = %$VAR1;
my @keys = keys %h;



#print STDERR $VAR1,"\n";
#print STDERR $elmnt{IDS}{TIT2};
#print STDERR scalar(@elmnts),"<---\n";
#print STDERR Dumper @elmnts;

# msste auch nur wenn group definiert ist
my $pageid;
my %sub;
if (exists $form_input ->{'sub'}) { # subkategorie in hash bergeben
	$pageid = $form_input ->{'sub'}; # hash id der Subkategorie
	my $i;
	for (@keys) {
		if ($i++ == $pageid) {
			%h =();
			for my $d (0..$#{$$VAR1{$_}}) {
			$h{$d} = [$$VAR1{$_}[$d]]; # passt nicht bei gruppierten und/oder sortierten; nochmal berdenken
			}
			@keys = keys %h;
			last;
		}
	}
} else {
	my $i; #Gruppen Ids definieren
	map { $sub{$_} = $i++ } @keys;
}
(my $ID = $form_input ->{'search'}) =~ tr/a-zA-Z_0-9//cd;
$pageid .= $ID if $form_input ->{'database'} eq "dir";

my $sortkey; # die hashid mit der als letztes sortiert wird
unless (exists $form_input ->{'sort'}) {
	@keys = sort { uc($h{$a}[0]{IDS}{TIT2}) cmp uc($h{$b}[0]{IDS}{TIT2}) } @keys;
	$sortkey = "{IDS}{TIT2}";
	print STDERR "Sorted by Titel \n" if $debug;
} else {
	$form_input ->{'sort'} = [$form_input ->{'sort'}] unless ref $form_input ->{'sort'};
	for (@{$form_input ->{'sort'}}) {
		print STDERR "Sorted by $_\n"  if $debug;
				
		if ($form_input ->{'sorttype'}) {
			@keys = eval('sort { if ($h{$a}[0]'.$_.' '.$form_input ->{'sorttype'}.' $h{$b}[0]'.$_.') { -1 } elsif ($h{$a}[0]'.$_.' == $h{$b}[0]'.$_.') { 0 } else { 1 } } @keys');
		} else {
			@keys = eval('sort { uc($h{$a}[0]'.$_.') cmp uc($h{$b}[0]'.$_.') } @keys');
		}
		
		$sortkey = $_;
	}
}

if ((exists $form_input ->{'group'}) &! (exists $form_input ->{'sub'})) {
	if ($form_input ->{'sorttype'}) {
		@keys = eval('sort { if ($h{$a}[0]'.$form_input->{'group'}.' '.$form_input ->{'sorttype'}.' $h{$b}[0]'.$form_input->{'group'}.') { -1 } elsif ($h{$a}[0]'.$form_input->{'group'}.' == $h{$b}[0]'.$form_input->{'group'}.') { 0 } else { 1 } } @keys');
	} else {
		@keys = sort { eval('uc($h{$a}[0]'.$form_input->{'group'}.') cmp uc($h{$b}[0]'.$form_input->{'group'}.')') } @keys;
	}
	print STDERR "Sorted by Group\n"  if $debug;
	$sortkey = $form_input ->{'group'};
}


#map { $h{$_}[0]{_sortkey} = $h{$_}[0]{$sortkey} } @keys;
#print STDERR join("\n", @keys);
#exit(0);

my @ul; my $pagetag;

my $maxkeysshown = ($#keys > 200 &! ($form_input ->{'tono'} || $form_input ->{'fromno'})); # &&  $form_input ->{'group'} =~ /TIT2|TALB|POPM|TPE1/ ???
if ($maxkeysshown) { # Achtung bedingung unten nochmal
	$pagetag = "playlist_inner_$pageid";
	@ul = ($pagetag, $title, "false' temporary='yes' all='$querystring' class='buttons");
	#next if ($form_input->{'tono'} < $i && $form_input->{'tono'});
	#next if ($i < $form_input->{'fromno'} && $form_input->{'fromno'});
} else {
	$pagetag = "playlist_$pageid";
	@ul = ($pagetag, $title, "false' temporary='yes' all='$querystring' afterPictures='yes' scroll='view");
	
	unless(exists $form_input ->{'sub'} && $form_input ->{'group'} =~ /TIT2|TALB|POPM|TPE1/) {  
	#gibt probleme bei bustaben-gruppierten ausgabe die mehr als 200 entr?e haben 
	#muss bei gruppen > 200 in denen gruppen stehen 
	#/TIT2|TALB|POPM|TPE1/ problem?
		print STDERR "Schneide ab\n";
		my $count = scalar(@keys);
		for (my $i; $i <= $count; ++$i) {
			shift(@keys) if $i+1 < $form_input->{'fromno'} && $form_input->{'fromno'};
			pop(@keys) if $i > $form_input->{'tono'} && $form_input->{'tono'};
		}
	}
}

if ($form_input ->{'database'} eq "infofield") {
# einzelanzeige
%h  = %{$$VAR1{$keys[0]}[0]};
print qq(<table style='font-size:12px'>
<tr style='vertical-align:top;'><td>Track:</td><td><b>$h{IDS}{TRCK}</b></td></tr>
<tr style='vertical-align:top;'><td>Titel:</td><td><b>$h{IDS}{TIT2}</b></td></tr>
<tr style='vertical-align:top;'><td>Interpret:</td><td><b>$h{IDS}{TPE1}</b></td></tr>
<tr style='vertical-align:top;'><td>Album:</td><td><b>$h{IDS}{TALB}</b></td></tr>
<tr style='vertical-align:top;'><td>Genre:</td><td><b>$h{IDS}{TCON}</b></td></tr>
<tr style='vertical-align:top;'><td>Jahr:</td><td><b>$h{IDS}{TYER}</b></td></tr>
<tr style='vertical-align:top;'><td>Kommentar:</td><td><b>$h{IDS}{TCOM}</b></td></tr>
);
exit(0);
}

if ($form_input ->{'action'} eq "play" || $form_input ->{'action'} eq "add" || $form_input ->{'database'} eq "last") {
if ($form_input ->{'first'}) {
	my $i;
	for (@keys) {
		last if $_ eq $form_input ->{'first'};
		$i++;
		}
	if ($i) {
		my @newkeys;
		for ($i..$#keys) {
			push(@newkeys, $keys[$_]);
		}
		for (0..($i-1)) {
			push(@newkeys, $keys[$_]);
		}
		@keys = @newkeys;
	}
}

my $playlist = $form_input ->{'database'} eq "last" ? $tempdir."/tempplaylist.m3u" : createm3u(map { $h{$_}[0]{DIR}.$h{$_}[0]{FILENAME} } @keys); # $tempdir."/tempplaylist.m3u";
#print STDERR Dumper $playlist;

PlaylistHandler($playlist, ($form_input ->{'database'} eq "last") ? "play" : $form_input ->{'action'});

exit(0);
}

#push(@ul, "", "_special", "<ul class='iTab'>
#<li><a onclick='doJSByHref(\"$me?actualdb\")'>Aktuell</a></li>
#<li><a onclick='mp3Dialog(\"Database\", \"$querystring\", \"action=add&\" ,\"action=play&\");'>Alle&nbsp;(".@keys.")</a></li>
#</ul>"
#);
#<li onclick='this.style.display=\"none\"; getElementsByName(\"_mdboptbar\")[0].style.display = \"block\";' style=''>&nbsp;&nbsp;&nbsp;&nbsp;...&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>


push(@ul, "", "_special", "<li class='bar'>
<a class='inlinebutton lightlightbgButton' onclick='doJSByHref(\"$me?actualdb\")'>Aktuell</a>
<a class='inlinebutton lightlightbgButton' onclick='mp3Dialog(\"Database\", \"$querystring\", \"action=add&\" ,\"action=play&\", null, 1);'>Alle&nbsp;(".@keys.")</a>
</li>"
);

if ($form_input ->{'database'} eq "dir") {
	my $prekey; my $first;
	for (decode_glob($form_input ->{'search'}."*")) {
		if (-d $_) {
		push(@ul, "", "_special", "<li class='group' id='<b><i>Verzeichnisse</i></b>'>".$form_input ->{'search'}."</li>") unless $first; #wenn dir
		$first=1;
		
		my $sortid; 
		my $skey = basename($_);
		$sortid = "id='".uc(substr($skey, 0, 1))."'" if uc(substr($skey, 0, 1)) ne uc(substr($prekey, 0, 1));
		$prekey = $skey; #  wenn sortiert wird, sollten die Sortierbedingungen als id genommen werden.
		my $real = $_;
		$real = readlink $real if -l $real;
		$real =~ s/\/{2,}/\//g;
		push(@ul, "", "_special", "<li $sortid><a href='$me?database=dir&title=$skey&filter={DIR}&search=".escapeQw($real)."/&sort={FILENAME}' class='folder mainfont'>".$skey."</a></li>"); # dirlink schreiben
		}
	}
}

#my %elmnt = %{$$VAR1{qw{/mnt/media/music/actual/David_Guetta-One_Love-2CD-Ltd.Ed.-2009-ADK/114-david_guetta-if_we_ever_(feat._makeba).mp3}}[0]},"\n";

my $prekey; my $i=0; 
if ($maxkeysshown) {
	my $lastkey;
#	for (map { uc(substr(eval('$h{$_}[0]'.$sortkey), 0, 1)) } @keys ) { 
	my $from; my $firsti = 0;
	for my $key (@keys) { 
		my $word = eval('$h{$key}[0]'.$sortkey);
		$_ = substr($word, 0, 3); $_ =~ s/\s+$//;
		$from = substr($word, 0, 3) unless $from;
		#$i >= 30 && $_ ne $prekey && 
		my $last = ($firsti + $i >= $#keys);
		if ($i >= 50 && uc($_) ne uc($prekey) || $last) { 
			my $lasti = $firsti + $i;
			if ($last) { $prekey = $_ if $last;	$lasti++; }
#			push(@ul, "", "_special", "<li><a href='$me?$ENV{'QUERY_STRING'}&fromno=$firsti&tono=$lasti'><h3 style='text-align:left;'>".lc($from)."</h3><h3 style='text-align:right;'>".lc($prekey)."</h3><h2>$firsti - $lasti</h2></a></li>") if $prekey; 
			push(@ul, "", "_special", "<li><a href='$me?$querystring&fromno=$firsti&tono=$lasti'><h2 style='height:21px; text-align:left;'>".lc($from)."</h2><h2 style='height:21px;text-align:right;'>".lc($prekey)."</h2></a></li>") if $prekey; 
			$firsti=$lasti + 1;
			$i = 0;
			$from = $_;
		} else { $i++ }
		$prekey = $_;
	} 
} else {
push(@ul, "", "_special", "<li class='group' id='<b><i>Lieder</i></b>'>Lieder</li>") if scalar(@keys);
		my $nuniq = 1; my $groupimage;
		for (@keys) { # sind nur die gleichen bilder vorhanden könnte auch mit album geschehen, oder sonst. gecheckt werden
			unless (defined($h{$_}[0]->{IDS}{APIC})) {
				$nuniq = 1;
				last;
			}
			if ($groupimage) {
				if ($h{$_}[0]->{IDS}{APIC} ne $groupimage) {
					$nuniq = 1;
					last;
				}
			}
			$groupimage = $h{$_}[0]->{IDS}{APIC};
			$nuniq = 0;
		}
	
	push(@ul, "", "_special", qq{<li style='text-align:center;'><img src='$me?media=database&pic=$groupimage' style='margin:-8px 5px -11px -10px; width:300px; display:inline-block; ' /></li>}) unless $nuniq;
	
	for (@keys) { # Gruppen
		$i++;
		my $sortid; 
		if ($sortkey =~ /TIT2|TALB|POPM|TPE1/) {
			my $skey = eval('$h{$_}[0]'.$sortkey);
			$sortid = "id='".uc(substr($skey, 0, 1))."'" if uc(substr($skey, 0, 1)) ne uc(substr($prekey, 0, 1));
			$prekey = $skey; #  wenn sortiert wird, sollten die Sortierbedingungen als id genommen werden.
		}
		my @elmnts = @{$h{$_}}; # Elemente der Gruppe

		if ( $form_input ->{'group'} && ($#elmnts || $form_input ->{'group'} !~ /TIT2|TALB|POPM|TPE1/) && not (exists $form_input ->{'sub'}) ) { # wenn Elemente, und nicht nach angezeigten wert gruppiert wird
			my $len = scalar(@elmnts);
			my @pics;
			map { push(@pics, $_) if exists $$_{IDS}{APIC} } @elmnts;
			my $rand = int(rand(scalar(@pics)));
			#print STDERR Dumper @pics;
			if (@pics) {
			push(@ul, "", "_special", qq{
			<li $sortid afterPicture='$me?media=database&pic=$pics[$rand]{IDS}{APIC}'>
			<a class='objfont' href='$me?title=$_&$querystring&sub=$sub{$_}'>
			<img style='margin:-8px 5px -12px -10px; width:100px; height: 100px; display:inline-block;' />
			<span style='top:6px; position: absolute;'>$_
			<br>
			<font class='topfont'>$len Elemente</font></span>
			</a></li>
			});
			} else {
			push(@ul, "", "_special", qq{
			<li $sortid>
			<a class='objfont' href='$me?title=$_&$querystring&sub=$sub{$_}'>$_
			<br><font class='topfont'>$len Elemente</font></a></li>
			});
			}
		} else { # wenn ein Element
			my %elmnt = %{$elmnts[0]};
			my $stars=getStars($elmnt{IDS}{POPM}{Rating});
			my $prenuller = "0" x (length(@keys) - length($i));
			my $dlgtitle = encode_entities($elmnt{IDS}{TIT2});

			if (exists $elmnt{IDS}{APIC} && $nuniq) {
			push(@ul, "", "_special", qq{
			<li $sortid afterPicture='$me?media=database&pic=$elmnt{IDS}{APIC}' class='topfont' onclick='mp3Dialog("$dlgtitle", "&id=$elmnt{ID}", "database=search&action=add", "database=search&action=play", $stars, 1, true)'>
			<img style='margin:-8px 5px -11px -10px; width:100px; height: 100px; display:inline-block; ' />
			<span style='float:right; display: inline-block; margin-right: 8px; width: 65px; height: 23px;' id='&id=$elmnt{ID}' class='star$stars'></span>
			<span style='top:6px;  position: absolute;' class='hideoverflow'>$elmnt{IDS}{TPE1}</span>
			<span style='top:26px; position: absolute;' class='hideoverflow'>$elmnt{IDS}{TALB}</span>
			<span style='top:46px; position: absolute;'>$prenuller$i<font class='objfont'> $elmnt{IDS}{TIT2}</font></span></li>
			});
			} else {
			push(@ul, "", "_special", qq{
			<li $sortid class='topfont' style='padding-right: 80px;' onclick='mp3Dialog("$dlgtitle", "&id=$elmnt{ID}", "database=search&action=add", "database=search&action=play", $stars, 1, true)'>$elmnt{IDS}{TPE1}
			<span style='position: absolute; right: 8px; top: 8px;'>$elmnt{IDS}{TALB}</span>
			<br>
			<span style='position: absolute; right: 8px; top: 24px; width: 65px; height: 23px;' id='&id=$elmnt{ID}' class='star$stars'></span>
			$prenuller$i<font class='objfont'> $elmnt{IDS}{TIT2}</font></a></li>
			});
			}
		}
	}
}
buildul(@ul);