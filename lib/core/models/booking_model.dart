import 'package:flutter/material.dart';

class BookingModel {
  final String id;
  final String userId;
  final String date;
  final String bookingDate;
  final TimeOfDay time;
  String status; // Remove final to allow updates
  final double price;
  final String serviceName;
  final String serviceType;
  final String repeat;
  final double totalPrice;
  final List<String> additionalServices;

  BookingModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.bookingDate,
    required this.time,
    required this.status,
    required this.price,
    required this.serviceName,
    required this.serviceType,
    required this.repeat,
    required this.totalPrice,
    required this.additionalServices,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'bookingDate': bookingDate,
      'time': '${time.hour}:${time.minute}',
      'status': status,
      'price': price,
      'serviceName': serviceName,
      'serviceType': serviceType,
      'repeat': repeat,
      'totalPrice': totalPrice,
      'additionalServices': additionalServices,
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String timeStr = json['time'] as String;
    List<String> timeParts = timeStr.split(':');

    return BookingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: json['date'] as String,
      bookingDate: json['bookingDate'] as String,
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      status: json['status'] as String,
      price: (json['price'] as num).toDouble(),
      serviceName: json['serviceName'] as String,
      serviceType: json['serviceType'] as String,
      repeat: json['repeat'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      additionalServices: List<String>.from(json['additionalServices'] ?? []),
    );
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? date,
    String? bookingDate,
    TimeOfDay? time,
    String? status,
    double? price,
    String? serviceName,
    String? serviceType,
    String? repeat,
    double? totalPrice,
    List<String>? additionalServices,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      bookingDate: bookingDate ?? this.bookingDate,
      time: time ?? this.time,
      status: status ?? this.status,
      price: price ?? this.price,
      serviceName: serviceName ?? this.serviceName,
      serviceType: serviceType ?? this.serviceType,
      repeat: repeat ?? this.repeat,
      totalPrice: totalPrice ?? this.totalPrice,
      additionalServices: additionalServices ?? this.additionalServices,
    );
  }
}
