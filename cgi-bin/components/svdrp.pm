# ------------------------------ SVDRP Connection ---------------------------

sub establishSocket {

my $svdrpServer = $OPT{vdr_adress} || "localhost";
my $svdrpPort 	= $OPT{vdr_port} || "2001";
$SIG{ALRM} = sub { errorSocket("SVDRP: timeout") };
alarm(20);

my $iaddr = inet_aton($svdrpServer)				||	errorSocket("SVDRP: no host");
my $paddr = sockaddr_in($svdrpPort, $iaddr);
my $proto = getprotobyname('tcp');

socket(SOCK, PF_INET, SOCK_STREAM, $proto)	||	errorSocket("SVDRP: socket $!");
connect(SOCK, $paddr)						||	errorSocket("SVDRP: connect $!");

# select(SOCK); $| = 1;
$connection = Receive();

alarm(0);
}

sub Send {
select(SOCK); $| = 1;

my $send;
if ($OPT{binmodetoutf8}) { $send = encode("utf-8", join("", @_)) }
else { $send = join("", @_) }
#$send = join("", @_);

print SOCK $send."\r\n" || print STDERR "SVDRP: Kein Parameter angegeben\n";

while (<SOCK>) {
	print STDERR $OPT{binmodetoutf8} ? decode("utf-8", $_) : $_ if $debug;
	last if substr($_, 3, 1) ne "-";
	}
select(STDOUT);
}

sub Receive {
select(SOCK); $| = 1;
alarm(20);

my $send;
if ($OPT{binmodetoutf8}) { $send = encode("utf-8", join("", @_)) }
else { $send = join("", @_) }
#$send = join("", @_);
print SOCK $send."\r\n" if @_;

my $result;
while (<SOCK>) {
	$result .= $_;
	last if substr($_, 3, 1) ne "-";
	}

alarm(0);
select(STDOUT);

return($OPT{binmodetoutf8} ? decode("utf-8", $result) : $result);
#return($result);

}

sub quitSocket {
print STDERR "@_\n" if @_;
$connection = Receive("quit");
close (SOCK);
}

sub errorSocket {
my $err;
$err .= "@_" if @_;
print STDERR $err."\n" if @_;
print STDERR "Closing Socket\n";

close (SOCK);
if ($OPT{vdr}) {
print js(qq< alert("$err\\n$OPT{configname}\\n$OPT{vdr_adress}:$OPT{vdr_port}"); >);

if ($OPT{panic_script}) {
	print js(qq<if (confirm("Start panicscript?\\n$OPT{panic_script}")) { 
		var jsreq = new XMLHttpRequest(); jsreq.onreadystatechange = function() { if (jsreq.readyState == 4) { eval(jsreq.responseText)	} }
		jsreq.open("GET", "$me\?PANIC", true); jsreq.send(null); } >);	
}

print js(qq< if (confirm("Change setfile to mainsettings?")) { document.cookie='IVDRSET=0'; location.reload();}>) if $OPT{configid};

}
}

1;