import 'package:json_annotation/json_annotation.dart';

part 'itinerary.g.dart';

@JsonSerializable()
class Trip {
  int id = 0;
  late String title;
  late String startDate; // ISO (yyyy-MM-dd)
  late String endDate; // ISO (yyyy-MM-dd)
  late List<TripDay> days;

  Trip();

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  Map<String, dynamic> toJson() => _$TripToJson(this);
}

@JsonSerializable()
class TripDay {
  late String date; // ISO
  late String summary;
  late List<TripItem> items;

  TripDay();

  factory TripDay.fromJson(Map<String, dynamic> json) =>
      _$TripDayFromJson(json);

  Map<String, dynamic> toJson() => _$TripDayToJson(this);
}

@JsonSerializable()
class TripItem {
  late String time; // HH:mm
  late String activity;
  late String location; // "lat,lng"

  TripItem();

  factory TripItem.fromJson(Map<String, dynamic> json) =>
      _$TripItemFromJson(json);

  Map<String, dynamic> toJson() => _$TripItemToJson(this);
}
