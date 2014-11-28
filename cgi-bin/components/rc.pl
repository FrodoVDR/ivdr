

# iVDR Remote Control v0.31

my $fin;


my %volume;
$volume{mplayer} = $volume{xinemediaplayer} = $volume{xineliboutput} = "rc+VOLU+";
$volume{xbmc} = "command=setvolume&parameter=";
$volume{vlc} = "command=volume&val=";

my $fin = qq(
<script language="javascript"> 
<!--
\$('numericvol').innerHTML = $actvolume;
\$('voldiv').ontouchstart = function(e) {
	if ( ! remotevol) {
		\$('numericvol').style.top = event.touches[0].pageY-25+"px";
		\$('numericvol').style.display = 'block';
		}
}
\$('voldiv').ontouchmove = function(e){ 
	e.preventDefault(); 
	var vol = Math.ceil(Math.abs(Math.max(0, Math.min($OPT{volumemax}-$OPT{volumemin}, ($OPT{volumemax}-$OPT{volumemin})/(350-70)*(event.touches[0].pageY-window.pageYOffset-70) ))-$OPT{volumemax})); 
	if (! remotevol || (remotevol+1) <= vol || (remotevol-1) >= vol) { 
		remotevol=vol; 
		\$('numericvol').innerHTML = remotevol;
		\$('numericvol').style.top = event.touches[0].pageY-25+"px";
	}
};
\$('voldiv').ontouchend = function(e){ 
	if ( ! remotevol) 
		hitk(this);
	else {
		SimpleHttpRequest(sn+'$volume{$OPT{player}}'+remotevol);
		console.log(sn+'$volume{$OPT{player}}'+remotevol);
	}
	\$('numericvol').style.display = 'none';
	remotevol=null;
}


//alert(\$('voldiv').ontouchmove);
scrollTo(0,1);
-->
</script>
</body>

</html>);

my %body;
my $tvimage = qq(
	<div style='text-align:center; width:100%; z-index:-1;'>
		<img onclick='refreshTV(1)' id='tvimage' src='$me?media=grab' width='94%' />
		<span onclick = 'tvactive = ! tvactive; if (! tvactive) this.style.backgroundImage="url($weburl/delete.png)"; else this.style.backgroundImage="url($weburl/active.png)";' style='display: block; position:absolute; top:2px; right: 1px; width:16px; height:16px; background:url($weburl/delete.png) no-repeat center;' />
	</div>) if $OPT{remoteimage};

$body{mplayer} = $body{xineliboutput} = $body{xinemediaplayer} = qq(
<body bgcolor='lightgray' ontouchend='setTimeout("refreshTV()", 100)'>
$tvimage
<div  style='display:block; width:174px; height:300px; float:left;'>
<div class='monster keyd' onclick="hitk(this)" value='back'>&#8630;</div>
<div class='big keya' onclick="hitk(this)" value='Up'>&#9650;</div>
<div class='big keyd' onclick="hitk(this)" value='Channel+'>&and;</div>
<div class='big keya' onclick="hitk(this)" value='Left'>&#9668;</div>
<div class='big keyd' onclick="hitk(this)" value='Ok'>&diams;</div>
<div class='big keya' onclick="hitk(this)" value='Right'>&#9658;</div>
<div class='t keyd' onclick="hitk(this)" value='Menu'>Menu</div>
<div class='big keya' onclick="hitk(this)" value='Down'>&#9660;</div>
<div class='big keyd' onclick="hitk(this)" value='Channel-'>&or;</div>
<div class='t keya' onclick="hitk(this)" value='FastRew'><span style='letter-spacing: -0.4em'>&#9668;&#9668;</span></div>
<div class='big keya' onclick="hitk(this)" value='Play'>&#9658;</div>
<div class='t keya' onclick="hitk(this)" value='FastFwd'><span style='letter-spacing: -0.4em'>&#9658;&#9658;</span></div>
<div class='t keya' onclick="hitk(this)" value='Prev'><span style='margin-left: -0.6em; letter-spacing: -0.6em'>&#10073;</span><span style='letter-spacing: -0.4em'>&#9668;&#9668;</span></div>
<div class='t keya' onclick="hitk(this)" value='Pause'><span style='margin-left: 0.5em;'>&#9612;&#9612;</span></div>
<div class='t keya' onclick="hitk(this)" value='Next'><span style='letter-spacing: -0.4em'>&#9658;&#9658;</span><span style='margin-left: -0.3em;'>&#10073;</span></div>
<div class='monster keya' style='color:red' onclick="hitk(this)" value='Record'>&#9679;</div>
<div class='big keya' onclick="hitk(this)" value='Stop'>&#8718;</div>
</div>
<div  style='display:block; width:56px; height:250px; float:left;'>
<div class='big red' style='float:right' onclick="hitk(this)" value='Red'></div>
<div class='big green' style='float:right' onclick="hitk(this)" value='Green'></div>
<div class='big yellow' style='float:right' onclick="hitk(this)" value='Yellow'></div>
<div class='big blue' style='float:right' onclick="hitk(this)" value='Blue'></div>
<div id='voldiv' class='t keyb' value='Mute'>Vol</div>
</div>
<div class='s keyd' onclick="hitk(this)" value='Recordings'>Rec</div>
<div class='s keyd' onclick="hitk(this)" value='Schedule'>TV</div>
<div class='s keyd' onclick="hitk(this)" value='Audio'>Audio</div>
<div class='s keyd' onclick="hitk(this)" value='Timers'>Timer</div>
<div class='s keyd' onclick="hitk(this)" value='Commands'>Commands</div>
<div class='s keyd' onclick="hitk(this)" value='Setup'>Setup</div>
<div  style='display:block; width:174px; height:200px; float:left;'>
<div class='big keya' onclick="hitk(this)" value='1'>1</div>
<div class='big keya' onclick="hitk(this)" value='2'>2</div>
<div class='big keya' onclick="hitk(this)" value='3'>3</div>
<div class='big keya' onclick="hitk(this)" value='4'>4</div>
<div class='big keya' onclick="hitk(this)" value='5'>5</div>
<div class='big keya' onclick="hitk(this)" value='6'>6</div>
<div class='big keya' onclick="hitk(this)" value='7'>7</div>
<div class='big keya' onclick="hitk(this)" value='8'>8</div>
<div class='big keya' onclick="hitk(this)" value='9'>9</div>
<div class='t keyd' onclick="hitk(this)" value='PrevChannel'>Last</div>
<div class='big keya' onclick="hitk(this)" value='0'>0</div>
<div class='t keyd' onclick="hitk(this)" value='Info'>Info</div>
</div>
<div class='u keyb' onclick="hitk(this)" value='User1'>$OPT{user_1}</div>
<div class='u keyb' onclick="hitk(this)" value='User2'>$OPT{user_2}</div>
<div class='u keyb' onclick="hitk(this)" value='User3'>$OPT{user_3}</div>
<div class='u keyb' onclick="hitk(this)" value='User4'>$OPT{user_4}</div>
<div class='u keyb' onclick="hitk(this)" value='User5'>$OPT{user_5}</div>
<div class='u keyb' onclick="hitk(this)" value='User6'>$OPT{user_6}</div>
<div class='u keyb' onclick="hitk(this)" value='User7'>$OPT{user_7}</div>
<div class='u keyb' onclick="hitk(this)" value='User8'>$OPT{user_8}</div>
<div class='u keyb' onclick="hitk(this)" value='User9'>$OPT{user_9}</div>
<hr style='width:95%; margin-top:8px;'>
<div class='t red' onclick="if (confirm('Shutdown?')) hitk(this)" value='Power'>OFF</div>
);
$body{xbmc} = qq(
<body bgcolor='lightgray' ontouchend='setTimeout("refreshTV()", 100)'>
$tvimage
<div  style='display:block; width:232px; height:300px; float:left;'>
<div class='monster keyd' onclick="SimpleHttpRequest(sn+'command=SendKey(275)')" value='back'>&#8630;</div>
<div class='big keya' onclick="hitk('3')" value='Up'>&#9650;</div>
<div class='t keyd' onclick="hitk('18')" value='Menu'>Menu</div>
<div class='big keyd' onclick="hitk('5')" value=''>&and;</div>

<div class='big keya' onclick="hitk('1')" value='Left'>&#9668;</div>
<div class='big keyd' onclick="SimpleHttpRequest(sn+'command=SendKey(0xF00D)')" value='Ok'>&diams;</div>
<div class='big keya' onclick="hitk('2')" value='Right'>&#9658;</div>
<div id='voldiv' class='t keyb' value='91'>Vol</div>

<div class='big keyd' onclick="SimpleHttpRequest(sn+'command=SendKey(0xF043)')" value=''>&#9997;</div>
<div class='big keya' onclick="hitk('4')" value='Down'>&#9660;</div>
<div class='big keyd' onclick="SimpleHttpRequest(sn+'command=SendKey(0xF049)')" value=''>&#9432;</div>
<div class='big keyd' onclick="hitk('6')" value=''>&or;</div>

<div class='t keya' onclick="hitk('15')" value=''><span style='margin-left: -0.6em; letter-spacing: -0.6em'>&#10073;</span><span style='letter-spacing: -0.4em'>&#9668;&#9668;</span></div>
<div class='t keyb' onclick="hitk('79')" value='Play'>&#9658;</div>
<div class='t keya' onclick="hitk('14')" value=''><span style='letter-spacing: -0.4em'>&#9658;&#9658;</span><span style='margin-left: -0.3em;'>&#10073;</span></div>
<div class='big keyd' onclick="hitk('56')" value=''>&#9835;</div>

<div class='t keyb' onclick="hitk('78')" value='FastRew'><span style='letter-spacing: -0.4em'>&#9668;&#9668;</span></div>
<div class='t keyb' onclick="hitk('12')" value='Pause'><span style='margin-left: 0.5em;'>&#9612;&#9612;</span></div>
<div class='t keyb' onclick="hitk('77')" value='FastFwd'><span style='letter-spacing: -0.4em'>&#9658;&#9658;</span></div>
<div class='big keyd' onclick="hitk('55')" value=''>&#9834; +</div>

<div class='monster keya' style='color:red' onclick="hitk('Record')" value='Record'>&#9679;</div>
<div class='t keyb' onclick="hitk('13')" value='Stop'>&#9607;</div>
<div class='t keyd' onclick="hitk('25')" value=''>abc</div>
<div class='big keyd' onclick="hitk('54')" value=''>&#9834; -</div>
</div>

<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(home))')" value=''>Home</div>
<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(videolibrary,movietitles))')" value=''>Movies</div>
<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(videolibrary,tvshowtitles))')" value=''>TV</div>
<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(musiclibrary))')" value=''>Music</div>
<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(settings))')" value=''>Settings</div>
<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(osdaudiosettings))')" value=''>Audio</div>
<div class='s keya' onclick="SimpleHttpRequest(sn+'command=ExecBuiltIn(activatewindow(osdvideosettings))')" value=''>Video</div>
<div class='s keya' onclick="hitk('18')" value=''>GUI</div>
<hr style='width:95%; margin-top:8px;'>
);
$body{vlc} = qq(
<body bgcolor='lightgray' ontouchend='setTimeout("refreshTV()", 100)'>

<div  style='display:block; width:232px; height:300px; float:left;'>


<div class='t keya' onclick="hitk('pl_previous')" value=''><span style='margin-left: -0.6em; letter-spacing: -0.6em'>&#10073;</span><span style='letter-spacing: -0.4em'>&#9668;&#9668;</span></div>
<div class='t keyb' onclick="hitk('pl_play')" value='Play'>&#9658;</div>
<div class='t keya' onclick="hitk('pl_next')" value=''><span style='letter-spacing: -0.4em'>&#9658;&#9658;</span><span style='margin-left: -0.3em;'>&#10073;</span></div>
<div class='big keya' onclick='hitk("fullscreen")'>&#9635;</div>

<div class='t keyb' onclick="hitk('seek&val=-2%25')" value='FastRew'><span style='letter-spacing: -0.4em'>&#9668;&#9668;</span></div>
<div class='t keyb' onclick="hitk('pl_pause')" value='Pause'><span style='margin-left: 0.5em;'>&#9612;&#9612;</span></div>
<div class='t keyb' onclick="hitk('seek&val=%2B5%25')" value='FastFwd'><span style='letter-spacing: -0.4em'>&#9658;&#9658;</span></div>
<div id='voldiv' class='t keyb' value='volume&val=0'>Vol</div>

<div class='big keya' onclick='hitk("pl_random")'>&#8669;</div>
<div class='t keyb' onclick="hitk('pl_stop')" value='Stop'>&#9607;</div>
<div class='big keya' onclick='hitk("pl_loop")'>&#8630;</div>
<div class='big keya' onclick='hitk("pl_repeat")'>&#8634;</div>
</div>

<hr style='width:95%; margin-top:8px;'>
);

print <<ENDE


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>iVDR Remote ($OPT{configname})</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="apple-touch-icon" href="$weburl/icon.png" /> 
<meta name="viewport" content="initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>

<script language="javascript"> 
<!--
var global;
var remotevol;
var tvactive =false;
function hitk(div) {
var jsreq = new XMLHttpRequest();

if (typeof(div)!='string') {
var oldclass = div.className;
div.className = oldclass+" nosh";
var key = div.getAttribute("value");
jsreq.onreadystatechange = function()
{
	if (jsreq.readyState == 4)
	{
		div.className = oldclass;
	}
};
} else 
	var key = div;
jsreq.open("GET", keyparam + key, true);
jsreq.send(null);
} 

function SimpleHttpRequest() {
	for (var i = 0; i < SimpleHttpRequest.arguments.length; ++i) {
		var jsreq = new XMLHttpRequest();
		jsreq.open("GET", SimpleHttpRequest.arguments[i], true);
		//jsreq.onreadystatechange = function() { jsreq.abort(); alert('ok'); }
		jsreq.send(null);
	}
}

function refreshTV(imp) {
if (! tvactive && ! imp )
	return;
if (! \$("tvimage")) 
	return;
if (window.pageYOffset < 150)
	\$("tvimage").src = '$me?media=grab&rnd='+Math.round(1 + 1000*(Math.random()));
}

function \$(id) { return document.getElementById(id); }
function \$tn(id) { return document.getElementsByTagName(id); }



document.addEventListener('touchstart', function(e) {
	startX = e.touches[0].pageX; 
	startY = e.touches[0].pageY;
}
, false);

document.addEventListener('touchend', function(e) {
if (! e.changedTouches.length == 1)
	return;

var x=e.changedTouches[0].pageX-startX;
var y=e.changedTouches[0].pageY-startY;

/*alert(e.changedTouches[0].pageX+" - "+startX+" = "+(e.changedTouches[0].pageX-startX)+"\\n"+e.changedTouches[0].pageY+" - "+startY+" = "+(e.changedTouches[0].pageY-startY));*/

if (e.changedTouches.length == 1) {
	if (x<-100 && Math.abs(y) < 40)
		{
		// alert("links");
		}
	if (x>100 && Math.abs(y) < 40)
		{
			opener.focus();
		}
	if (y<-100 && Math.abs(x) < 40)
		{
		//	alert("oben");
		}
	if (y>100 && Math.abs(x) < 40)
		{
		//	alert("unten");
		}
}

}, false);


var sn = '$mediaselect{_OPT_}{SCRIPTNAME}';
var ivdr = '$me';
var www = '$weburl';
var keyparam = '$mediaselect{_OPT_}{KEYPARAM}';
var startX;
var startY;
//-->
</SCRIPT>

<style type="text/css">
<!--

div.t, div.big, div.monster, div.s, div.u, span.vol {
	-webkit-border-radius: 8px;
	/*-webkit-border-image: url("./SBGenericAppIcon.png") 5 5 10;*/
	/*-webkit-border-image: url("$weburl/bottombardarkgray2.png") 10;*/
	/*-webkit-border-image: url("./bottombarclear.png") 5 5 10;*/
	-webkit-box-shadow: 3px 2px 2px rgba(0, 0, 0, 0.5);
	background-image: url($weburl/buttonoverlay.png);
	background-repeat: repeat-x;
	background-position: center;
	font-family: inerhit;
	font-size: 26px;
	font-weight: bold;
	margin: 8px 0px 0px 8px;
	padding:3px;
	text-shadow: rgba(255,255,255,0.6) 1px 1px 1px;
	color: #000000;
	text-decoration: none;
	text-align:center;
	vertical-align: middle;
	overflow:hidden;  /* text-overflow: ellipsis; */
	white-space:nowrap;
	float:left;
	width:44px;
	height:36px;
	line-height:36px;
	}
div.nosh {
	-webkit-box-shadow: none;
}
div.t {
	font-size: 14px;
}
div.big {
	font-size: 24px;
	}
div.monster {
	font-size: 36px;
	}
div.s {
	font-size: 16px;
	width:66px;
	float:right;
	font-weight: normal;
}
div.u {
	font-size: 16px;
	width:54px;
	float:right;
}

div.full { 
	width:100%;
}

.blue { background-color: rgba(0,0,255,1 ); }
.red { background-color: rgba(255,0,0,1); }
.yellow { background-color: rgba(255,255,0,1); }
.green { background-color: rgba(0,255,0,1); }
.black { background-color: rgba(0,0,0,1); }
.white { background-color: rgba(255,255,255,1); }
.keya { background-color: rgba(170,240,255,1); }
.keyb { background-color: rgba(240,255,240,1); }
.keyc { background-color: rgba(255,240,34,1); }
.keyd { background-color: rgba(255,238,187,1); }

#comPad { margin: 0 6px 8px 0;}}
td { text-align:center }

span.vol{
	position: absolute;
	left: 30px;
	background-color: darkgray; 
	text-align:center;
	-webkit-border-radius: 14px;
	display: block;
	height:50px;
	width:120px;
	line-height: 50px;
	font-size: 36px;
	font-weight: bold;
}

body {
margin: 3px 8px 0px 0px;
 padding: 0; 
min-height: 480px;
 }
/*-->
</style>

</head>

$body{$OPT{player}}

<span class='vol' style='display:none' id='numericvol'>0</span>

$fin

ENDE

