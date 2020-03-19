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
  String digits;
  String algorithm;
  String issuer;
  String period;

  Code({
    this.id,
    this.user,
    this.site,
    this.secret,
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
        "digits": digits,
        "algorithm": algorithm,
        "issuer": issuer,
        "period": period,
      };
}
