// lib/models/timestamp_adapter.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = 0; // Choisissez un ID unique

  @override
  Timestamp read(BinaryReader reader) {
    final milliseconds = reader.readInt();
    return Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}