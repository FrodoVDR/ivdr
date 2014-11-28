makehtml();

my @ul; # Hauptmenerstellung
my @channels = &channels;
my @mediatypes;
my %menuuls;

$footer .= qq(<font class='footerfont'><center>
<p>iVDR $version</p>
</center></font>);

push(@ul,
"main", "<span id=\"menutitle\">$OPT{configname}</span>", "true' scroll='view' dynamicnode='divstatistic divstream",
"",		"_special", qq[<a onclick=''><img style="position: fixed; left: 2px; top:3px; z-index:1;" src="$weburl/logo.png" /></a>],
"",		"_special",	remoteButton());

#print $cgi->start_ul({-id=>'main', -title=>"<span id='menutitle'>$OPT{configname}</span>", -class=>'panel', -selected=>'true', -dynamicnode=>'divstatistic divstream'});
#print qq[<a onclick='ivdrDialog();'><img style="position: fixed; left: 2px; top:3px; z-index:1;" src="$weburl/logo.png" /></a>];
#print remoteButton();
#print $cgi->h2({}, "TV", $cgi->fieldse);
#print $cgi->div({-class=>'row'},$cgi->a({-href=>'#'},"TEST"));
#print $cgi->end_ul;

if ($OPT{stream}) {
push(@{$menuuls{stream_ul}}, "", "_special", "</fieldset><h2 id='stream_ul' title='Streams'>Streams".fieldsetmoveButton('stream_ul')."</h2><fieldset id='divstream' tag='".$me."?stream=overview'><div class='row topfont'><a>Loading...</a></div>");
}

if ($OPT{mediathek} || $OPT{media_music_on} || $OPT{media_video_on} || $OPT{media_radio_on}) {
push(@{$menuuls{media_ul}},	"",	"_group",	"<h2 id='media_ul' title='$L{MEDIA}'>$L{MEDIA}".fieldsetmoveButton('media_ul')."</h2>");
push(@{$menuuls{media_ul}}, "#mediathek",	"_iui",	"Mediathek") if $OPT{mediathek};
push(@mediatypes, {type=>"MUSIC", dir=>$OPT{media_music_dir}}) if $OPT{media_music_on};
push(@mediatypes, {type=>"MPLAYER", dir=>$OPT{media_video_dir}}) if $OPT{media_video_on};
push(@mediatypes, {type=>"RADIO", dir=>$OPT{media_radio_dir}}) if $OPT{media_radio_on};
for (@mediatypes) {	push(@{$menuuls{media_ul}}, scalar(@{$$_{dir}}) > 1 ? "#ln_".$$_{type} : "$me?DIR+".$$_{type}."+0", "_iui", $L{$$_{type}}) }
}

if ($OPT{vdr}) {
push(@{$menuuls{vdr_ul}},	"",			"_group", "<h2 id='vdr_ul' title='TV'>TV".fieldsetmoveButton('vdr_ul')."</h2>");
if ($OPT{usecategory}) {
	my %info = ("title" => $L{CHANNELS},
				"href"	=> "#ln_channels",
				"onchange" => "iui.showPageByHash(this.value); this.selectedIndex = 0; ", 
				"prevalue" => "ln_channels_grp_",
				"value" => []);
	for (@channels) { push (@{$info{value}}, $$_{name}) }

	push(@{$menuuls{vdr_ul}},	"",			"_special", twinButtonList(%info));
}
else { push(@{$menuuls{vdr_ul}},	"#ln_channels", "_iui", 	$L{CHANNELS}); }
push(@{$menuuls{vdr_ul}},	"$me?NOW",		"_iui",		$L{NOW},
			"#schedTime",	"_iui",		$L{AT},
			"$me?FAV",		"_iui",		$L{FAVS},
			"$me?TIMER",	"_iui",		$L{TIMER},
			"$me?REC=LIST' onclick='multiselect = false",		"_iui",		$L{RECORDS}
			);

push(@{$menuuls{vdrinfo_ul}}, "", "_special", "</fieldset><h2 id='vdrinfo_ul' title='$OPT{configname}'>$OPT{configname}".fieldsetmoveButton('vdrinfo_ul')."</h2><fieldset id='divstatistic' tag='$me?STAT'><div class='text topfont'>Loading...</div>");

push(@{$menuuls{epgs_ul}},	"",	"_group", "<h2 id='epgs_ul' title='EPG Search'>EPG Search".fieldsetmoveButton('epgs_ul')."</h2>",
			"",	"_special",	&quicksearch,
			"$me?EPGSEARCH","_iui",		$L{SEARCHES}
			);
}

if (@CONFSETS > 1) {
	push(@{$menuuls{conf_ul}}, "", "_group", "<h2 id='conf_ul' title='$L{PROFILE}'>$L{PROFILE}".fieldsetmoveButton('conf_ul')."</h2>");
	my $d;
	for (@CONFSETS) {
		my $host = $$_{configname};
		my $class;
		$class = 'checked' if $$_{configid} == $OPT{configid};
		push(@{$menuuls{conf_ul}}, "", "_special", qq{
			<div class='row $class' id='CHECKED$host'>
			<a onclick="document.cookie='IVDRSET=$d'; location.reload();">
			$host</a></div>}
		);
		$d++;
	}
}

if ($OPT{special_links_link}->[0]) {
	push(@{$menuuls{own_ul}},	"",	"_group",	"<h2 id='own_ul' title='$L{OWNLINKS}'>$L{OWNLINKS}".fieldsetmoveButton('own_ul')."</h2>");
	
	for (my $i; $i < @{$OPT{special_links_name}}; $i++) {
	 push(@{$menuuls{own_ul}}, $OPT{special_links_link}->[$i],$OPT{special_links_target}->[$i],$OPT{special_links_name}->[$i]);
	}
}

push(@{$menuuls{set_ul}},	"",	"_group",	"<h2 id='set_ul' title='$L{SETTINGS}'>iVDR".fieldsetmoveButton('set_ul')."</h2>",
			"#settings", "_iui", $L{SETTINGS},
			qq|onclick='var nds = document.getElementsByName("posnegbuttons"); for (var i=0; i < nds.length; ++i) { ddd(nds[i]); nds[i].style.display = "inline-block" }'|, "_no", $L{MOVE}
	);

	
my @mul;
for (getmenuorder()) {
next unless $menuuls{$_};
push(@mul,  @{$menuuls{$_}});
}
	

buildfieldset(@ul, @mul, $footer);

if ($OPT{vdr}) {
# ------------------------------------ Channelliste und Gruppenseperierte Channelliste --------------------------
&ulChannels("", @channels);
# ------------------------------------ Was l�ft um ---------------------
@ul=();
for (@schedtime) {
	my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat, $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(time);
	my $t = timelocal(0,substr($_,2), substr($_,0,2),$Monatstag, $Monat, $Jahr); 
		push (@ul, "", "_special", "\n<li><a href='$me?AT".substr($_,0,2).substr($_,2)."'>".fdate($t, $timef{schedtime})."</a></li>")	
}

buildul("schedTime", $L{AT}, "false' class='buttons", @ul);
}

# ------------------------------------ Erzeugt erste ebene der Verzeichnisse der Medientypen ---------------------
for (@mediatypes) {
@ul=();
if (scalar(@{$$_{dir}}) > 1) { my $i;
  for my $dirs (@{$$_{dir}}) {
    
	$dirs = {dir => $dirs} unless (ref $dirs);
	my $dstr = chClientDir($$dirs{dir});
	  push(@ul, "", "_no", "<a href='$me?DIR+".$$_{type}."+".$i++."' class='folder mainfont'>".basename($dstr)."<div class='subfont lesssize'> $dstr</div></a>" )
  } 
}
buildul("ln_".$$_{type}, $L{$$_{type}}, "false", @ul);
}

# ------------------------------------ Mediathek ---------------------

&ulsettings();

&mediathek() if $OPT{mediathek};

makehtml("food");

quitSocket();
exit(0);

sub ulChannels { # UL_Array  der Kan�e und der Kan�e Gruppensortiert

my $lnk = "ln_channels"; my $prglnk; my $d=0;my $col;
my $class = "' class='buttons";
my @prg; my @grpprg; my $tag = shift(@_);

push(@prg, $lnk, $L{CHANNELS}, "false' afterPictures='yes' class='buttons");

for (@_) {
	last if ! $$_{channels};
	#if ($d / 2 ne int($d / 2)) { $col = "darker" } 
	#else { $col = "light" }
	
	$prglnk = $lnk."_grp_".$d++;
	my $groupname = $$_{name};
	push(@grpprg, $prglnk, $$_{name} || $L{CHANNELS}, "false' afterPictures='yes' class='buttons");
# 8404 8406 8656 8678
# 8405 8407 8658 8680
	push(@grpprg,"", "_special", 
		"<ul class='iTab'>
			<li><a onclick='iui.showPageByHash(\"".$lnk."_grp_".($d-2)."\", true)'><font size=4>&#9668</font></a></li>
			<li><a onclick='iui.showPageByHash(\"".$lnk."_grp_".$d."\")'><font size=4>&#9658</font></a></li>
		</ul>");
		#margin: 1px 
		#"<a id='rightButton' class='button' href='#".$lnk."_grp_".$d."'><font size=14 style='line-height:58px;'>&nbsp;&#8407&nbsp;</font></a>");
		my $d;
		for (@{$$_{channels}}) {
			if ($$_{id}) {
				my $style;
				my $logo = getChannelLogo($$_{id}, 32);
				my $name = ($logo ? $logo."&nbsp;&nbsp;" : "").getChannelName($$_{id});
				$logo =~ s/src=\".*?\"//;
				$name =~ s/"/\\"/g;
				my $tag = "<h2>".($logo || getChannelName($$_{id}))."</h2>";
				my $no = "<h3>".$$_{no}."</h3>";
				
				if (! $d && $OPT{usecategory}) {
					$style .= " clear:left;";
					push (@prg,    "", "_special", "<li style='clear:left;' class='group'>$groupname</li>");				
				}
				#$tag = " ";	$no = "<h3>".$$_{no}."</h3>";
				#$name = "<img height=\\\"42px\\\" src=\\\"$me?media=chapic&id=$file\\\" />";
				#$style .= "background-image: url($me?media=chapic&id=$file); background-repeat:no-repeat; background-position:center;";
				my $ap = "afterPicture='".getChannelLogo($$_{id})."'" if $logo;
				push (@grpprg, "", "_special", "<li class='$col' $ap style='$style'><a onclick='chaDialog(\"".$$_{id}."\", \"".$name."\")'>".$tag.$no."</a></li>");
				push (@prg,    "", "_special", "<li class='$col' $ap style='$style'><a onclick='chaDialog(\"".$$_{id}."\", \"".$name."\")'>".$tag.$no."</a></li>");
#$OPT{chaimages}."/".$cgi->url_param('id').".png";
			}
			$d++;
		}
	buildul(@grpprg);
	@grpprg = ();
	}
	buildul(@prg);

}

sub quicksearch { # keine Parameter Erzeugt Quicksearch

my $qs = qq(<form id="searchForm" action="$me" method="GET" onsubmit="event.preventDefault(); submitForm(this); " style="margin:0;"><input type="hidden" name="change" value="quicksearch"><input type="hidden" name="type" value="dialog"><div class='row'><label><img style="margin:5px 0px 0px 0px" src="$weburl/Search.png"></label><input type="text" style="padding: 12px 10px 0 55px;" name="string" placeholder="quicksearch" onclick="javascript:showElement('showquicksearch')" /></div><div id="showquicksearch" style="display:none;">);
$qs .= toggle($L{TITLE}, "stitle", $L{YES}, $L{NO}, 1, "", 1, "0");
$qs .= toggle($L{EPISODE}, "ssubtitle", $L{YES}, $L{NO}, 1, "", 1, "0");
$qs .= toggle($L{DESCRIPTION}, "sdescr", $L{YES}, $L{NO}, 1, "", 1, "0");
$qs .= qq(<div class="row"><label>$L{SMETHOD}</label><select name="modus">
<option value="0">$L{PHRASE}</option>
<option value="1" selected>$L{ALLWORDS}</option><option value="2">$L{ONEWORD}</option><option value="3">$L{MATCHEXACTLY}</option><option value="4">$L{REGULAR}</option>
</select></div><div class="text" style="text-align:center; " ><nobr>
<input type="button" class="subButton whiteButton" onclick="javascript:hideElement('showquicksearch')" value="$L{HIDE}">
<input type="submit" class="subButton blueButton" value="$L{DOSEARCH}"/></nobr></div></div></form>);
}

sub mediathek {

my @ul;
print qq(<div id='mediathek' title='Mediathek' class='panel' dynamicnode='actualplay' scroll='view'>
<!--<a id='rightButton' style='padding:4px 10px 0; margin:-1px 0 0' class='button' onclick="var nd=\$('actualplay'); iui.showPageByHref(nd.getAttribute('tag'), null,null, nd)"><img src='$weburl/reload.png' /></a>-->
<a id='rightButton' class='button' href="#mdsearch">Suchen</a>
<!--<a class='button' onclick="var nd=\$('actualplay'); iui.showPageByHref(nd.getAttribute('tag'), null,null, nd)">Aktuell</a>-->
<fieldset id='actualplay' tag='$me?actualdb+fieldset' onclick="var nd=this; iui.showPageByHref(nd.getAttribute('tag'), null,null, nd)"><div class='row topfont' style='text-align:center; line-height:3em;'>Aktuelle Wiedergabe...</div></fieldset>

<h2 id='Verzeichnisse'>Verzeichnisse</h2><fieldset>);


my $i=0; my $moretag = "name='moredir' style='display:none'";
for (@{$OPT{media_music_dir}}) {
	#push(@ul, "", "_special", "<div onclick='this.style.display=\"none\"; for (var i in document.getElementsByName(\"moredir\")) document.getElementsByName(\"moredir\")[i].style.display=\"block\";' class='row'><a href='' class='mainfont'>...</a></div>") if $i == 3;
	print "<div onclick='this.style.display=\"none\"; for (var i in document.getElementsByName(\"moredir\")) document.getElementsByName(\"moredir\")[i].style.display=\"block\";' class='row'><label>...</label></div>" if $i == 3;
	unless (ref $_) {
		$_ .= "/" unless $_ =~ /\/$/;
		print "<div class='row folder' ".($i > 2 ? $moretag : "")."><a style='padding-bottom:3px;' href='$me?database=dir&sort={FILENAME}&filter={DIR}&search=".$_."&title=".basename($_)."'>".basename($_)."<div class='subfont nosize'>".$_."</div></a></div>";
	} else {
		$$_{dir} .= "/" unless $$_{dir} =~ /\/$/;
		print "<div class='row folder' ".($i > 2 ? $moretag : "")."><a style='padding-bottom:3px;' href='$me?database=dir&sort={FILENAME}&filter={DIR}&search=".$$_{dir}."&title=".basename($$_{dir})."'>".basename($$_{dir})."<div class='subfont nosize'>".$$_{dir}."</div></a></div>";
	}
	$i++;
}


my $last = qq(<div class='row play'><a onclick='doJSByHref("$me?database=last")'>Zuletzt gespielt</a></div>);

print qq(	</fieldset><h2 id='Wiedergabelisten'>Wiedergabelisten</h2><fieldset>$last
<div class='row listarrow'><a href='$me?database=search&group={II}{ADD}&sub=0&sorttype=>'>Neusten</a></div>
<div class='row listarrow'><a href='$me?database=search&numeric={IDS}{POPM}{Rating}&operation=ge 1&sort={IDS}{POPM}{Rating}&sorttype=>&tono=200'>Top200</a></div>
<div class='row listarrow'><a href='$me?database=search&numeric={IDS}{POPM}{Rating}&operation=eq 255&sort={IDS}{POPM}{Counter}'>Lieblingstitel</a></div>
<!--<div class='row listarrow'><a href=''>On the go</a></div>
<div onclick='this.style.display="none"; for (var i in document.getElementsByName("moreplaylist")) document.getElementsByName("moreplaylist")[i].style.display="block";' class='row'><label>...</label></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&search=wayne&filter={IDS}{TIT2}&filter={IDS}{TPE1}'>meistgespielt</a></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&sort={DIR}&sort={ID}'>Lieblingstitel</a></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&sort={DIR}&sort={ID}'>Lieblingstitel</a></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&search=Hip.*Hop&filter={IDS}{TCON}'>OK</a></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&search=Rap&filter={IDS}{TCON}'>OK</a></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&search=R.B&filter={IDS}{TCON}'>OK</a></div>
<div class='row listarrow' name='moreplaylist' style='display:none'><a href='$me?database=search&sort={DIR}&sort={ID}'>OK</a></div>-->
);

print qq(</fieldset><h2 id='Listen'>Listen</h2><fieldset>
<div class='row listarrow'><a href='$me?database=search&group={IDS}{TALB}&title=Album'>Album</a></div>
<div class='row listarrow'><a href='$me?database=search&sort={IDS}{TIT2}&title=Titel'>Titel</a></div>
<div class='row listarrow'><a href='$me?database=search&group={IDS}{TPE1}&title=Interpreten'>Interpreten</a></div>
<div class='row listarrow'><a href='$me?database=search&group={IDS}{TYER}&title=Jahr'>Jahr</a></div>
<div class='row listarrow'><a href='$me?database=search&group={IDS}{TCON}&title=Genre'>Genre</a></div>
);
	

print "</fieldset>";

#print qq(<h2 id='Plattform'>Wiedergabe Plattform</h2><fieldset>
#<div class='row checked'><a href='' onclick=''>VDR</a></div>
#<div class='row'><a href='' onclick=''>XBMC</a></div>
#<div class='row'><a href='' onclick=''>VLC</a></div>
#<div class='row'><a href='' onclick=''>IceCast</a></div>
print qq(</fieldset></div>);




my $qs = qq(<fieldset><div class='row'><label><img style="margin:5px 0px 0px 0px" src="$weburl/Search.png"></label>
<input type="text" style="padding: 12px 10px 0 55px;" name="search" placeholder="Suchfeld" />
<!--onclick="javascript:showElement('showquicksearch')" />--></div>);

$qs .= qq(<div class="row"><label>Gruppieren</label><select name="group" style="left:130px">
<option value="" selected>Nein</option>
<option value="{IDS}{TIT2}">Titel</option>
<option value="{IDS}{TPE1}">Interpret</option>
<option value="{IDS}{TALB}">Album</option>
<option value="{IDS}{TCON}">Genre</option>
<option value="{IDS}{TYER}">Jahr</option>
<option value="{DIR}">Verzeichnis</option>
</select></div>);


$qs .= qq(</fieldset><h2 id='Listen'>Suchen in</h2><fieldset>);
$qs .= toggle("Dateiname", "filter", "Ja", "Nein", 1, "", "{FILENAME}","0");
$qs .= toggle("Titel", "filter", "Ja", "Nein", 1, "", "{IDS}{TIT2}","0");
$qs .= toggle("Interpret", "filter", "Ja", "Nein", 1, "", "{IDS}{TPE1}","0");
$qs .= toggle("Album", "filter", "Ja", "Nein", 0, "", "{IDS}{TALB}","0");
$qs .= toggle("Genre", "filter", "Ja", "Nein", 0, "", "{IDS}{TCON}","0");
				

$qs .= qq(</fieldset><fieldset>);

$qs .= toggle("Verzeichnisse", "nofilter2", "", "Alle", 0, "toggleDiv(this, 'searchdirdiv')", "0","1");
$qs .= "<div id='searchdirdiv' style='display:none'>";
for (@{$OPT{media_music_dir}}) {
	unless (ref $_) {
		$_ .= "/" unless $_ =~ /\/$/;
		#$qs .= "<option value='{DIR}=$_'>".basename($_)."</option>)";
		$qs .= toggle(basename($_), "filter2", "Ja", "Nein", 0, "toggleDiv(this, 'filter2')", "{DIR}=$_","");
	} else {
		$$_{dir} .= "/" unless $$_{dir} =~ /\/$/;
		#$qs .= "<option value='{DIR}=".$$_{dir}."'>".basename($$_{dir})."</option>)";
		$qs .= toggle(basename($$_{dir}), "filter2", "Ja", "Nein", 0, "toggleDiv(this, 'filter2')", "{DIR}=$$_{dir}","");
	}
}
$qs .= "</fieldset></div>";

my $qo .= qq(<div class="text" style="text-align:center; " ><nobr>
<!--<input type="button" class="subButton whiteButton" onclick="javascript:hideElement('showquicksearch')" value="$L{HIDE}">-->
<input type="submit" class="subButton blueButton" value="$L{DOSEARCH}"/></nobr></div>);
	
print qq(
<form id="mdsearch" action="$me" method="GET" class='panel' onsubmit="event.preventDefault(); submitForm(this); " style="margin:0;" title='Suchen'>
<input type="hidden" name="database" value="search">
<input class="button redHeadButton" type='submit' name="searchbutton" value=$L{DOSEARCH}>
<!--<input type="hidden" name="type" value="dialog">-->
$qs
</form>);

}

sub ulsettings {

print qq|
<div id="settings" class="panel" title="$L{SETTINGS}">
<a class="button blueHeadButton" href="$me?confighandler=load&set=new">$L{NEW}</a>
<h2>$L{EDIT}</h2>
<fieldset>|;
my $d=0;
for (@CONFSETS) {
print qq|<div class="row listarrow"><a href="$me?confighandler=load&set=$d">$$_{configname}</a></div>|;
$d++;
}
print qq|</fieldset>|;
if (@CONFSETS>1) {
print qq|<h2>Homescreenicon</h2> <fieldset>|;
	for ($d=0; $d<@CONFSETS; $d++) {
	#<div class="row listarrow"><a onclick="" href="$me?confighandler=load&set=$d">$$_{configname}<a/></div>
	next unless $d;
	my $title=$CONFSETS[$d]{configname};
	print qq|<div class='row'>
	<a onclick="document.cookie='IVDRHS=$title'; window.open('$me?load=$d', 'HomescreenHandler');">
	$title</a></div>|;
	}
print qq|</fieldset><center><font class='footerfont'>Create a Homescreenicon to start directly with the choosen settings!</font></center>|;
}
print qq|</div>|;

}

sub fieldsetmoveButton {
return unless @_;
return(qq|
<img onclick="moveFieldset(\$('$_[0]'), 'false'); doJSByHref('$me?MENUMOVE+$_[0]+-1');" name="posnegbuttons" style="display:none; right:38px;" src="$weburl/upbtn.png">
<img onclick="moveFieldset(\$('$_[0]', 'true')); doJSByHref('$me?MENUMOVE+$_[0]+1');" name="posnegbuttons" style="display:none; right:0px;" src="$weburl/downbtn.png">
|);
#SimpleHttpRequest
}

sub buildfieldset { # baut die html Aufz�lung auf, Arg0->ID Arg1->Title, Arg2->selected[true,false] , ab Arg3 link, target, title, letzter ist der  title der ersten group		->STDOUT
my @ul = @_;

print "<div id='".shift(@ul)."' title='".shift(@ul)."' class='panel' selected='".shift(@ul)."'>";
#<li class="group">Z</li>
my $footer = pop(@ul);
for (my $i = 0; $i < @ul; $i++) {
	if ($ul[$i+1] eq "_iui") {
		print "<div class='row listarrow'><a href='$ul[$i]'>".$ul[++$i+1]."</a></div>";
		++$i;
	}
	elsif ($ul[$i+1] eq "_no") {
		print "<div class='row' $ul[$i]><label>$ul[++$i+1]</label></div>";
		++$i;	
	}
	elsif ($ul[$i+1] eq "_group") {
		print "</fieldset>$ul[++$i+1]<fieldset>";
		++$i;	
	}
	elsif ($ul[$i+1] eq "_special") {
		print "$ul[++$i+1]";
		++$i;	
	}
	elsif ($ul[$i+1] eq "_replace") {
		print "<div class='row'><a href='$ul[$i]' target='_replace'>".$ul[++$i+1]."</a></div>";
		++$i;
	}	
	else {
		print "<div class='row'><a href='$ul[$i]' target='$ul[++$i]'>$ul[++$i]</a></div>";
	}
}	
print "</fieldset>";
print "$footer</div>";
}

