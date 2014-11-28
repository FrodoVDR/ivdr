/*
 	 Copyright (c) 2007, iUI Project Members
	 See LICENSE.txt for licensing terms
 */
 
// iVDR Globalisierung
// (function() {

var slideInc = 0.5; 
var slideBase = -0.5; 
var slideSpeed; 
var slideInterval = 10; 
c = null; 
var currentPage = null; 			// HTMLDivElement HTMLUListElement
var currentDialog = null; 
var currentWidth = 0; 				// 480 und 320
var currentYOffset = 0;
var currentHash = location.hash; 	//  #_main #_ln_groups -> location.hash
var activeLi;
var hashPrefix = "#_"; 		
var pageHistory = []; 				// main,ln_groups,channelgroup3,ln_sched
//* iVDR deactivate Rotation ScrollUp
var pageLocationHistory = [];
var currentLocation = 1;
//* iVDR preSelect
var preSelect = null;
var newPageCount = 0; 
var checkTimer;
var activepicload = false;

var multiselect = false;
var usercontrol = [];
var wdlg;
var btnfrm;
var tse=[];
var tee=[];
var kbar;
var kform;

var remotewin;

var remotevol=null;


var touchDevice=isTouchDevice();
function isTouchDevice() { 
    try { 
        document.createEvent("TouchEvent"); 
        return true; 
    } catch (e) { 
        return false; 
    } 
} 

//var volrotation=0;
//var remotewnd;
//var rememberevent;
//var gestureStartX;
//var gestureStartY;

// *************************************************************************************************

window.iui =
{
    showPage: function(page, backwards)
    {
	//console.log("showPage: "+page.id+" "+page);
        if (page)
        {
            if (currentDialog)
            {
                currentDialog.removeAttribute("selected");
                currentDialog = null;
            }

            if (hasClass(page, "dialog"))
                showDialog(page);
            else
            {
                var fromPage = currentPage;
                currentPage = page;

                if (fromPage)
                    setTimeout(slidePages, 0, fromPage, page, backwards);
                else
                    updatePage(page, fromPage);
            }
        }
    },

    showPageById: function(pageId, bw)
    {
	//console.log("showPageById: "+pageId);
		//waitDialog(true);
		var page = $(pageId);
        if (page)
        {
            var index = pageHistory.indexOf(pageId);
			var backwards = index != -1 || bw;
			if (backwards)
                pageHistory.splice(index, pageHistory.length);

            iui.showPage(page, backwards);
        }
		//waitDialog(false);
	},

    showPageByHref: function(href, args, method, replace, cb)
    {
	//console.log("showPageByHref: "+href, args, method, replace, cb);
        if (!replace)
			waitDialog(true);
			
		var req = new XMLHttpRequest();
        req.onerror = function()
        {
			//console.log("showPageByHref: ERROR ");
            if (cb)
                cb(false);
        };

        req.onreadystatechange = function()
        {
            if (req.readyState == 4)
            {
                if (replace)
                    replaceElementWithSource(replace, req.responseText);
				else
                {
					var frag = document.createElement("div");
                    frag.innerHTML = req.responseText;
                    iui.insertPages(frag.childNodes);
				}
                if (cb)
                    setTimeout(cb, 1000, true);
				
				waitDialog(false);
            }
        };

        if (args)
        {
            if (method == "POST")
				req.open(method, href, true);				
			else
				req.open(method, href+"?"+args.join("&"), true);				
			
            //req.open("POST", href + "?" + args.join("&"), true);
            req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            req.setRequestHeader("Content-Length", args.length);
            req.send(args.join("&"));
		}
        else
        {
            req.open(method || "GET", href, true);
            req.send(null);
        }        
	},
	// iVDR function Outsourcing
	showPageByHash: function(hash, bw)
	{
		//waitDialog(true);
		//console.log("showPageByHash: "+hash);
		var id = $(hash);
		id.setAttribute('selected', 'true');
		iui.showPage(id, bw);
		setTimeout(id.removeAttribute('selected'), 500);
		//waitDialog(false);
	},
    
    insertPages: function(nodes)
    {
        var targetPage;
			//console.log("insertPages: "+nodes.length);
        for (var i = 0; i < nodes.length; ++i)
        {
            var child = nodes[i];
            if (child.nodeType == 1)
            {
                if (!child.id)
                    child.id = "__" + (++newPageCount) + "__";

                var clone = $(child.id);
                if (clone)
                    clone.parentNode.replaceChild(child, clone);
                else
                    document.body.appendChild(child);

                if (child.getAttribute("selected") == "true" || !targetPage)
                    targetPage = child;
                
                --i;
            }
        }

        if (targetPage)
            iui.showPage(targetPage);    
    },

    getSelectedPage: function()
    {
	//console.log("getSelectedPage");
        for (var child = document.body.firstChild; child; child = child.nextSibling)
        {
            if (child.nodeType == 1 && child.getAttribute("selected") == "true")
                return child;
        }    
    },
    // iVDR preSelect
	getPrePages: function()
    {
        var childs = [];
		for (var child = document.body.firstChild; child; child = child.nextSibling)
        {
            if (child.nodeType == 1 && child.getAttribute("selected") == "pre") {
				child.removeAttribute("selected");
				childs.push(child.id);
			}
        }
		return childs;
    },  

	refreshPage: function() {
		waitDialog(true);
		page = iui.getSelectedPage();
		if(page) 
				iui.showPageByHref(page.getAttribute("tag"));
	}
	
};

// *************************************************************************************************

addEventListener("load", function(event)
{
//getmeenv("Load Anfang");
//console.log("Event Load: "+event);
		//* iVDR preselect
		var prepages = iui.getPrePages();
		if (prepages) {
			var d=1;
			for (var i = 0; i < prepages.length; ++i) {
				pageHistory.splice(pageHistory.length-d--, 0, prepages[i]);	
				pageLocationHistory.splice(pageHistory.length-d--, 0, 1);	
				location.hash = hashPrefix + prepages[i]; //, 1000;  // whats this
				scrollTo(0,1);
			}
		}
		
		var page = iui.getSelectedPage();

		if (page)
	        iui.showPage(page);
	    setTimeout(preloadImages, 0);
	    setTimeout(checkOrientAndLocation, 0);
	    checkTimer = setInterval(checkOrientAndLocation, 300);
	    
		//* iVDR deactivate Rotation ScrollUp
		setTimeout(scrollTo, 100, 0, 1);

//getmeenv("Load Ende");
		
}, false);
    
addEventListener("click", function(event)
{
    var link = findParent(event.target, "a");
	if (link)
    {
		//iVDR same Frame return
		currentLocation = window.pageYOffset;
		//console.log("EventListener Click:"+link+" - "+link.hash);
        function unselect() { link.removeAttribute("selected"); }
        if (link.href && link.hash && link.hash != "#")
        {
			//iui.showPageByHash(link.hash.substr(1));
			link.setAttribute("selected", "true");
			iui.showPage($(link.hash.substr(1)));
            setTimeout(unselect, 500);
        }
        else if (link == $("backButton")) 
            history.back();
        else if (link.getAttribute("type") == "submit")
            submitForm(findParent(link, "form"));
        else if (link.getAttribute("type") == "cancel")
            cancelDialog(findParent(link, "form"));
        else if (link.target == "_replace")
        {
			link.setAttribute("selected", "progress");
            iui.showPageByHref(link.href, null, null, link, unselect);
        }
        else if (link.target == "_js")
			doJSByHref(link.href);
        else if (!link.target && link.href)
        {
            link.setAttribute("selected", "progress");
            iui.showPageByHref(link.href, null, null, null, unselect);
        }
        else
			return;

		event.preventDefault();        
    }
}, true);

addEventListener("click", function(event)
{
	var div = findParent(event.target, "div");
    if (div && hasClass(div, "toggle"))
    {
        div.setAttribute("toggled", div.getAttribute("toggled") != "true");
        event.preventDefault();        
    }
}, true);

addEventListener("click", function(event) {
	var li = findParent(event.target, "li");
	if (li) 
		activeLi = li;
//	alert(activeLi.innerHTML);
}, true);
//document.addEventListener('touchend', loadPictures, false);

function loadPictures(partial) 
{ 
	if (activepicload) return true;
	else activepicload = true;
	if (! currentPage) return false; 
	if (! currentPage.getAttribute('afterPictures')) return false; 
	for (var i in currentPage.childNodes) { 
			var li = currentPage.childNodes[i]; 
			if (li.nodeName != "LI") continue; 
			var link = li.getAttribute('afterPicture');
			if (! link) continue; 
			var off=currentPage.offsetTop+li.offsetTop; 
			if (off > window.pageYOffset+window.innerHeight && partial) break; 
			if (off+li.height < window.pageYOffset && partial) continue;            

			var nds = li.getElementsByTagName("img");
			nds[0].src = link; 
			li.removeAttribute('afterPicture'); 			
	}
	return false;
} 

// Left and Right Drag to switch to common page
/* document.addEventListener('touchstart', function(e) 
{
tse[0]=e.targetTouches[0].pageX;
tse[1]=e.targetTouches[0].pageY;
} , false); 
document.addEventListener('touchmove', function(e) 
{ 
tee[0]=e.targetTouches[0].pageX;
tee[1]=e.targetTouches[0].pageY;
} , false); 
document.addEventListener('touchend', function(e) 
{ 
//console.log("hor: "+(tse[0]-tee[0])+" ver"+(tse[1]-tee[1])+"  "+Math.abs(tse[1]-tee[1]));

//if ((tee[0]-tse[0]) > 170 && Math.abs(tse[1]-tee[1]) < 20)
//	history.back();

if ((tse[0]-tee[0]) > 170 && Math.abs(tse[1]-tee[1]) < 20)
	location.href = ivdr+"?REMOTE";
	
} , false); 
 */
 
function checkOrientAndLocation()
{
    if (window.innerWidth != currentWidth)
    {   
        //* iVDR deactivate Rotation ScrollUp
		//if (currentWidth != 0)
		//	setTimeout(scrollBy, 100, 0,  window.innerWidth == 480 ? -75 : 75);    

		currentWidth = window.innerWidth;
        /*var orient = currentWidth == 320 ? "profile" : "landscape";
        document.body.setAttribute("orient", orient);*/
	
		if (currentPage.getAttribute('scroll'))
			createScrollBar(currentPage);

	}
	
	if (currentYOffset != window.pageYOffset)
    {  
		currentYOffset = window.pageYOffset;
		if (touchDevice)
			activepicload = loadPictures(touchDevice);
	}
	
    if (decodeURI(location.hash) != currentHash)
    {
        var pageId = location.hash.substr(hashPrefix.length)
		iui.showPageById(pageId, location.hash == "#_main");
	}
}

function showDialog(page)
{
    currentDialog = page;
    // iVDR special  let dialog show at windowposition
	if (window.pageYOffset < 1)
		window.scrollTo(0,1);
	page.style.top = window.pageYOffset + "px";
	//page.style.opacity = "0";
	// -------
	
	page.style.height = Math.min(window.innerHeight,500)+"px";

	page.setAttribute("selected", "true");
    if (hasClass(page, "dialog") && !page.target)
	   showForm(page);
    
	// iVDR fade in Effect
	//   var show = window.setInterval(function() {
	//	page.style.opacity = "100";
	//	window.clearInterval(show);
	//}, 100);
}

function showForm(form)
{
    form.onsubmit = function(event)
    {
        event.preventDefault();
        submitForm(form);
    };
    
    form.onclick = function(event)
    {
        if (event.target == form && hasClass(form, "dialog"))
            cancelDialog(form);
    };
}


function cancelDialog(form)
{
	//form.style.opacity = "0";
    // iVDR fade out Effect
	//var hide = window.setInterval(function() {
			form.removeAttribute("selected");
	//		window.clearInterval(hide);
	//	}, 600);

}


function updatePage(page, fromPage, down, noHistory)
{
//console.log("updatePage: "+page+" id: "+page.id);
//console.log("updatePage from: "+fromPage ||""+" id: "+fromPage.id|| "");
	if (!page.id)
        page.id = "__" + (++newPageCount) + "__";

    location.href = currentHash = hashPrefix + page.id;

//console.log("noHistory: "+noHistory);
    if (!noHistory) 
		pageHistory.push(page.id);

	//* iVDR pageLocationHistory
	
	if (pageHistory.length > 2)
		$('backicon').style.display = "inline";
	else
		$('backicon').style.display = "none";
	
	
	if (page.id != "main" && down) // && window.pageYOffset == 1) 
		{
		//console.log(page.id+"!=main &&"+down);
		setTimeout(scrollTo, 300, 0, down);
		}

		
    var pageTitle = $("pageTitle");
    if (page.title)
        pageTitle.innerHTML = page.title;

    if (page.localName.toLowerCase() == "form" && !page.target)
        showForm(page);

        
    var backButton = $("backButton");
	if (backButton)
    {
        var prevPage = $(pageHistory[pageHistory.length-2]);
		if (prevPage && !page.getAttribute("hideBackButton"))
        {
            backButton.style.display = "inline";
            backButton.innerHTML = prevPage.title ? prevPage.title : "Back";
        }
        else
            backButton.style.display = "none";
    }
    
	if (page.getAttribute('scroll'))
		createScrollBar(page)

	if (page.getAttribute('dynamicnode')) 
		updateNodes(page)
	
	kb().style.height=document.height+'px';
	
	activepicload = loadPictures(touchDevice);
	
}

function updateNodes(page) {
	var nd = page.getAttribute('dynamicnode').split(/ /);
	//nd.innerHTML = "Lade";
	
	for (var n in nd) { 
	  if ($(nd[n])) {
		if ($(nd[n]).getAttribute('tag')) 
			iui.showPageByHref($(nd[n]).getAttribute('tag'), null,null, $(nd[n]));
	  }
	}
}

function createScrollBar(page) {
	
	var sb; 
	var st;
	var scrollArray = [];
	var scrollPos = 0;
	var view = (page.getAttribute('scroll').toLowerCase() == "view");

	for (var i in currentPage.childNodes) {
		if (currentPage.childNodes[i].id == "scrollBar")
			sb = currentPage.childNodes[i];
		if (currentPage.childNodes[i].id == "scrollBarText")
			st = currentPage.childNodes[i];
		if (sb && st)
			break;
	}
	
	for (var li in currentPage.childNodes) {
		var ch = currentPage.childNodes[li];
		if ((ch.nodeName == "LI" || ch.nodeName == "H2") && ch.id) {
				scrollArray.push(ch);
			}
	}
	
	if (scrollArray.length < 2)
		return;
	
	if (! st) {
		st = document.createElement("div");
		st.id = 'scrollBarText';
		st.style.display='none';

		var t = [];
		for ( var id in scrollArray) {
			t.push((scrollArray[id].title || scrollArray[id].id));
		}
		st.innerHTML = t.join("<br>");
		
		page.appendChild(st);
	}
	
	st.style.height = window.innerHeight+"px";
	st.style.fontSize = Math.min(22, Math.max(9, (window.innerHeight - scrollArray.length*3) / scrollArray.length))+"px";
	st.style.lineHeight = window.innerHeight / scrollArray.length+"px";

	if (! sb) {
		sb = document.createElement("div");
		sb.id = 'scrollBar';
		
		page.appendChild(sb);
	}

	if (view) {
		sb.addEventListener('touchstart', function(e) { st.style.display='block'; st.style.top = window.pageYOffset-45+"px"; } , false); 
		sb.addEventListener('touchend', function(e) { st.style.display='none'; } , false); 
	}

	sb.addEventListener('touchmove', function(e) { e.preventDefault() } , false); 
	sb.addEventListener('touchmove', function(e) 
	{
		var barHeight = Math.floor(window.innerHeight / scrollArray.length) * scrollArray.length;
		var div = barHeight / scrollArray.length;
		var pos = Math.floor((e.targetTouches[0].pageY-window.pageYOffset) / div);
		if (scrollPos != pos && pos >= 0 && pos < scrollArray.length) {
			scrollPos = pos;
			var g = Math.min(page.offsetHeight - window.innerHeight, scrollArray[pos].offsetTop);
			if (view)
				st.style.top = g+"px";
			
			window.scrollTo(0,g+45);
		}			
	}, false);
}

function clonePage(a,b){ 
        var c=a.cloneNode(true); 
        c.style.position="absolute"; 
        c.style.left=b; 
        c.style.top=a.offsetTop+"px"; 
        c.style.width="100%"; 
        c.setAttribute("selected", "true"); 
        document.body.appendChild(c); 
        return c 
} 

function slidePages(fromPage, toPage, backwards) { 
//		console.log("slidePages: "+fromPage.id+" -> "+toPage.id);
		var scrollbug = 1;
	if (backwards) { 
		//* iVDR pageLocationHistory
		var down = pageLocationHistory[pageLocationHistory.length-1];
		scrollbug = down;
		pageLocationHistory.pop();

		if (Slide){
			slidePagesGauche(fromPage, toPage, down); 
			//console.log(typeof toPage)
		}
		else 
		{
			toPage.setAttribute("selected", "true");
			fromPage.removeAttribute("selected");
			setTimeout(updatePage, 100, toPage, fromPage, down);
		}
		if (fromPage) {
			var attrtemp = fromPage.getAttribute("temporary");
			if (attrtemp) { 
				if (attrtemp.toLowerCase() == "yes") {
					// !!!!!!!! geht bei scroll nicht
					// problem nicht angezeigte haben kein parentNode
					// !!!!!!!! wenn direkt zu main gegangen wird, wird nur das jetzige gelöscht, evtl generell alle suchen
					fromPage.parentNode.removeChild(fromPage);
				}
				//else if (attrtemp.toLowerCase() == "all") {
					// erst wenn toPage kein temporary hat
					//if (! toPage.getAttribute('temporary')) {
					//	for (var i in document.getElementsByTagName("UL")) {
					//	var tag = document.getElementsByTagName("UL")[i]
					//	if (tag) {
					//	if (tag.getAttribute('temporary')) {
					//		if (tag.getAttribute('temporary').toLowerCase() == 'all') {
					//			console.log(document.getElementsByTagName("UL")[i].id);
					//			tag.parentNode.removeChild(fromPage);
					//		}
					//	}
					//	}
					//	}
					// }
					// !!!!!!!alert("OK muss noch!");
					// search in all elements for 
					// }
			}
		}
		
	}
	else {
		//* iVDR pageLocationHistory
		//console.log("location: "+window.pageYOffset);
		//console.log("location history: "+pageLocationHistory.join(" - "));

		
		if (toPage.id != fromPage.id) { 
			pageLocationHistory.push(window.pageYOffset);
			if (Slide)
				slidePagesDroite(fromPage, toPage); 
			else {
				toPage.setAttribute("selected", "true");
				fromPage.removeAttribute("selected");
				setTimeout(updatePage, 100, toPage, fromPage, 1, toPage.id == fromPage.id);
				scrollbug = 1;
//				scrollTo(0,1);
			}
		}
		else 
		{
			toPage.setAttribute("selected", "true");
			fromPage.removeAttribute("selected");
			setTimeout(updatePage, 100, toPage, fromPage, currentLocation, toPage.id == fromPage.id);
			scrollbug = currentLocation;
			//scrollTo(0,currentLocation);
			//setTimeout(scrollTo(0,currentLocation);
		}
	}
//scrollTo(0,scrollbug);
}

function slidePagesDroite(fromPage, toPage) 
{ 
        var h=window.innerWidth; 
    toPage.style.left = "100%"; 
    toPage.setAttribute("selected", "true"); 
        scrollTo(0,1); 
    clearInterval(checkTimer); 
    var percent = 100; 
        slideSpeed = slideBase; 
    var timer = setInterval(function() { 
                if (percent >= 33) slideSpeed += slideInc; 
                else {slideSpeed -= 1.6*slideInc; 
                if (slideSpeed <= 1) 
                slideSpeed = 1}; 
        percent -= slideSpeed; 
        if (percent <= 0) 
        { 
            percent = 0; 
            clearInterval(timer); 
                        scrollTo((100-percent)/100*h ,1); 
                fromPage.removeAttribute("selected"); 
                                var c=clonePage(toPage, h+"px"); 
                                toPage.style.left="0px"; 
                                var t=0; 
                                var truc=setInterval(function(){if(t>0) { 
                                        scrollTo(0,1); 
                                        document.body.removeChild(c); 
                                        clearInterval(truc); 
                                }t++;}, 10); 
                    checkTimer = setInterval(checkOrientAndLocation, 300); 
                setTimeout(updatePage, 0, toPage, fromPage); 
                                return; 
        } 
                scrollTo((100-percent)/100*h ,1); 
    }, slideInterval); 


} 

function slidePagesGauche(fromPage, toPage, down) 
{ 
		var h=window.innerWidth; 
        var c=clonePage(fromPage, h+"px"); 
        scrollTo(h, 1); 
    toPage.style.left ="0px"; 
    toPage.setAttribute("selected", "true"); 
        document.body.removeChild(fromPage); 
    clearInterval(checkTimer); 
    var percent = 100; 
        slideSpeed = slideBase; 
    var timer = setInterval(function() { 
                if (percent >= 33) slideSpeed += slideInc; 
                else {slideSpeed -= 1.6*slideInc; 
                if (slideSpeed <= 1) 
                slideSpeed = 1}; 
                if (slideSpeed == 0.002) slideSpeed=3; 
                if (slideSpeed == 0.001) slideSpeed=0.002; 
                if (slideSpeed == 1.5) slideSpeed=0.001; 

        percent -= slideSpeed; 
        if (percent <= 0) 
        { 
            percent = 0; 
            clearInterval(timer); 
                        scrollTo(percent/100*h ,1); 
                        c.removeAttribute("selected"); 
                        checkTimer = setInterval(checkOrientAndLocation, 300); 
            setTimeout(updatePage, 0, toPage, fromPage, down); 


        } 
                scrollTo(h*percent/100 ,1); 
    }, slideInterval); 


} 

function preloadImages()
{
    var preloader = document.createElement("div");
    preloader.id = "preloader";
    document.body.appendChild(preloader);
}

function submitForm(form)
{
	iui.showPageByHref(form.action || "POST", encodeForm(form), form.method);
}
//submitForm(this);
function encodeForm(form)
{
    function encode(inputs)
    {
        for (var i = 0; i < inputs.length; ++i)
        {
			var inp = inputs[i];
			if (inp.name) {
				if (inp.getAttribute('multiple') != null) {
					for (var d = 0; d < inp.length; ++d) {
						if(inp[d].selected) {
						  if (utf8)
							args.push(inp.name + "=" + encodeURI(inp[d].value));
						  else
							args.push(inp.name + "=" + escape(inp[d].value));
						}
					}
				} else {
				  if (utf8)
					args.push(inp.name + "=" + encodeURI(inp.value));
				  else
					args.push(inp.name + "=" + escape(inp.value));
				}
            }
        }
    }

    var args = [];
    encode(form.getElementsByTagName("input"));
    encode(form.getElementsByTagName("select"));
	return args;    
}

function findParent(node, localName)
{
    while (node && (node.nodeType != 1 || node.localName.toLowerCase() != localName))
        node = node.parentNode;
    return node;
}

function hasClass(ele,cls) { return ele.className.match(new RegExp('(\\s|^)'+cls+'(\\s|$)')); }
function addClass(ele,cls) { if (!this.hasClass(ele,cls)) ele.className += " "+cls; }
function removeClass(ele,cls) { if (hasClass(ele,cls)) { var reg = new RegExp('(\\s|^)'+cls+'(\\s|$)'); ele.className=ele.className.replace(reg,' '); } }

function replaceElementWithSource(replace, source)
{
    var page = replace.parentNode;
    var parent = replace;
    while (page.parentNode != document.body)
    {
        page = page.parentNode;
        parent = parent.parentNode;
    }

    var frag = document.createElement(parent.localName);
    frag.innerHTML = source;

	// iVDR replace Correction
    //page.removeChild(parent);
	 //   while (frag.firstChild)
	//        page.appendChild(frag.firstChild);

    while (frag.firstChild)
		page.insertBefore(frag.firstChild, parent);
	
	page.removeChild(parent);
}

function $(id) { return document.getElementById(id); }
function ddd() { console.log.apply(console, arguments); }
function bf()  { if (! btnfrm) btnfrm = $('buttonsForm'); return btnfrm; }
function wd()  { if (! wdlg) wdlg = $('dlg_wait'); return wdlg; }
function kb()  { if (! kbar) kbar = $('keyBar'); return kbar; }
function kf()  { if (! kform) kform = $('keysform'); return kform; }
function isObject(o) {return (o && "object" == typeof o) }   
function isArray(o) {return isObject(o) && o.constructor == Array;}  

//function bf()  { if (! btnfrm) btnfrm = $('buttonsForm'); return btnfrm; }


//iVDR Globalisierung
//})();

//* iVDR CODE

function toggle(myDiv, myCheckbox, trueval, falseval)
{
	if (myDiv.getAttribute('id')) {
		
		for (var chlds in myDiv.childNodes) {
			//var myCheckbox = document.getElementsByName(myCheckbox)[0];
			var myCheckbox = myDiv.childNodes[chlds];
			
			if (typeof myDiv.childNodes[chlds] == "object") {
			if (myCheckbox) {
			if (myCheckbox.getAttribute('type') == 'hidden') {
				if (myDiv.getAttribute('toggled') == 'true')
					myCheckbox.value = trueval;
				else
					myCheckbox.value = falseval;
			}
			}
			}
		}
	}
}
	
function toggleDiv(myDiv, targetDiv)
{
	if (myDiv.getAttribute('id')) {
		if (targetDiv) {
			if (myDiv.getAttribute('toggled') == 'true')
				showElement(targetDiv);
			else
				hideElement(targetDiv);
		}
	}
}

// Wie Optionbox. Eins pro liste angeklickt. n.n.
/*function toggleChecked(myID) {
var childs = findParent($(myID),"fieldset").getElementsByTagName("div");
	for (var inner in childs) {
		if(childs[inner].nodeType == 1) 
			childs[inner].setAttribute('class', 'row');
	}
$(myID).setAttribute('class', 'row checked');
}
*/

function fillElementByHref(href, id, cb) {
			//waitDialog(true);
			var jsreq = new XMLHttpRequest();
	        jsreq.onreadystatechange = function()
	        {

			if (jsreq.readyState == 4) 
				{
					
					id.innerHTML = jsreq.responseText;
					//eval(jsreq.responseText);

					if (cb) 
						cb(true);
				
					//waitDialog(false);
				}
			}
			
			
			jsreq.open("GET", href, true);
            jsreq.send(null);
}

function doJSByHref(href, cb) {
			waitDialog(true);
			var jsreq = new XMLHttpRequest();
	        jsreq.onreadystatechange = function()
	        {

			if (jsreq.readyState == 4) 
				{
					eval(jsreq.responseText);

					if (cb) 
						cb(true);
				
					waitDialog(false);
				}
			}
			
			
			jsreq.open("GET", href, true);
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

function hideElement(elmnt) { $(elmnt).style.display = "none"; }
function showElement(elmnt) { $(elmnt).style.display = "block"; }

function deleteHistory(root, curr) { 
	pageHistory=[];
	pageLocationHistory=[];
	if (root) {
		clearInterval(checkTimer); 
		currentPage.removeAttribute("selected");

		currentPage = $(root);
		currentHash = hashPrefix+root;
		location.hash = hashPrefix+root;
		pageHistory=[root];
	}
}

function unCheck() {
	var elmnts = document.getElementsByName("record");
	for (var i = 0; i < elmnts.length; ++i) {
		if (elmnts[i].getAttribute("checked"))
			elmnts[i].removeAttribute("checked");
			elmnts[i].style.backgroundColor = "";
	}
}

function recBar(show) {
	
	for (var rot in document.getElementsByName('recoptiontoggle') )
		if (rot < document.getElementsByName('recoptiontoggle').length) document.getElementsByName('recoptiontoggle')[rot].style.display = (show) ? "none" : "block";

	for (var ro in document.getElementsByName('recoption') )
		if (ro < document.getElementsByName('recoptiontoggle').length) document.getElementsByName('recoption')[ro].style.display = (show) ? "block" : "none";

		//item.style.display = "block";
//		item.style.display = (show) ? "none" : "block";;
}

	function button(value, href, onclick, question, target, image) {
		this.value = value;
		this.href = href;
		this.onclick = onclick;
		this.question = question;
		this.target = target;
		this.image = image;
	}
	
	function dialog(title, rec, cntrl, topright, stars, buttons) {
		//this.red = red;		this.green = green;		this.yellow = yellow;		this.blue = blue;		this.topleft = topleft;		this.topright = topright;		this.red2 = red2;		this.green2 = green2;		this.yellow2 = yellow2;		this.blue2 = blue2;
		// set Dialog Values
		
		this.activePageNo = 1;
		this.toggle = function() { 
			if (this.activePageNo * 4 >= buttons.length) 
				this.activePageNo = 1;
			else
				this.activePageNo += 1;
			setDialogButtons(this);
		}
		this.show = function() { 
			var self = bf();
			////self.addEventListener('touchmove', function(e) { e.preventDefault(); }, false); 
			setDialog();
			setDialogButtons(this);
			showDialog(self)
		}
	
		function setDialog() {
				
			$('headline').innerHTML = title;
			$('morebtn').style.display = "none";
			$('selectField').style.display = "none";
			$('epginfobar').style.display = "none";
			$('moviebtn').style.display = "none";
			$('toprightbtn').style.display = "none";
			$('epginfobar').innerHTML = "";
			$('timebardiv').style.display = "none";
			
			
			// console.log(buttons.length);
			if (buttons.length > 100)
				{ $('morebtn').style.display = "block"; }
			if (rec)
				{ $('recbtns').style.display = 'block'; }
			else
				{ $('recbtns').style.display = 'none'; }
			if (cntrl)
				{ $('cntrlbtns').style.display = 'block'; }
			else 
				{ $('cntrlbtns').style.display = 'none'; }

			
			if (stars != null) {
			if (stars[0] != null)
				{ 
					$('moviebtn').style.height = "110px"; 
					$('rateStars').style.display = 'block';
					var div = $('rateStars').childNodes;
					for (var nds in div) {
						if (div[nds].nodeType == 1) {
							if (div[nds].getAttribute('tag') != null)
								div[nds].onclick = new Function(
									"dialogStars(this.getAttribute('tag'), '"+stars[1]+"');" );
						}
					}
					dialogStars(stars[0]);
				}
			else 
				{ $('rateStars').style.display = "none"; $('moviebtn').style.height = "210px"; }
				}
			else 
				{ $('rateStars').style.display = "none"; $('moviebtn').style.height = "210px"; }
			
		}
		
		function setDialogButtons(dlg, fade) {
			var btns;
			$('btnsarea').innerHTML = "";
			
			if (dlg.activePageNo == 1)
				//btns = new Array(buttons[0], buttons[1], buttons[2], buttons[3], buttons[4], buttons[5], buttons[6], buttons[7], buttons[8]);
				btns = buttons;
			else {
				var i = (dlg.activePageNo - 1) * 8;
				btns = new Array(buttons[i], buttons[++i], buttons[++i], buttons[++i]);
				}
			
				for (var i = 0; i <= btns.length-1; i++) {
				var newbtn = document.createElement("a");
				newbtn.className = 'dialogbutton';
				var act = $('btnsarea').appendChild(newbtn);
				
				if (btns[i]) {
					
					act.innerHTML = "<img src='"+btns[i].image+"' /><br>"+btns[i].value;
					
//					if (btns[i].href) act.setAttribute("href", btns[i].href); 
					if (btns[i].href) act.setAttribute("href", encodeURI(btns[i].href)); 
						else act.removeAttribute("href");
//						else act.setAttribute("href", "");
					if (btns[i].target) act.setAttribute("target", btns[i].target)
						else act.removeAttribute("target");
					if (btns[i].onclick) {
						var string;
						if (btns[i].question)
							string = "if(confirm(\"" + btns[i].question + "\")) {" + btns[i].onclick + "}";
						else 
							string = btns[i].onclick;

						act.setAttribute("onclick", string);
					}
					else act.removeAttribute("onclick");
				}
				else
					act.style.display = 'none';
				}
		}
	}
	
// button(value, href, onclick, question, target)
var oDialog;
// [Kanalnummer][Event_ID|NOEPG][optional Ursprung NOW|NEXT|SCHED|SEARCH|AT] 
// Achtung immer 4 voll machen sonst stehen Userbuttons an unterschiedlichen stellen
//doJSByHref('"+ivdr+"?NEWTIMER+"+chanID+"+"+eventID+"+'+dir, iui.refreshPage())
	function epgDialog(chanID, eventID, title, source, starttime) {
		var btns = new Array(
			(mpplay)
			? new button(lp_SWITCH, ivdr+"?cmdat+"+starttime+"+CHAN+"+chanID+"|MESG+iVDR SWITCH: "+title, "cancelDialog(bf());", null, "_js", www+"/btn_start.png")
			: new button(lp_PLAY, ivdr+"?mpplay+CHAN+"+chanID, null, null, "_js", www+"/btn_start.png"),
//			new button(lp_PLAY, null, "SimpleHttpRequest('ok');", null, null, www+"/btn_stream.png"),
			(eventID != "NOEPG") ? new button(lp_REPLAY, ivdr+"?REPLAY+"+chanID+"+"+eventID, null, null, null, www+"/btn_search.png") : null,
			(eventID != "NOEPG") ? new button(lp_RECORD, null, "var dir = prompt('"+lp_PREFIX+"','"+recprefix+"'); if (dir != null) {cancelDialog(bf()); doJSByHref('"+ivdr+"?NEWTIMER+"+chanID+"+"+eventID+"+'+dir, iui.refreshPage)}", null, null, www+"/btn_save.png") : null,
			(source == "NOW") ? stream && new button(lp_STREAM, null, "$('btnsarea').innerHTML = ''; if (confirm('"+lp_STARTNOW+"')) doJSByHref(ivdr+'?stream=dialog&type=live&id="+chanID+"'); else doJSByHref(ivdr+'?stream=live&id="+chanID+"');", null, null, www+"/btn_show.png") : null,
			(eventID != "NOEPG") ? new button("epgSearch", ivdr+"?EPGSEARCHFIELD+new+"+title+"+"+chanID, null, null, "_changewindow", www+"/btn_epgs.png" ) : null,
			(source != "SCHED") ? new button(lp_SCHED, ivdr+"?CHANINFO+"+chanID, null, null, null, www+"/btn_sched.png") : null,
			(eventID != "NOEPG") ?new button(lp_INFO, null, '$("epginfobar").style.display = "block"', null, null, www+"/btn_info.png") : null
			//new button(lp_STREAM, ivdr+"?STREAMFORM+streamdev+"+chanID, null, null, "_changewindow"),
			//(source == "NOW") ? new button(lp_STREAM, null, "$('greenbtn').style.display = 'none'; doJSByHref(sn+'stream=live&id="+chanID+"');") : null,
			);
			for (var i = 0; i < usercontrol.length; i++)
				btns.push(usercontrol[i]);
		
		oDialog = new dialog(title, null, null, null, null, btns);
		
		oDialog.show();
		fillElementByHref(ivdr+'?EPGINFOFIELD+'+chanID+'+'+eventID+'+1', $('epginfobar'));
	}	
	function recDialog(recID, actHash, me, recName, sortType, sequence) {
		if (multiselect) {
			if (me.getAttribute("checked")) {
				me.style.backgroundColor = "";
				me.removeAttribute("checked");
			}
			else {
				me.style.backgroundColor = "#D0E0FF";
				me.setAttribute("checked", "true");
			}
		}
		else {
			var btns = new Array(			
				(mpplay) ?
				new button(lp_BEGIN, ivdr+"?cmd+PLAY+"+recID+"+begin", null, null, null, www+"/btn_start.png") : null, 
				(mpplay)
				? new button(lp_RESUME, ivdr+"?cmd+PLAY+"+recID, null, null, null, www+"/btn_play.png")
				: new button(lp_PLAY, ivdr+"?mpplay+REC+"+recID, null, null, null, www+"/btn_start.png"),
				stream && new button(lp_STREAM, null, "$('btnsarea').innerHTML = ''; if (confirm('"+lp_STARTNOW+"')) doJSByHref(ivdr+'?stream=dialog&type=rec&id="+recID+"'); else doJSByHref(ivdr+'?stream=rec&id="+recID+"');", null, null, www+"/btn_show.png"),
				new button(lp_REPLAY, ivdr+"?REPLAY+"+recID, null, null, null, www+"/btn_search.png"),
				new button(lp_RENAME, null, "var name = prompt('"+lp_RENAME+"', '"+recName+"'); if (name) { iui.showPageByHref('"+ivdr+"?REC=RENR&hs="+actHash+"&st="+sortType+"&sq="+sequence+"&ID="+recID+"&STRING='+name); }", null, null, www+"/btn_edit.png" ),
				new button(lp_MOVE, ivdr+"?MOVE+"+recID, null, null, "_js", www+"/btn_folder.png"), 
				new button(lp_REMOVE, null, "cancelDialog(bf()); unCheck(); iui.showPageByHref('"+ivdr+"?REC=DELM&IDS="+recID+"&hs="+actHash+"&st="+sortType+"&sq="+sequence+"')", lp_DELREC, null, www+"/btn_trash.png"),
				new button(lp_INFO, null, '$("epginfobar").style.display = "block"', null, null, www+"/btn_info.png")
				//				new button(lp_STREAM, ivdr+"?RECINFOFIELD+"+recID, null, null, "_changewindow"),
				//new button(lp_STREAM, null, "$('greenbtn').style.display = 'none'; doJSByHref(sn+'stream=rec&id="+recID+"');"),
				);
				for (var i = 0; i < usercontrol.length; i++)
					btns.push(usercontrol[i]);
			
			oDialog = new dialog(recName || lp_RECORDS, true, null, null, null, btns	);
			oDialog.show();
			fillElementByHref(ivdr+'?RECINFOFIELD+'+recID+'+1', $('epginfobar')); 
		}
	}
	function timDialog(timerID, channelID, eventID, refresh) {
		var btns = new Array(			
			new button(lp_ON+"/"+lp_OFF, null, "cancelDialog(bf()); iui.showPageByHref('"+ivdr+"?TIMER+ONOFF+"+timerID+"');", null, null, www+"/btn_switch.png"),
			new button(lp_EDIT, ivdr+"?TINFO+"+timerID+"+Bearbeiten", null, null, "_changewindow", www+"/btn_edit.png"),
			(channelID != "NOEPG") ? new button(lp_REPLAY, ivdr+"?REPLAY+"+channelID+"+"+eventID, null, null, null, www+"/btn_search.png") : null,
			new button(lp_REMOVE, null, "cancelDialog(bf()); iui.showPageByHref('"+ivdr+"?TIMER+DELT+"+timerID+"')", lp_DELTIMER, null, www+"/btn_trash.png")
			);
			for (var i = 0; i < usercontrol.length; i++)
				btns.push(usercontrol[i]);
		
		oDialog = new dialog(lp_TIMER, null, null,
			new button(lp_INFO, null, '$("epginfobar").style.display = "block"'),
			 null, btns );
		oDialog.show();
		fillElementByHref(ivdr+'?EPGINFOFIELD+'+channelID+'+'+eventID+'+1', $('epginfobar')); 
	}
	function espDialog(epgsID, epgsName) {
		var btns = new Array(			
			new button(lp_ON+"/"+lp_OFF, null, "cancelDialog(bf()); iui.showPageByHref('"+ivdr+"?EPGSEARCH+ONOFF+"+epgsID+"');", null, null, www+"/btn_switch.png"),
			new button(lp_EDIT, ivdr+"?EPGSEARCHFIELD+"+epgsID+"+Bearbeiten", null, null, "_changewindow", www+"/btn_edit.png"),
			new button(lp_DOSEARCH, ivdr+"?SEARCHRESULT+"+epgsID, null, null, null, www+"/btn_search.png"),
			new button(lp_REMOVE, null, "cancelDialog(bf()); iui.showPageByHref('"+ivdr+"?EPGSEARCH+DELS+"+epgsID+"')", lp_DELSEARCH, null, www+"/btn_trash.png")
			);
			for (var i = 0; i < usercontrol.length; i++)
				btns.push(usercontrol[i]);
		
		oDialog = new dialog(epgsName, null, null, null, null, btns );
		oDialog.show();
	}
	function chaDialog(chanID, chanName) {
		var btns = new Array(			
			(mpplay) 
			? new button(lp_SWITCH, ivdr+"?cmd+CHAN+"+chanID, "cancelDialog(bf());", null, null, www+"/btn_start.png")
			: new button(lp_PLAY, ivdr+"?mpplay+CHAN+"+chanID, null, null, "_js", www+"/btn_start.png"),
			new button(lp_SCHED, ivdr+"?CHANINFO+"+chanID+"+"+chanName, null, null, null, www+"/btn_sched.png"),
			stream && new button(lp_STREAM, null, "$('btnsarea').innerHTML = ''; if (confirm('"+lp_STARTNOW+"')) doJSByHref(ivdr+'?stream=dialog&type=live&id="+chanID+"'); else doJSByHref(ivdr+'?stream=live&id="+chanID+"');",null, null, www+"/btn_show.png"),
			new button(lp_RECORD, ivdr+"?TINFO+new+"+chanID+"+"+chanName, null, null, "_changewindow", www+"/btn_save.png")
//			new button(lp_STREAM, ivdr+"?STREAMFORM+streamdev+"+chanID, null, null, "_changewindow"),
//			new button(lp_STREAM, null, "$('greenbtn').style.display = 'none'; doJSByHref(sn+'stream=live&id="+chanID+"');"),
//window.open(\"/data/iphone/istreamdev/ram/session1/stream.m3u8\", \"_changewindow\")
//			new button(lp_STREAM, null, "doJSByHref(ivdr+'?js')"),
			);
			for (var i = 0; i < usercontrol.length; i++)
				btns.push(usercontrol[i]);
		
		oDialog = new dialog(chanName, null, null, null, null, btns);
		oDialog.show();
	}
	function mp3Dialog(name, id, add, play, starscount, calljs, parentul, marker) {
		// diesen code einfacher machen
		// soll eigentlich nur 

		// !!!!!!!!!!!!!!!!!!!!!! add und play sollte wenn nicht vorhanden aus parent ul gelesen werden werden
		// !!!!!!!!!!!!!!!!!!!!!! sonst steht in jedem element das selbe
		var start = "SimpleHttpRequest('"+sn;
		if (calljs)
			start = "doJSByHref('"+ivdr+"?";
		var end = "'); ";
		var all;
		var first=id;
		if (parentul) {
			first=first.replace(/id/, "first");

			if (! $(parentul)) {
				parentul=currentPage;
			}
		}
		//console.log(first);
		
		if (isArray(add)) 
			add = start+(add.join(end+start))+id+end;
		else if(add) { add = start+add+id+end }
		
		if (isArray(play)) {
			if (parentul)
				all = start+(play.join(end+start))+"&"+parentul.getAttribute('all')+first+end;
			play = start+(play.join(end+start))+id+end;
		} else if(play) { 
			if (parentul)
				all = start+play+"&"+parentul.getAttribute('all')+first+end;
			play = start+play+id+end;
		}


		//ddd(add);
		//ddd(play);
		//ddd(id);
		
		var btns = new Array( 
			parentul ? new button(lp_ALLFRMHER, null, all+"; cancelDialog(bf())", null, null, www+"/btn_play.png") : play ? new button(lp_PLAY,null, play+"; cancelDialog(bf())", null, null, www+"/btn_start.png") : null,
			add && new button(lp_ADD, null, add+"; cancelDialog(bf())", null, null, www+"/btn_add.png"),
			marker && new button(lp_MARK, null, "doJSByHref(ivdr+'?DATAMARKFILE+"+id+"'); cancelDialog(bf()); if (hasClass(activeLi, 'checked')) removeClass(activeLi, 'checked'); else addClass(activeLi, 'checked');", null, null, www+"/btn_mark.png"),
			stream && new button(lp_STREAM, null, "$('btnsarea').innerHTML = ''; if (confirm('"+lp_STARTNOW+"')) doJSByHref(ivdr+'?stream=dialog&type=media&id="+id+"'); else doJSByHref(ivdr+'?stream=media&id="+id+"');", null, null, www+"/btn_show.png"),
			new button(lp_OPEN, ivdr+"?media=play&file="+id, null, null, "_blank", www+"/btn_stream.png")
//			new button(lp_STREAM, null, "alert('not supported yet...')"),
//			new button(lp_PLAY,sn+"cmd+HITK+STOP"+"|"+action+id, "cancelDialog($('buttonsForm'))"),
//			new button(lp_INFO, null, "alert('not supported yet...')"),
//			new button(lp_ADD, sn+"cmd+"+action+id, "cancelDialog($('buttonsForm'))")
			);
			for (var i = 0; i < usercontrol.length; i++)
				btns.push(usercontrol[i]);

		oDialog = new dialog(name, null, true, 
		new button(lp_INFO, null, '$("epginfobar").style.display = "block"; fillElementByHref("'+ivdr+'?database=infofield'+id+'", $("epginfobar"));'),
		[starscount, id], btns );
		oDialog.show();
		
		//ivdr+"?media=play&file="+id
		$('moviebtn').src = ivdr+"?media=play&file="+id;
		$('moviebtn').style.display = 'block';
	}
/*		function mediaDialog(name, id, add, play, starscount) {

		var btns = new Array( 
			play ? new button(lp_PLAY,null, "doJSByHref('"+ivdr+"?mpctrl="+play+"&id="+id+"'); cancelDialog(bf())", null, null, www+"/btn_start.png") : null,
			add ? new button(lp_ADD, null, "doJSByHref('"+ivdr+"?mpctrl="+add+"&id="+id+"'); cancelDialog(bf())", null, null, www+"/btn_add.png") : null,
			new button(lp_MARK, ivdr+"?DATAMARKFILE+"+id, "cancelDialog(bf())", null, null, www+"/btn_mark.png"),
			new button(lp_STREAM, null, "$('btnsarea').innerHTML = ''; if (confirm('"+lp_STARTNOW+"')) doJSByHref(ivdr+'?stream=dialog&type=media&id="+id+"'); else doJSByHref(ivdr+'?stream=media&id="+id+"');", null, null, www+"/btn_show.png"),
			new button(lp_OPEN, ivdr+"?media=play&file="+id, null, null, "_changewindow", www+"/btn_stream.png")
//			new button(lp_STREAM, null, "alert('not supported yet...')"),
//			new button(lp_PLAY,ivdr+"?cmd+HITK+STOP"+"|"+action+id, "cancelDialog($('buttonsForm'))"),
//			new button(lp_INFO, null, "alert('not supported yet...')"),
//			new button(lp_ADD, ivdr+"?cmd+"+action+id, "cancelDialog($('buttonsForm'))")
			);
			for (var i = 0; i < usercontrol.length; i++)
				btns.push(usercontrol[i]);

		oDialog = new dialog(name, null, true, 
		new button(lp_INFO, null, '$("epginfobar").style.display = "block"; fillElementByHref("'+ivdr+'?database=infofield'+id+'", $("epginfobar"));'),
		[starscount, id], btns );
		oDialog.show();
	}*/
	function strDialog(dlgName, wwwurl, stream, onair) {

		var btns = new Array(                  
			new button(lp_SAVE, null, 'cancelDialog(bf()); var name = prompt("'+lp_ENTERNAME+'", "'+dlgName+'"); if (name) { doJSByHref(ivdr+"?stream=save&id='+stream+'&name="+name) }', null, null, www+"/btn_save.png"),
			new button(lp_OFF, null, 'cancelDialog(bf()); doJSByHref(ivdr+"?stream=stop&id='+stream+'")', null, null, www+"/btn_switch.png"),
			new button(lp_REMOVE, null, '$("activemedia").style.display = "none"; cancelDialog(bf()); doJSByHref(ivdr+"?stream=remove&id='+stream+'")', null, null, www+"/btn_cancel.png"),
			//new button(lp_STOPALL, null, 'cancelDialog(bf()); doJSByHref(ivdr+"?cmd+killffmpeg")', null, null, www+"/btn_stop.png"),
			new button(lp_OPEN,  wwwurl+stream+"/stream.m3u8", null, null, "_blank", www+"/btn_stream.png")
		);

			for (var i = 0; i < usercontrol.length; i++)
					btns.push(usercontrol[i]);

		oDialog = new dialog(dlgName, null, null, null, null, btns);
		$('activemedia').style.display = "block";
		$('activemedia').onclick = function() { strDialog(dlgName, wwwurl, stream, true) };
		oDialog.show();

		if (! onair) {
			$('moviebtn').src = wwwurl+stream+"/stream.m3u8";
		}
		$('moviebtn').style.display = 'block';
	}
//ivdr+"media=grab"
//'$("epginfobar").style.display = "block"; $("epginfobar").innerHTML = "<img width=\'100%\' src=\''+ivdr+'?media=grab\' />"'
	function ivdrDialog() {
		//$('keysform').style.display = "block";
		//oDialog = new dialog("iVDR", true, null, null, null, new Array());
		//oDialog = new dialog("iVDR", null, null, null,null, [null,new button("Grab TV", null, "if (confirm('Start directly?')) doJSByHref(sn+'stream=dialog&type=media&id=1'); else alert('So not')")], usercontrol);
		//oDialog.show();
		//$('epginfobar').style.display = "block";
		//$('epginfobar').innerHTML ="asfasf";
		showDialog(bf());
		
		//showRemote();
	}
	
function chooseButton() {
	var btns = document.getElementsByName("multiSelectButton");
	
	if (multiselect) {
		//var cls = "button lightHeadButton";
		var cls = "";
		multiselect = false;
		}
	else {
		//var cls = "button blueHeadButton";
		var cls = "act";
		multiselect = true;
		}
	
	for (var i = 0; i < btns.length; ++i) {
		// btns[i].className = cls;
		btns[i].className = cls;
	}

	if (! multiselect) {
		var elmnts = document.getElementsByName("record");
		var ids = [];
		for (var i = 0; i < elmnts.length; ++i) {
			if (elmnts[i].getAttribute("checked"))
				ids.push(elmnts[i].getAttribute("tag"));
		}
			//console.log(ids);
			
			if (ids.length > 0) {
				var btns = new Array(			
					// "?REC+DELM+"+ids.join("+")
					new button(lp_REMOVE, null, "cancelDialog(bf()); deleteHistory('main'); unCheck(); iui.showPageByHref('"+ivdr+"?REC=DELM&IDS="+ids.join("&IDS=")+"');", ids.length+" "+lp_MULTIDELETE, null, www+"/btn_trash.png"),
					null,
					new button(lp_MOVE, ivdr+"?MOVE+"+ids.join("+"), null, null, "_js", www+"/btn_folder.png")
					//new button(lp_CONVERT, ivdr+"?CONVERT+"+ids.join("+"), null, null, "_js")
					);
					for (var i = 0; i < usercontrol.length; i++)
						btns.push(usercontrol[i]);
				
				oDialog = new dialog(ids.length+" "+lp_RECORDS, null, null, null, null, btns	);
				oDialog.show();
			}

	}
	
}

function searchBarSet(me, elmnt) {

var names = document.getElementsByName(elmnt);

if (me.className.match(/lightlightbgButton/)) { 
		me.className="inlinebutton"; // eig. in seperate funktion
		for (var el in names) {
			names[el].style.display = "block"
			}
	} else { 
		me.className="inlinebutton lightlightbgButton"; // eig. in seperate funktion
		for (var el in names) { 
			names[el].style.display = "none"
			}
	}

}

function waitDialog(show, elmnt) {
	var waitdialog = wd();
	var heightOff;
	if (elmnt)
		heightOff = elmnt.top + elmnt.height / 2 - 34 + "px";
	else 
		heightOff = window.pageYOffset + window.innerHeight / 2 - 34 + "px";
		
	if (waitdialog) {
		if (show) {
			waitdialog.style.display = 'block';
			waitdialog.style.top = heightOff;
			waitdialog.style.left = window.innerWidth / 2 - 34 + "px";
		}
		else {
			waitdialog.style.display = 'none';
		}
	}
}

function dialogStars(stars, id) {
	// Parameter: [starscount, id, stars] 
	var div = $('rateStars').childNodes;
	var i = 0;

	for (var nds in div) {
		if (div[nds].nodeName == "SPAN") {
			i++;
			if (stars >= i)
				div[nds].className = "ratestar";
			else
				div[nds].className = "ratedot";
		}
	}

	if (id) {
	var jsreq = new XMLHttpRequest();
	jsreq.open("GET", ivdr+"?database=write&"+id+"&data={IDS}{POPM}{URL}='iVDR'&data={IDS}{POPM}{Rating}="+((stars==1)?1:(stars==2)?64:(stars==3)?128:(stars==4)?196:(stars==5)?255:0), true);
	//jsreq.open("GET", ivdr+"?database=write&"+id+"&data={IDS}{POPM}=iVDR", true);
//	jsreq.open("GET", ivdr+"?database=write&"+id+"&data={II}{RATE}="+(stars*51), true);
	jsreq.send(null);
	// geht nur weil die id der elemente gleich gesetzt ist sollte mal über objekte geregelt werden...
	if ($(id))
		$(id).className = 'starspacer star'+stars;
	}
}
	
function pinmove(evt) {
var pos;
if(typeof evt=='undefined')
	pos = 0;
else if(!evt) 
	pos = window.event.pageX-25;
else
	pos = evt.pageX-25;
	
var pin = $('pin');
var wdth = window.innerWidth-50;
var max = pin.getAttribute('maxvalue');
var val = parseInt(pos/wdth*max);
if (val < 0 || val > max)
	return;
pin.style.left=(pos-15)+"px";
pin.setAttribute('value', val);
pin.innerHTML = parseInt(val/60)+":"+(val%60 > 9 ? "" : "0")+parseInt(val%60);

//ddd(pos);
//ddd(wdth);
//ddd(pin.getAttribute('value'));

}

function testme(obj) {
	var test;
	for (var i in obj) {
		test += "\n"+i+" - "+obj[i];
	}
	alert(test);
}


function hitk(first, second, third) {

var arr = [first, second, third];

for (var i in arr) {
	if (arr[i]) {
		SimpleHttpRequest(keyparam + arr[i]);
	}
}

}

/*
function getChanges(e) {
if (e.touches.length > 1)
	return;
var x=e.touches[0].pageX-startX;
var y=e.touches[0].pageY-startY;

//alert(e.touches[0].pageX+" - "+startX+" = "+(e.touches[0].pageX-startX)+"\n"+e.touches[0].pageY+" - "+startY+" = "+(e.touches[0].pageY-startY));

if (e.touches.length == 1) {
	if (x<-100 && Math.abs(y) < 40)
		{
		//	alert("links");
//			e.preventDefault();
//			rememberevent.preventDefault();
			cancelDialog(kf());
		}
	if (x>100 && Math.abs(y) < 40)
		{
		//	alert("rechts");
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

}

function startEvent(e) {
	startX = e.touches[0].pageX; 
	startY = e.touches[0].pageY;
}*/

function moveFieldset(H, UP) {

if (UP) {
	var FOWN=getNextNode(H, "FIELDSET");
	var HUP=getPrevNode(H, "H2");
	H.parentNode.insertBefore(H, HUP);
	H.parentNode.insertBefore(FOWN,HUP);
}
else {
	var HUP=getNextNode(H, "H2");
	var FOWN=getNextNode(HUP, "FIELDSET");
	H.parentNode.insertBefore(HUP, H);
	H.parentNode.insertBefore(FOWN, H);
}

function getPrevNode(nd, name) {
	nd=nd.previousSibling;
	while (nd.nodeName != name) {
		nd=nd.previousSibling;
	}
	return(nd);
}
function getNextNode(nd, name) {
	nd=nd.nextSibling;
	while (nd.nodeName != name) {
		nd=nd.nextSibling;
	}
	return(nd);
}

}
/*
function returnCookie(nm) {
if (! document.cookie) return;
var ck = document.cookie+";"
var pat = nm+"=(.*?);.*";
var rgxp = new RegExp(pat);
var exc=rgxp.exec(ck);
ddd(ck);
return (RegExp.$1);
}*/