import '../../data/models/itinerary.dart';

class TripEntity {
  final int? id;
  final String title;
  final String startDate;
  final String endDate;
  final List<TripDayEntity> days;

  TripEntity({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory TripEntity.fromModel(Trip m) => TripEntity(
    id: m.id == 0 ? null : m.id,
    title: m.title,
    startDate: m.startDate,
    endDate: m.endDate,
    days: m.days.map(TripDayEntity.fromModel).toList(),
  );

  Trip toModel() {
    final t = Trip()
      ..title = title
      ..startDate = startDate
      ..endDate = endDate
      ..days = days.map((d) => d.toModel()).toList();
    if (id != null) t.id = id!;
    return t;
  }
}

class TripDayEntity {
  final String date;
  final String summary;
  final List<TripItemEntity> items;

  TripDayEntity({
    required this.date,
    required this.summary,
    required this.items,
  });

  factory TripDayEntity.fromModel(TripDay m) => TripDayEntity(
    date: m.date,
    summary: m.summary,
    items: m.items.map(TripItemEntity.fromModel).toList(),
  );

  TripDay toModel() => TripDay()
    ..date = date
    ..summary = summary
    ..items = items.map((i) => i.toModel()).toList();
}

class TripItemEntity {
  final String time;
  final String activity;
  final String location;
  TripItemEntity({
    required this.time,
    required this.activity,
    required this.location,
  });

  factory TripItemEntity.fromModel(TripItem m) =>
      TripItemEntity(time: m.time, activity: m.activity, location: m.location);

  TripItem toModel() => TripItem()
    ..time = time
    ..activity = activity
    ..location = location;
}
