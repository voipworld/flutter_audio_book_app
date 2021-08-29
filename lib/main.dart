import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_cache/just_audio_cache.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'common.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();
JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
//await MobileAds.instance.initialize();
runApp(MyApp());
}

const int maxFailedLoadAttempts = 3;
class MyApp extends StatefulWidget {
const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );
InterstitialAd? _interstitialAd;
int _numInterstitialLoadAttempts = 0;
  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;
bool willPlay=false;
bool appStarting=true;

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
  Future<void> _createAnchoredBanner(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      print('Unable to get height of anchored banner.');
      return;
    }

    final BannerAd banner = BannerAd(
      size: size,
      request: request,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-8560183752416211/1124339519'
          : 'ca-app-pub-8560183752416211/1124339519',
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _anchoredBanner = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
      ),
    );
    return banner.load();
  }

void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-8560183752416211/7196785661',
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
if (appStarting) {
appStarting=false;
_showInterstitialAd();
}
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) async {
appStarting=false;
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
               _createInterstitialAd();
            }
          },
        ));
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) async {
        ad.dispose();
        _createInterstitialAd();
if (willPlay) {
willPlay=false;
_player.play();
}
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) async {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
if (willPlay) {
willPlay=false;
_player.play();
}
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  @override
  void initState() async {
super.initState();
 _createInterstitialAd();
final prefs = await SharedPreferences.getInstance();
_index = prefs.getInt('index') ?? 0;
    _player = AudioPlayer();
        _player.playerStateStream.listen((state) {
      setState(() {
        _state = state;
      });
if (_state!.playing) {
} else {
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
_interstitialAd?.dispose();
_anchoredBanner?.dispose();
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
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
                bottomLeft: Radius.circular(30)
            )
        ),
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
                          top: 32, bottom: 32, left: 32, right: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
GestureDetector(
                                onTap: () async {
    setState(() {
_index=index;
    });
final prefs = await SharedPreferences.getInstance();
prefs.setInt('index', _index);
await getTracks();
willPlay=true;
//_player.play();
_showInterstitialAd();
Navigator.of(context).pop();
        const snackBar = SnackBar(content: Text('Tap'));
ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).buttonColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(newData[index]['title']),
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
Expanded(
child: Center(
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
                        onPressed: () {
_player.pause();
                        },
                      );

  Widget get _playButton => 
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        tooltip: "Play",
                        onPressed: () {
_player.play();
                        },
);
}