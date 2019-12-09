import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseDatabase userdatabase = FirebaseDatabase.instance;
final DatabaseReference databaseReference = FirebaseDatabase.instance.reference();
final FirebaseAuth auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = new GoogleSignIn();
final _db = Firestore.instance;

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copy Paste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _inputController = TextEditingController();
  final _clipboardController = TextEditingController();
  bool _visible = true;

  DocumentSnapshot document;

  void _setClipboard() {
    Clipboard.setData(new ClipboardData(text: _inputController.text));
    FocusScope.of(context).unfocus();
  }

  void _getClipboard() async {
    ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    _inputController.text = data.text;
    FocusScope.of(context).unfocus();
  }

  void _clear() async {
    _inputController.text = "";
  }

  void _upload() async {
    final FirebaseUser user = await auth.currentUser();
    FocusScope.of(context).unfocus();
    if (user != null) {
      if (_inputController.text.trim() != null) {
        _db
            .collection('clipboard_data')
            .document(document.documentID)
            .updateData({user.uid: _inputController.text});
      }
    } else {
      _clipboardController.text = "Sign in to upload.";
    }
  }

  void _clearUpload() async {
    final FirebaseUser user = await auth.currentUser();
    if (user != null) {
      if (_inputController.text.trim() != null) {
        _db
            .collection('clipboard_data')
            .document(document.documentID)
            .updateData({user.uid: ""});
      }
    }
  }

  void _download() async {
    final FirebaseUser user = await auth.currentUser();
    if (user != null) {
      setState(() {
        _visible = false;
      });
      try {
        _clipboardController.text = document[user.uid];
      } catch(e) {
        _clipboardController.text = "No data saved yet";
      }
    }
    else {
      print("Not logged in!!!!");
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Copy Paste'),
    ),
    backgroundColor: Colors.lightBlueAccent,
    body: SafeArea(
      child: ListView(
        children: <Widget>[
          // input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              child: TextField(
                controller: _inputController,
                decoration: InputDecoration(
                  labelText: 'Input Text',
                  filled: true,
                  fillColor: Colors.white60,
                  prefixIcon: IconButton(
                    icon: Icon(Icons.content_paste),
                    iconSize: 30,
                    onPressed: () => _getClipboard(),
                    tooltip: 'Paste',
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.cancel),
                    iconSize: 30,
                    onPressed: () => _clear(),
                    tooltip: 'Clear',
                  ),
                ),
                minLines: 2,
                maxLines: 10,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
            Firestore.instance.collection('clipboard_data').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      LinearProgressIndicator(),
                      Text("Loading your previous data...")
                    ],
                  ),
                );
              }
              else {
                document = snapshot.data.documents[0]; // set document snapshot
                return _buildClipboard();
              }
            },
          ),
          StreamBuilder<QuerySnapshot>(
            builder: (context, snapshot) {
                return _buildSend();
            },
          ),
          StreamBuilder<QuerySnapshot>(
            builder: (context, snapshot) {
              return _buildLoginLogout();
            },
          ),



        ],
      ),
    ),
  );
}

Widget _buildClipboard()  {
    _download();
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Form(
      child: TextField(
        readOnly: true,
        controller: _clipboardController,
        decoration: InputDecoration(
          labelText: 'Cliboard',
          filled: true,
          fillColor: Colors.white60,
          prefixIcon: IconButton(
            iconSize: 30,
            icon: Icon(Icons.content_copy),
            onPressed: () {
              _setClipboard();
            },
            tooltip: 'Copy',
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel),
            iconSize: 30,
            onPressed: () => _clearUpload(),
            tooltip: 'Delete',
          ),
        ),
        minLines: 1,
        maxLines: 5,
      ),
    ),
  );

}


  Widget _buildSend()  {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          child: FlatButton(
            color: Colors.white60,
            onPressed: _upload,
                child: Text(
                  "Send",
            ),
          ),
        ),
      );
  }

  Widget _buildLoginLogout()  {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
          child: Visibility (
            visible: _visible,
            child: FlatButton(
              color: Colors.white60,
              onPressed: _googleSignIn,
              child: Text(
                "Login",
              ),
            ),
            replacement: FlatButton(
              color: Colors.white60,
              onPressed: _googleSignOut,
              child: Text(
                "Logout",
              ),
            ),
          )


      ),
      );
  }

Future _googleSignIn() async {
  final GoogleSignInAccount googleUser = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser
      .authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = (await auth.signInWithCredential(credential))
      .user;
  print("signed in " + user.displayName);

  setState(() {
    _visible = false;
  });

  return user;
}

_googleSignOut() {
  googleSignIn.signOut();
  auth.signOut();
  setState(() {
    _visible = true;
  });
  _clipboardController.text = "";
}

}
