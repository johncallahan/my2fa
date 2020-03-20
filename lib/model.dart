import 'dart:convert';

Code codeFromJson(String str) {
  final jsonData = json.decode(str);
  return Code.fromMap(jsonData);
}

String codeToJson(Code data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class Code {
  int id;
  String user;
  String site;
  String secret;
  String salt;
  String digits;
  String algorithm;
  String issuer;
  String period;

  Code({
    this.id,
    this.user,
    this.site,
    this.secret,
    this.salt,
    this.digits,
    this.algorithm,
    this.issuer,
    this.period,
  });

  factory Code.fromMap(Map<String, dynamic> json) => new Code(
        id: json["id"],
        user: json["user"],
        site: json["site"],
        secret: json["secret"],
        salt: json["salt"],
        digits: json["digits"],
        algorithm: json["algorithm"],
        issuer: json["issuer"],
        period: json["period"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "user": user,
        "site": site,
        "secret": secret,
        "salt": salt,
        "digits": digits,
        "algorithm": algorithm,
        "issuer": issuer,
        "period": period,
      };
}
