import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'dart:math';
import './settings.dart';
import './swiper.dart';

class Photo extends StatefulWidget {
  @override
  PhotoState createState() => PhotoState();
}

class PhotoState extends State<Photo> {
  var _imageOn;
  Set<String> _imagesSorted = {};
  var _imageList;
  final _random = new Random();
  List<AssetEntity> _imageOrder = [];
  int _imagePointer = 0;

  @override
  void initState() {
    super.initState();
    _imageOn = null;
  }

  void toSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: Settings(),
      );
    }));
  }

  void nextImages(int max, int numImages) async {
    List<AssetEntity> imageOrder = [];
    Set<int> indicesIncluded = {};
    int nextIndex = -1;
    // If all images have been sorted, don't enter loop
    if (_imageList.length != _imagesSorted.length) {
      // Fill up the imageOrder until numImages is reached OR we run out of photos to choose from
      while ((imageOrder.length < numImages) &&
          (imageOrder.length < _imageList.length)) {
        nextIndex = _random.nextInt(max);
        // If the image has not been sorted yet and it has not been included in this run
        if (!_imagesSorted.contains(_imageList[nextIndex].id) &&
            !indicesIncluded.contains(nextIndex)) {
          AssetEntity image = _imageList[nextIndex];
          // File imageFile = (await image.file)!;
          // var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
          imageOrder.add(image);
          indicesIncluded.add(nextIndex);
        }
      }
    }
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        _imageOrder = imageOrder;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("PhotoSort"), actions: <Widget>[
          IconButton(onPressed: toSettings, icon: Icon(Icons.settings))
        ]),
        body: FutureBuilder<bool>(
          future: _requestPermission(Permission.photos),
          builder: (context, snapshot) {
            bool authorized = snapshot.data ?? false;
            if (authorized) {
              return _displayPhotoBuilder();
            }
            return Text("Not Authorized");
          },
        ),
        bottomNavigationBar: Container(
          child: _displayButtons(),
          color: Colors.blue,
          height: 100,
        ),
        // persistentFooterButtons: [_displayButtons()],
        backgroundColor: Colors.white);
  }

  void keepPhoto() {
    setState(() {
      _imagePointer++;
      _imagesSorted.add(_imageOn.id);
      if (_imagePointer < _imageOrder.length) {
        _imageOn = _imageOrder[_imagePointer];
      }
    });
  }

  void deletePhoto() {
    PhotoManager.editor
        .deleteWithIds([_imageOn.id]).whenComplete(() => setState(() {
              _imagePointer++;
              _imagesSorted.add(_imageOn.id);
              if (_imagePointer < _imageOrder.length) {
                _imageOn = _imageOrder[_imagePointer];
              }
            }));
  }

  Widget _displayButtons() {
    final ButtonStyle style = TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 40), elevation: 0);
    final keepButton = ElevatedButton(
        onPressed: keepPhoto, style: style, child: const Text('Keep'));

    final deleteButton = ElevatedButton(
        onPressed: deletePhoto, style: style, child: const Text('Delete'));

    List<Widget> l = [];

    l.add(deleteButton);
    l.add(keepButton);
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [Center(child: deleteButton), Center(child: keepButton)],
    ));
  }

  FutureBuilder<Widget> _displayPhotoBuilder() {
    return FutureBuilder<Widget>(
        future: _displayPhoto(),
        builder: (context, snapshot) {
          return snapshot.data ?? CircularProgressIndicator();
        });
  }

  Future<Widget> _displayPhoto() async {
    // If image list has not be initialized yet
    if (!(_imageList is List)) {
      var list = await PhotoManager.getAssetPathList();
      // TODO: Verify that index 0 is Recents
      List<AssetEntity> imageList = await list[0].assetList;
      setState(() {
        _imageList = imageList;
      });
      return CircularProgressIndicator();
    }

    // If we need a new photo order (hardcoding 5 for now)
    if (_imagePointer == _imageOrder.length) {
      nextImages(_imageList.length, 10);
    }

    // If no images remain
    if (_imageList.length == 0 || _imageOrder.length == 0) {
      return Text("No photos found");
    }

    // AssetEntity image = _imageList[_imagePointer];

    // If imageOn has not be initialized
    if (_imageOn is! AssetEntity) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        setState(() {
          _imageOn = _imageOrder[0];
          _imagesSorted.add(_imageOn.id);
        });
      });
    }
    if (_imagePointer < _imageOrder.length) {
      return Swiper(_imageOrder, keepPhoto, deletePhoto);
    }
    return CircularProgressIndicator();
  }

  Future<bool> _requestPermission(Permission permission) async {
    var result = await PhotoManager.requestPermissionExtend();
    if (result == PermissionState.authorized) {
      return true;
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
                title: Text('Camera Permission'),
                content: Text(
                    'PhotoSort needs access to your photos to display them'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text('Deny'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoDialogAction(
                    child: Text('Settings'),
                    onPressed: () => openAppSettings(),
                  ),
                ],
              ));
      return false;
    }
  }
}
