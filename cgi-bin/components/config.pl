require htmlelement;
$configmenu = $files."config.xml";

if ($form_input ->{'confighandler'} eq "save" ) { #zeigt die bergebenen Parameter an

errorout("Error: ivdr.db is not writeabele!") unless -w $configfile;
my $partial;
if (exists $form_input ->{'savepartial'} ) {
	dbg("Partial saveing");
	$partial=1;
	delete $form_input ->{'savepartial'};
	delete $form_input ->{'configname'};
	delete $form_input ->{'configid'};
}

#my $config = getconfigstruct();
my %requiredvar = getconfigstruct("required");
my %attribedvar = getconfigstruct("attrib");
my %regexpedvar = getconfigstruct("regexp");
my $info;

# checke ob ben?igte variablen nicht leer ist, ansonsten nimm default oder brich ab
my $err;


for (keys(%requiredvar)) {
# nicht wenn partial und die variable nicht existiert
	next if ($partial && ! exists $$form_input{$requiredvar{$_}{name}});
	unless ($$form_input{$requiredvar{$_}{name}}) {
		if ($requiredvar{$_}{default}) {
			dbg("Default set: ".$requiredvar{$_}{name}." - ".$requiredvar{$_}{default});
			$info .= "Set default: ".$requiredvar{$_}{title}." = ".$requiredvar{$_}{default}."\\n";
			$$form_input{$requiredvar{$_}{name}} = $requiredvar{$_}{default};
		} else { 
			$err .= "Field is required: $requiredvar{$_}{title} ($requiredvar{$_}{name})\\n" if $$form_input{$requiredvar{$_}{required}} || $requiredvar{$_}{required} == 1; 
			}
	}
}


# bearbeite attribut check und regexp check
for (keys(%attribedvar)) {
	next unless $form_input->{$_};
	my @a = $form_input->{$_} =~ /^ARRAY/ ? @{$form_input->{$_}} : ($form_input->{$_});
	for my $attrib (@a) {
		eval("\$info .= '$attribedvar{$_}{attrib}{text}\\n$attribedvar{$_}{title} ($attrib)\\n\\n' unless -$attribedvar{$_}{attrib}{value} '$attrib';");
	}
}
for (keys(%regexpedvar)) {
	next unless $form_input->{$_};
	my @a = $form_input->{$_} =~ /^ARRAY/ ? @{$form_input->{$_}} : ($form_input->{$_});
	for my $attrib (@a) {
		eval("\$err .= '$regexpedvar{$_}{title} ($attrib)\\n$regexpedvar{$_}{regexp}{text}\\n\\n' unless '$attrib' =~ /$regexpedvar{$_}{regexp}{value}/;");
	}
}

errorout($err) if $err;
#konvertiere zu array
my %multiplegroupvar = getconfigstruct("multiple", "group");
my %multiplevar = getconfigstruct("multiple");
my @keys = keys(%multiplevar);
for (keys(%multiplegroupvar)) {
	for (@{$multiplegroupvar{$_}{element}}) {
		push(@keys, $$_{var}{name});
	}
}
for (@keys) {
	next if ($partial && ! exists $$form_input{$_});
	unless ($$form_input{$_} =~ /^ARRAY/) {
		print STDERR "Convert Scalar to Array: $_\n";
		$$form_input{$_}=[$$form_input{$_}];
	}
}
# leere elemente in einfachen multiple entfernen
my %multiplevar = getconfigstruct("multiple");

for my $key (keys(%multiplevar)) {
	next if ($partial && ! exists $$form_input{$_});
	my @n;
	for (@{$$form_input{$key}}) {
		push(@n, $_) if $_;
	};

	if ($#{$$form_input{$key}} != $#n) {
		print STDERR "Removing empty entries in: $key\n";
		@{$$form_input{$key}} = @n;
	}
}

if ($$form_input{configid} =~ /new/i) {
$$form_input{configid} = $#CONFSETS+1;
push(@CONFSETS, $form_input);
print "document.getElementsByName('configid')[0].value='".($#CONFSETS)."';";
}
elsif ($partial) {
	for my $keys (keys %$form_input) {
	dbg($keys." -> ".$$form_input{$keys});
	for (@CONFSETS) {
		$$_{$keys} = $$form_input{$keys};
	}
	}
}
else { $CONFSETS[$$form_input{configid}]=$form_input }
#print STDERR Dumper \@CONFSETS;
#open(CONFIG, "> $configfile") or die "Error opening config file!";
#print CONFIG Dumper \@CONFSETS;
#close(CONFIG);
store [@CONFSETS], $configfile;
dbg("$L{SAVECONF}\n$info");
print "alert(\"".decode_entities($L{SAVECONF})."\\n\\n".decode_entities($info)."\");";

exit(0);

sub errorout {
my $err;
$err = "\\n".$_[0] if $_[0];
warn qq|$L{SAVEERR} $err|;

print "alert(\"".decode_entities($L{SAVEERR}.$err)."\")";
exit(0);

}
}
elsif ($form_input ->{'confighandler'} eq "load" ) {				# Einstellungen ARG1->OPTIONSET

my $new;
$new = 1 if $form_input ->{'set'} =~ /new/i;

my $data = getconfigstruct();

unless ($new) { die "Error while loading Configuration!" unless loadconfig($form_input ->{'set'}) };

#print STDERR Dumper $$data{config}{category};
#print STDERR Dumper $OPT{name};


my @categories = @{$$data{config}{category}};

#makehtml("","","","");

my $submit = qq|<input class="button blueHeadButton" onclick="doJSByHref('$me?'+encodeForm(\$('mainbody')).join('&'));" type='button' value=$L{SAVE}>|;

print qq(<div id="config_settings" title="$L{SETTINGS}" action="$me" class="panel" selected="true">
$submit
<input type="hidden" name="confighandler" value="save">
<input type="hidden" name="configid" value="$$form_input{'set'}">
<input type="hidden" name="configversion" value="$version">
);

print qq(<h2>Auswahl</h2><fieldset>);
for (@categories) { print qq(<div class='row listarrow'><a href='#cat_$$_{name}'>$$_{title}</a></div>); }
print qq(</fieldset>);
unless ($new) {
print qq|<br><center>|;

print qq|<span onclick="var cnf = confirm('$L{DELCONF}'); if (cnf) doJSByHref('$me?confighandler=delete&set=$$form_input{'set'}');" class='subButton redButton'>$L{REMOVE}</span>| if $form_input ->{'set'};

print qq|<span onclick="var confname=prompt('Configname:'); if (! confname) return; document.getElementsByName('configname')[0].value=confname; document.getElementsByName('configid')[0].value='new'; doJSByHref('$me?'+encodeForm(\$('mainbody')).join('&'));" class='subButton blueButton'>$L{ADD}</span>|;


print qq|</center>|; };
print qq(</div>);

my @multiplegroups;
for (@categories) {
	make_menu($_, "cat_");
}
for (@multiplegroups) {
	make_menu($_, "group_");
}

#makehtml("food", "display:none");
exit(0);

sub make_menu {
	print qq(<div id="$_[1]$_[0]{name}" title="$_[0]{title}" class="panel">$submit);
	if ($_[0]{multiple}) {
		$_[0]{title} = encode_entities($_[0]{title});
		#$_[0]{descr} = encode_entities($_[0]{descr}) if $_[0]{descr};
		my $info = qq|<img class='info' src='$weburl/info.png' style='left:100px' onclick='alert("$_[0]{descr}")' />| if $_[0]{descr};

	 my $thisfield="addfieldset_".$_[0]{name};
	 my $img = qq(<img 
	 onclick='var newfield=\$("$thisfield").cloneNode(true); \$("$_[1]$_[0]{name}").appendChild(newfield)'
	 style='right:38px;' src='$weburl/add.png' />
	 <img 
	 onclick='var div=\$("$_[1]$_[0]{name}"); if (div.childNodes.length > 3) div.removeChild(div.lastChild)'
	 style='right:0px;' src='$weburl/remove.png' />);
	 #<h2>$L{GROUP}$info$img</h2>
	 my $mover = mover($thisfield."_0");
	 print qq($info<div style='display:block; position: absolute; right: 8px; top: 2px;'>$img</div>$mover<fieldset id="$thisfield">);
	
	 #$OPT{$_[0]{element}->[0]{var}{name}} = [] unless $OPT{$_[0]{element}->[0]{var}{name}} =~ /^ARRAY/;

	 my $n = $#{$OPT{$_[0]{element}->[0]{var}{name}}};
	 $n = 0 > $n ? 0 : $n;
	 $n = 0 if $new;
	 for my $d (0..$n) { # fr anzahl datens?ze
	  for my $var (@{$_[0]{element}}) { # values ausfllen fr jedes feld
	   $var->{var}{value} = $OPT{$var->{var}{name}}->[$d] unless $new;
	  }

	  #print STDERR $_[0]{element}->[0]{var}{name}, " - ", $d, " - ", $n,"\n";
	  for my $elmnt (@{$_[0]{element}}) { # handle elmnt
		print_var(%{$$elmnt{var}});
	  }
	  print qq(</fieldset>);
	  print mover($thisfield."_".($d+1))."<fieldset>" unless $d == $n;
	 }

	 
    } else {
	 print qq(<fieldset>);
	 handle_element(@{$_[0]{element}});
	 print qq(</fieldset>);
	}
	print qq|<center><br><br><span onclick="var q = confirm('$L{SURE}'); if (q) doJSByHref('$me?confighandler=save&savepartial=all&'+encodeForm(currentPage).join('&'));" class='subButton redButton'>$L{ALLCONF}</span><br><br></center>|;
	print qq(</div>);
}

sub handle_element {
my @tmp = @_;
	for (@tmp) {
	 if ($$_{var}) {
	  $$_{var}{title} = encode_entities($$_{var}{title});
	  #$$_{var}{descr} = encode_entities($$_{var}{descr}) if $$_{var}{descr};
	  my $info = qq|<img class='info' src='$weburl/info.png' onclick='alert("$$_{var}{descr}")' />| if $$_{var}{descr};
	  $$_{var}{title} .= $info;
	  
	  if ($$_{var}{multiple}) { 
		my $thisfield = "addfield_".$$_{var}{name};
#
		print qq|</fieldset><h2>$$_{var}{title}$info<img 
		onclick='var newdiv=document.createElement("div"); newdiv.className="row"; var newinp=document.getElementsByName("$$_{var}{name}")[0].cloneNode(true); newinp.setAttribute("value",""); newdiv.appendChild(newinp); \$("$thisfield").appendChild(newdiv); newinp.focus();'
		style='right:38px;' src='$weburl/add.png' />
		<img 
		onclick='var div=\$("$thisfield"); if (div.childNodes.length > 1) div.removeChild(div.lastChild)'
		style='right:0px;' src='$weburl/remove.png' />
		</h2><fieldset id='$thisfield'>|;
		$$_{var}{title}="";
		push (@{$OPT{$$_{var}{name}}}, "") unless @{$OPT{$$_{var}{name}}};
		for my $conf (@{$OPT{$$_{var}{name}}}) {
		 $$_{var}{value} = $conf;
		 print_var(%{$$_{var}});
		}
		
	  } else {
	   $$_{var}{value} = $OPT{$$_{var}{name}};
	   print_var(%{$$_{var}}); 
	  }
	 }
	 if ($$_{group}) {
		$$_{group}{title} = encode_entities($$_{group}{title});
		#$$_{group}{descr} = encode_entities($$_{group}{descr}) if $$_{group}{descr};
		my $info = qq|<img class='info' src='$weburl/info.png' onclick='alert("$$_{group}{descr}")' />| if $$_{group}{descr};
	  if ($$_{group}{multiple}) {
	   push(@multiplegroups, $$_{group});
	   print qq(<div class='row listarrow'><a href='#group_$$_{group}{name}'>$$_{group}{title}</a></div>);
	  } else {
		$$_{group}{title} .= $info;
	   print qq(</fieldset><h2>$$_{group}{title}</h2><fieldset>);
       handle_element(@{$$_{group}{element}});
	  }
	 }
	}
}
sub print_var {
		# funktion var
		my %tmp = @_;
		my @types=(\&xml_text_row, \&xml_text_row, \&xml_toggle, \&xml_list_row);
		print &{$types[$tmp{type}]}(%tmp);
}
sub xml_text_row {
	my %tmp = @_;
	#$OPT{$tmp{name}} = [$OPT{$tmp{name}}] unless  
	text_row($tmp{title}, $tmp{name}, $new ? $tmp{default} : $tmp{value}, ($tmp{type} == 1 ? "[0-9]*" : ""));
}
sub xml_toggle {
	my %tmp = @_;
	toggle($tmp{title}, $tmp{name}, $L{YES}, $L{NO},$new ? $tmp{default} : $tmp{value}, "", 1, 0);
}
sub xml_list_row {
	my %tmp = @_;
	my @set=@{$$data{config}{set}{$tmp{setname}}{item}};
	my $item;
	if ($tmp{value} && ! $new) {
	 for(@set) {
	  if ($_->{value} eq $tmp{value}) {
		$_->{selected}=1;
		$item = $_;
		last;
	  }
	 };
	}

	my $result = list_row($tmp{title}, $tmp{name}, "", "", \@set);
	delete $item->{selected};
	return($result);
}

sub mover {
return unless @_;
return(qq(<h2 id='$_[0]' style='height:24px;'>
<img onclick="moveFieldset($_[0], true)" style="left: 60px;" src="$weburl/upbtn.png">
<img onclick="moveFieldset($_[0], false)" style="" src="$weburl/downbtn.png"></h2>));
}

}
elsif ($form_input ->{'confighandler'} eq "delete") {				# Einstellungen ARG1->OPTIONSET

unless ($form_input ->{'set'}) {
print "alert('Can\\'t delete first Configuration. Sorry!')";
exit(0);
}

my $d;
my @NEWCS;
for (@CONFSETS) {
	push(@NEWCS, $_) unless $d++ == $form_input ->{'set'};
}
$d=0;
for (@NEWCS) {
$$_{configid} = $d++;
}

store [@NEWCS], $configfile;

print "alert('".decode_entities($L{DELCONFDONE})."'); window.close(); location.reload();";
exit(0);
}


sub getconfigstruct {
require XML::Simple;
my $xml = new XML::Simple;
my $data = $xml->XMLin($configmenu, KeyAttr => { set => "+name"}, ForceArray => [ 'element', 'set' ] );
translate_xml($data);

return $data unless @_;

my $elmnt = ($_[1] ? $_[1] : "var");

my %OPTS;
my @elmnts = @{$$data{config}{category}};
for (@elmnts) {
for (@{$$_{element}}) {
push(@elmnts, $$_{group}) if $$_{group};
#$OPTS{$$_{var}{name}}=$$_{var}{default} if $$_{var};
$OPTS{$$_{$elmnt}{name}}=$$_{$elmnt} if $$_{$elmnt}{$_[0]};
}
}

return %OPTS;


sub translate_xml {
	for (@{$_[0]{config}{category}}) {
		transhandle_hash($_);
	}
	return $h;
}

sub transhandle_hash {
	translate_hash($_[0]);
	for (@{$_[0]{element}}) {
		translate_hash($$_{var}) if $$_{var};
		transhandle_hash($$_{group}) if $$_{group};
	}
}

sub translate_hash {
	for my $tr ("descr","title") {
		if ($_[0]{$tr} =~ /HASH/) {
			$_[0]{$tr} = ($_[0]{$tr}{$OPT{language}} || $_[0]{$tr}{en} || $_[0]{$tr}{de});
		}
	}
}

}





