import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:math';
import './settings.dart';
import './swiper.dart';
import 'package:tcard/tcard.dart';

class Photo extends StatefulWidget {
  @override
  PhotoState createState() => PhotoState();
}

class PhotoState extends State<Photo> with WidgetsBindingObserver {
  var _imageOn;
  var _imageList;
  var _deletionAlbum;
  final _random = new Random();
  int _imagePointer = 0;
  var _controller;
  int _albumOn = -1;
  int _destinationAlbumOn = -1;
  int _pageOn = -1;
  var _assetList;
  List<String> _idsToDelete = [];

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
    _imageOn = null;
    _controller = TCardController();
    _albumOn = -1;
    var deleteAsset;
    PhotoManager.editor.iOS
        .createAlbum(
          "PhotoSort - To Delete",
        )
        .then(
            (deletionAlbum) => PhotoManager.getAssetPathList().then((value) => {
                  setState(() {
                    _assetList = value;
                    _deletionAlbum = deletionAlbum;
                  })
                }));
  }

  void reloadPhotos() {
    PhotoManager.getAssetPathList().then((value) => {
          setState(() {
            _assetList = value;
            _imageList = null;
            _albumOn = -1;
            _imageOn = null;
            _pageOn = -1;
          })
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("PhotoSort"),
            actions: <Widget>[
              IconButton(onPressed: toSettings, icon: Icon(Icons.settings))
            ],
            leading: Builder(builder: (BuildContext context) {
              if (_albumOn != -1) {
                return IconButton(
                    onPressed: reloadPhotos, icon: Icon(Icons.chevron_left));
              } else {
                return Container();
              }
            })),
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
      if (_imagePointer < _imageList.length) {
        _imageOn = _imageList[_imagePointer];
      }
    });
  }

  void deletePhoto() async {
    await PhotoManager.editor
        .copyAssetToPath(asset: _imageOn, pathEntity: _deletionAlbum);
    setState(() {
      _imagePointer++;
      if (_imagePointer < _imageList.length) {
        _imageOn = _imageList[_imagePointer];
      }
    });
  }

  Widget _displayButtons() {
    SwipDirection? left = SwipDirection.Left;
    SwipDirection? right = SwipDirection.Right;
    final ButtonStyle style = TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 40), elevation: 0);
    final keepButton = ElevatedButton(
        onPressed: () => _controller.forward(direction: right),
        style: style,
        child: const Text('Keep'));

    final deleteButton = ElevatedButton(
        onPressed: () => _controller.forward(direction: left),
        style: style,
        child: const Text('Delete'));
    if (_imageOn != null) {
      return Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [Center(child: deleteButton), Center(child: keepButton)],
      ));
    } else {
      return Container();
    }
  }

  FutureBuilder<Widget> _displayPhotoBuilder() {
    return FutureBuilder<Widget>(
        future: _displayPhoto(),
        builder: (context, snapshot) {
          return snapshot.data ?? CircularProgressIndicator();
        });
  }

  int getNextPage(numPages) {
    return _random.nextInt(numPages);
  }

  Future<Widget> _displayPhoto() async {
    // If image list has not be initialized yet
    if (!(_imageList is List)) {
      // TODO: Verify that index 0 is Recents
      if (_albumOn < 0 || _destinationAlbumOn < 0) {
        return albumSelect(_assetList);
      }
      if (_pageOn == -1) {
        int numPhotos = _assetList[_albumOn].assetCount;
        int numPages = (numPhotos / 10).ceil();
        setState(() {
          _pageOn = getNextPage(numPages);
        });
      }
      List<AssetEntity> imageList =
          await _assetList[_albumOn].getAssetListPaged(_pageOn, 10);
      setState(() {
        _imageList = imageList;
      });
      return CircularProgressIndicator();
    }

    // If no images remain
    if (_imageList.length == 0) {
      return Text("No photos found");
    }
    // If we need a new photo order (hardcoding 10 for now)
    if ((_imagePointer == _imageList.length)) {
      await PhotoManager.editor.deleteWithIds(_idsToDelete);
      int numPhotos = _assetList[_albumOn].assetCount;
      int numPages = (numPhotos / 10).ceil();
      setState(() {
        _imageOn = null;
        _imageList = null;
        _imagePointer = 0;
        _pageOn = getNextPage(numPages);
      });
    }

    // AssetEntity image = _imageList[_imagePointer];

    // If imageOn has not be initialized
    if (_imageOn is! AssetEntity) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        setState(() {
          _imageOn = _imageList[0];
        });
      });
    }
    if (_imagePointer < _imageList.length) {
      return Swiper(_imageList, keepPhoto, deletePhoto, _controller);
    }
    return CircularProgressIndicator();
  }

  void setAlbum(index) {
    setState(() {
      _albumOn = index;
    });
  }

  void setDestinationAlbum(index) {
    setState(() {
      _destinationAlbumOn = index;
    });
  }

  Widget albumSelect(list) {
    Map<int, Color> color = {
      50: Color.fromRGBO(136, 14, 79, .1),
      100: Color.fromRGBO(136, 14, 79, .2),
      200: Color.fromRGBO(136, 14, 79, .3),
      300: Color.fromRGBO(136, 14, 79, .4),
      400: Color.fromRGBO(136, 14, 79, .5),
      500: Color.fromRGBO(136, 14, 79, .6),
      600: Color.fromRGBO(136, 14, 79, .7),
      700: Color.fromRGBO(136, 14, 79, .8),
      800: Color.fromRGBO(136, 14, 79, .9),
      900: Color.fromRGBO(136, 14, 79, 1),
    };
    return ListView(
        padding: const EdgeInsets.all(8),
        children: List<Widget>.generate(list.length + 2, (index) {
          int listIndex = index - 1;
          String phrase = "Which album would you like to sort?";
          if (_albumOn >= 0) {
            phrase = "Where would you like the deleted photos to go?";
          }
          if (index == 0) {
            return Center(
                child: Text(phrase,
                    style: TextStyle(
                        fontSize: 20,
                        color: MaterialColor(0xFFF37E21, color))));
          } else if (index < list.length + 1) {
            return Center(
                child: TextButton(
                    onPressed: () {
                      _albumOn < 0
                          ? setAlbum(listIndex)
                          : setDestinationAlbum(listIndex);
                    },
                    style: TextButton.styleFrom(
                        fixedSize: const Size(1000, 100),
                        textStyle: TextStyle(fontSize: 20)),
                    child: Text(list[listIndex].name)));
          } else if (index == list.length + 1 && _albumOn >= 0) {
            return Center(
                child: Text("Create a new album",
                    style: TextStyle(
                        fontSize: 20,
                        color: MaterialColor(0xFFF37E21, color))));
          } else {
            return SizedBox.shrink();
          }
        }));
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
