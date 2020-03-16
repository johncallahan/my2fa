import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:countdown/countdown.dart';
import 'package:dart_otp/dart_otp.dart';

void main() {
  runApp(new MyApp());
} 

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.green,
      ),
      home: new MyHomePage(title: 'My2FA'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _codes = [11,22];
  String barcode = "otpauth://totp/XXX:YYY?secret=ZZZ&digits=6&algorithm=SHA1&issuer=r2&period=30";
  String totp = "wait...";
  String site = "";
  final _biggerFont = const TextStyle(fontSize: 36.0);

  int val = 0;
  CountDown cd;

  void _setTotp() {
    RegExp exp = new RegExp(r"otpauth\:\/\/totp\/([A-Za-z0-9]+)\:([A-Za-z0-9]+)\?secret\=([A-Za-z0-9]+)\&.*");
    RegExpMatch match = exp.firstMatch(barcode);
    String justSite = match.group(1);
    String user = match.group(2);
    String secret = match.group(3);
    TOTP totpCode = TOTP(secret: secret);
    totp = totpCode.now();
    site = user + "@" + justSite;
  }

  void _randomNumber() {
    setState(() {
      countdown();
      _setTotp();
    });
  }

  void countdown() {
    cd = new CountDown(new Duration(seconds: 30));
    var sub = cd.stream.listen(null);
    sub.onDone(() {
      countdown();
    });

    sub.onData((Duration d) {
      if (val == d.inSeconds) return;
      setState(() {
        val = d.inSeconds;
        if (val == 0) {
          _setTotp();
        }
      });
    });
  }

  Widget _buildCodes() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return Divider();
          final index = i ~/ 2;
          if (index >= _codes.length) {
            return null;
          } else {
            return _buildRow(_codes[index]);
          }
        });
  }

  Widget _buildRow(int i) {
    _setTotp();
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: Text(
              totp,
              style: _biggerFont,
            ),
            subtitle: Text(site),
          ),
          ButtonTheme.bar(
            child: new ButtonBar(
              children: <Widget>[
                new Text(
                  val.toString(),
                  style: new TextStyle(fontSize: 30.50),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: _buildCodes(),
      floatingActionButton: new FloatingActionButton(
        onPressed: _scan,
        tooltip: 'Scan QR Code',
        child: new Icon(Icons.add),
      ),
    );
  }

  void _scan() {
    scan();
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      print(barcode);
      setState(() => this.barcode = barcode);
      setState(() { _randomNumber(); });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode = 'Nothing Scan');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }
}
