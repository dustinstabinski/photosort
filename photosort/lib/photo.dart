import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import './settings.dart';

class Photo extends StatefulWidget {
  @override
  PhotoState createState() => PhotoState();
}

class PhotoState extends State<Photo> {
  int _index = 0;
  var _imageOn;
  Set<String> _imagesSorted = {};
  var _imageList;
  final _random = new Random();

  @override
  void initState() {
    super.initState();
    _index = 0;
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

  int nextImage(int max) {
    int nextIndex = -1;
    if (_imageList.length != _imagesSorted.length) {
      while (
          nextIndex == -1 || _imagesSorted.contains(_imageList[nextIndex].id)) {
        nextIndex = 0 + _random.nextInt(max - 0);
      }
    }

    return nextIndex;
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
        persistentFooterButtons: [_displayButtons()]);
  }

  Widget _displayButtons() {
    final ButtonStyle style =
        TextButton.styleFrom(textStyle: const TextStyle(fontSize: 50));
    final keepButton = ElevatedButton(
        onPressed: () => {
              setState(() {
                _index = nextImage(_imageList.length);
                _imagesSorted.add(_imageOn.id);
              })
            },
        style: style,
        child: const Text('Keep'));

    final deleteButton = ElevatedButton(
        onPressed: () => {
              PhotoManager.editor
                  .deleteWithIds([_imageOn.id]).whenComplete(() => setState(() {
                        if (_imageList.length > 0) {
                          // HANDLE DELETE

                        }

                        _index = nextImage(_imageList.length);
                      })),
            },
        style: style,
        child: const Text('Delete'));

    List<Widget> l = [];

    l.add(deleteButton);
    l.add(keepButton);
    return Container(
        child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Expanded(child: deleteButton), Expanded(child: keepButton)],
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
    if (!(_imageList is List)) {
      var list = await PhotoManager.getAssetPathList();
      List<AssetEntity> imageList = await list[0].assetList;
      setState(() {
        _imageList = imageList;
      });
      return CircularProgressIndicator();
    }
    if (_imageList.length == 0 || _index == -1) {
      return Text("No photos found");
    }
    // TODO: Verify that index 0 is Recents

    if (_index < _imageList.length) {
      AssetEntity image = _imageList[_index];
      if (!(_imageOn is AssetEntity) || (image.id != _imageOn.id)) {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() {
            _imageOn = image;
          });
        });
      }
      File imageFile = (await image.file)!;
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      if (decodedImage.height > decodedImage.width) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          height: double.infinity,
          alignment: Alignment.center,
        );
      }
      return Center(child: Image.file(imageFile));
    } else {
      return Text("No pictures found");
    }
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
