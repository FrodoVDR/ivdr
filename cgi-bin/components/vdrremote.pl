
my %dialogkeys;
# folgender fall ist nicht berücksichtigt
# mediaplayer extern, playvdrovermediaplayer aus
# dann müssen reckeys vdr befehle sein, und cntrlbtns player befehle
# problem: hitk kennt nur den aktuellen player 
# lösung: reckeys bei vdr intern über simplehttprequest und wenn playovermediaplayer = off reckeys von vdr in player keys
$dialogkeys{vdr} = $dialogkeys{mplayer} = $dialogkeys{xineliboutput} = {
	reckeys => {
#		navback=>'hitk(7, "PLAY")',
#		prevtrk=>'hitk(1)',
#		stopkey=>'hitk("Stop")',
#		infokey=>'hitk("OK")',
#		nexttrk=>'hitk("Yellow")',
#		navfrwd=>'hitk(8)', 
		navback=>'SimpleHttpRequest("'.$me.'?rc+7", "'.$me.'?rc+PLAY")',
		prevtrk=>'SimpleHttpRequest("'.$me.'?rc+1")',
		stopkey=>'SimpleHttpRequest("'.$me.'?rc+Stop")',
		infokey=>'SimpleHttpRequest("'.$me.'?rc+OK")',
		nexttrk=>'SimpleHttpRequest("'.$me.'?rc+Yellow")',
		navfrwd=>'SimpleHttpRequest("'.$me.'?rc+8")',
	},
	ctrlkeys => {
		navback=>'hitk("Prev", "Prev")',
		prevtrk=>'hitk("FastRew")',
		stopkey=>'hitk("Stop")',
		pauskey=>'hitk("Pause")',
		nexttrk=>'hitk("FastFwd")',
		navfrwd=>'hitk("Next")',
	},
};
$dialogkeys{xbmc} = {
	reckeys => {
		navback=>'hitk(4)',
		prevtrk=>'hitk(1)',
		stopkey=>'hitk(13)',
		infokey=>'SimpleHttpRequest(sn+"command=SendKey(0xF049)")',
		nexttrk=>'hitk(2)',
		navfrwd=>'hitk(3)',
	},
	ctrlkeys => {
		navback=>'SimpleHttpRequest(sn+"command=PlayPrevExSlide()");',
		prevtrk=>'hitk(1)',
		stopkey=>'SimpleHttpRequest(sn+"command=StopExSlide()");',
		pauskey=>'hitk(12)',
		nexttrk=>'hitk(2)',
		navfrwd=>'SimpleHttpRequest(sn+"command=PlayNextExSlide()");',
	},
};
$dialogkeys{vlc} = {
	reckeys => {
		navback=>'hitk("pl_previous")',
		prevtrk=>'hitk("seek&val=-2%25")',
		stopkey=>'hitk("pl_stop")',
		infokey=>'hitk("fullscreen")',
		nexttrk=>'hitk("seek&val=%2B5%25")',
		navfrwd=>'hitk("pl_next")',
	},
	ctrlkeys => {
		navback=>'hitk("pl_previous")',
		prevtrk=>'hitk("seek&val=-2%25")',
		stopkey=>'hitk("pl_stop")',
		pauskey=>'hitk("pl_pause")',
		nexttrk=>'hitk("seek&val=%2B5%25")',
		navfrwd=>'hitk("pl_next")',
	},
};

my %actualkeys = %{$dialogkeys{$OPT{player}}};
unless($OPT{vdr_mpplay}) {
$actualkeys{reckeys} = $dialogkeys{vdr}{reckeys};
};

print qq[
<form id='buttonsForm' class='dialog'><fieldset>
<h1 id='headline'  onclick='cancelDialog(bf())'></h1>
</fieldset>	

<a id='morebtn' class='leftButton lightHeadButton' onclick='oDialog.toggle();' style='position:absolute; display:none;'>&nbsp;&nbsp;&nbsp;&#8230&nbsp;&nbsp;&nbsp;</a>

<a id='toprightbtn' class='button' style='position:absolute;  display:none;'></a>

<a id='closebtn' class="leftButton lightHeadButton" style="position:absolute; padding:4px 10px 0; margin:-2px 0 0" onTouchstart="event.preventDefault(); cancelDialog(bf());" onClick="cancelDialog(bf());"><img src="$weburl/AddressViewStop.png" /></a>

<div id='recbtns' style='display:none; position:absolute; bottom:0px; text-align:center; width:100%;'>
<div style='width:16%; float:left' onclick='$actualkeys{reckeys}{navback}'><img src='$weburl/key_back.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{reckeys}{prevtrk}'><img src='$weburl/key_prev.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{reckeys}{stopkey}'><img src='$weburl/key_stop.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{reckeys}{infokey}'><img src='$weburl/key_ok.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{reckeys}{nexttrk}'><img src='$weburl/key_forw.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{reckeys}{navfrwd}'><img src='$weburl/key_next.png'></div>
</div>

<div id='cntrlbtns' style='display:none;display:none; position:absolute; bottom:0px; text-align:center; width:100%;'>
<div style='width:16%; float:left' onclick='$actualkeys{ctrlkeys}{navback}' value='Prev'><img src='$weburl/key_back.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{ctrlkeys}{prevtrk}'><img src='$weburl/key_prev.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{ctrlkeys}{stopkey}'><img src='$weburl/key_stop.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{ctrlkeys}{pauskey}'><img src='$weburl/key_pause.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{ctrlkeys}{nexttrk}'><img src='$weburl/key_forw.png'></div>
<div style='width:16%; float:left' onclick='$actualkeys{ctrlkeys}{navfrwd}'><img src='$weburl/key_next.png'></div>
</div>

<!--<a id='greenbtn' class='button greenButton topright'></a>
<a id='bluebtn' class='button blueButton bottomright'></a>
<a id='redbtn' class='button redButton topleft'></a>
<a id='yellowbtn' class='button yellowButton bottomleft'></a>-->

<div id='btnsarea'>
<!--<span class='dialogbutton'><img src='/pics/new/edit-clear.png' /><br>Löschen</span>-->
</div>

<!--<embed id="moviebtn" style=" display:none;  width:280px; margin: 20px; height: 210px " src="" 
type="video/x-m4v" target="myself" scale="1" />-->
<video id="moviebtn" style=' display:none;  width:220px; margin: 20px; height: 160px ' autobuffer controls preload="metadata" onerror="" onclick="this.play()" src="">
</video>


<input id='inputField_1' type="hidden">
<input id='inputField_2' type="hidden">

<div id='timebardiv' style='position:absolute; bottom: 230px; left:25px; right:25px; display:none;' align="center">
<span id="pin" value='0' maxvalue='1000'></span>
<span id="timebarlabel" ontouchstart='event.preventDefault(); pinmove(event.targetTouches[0])' ontouchmove='event.preventDefault(); pinmove(event.targetTouches[0])' onclick='pinmove(event);'>Dauer: 15 minuten</span>
<table id="timebar" cellspacing="0" style='width:100%;margin:0px 20px' ontouchstart='event.preventDefault(); pinmove(event.targetTouches[0])' ontouchmove='event.preventDefault(); pinmove(event.targetTouches[0])' onclick='pinmove(event);'><tr>
<td width="0%"></td>
<td width="5%" class="yellow"></td>
<td width="2%"></td>
<td width="10%"  class="yellow"></td>
<td width="0%"></td>
<td width="4%" class="yellow"></td>
<td width="27%"></td>
<td width="38%" class="yellow"></td>
</tr></table>
</div>


<div id='selectField' style='display:none;'>
<span id='selectFieldLabel_1' class='roundmark' style='position: absolute; bottom: 190px; left:4%;'>Test</span>
<select id='selectField_1' style='position: absolute; bottom: 145px;left:5%; width:90%;'></select>
<span id='selectFieldLabel_2' class='roundmark' style='position: absolute; bottom: 120px; left:4%;'>Test</span>
<select id='selectField_2' style='position: absolute; bottom: 75px;left:5%; width:90%;'></select>
<span id='selectFieldLabel_3' class='roundmark' style='position: absolute; bottom: 50px; left:4%;'>Test</span>
<select id='selectField_3' style='position: absolute; bottom: 5px;left:5%; width:90%;'></select>
</div>

<div id='epginfobar' style='text-align: left; position: absolute; display: none; overflow: auto;
background-color:#FFFFFF; left:14px; top:55px; right: 14px; bottom:14px; padding:14px;
box-sizing: border-box; -webkit-box-sizing: border-box; -webkit-border-radius: 10px;
-webkit-box-shadow: inset 0px 0px 5px #000;'
 onclick='this.style.display="none"'>
</div>
<script>
var eib = \$('epginfobar');
var eibyof;
eib.addEventListener('touchstart', function(e) { eibyof = e.targetTouches[0].pageY } , false); 
eib.addEventListener('touchmove', function(e) { e.preventDefault() } , false); 
eib.addEventListener('touchmove', function(e) 
	{
			eib.scrollTop += eibyof-e.targetTouches[0].pageY;
			eibyof=e.targetTouches[0].pageY; 
			
	}, false);
</script>

<div id='rateStars' style='display: none; position: absolute; bottom: 72px; padding: 0px 10px; margin: 0px; width:94%; text-align: center;'>
<div tag='0' style='position:absolute; display: block; left: 0px; width:50%; height:24px;' onclick='dialogStars(this.getAttribute("tag"))'></div>
<span class='ratedot' tag='1' onclick='dialogStars(this.getAttribute("tag"))'></span>
<span class='ratedot' tag='2' onclick='dialogStars(this.getAttribute("tag"))'></span>
<span class='ratedot' tag='3' onclick='dialogStars(this.getAttribute("tag"))'></span>
<span class='ratedot' tag='4' onclick='dialogStars(this.getAttribute("tag"))'></span>
<span class='ratedot' tag='5' onclick='dialogStars(this.getAttribute("tag"))'></span>
</div>
<!-- BOTTOM-LABEL: <div style='display: block; position: absolute; bottom: 0px; padding: 10px; color: #FFF; height: 20px; white-Space: nowrap; text-align: right;'>asuh asiguh asisugh asui 020-richgirl_-_he_aint_wit_me_now-ministry.mp3</div>-->
</form>
];