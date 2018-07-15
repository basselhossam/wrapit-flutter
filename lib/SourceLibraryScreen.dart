import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import './ArticleSourceScreen.dart' as ArticleSourceScreen;
import './globalStore.dart' as globalStore;

class SourceLibraryScreen extends StatefulWidget {
  SourceLibraryScreen({Key key}) : super(key: key);

  @override
  _SourceLibraryScreenState createState() => new _SourceLibraryScreenState();
}

class _SourceLibraryScreenState extends State<SourceLibraryScreen> {
  DataSnapshot snapshot;
  List sources;
  List mySources;
  bool change = false;
  final FlutterWebviewPlugin flutterWebviewPlugin = new FlutterWebviewPlugin();

  Future getData() async {
    var mysnap = await globalStore.articleSourcesDatabaseReference.once();
    var snap = await globalStore.sourcesDatabaseReference.once();
    if (mounted) {
      this.setState(() {
        snapshot = snap;
        sources = [];
        mySources = [];
        if (snapshot.value != null) {
          var value = snapshot.value;
          if (value != null) {
            value.forEach((k, v) {
              var x = {};
              x['name'] = v['name'];
              x['id'] = v['newsApiID'];
              x['imageURL'] = v['icon'];
              x['flag'] = 0;
              sources.add(x);
            });
          }
        }
        if(mysnap.value != null){
          var value = mysnap.value;
          if (value != null) {
            value.forEach((k, v) {
              var x = {};
              x['name'] = v['name'];
              x['id'] = v['id'];
              x['key'] = k;
              mySources.add(x);
            });
          }
        }
      });
    }
    return "Success!";
  }

  _hasSource(id) {
    int flag = 0;
    for(final v in mySources) {
      if (v['id'].compareTo(id) == 0) {
        flag = 1;
      }
    }
    if (flag == 1) return true;
    return false;
  }

  pushSource(name, id) {
    globalStore.articleSourcesDatabaseReference.push().set({
      'name': name,
      'id': id,
    });
  }

  _onAddTap(name, id) {
    int flag = 0;
    for(final v in mySources) {
      if (v['id'].compareTo(id) == 0) {
        flag = 1;
        Scaffold.of(context).showSnackBar(new SnackBar(
          content: new Text('$name removed'),
          backgroundColor: Colors.grey[600],
        ));
        globalStore.articleSourcesDatabaseReference.child(v['key']).remove();
      }
    }
    if (flag != 1) {
      Scaffold.of(context).showSnackBar(new SnackBar(
          content: new Text('$name added'),
          backgroundColor: Colors.grey[600]));
      pushSource(name, id);
    }
    this.getData();
    if (mounted) {
      this.setState(() {
        change = true;
      });
    }
  }

  CircleAvatar _loadAvatar(var url) {
    if (url == "http://www.bleacherreport.com") {
      return new CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: new NetworkImage(
            "http://static-assets.bleacherreport.com/favicon.ico"),
        radius: 40.0,
      );
    }
    try {
      return new CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: new NetworkImage(url),
        radius: 40.0,
      );
    } catch (Exception) {
      return new CircleAvatar(
        child: new Icon(Icons.library_books),
        radius: 40.0,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    this.getData();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.grey[200],
      body: sources == null
          ? const Center(child: const CircularProgressIndicator())
          : new GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 25.0),
              padding: const EdgeInsets.all(10.0),
              itemCount: sources == null ? 0 : sources.length,
              itemBuilder: (BuildContext context, int index) {
                return new GridTile(
                  footer: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Flexible(
                          child: new SizedBox(
                            height: 16.0,
                            width: 100.0,
                            child: new Text(
                              sources[index]['name'],
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      ]),
                  child: new Container(
                    height: 500.0,
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: new GestureDetector(
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          new SizedBox(
                            height: 100.0,
                            width: 100.0,
                            child: new Row(
                              children: <Widget>[
                                new Stack(
                                  children: <Widget>[
                                    new SizedBox(
                                      child: new Container(
                                        child: _loadAvatar(
                                            sources[index]['imageURL']),
                                        padding: const EdgeInsets.only(
                                            left: 10.0, top: 12.0, right: 10.0),
                                      ),
                                    ),
                                    new Positioned(
                                      right: 0.0,
                                      child: new GestureDetector(
                                        child: _hasSource(
                                                sources[index]['id'])
                                            ? new Icon(
                                                Icons.check_circle,
                                                color: Colors.greenAccent[700],
                                              )
                                            : new Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.grey[500],
                                              ),
                                        onTap: () {
                                          _onAddTap(
                                              sources[index]['name'],
                                              sources[index]['id']);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
