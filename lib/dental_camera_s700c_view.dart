// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_settings_plus/core/open_settings_plus.dart';
import 'package:screen_recorder/screen_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

bool _isRecording = false;

class S700cView extends StatefulWidget {
  const S700cView({super.key});

  @override
  State<S700cView> createState() => _S700cViewState();
}

class _S700cViewState extends State<S700cView> {
  static const platform = MethodChannel('dental_camera_s700c_plugin');

  bool isExporting = false;
  double angle = 0.0;
  final ScreenRecorderController _screenRecorderController =
      ScreenRecorderController();
  bool get canExport => _screenRecorderController.exporter.hasFrames;

  @override
  void initState() {
    asyncInit();
    super.initState();
  }

  asyncInit() async {
    platform.setMethodCallHandler(_handleMethodCall);
    await platform.invokeMethod('init');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'gsensorData':
        final String hexData = bytesToHex(call.arguments);
        setState(() {
          angle = getAngle(hexData);
        });
        break;
      case 'photoCaptured':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto scattata"),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'noFrameAvailable':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nessun frame disponibile"),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'photoPreview':
        Uint8List imageData = call.arguments;
        bool? saveResult = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Anteprima',
                style: TextStyle(fontSize: 16),
              ),
              content: Image.memory(imageData),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Salva',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: const Text(
                    'Annulla',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        );
        if (saveResult ?? false) {
          await _saveImage(imageData);
        }
        break;

      default:
        throw PlatformException(
            code: "Not Implemented",
            message: "Method ${call.method} not implemented.");
    }
  }

  Future<void> _saveImage(Uint8List imageData) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/temp_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(imageData);
      bool? result;
      try {
        result = await GallerySaver.saveImage(imagePath);
      } catch (e) {
        //print("[DEBUG] Error saving image to gallery: $e");
      }

      if (result ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Immagine salvata con successo"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Salvataggio immagine fallito"),
            duration: Duration(seconds: 2),
          ),
        );
      }
      await file.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore durante il salvataggio dell'immagine: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _foto() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('foto');
      } else if (Platform.isIOS) {
        await platform.invokeMethod('foto_ios');
      }
    } catch (e) {
      //print("Failed to capture photo: '${e}'.");
    }
  }

  Future<void> _startRecording() async {
    if (await _requestPermissions()) {
      _screenRecorderController.start();
      setState(() {
        _isRecording = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Storage permission denied"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    if (await Permission.videos.isGranted) {
      return true;
    }
    // Check for specific permissions on Android 13 and above
    if (await Permission.videos.request().isGranted) {
      return true;
    }
    // Request the storage permission
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<void> _stopRecording() async {
    _screenRecorderController.stop();
    setState(() {
      _isRecording = false;
      isExporting = true;
    });
    //TODO: finire qui
    bool? saveResult = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Vuoi salvare il video?',
            style: TextStyle(fontSize: 32),
          ),

          actionsAlignment: MainAxisAlignment.center,
          // content: Image.memory(imageData),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Salva',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: const Text(
                'Annulla',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
    if (!(saveResult ?? false)) {
      setState(() {
        isExporting = false;
        _screenRecorderController.exporter.clear();
      });
      return;
    }
    try {
      List<RawFrame>? frames =
          await _screenRecorderController.exporter.exportFrames();
      if (frames == null || frames.isEmpty) {
        setState(() {
          isExporting = false;
        });
        throw Exception("Failed to export frames");
      }

      final directory = await getTemporaryDirectory();
      final framePathTemplate = '${directory.path}/DentalCam_%03d.png';

      for (int i = 0; i < frames.length; i++) {
        final framePath =
            framePathTemplate.replaceAll('%03d', i.toString().padLeft(3, '0'));
        final file = File(framePath);
        await file.writeAsBytes(frames[i]
            .image
            .buffer
            .asUint8List()); // Convert ByteData to Uint8List
      }

      await _convertFramesToVideo(framePathTemplate);
    } catch (e) {
      //print("[DEBUG] Error during frame export: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Errore durante l'esportazione dei frame"),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isExporting = false;
        _screenRecorderController.exporter.clear();
      });
    }
  }

  Future<void> _convertFramesToVideo(String framePathTemplate) async {
    try {
      final directory = await getTemporaryDirectory();
      final videoPath = '${directory.path}/recorded_video.mp4';
      print("framePathTemplate=$framePathTemplate");
      // FFmpeg command to convert PNG frames to MP4
      final command = '-r 9.8 -i $framePathTemplate -vcodec mpeg4 $videoPath';

      await FFmpegKit.execute(command).then((esit) async {
        final rc = await esit.getReturnCode();
        if (rc!.getValue() == 0) {
          bool? result;

          try {
            result = await GallerySaver.saveVideo(videoPath);
          } catch (e) {
            //print("[DEBUG] Error saving video to gallery: $e");
          }

          if (result ?? false) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Video salvato con successo"),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Salvataggio video fallito"),
                duration: Duration(seconds: 2),
              ),
            );
          }
          await File(videoPath).delete();
        } else {
          print(
              "[DEBUG] FFmpeg process failed with return code ${rc.getValue()}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Errore durante la conversione del video"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    } catch (e) {
      print("[DEBUG] Error during frame to video conversion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore durante la conversione del video: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String bytesToHex(Uint8List bytes) {
    const String hexChars = '0123456789ABCDEF';
    StringBuffer hex = StringBuffer();
    for (int byte in bytes) {
      int high = (byte >> 4) & 0x0F;
      int low = byte & 0x0F;
      hex.write(hexChars[high]);
      hex.write(hexChars[low]);
    }
    return hex.toString();
  }

  double getAngle(String data) {
    List<String> msg = [];
    for (int i = 0; i < data.length; i += 2) {
      msg.add(data.substring(i, math.min(i + 2, data.length)));
    }

    int xSymbol = 1, zSymbol = 1;
    StringBuffer xBuilder = StringBuffer();
    StringBuffer zBuilder = StringBuffer();

    for (int i = 0; i < msg.length; i++) {
      if (i == 0 && (msg[i] == "2D" || msg[i] == "2d")) {
        xSymbol = -1;
      }
      if (i == 6 && (msg[i] == "2D" || msg[i] == "2d")) {
        zSymbol = -1;
      }
      if (i > 0 && i < 5) {
        xBuilder.write(msg[i][1]);
      }
      if (i > 6) {
        zBuilder.write(msg[i][1]);
      }
    }

    int x = int.parse(xBuilder.toString()) * xSymbol;
    int z = int.parse(zBuilder.toString()) * zSymbol;

    return (math.atan2(x.toDouble(), z.toDouble()) * 180 / math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.black,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isExporting)
              const Center(
                  child: SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 8,
                        color: Colors.teal,
                      )))
            else ...[
              Expanded(
                child: Center(
                  child: ScreenRecorder(
                    background: Colors.black,
                    height: MediaQuery.of(context).size.width / 1.49,
                    width: MediaQuery.of(context).size.width,
                    controller: _screenRecorderController,
                    child: Platform.isIOS
                        ? const UiKitView(
                            viewType: 'my_uikit_view',
                          )
                        : const AndroidView(
                            viewType: 'mjpeg-view-type',
                          ),
                  ),
                ),
              ),
              _FinalButtonRow(
                fotoCallBack: () {
                  _foto();
                },
                videoCallBack: _isRecording ? _stopRecording : _startRecording,
              )
              // ElevatedButton(
              //   onPressed: _foto,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.teal,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(18.0),
              //     ),
              //   ),
              //   child: const Text('Foto'),
              // ),
              // ElevatedButton(
              //   onPressed: _isRecording ? _stopRecording : _startRecording,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: _isRecording ? Colors.red : Colors.teal,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(18.0),
              //     ),
              //   ),
              //   child: Text(_isRecording ? 'Stop' : 'Video'),
              // ),
            ],
          ],
        ),
      ),
    );
  }
}

_CameraMode _mode = _CameraMode.photo;

class _FinalButtonRow extends StatefulWidget {
  const _FinalButtonRow(
      {required this.fotoCallBack, required this.videoCallBack});
  final VoidCallback fotoCallBack;
  final Function() videoCallBack;
  @override
  State<_FinalButtonRow> createState() => __FinalButtonRowState();
}

class __FinalButtonRowState extends State<_FinalButtonRow> {
  Timer? videoTimer;

  final cnt = StreamController<String?>.broadcast();
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    cnt.close();
    cancelTimer();
    super.dispose();
  }

  prepareTimer() {
    final startTime = DateTime.now();
    videoTimer = Timer.periodic(Durations.extralong4, (timer) {
      final dur = DateTime.now().difference(startTime);
      cnt.add(dur.toString().split('.')[0]);
    });
  }

  cancelTimer() {
    // cnt.add(null);
    videoTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<String?>(
                stream: cnt.stream,
                builder: (context, snapshot) {
                  return Opacity(
                    opacity: snapshot.data != null ? 1 : 0,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(80))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          snapshot.data ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }),
          ),
          Row(
            //  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 32.0),
                      child: InkWell(
                        enableFeedback: false,
                        highlightColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        onTap: () {
                          if (Platform.isAndroid) {
                            const OpenSettingsPlusAndroid().wifi();
                          } else if (Platform.isIOS) {
                            const OpenSettingsPlusIOS().wifi();
                          }
                        },
                        child: Icon(
                          Icons.wifi,
                          color: Colors.white.withOpacity(0.7),
                          size: 35,
                        ),
                      ),
                    )),
              ),
              InkWell(
                enableFeedback: false,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                onTap: () async {
                  if (_mode == _CameraMode.photo) {
                    widget.fotoCallBack();
                  } else {
                    await widget.videoCallBack();
                    if (_isRecording) {
                      prepareTimer();
                    } else {
                      cancelTimer();
                    }
                  }
                },
                child: Container(
                  height: 75,
                  width: 75,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.7),
                      shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                children: [
                                  InkWell(
                                    enableFeedback: false,
                                    highlightColor: Colors.transparent,
                                    splashFactory: NoSplash.splashFactory,
                                    onTap: () {
                                      // if (mode == _CameraMode.photo) {
                                      //   mode = _CameraMode.video;
                                      // } else {
                                      _mode = _CameraMode.photo;
                                      //  }
                                      setState(() {});
                                    },
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: _mode == _CameraMode.photo
                                          ? Colors.teal
                                          : Colors.white.withOpacity(0.7),
                                      size: 35,
                                    ),
                                  ),
                                  Text(
                                    'Foto',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _mode == _CameraMode.photo
                                            ? Colors.teal
                                            : Colors.black),
                                  )
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                InkWell(
                                  enableFeedback: false,
                                  highlightColor: Colors.transparent,
                                  splashFactory: NoSplash.splashFactory,
                                  onTap: () {
                                    // if (mode == _CameraMode.photo) {
                                    //   mode = _CameraMode.video;
                                    // } else {
                                    _mode = _CameraMode.video;
                                    //  }
                                    setState(() {});
                                  },
                                  child: Icon(
                                    Icons.videocam_outlined,
                                    color: _mode == _CameraMode.video
                                        ? Colors.teal
                                        : Colors.white.withOpacity(0.7),
                                    size: 35,
                                  ),
                                ),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _mode == _CameraMode.video
                                          ? Colors.teal
                                          : Colors.black),
                                )
                              ],
                            ),
                          ],
                        )
                        //  InkWell(
                        //   enableFeedback: false,
                        //   highlightColor: Colors.transparent,
                        //   splashFactory: NoSplash.splashFactory,
                        //   onTap: () {
                        //     if (mode == _CameraMode.photo) {
                        //       mode = _CameraMode.video;
                        //     } else {
                        //       mode = _CameraMode.photo;
                        //     }
                        //     setState(() {});
                        //   },
                        //   child: Icon(
                        //     mode == _CameraMode.photo
                        //         ? Icons.camera_alt_outlined
                        //         : Icons.videocam_outlined,
                        //     color: Colors.white.withOpacity(0.7),
                        //     size: 35,
                        //   ),
                        // ),
                        )),
              ),

              // ElevatedButton(
              //   onPressed: _foto,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.teal,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(18.0),
              //     ),
              //   ),
              //   child: const Text('Foto'),
              // ),
              // ElevatedButton(
              //   onPressed: isRecording ? _stopRecording : _startRecording,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: isRecording ? Colors.red : Colors.teal,
              //     foregroundColor: Colors.white,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(18.0),
              //     ),
              //   ),
              //   child: Text(isRecording ? 'Stop' : 'Video'),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _CameraMode {
  photo,
  video;
}
