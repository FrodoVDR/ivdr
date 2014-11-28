#!/usr/bin/perl

# iVDR Version 0.3 Webfrontend for touchdevices

# Copyright (C) 2008-2011  Oliver Georgi

# This program is free software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation; either version 3 of 
# the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See 
# the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with this program; if not,
# see <http://www.gnu.org/licenses/>.

# http://www.i-vdr.de
# info@i-vdr.de
 
use strict;
use CGI ':standard';;
use CGI::Carp qw(fatalsToBrowser);
use Encode;
use File::Basename;
use File::Glob ':glob';
use Time::Local;
use Socket;	
use HTML::Entities;
use URI::Escape;
use URI::Escape 'uri_escape_utf8';
use Storable;

use Data::Dumper;

use vars qw(	
		$version $cgi @query $form_input
		$files $me $configfile $configmenu $istream
		%OPT @CONFSETS %L 
		$tempdir $debug $weburl $atprocess @schedtime @menusort $jscript $UserDefinedInfoFile 
		%timef %mediaselect
		$footer %dbmusic
		@timerinfo @channelinfo %epgdata $connection
		
		@lirccontrols @usercontrol
);

END { 
	quitSocket() if $connection;
	close(STDERR); 
}

$version = "0.3.3";
$cgi = new CGI;
$me = $cgi->script_name();
$me =~ s/\?.*$//;
$files = "./components/";;
$configfile = $files."ivdr.db";
@query = split(/\+/, $ENV{'QUERY_STRING'});
@query = @ARGV unless @query; 
umask 0;

push(@INC, $files);
require config;

mkdir $tempdir unless -d $tempdir; die "Can't acces iVDR-Workdir" unless -w $tempdir;

open(STDERR, ">> $tempdir/ivdr.log") or warn "Failed to redirect STDERR. Check rights of $tempdir/ivdr.log";

sub loadlanguage {
	do $OPT{language}.".lang.pack" || do substr($ENV{HTTP_ACCEPT_LANGUAGE}, 0, 2).".lang.pack" || do "en.lang.pack" && warn "Error loading language: $OPT{language}. Loading defaults!" || die "lang.pack Error: $!";
}
if (defined($cgi ->url_param("load"))) {
my $link = $cgi->url_param("load");
print $cgi->header(-type => 'text/html');

if (defined(my $title = $cgi->cookie(-name=>'IVDRHS'))) {
my $abs=$cgi->server_name();
print qq|
<html><head>
<link rel='apple-touch-icon' href='http://$abs/$weburl/icon.png' />
<link rel='shortcut icon' href='$weburl/favicon.ico' type='image/x-icon'>
<meta http-equiv='content-type' content='text/html; charset=$OPT{charset}'>
<meta name='viewport' content='width=320; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;' />
<style type='text/css' media='screen'>\@import '$weburl/iui.css';</style>
<script type='application/x-javascript' src='$jscript'></script>
<title>iVDR ($title)</title>
<script type='text/javascript'>
document.cookie = 'IVDRHS=0; expires=Thu, 01-Jan-70 00:00:01 GMT;';
</script>
</head><body>

</body></html>|;
dbg($cgi->cookie(-name=>'IVDRHS'));
# <link rel='apple-touch-icon-precomposed' href='http://$cgi->server_name()/$weburl/icon.png' />
# <meta name='apple-mobile-web-app-capable' content='yes' />

} else {
print qq|
<html><head>
<meta http-equiv="set-cookie" content="IVDRSET=$link">
<meta http-equiv="refresh" content="0; URL=$me">
</head></html>|;
}
exit(0);
}
unless (loadconfig($cgi->cookie(-name=>'IVDRSET'))) {
	warn "Error while loading Configuration! $@";
	loadlanguage();
	$footer .= js("alert('$L{WELCOME}')") if -z $configfile;
} else { loadlanguage(); $footer .= js("alert('$L{CONFIGERR}')") if $OPT{configversion} ne $version; }

require packages;

if ($cgi->url_param('media')) {
do "mediastream.pl";
warn "couldn't parse mediastream.pl: $@" if $@;
exit(0);
}

print STDERR fdate(time, "[IVDR LOG: #d#.#m#.#y# #HH#:#MM#:#SS#]"), "$ENV{'REMOTE_ADDR'}:", $ENV{'REQUEST_URI'}, " - Method: ", $ENV{'REQUEST_METHOD'}, " - Length: ", $ENV{'CONTENT_LENGTH'}, " - CONFIG: ".$OPT{configname}."]\n";

if ($OPT{binmodetoutf8}) {
	binmode(STDOUT, ":encoding(utf-8)");
	binmode(STDERR, ":encoding(utf-8)");

	@query = map { decode("utf8", uri_unescape($_)) } @query;
}
else { @query = map { uri_unescape($_) } @query }

if ($query[0] =~ /^(-v|--version|--config|-c)$/i) { 
	print "iVDR - Webfrontend for touch devices. Version $version\n";
	exit(0) if $query[0] =~ /-v|--version/i;
	print "----------->  Mainconfig  <------------\n";
	my @main = fileArray($files."config.pm");
	for (@main) {
	print $_,"\n";
	}
	print "---------->  Configuration $query[1] <----------\n";
	my %h = %{$CONFSETS[$query[1]]};
	for (sort keys(%h)) {
	next if $_ =~ /^(filter|filter2|database|group|modus|nofilter2|sdescr|search|searchbutton|ssubtitle|stitle|string|type)$/;
my $val = (ref $h{$_} ? join(", ", @{$h{$_}}) : $h{$_});
write;
format STDOUT =
@<<<<<<<<<<<<<<<<<<<<< @*
$_ $val
.
	}
	exit(0);
}
#elsif ($query[0] eq "MANIFEST") {
#
##print $cgi->header(-type    =>'text/cache-manifest', -charset => $OPT{charset});
#print $cgi->header(-type    =>'text/cache-manifest');
#
#my @files = qw(
#active.png           bottombarblue.png       btn_epgs.png    btn_stop.png       delete.png       key_forw.png      loading.gif      old_listGroup.png  remove.png           thumb.png
#addbtn.png           bottombardarkgray2.png  btn_folder.png  btn_stream.png     downbtn.png      key_next.png      loadingipad.png  PinGreen.png       Search.png           toggle.gif
#add.png              bottombargray.png       btn_info.png    btn_switch.png     extendedbtn.png  key_ok.png        logo.png         Pin.png            selection.png        toggleOn.gif
#AddressViewStop.png  bottombargreen.png      btnllbg.png     btn_trash.png      favicon.ico      key_pause.png     modal.png        pinstripes.png     star0.png            toolbar.png
#attention.png        bottombarredfire.png    btn_mark.png    bullet-media.png   folder.png       key_prev.png      More_org.png     playbtn.png        star1.png            toolButton_old.png
#backButton.png       bottombarwhite.png      btn_play.png    button-light.png   icon.png         key_stop.png      More.png         ratestar.png       star2.png            toolButton.png
#barorange.png        bottombaryellow.png     btn_save.png    buttonoverlay.png  info.png         LICENSE.txt       mplus.png        recdeact.png       star3.png            upbtn.png
#bar.png              btn_add.png             btn_sched.png   button-red.png     iui.css          listArrow.png     new.png          recinfo.js         star4.png            whitedot.png
#barseperator.png     btn_cancel.png          btn_search.png  cancel.png         iui_dev.js       listArrowSel.png  next.png         rec.png            star5.png            whitestar.png
#barwhite.png         btndlbg.png             btn_show.png    check.png          iui.js           listGroup.png     NOTICE.txt       refresh.png        StarsBackground.png
#blueButton.png       btn_edit.png            btn_start.png   cut.png            key_back.png     loading2.gif      reload.png       StarsForeground.png
#);
#
#print qq<CACHE MANIFEST
#
## 2012-02-15 15:48
#>;
#print map { $weburl."/".$_."\n" } @files;
#
#print qq|
#NETWORK:
#*
#|;
#
#dbg("Manifest loaded!");
#exit(0);
#}

print $cgi->header(-type    =>'text/html', -charset => $OPT{charset});

foreach my $name ( $cgi ->url_param ) {
  my @val = $cgi ->url_param( $name );
  foreach ( @val ) {
	$_ = decode("utf-8", $_) if $OPT{binmodetoutf8};
  }
  $name = decode("utf-8", $name) if $OPT{binmodetoutf8};
  if ( scalar @val == 1 ) {   
	$form_input ->{$name} = $val[0];
  } else {                      
	$form_input ->{$name} = \@val;  # save value as an array ref
  }
}

if ($form_input ->{'test'} eq "own" ) { #zeigt die bergebenen Parameter an

my $para;

$para .= "Request Methode: ".$cgi->request_method()."\n";
$para .= "\$cgi->param\n\nName \t   Wert\n------------\n";
	for (keys(%$form_input)) { 
	$para .= "$_ \t".$form_input ->{$_}."\n";
	}

print STDERR $para;
print STDERR "------------- ENDE ------------\n";
exit(0);
}
elsif ($form_input ->{'test'} eq "dumper" ) { #zeigt die bergebenen Parameter an

my $para;

$para .= "Request Methode: ".$cgi->request_method()."\n"; 
$para .= "\$cgi->param\n";
print STDERR $para;
print STDERR Dumper $form_input;
print STDERR "------------- ENDE ------------\n";
exit(0);
}

if (exists $form_input ->{'confighandler'}) {
do "config.pl";
warn "couldn't parse config.pl: $@" if $@;
exit(0);
}

if (exists $form_input ->{'database'}) {
do "mediathek.pl";
warn "couldn't parse mediathek.pl: $@" if $@;
exit(0);
}

$OPT{vdr_streamdev} = "http://$ENV{SERVER_ADDR}:3000/TS/" unless $OPT{vdr_streamdev};

if (exists $form_input ->{'stream'}) { 
do "istream.pl";
warn "couldn't parse istream.pl: $@" if $@;
exit(0);
}

if ($query[0] eq "MENUMOVE") {

@menusort=getmenuorder();
my $d=0;
for (@menusort) {  last if $_ eq $query[1]; $d++; }

my $i =eval($d."+($query[2])");
my $tmp = $menusort[$d];
$menusort[$d] = $menusort[$i];
$menusort[$i]=$tmp;

#my $cookie1 = cookie(-name=>'IVDRMENUSORT', -value=>join(" ", @menusort));
#my $cookie1 = new CGI::Cookie(-name=>'IVDRMENUSORT',-value=>join(" ", @menusort));
#print $cgi->header(-type    =>'text/html', -charset => $OPT{charset}, -cookie=>$cookie1);
print "document.cookie='IVDRMENUSORT=".join(" ", @menusort)."';";

exit(0);
}
elsif ($query[0] eq "DATAMARKFILE") { 				# vdrTube Plugin (erzeugt eine Liste anhand der xml Dateien)
die ("Missing Parameter!") unless $query[1];
die "Please create an writeable markedfiles.log" unless -w "./markedfiles.log";

my @marked = fileArray("./markedfiles.log");

my $file = chServerDir($query[1]);

my $res;
if(grep(/^$file$/, @marked)) {
dbg("Erase markup!");
@marked = grep(!/^$file$/, @marked);
$res = join("\n", @marked);
}
else {
dbg("Put markup!");# Have  to do this because push destroys specialcases
$res = join("\n", @marked)."\n".$file;
}

open(FILE, "> ./markedfiles.log") or die "Can not open markedfiles.log: $!\n";
binmode(FILE, ":encoding(utf-8)") if $OPT{binmodetoutf8};
print FILE $res;
close(FILE);
exit(0);
}
elsif ($query[0] eq "DIR") { 				# Erzeugt eine Verzeichnisstruktur als Aufz�lung $query[1]
if (! defined($query[1])) {die "Fehlender Parameter: TYP!"}

my %bdp = %{$mediaselect{$query[1]}};

# DIR (twindir)
#"<li id='$id'><img class='inlineleft' src='$weburl/extendedbtn.jpg' onclick='".$bdp{dialog}."(\"".$filename."\",\"".$_."\",\"".($bdp{diradd} ? $bdp{action}.$bdp{diradd} : "")."\",\"".($bdp{dirplay} ? $bdp{action}.$bdp{dirplay} : "")."\")' /><a href='#".$_tmp."' class='img folder mainfont' style='line-height:42px; padding-top:0px'>".$filename."<div class='subfont nosize'> ".$dir."</div></a></li>"

#FILE (twin)
#"<li id='$id'><img class='inlineleft' src='$weburl/playbtn.jpg' onclick='iui.showPageByHref(\"".$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}.($bdp{add} ? $bdp{add} : $bdp{play}).$file."\")' /><a onclick='".$bdp{dialog}."(\"".$filename."\",\"".$file."\",\"".($bdp{add} ? $bdp{action}.$bdp{add} : "")."\", \"".($bdp{play} ? $bdp{action}.$bdp{play} : "")."\")' class='img none smallfont minsize'>".$filename."</a>$sub</li>"
# -
#"<li id='$id'><a href='".$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}.$bdp{play}.$file."' class='play smallfont minsize'>".$filename."</a>$sub</li>"

$bdp{id}		= "ln_".$query[1];
$bdp{title}		= $L{$query[1]};

my $aktdir = @{$bdp{dir}}[$query[2] || 0];

if ($aktdir =~ /^HASH\(/) { 
	$bdp{dir} = $$aktdir{dir};
	$bdp{pat} = $$aktdir{pat} if $$aktdir{pat};
	$bdp{rek} = defined($$aktdir{rek}) ? $$aktdir{rek} : $bdp{rek};
	
} else {
	$bdp{dir} = $aktdir;
}
#print STDERR Dumper(%bdp)."\n";

my @dirs = ($bdp{dir});


warn "Please create an writeable markedfiles.log" unless -w "./markedfiles.log";
my @marked = fileArray("./markedfiles.log");

for (@dirs) {
  (my $_tmp = $_)=~tr/a-zA-Z_0-9//cd;

  my $sel =  "fasle"; #$$$key{selected} ? "true" : "false";
  my @ul = ($_tmp, basename($_), $sel."' temporary='all' scroll='view");

  #my @inner = sort { ((-d $a) ? 0 : 1) <=> ((-d $b) ? 0 : 1) } <${_}/*>; # Verzeichnisse an erste stelle;
  
  my @inner = sort { -d $b <=> -d $a } decode_glob("$_/*"); # Verzeichnisse an erste stelle;
  my $sortletter; my $id;

  for (@inner) {
	my $filename = encode_entities(basename($_), '"\'');

	if (scalar(@inner) > 20 && $sortletter ne uc(substr($filename,0,1))) { $id = uc(substr($filename,0,1)); $sortletter = $id; }
	else { $id = "" }			

    if (-d $_) {
     my ($hassubdir, $hasfiles);
     if (my @innerinner = decode_glob("$_/*")) { # wenn unterverzeichnis nicht leer ist
	   for (@innerinner) {  
        if (-d $_ && $bdp{rek}) { $hassubdir=1 } # verzeichnis muss entweder verzeichnisse enthalten(bei $bdp{rek}) oder dateien die auf regex passen
        if (-d $_) { $hassubdir=1 } # verzeichnis muss entweder verzeichnisse enthalten oder dateien die auf regex passen
		elsif (-z $_) { next }
		elsif ($_ =~ /\.m3u$|\.($bdp{pat})$/ &! -d $_) { $hasfiles = 1 }
        }
       if ($hassubdir || $hasfiles) {
		(my $_tmp = $_)=~tr/a-zA-Z_0-9//cd;
			
			my $dir = chClientDir($_);
			my $direntity = encode_entities($dir);
			
			#my $dir = encode_entities($_);
			if (($bdp{diradd} || $bdp{dirplay}) && $hasfiles) {
			#\"".($bdp{dirplay} ? $bdp{action}.$bdp{dirplay} : "")."\"
			#my @rp = (ref $bdp{dirplay}) ? @{$bdp{dirplay}} : ($bdp{dirplay});
			#my $playurl = "null"; $playurl = '["'.$bdp{action}.join('", "'.$bdp{action}, @rp).'"]' if $bdp{dirplay};
			#\"".($bdp{diradd} ? $bdp{action}.$bdp{diradd} : "")."\"			
			#my @ra = (ref $bdp{diradd}) ? @{$bdp{diradd}} : ($bdp{diradd});
			#my $addurl = "null"; $addurl = '["'.$bdp{action}.join('", "'.$bdp{action}, @ra).'"]' if $bdp{diradd};
			my $playurl = "null"; 
			my $action = ($bdp{diraction} || $bdp{action});
			if ($bdp{dirplay}) {
				my @rp = (ref $bdp{dirplay}) ? @{$bdp{dirplay}} : ($bdp{dirplay});
				#$playurl = '"'.$bdp{action}.$bdp{dirplay}.'"';
				$playurl = '["'.$action.join('", "'.$action, @rp).'"]';
				$playurl=~s/\{pat\}/$bdp{pat}/;
				
			}
			my $addurl = "null"; 
			if ($bdp{diradd}) {
				my @rp = (ref $bdp{diradd}) ? @{$bdp{diradd}} : ($bdp{diradd});
				#$addurl = '"'.$bdp{action}.$bdp{diradd}.'"';
				$addurl = '["'.$action.join('", "'.$action, @rp).'"]';
				$addurl=~s/\{pat\}/$bdp{pat}/;
			}
			
			#push(@ul, "", "_special", "<li id='$id'><img class='inlineleft' src='$weburl/playbtn.jpg' onclick='".$bdp{twindir}."(\"".$filename."\",\"".uri($_)."\",\"".$bdp{diraction}."\")' /><a href='#".$_tmp."' class='img folder mainfont'>".$filename."<font class='subfont nosize'> ".$direntity."</font></a></li>") }
			push(@ul, "", "_special", "<li id='$id'><img class='inlineleft' src='$weburl/extendedbtn.png' onclick='".$bdp{dialog}."(\"".$filename."\",\"".$_."\", $addurl, $playurl, null, true)' /><a href='#".$_tmp."' class='img folder mainfont' style='white-space:nowrap; line-height:42px; padding-top:0px'>".$filename."<div class='subfont nosize'> ".$direntity."</div></a></li>")
			#push(@ul, "", "_special", "<li id='$id'><img class='inlineleft' src='$weburl/extendedbtn.png' onclick='mediaDialog(\"".$filename."\",\"".$_."\", \"diradd\", \"dirplay\")' /><a href='#".$_tmp."' class='img folder mainfont' style='line-height:42px; padding-top:0px'>".$filename."<div class='subfont nosize'> ".$direntity."</div></a></li>")
			} else { push(@ul, "", "_special", "<li id='".$id."'><a href='#".$_tmp."' class='folder mainfont' style='white-space:nowrap'>".$filename."<br><font class='subfont lesssize'> ".$direntity."</font></a></li>") } # dirlink schreiben
			push(@dirs, $_) if $bdp{rek};
       }
     }
    } elsif (-z $_) { next # notwendig...
#    } elsif (-w $_) { next  #Datei kann beschrieben werden evtl woanders sinnvoller
    }
    #elsif ($_ =~ /\.m3u$/) { push(@$$akt, $_) }
    # Playlist schreiben
    # dirlink: dblclick oder twinbutton, dialogfeld mit alles abspielen hinzufgen..., navigieren
    elsif ($_ =~ /\.($bdp{pat})$/) {
		my $_temp = $_;
		$_temp =~ s/\(|\)/\\$&/g;
#		my $file = uri($_);
		my $sub; my $orgfilename = $filename;
		if (yes($UserDefinedInfoFile) && -f $_.".info") {
			my $read = readFile($_.".info");
			$filename = encode_entities($2) if $read =~ /<title>(<!\[CDATA\[)*(.*?)(\]\]>)*<\/title>/si;
			$filename =~ s/&quot;|\r|\n//g;
			#warn $filename;
			$sub = "<br><font style='margin: 0px 15px' class='subfont'><b>$orgfilename</b><br>$2</font>" if $read =~ /<description>(<!\[CDATA\[)*(.*?)(\]\]>)*<\/description>/si;
		}

		my $file = uri(chClientDir($_));
		#my $file = $_;
		# \"".($bdp{play} ? $bdp{action}.$bdp{play} : "")."\"
		my @rp = (ref $bdp{play}) ? @{$bdp{play}} : ($bdp{play});
		my $playurl = "null"; $playurl = '["'.$bdp{action}.join('", "'.$bdp{action}, @rp).'"]' if $bdp{play};
		# \"".($bdp{add} ? $bdp{action}.$bdp{add} : "")."\"
		my @ra = (ref $bdp{add}) ? @{$bdp{add}} : ($bdp{add});
		my $addurl = "null"; $addurl = '["'.$bdp{action}.join('", "'.$bdp{action}, @ra).'"]' if $bdp{add};
		#SimpleHttpRequest(\"".$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}.($bdp{add} ? $bdp{add} : $bdp{play}).$file."\")
		my @rr = @rp;
		@rr = @ra if $bdp{add};
		my $addbtn; $addbtn = "<img class='inlineleft' src='$weburl/".($bdp{add} ? "addbtn" : "playbtn").".png' onclick='".'SimpleHttpRequest("'.$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}.join('", "'.$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}, @rr).$file.'");\' />' if $bdp{add} || $bdp{play};
		
		#dbg($_temp);
		push(@ul, "", "_special", 		
		"<li id='$id' class='".(grep(/^$_temp$/, @marked) && "checked")."'>$addbtn<a onclick='".$bdp{dialog}."(\"".$filename."\",\"".$file."\", $addurl, $playurl, null, null, null, true)' class='img none smallfont minsize'>".$filename."</a>$sub</li>");
		#if ($bdp{add}) { push(@ul, "", "_special", "<li id='$id'><img class='inlineleft' src='$weburl/playbtn.jpg' onclick='SimpleHttpRequest(\"".$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}.($bdp{add} ? $bdp{add} : $bdp{play}).$file."\")' /><a onclick='".$bdp{dialog}."(\"".$filename."\",\"".$file."\",\"".($bdp{add} ? $bdp{action}.$bdp{add} : "")."\", \"".($bdp{play} ? $bdp{action}.$bdp{play} : "")."\")' class='img none smallfont minsize'>".$filename."</a>$sub</li>") }
		#else { push(@ul, "", "_special", "<li id='$id'><a href='".$mediaselect{_OPT_}{SCRIPTNAME}.$bdp{action}.$bdp{play}.$file."' class='play smallfont minsize'>".$filename."</a>$sub</li>") }
	}
  }
buildul(@ul);
}
#  print STDERR Dumper(@dirs)."\n";
exit(0);

}
elsif ($query[0] eq "LIRC") { 				# LIRC-Tunnel
shift(@query);
my $no = shift(@query);
if ($no == "ub") { irsend($usercontrol[shift(@query)]) } 
else { irsend($lirccontrols[$no]) }

exit(0);
}
elsif ($query[0] eq "PANIC") { 				# Panicscript starten js Rckgabe
my $result;
if ($OPT{panic_script}) { $result = qx($OPT{panic_script} 2>&1);	}
else { print "alert('No Panicscript defined!');" }
	
	print STDERR $result if $debug;
	$result=~s/\n/\\n/g;
	$result=~s/\r//g;
	print "alert('".$result."')";
	exit(0);
}
elsif ($query[0] eq "cmdat") { 				# Fhrt den Befehl zu einer bestimmten Zeit aus. Liegt er in der Vergangenheit dann sofort.

shift(@query);
my $t = shift(@query) - $OPT{pre_switch_time};

if ($t <= time) {
	unshift(@query, "cmd");
}
else {
	print STDERR fdate($t, "#HH##MM# #mm##dd##yy#")." _ "."$0\n" if $debug;
	
	open(IN, "| $atprocess ".fdate($t, "#HH##MM# #mm##dd##yy#")) or errout();
	print IN $0." cmd ".join(" ", @query);
	print IN "\cD";
	close (IN);
	

	print "alert('".decode_entities($L{ATCOMMAND})." ".fdate($t, $timef{timer})."');"; 
	exit(0);
}
sub errout { print "alert('Error while opening at: $!');"; exit(1); }
}


require svdrp;
establishSocket(); 
require vdr;
require htmlelement;
$OPT{usecategory} = ($OPT{usecategory} && -e $OPT{channels});

if (exists $form_input ->{'change'}) {			# Parameterverarbeitung von Formulardaten

if ($form_input ->{'change'} eq "timer" || $form_input ->{'change'} eq "new") {
# my %vars = $cgi->Vars; # k�nte evtl umlaute decodieren
# $form_input ->{'change'} = timer
# id, head, title, name, channelid, active ,activechannel , date, start, stop, prio, life
# change,  name, channel, date, start, stop, prio, life

my $type = "NEWT"; $type = "MODT" if $form_input ->{'id'};

my $t = $form_input ->{'id'}." ";
$t .= $form_input ->{'active'};
#$t .= ":".$form_input ->{'channel'}.":".$form_input ->{'date'}.":".$form_input ->{'starth'}.$form_input ->{'startm'};
$t .= ":".$form_input ->{'channel'}.":".$form_input ->{'year'}."-".$form_input ->{'month'}."-".$form_input ->{'day'}.":".$form_input ->{'starth'}.$form_input ->{'startm'};
$t .= ":".$form_input ->{'stopph'}.$form_input ->{'stoppm'}.":".$form_input ->{'prio'}.":".$form_input ->{'life'}.":";
$t .= $form_input ->{'dir'}."~" if ( $form_input ->{'dir'} ne "");
$t .= $form_input ->{'name'}.":";
$t .= $form_input ->{'aux'};
print STDERR "Modificate Timer: ".$t."\n" if $debug;
my $result = Receive("$type $t");
$result =~ s/\r\n//g;
my @r = split(/:/, $result);
$result = "$L{SAVETIMER}!\\n $r[2] $r[3]-$r[4]\\n$r[7]\\n$r[5] / $r[6]";

print " alert(\"$result\"); ";

}
elsif ($form_input ->{'change'} eq "quicksearch" ) {
if ($form_input ->{'window'} eq 'dialog') {
	makehtml("", "", "");
	makehtml("food");
	
}
my %search; my @ul = ("epgsearch", $form_input ->{'string'}, "true' temporary='yes' scroll='view' tag='".$ENV{'REQUEST_URI'});

push(@ul, "", "_special", closeButton()) if ($form_input ->{'window'} eq 'dialog');
     
#for (%$form_input) { 
for (keys(%$form_input)) { 
	$search{$_} = $form_input ->{$_};
	#print STDERR $_." -> ".$form_input ->{$_}."\n";
	}

if ($form_input ->{"useday"} == 1) {
	my $binday .= $form_input ->{"usesam"};
	$binday .= $form_input ->{"usefre"};
	$binday .= $form_input ->{"usedon"};
	$binday .= $form_input ->{"usemit"};
	$binday .= $form_input ->{"usedie"};
	$binday .= $form_input ->{"usemon"};
	$binday .= $form_input ->{"useson"};
	$search{day} = "-".oct("0b$binday");
}

$search{start} = $search{starth}.$search{startm};
$search{stop} = $search{stoph}.$search{stopm};

my $value = join(":",getSearch(%search));
print STDERR "Searchstring: ".$value."\n" if $debug;

push(@ul, doSearch($value));

buildul(@ul);

print "</body></html>" if $form_input ->{'window'} eq 'dialog';
}
elsif ($form_input ->{'change'} eq "epgsearch" ) {
my $para; my %h;

#if ($OPT{binmodetoutf8}) { for ($cgi->param()) { $h{$_} = encode("utf8", $cgi->param($_)) } }
#else { for ($cgi->param()) { $h{$_} = $cgi->param($_) } }
for (keys(%$form_input)) { $h{$_} = $form_input ->{$_} }

if ($form_input ->{"useday"} == 1) {
	my $binday .= $form_input ->{"usesam"};
	$binday .= $form_input ->{"usefre"};
	$binday .= $form_input ->{"usedon"};
	$binday .= $form_input ->{"usemit"};
	$binday .= $form_input ->{"usedie"};
	$binday .= $form_input ->{"usemon"};
	$binday .= $form_input ->{"useson"};
	$h{day} = "-".oct("0b$binday");
}

$h{start} = $h{starth}.$h{startm};
$h{stop} = $h{stoph}.$h{stopm};


$para = join(":",getSearch(%h));
#$para = encode("utf8", $para) if $OPT{binmodetoutf8};

my $type = $form_input ->{"type"};

print STDERR "epgTimer String $type : ".$para."\n" if $debug;
my $result = Receive("PLUG epgsearch $type $para");
$result =~ s/'/\\'/g;
$result =~ s/\r\n//g;
print STDERR "SVDRP Result: ".$result."\n" if $debug;

print qq< alert(\"$result\"); >;
}

quitSocket();
exit(0);
}

if (! defined($query[0]) || $query[0] eq "") { 				# kein Parameter, erstellt das Hauptmenue

do "main.pl";
warn "couldn't parse main.pl: $@" if $@;

quitSocket();
exit(0);
}
elsif ($query[0] eq "rc") { 				# Remotecontrol
	shift(@query);
	if ($query[0] eq "VOLU") { 
		Send("@query");
		Send("HITK VOLUME+");
		exit(0);
	}
	if ($query[0] eq "Channel") { $query[0] .= "+" }
		Send("HITK $query[0]");
		quitSocket();
	exit(0);
}
elsif ($query[0] eq "cmd") { 				# SVDRP-Tunnel
	shift(@query);
	#my @query = map uri_unescape($_), @query;
print STDERR join(" + ", @query)."\n" if $debug;	
	
	for (split(/\|/, join(" ",@query))) {
		if ($_ =~ /^killffmpeg/) {
			system('killall ffmpeg') == 0 
				or print "alert('Error while killing ffmpeg!');";
		}
		elsif ($_ =~ /^playdir(.*?) (.*?) (.*)/) { 
			my @files; my $pat = $1; $pat = "." unless $pat;
			for (decode_glob($3."/*")) { push(@files, $_) if $_ =~ /\.($pat)$/ }
			PlaylistHandler(createm3u(@files), $2);
		} else {
			Send($_);
		}
	}
	quitSocket();
	exit(0);
}
elsif ($query[0] eq "mpplay") {
shift(@query);
#dbgd(@query);
dbg($query[0]);
	my @cmds;
	my @a = ($mediaselect{MPLAYER}{play}) unless $mediaselect{MPLAYER}{play} =~ /ARRAY/;
	@a = @{$mediaselect{MPLAYER}{play}} unless @a;
	for (@a) {
	 push(@cmds, $mediaselect{_OPT_}{SCRIPTNAME}.$mediaselect{MPLAYER}{action}.$_);
	}
	if ($query[0] eq "CHAN") {
		$cmds[$#cmds] .= $OPT{vdr_streamdev}.$query[1] ;
	} elsif ($query[0] eq "REC") {
		my %rs = recordHash(Receive("LSTR"));
		my %r = getRecByID(\%rs, $query[1]);
		# ' werden nicht escaped, daher hat es bei vlc nicht gefunzt
		my @files = map { uri(chClientDir($_)) } bsd_glob($r{path}."/00*");
		$cmds[$#cmds] .= shift(@files);
		my @a = ($mediaselect{MPLAYER}{add}) unless $mediaselect{MPLAYER}{add} =~ /ARRAY/;
		@a = @{$mediaselect{MPLAYER}{add}} unless @a;
		for (@a) {
		 push(@cmds, $mediaselect{_OPT_}{SCRIPTNAME}.$mediaselect{MPLAYER}{action}.$_);
		}
		my $rep = $cmds[$#cmds];
		$cmds[$#cmds] .= shift(@files);
		for (@files) {
			push(@cmds, $rep.$_);
		}
	} elsif ($query[0] eq "FILE") {
		die("Unfinshed: ", @query);
	} else {
		die("Unkown: ", @query);
	}

	require LWP::Simple;
	for (@cmds) {
		#HTTP Handler
		dbg($_);
		my $contents = LWP::Simple::get($_);
	}
exit(0);
	
}
elsif (uc($query[0]) eq "REMOTE") {
my $vol = Receive("VOLU");
$vol =~ /250.*?(\d*)\r\n/;
our $actvolume = $1;
do "rc.pl";
warn "couldn't parse rc.pl: $@" if $@;
quitSocket();
exit(0);
}
elsif ($query[0] eq "actualdb"){

do "mediathek.pl";
warn "couldn't parse mediathek.pl: $@" if $@;

exit(0);

}
elsif ($query[0] eq "test"){
exit(0);
}
else { 										# Wenn unbekannter Parameter angegeben

do "vdrhandler.pl";
warn "couldn't parse vdrhandler.pl: $@" if $@;

quitSocket();
die "Unbekannter Parameter angegeben!\n";
}

quitSocket();
exit(0);

sub dbg {
print STDERR join("\n", @_),"\n";
}

sub dbgd {
print STDERR Dumper @_;
}

sub loadconfig {

#my $CONFIG = readFile($configfile);
my $no = $_[0] || 0; my $return=1;
#eval(readFile($configfile)) or die "Error while reading $configfile";
my $VAR1;
if (-e $configfile && ! -z $configfile) {
$VAR1 = retrieve $configfile or "";
}
unless ($VAR1) {
	warn "Error while loading $configfile!";
	return;
}
unless ($$VAR1[$no]) {
	warn "Configuration don't exist.\nLoading main-config";
	$return=0;
	$no=0;
}
@CONFSETS = @$VAR1;
%OPT=(%{$$VAR1[$no]});
return($return);
}

# MENU, MENUMOVE
sub getmenuorder() {
my @a = split(" ", $cgi->cookie(-name=>'IVDRMENUSORT'));
dbg($cgi->cookie(-name=>'IVDRMENUSORT'));
@a ? return @a : return @menusort;
}

# ------------------------------ LIRC ---------------------------

sub irsend { # �ergabe ref. LIRC Hashes
	my @cmds = @_;
	
	@cmds = @{$_[0]{makro}} if $_[0]{makro};
	# print STDERR $_[0]{makro} if $_[0]{makro};
	for (@cmds) {
	if ($$_{time}) {
	  system ("irsend SEND_START ".$$_{cmd});
	  print STDERR "irsend SEND_START ".$$_{cmd}."\n";
	  select(undef, undef, undef, $$_{time});
	  system ("irsend SEND_STOP ".$$_{cmd});
	  print STDERR "irsend SEND_STOP ".$$_{cmd}."\n";
	}
	else {
	  system ("irsend SEND_ONCE ".$$_{cmd});
	  print STDERR "irsend SEND_ONCE ".$$_{cmd}."\n";
	  }
	select(undef, undef, undef, $$_{pause}) if $$_{pause};
	}
}

# ------------------------------ HTML-Erzeugung ---------------------------

sub js { return("<script type='text/javascript'>".$_[0]."</script>") }

sub makehtml {	# Erwartet [food] gibt den HTML-Footer aus, andererseits den HTML-HEADER	 ARG0->Button link Arg1->Target Arg2->Title 	->STDOUT

if (lc($_[0]) eq "food") {
	
	do $mediaselect{_OPT_}{DIALOGFORM};
	warn "couldn't parse $mediaselect{_OPT_}{DIALOGFORM}: $@" if $@;
	print js("scrollTo(0,1)");
	print "</body></html>\n";
}
else {
#dbg("http://".$cgi->server_name().$weburl);
my $server = $cgi->server_name();

#<html manifest='$me?MANIFEST' xmlns='http://www.w3.org/1999/xhtml'>
print qq|<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>
<html xmlns='http://www.w3.org/1999/xhtml'>
<head><title>iVDR ($OPT{configname})</title>

<link rel='apple-touch-icon' href='http://$server/$weburl/icon.png' />
<link rel='shortcut icon' href='$weburl/favicon.ico' type='image/x-icon'>

<meta http-equiv='content-type' content='text/html; charset=$OPT{charset}'>
<meta name='viewport' content='width=device-width,minimum-scale=1.0,maximum-scale=1.0,user-scalable=no' />

<style type='text/css' media='screen'>\@import '$weburl/iui.css';</style>
<script type='application/x-javascript' src='$jscript'></script>
<script type='text/javascript'>|;

# <meta name='apple-mobile-web-app-capable' content='yes' />
# <link rel='apple-touch-icon-precomposed' href='http://$cgi->server_name()/$weburl/icon.png' />
# <link rel='apple-touch-startup-image' href='/iVDR/loadingipad.png' />

my @jswords = qw(ADD ALLFRMHER BEGIN CONVERT DELREC DELSEARCH DELTIMER DOSEARCH EDIT ENTERNAME HIDE INFO MARK MOVE
MULTIDELETE OFF ON OPEN PLAY PREFIX RECORD RECORDS REMOVE RENAME REPLAY RESUME RUN SAVE SCHED
STARTNOW STOPALL STREAM SWITCH TIMER);
for (@jswords) {
	print "var lp_".$_." = '".decode_entities($L{$_})."';";
}

#my @d; my $i;
#for (@usercontrol) { 
#	push(@d,"new button('".$$_{name}."', '".$me."?LIRC+ub+".$i."')") if $$_{cmd} || $$_{makro};
#	 if ($$_{svdrp}) { 
#		push(@d,"new button('".$$_{name}."', '".$me."?cmd+".$$_{svdrp}."')");
#	 }
#	$i++;
# }
#print "var usercontrol = new Array(".join(",", @d).");";

print "var recprefix = '".decode_entities($OPT{stddir})."';";
print "var sn = '".$mediaselect{_OPT_}{SCRIPTNAME}."';";
print "var ivdr = '".$me."';";
print "var www = '".$weburl."';";
print "var keyparam = '".$mediaselect{_OPT_}{KEYPARAM}."';";
print "var Slide = ",$OPT{slide} ? "true": "false",";" ;
print "var utf8 = ",$OPT{binmodetoutf8} ? "true": "false",";" ;
print "var mpplay =",$OPT{vdr_mpplay} ? "false": "true",";" ;
print "var stream =",$OPT{stream} ? "true": "false",";" ;
#if ($debug) {
#print qq|
#var webappCache = window.applicationCache;
#console.log("Cache status: " + webappCache.status);
#if (webappCache.status == 4) {
#  webappCache.update();
#  console.log("Updating the cache");
#  webappCache.swapCache();
#} else {
#  console.log("Nothing to do....");
#}
#|;
#}

print "</script>";
print qq|
<body id='mainbody'><div class="toolbar">
<div id='keyBar' ontouchstart='event.preventDefault();' ontouchmove='event.preventDefault(); if (remotewin) { if (! remotewin.closed) { remotewin.focus(); return; }}; remotewin=window.open("$me?REMOTE","_remote_control");'></div>
<div id='dlg_wait'><img src='$weburl/loading2.gif'></div>
<h1 id="pageTitle" onClick='location.hash = "#_main"; deleteHistory();'></h1>
<font id='backicon' color=white style='left:48%; position:absolute; top:0px; line-height:80px; text-align: center; display:none;'>&#8630;</font>
<img id='activemedia' src='$weburl/activemedia.png' style='z-index:2; left:80px; position:absolute; top:0px; height:32px; width:32px; margin:6px; display:none;' />
<a id="backButton" class="button" href="#"></a>
<!--<div style="display:block; position:absolute; right: 10px; top:50px;">Hallo</div>-->|;
#8404
# location.hash = "#_main"; deleteHistory();location.hash = "#_main"; deleteHistory();
#<h1 id="pageTitle" onClick='location.hash = "#_main"; deleteHistory();location.hash = "#_main"; deleteHistory();'></h1>

print "<a id='rightButton' class='button blueHeadButton' href='$_[0]' target='$_[1]'>$_[2]</a>" if $_[2];
print "</div>";
}	
}

# sub showDialog { # baut ein dialogfeld auf, ARG0->Head, ARG1->Titel, ARG2->Text Text in HTML-Form m�lich!, [ARG3]	->selected [ARG4]->closebutton	ARG5 close fieldset->STDOUT
# print $_[0];
# print closeButton() if $_[4]; 
# print "<div id='frmdialog' title='".$_[0]."' class='panel' selected='true'>\n";
# print "	<h2>$_[1]</h2><fieldset><div align='left' style='padding:20px;'>\n";
# print "$_[2]\n";
# print "  </div>";
# my $ad = qq(
# <script type="text/javascript"><!--
# google_ad_client = "pub-2871447268512752";
# /* 250x250, Erstellt 02.05.09 */
# google_ad_slot = "2820630656";
# google_ad_width = 250;
# google_ad_height = 250;
# //-->
# </script>
# <script type="text/javascript"
# src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
# </script>
# );
# print "</fieldset></div>\n" if !$_[5];
#
# }

sub buildul { # baut die html Aufz�lung auf, Arg0->ID Arg1->Title, Arg2->selected[true,false] , ab Arg3 link, target, title	# sind ersten 3 leer wird kein ul gebaut nur li		->STDOUT
my @ul = @_;
my $id = shift(@ul);
my $ti = shift(@ul);
my $ta = shift(@ul);
my $it;

#<li class="group">Z</li>
for (my $i = 0; $i < @ul; $i++) {
	if ($ul[$i+1] eq "_iui") {
		$it .= "<li><a href='$ul[$i]'>".$ul[++$i+1]."</a></li>";
		++$i;
	}
	elsif ($ul[$i+1] eq "_no") {
		$it .= "<li>$ul[++$i+1]</li>";
		++$i;	
	}
	elsif ($ul[$i+1] eq "_group") {
		$it .= "<li class='group'>$ul[++$i+1]</li>";
		++$i;	
	}
	elsif ($ul[$i+1] eq "_special") {
		$it .= "$ul[++$i+1]";
		++$i;	
	}
	else {
		$it .= "<li><a href='$ul[$i]' target='$ul[++$i]'>$ul[++$i]</a></li>";
	}
}	

if ($id ne "" || $ti ne "" || $ta ne "") {
	$it = "<ul id='".$id."' title='".$ti."' selected='".$ta."'>".$it."</ul>";
}
# <div id='navBar' style='position:absolute; right:0px; top:0px; width:20px; height:100%;'></div>
# !!!!!!!!!!! als navBar auf der rechten Seite
#print STDERR $it."\n";
print $it;
}

# ------------------------------ Dateizugriff ---------------------------

sub readFile { # Liest die Datei Arg1 in einen String zur Komplettverarbeitung			-> STRING				..-->> veraltet <<--..
	open(FILE,$_[0]) or die "Kann Datei nicht lesen: $! $_[0]\n"; my $epg = join("", <FILE>); close(FILE);
return $epg;
}

sub fileArray { # Liest die Datei Arg1 in einen Array	zur zeilenweise Bearbeitung		-> ARRAY
	unless (-e $_[0]) {
		warn "$_[0] doesn't exist!";
		return();
	}
	my @epg;
	open(FILE,$_[0]) or die "Can't open file: $_[0] $!\n"; while(defined(my $line = <FILE>)) {
		chomp($line);
		if ($OPT{binmodetoutf8}) { 
			push(@epg, decode("utf-8", $line)) }
		else { push(@epg, $line) }
	} close(FILE);
	return @epg;
}

sub getfile { # dir, file
return unless -d $_[0];
return(grep (/$_[1]$/i,decode_glob($_[0]."/*")));
}	

sub decode_glob {
	if ($OPT{binmodetoutf8}) { map { decode("utf-8", $_) } bsd_glob($_[0]) }
	else { bsd_glob($_[0]) }
}

# ------------------------------ Zeit Subs ---------------------------

sub timediff { # Gibt die Tage Stunden und Minuten zurck, Arg0 Sekunden, Arg1 negativer zeiger, Arg2 positiver zeiger,  Arg3 -> min|std|day, Arg4 -> Alttext, Arg5 -> 0 Text
my $a; my $s; my $m; my $h; my $d;
if (! $_[3]) {
	$a = abs($_[0]);
	$s = $a % 60;
	$m = ($a -= $s) / 60 % 60;
	$h = ($a -= $m * 60) / 3600 % 24;
	$d = ($a -= $h * 3600) / 86400;
}
elsif ($_[3] eq "min") { $m = int(abs($_[0]) / 60) }
elsif ($_[3] eq "std") { $h = int(abs($_[0]) / 3600) }
elsif ($_[3] eq "day") { $d = int(abs($_[0]) / 86400) }

$a = abs($_[0])==$_[0] ? "$_[1]" : "$_[2]";
if (! $_[4]) 
{
	if ($d) { if ($d > 1) { $a .= " $d ".$L{DAYS} } else { $a .= " $d ".$L{DAY} } }
	if ($h) { if ($h > 1) { $a .= " $h ".$L{HOURS} } else { $a .= " $h ".$L{HOUR} } }
	if ($m) { if ($m > 1) { $a .= " $m ".$L{MINUTES}} else { $a .= " $m ".$L{MINUTE} } }
}
else { $a .= " $d$h$m$_[4]" }

if (! $d &! $h &! $m) { $a = $_[5] || $L{NOW} }
return($a);
}

sub fdate { # Formatiert ein Datum/Zeit, Arg0->Zeit im UDC Format, Arg1-> Format, [optional ARG2->Absolute]
	my ($Sekunden, $Minuten, $Stunden, $Monatstag, $Monat, $Jahr, $Wochentag, $Jahrestag, $Sommerzeit) = localtime(abs($_[0]));
	if (! defined($_[2]) || ! $_[2]) { $Monat++; $Jahrestag++; $Jahr+=1900; }
	my @Wochentage = ($L{SUN}, $L{MON}, $L{THU}, $L{WED}, $L{TUR}, $L{FRI}, $L{SAT});
	my @Monatsnamen = ($L{JAN}, $L{FEB}, $L{MAR}, $L{APR}, $L{MAY}, $L{JUN}, $L{JUL}, $L{AUG}, $L{SEP}, $L{OCT}, $L{NOV}, $L{DEC});
	
	my $tmp; my $date = $_[1]; 
	my $enstd = $Stunden > 12 ? $Stunden - 12 : $Stunden;
	$enstd = 12 if $Stunden == 0;
	
	my %def = ("#d#" => $Monatstag
		,"#dd#" => $Monatstag < 10 ? $Monatstag = "0".$Monatstag : $Monatstag
		,"#ddd#" => substr($Wochentage[$Wochentag], 0, 3)
		,"#dddd#" => $Wochentage[$Wochentag]
		,"#dw#" => $Wochentag
		,"#dy#" => $Jahrestag	
		,"#m#" => $Monat
		,"#mm#" => $Monat < 10 ? $Monat = "0".$Monat : $Monat
		,"#mmm#" => substr($Monatsnamen[$Monat-1], 0, 3)
		,"#mmmm#" => $Monatsnamen[$Monat-1]
		,"#y#" => $Jahr		
		,"#yy#" => substr($Jahr, 2)
		,"#S#" => $Sekunden
		,"#M#" => $Minuten
		,"#H#" => $Stunden
		,"#h#" => $enstd
		,"#SS#" => $Sekunden < 10 ? "0".$Sekunden : $Sekunden
		,"#MM#" => $Minuten < 10 ? "0".$Minuten : $Minuten
		,"#HH#" => $Stunden < 10 ? "0".$Stunden : $Stunden
		,"#hh#" => $enstd < 10 ? "0".$enstd : $enstd
		,"#ampm#" => $Stunden >= 12 ? "pm" : "am"
		);
	foreach (keys(%def)) { while ($date =~ /$_/g) { $date = "$`$def{$_}$'" } }
	return($date);
}

sub yes { my $lon = lc($L{ON}); my $lyes = lc($L{YES}); return 1 if lc($_[0]) =~ /yes|ja|1|on|ein|${lon}|${lyes}/ }
sub no { my $loff = lc($L{OFF}); my $lno = lc($L{NO}); return 1 if lc($_[0]) =~ /no|nein|0|off|aus|${loff}|${lno}/ }

sub uri {
my $tag;
if ($OPT{binmodetoutf8}) { $tag=uri_escape_utf8($_[0]) }
else { $tag=uri_escape($_[0]) }
#$_[0] =~ s/'/%27/g;
return $tag;
}

sub escapeQw {
	my $qw = qq(\\\\|'|");
	(my $_tmp = $_[0]) =~ s/$qw/\\$&/g;
	return($_tmp);
}

sub createm3u {
	my $m3u = $tempdir."/tempplaylist.m3u";
	open(TMP, "> ".$m3u) or die "Can't access Tempdir\n";
	
	my $action = $dbmusic{play};
	$action = [$action] unless ref $action;
	
	my $prefix = "../.." if join("",@$action) =~ /plug\+mp3\+/;
	
	for (@_) {
		print TMP $prefix.chClientDir($_)."\n"; #!!!! eigentlich fr ../ fr jedes verzeichnis das tempdir von root weg ist.
	}
	close TMP;
	if (-e $m3u &! -z $m3u) {
		return($m3u) 
	} else {
		return(0)
	}
}

sub getStars {
	my $rate=$_[0];
	my $stars=0;
	return(0) unless $rate;
	if ($rate=~/^\d/ ) { # if ($_ =~ /^\d/) {
		$stars = (255 == $rate)*5 || $rate<= 5 && $rate || $rate && int($rate/64) + 1;
	} else {
		(my $test = $_) =~ s/\-//g;
		$stars = length($test);
	}
	return($stars);
}

sub PlaylistHandler { # 0: Playlist, 1: type (add, play)
	my $tmplist = $_[0];
#$tmplist = "http://".$ENV{SERVER_ADDR}.$me."?media=playlist.m3u";
	my $action = $dbmusic{$_[1]};
	$action = [$action] unless ref $action;
	if ($dbmusic{action} eq "cmd+") {
		#SVDRP Handler
		require svdrp;
		establishSocket(); 

		my $i;
		for (@$action) {
			$i++;
			(my $_tmp = $_) =~ s/\+/ /g;
			#dbg($_tmp.($i eq @$action ? " ".$tmplist : ""));
Send($_tmp.($i eq @$action ? " ".$tmplist : ""));
			select(undef,undef,undef,.3);
		}
	} else {
		shift(@query);
		#HTTP Handler
		# require HTTP::Request;
		#my $request = HTTP::Request->new(GET => $mediaselect{_OPT_}{SCRIPTNAME}.$dbmusic{action}.);
		require LWP::Simple;
		my $i;
		for (@$action) {
			$i++;
			print STDERR $mediaselect{_OPT_}{SCRIPTNAME}.$dbmusic{action}.$_.($i eq @$action ? uri($tmplist) : ""),"\n";			             
dbg(LWP::Simple::get($mediaselect{_OPT_}{SCRIPTNAME}.$dbmusic{action}.$_.($i eq @$action ? uri($tmplist) : "")));
			#print "SimpleHttpRequest('".$mediaselect{_OPT_}{SCRIPTNAME}.$dbmusic{action}.$_.($i eq @$action ? $tmplist : "")."');";
		}
	}
}	
			
sub chClientDir { # wenn ref von string bergeben wird, wird dieser ge�dert ansonsten gibt er den ge�derten string zurck
	return($_[0]) unless $OPT{clientdir}[0] && $OPT{serverdir}[0];
	my $_temp = $_[0];
	for (my $i; $i < @{$OPT{serverdir}}; $i++) {
			last if $_temp =~ s/^$OPT{serverdir}[$i]/$OPT{clientdir}[$i]/;
	}
	return($_temp);
}
sub chServerDir { # wenn ref von string bergeben wird, wird dieser ge�dert ansonsten gibt er den ge�derten string zurck
	return($_[0]) unless $OPT{clientdir}[0] && $OPT{serverdir}[0];
	my $_temp = $_[0];
	for (my $i; $i < @{$OPT{serverdir}}; $i++) {
			last if $_temp =~ s/^$OPT{clientdir}[$i]/$OPT{serverdir}[$i]/;
	}
	return($_temp);
}
		
sub dec2bin { # Dezimal zu bin�, sollte rckw�ts ausgelesen werden um aufw�tskompatibel zu sein. len - pos
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}

sub bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}
