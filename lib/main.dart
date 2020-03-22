import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:countdown/countdown.dart';
import 'package:dart_otp/dart_otp.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:random_string/random_string.dart';

import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';

import 'package:my2fa/database.dart';
import 'package:my2fa/model.dart';

void main() {
  runApp(MaterialApp(home: MyHomePage()));
} 

class MyHomePage extends StatefulWidget {
  final String title = "My 2FA";

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final StreamController<bool> _verificationNotifier = StreamController<bool>.broadcast();

  int val = 0;
  CountDown cd;
  bool editMode = false;
  bool isAuthenticated = false;
  String _passcode;
  
  final _biggerFont = const TextStyle(fontSize: 36.0);

  @override
  void initState() {    
    countdown();
  }

  Code _addCode(String barcode) {
    RegExp exp = new RegExp(r"otpauth\:\/\/totp\/([A-Za-z0-9]+)\:([A-Za-z0-9]+)\?secret\=([A-Za-z0-9]+)\&.*");
    RegExpMatch match = exp.firstMatch(barcode);
    String justSite = match.group(1);
    String user = match.group(2);
    String secret = match.group(3);

    var salt = CryptKey().genDart(16);
    var Encrypter = AesCrypt(_passcode + "0000" + _passcode);
    String encrypted = Encrypter.encrypt(secret,salt);
    
    return Code(
      user: user,
      site: justSite,
      secret: encrypted,
      salt: salt,
      digits: "6",
      algorithm: "SHA1",
      issuer: justSite,
      period: "30");
  }

  void countdown() {
    cd = new CountDown(new Duration(seconds: 30));
    var sub = cd.stream.listen(null);
    sub.onDone(() {
      countdown();
    });

    sub.onData((Duration d) {
      if(editMode) return;
      setState(() { val = 30 - (DateTime.now().second % 30); });
    });
  }

  Future<bool> _showConfirmationDialog(BuildContext context, Code code, String action) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Do you want to $action this ${code.user} @ ${code.site}?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.pop(context, true); // showDialog() returns true
              },
            ),
            FlatButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.pop(context, false); // showDialog() returns false
              },
            ),
          ],
        );
      },
    );
  }

  String _getTOTP(Code code) {
    var Encrypter = AesCrypt(_passcode + "0000" + _passcode);
    try {
      String decrypted = Encrypter.decrypt(code.secret,code.salt);
      return TOTP(secret: decrypted).now();
    } catch(e) {
      return TOTP(secret: randomString(32)).now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: !isAuthenticated ? null : <Widget>[
            IconButton(
              icon: Icon(editMode ? Icons.save : Icons.edit),
              onPressed: () {
                editMode = !editMode;
              },
            ),
        ],
      ),
      body: FutureBuilder<List<Code>>(
        future: DBProvider.db.getAllCodes(),
        builder: (BuildContext context, AsyncSnapshot<List<Code>> snapshot) {
          if (isAuthenticated && snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                Code code = snapshot.data[index];
                return Dismissible(
                  key: UniqueKey(),
                  background: Container(color: Colors.red),
                  confirmDismiss: (DismissDirection dismissDirection) async {
                    switch(dismissDirection) {
                      case DismissDirection.endToStart:
                      case DismissDirection.startToEnd:
                        return await _showConfirmationDialog(context, code, 'delete') == true;
                      case DismissDirection.horizontal:
                      case DismissDirection.vertical:
                      case DismissDirection.up:
                      case DismissDirection.down:
                        assert(false);
                    }
                    return false;
                  },
                  onDismissed: (direction) {
                    DBProvider.db.deleteCode(code.id);
                  },
                  child: Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.timelapse),
                          title: Text(
                            editMode ? code.user + "@" + code.issuer : _getTOTP(code),
                            style: _biggerFont,
                          ),
                          subtitle: Text(editMode ? "" : code.user + "@" + code.issuer),
                        ),
                        ButtonTheme.bar(
                          child: new ButtonBar(
                            children: <Widget>[
                              new Text(
                                editMode ? "" : val.toString(),
                                style: new TextStyle(fontSize: 30.50),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  )
                );
              } 
            );
          } else if(!isAuthenticated) {
            return PasscodeScreen(
                title: 'Enter App Passcode',
                circleUIConfig: CircleUIConfig(
                  borderColor: Colors.blue,
                  fillColor: Colors.blue,
                  circleSize: 30),
                keyboardUIConfig: KeyboardUIConfig(
                  digitBorderWidth: 2,
                  primaryColor: Colors.blue),
                passwordEnteredCallback: _onPasscodeEntered,
                cancelLocalizedText: 'Cancel',
                deleteLocalizedText: 'Delete',
                shouldTriggerVerification: _verificationNotifier.stream,
                backgroundColor: Colors.black.withOpacity(0.8),
                cancelCallback: _onPasscodeCancelled,
              );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }
      ),
      floatingActionButton: !isAuthenticated || editMode ? null : new FloatingActionButton(
        onPressed: () { scan(); },
        tooltip: 'Scan QR Code',
        child: new Icon(Icons.add),
      ),
    );
  }

  _onPasscodeEntered(String enteredPasscode) {
    _passcode = enteredPasscode;
    //_verificationNotifier.add(true);
    setState(() { this.isAuthenticated = true; });
  }

  _onPasscodeCancelled() {

  }

  void scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      Code code = _addCode(barcode);
      if(code != null) {
        await DBProvider.db.newCode(code);
        setState(() { });
      };
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        return null;
      } else {
        return null;
      }
    } on FormatException {
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }
}
