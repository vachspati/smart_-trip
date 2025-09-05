// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip()
  ..id = (json['id'] as num).toInt()
  ..title = json['title'] as String
  ..startDate = json['startDate'] as String
  ..endDate = json['endDate'] as String
  ..days = (json['days'] as List<dynamic>)
      .map((e) => TripDay.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'days': instance.days,
    };

TripDay _$TripDayFromJson(Map<String, dynamic> json) => TripDay()
  ..date = json['date'] as String
  ..summary = json['summary'] as String
  ..items = (json['items'] as List<dynamic>)
      .map((e) => TripItem.fromJson(e as Map<String, dynamic>))
      .toList();

Map<String, dynamic> _$TripDayToJson(TripDay instance) => <String, dynamic>{
      'date': instance.date,
      'summary': instance.summary,
      'items': instance.items,
    };

TripItem _$TripItemFromJson(Map<String, dynamic> json) => TripItem()
  ..time = json['time'] as String
  ..activity = json['activity'] as String
  ..location = json['location'] as String;

Map<String, dynamic> _$TripItemToJson(TripItem instance) => <String, dynamic>{
      'time': instance.time,
      'activity': instance.activity,
      'location': instance.location,
    };
