#!/usr/bin/perl

use strict; #!!!!!!!!! deaktiviert um ivdr.pl parsen zu können
use CGI;
#use Encode;
use File::Basename;
use Time::Local;
#use Socket;	
#use HTML::Entities;
#use URI::Escape;
use File::Glob ':glob';
use Getopt::Long;
use MP3::Tag;
use Storable;
#use Storable qw(nstore store_fd nstore_fd);

use Data::Dumper;
use Benchmark ':hireswallclock';

umask 0;

my $t0 = new Benchmark;
my $bnread;
my $bnhandle;
my $bnexecute; 


use vars qw( %opt );
			
die usage() if (!GetOptions(
	\%opt, "c", "create", "u", "update", "noclean",
	"p", "h", "i",
	"f=s", "file=s", "dir=s@",
	"put","data=s%",
	"get","group=s","filter=s%", "filter2=s%", "numeric=s%", "id=i@", "and",
	"pic=i", 
	) || $opt{h});

	#wenn die hash keys gleich sind, wird nur das letzte genommen;;;;;
	
my $datenbank = ($opt{f} || $opt{file} || "media.db");
my $debug = 1;


if ($opt{create} || $opt{c} || $opt{update} || $opt{u}) {
#--------------------------- BEGIN ------------------
my $ds = ($opt{dir} || ["/"]);
my @dirs = @$ds;
print STDERR "Using these Directories:\n", join("\n",@dirs),"\n";

if (-e $datenbank && ($opt{create} || $opt{c}) && ! -z $datenbank) {
	die ("Datenbank bereits vorhanden!\nVersuch Parameter --update");
}

unless (open (DATA, ">> $datenbank") && -w $datenbank) {
	die ("Error open Database!");
}
close(DATA);

my %files;
my @filearr;
my $i;
my $starttime = time;

my @pics; my @picn;

for my $dir (@dirs) {
unless (-d $dir && -e $dir) {
	print STDERR "Achtung $dir ist kein Verzeichnis oder existiert nicht. Überspringe.\n";
	next;
}
if ( -l $dir ) {
	print STDERR "Ignoriere symlink $dir";
	next;
}
	$dir .= "/" unless $dir =~ /\/$/;
	my @inner = bsd_glob($dir."*");
	for (@inner) {
		if ($_ =~ /\.mp3$/ && ! $files{$_}) { # nicht schon in %files und .mp3 Endung
			my %h;
			push(@filearr, \%h);
			$h{FILENAME}=basename($_);
			$h{DIR}=$dir;
			$files{$_}=\%h;
			my $mp3 = MP3::Tag->new($_);
			$mp3->get_tags(); 
			if (exists $mp3->{ID3v1}) { 
					$h{TAG}="ID3v1"; 
					#($title, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo(); 
					#$mp3->genres($genreID); 
					($h{IDS}{TIT2}, $h{IDS}{TRCK}, $h{IDS}{TPE1}, $h{IDS}{TALB}, $h{IDS}{TCOM}, $h{IDS}{TYER}, $h{IDS}{TCON}) = $mp3->autoinfo();
			} 
			
			if (exists $mp3->{ID3v2}) { 
				$h{TAG}="ID3v2"; 
				my $frameIDs_hash = $mp3->{ID3v2}->get_frame_ids('truename'); 
				#$h{IDS} = $frameIDs_hash; 
					
				map { $h{IDS}{$_} = $mp3->{ID3v2}->get_frame($_) } keys %{$frameIDs_hash}; 
			} 

			if ($h{IDS}{APIC}) { # Schaue ob es das bild schon gibt, wenn neu dann schreibe in picn
				my $d=0;
				#print STDERR length($h{IDS}{APIC}{_Data});
				#print Dumper $h{IDS}{APIC}{_Data};
				for (@pics)	{
					last if ($h{IDS}{APIC}{_Data} eq $pics[$d]);
					$d++;
				}
				if ($d >= scalar(@pics)) {
					push(@pics, $h{IDS}{APIC}{_Data});
					push(@picn, $_);
				}
				$h{IDS}{APIC}=$d;
			}
			
			# unless (exists $mp3->{ID3v1} || exists $mp3->{ID3v2}) { 
				# #print "No Tag found: $_\n" if $debug; 
				# #print Dumper $mp3; 
			# }

			$h{IDS}{TIT2} = $h{FILENAME} unless $h{IDS}{TIT2};
			$h{ID} = $i++; 
			#($h{IDS}{TIT2}, $h{IDS}{TRCK}, $h{IDS}{TPE1}, $h{IDS}{TALB}, $h{IDS}{TCOM}, $h{IDS}{TYER}, $h{IDS}{TCON}) = $mp3->autoinfo();
			
			# II alle daten die nur von mdb geschrieben und verwendet werden 
			$h{II}{ADD} = $starttime; # datum in datenbank aufgenommen 
			$h{II}{exist}=1;
			#$h{II}{CHANGE};        # wenn datenbank eintrag geändert wurde aber nicht in tag geschrieben wurde
									# enthält array mit den geänderten hashindexes 
									# [ {'{IDS}{TIT2}' => 'Title 01'}, ... ]
			# merken 
			#$h{II}{SKIP};          # anzahl übersprungen wenn vor 50% übersprungen wurde 
			#$h{II}{NOGO}			# geht gar nicht
			#{IDS}{TBPM} 
			#{IDS}{POPM}{Rating} 		# Bewertung 0-255  0=0  1>=1(20)  2>=64(40)  3>=128(60)  4>=196(80)  5=255(100)
			#{IDS}{POPM}{Counter} 		# Abgespielt
			print STDERR $i."\r"; 
		}
		push(@dirs, $_) if -d $_;
	}
}

if ($opt{update} || $opt{u}) {
	
	my %data = getData('group'=>'{DIR}.$$_{FILENAME}');

	# TODO:
	# umgekerte suche suche in allen datenbank einträgen ob daten nicht mehr in neuen datenbank oder festplatte ist
			# schaue ob die datei wo anders ist,
			# suche nach dateinamen
			# wenn gefunden 
			# 	und datei nicht doppel vorhanden
			# 	und IDS gleich, TIT2, TPE1
			#	übernehme ivdr (II) hash  ok
	my $changed;
	for my $key (keys %data) {
		$data{$key}[0]{II}{exist}=0;
		print Dumper $data{$key}[0] if exists $data{$key}[0]{II}{CHANGE};
		if (modifyFile($data{$key}[0])) {
		delete $data{$key}[0]{II}{CHANGE};
		$changed++;
		}
	}
	
	my $d=scalar(keys(%data)); my $added; my $new;
	for my $new (@filearr) {
		if ($data{$$new{DIR}.$$new{FILENAME}}) {
			my $curr = \$data{$$new{DIR}.$$new{FILENAME}}[0];
			$$$curr{II}{exist}=1;
			#print STDERR Dumper $$new{IDS}; # Neue Daten
			#print STDERR Dumper $$curr{IDS}; # Gespeicherte INFOS

			#if ($$curr{CHANGED}) { # wenn die daten über ivdr geändert wurden
				#print Dumper $$$curr{IDS};
				#print Dumper $$new{IDS};
				$$$curr{IDS} = $$new{IDS}; #!!!! funktioniert referenz?
				# schaue alle keys nach ob vorhanden wenn nicht vorhanden nimm den neuen, falls neue hinzukommen bei neuerer version
				$changed++;
			#}
			# wenn die daten extern geändert wurden
			# paramter 
			
#			unless ($$curr{CHANGED}) { #????
#				print STDERR "Gleich!";
#				$$new{IDS} = $$curr{IDS};
#			} else {
#				print STDERR "nicht Gleich!";
#			}
#			exit(0);

		} else {
			#print STDERR $$new{FILENAME}," added!\n" if $debug;
			$added++;
			# füge datensatz hinzu
			$$new{ID} = $d++;
			$data{$$new{DIR}.$$new{FILENAME}}[0] = $new;
		}
	}

unless ($opt{noclean}) {
	for my $old (keys %data) {
		unless ($data{$old}[0]{II}{exist}) {
			print $data{$old}[0]{DIR}.$data{$old}[0]{FILENAME}." does not exist. Delete now.\n";
			delete $data{$old};
		} else {
			delete $data{$old}[0]{II}{exist}
		}
	}
}
	
if ($changed || $added) {
	print "Writing Database!\n";
	print "$added added!\n" if $added;
	#print "$changed changed!\n" if $changed;
	writeDB( map {$data{$_}[0]} keys %data ); 
	store \@picn, "images.".$datenbank;
} else {
	print "No change. Do nothing!\n";
}
exit(0);
}

writeDB(@filearr);
store \@picn, "images.".$datenbank;
}

#------------------------------------------------------------------------------------------------
#--------------------------------- ENDE FÜLLEN ANFANG AUSLESEN ----------------------------------
#------------------------------------------------------------------------------------------------

if (defined($opt{i})) {

print STDERR $opt{i},"\n" if $debug;

#my %h = getData();
#for (keys %h) {
#print $h{$_}[0]{DIR}.$h{$_}[0]{FILENAME}."\n".$h{$_}[1]{DIR}.$h{$_}[1]{FILENAME}." -- ".$_." -> ".@{$h{$_}}."\n" if @{$h{$_}} > 1;
#}

my %type = getData("{IDS}{TPE1}", $opt{i});
for (keys %type) { 
	print STDERR $_," (",scalar(@{$type{$_}}),")\n" if $debug; 
}
}

if ($opt{p}) {

my %type = getData(
	  'group' => '{DIR}',
	  'filter' => {
					'{DIR}' => '/mnt/media/music/actual/Rihanna-Rated_R-2009-DOH/'
				  }
);

 map { print STDERR $_," (",scalar(@{$type{$_}}),")\n"; } keys %type;


#print Dumper($d{'/mnt/media/music/actual//Jay-Z-The_Blueprint_3-2009-H3X/06-jay-z-real_as_it_gets_(featuring_young_jeezy).mp3'})."\n";
#exit(0);

#while (my ($k, $v) = each %files)
#  { print "$k -> $v\n";
#	for (keys($v)) { print $_."\n"};
#  }

#print Dumper(%files);
#untie %files;
#exit(0);
#my %test;
#tie %test, "DB_File", "media.db", O_RDWR|O_CREAT, 0640, $DB_HASH or die "Cannot open file 'media.db': $!\n";

#print Dumper(%test);
#untie %test;

}

if (defined($opt{get})) {


my %data = getData(%opt);
print Dumper \%data;
#nstore_fd \%data, \*STDOUT;

#my %type = getData($opt{search});
#for (keys %type) { 
#	print STDERR $_," (",scalar(@{$type{$_}}),")\n" if $debug; 
#}

}

if (defined($opt{pic})) {

	my $VAR1 = retrieve "images.".$datenbank;
	my $mp3 = MP3::Tag->new($$VAR1[$opt{pic}]);
	$mp3->get_tags(); 
	print $mp3->{ID3v2}->get_frame('APIC')->{'_Data'};

}

if (defined($opt{put})) {
	die ("Keine Daten zum hinzufügen. Parameter data notwendig") unless defined($opt{data});
	
	#$para{group} = "{ID}"; # vermeiden das der Gruppen Array geschrieben wird.
	# NUR MIT ID (EINE) MOMENTAN MÖGLICH
	my %data = getData();
	for (keys %{$opt{data}})
	{
		unless ($_ eq "{FILENAME}" or $_ eq "{DIR}") { # Datenbankeinträge korregieren unabhängig von TAG
			print STDERR '$data{$opt{id}[0]}[0]'.$_."='".$opt{data}{$_}."'","\n" if $debug;
			eval('$data{$opt{id}[0]}[0] '.$_."='".$opt{data}{$_}."'");
		}
	};
	#map { $data{$opt{id}[0]}[0]{II}{CHANGE}{$_}=$opt{data}{$_} } keys %{$opt{data}};# unless writeData($data{$opt{id}[0]}[0], $opt{data}); # wenn nicht geschrieben werden konnte
	print STDERR modifyFile($data{$opt{id}[0]}[0], $opt{data});
	#print STDERR Dumper $data{$opt{id}[0]}[0];

	writeDB( map {$data{$_}[0]} keys %data );
	
}

my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print STDERR "the read code took:",timestr($bnread),"\n";
print STDERR "the handle code took:",timestr($bnhandle),"\n";
print STDERR "the execute code took:",timestr($bnexecute ),"\n";
print STDERR "the whole code took:",timestr($td),"\n";


sub getData { 
my %para = @_; 
$para{group} = "{ID}" unless(defined($para{group})); 
my $operator = "||";
$operator = "&& " if($para{and}); # achtung wenn or dann wird bei suche die vorrangikeit || vor and nicht mehr eingehalten
#$para = { 
#          'group' => '{ID}', 
#          'filter' => { 
#                        '{IDS}{TIT2}' => 'g4l', 
#                        '{DIR}' => '/mnt/media/music/actual/Rihanna-Rated_R-2009-DOH/' 
#                      }, 
#        }; 


my $bn0 = new Benchmark;
my $VAR1 = (retrieve $datenbank)->[0];

my $bn1 = new Benchmark;
$bnread = timediff($bn1, $bn0);

$bn0 = new Benchmark;
my @rr;
if (defined($para{id})) { 		# wenn ids seperiert werden sollen
	my %h;
	for (@$VAR1) { $h{$$_{ID}} = \$_ } 	# schreibe einen hash mit den ids
	for (@{$para{id}}) {				# pushe die ids !!!!!!! evtl über map schneller
		push(@rr, ${$h{$_}});
	}
} else { @rr = @$VAR1 }			# andernfalls schreibe alle rein

my @filter; 
for (keys %{$para{filter}} ) { 
 $para{filter}{$_} =~ s/\//\\\//g;              # / in suchstring durch \/ ersetzen 
 $para{filter}{$_} =~ s/(\(|\))/\\\1/g;         # () in \(\) ersetzen
	# !!!!!!! regexpr müssen gebackslashed werden 
    # !!!!!!! Sonderzeichen und \s durch . oder .* ersetzen je nach bedarf oder duchmethode
 push(@filter, '$$_'.$_.' =~ /'.$para{filter}{$_}.'/i'); 
} 

my @filter2; 
for (keys %{$para{filter2}} ) { 
 $para{filter2}{$_} =~ s/\//\\\//g;              # / in suchstring durch \/ ersetzen 
 $para{filter2}{$_} =~ s/(\(|\))/\\\1/g;         # () in \(\) ersetzen
	# !!!!!!! regexpr müssen gebackslashed werden 
    # !!!!!!! Sonderzeichen und \s durch . oder .* ersetzen je nach bedarf oder duchmethode
 push(@filter2, '$$_'.$_.' =~ /'.$para{filter2}{$_}.'/i'); 
} 
#print STDERR Dumper @filter;
#print STDERR Dumper @filter2;
my @numeric; 
for (keys %{$para{numeric}} ) { 
 #$para{filter}{$_} =~ s/\//\\\//g;              # / in suchstring durch \/ ersetzen 
 push(@numeric, '$$_'.$_.' '.$para{numeric}{$_}); 
} 


my %result; 
# !!!!! wenn keine gruppe dann push ohne eval; ggf %h nehmen falls keine weiteren bedingungen

#my $code = 'push(@{$result{$$_'.$para{group}.'}}, \%$_) '.(@filter ? 'if '.join(" && ", @filter) : ''); 
my $code;

$code = 'push(@{$result{$$_'.$para{group}.'}}, \%$_) ';

# evtl. übersichtlicher wenn einzelzeiten
$code .= (@filter || @numeric ? 'if ' : "").
(@filter ? join(" ".$operator." ", @filter) : " ").
(@filter2 ? " and ".join(" ".$operator." ", @filter2) : "").
(@filter && @numeric ? ' and ' : "").
(@numeric ? join(" ".$operator." ", @numeric) : " "); 

$bn1 = new Benchmark;
$bnhandle = timediff($bn1, $bn0);


print STDERR $code."\n" if $debug;
#map { eval($code) } @arr; 
$bn0 = new Benchmark;
for (@rr) { eval($code) } 
#for (@rr) { push(@{$result{$$_{ID}}}, \%$_)};
$bn1 = new Benchmark;
$bnexecute = timediff($bn1, $bn0);


return(%result); 
} 

sub writeDB {
# Datenbank schreiben, array mit allen hash elementen

store [\@_], $datenbank;

}

sub modifyFile { # 0. FILEELEMENT 1. CHANGESHASH
	my $h = shift || return(0);
	my $ch = shift || $$h{II}{CHANGE} || return(0);
	
	print STDERR $$h{DIR}.$$h{FILENAME}."\n";
	unless (-w $$h{DIR}.$$h{FILENAME} && -w $$h{DIR}) {
		for (keys %$ch) {
			$$h{II}{CHANGE}{$_} = $$ch{$_}; # schreibe CHANGE wenn fehler;
		}
		print STDERR "Datei wurden nicht geschrieben! Starten sie mdb.pl --update mit schreibrechten!\n";
		return(0);
	}	
	
	#print STDERR Dumper $h;
	#print STDERR Dumper $ch;
	my $mp3 = MP3::Tag->new($$h{DIR}.$$h{FILENAME});
	$mp3->get_tags();

	for (keys %$ch) {
		print STDERR $_,"\n" if $debug;
		if ($_ =~ /^{IDS}/) {
			$_ =~ /{IDS}{(.*?)}{(.*?)}/;
			
			my $fname = $1;
			my $refname = $2;
			
			print STDERR "Ändere mp3 Tag!\n" if $debug;
			#print STDERR Dumper $h{II};
			
			$mp3->new_tag("ID3v2") unless exists $mp3->{ID3v2}; # konvertiere gleich v1 zu v2

			my $info = $mp3->{ID3v2}->get_frame($fname) ||
			$mp3->{ID3v2}->get_frame($mp3->{ID3v2}->add_frame($fname));
			
			#print STDERR "Vorher:", Dumper $info if $debug;
			#print STDERR $$info{URL},"\n";;
			
			if (ref $info) {
				(my @data, my $res_inp) = $mp3->{ID3v2}->what_data($fname); #für die reihenfolge des datenfeldes
				$$info{$refname} = $$ch{$_};
				$mp3->{ID3v2}->change_frame($fname, map { $$info{$_} } @{$data[0]}); 
				#$mp3->{ID3v2}->change_frame("POPM", ('iVDR', 5))
				#$mp3->{ID3v2}->change_frame($fname, ("TEST",1,2));
			} elsif ($info) { # wenn nur ein string besteht
				$mp3->{ID3v2}->change_frame($fname, $$ch{$_}); # !!!!!!!!!!!!!!untestet
			} else {
				#$fn = $id3v2->add_frame($fname, @data);
				print STDERR "Error while writing TAG: $fname, $refname\n";
			}
			#print STDERR "Nachher:", Dumper $mp3->{ID3v2}->get_frame($fname) if $debug;

		} elsif ($_ =~ /^{FILENAME}||^{DIR}/) {
			print STDERR "Verschiebe!\n" if $debug;
			# keine funktion. sollte am ende nach tag schreiben erfolgen
		} else {
			print STDERR "Unkown Handleing: $_ \n" if $debug;
		}
		#delete $$h{II}{CHANGE}{$_}; # entferne entsprechenden CHANGE TAG 
		#$$h{II}{CHANGE}{$_} = $$ch{$_}; # schreibe CHANGE wenn fehler;
	}
	delete $$h{II}{CHANGE} unless keys %{$$h{II}{CHANGE}};
	
	print STDERR "Schreibe mp3Tag in Datei\n" if $debug;
	my $tagwritten = $mp3->{ID3v2}->write_tag();

	#my $fileisrenamed;
	#unless ($fileisrenamed) {
	#   #renamechangetags neu schreiben wvtl.
	#	return(0);
	#}
	print "Something went wrong: $!\n" unless $tagwritten;
	print STDERR Dumper $tagwritten if $debug;
	return($tagwritten);
}

sub usage {
# die usage() if (!GetOptions(
	# \%opt, "c", "create", "u", "update", "noclean",
	# "p", "h", "i",
	# "f=s", "file=s", "dir=s@",
	# "put","data=s%",
	# "get","group=s","filter=s%", "filter2=s%", "numeric=s%", "id=i@", "and",
	# "pic=i", 
	# ) || $opt{h});
print STDERR << "EOF";
	This program creates database of your mp3 files.
	usage: $0 [-hcu] [-f|--file=file] [--dir=dir [--dir=dir]] [--put --data=IDS] [--get] [--pic=id]
	-h                  : this (help) message
	--create -c         : Create DataBase
	--update -u         : Update DataBase
	--noclean           : Don't delete files not found
	--file=file -f      : use file as database
	--dir=directory     : use directories instead of /

	--get               : Print Database Hash
	--group=TYPE        : Hash index. Default: {ID}
	--filter
	    TYPE=string     : Filteroptions, no same TYPES possible, if nessecary seperate with \|

	--and               : and instead of or
	--filter2 
	    TYPE=string     : ANDs Filter

	--numeric
	    TYPE=operand    : eq, ne, gt, lt, ge, le

	--id=DBID           : Specifie a ID	
		
	TYPE ist der Hash zeiger der verwendet werden soll. Immer in geschweiften klammern angeben. {TYPE}
	    {ID}            : Unique Database ID
	    {DIR}           : Verzeichnis
	    {FILENAME}      : Dateiname
	    {IDS}{TAGID}    : mp3v2 Tag ID
	    {II}{TYPE}      : Informationen über Datenbankeinträge
	
	example: $0 --get --filter='{IDS}{TIT2}=Michael Jackson'

	
EOF

exit;
}