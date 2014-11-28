function Box(inElement) {
var self = this;
this.bar = $('bar'); 

this.offL = 0;
this.offT = 0;

this.min = 0;
this.max = 0;
		
this.value = 0;

this.element = inElement;

this.xOffset = this.element.offsetWidth/2;
this.yOffset = this.element.offsetHeight/2;

this.setElementaries = function() {
	self.offL = 0;
	self.offT = self.bar.offsetHeight/2;
	var p = self.bar;
	while (p.parentNode) { self.offL += p.offsetLeft; self.offT += p.offsetTop; p = p.parentNode;} 

	self.min = self.offL; 
	self.max = self.offL + bar.offsetWidth;
}

this.element.addEventListener('touchstart', function(e) { e.preventDefault() });
this.element.addEventListener('touchmove', function(e) { self.onTouchMove(e), false });
this.element.addEventListener('touchend', function(e) { self.updateEmbed(), false });

this.updateEmbed = function() {
		//$('_a').innerHTML = $('info').getAttribute('_offset')+" - "+$('info').getAttribute('_recid')+' - '+$('info').getAttribute('_aspect');
		//alert($('info').getAttribute('_aspect'));
		//$('_b').innerHTML = $('emb').getAttribute('flashvars');
		//alert($('emb').getAttribute('flashvars'));

		var flashvar = $('emb').getAttribute('flashvars').split('&');
		//var re = /file=(.*)/;
		var expr = /file=(.*)\?(.*)/.exec(decodeURIComponent(flashvar[0]));
		var param = expr[1]+"?stream=rec&recid="+$('info').getAttribute('_recid')+"&offset="+self.value+"&aspect="+$('info').getAttribute('_aspect');
		//$('emb').setAttribute('flashvars', "file="+encodeURIComponent(param)+"&"+flashvar[1]);
		$('parentemb').innerHTML = '<embed id="emb" src="http://imobilecinema.com/imcfp.swf" type="application/x-shockwave-flash" width=80 height=80 align=right flashvars="file='+encodeURIComponent(param)+"&"+flashvar[1]+'">';
		//$('_c').innerHTML = $('emb').getAttribute('flashvars');;
		//$('_d').innerHTML = $('parentemb').innerHTML;
		//alert($('emb').getAttribute('flashvars'));
		
		// image = flashvar[1];
}

this.onTouchMove = function (e) {
    e.preventDefault();
	if (e.targetTouches[0].clientX >= this.min && e.targetTouches[0].clientX <= this.max) {
		this.position = e.targetTouches[0].clientX+", "+this.y;
		this.value = Math.round((this.x-this.min)/(this.max-this.min)*65536);
		}
	}  

this.orientationChange = function () {
	self.setElementaries();
	self.position = (self.min+(self.max-self.min)*(self.value/65536))+','+self.offT;	
	}
}
	
Box.prototype = {

get position() {
return this._position;
},

set position(pos) {
	this._position = pos;

var components = pos.split(',');
var x = components[0];
var y = components[1];

this.element.style.webkitTransform = 'translate('+(x-this.xOffset)+'px, '+(y-this.yOffset)+'px)';

},

get x() {
return parseInt(this._position.split(',')[0]);
},

set x(inX) {
var comps = this._position.split(',');
copms[0] = inX;
this.position = comps.join(',');
},

get y() {
return parseInt(this._position.split(',')[1]);
},

set y(inY) {
var comps = this._position.split(',');
copms[1] = inY;
this.position = comps.join(',');
}
}


function loaded() {
//<div id="pin"></div>
bx = new Box(document.getElementById('pin'));
bx.setElementaries();
bx.position = bx.offL+','+bx.offT;
window.addEventListener("orientationchange", function() { bx.orientationChange() }, false);

}

var bx;
window.addEventListener('load', loaded, true);


