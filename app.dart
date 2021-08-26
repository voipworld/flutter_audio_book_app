import "dart:async";
import "dart:math";
import 'dart:convert';
import "package:cache_audio_player/cache_audio_player.dart";
import "package:flutter/material.dart";
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:flutter/cupertino.dart";
 import 'package:wakelock/wakelock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:fluttertoast/fluttertoast.dart';
List tocData;
List data;
void main() {
runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

var _index=1;
var playPause="Play";
final String intro="https://ia601400.us.archive.org/23/items/02_20210814_20210814/01%20-%20%D8%A7%D9%84%D9%85%D9%82%D8%AF%D9%85%D8%A9%20-%20%D8%A7%D9%84%D9%88%D8%B3%D8%A7%D8%A6%D9%84%20%D8%A7%D9%84%D9%85%D9%81%D9%8A%D8%AF%D8%A9%20%D9%84%D9%84%D8%AD%D9%8A%D8%A7%D8%A9%20%D8%A7%D9%84%D8%B3%D8%B9%D9%8A%D8%AF%D8%A9%20-%20%D8%B9%D8%A8%D8%AF%20%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86%20%D8%A8%D9%86%20%D9%86%D8%A7%D8%B5%D8%B1%20%D8%A7%D9%84%D8%B3%D8%B9%D8%AF%D9%8A.opus";
var maxTrack=1000;
  final CacheAudioPlayer _audioPlayer = CacheAudioPlayer();
var url;
var title="الوسائل المفيدة للحياة السعيدة";
StreamSubscription connectivitySubscription;
  StreamSubscription<AudioPlayerState> _stateSubscription;
  StreamSubscription<Object> _errorSubscription;

  AudioPlayerState _state = AudioPlayerState.PAUSED;
  Object _error;
  bool repeat = false;
bool isPlaying=false;
  @override
  void initState() {
super.initState();
initPlayer();
}

initPlayer() {
_audioPlayer.registerListeners();
MediaNotification.setListener('pause', () {
TogglePlayPause();
});

MediaNotification.setListener('play', () {
TogglePlayPause();
});

MediaNotification.setListener('next', () {
switchSong (true);
});

    MediaNotification.setListener('prev', () {
switchSong(false);
});

    MediaNotification.setListener('select', () {
});
    _stateSubscription =
        _audioPlayer.onStateChanged.listen((AudioPlayerState state) {
      setState(() {
        _state = state;
      });
switch (_state) {
      case AudioPlayerState.PLAYING:
Wakelock.enable();
                            MediaNotification.showNotification(
title: 'الوسائل المفيدة للحياة السعيدة',
author: 'عبد الرحمن السعدي',
isPlaying: false);
      setState(() {
playPause="Stop";
      });
break;
      case AudioPlayerState.READYTOPLAY:
break;
      case AudioPlayerState.BUFFERING:
showToast ("Loading...");
break;
      case AudioPlayerState.PAUSED:
Wakelock.disable();
                            MediaNotification.showNotification(
title: 'الوسائل المفيدة للحياة السعيدة',
author: 'عبد الرحمن السعدي',
                        isPlaying: true);
      setState(() {
playPause="Play";
      });
break;
      case AudioPlayerState.FINISHED:
      setState(() {
playPause="Play";
      });
if (_index==maxTrack) {
Wakelock.disable();
return;
}
switchSong (true);
break;
}
    });
    _errorSubscription = _audioPlayer.onError.listen((Object error) {
      setState(() {
        _error = error;
showToast (_error);
      });
    });
_audioPlayer.loadUrl(url);
  }

  @override
  void dispose() {
    super.dispose();
    _stateSubscription.cancel();
    _errorSubscription.cancel();
    _audioPlayer.stop();
    _audioPlayer.unregisterListeners();
  }

  @override
  Widget build(BuildContext context) {
return MaterialApp(
home: Directionality(
        textDirection: TextDirection.rtl,
        child:  Scaffold(
        appBar: AppBar(
          title: Text ("الوسائل المفيدة للحياة السعيدة"),
        ),
drawer: Drawer(
        child: new FutureBuilder(
            future: DefaultAssetBundle.of(context).loadString('assets/data.json'),
            builder: (context, snapshot) {
              var newData = json.decode(snapshot.data.toString());
      setState(() {
maxTrack=newData.length;
      });
return ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 32, bottom: 32, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              InkWell(
                                onTap: () async {
SharedPreferences prefs = await _prefs;
      setState(() {
_index=index;
url=tocData[_index][url];
title=tocData[_index][title];
      });
loadSong (_index);
showToast(title);
//Navigator.of(context).pop();
                                },
                                child: Text(
                                  newData[index]['title'],
                                  style: TextStyle(
                                      fontSize: 22),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: newData == null ? 0 : newData.length,
              );
            },
        ),
      ),
        body: Center(
          child: _playerContainer(),
        ),
      ),
),
    );
  }

  _playerContainer() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
children: <Widget>[
Text("$title"),
],
),
          Row(
            children: <Widget>[
              IconButton(
                icon: backIcon(),
tooltip: "Back",
                onPressed: () {
switchSong(false);
                },
              ),
          SizedBox(
            height: 20,
          ),
              IconButton(
                icon: playerIcon(),
tooltip: playPause,
                onPressed: () {
TogglePlayPause();
                },
              ),
          SizedBox(
            height: 20,
          ),
              IconButton(
                icon: nextIcon(),
tooltip: "Next",
                onPressed: () {
switchSong (true);
                },
              ),
              SizedBox(
                width: 20,
              ),
CheckboxListTile(
  title: Text("Repeat"),
  value: repeat,
  onChanged: (newValue) {
    setState(() {
repeat= newValue;
    });
  },
  controlAffinity: ListTileControlAffinity.leading,
),
          SizedBox(
            height: 20,
          ),
            ],
          ),
          _error == null ? SizedBox() : Text("there was an error $_error"),
        ],
      ),
    );
  }

  Icon playerIcon() {
    switch (_state) {
      case AudioPlayerState.PLAYING:
        return Icon(Icons.pause);
      case AudioPlayerState.READYTOPLAY:
break;
      case AudioPlayerState.BUFFERING:
break;
      case AudioPlayerState.PAUSED:
return Icon(Icons.play_arrow);
      case AudioPlayerState.FINISHED:
        return Icon(Icons.play_arrow);
      default:
        return Icon(Icons.error);
    }
  }

  TogglePlayPause() {
    switch (_state) {
      case AudioPlayerState.PLAYING:
        return _audioPlayer.stop();
      case AudioPlayerState.READYTOPLAY:
return _audioPlayer.play();
      case AudioPlayerState.BUFFERING:
break;
      case AudioPlayerState.PAUSED:
return _audioPlayer.play();
break;
      case AudioPlayerState.FINISHED:
                return _audioPlayer.play();
break;
      default: {
}
    }
  }

backIcon() {
return Icon(Icons.skip_previous);
}

nextIcon() {
return Icon(Icons.skip_next);
}

switchSong (bool next) {
if (next) {
if (_index==maxTrack) {
return;
}
      setState(() {
_index=_index+1;
      });
loadSong (_index);
} else {
if (_index==1) {
return;
}
      setState(() {
_index=_index-1;
      });
loadSong (_index);
}
}

loadSong (index) {
    setState(() {
url=tocData[index]['url'];
title=tocData[index]['title'];
    });

    _audioPlayer.stop();
_audioPlayer.loadUrl(url);
_audioPlayer.play();
}

showToast (String message) {
Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
}
}