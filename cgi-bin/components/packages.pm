use strict;

return 1 unless %OPT;

my %switch_timeformat=(
'24' => {
	"epgscreen" 	=> "#ddd#, den #d#. #mmmm# #y#<br>#HH#:#MM# Uhr",
	"channeltime"	=> "#HH#:#MM#",
	"channeltimeto"	=> "#HH#:#MM# Uhr",
	"channelday"	=> "#dddd#, den #dd#.#mm#.#y#",
	"search"		=> "#ddd#, #dd#.#mm#.#y# #HH#:#MM#",
	"timergroup"	=> "#dddd#, den #dd#.#mm#.#y#",
	"timer"			=> "#dddd#, #HH#:#MM# Uhr",
	"record"		=> "#ddd#, #dd#.#mm#.#yy# #HH#:#MM# Uhr",
	"activerecord"	=> "#HH#:#MM# Uhr",
	"schedtime"		=> "#HH#:#MM#<h2>Uhr</h2>"
},
'12' => {
	"epgscreen" 	=> "#ddd#, #y# #mmmm# #d#<br>#hh#:#MM# #ampm#",
	"channeltime"	=> "#hh#:#MM#",
	"channeltimeto"	=> "#hh#:#MM# #ampm#",
	"channelday"	=> "#dddd#, #y#-#mm#-#dd#",
	"search"		=> "#ddd#, #y#-#mm#-#dd# #hh#:#MM#",
	"timergroup"	=> "#dddd#, #y#-#mm#-#dd#",
	"timer"			=> "#dddd#, #hh#:#MM# #ampm#",
	"record"		=> "#ddd#, #yy#-#mm#-#dd# #hh#:#MM# #ampm#",
	"activerecord"	=> "#hh#:#MM# #ampm#",
	"schedtime"		=> "#hh#:#MM#<h2>#ampm#</h2>",
});
%timef = %{$switch_timeformat{$OPT{timeformat}}};


#mplayer xineliboutput xbmc vlc
$OPT{player_adress} = "http://$ENV{SERVER_ADDR}:8080" unless $OPT{player_adress};
my %switch_media;
%switch_media = (
mplayer => {
	_OPT_ => {
		DIALOGFORM => "vdrremote.pl",
		KEYPARAM => $me."?rc+",
		SCRIPTNAME => $me."?",
		ACTUALPLAY => {command=>"PLUG mp3 CURR",regex=>"900.*$tempdir(\.\.\/)*(.*)\r\n",no=>2},
		},
	MUSIC => {
		dialog	=> "mp3Dialog",
		action	=> "cmd+",
		play	=> ["HITK+STOP", "plug+mp3+play+"],
		add		=> "plug+mp3+play+",
		dirplay => "playdir{pat}+play+",
		diradd	=> "playdir{pat}+add+",
	},
	MPLAYER => {
		dialog	=> "mp3Dialog",
		action => "cmd+",
		play => "plug+mplayer+play+",
	},
	RADIO => {
		dialog	=> "mp3Dialog",
		action	=> "cmd+",
		play	=> ["HITK+STOP", "plug+mp3+play+"],
		add		=> "plug+mp3+play+",		
	},
},
xbmc => {
	_OPT_ => {
		DIALOGFORM => "vdrremote.pl",
		KEYPARAM => $OPT{player_adress}."/xbmcCmds/xbmcHttp?command=Action&parameter=",
		SCRIPTNAME => $OPT{player_adress}."/xbmcCmds/xbmcHttp?",
		},
	MUSIC => {
		dialog	=> "mp3Dialog",
		action	=> "command=",
		play	=> ["ClearPlayList","PlayFile&parameter="],
		add		=> ["SetCurrentPlaylist(0)", "AddToPlayList&parameter="],
		diraction=> "cmd+",
		dirplay => "playdir{pat}+play+",
		diradd	=> "playdir{pat}+add+",
	},
},
vlc => {
	_OPT_ => {
		DIALOGFORM => "vdrremote.pl",
		KEYPARAM => $OPT{player_adress}."/requests/status.xml?command=",
		SCRIPTNAME => $OPT{player_adress}."/requests/status.xml?",
		},
	MUSIC => {
		dialog	=> "mp3Dialog",
		action	=> "command=",
		play	=> "in_play&input=",
		add		=> "in_enqueue&input=",
		# Just testing don't work!
		#dirplay => "in_play&input=".uri("http://".$ENV{SERVER_ADDR}.$me."?media=playlist.m3u"),
		#diradd	=> "in_play&input=".uri("http://".$ENV{SERVER_ADDR}.$me."?media=playlist.m3u"),
		#method	=> "http", # svdrp / http
		#prefix	=> "command=",
		
	},
},
);
# xbmc specials
%{$switch_media{xbmc}{MPLAYER}} = %{$switch_media{xbmc}{RADIO}} = %{$switch_media{xbmc}{MUSIC}};
delete $switch_media{xbmc}{RADIO}{dirplay};
delete $switch_media{xbmc}{RADIO}{diradd};

# vlc specials
%{$switch_media{vlc}{MPLAYER}} = %{$switch_media{vlc}{RADIO}} = %{$switch_media{vlc}{MUSIC}};

# xineliboutput specials
%{$switch_media{xineliboutput}{MUSIC}} = %{$switch_media{mplayer}{MUSIC}};
%{$switch_media{xineliboutput}{MPLAYER}} = %{$switch_media{mplayer}{MPLAYER}};
%{$switch_media{xineliboutput}{RADIO}} = %{$switch_media{mplayer}{RADIO}};
%{$switch_media{xineliboutput}{_OPT_}} = %{$switch_media{mplayer}{_OPT_}};
$switch_media{xineliboutput}{MUSIC}{play} = "plug+xineliboutput+PMSC+";
$switch_media{xineliboutput}{MPLAYER}{play} = "plug+xineliboutput+PMDA+";
$switch_media{xineliboutput}{RADIO}{play} = "plug+xineliboutput+PMSC+";
delete $switch_media{xineliboutput}{MUSIC}{add};
delete $switch_media{xineliboutput}{RADIO}{add};

# xinemediaplayer specials
%{$switch_media{xinemediaplayer}{MUSIC}} = %{$switch_media{mplayer}{MUSIC}};
%{$switch_media{xinemediaplayer}{MPLAYER}} = %{$switch_media{mplayer}{MPLAYER}};
%{$switch_media{xinemediaplayer}{RADIO}} = %{$switch_media{mplayer}{RADIO}};
%{$switch_media{xinemediaplayer}{_OPT_}} = %{$switch_media{mplayer}{_OPT_}};
$switch_media{xinemediaplayer}{MPLAYER}{play} = "plug+xinemediaplayer+play+";


%mediaselect = %{$switch_media{$OPT{player}}};
%dbmusic = %{$mediaselect{MUSIC}};

# fill %mediaselect 
my @media =(
{key => "MUSIC", dir => "media_music_dir",rek => "media_music_rek",pat => "media_music_pat"},
{key => "MPLAYER", dir => "media_video_dir",rek => "media_video_rek",pat => "media_video_pat"},
{key => "RADIO", dir => "media_radio_dir",rek => "media_radio_rek",pat => "media_radio_pat"},
);
my @hash = qw(dir rek pat);
for my $m (@media) {
	for (my $d = 0;$d < @{$OPT{$m->{dir}}};$d++) {
		my %h;
		for (my $i = 0;$i < @hash; $i++) {
			$h{$hash[$i]} = $OPT{$m->{$hash[$i]}}->[$d];
		}
		push(@{$mediaselect{$m->{key}}{dir}}, \%h);
	}
#	}
}

1;