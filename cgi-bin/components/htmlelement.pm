# used in vdrhandler main config
sub remoteButton { return ("<a id='rightButton' class='button' onclick='if (remotewin) { if (! remotewin.closed) { remotewin.focus(); return; }}; remotewin=window.open(\"$me?REMOTE\",\"_remote_control\");'>$L{REMOTE}</a>") }
sub closeButton { return('<a class="leftButton lightHeadButton" style="padding:4px 10px 0; margin:-2px 0 0" onClick="javscript:window.close()"><img src="'.$weburl.'/AddressViewStop.png" /></a>') };
sub refreshButton { return("<a id='rightButton' style='padding:4px 10px 0; margin:-1px 0 0' class='button' onClick='iui.refreshPage()'><img src='".$weburl."/reload.png' /></a>") }
sub addrefButton {         
		return(
		"<ul class='iTab'>
			<li><a href='$_[0]' target='_changewindow'><img src='".$weburl."/mplus.png' /></a></li>
			<li><a onClick='iui.refreshPage()'><img src='".$weburl."/reload.png' /></a></li>
		</ul>");
 }
sub twinButtonList { # hash bergeben title, href, onchange, \@value

my %h = @_;
# $h{title} # $h{href} #$h{onchange} # $h{prevalue} # @$h{value} 

my $grp=0;
my $result = qq(<div class='row more' style='border-left:1px solid #999; float:right;'>
<select class='small' style='width:50px; left:0px; background:none;' onchange='$h{onchange}'><option></option>\n);
for (@{$h{value}}) {
	$result .= "<option value='$h{prevalue}".$grp++."'>$_</option>";
}
$h{href} = "href='$h{href}'";
$result .= qq(\n</select></div><div class='row listarrow' style='margin:0 58px 0 0'><a $h{href}>$h{title}</a></div>);
}
sub toggle{		# Erzeugt ein Togglefeld Arg0 -> Label, Arg1-> checkboxname, Arg2 -> [ON], Arg3 -> [OFF] [Arg4] -> toggled 0/1 [Arg5] -> onclick Arg6 -> truevalue arg7 -> falsevalue
my $toggle = qq(<div class="row"><label>$_[0]</label><div class="toggle" id="tgldiv" onclick="toggle(this, '$_[1]','$_[6]','$_[7]'); $_[5]");
$toggle .= ' toggled="true"' if $_[4] && $_[4] eq 1;
$toggle .= qq(><span class="thumb"></span><span class="toggleOn">$_[2]</span><span class="toggleOff">$_[3]</span><input type="hidden" name="$_[1]");
if ($_[4] && $_[4] eq 1) { $toggle .= "  value=\"$_[6]\"" } else { $toggle .= "  value=\"$_[7]\"" }
$toggle.= qq(></div></div>);
return($toggle);
}
sub text_row { # Arg0->Label, Arg1->name, Arg2->value, Arg3->pattern(tel, url, email, [0-9]*)
return qq(<div class="row">
			<label class='info'>$_[0]</label>
			<input type="text" name="$_[1]" pattern="$_[3]" value="$_[2]">
		</div>);
}
sub list_row { # Arg0->Titel, Arg1->name[s], Arg2->class, Arg3->trennzeichen, Arg4.ff->[{value=>, text=>, selected=>}, ...]
my $result = shift;
$result = "<div class='row'><label>".$result."</label>";
my $names = shift; my $class = shift; my $separator=shift; my $d=0; my $sep;
$names = [$names] unless $names =~ /ARRAY/;
for (@_) {
$result .= " $sep <select name='".$$names[$d++]."' class='".$class."'>";
for (@$_) { $result .= "<option value='$$_{value}' ".($$_{selected} ? "selected" : "").">$$_{text}</option>" }
$result .= "</select> ";
$sep = $separator;
}
$result .= "</div>";
return($result);
}

1;