import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_recorder/screen_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('dental_camera_s700c_plugin');
  bool isRecording = false;
  bool isExporting = false;
  double angle = 0.0;
  ScreenRecorderController _screenRecorderController =
      ScreenRecorderController();
  bool get canExport => _screenRecorderController.exporter.hasFrames;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethodCall);
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
          SnackBar(
            content: Text("Foto scattata"),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'noFrameAvailable':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
              title: Text('Anteprima'),
              content: Image.memory(imageData),
              actions: <Widget>[
                TextButton(
                  child: Text('Salva'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: Text('Annulla'),
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
        print("[DEBUG] Error saving image to gallery: $e");
      }

      if (result ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Immagine salvata con successo"),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          duration: Duration(seconds: 2),
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
    } on PlatformException catch (e) {
      print("Failed to capture photo: '${e.message}'.");
    }
  }

  Future<void> _startRecording() async {
    if (await _requestPermissions()) {
      _screenRecorderController.start();
      setState(() {
        isRecording = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      isRecording = false;
      isExporting = true;
    });

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
      print("[DEBUG] Error during frame export: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

      // FFmpeg command to convert PNG frames to MP4
      final command = '-r 9.8 -i $framePathTemplate -vcodec mpeg4 $videoPath';

      await _flutterFFmpeg.execute(command).then((rc) async {
        if (rc == 0) {
          bool? result;
          try {
            result = await GallerySaver.saveVideo(videoPath);
          } catch (e) {
            print("[DEBUG] Error saving video to gallery: $e");
          }

          if (result ?? false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Video salvato con successo"),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Salvataggio video fallito"),
                duration: Duration(seconds: 2),
              ),
            );
          }
          await File(videoPath).delete();
        } else {
          print("FFmpeg process failed with return code $rc");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
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
          duration: Duration(seconds: 2),
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
      appBar: AppBar(
        title: Text('Telecamerina'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isExporting)
              Center(child: CircularProgressIndicator())
            else ...[
              Expanded(
                child: ScreenRecorder(
                  height: 500,
                  width: 500,
                  controller: _screenRecorderController,
                  child: Platform.isIOS
                      ? UiKitView(
                          viewType: 'my_uikit_view',
                        )
                      : AndroidView(
                          viewType: 'mjpeg-view-type',
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _foto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      child: Text('Foto'),
                    ),
                    ElevatedButton(
                      onPressed: isRecording ? _stopRecording : _startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRecording ? Colors.red : Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                      child: Text(isRecording ? 'Stop' : 'Video'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
