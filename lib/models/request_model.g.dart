// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RequestModelAdapter extends TypeAdapter<RequestModel> {
  @override
  final int typeId = 2;

  @override
  RequestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RequestModel(
      id: fields[0] as String,
      name: fields[1] as String,
      method: fields[2] as String,
      url: fields[3] as String,
      headersList: (fields[4] as List?)?.cast<HeaderItem>(),
      body: fields[5] as String?,
      queryParamsList: (fields[6] as List?)?.cast<HeaderItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, RequestModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.headersList)
      ..writeByte(5)
      ..write(obj.body)
      ..writeByte(6)
      ..write(obj.queryParamsList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
