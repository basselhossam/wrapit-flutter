import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:share/share.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:timeago/timeago.dart';
import './globalStore.dart' as globalStore;

class HomeFeedScreen extends StatefulWidget {
  HomeFeedScreen({Key key}) : super(key: key);

  @override
  _HomeFeedScreenState createState() => new _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  List data;
  List mySources;
  List myBookMarks;
  DataSnapshot snapshot;
  TimeAgo ta = new TimeAgo();
  final FlutterWebviewPlugin flutterWebviewPlugin = new FlutterWebviewPlugin();

  Future getData() async {
    await globalStore.logIn;
    if (await globalStore.userDatabaseReference == null) {
      await globalStore.logIn;
    }
    var snap = await globalStore.sourcesDatabaseReference.once();
    var mybook = await globalStore.articleDatabaseReference.once();
    var mysnap = await globalStore.articleSourcesDatabaseReference.once();
     if (mounted) {
      this.setState(() {
        snapshot = snap;
        data = [];
        mySources = [];
        myBookMarks = [];
        if(mysnap.value != null){
          var value = mysnap.value;
          if (value != null) {
            value.forEach((k, v) {
              mySources.add(v['id']);
            });
          }
        }
        if(mybook.value != null){
          var value = mybook.value;
          if (value != null) {
            value.forEach((k, v) {
              var x = {};
              x['url'] = v['url'];
              x['key'] = k;
              myBookMarks.add(x);
            });
          }
        }
        if (snapshot.value != null) {
          var value = snapshot.value;
          if (value != null) {
            value.forEach((k, v) {
              if(v.containsKey('articles')){
                v['articles'].forEach((key,val){
                  if(mySources.contains(val['newsApiID']) || mySources.length == 0) {
                    var x = {};
                    x['title'] = val['title'];
                    x['sourceName'] = v['name'];
                    x['sourceID'] = v['newsApiID'];
                    x['url'] = val['url'];
                    x['imageURL'] = val['image'];
                    x['publishedAt'] = val['time'];
                    x['exSummary'] = '';
                    for (var exSummary in val['exSummary']) {
                      x['exSummary'] += exSummary + "\n";
                    }
                    x['abSummary'] = val['abSummary'];
                    x['ratio'] = val['ratio'];
                    x['key'] = key;
                    x['category'] = val['category'];
                    data.add(x);
                  }
                });
              }
            });
            data.sort((a,b) => DateTime.parse(b['publishedAt']).compareTo(DateTime.parse(a['publishedAt'])));
          }
        }
      });
     }
    return "Success!";
  }

  _hasArticle(article) {
    int flag = 0;
    for(final v in myBookMarks) {
      if (v['url'].compareTo(article['url']) == 0) {
        flag = 1;
      }
    }
    if (flag == 1) return true;
    return false;
  }

  pushArticle(article) {
    globalStore.sourcesDatabaseReference
      .child(article['sourceID'])
      .child('articles')
      .child(article['key'])
      .once().then((DataSnapshot snapshot) {
        globalStore.articleDatabaseReference.push().set(snapshot.value);
      });
  }

  _onBookmarkTap(article) {
    int flag = 0;
    for(final v in myBookMarks) {
      if (v['url'].compareTo(article['url']) == 0) {
        flag = 1;
        globalStore.articleDatabaseReference.child(v['key']).remove();
        Scaffold.of(context).showSnackBar(new SnackBar(
          content: new Text('Article removed'),
          backgroundColor: Colors.grey[600],
        ));
      }
    }
    if (flag != 1) {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text('Article saved'),
        backgroundColor: Colors.grey[600],
      ));
      pushArticle(article);
    }
    this.getData();
  }

  @override
  void initState() {
    super.initState();
    this.getData();
  }

  Column buildButtonColumn(IconData icon) {
    Color color = Theme.of(context).primaryColor;
    return new Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        new Icon(icon, color: color),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.grey[200],
      body: new Column(children: <Widget>[
        new Expanded(
          child: data == null
              ? const Center(child: const CircularProgressIndicator())
              : data.length != 0
                  ? new ListView.builder(
                      itemCount: data == null ? 0 : data.length,
                      padding: new EdgeInsets.all(8.0),
                      itemBuilder: (BuildContext context, int index) {
                        return new Card(
                          elevation: 1.7,
                          child: new Padding(
                            padding: new EdgeInsets.all(10.0),
                            child: new Column(
                              children: [
                                new Row(
                                  children: <Widget>[
                                    new Padding(
                                      padding: new EdgeInsets.only(left: 4.0),
                                      child: new Text(
                                        timeAgo(DateTime.parse(data
                                            [index]["publishedAt"])),
                                        style: new TextStyle(
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    new Padding(
                                      padding: new EdgeInsets.all(5.0),
                                      child: new Text(
                                        data[index]["sourceName"] + " (" + data[index]['category'] + " )",
                                        style: new TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                new Row(
                                  children: <Widget>[
                                    new Padding(
                                      padding:
                                      new EdgeInsets.only(top: 8.0),
                                      child: new SizedBox(
                                        width: 0.75 * width,
                                        child: new FadeInImage.assetNetwork(
                                          placeholder: 'assets/loading.gif',
                                          image: data[index]
                                          ["imageURL"],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                ),
                                new Row(
                                  children: [
                                    new Expanded(
                                      child: new GestureDetector(
                                        child: new Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            new Padding(
                                              padding: new EdgeInsets.only(
                                                  left: 4.0,
                                                  right: 8.0,
                                                  bottom: 8.0,
                                                  top: 8.0),
                                              child: new Text(
                                                data[index]
                                                    ["title"],
                                                style: new TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            new Padding(
                                              padding: new EdgeInsets.only(
                                                  left: 4.0,
                                                  right: 4.0,
                                                  bottom: 4.0),
                                              child: new Text(
                                                "Extractive (Ratio: "+ (data[index]['ratio']*100).toStringAsPrecision(4) +"%)\n" +
                                                  data[index]["exSummary"] +
                                                  "\n\nAbstractive:\n" + data[index]["abSummary"],
                                                style: new TextStyle(
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          flutterWebviewPlugin.launch(
                                              data[index]["url"],
                                              fullScreen: false);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new GestureDetector(
                                      child: new Padding(
                                          padding:
                                          new EdgeInsets.symmetric(
                                              vertical: 10.0,
                                              horizontal: 5.0),
                                          child: buildButtonColumn(
                                              Icons.share)),
                                      onTap: () {
                                        share(data[index]
                                        ["url"]);
                                      },
                                    ),
                                    new GestureDetector(
                                      child: new Padding(
                                          padding:
                                          new EdgeInsets.all(5.0),
                                          child: _hasArticle(
                                              data[index])
                                              ? buildButtonColumn(
                                              Icons.bookmark)
                                              : buildButtonColumn(Icons
                                              .bookmark_border)),
                                      onTap: () {
                                        _onBookmarkTap(
                                            data[index]);
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ), ////
                          ),
                        );
                      },
                    )
                  : new Center(
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          new Icon(Icons.chrome_reader_mode,
                              color: Colors.grey, size: 60.0),
                          new Text(
                            "No articles saved",
                            style: new TextStyle(
                                fontSize: 24.0, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
        )
      ]),
    );
  }
}
