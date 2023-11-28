import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String? _imagePath;
  List<String> _imagePaths = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Document Scanner',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ElevatedButton(
          //   onPressed: fetchImageFromCamera,
          //   child: const Text('Scan'),
          // ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchImageFromGallery,
            child: const Text('Upload'),
          ),
          const SizedBox(height: 20),
          // ElevatedButton(
          //   onPressed: createPdf,
          //   child: const Text('Create PDF'),
          // ),
          const SizedBox(height: 20),
          // ..._imagePaths.map((path) => Image.file(File(path))),
          GridView.builder(
            padding: const EdgeInsets.all(10),
            shrinkWrap: true,
            itemCount: _imagePaths.length + 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index == _imagePaths.length) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed:
                        fetchImageFromCamera, // or any other function you want to execute
                  ),
                );
              } else {
                return Image.file(File(_imagePaths[index]));
              }
            },
          ),
          const Spacer(),
          InkWell(
              onTap: () async {
                await createPdf();
                _imagePaths.clear();
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("Create PDF",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    )),
              ))
        ],
      ),
    );
  }

  Future<void> fetchImageFromCamera() async {
    bool cameraPermissionGranted = await Permission.camera.request().isGranted;
    if (!cameraPermissionGranted) {
      cameraPermissionGranted =
          await Permission.camera.request() == PermissionStatus.granted;
    }

    if (!cameraPermissionGranted) {
      return;
    }

    String imageFilePath = join((await getApplicationSupportDirectory()).path,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");

    bool operationSuccessful = false;

    try {
      operationSuccessful = await EdgeDetection.detectEdge(
        imageFilePath,
        canUseGallery: true,
        androidScanTitle: 'Scanning',
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );
      print("operationSuccessful: $operationSuccessful");
    } catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      if (operationSuccessful) {
        _imagePath = imageFilePath;
      }
    });
    _imagePaths.add(imageFilePath);
  }

  Future<void> fetchImageFromGallery() async {
    // Your existing gallery image fetching code here
    String imageFilePath = join((await getApplicationSupportDirectory()).path,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");

    bool operationSuccessful = false;
    try {
      operationSuccessful = await EdgeDetection.detectEdgeFromGallery(
        imageFilePath,
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );
      print("operationSuccessful: $operationSuccessful");
    } catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      if (operationSuccessful) {
        _imagePath = imageFilePath;
      }
    });
    // On success, add the image path to _imagePaths
    _imagePaths.add(imageFilePath);
  }

  Future<void> createPdf() async {
    final pdf = pw.Document();
    for (var imagePath in _imagePaths) {
      final image = pw.MemoryImage(
        File(imagePath).readAsBytesSync(),
      );
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Image(image),
          ),
        ),
      );
    }
    // _isCreatedPdf = true;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    //clear the image paths
    _imagePaths.clear();
  }
}
