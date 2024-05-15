// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/scheduler.dart';
// import 'dart:io';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:gallery_saver/gallery_saver.dart';

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   static const platform = MethodChannel('com.example.flutterino/stream');

//   bool isRecording = false; // Stato per la registrazione
//   double angle = 0.0; // Angolo calcolato dai dati del sensore G

//   @override
//   void initState() {
//     super.initState();
//     platform.setMethodCallHandler(_handleMethodCall);
//   }

//   Future<dynamic> _handleMethodCall(MethodCall call) async {
//     switch (call.method) {
//       case 'gsensorData':
//         final String hexData = bytesToHex(call.arguments);
//         setState(() {
//           angle = getAngle(hexData);
//         });
//         break;
//       case 'photoCaptured':
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Foto scattata"),
//             duration: Duration(seconds: 2),
//           ),
//         );
//         break;
//       case 'noFrameAvailable':
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Nessun frame disponibile"),
//             duration: Duration(seconds: 2),
//           ),
//         );
//         break;
//       case 'recordingStatus':
//         String message = call.arguments == "started"
//             ? "Registrazione iniziata"
//             : "Registrazione fermata";
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             duration: Duration(seconds: 2),
//           ),
//         );
//         setState(() {
//           isRecording = call.arguments == "started";
//         });
//         if (call.arguments == "stopped") {
//           _saveVideo(call.arguments['videoPath']);
//         }
//         break;
//       case 'photoPreview':
//         print("[DEBUG] photoPreview method called");
//         Uint8List imageData = call.arguments;
//         print("[DEBUG] Received imageData with length: ${imageData.length}");

//         bool? saveResult = await showDialog<bool>(
//           context: context,
//           builder: (BuildContext context) {
//             print("[DEBUG] Showing preview dialog");
//             return AlertDialog(
//               title: Text('Anteprima'),
//               content: Image.memory(imageData),
//               actions: <Widget>[
//                 TextButton(
//                   child: Text('Salva'),
//                   onPressed: () {
//                     print("[DEBUG] Save button pressed");
//                     Navigator.of(context).pop(true);
//                   },
//                 ),
//                 TextButton(
//                   child: Text('Annulla'),
//                   onPressed: () {
//                     print("[DEBUG] Cancel button pressed");
//                     Navigator.of(context).pop(false);
//                   },
//                 ),
//               ],
//             );
//           },
//         );
//         print("[DEBUG] Dialog result: $saveResult");

//         if (saveResult ?? false) {
//           print("[DEBUG] Saving image");
//           await _saveImage(imageData);
//           print("[DEBUG] Image saved");
//         } else {
//           print("[DEBUG] Image not saved");
//         }
//         break;

//       default:
//         throw PlatformException(
//             code: "Not Implemented",
//             message: "Method ${call.method} not implemented.");
//     }
//   }

//   Future<void> _saveImage(Uint8List imageData) async {
//     try {
//       // Get the temporary directory
//       final directory = await getTemporaryDirectory();
//       final imagePath = '${directory.path}/temp_image.png';

//       print("[DEBUG] Saving image to path: $imagePath");

//       // Write the image data to a file
//       final file = File(imagePath);
//       await file.writeAsBytes(imageData);

//       print("[DEBUG] Image written to file");

//       // Save the image to the gallery
//       bool? result;
//       try {
//         result = await GallerySaver.saveImage(imagePath);
//         print("[DEBUG] Image saved to gallery: $result");
//       } catch (e) {
//         print("[DEBUG] Error saving image to gallery: $e");
//       }

//       if (result ?? false) {
//         print("[DEBUG] Successfully saved image to gallery");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Immagine salvata con successo"),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       } else {
//         print("[DEBUG] Failed to save image to gallery");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Salvataggio immagine fallito"),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }

//       // Optionally delete the temporary file
//       await file.delete();
//       print("[DEBUG] Temporary file deleted");
//     } catch (e) {
//       print("[DEBUG] Error during saving image: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Errore durante il salvataggio dell'immagine: $e"),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Future<void> _saveVideo(String videoPath) async {
//     try {
//       // Save the video to the gallery
//       final result = await GallerySaver.saveVideo(videoPath);
//       if (result ?? false) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Video salvato con successo"),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Salvataggio video fallito"),
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Errore durante il salvataggio del video: $e"),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   Future<void> _foto() async {
//     try {
//       if (Platform.isAndroid) {
//         await platform.invokeMethod('foto');
//       } else if (Platform.isIOS) {
//         await platform.invokeMethod('foto_ios');
//       }
//     } on PlatformException catch (e) {
//       print("Failed to capture photo: '${e.message}'.");
//     }
//   }

//   Future<void> _video() async {
//     try {
//       if (Platform.isAndroid) {
//         await platform.invokeMethod('video');
//       } else if (Platform.isIOS) {
//         await platform.invokeMethod('video_ios');
//       }
//       setState(() {
//         isRecording = !isRecording; // Toggle recording state
//       });
//     } on PlatformException catch (e) {
//       print("Failed to toggle video recording: '${e.message}'.");
//     }
//   }

//   // Add the new methods here
//   String bytesToHex(Uint8List bytes) {
//     const String hexChars = '0123456789ABCDEF';
//     StringBuffer hex = StringBuffer();
//     for (int byte in bytes) {
//       int high = (byte >> 4) & 0x0F;
//       int low = byte & 0x0F;
//       hex.write(hexChars[high]);
//       hex.write(hexChars[low]);
//     }
//     return hex.toString();
//   }

//   double getAngle(String data) {
//     List<String> msg = [];
//     for (int i = 0; i < data.length; i += 2) {
//       msg.add(data.substring(i, math.min(i + 2, data.length)));
//     }

//     int xSymbol = 1, zSymbol = 1;
//     StringBuffer xBuilder = StringBuffer();
//     StringBuffer zBuilder = StringBuffer();

//     for (int i = 0; i < msg.length; i++) {
//       if (i == 0 && (msg[i] == "2D" || msg[i] == "2d")) {
//         xSymbol = -1;
//       }
//       if (i == 6 && (msg[i] == "2D" || msg[i] == "2d")) {
//         zSymbol = -1;
//       }
//       if (i > 0 && i < 5) {
//         xBuilder.write(msg[i][1]);
//       }
//       if (i > 6) {
//         zBuilder.write(msg[i][1]);
//       }
//     }

//     int x = int.parse(xBuilder.toString()) * xSymbol;
//     int z = int.parse(zBuilder.toString()) * zSymbol;

//     return (math.atan2(x.toDouble(), z.toDouble()) * 180 / math.pi);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Telecamerina'),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Expanded(
//             child: Platform.isIOS
//                 ? UiKitView(
//                     viewType: 'my_uikit_view',
//                   )
//                 : AndroidView(
//                     viewType: 'mjpeg-view-type',
//                   ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: _foto,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(18.0),
//                     ),
//                   ),
//                   child: Text('Foto'),
//                 ),
//                 ElevatedButton(
//                   onPressed: _video,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(18.0),
//                     ),
//                   ),
//                   child: Text(isRecording ? 'Stop' : 'Registra'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('evviva gesu\'');
  }
}
