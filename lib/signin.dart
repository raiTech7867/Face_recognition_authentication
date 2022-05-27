import 'dart:io';

import 'package:camera/camera.dart';
import 'package:facedetectionattandanceapp/models/user_model.dart';
import 'package:facedetectionattandanceapp/services/camera_service.dart';
import 'package:facedetectionattandanceapp/services/facenet_service.dart';
import 'package:facedetectionattandanceapp/services/ml_kit_service.dart';
import 'package:facedetectionattandanceapp/widgets/FacePainter.dart';
import 'package:facedetectionattandanceapp/widgets/auth_action_button.dart';
import 'package:facedetectionattandanceapp/widgets/camera_header.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:math'as math;
class SignIn extends StatefulWidget {
  final CameraDescription cameraDescription;

  const SignIn({
    Key? key,
    required this.cameraDescription,
  }) : super(key: key);


  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  CameraService _cameraService = CameraService();
  MLKitService _mlKitService = MLKitService();
  FaceNetService _faceNetService = FaceNetService.faceNetService;

 late Future _initializeControllerFuture;

  bool cameraInitializated = false;
  bool _detectingFaces = false;
  bool pictureTaked = false;

  // switchs when the user press the camera
  bool _saving = false;
  bool _bottomSheetVisible = false;

 late String imagePath;
 late Size imageSize;
  Face? faceDetected;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (pictureTaked) {
                    return Container(
                      width: width,
                      height: height,
                      child: Transform(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: Image.file(File(imagePath)),
                          ),
                          transform: Matrix4.rotationY(mirror)),
                    );
                  } else {
                    return Transform.scale(
                      scale: 1.0,
                      child: AspectRatio(
                        aspectRatio: MediaQuery.of(context).size.aspectRatio,
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.fitHeight,
                            child: Container(
                              width: width,
                              height: width *
                                  _cameraService
                                      .cameraController.value.aspectRatio,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  CameraPreview(
                                      _cameraService.cameraController),
                                  CustomPaint(
                                    painter: FacePainter(
                                        face: faceDetected,
                                        imageSize: imageSize),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              }),
          CameraHeader(
            "LOGIN",
            onBackPressed: _onBackPressed,
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !_bottomSheetVisible?AuthActionButton(
        _initializeControllerFuture,
        onPressed: onShot,
        isLogin: true,
        reload: _reload,
      )
          : Container(),
    );
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    // Dispose of the controller when the widget is disposed.
    _cameraService.dispose();
  }
  void _start() async {
    _initializeControllerFuture =
        _cameraService.startService(widget.cameraDescription);
    await _initializeControllerFuture;

    setState(() {
      cameraInitializated = true;
    });

    _frameFaces();
  }

  void _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        // if its currently busy, avoids overprocessing
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlKitService.getFacesFromImage(image);

          if (faces != null) {
            if (faces.length > 0) {
              // preprocessing the image
              setState(() {
                faceDetected = faces[0];
              });

              if (_saving) {
                 _saving = false;
                 _faceNetService.setCurrentPrediction(image, faceDetected!);
              }
            } else {
              setState(() {
                faceDetected = null;
              });
            }
          }

          _detectingFaces = false;
        } catch (e) {
          print(e);
          _detectingFaces = false;
        }
      }
    });
  }

  Future<bool> onShot() async {
    if (faceDetected == null) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('No face detected!'),
          );
        },
      );

      return false;
    } else {
      _saving = true;

      await Future.delayed(const Duration(milliseconds: 500));
      await _cameraService.cameraController.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));
      XFile file = await _cameraService.takePicture();

      setState(() {
        _bottomSheetVisible = true;
        pictureTaked = true;
        imagePath = file.path;

      });

      return true;
    }
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }
  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      cameraInitializated = false;
      pictureTaked = false;
    });
    this._start();
  }

}
