import 'dart:convert';
///json decoder for api response

CurrentPriceData currentPriceDataFromJson(String str) =>
    CurrentPriceData.fromJson(json.decode(str));

String currentPriceDataToJson(CurrentPriceData data) =>
    json.encode(data.toJson());

class CurrentPriceData {
  CurrentPriceData({
    required this.time,
    required this.bpi,
  });

  Time time;
  Bpi bpi;

  factory CurrentPriceData.fromJson(Map<String, dynamic> json) =>
      CurrentPriceData(
        time: Time.fromJson(json["time"]),
        bpi: Bpi.fromJson(json["bpi"]),
      );

  Map<String, dynamic> toJson() => {
        "time": time.toJson(),
        "bpi": bpi.toJson(),
      };
}

class Bpi {
  Bpi({
    required this.usd,
  });

  Eur usd;

  factory Bpi.fromJson(Map<String, dynamic> json) => Bpi(
        usd: Eur.fromJson(json["USD"]),
      );

  Map<String, dynamic> toJson() => {
        "USD": usd.toJson(),
      };
}

class Eur {
  Eur({
    required this.code,
    required this.symbol,
    required this.rate,
    required this.description,
    required this.rateFloat,
  });

  String code;
  String symbol;
  String rate;
  String description;
  double rateFloat;

  factory Eur.fromJson(Map<String, dynamic> json) => Eur(
        code: json["code"],
        symbol: json["symbol"],
        rate: json["rate"],
        description: json["description"],
        rateFloat: json["rate_float"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "symbol": symbol,
        "rate": rate,
        "description": description,
        "rate_float": rateFloat,
      };
}

class Time {
  Time({
    required this.updated,
    required this.updatedIso,
  });

  String updated;
  DateTime updatedIso;

  factory Time.fromJson(Map<String, dynamic> json) => Time(
        updated: json["updated"],
        updatedIso: DateTime.parse(json["updatedISO"]),
      );

  Map<String, dynamic> toJson() => {
        "updated": updated,
        "updatedISO": updatedIso.toIso8601String(),
      };
}
