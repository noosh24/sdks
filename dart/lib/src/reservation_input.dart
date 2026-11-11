part of 'client.dart';

final class PreOrderLine {
  const PreOrderLine({required this.itemId, required this.qty, this.note});

  final String itemId;
  final int qty;
  final String? note;

  Map<String, Object> toJson() => {'itemId': itemId, 'qty': qty, 'note': ?note};
}

final class NewReservation {
  const NewReservation({
    required this.date,
    required this.time,
    required this.guests,
    required this.guestName,
    required this.phone,
    this.email,
    this.tableId,
    this.zone,
    this.specialRequest,
    this.allergyNote,
    this.birthday,
    this.childChair,
    this.preOrder,
    this.externalRef,
  });

  final CalendarDate date;
  final String time;
  final int guests;
  final String guestName;
  final String phone;
  final String? email;
  final String? tableId;
  final String? zone;
  final String? specialRequest;
  final String? allergyNote;
  final bool? birthday;
  final bool? childChair;
  final List<PreOrderLine>? preOrder;
  final String? externalRef;

  bool get isIdempotent => externalRef?.trim().isNotEmpty ?? false;

  Map<String, Object> toJson() => {
    'date': '$date',
    'time': time,
    'guests': guests,
    'guestName': guestName,
    'phone': phone,
    'email': ?email,
    'tableId': ?tableId,
    'zone': ?zone,
    'specialRequest': ?specialRequest,
    'allergyNote': ?allergyNote,
    'birthday': ?birthday,
    'childChair': ?childChair,
    if (preOrder case final lines?)
      'preOrder': [for (final line in lines) line.toJson()],
    'externalRef': ?externalRef,
  };
}

final class CreateReservationResult {
  const CreateReservationResult({
    required this.reservation,
    required this.created,
  });

  final Reservation reservation;
  final bool created;
}
