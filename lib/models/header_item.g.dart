// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'header_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HeaderItemAdapter extends TypeAdapter<HeaderItem> {
  @override
  final int typeId = 3;

  @override
  HeaderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HeaderItem(
      key: fields[0] as String,
      value: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HeaderItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeaderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
