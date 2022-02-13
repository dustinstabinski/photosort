import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:math';
import 'dart:io';
import 'package:tcard/tcard.dart';

class Swiper extends StatefulWidget {
  var _images;
  var _keepPhoto;
  var _deletePhoto;
  var _controller;

  Swiper(List<AssetEntity> images, Function keepPhoto, Function deletePhoto,
      TCardController controller) {
    _images = images;
    _keepPhoto = keepPhoto;
    _deletePhoto = deletePhoto;
    _controller = controller;
  }

  @override
  SwiperState createState() =>
      SwiperState(_images, _keepPhoto, _deletePhoto, _controller);
}

class SwiperState extends State<Swiper> {
  var _images;
  var _keepPhoto;
  var _deletePhoto;
  double _x = 100.0;
  Offset _offset = Offset.zero;
  TCardController _controller = TCardController();

  SwiperState(List<AssetEntity> images, Function keepPhoto,
      Function deletePhoto, TCardController controller) {
    _images = images;
    _keepPhoto = keepPhoto;
    _deletePhoto = deletePhoto;
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: getImage(),
      builder: (context, snapshot) {
        return snapshot.data ?? CircularProgressIndicator();
      },
    );
  }

  Future<Widget> getImage() async {
    List<List> finalImages = [];
    List<Widget> cards = [];
    for (var image in _images) {
      File imageFile = (await image.file)!;
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      finalImages.add([decodedImage, imageFile]);
    }

    for (var imageInfo in finalImages) {
      cards.add(finalImage(imageInfo[0], imageInfo[1]));
    }

    return Container(
      child: TCard(
        cards: cards,
        size: const Size(double.infinity, double.infinity),
        onForward: (index, info) async {
          if (info.direction == SwipDirection.Right) {
            _keepPhoto();
          } else if (info.direction == SwipDirection.Left) {
            await _deletePhoto();
          }
        },
        lockYAxis: true,
        delaySlideFor: 800,
        controller: _controller,
      ),
    );
  }

  Widget finalImage(decodedImage, imageFile) {
    if (decodedImage.height > decodedImage.width) {
      return Image.file(
        imageFile,
        fit: BoxFit.contain,
        height: double.infinity,
        alignment: Alignment.center,
      );
    }
    var boxDecoration = const BoxDecoration(color: Colors.white);
    return Container(
      decoration: boxDecoration,
      child: Image.file(
        imageFile,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }
}
