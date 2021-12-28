import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  const App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.amber), home: Photo());
  }
}

class Photo extends StatefulWidget {
  @override
  PhotoState createState() => PhotoState();
}

class PhotoState extends State<Photo> {
  int _index = 0;
  int _test = 1;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _test = 1;
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("PhotoSort")),
        body: FutureBuilder<bool>(
          future: _requestPermission(Permission.photos),
          builder: (context, snapshot) {
            bool authorized = snapshot.data ?? false;
            if (authorized) {
              return _displayPhotoBuilder();
            }
            return Text("Not Authorized");
          },
        ));
  }

  FutureBuilder<Widget> _displayPhotoBuilder() {
    return FutureBuilder<Widget>(
        future: _displayPhoto(),
        builder: (context, snapshot) {
          return snapshot.data ?? Text("Loading");
        });
  }

  Future<Widget> _displayPhoto() async {
    List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
    // TODO: Verify that index 0 is Recents
    List<AssetEntity> imageList = await list[0].assetList;
    if (_index < imageList.length) {
      AssetEntity image = imageList[_index];
      File imageFile = (await image.file)!;
      return GestureDetector(
          onTap: () => setState(() {
                _index++;
              }),
          child: Image.file(imageFile));
    } else {
      setState(() {
        _index = 0;
      });
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
    // if (await permission.isGranted) {
    //   return true;
    // } else {
    //   var result = await permission.request();
    //   if (result == PermissionStatus.granted) {
    //     return true;
    //   } else {
    //
    //   }
    // }
  }
}
