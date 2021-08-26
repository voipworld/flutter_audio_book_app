import 'dart:convert';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock/wakelock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_cache/just_audio_cache.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rxdart/rxdart.dart';
import 'common.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
runApp(MyApp());
}

class MyApp extends StatefulWidget {
const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  dynamic _data;
  var maxTrack = 0;
var position=0;
  var title = "Title";
  var url = "1111";
  int _index = 0;
  late final AudioPlayer _player;
  PlayerState? _state;
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  getTracks() async {
    var toc = await rootBundle.loadString('assets/toc.json');
    _data = json.decode(toc);
    maxTrack = _data.length;
    String URI = _data[_index]['url'];
    setState(() {
      title = _data[_index]['title'];
      url = URI;
    });
_player.dynamicSet(url: url);
  }

  showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  void initState() async {
super.initState();
final prefs = await SharedPreferences.getInstance();
_index = prefs.getInt('index') ?? 0;
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    _player = AudioPlayer();
        _player.playerStateStream.listen((state) {
      setState(() {
        _state = state;
      });
if (_state!.playing) {
Wakelock.enable();
} else {
Wakelock.disable();
}
switch (_state?.processingState) {
case  ProcessingState.completed:
if (_index==maxTrack) {
return;
}
_index=_index+1;
getTracks();
_player.play();
break;
}
    });
getTracks();
  }
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player.stop();
    }
  }

  void _playAudio() async {
    _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
localizationsDelegates: [
GlobalCupertinoLocalizations.delegate,
GlobalMaterialLocalizations.delegate,
GlobalWidgetsLocalizations.delegate,
],
supportedLocales: [
Locale("ar", "AE"),
],
locale: Locale("ar", "AE"),
  title: 'الوسائل المفيدة للحياة السعيدة',
  theme: ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.lightBlue[800],
    accentColor: Colors.cyan[600],
),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text("الوسائل المفيدة للحياة السعيدة"),
centerTitle: true,
          ),
          drawer: Drawer(
        child: FutureBuilder(
            future: DefaultAssetBundle.of(context)
                .loadString('assets/toc.json'),
            builder: (context, snapshot) {
              // Decode the JSON
              var newData = json.decode(snapshot.data.toString());

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
    setState(() {
_index=index;
    });
final prefs = await SharedPreferences.getInstance();
prefs.setInt('index', _index);
await getTracks();
_player.play();
Navigator.of(context).pop();
                                },
                                child: Text(newData[index]['title'],
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
            child: Container(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
Container(
width: 600,
height: 400,
child: SizedBox.shrink(
child: Text("$title",
textAlign: TextAlign.center,
  style: TextStyle(
    color: Colors.black,
fontSize: 25,
fontWeight: FontWeight.bold,
),
),
),
),
                    ],
                  ),
                  Row(
                    children: <Widget>[
IconButton(
                        icon: Icon(Icons.skip_previous),
                        tooltip: "Back",
                        onPressed: () async {
                          if (_index == 0) {
                            return;
                          }
                            _index = _index - 1;
final prefs = await SharedPreferences.getInstance();
prefs.setInt('index', _index);
_player.stop();
getTracks();
_player.play();
                        },
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.backward_fill),
                        tooltip: "-10 Seconds",
                        onPressed: () async {
await _player.seek(Duration(seconds: _player.position.inSeconds - 10));
                        },
                      ),
                                SizedBox(
            height: 40,
          ),
                      _audioStateWidget(),
                                SizedBox(
            height: 40,
          ),
                      IconButton(
                        icon: Icon(CupertinoIcons.forward_fill),
                        tooltip: "+10 Seconds",
                        onPressed: () async {
await                           _player.seek(Duration(seconds: _player.position.inSeconds + 10));
                        },
                      ),
                                SizedBox(
            height: 40,
          ),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        tooltip: "Next",
                        onPressed: () async {
                          if (_index == maxTrack) {
                            return;
                          }
                            _index = _index + 1;
final prefs = await SharedPreferences.getInstance();
prefs.setInt('index', _index);
_player.stop();
await getTracks();
_player.play();
                        },
                      ),
                    ],
                                      ),
                  Row(
                    children: <Widget>[
                                SizedBox(
            height: 40,
          ),
Container(
width: 400,
height: 200,
child: SizedBox.shrink(
child:                                    StreamBuilder<PositionData>(
                stream: _positionDataStream,
                builder: (context, snapshot) {
position=_player.position.inSeconds;
                  final positionData = snapshot.data;
                                    return SeekBar(
                    duration: positionData?.duration ?? Duration.zero,
                    position: positionData?.position ?? Duration.zero,
                    bufferedPosition:
                        positionData?.bufferedPosition ?? Duration.zero,
                    onChangeEnd: _player.seek,
                  );
                },
              ),
),
),
                                SizedBox(
            height: 40,
          ),
],
),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _audioStateWidget() {
    if (_state == null) return _playButton;

    if (_state!.playing) {
      return _pauseButton;
    } else {
      return _playButton;
    }
  }

  Widget get _pauseButton => IconButton(
                        icon: Icon(Icons.pause),
                        tooltip: "Pause",
                        onPressed: () async {
await _player.pause();
                        },
                      );

  Widget get _playButton => 
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        tooltip: "Play",
                        onPressed: () async {
_player.play();
                        },
);
}