// This is a generated file - do not edit.
//
// Generated from AcquireApp.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class AcquireRequest_Package_Payload extends $pb.GeneratedMessage {
  factory AcquireRequest_Package_Payload({
    $core.String? packageName,
    $core.int? f2,
    $core.int? f3,
  }) {
    final result = create();
    if (packageName != null) result.packageName = packageName;
    if (f2 != null) result.f2 = f2;
    if (f3 != null) result.f3 = f3;
    return result;
  }

  AcquireRequest_Package_Payload._();

  factory AcquireRequest_Package_Payload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireRequest_Package_Payload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireRequest.Package.Payload',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'packageName', protoName: 'packageName')
    ..aI(2, _omitFieldNames ? '' : 'f2', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'f3', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Package_Payload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Package_Payload copyWith(
          void Function(AcquireRequest_Package_Payload) updates) =>
      super.copyWith(
              (message) => updates(message as AcquireRequest_Package_Payload))
          as AcquireRequest_Package_Payload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Package_Payload create() =>
      AcquireRequest_Package_Payload._();
  @$core.override
  AcquireRequest_Package_Payload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Package_Payload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireRequest_Package_Payload>(create);
  static AcquireRequest_Package_Payload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get packageName => $_getSZ(0);
  @$pb.TagNumber(1)
  set packageName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPackageName() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackageName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get f2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set f2($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasF2() => $_has(1);
  @$pb.TagNumber(2)
  void clearF2() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get f3 => $_getIZ(2);
  @$pb.TagNumber(3)
  set f3($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasF3() => $_has(2);
  @$pb.TagNumber(3)
  void clearF3() => $_clearField(3);
}

class AcquireRequest_Package extends $pb.GeneratedMessage {
  factory AcquireRequest_Package({
    AcquireRequest_Package_Payload? payload,
    $core.int? f2,
  }) {
    final result = create();
    if (payload != null) result.payload = payload;
    if (f2 != null) result.f2 = f2;
    return result;
  }

  AcquireRequest_Package._();

  factory AcquireRequest_Package.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireRequest_Package.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireRequest.Package',
      createEmptyInstance: create)
    ..aOM<AcquireRequest_Package_Payload>(1, _omitFieldNames ? '' : 'payload',
        subBuilder: AcquireRequest_Package_Payload.create)
    ..aI(2, _omitFieldNames ? '' : 'f2', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Package clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Package copyWith(
          void Function(AcquireRequest_Package) updates) =>
      super.copyWith((message) => updates(message as AcquireRequest_Package))
          as AcquireRequest_Package;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Package create() => AcquireRequest_Package._();
  @$core.override
  AcquireRequest_Package createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Package getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireRequest_Package>(create);
  static AcquireRequest_Package? _defaultInstance;

  @$pb.TagNumber(1)
  AcquireRequest_Package_Payload get payload => $_getN(0);
  @$pb.TagNumber(1)
  set payload(AcquireRequest_Package_Payload value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayload() => $_clearField(1);
  @$pb.TagNumber(1)
  AcquireRequest_Package_Payload ensurePayload() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get f2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set f2($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasF2() => $_has(1);
  @$pb.TagNumber(2)
  void clearF2() => $_clearField(2);
}

class AcquireRequest_Version extends $pb.GeneratedMessage {
  factory AcquireRequest_Version({
    $fixnum.Int64? versionCode,
    $core.int? f3,
  }) {
    final result = create();
    if (versionCode != null) result.versionCode = versionCode;
    if (f3 != null) result.f3 = f3;
    return result;
  }

  AcquireRequest_Version._();

  factory AcquireRequest_Version.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireRequest_Version.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireRequest.Version',
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'versionCode', $pb.PbFieldType.OU6,
        protoName: 'versionCode', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'f3', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Version clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Version copyWith(
          void Function(AcquireRequest_Version) updates) =>
      super.copyWith((message) => updates(message as AcquireRequest_Version))
          as AcquireRequest_Version;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Version create() => AcquireRequest_Version._();
  @$core.override
  AcquireRequest_Version createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Version getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireRequest_Version>(create);
  static AcquireRequest_Version? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get versionCode => $_getI64(0);
  @$pb.TagNumber(1)
  set versionCode($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionCode() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.int get f3 => $_getIZ(1);
  @$pb.TagNumber(3)
  set f3($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(3)
  $core.bool hasF3() => $_has(1);
  @$pb.TagNumber(3)
  void clearF3() => $_clearField(3);
}

class AcquireRequest_Message30 extends $pb.GeneratedMessage {
  factory AcquireRequest_Message30({
    $core.int? f1,
    $core.int? f2,
  }) {
    final result = create();
    if (f1 != null) result.f1 = f1;
    if (f2 != null) result.f2 = f2;
    return result;
  }

  AcquireRequest_Message30._();

  factory AcquireRequest_Message30.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireRequest_Message30.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireRequest.Message30',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'f1', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'f2', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Message30 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest_Message30 copyWith(
          void Function(AcquireRequest_Message30) updates) =>
      super.copyWith((message) => updates(message as AcquireRequest_Message30))
          as AcquireRequest_Message30;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Message30 create() => AcquireRequest_Message30._();
  @$core.override
  AcquireRequest_Message30 createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireRequest_Message30 getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireRequest_Message30>(create);
  static AcquireRequest_Message30? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get f1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set f1($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasF1() => $_has(0);
  @$pb.TagNumber(1)
  void clearF1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get f2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set f2($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasF2() => $_has(1);
  @$pb.TagNumber(2)
  void clearF2() => $_clearField(2);
}

class AcquireRequest extends $pb.GeneratedMessage {
  factory AcquireRequest({
    AcquireRequest_Package? package,
    Field? f8,
    AcquireRequest_Version? version,
    $core.int? offerType,
    $core.int? f15,
    $core.String? nonce,
    $core.int? f25,
    AcquireRequest_Message30? m30,
  }) {
    final result = create();
    if (package != null) result.package = package;
    if (f8 != null) result.f8 = f8;
    if (version != null) result.version = version;
    if (offerType != null) result.offerType = offerType;
    if (f15 != null) result.f15 = f15;
    if (nonce != null) result.nonce = nonce;
    if (f25 != null) result.f25 = f25;
    if (m30 != null) result.m30 = m30;
    return result;
  }

  AcquireRequest._();

  factory AcquireRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireRequest',
      createEmptyInstance: create)
    ..aOM<AcquireRequest_Package>(1, _omitFieldNames ? '' : 'package',
        subBuilder: AcquireRequest_Package.create)
    ..aOM<Field>(8, _omitFieldNames ? '' : 'f8', subBuilder: Field.create)
    ..aOM<AcquireRequest_Version>(12, _omitFieldNames ? '' : 'version',
        subBuilder: AcquireRequest_Version.create)
    ..aI(13, _omitFieldNames ? '' : 'offerType',
        protoName: 'offerType', fieldType: $pb.PbFieldType.OU3)
    ..aI(15, _omitFieldNames ? '' : 'f15', fieldType: $pb.PbFieldType.OU3)
    ..aOS(22, _omitFieldNames ? '' : 'nonce')
    ..aI(25, _omitFieldNames ? '' : 'f25', fieldType: $pb.PbFieldType.OU3)
    ..aOM<AcquireRequest_Message30>(30, _omitFieldNames ? '' : 'm30',
        subBuilder: AcquireRequest_Message30.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireRequest copyWith(void Function(AcquireRequest) updates) =>
      super.copyWith((message) => updates(message as AcquireRequest))
          as AcquireRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireRequest create() => AcquireRequest._();
  @$core.override
  AcquireRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireRequest>(create);
  static AcquireRequest? _defaultInstance;

  @$pb.TagNumber(1)
  AcquireRequest_Package get package => $_getN(0);
  @$pb.TagNumber(1)
  set package(AcquireRequest_Package value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => $_clearField(1);
  @$pb.TagNumber(1)
  AcquireRequest_Package ensurePackage() => $_ensure(0);

  @$pb.TagNumber(8)
  Field get f8 => $_getN(1);
  @$pb.TagNumber(8)
  set f8(Field value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasF8() => $_has(1);
  @$pb.TagNumber(8)
  void clearF8() => $_clearField(8);
  @$pb.TagNumber(8)
  Field ensureF8() => $_ensure(1);

  @$pb.TagNumber(12)
  AcquireRequest_Version get version => $_getN(2);
  @$pb.TagNumber(12)
  set version(AcquireRequest_Version value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(12)
  void clearVersion() => $_clearField(12);
  @$pb.TagNumber(12)
  AcquireRequest_Version ensureVersion() => $_ensure(2);

  @$pb.TagNumber(13)
  $core.int get offerType => $_getIZ(3);
  @$pb.TagNumber(13)
  set offerType($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(13)
  $core.bool hasOfferType() => $_has(3);
  @$pb.TagNumber(13)
  void clearOfferType() => $_clearField(13);

  @$pb.TagNumber(15)
  $core.int get f15 => $_getIZ(4);
  @$pb.TagNumber(15)
  set f15($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(15)
  $core.bool hasF15() => $_has(4);
  @$pb.TagNumber(15)
  void clearF15() => $_clearField(15);

  @$pb.TagNumber(22)
  $core.String get nonce => $_getSZ(5);
  @$pb.TagNumber(22)
  set nonce($core.String value) => $_setString(5, value);
  @$pb.TagNumber(22)
  $core.bool hasNonce() => $_has(5);
  @$pb.TagNumber(22)
  void clearNonce() => $_clearField(22);

  @$pb.TagNumber(25)
  $core.int get f25 => $_getIZ(6);
  @$pb.TagNumber(25)
  set f25($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(25)
  $core.bool hasF25() => $_has(6);
  @$pb.TagNumber(25)
  void clearF25() => $_clearField(25);

  @$pb.TagNumber(30)
  AcquireRequest_Message30 get m30 => $_getN(7);
  @$pb.TagNumber(30)
  set m30(AcquireRequest_Message30 value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasM30() => $_has(7);
  @$pb.TagNumber(30)
  void clearM30() => $_clearField(30);
  @$pb.TagNumber(30)
  AcquireRequest_Message30 ensureM30() => $_ensure(7);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties({
    $core.Iterable<
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry>?
        entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase.Properties',
      createEmptyInstance: create)
    ..pPM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry>(
        1, _omitFieldNames ? '' : 'entries',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties?
      _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry>
      get entries => $_getList(0);
}

enum AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_Data {
  boolValue,
  intValue,
  notSet
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry({
    $core.String? key,
    $core.String? boolValue,
    $core.int? intValue,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (boolValue != null) result.boolValue = boolValue;
    if (intValue != null) result.intValue = intValue;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int,
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_Data>
      _AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_DataByTag =
      {
    2: AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_Data
        .boolValue,
    4: AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_Data
        .intValue,
    0: AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_Data
        .notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase.Entry',
      createEmptyInstance: create)
    ..oo(0, [2, 4])
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'boolValue', protoName: 'boolValue')
    ..aI(4, _omitFieldNames ? '' : 'intValue', protoName: 'intValue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry?
      _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(4)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_Data
      whichData() =>
          _AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry_DataByTag[
              $_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(4)
  void clearData() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get boolValue => $_getSZ(1);
  @$pb.TagNumber(2)
  set boolValue($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBoolValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearBoolValue() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.int get intValue => $_getIZ(2);
  @$pb.TagNumber(4)
  set intValue($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(4)
  $core.bool hasIntValue() => $_has(2);
  @$pb.TagNumber(4)
  void clearIntValue() => $_clearField(4);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase({
    $core.String? label,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties?
        properties,
  }) {
    final result = create();
    if (label != null) result.label = label;
    if (properties != null) result.properties = properties;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties>(
        2, _omitFieldNames ? '' : 'properties',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => $_clearField(1);

  @$pb.TagNumber(2)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
      get properties => $_getN(1);
  @$pb.TagNumber(2)
  set properties(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
              value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProperties() => $_has(1);
  @$pb.TagNumber(2)
  void clearProperties() => $_clearField(2);
  @$pb.TagNumber(2)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties
      ensureProperties() => $_ensure(1);
}

/// Looks important, but not used in the current implementation
class AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8({
    $core.Iterable<
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing>?
        someThings,
  }) {
    final result = create();
    if (someThings != null) result.someThings.addAll(someThings);
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Message8',
      createEmptyInstance: create)
    ..pPM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing>(
        1, _omitFieldNames ? '' : 'someThings',
        protoName: 'someThings',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8 copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8?
      _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing>
      get someThings => $_getList(0);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing({
    $core.int? f1,
    $core.int? f2,
    Field? f3,
    Field? f4,
    $core.String? f6,
  }) {
    final result = create();
    if (f1 != null) result.f1 = f1;
    if (f2 != null) result.f2 = f2;
    if (f3 != null) result.f3 = f3;
    if (f4 != null) result.f4 = f4;
    if (f6 != null) result.f6 = f6;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.SomeThing',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'f1')
    ..aI(2, _omitFieldNames ? '' : 'f2')
    ..aOM<Field>(3, _omitFieldNames ? '' : 'f3', subBuilder: Field.create)
    ..aOM<Field>(4, _omitFieldNames ? '' : 'f4', subBuilder: Field.create)
    ..aOS(6, _omitFieldNames ? '' : 'f6')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get f1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set f1($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasF1() => $_has(0);
  @$pb.TagNumber(1)
  void clearF1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get f2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set f2($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasF2() => $_has(1);
  @$pb.TagNumber(2)
  void clearF2() => $_clearField(2);

  @$pb.TagNumber(3)
  Field get f3 => $_getN(2);
  @$pb.TagNumber(3)
  set f3(Field value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasF3() => $_has(2);
  @$pb.TagNumber(3)
  void clearF3() => $_clearField(3);
  @$pb.TagNumber(3)
  Field ensureF3() => $_ensure(2);

  @$pb.TagNumber(4)
  Field get f4 => $_getN(3);
  @$pb.TagNumber(4)
  set f4(Field value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasF4() => $_has(3);
  @$pb.TagNumber(4)
  void clearF4() => $_clearField(4);
  @$pb.TagNumber(4)
  Field ensureF4() => $_ensure(3);

  @$pb.TagNumber(6)
  $core.String get f6 => $_getSZ(4);
  @$pb.TagNumber(6)
  set f6($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasF6() => $_has(4);
  @$pb.TagNumber(6)
  void clearF6() => $_clearField(6);
}

enum AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_ {
  gamePurchase,
  appPurchase,
  notSet
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper({
    $core.int? status,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8?
        m8,
    $core.String? signature,
    AcquireResponseWrapper_AcquireResponse_Response? response,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase?
        gamePurchase,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase?
        appPurchase,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (m8 != null) result.m8 = m8;
    if (signature != null) result.signature = signature;
    if (response != null) result.response = response;
    if (gamePurchase != null) result.gamePurchase = gamePurchase;
    if (appPurchase != null) result.appPurchase = appPurchase;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int,
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_>
      _AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_ByTag =
      {
    12: AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_
        .gamePurchase,
    15: AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_
        .appPurchase,
    0: AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_
        .notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper',
      createEmptyInstance: create)
    ..oo(0, [12, 15])
    ..aI(7, _omitFieldNames ? '' : 'status')
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8>(
        8, _omitFieldNames ? '' : 'm8',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
                .create)
    ..aOS(9, _omitFieldNames ? '' : 'signature')
    ..aOM<AcquireResponseWrapper_AcquireResponse_Response>(
        10, _omitFieldNames ? '' : 'response',
        subBuilder: AcquireResponseWrapper_AcquireResponse_Response.create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase>(
        12, _omitFieldNames ? '' : 'gamePurchase',
        protoName: 'gamePurchase',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
                .create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase>(
        15, _omitFieldNames ? '' : 'appPurchase',
        protoName: 'appPurchase',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper?
      _defaultInstance;

  @$pb.TagNumber(12)
  @$pb.TagNumber(15)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_
      whichPurchase() =>
          _AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_ByTag[
              $_whichOneof(0)]!;
  @$pb.TagNumber(12)
  @$pb.TagNumber(15)
  void clearPurchase() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(7)
  $core.int get status => $_getIZ(0);
  @$pb.TagNumber(7)
  set status($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(7)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(7)
  void clearStatus() => $_clearField(7);

  @$pb.TagNumber(8)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
      get m8 => $_getN(1);
  @$pb.TagNumber(8)
  set m8(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
              value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasM8() => $_has(1);
  @$pb.TagNumber(8)
  void clearM8() => $_clearField(8);
  @$pb.TagNumber(8)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8
      ensureM8() => $_ensure(1);

  @$pb.TagNumber(9)
  $core.String get signature => $_getSZ(2);
  @$pb.TagNumber(9)
  set signature($core.String value) => $_setString(2, value);
  @$pb.TagNumber(9)
  $core.bool hasSignature() => $_has(2);
  @$pb.TagNumber(9)
  void clearSignature() => $_clearField(9);

  @$pb.TagNumber(10)
  AcquireResponseWrapper_AcquireResponse_Response get response => $_getN(3);
  @$pb.TagNumber(10)
  set response(AcquireResponseWrapper_AcquireResponse_Response value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasResponse() => $_has(3);
  @$pb.TagNumber(10)
  void clearResponse() => $_clearField(10);
  @$pb.TagNumber(10)
  AcquireResponseWrapper_AcquireResponse_Response ensureResponse() =>
      $_ensure(3);

  @$pb.TagNumber(12)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      get gamePurchase => $_getN(4);
  @$pb.TagNumber(12)
  set gamePurchase(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
              value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasGamePurchase() => $_has(4);
  @$pb.TagNumber(12)
  void clearGamePurchase() => $_clearField(12);
  @$pb.TagNumber(12)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      ensureGamePurchase() => $_ensure(4);

  @$pb.TagNumber(15)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      get appPurchase => $_getN(5);
  @$pb.TagNumber(15)
  set appPurchase(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
              value) =>
      $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasAppPurchase() => $_has(5);
  @$pb.TagNumber(15)
  void clearAppPurchase() => $_clearField(15);
  @$pb.TagNumber(15)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase
      ensureAppPurchase() => $_ensure(5);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload({
    $core.String? encoded,
  }) {
    final result = create();
    if (encoded != null) result.encoded = encoded;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.Payload.EncodedPayload',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'encoded')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get encoded => $_getSZ(0);
  @$pb.TagNumber(1)
  set encoded($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEncoded() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncoded() => $_clearField(1);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload({
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo?
        appInfo,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload?
        encodedPayload,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload?
        subPayload,
  }) {
    final result = create();
    if (appInfo != null) result.appInfo = appInfo;
    if (encodedPayload != null) result.encodedPayload = encodedPayload;
    if (subPayload != null) result.subPayload = subPayload;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.Payload',
      createEmptyInstance: create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo>(
        1, _omitFieldNames ? '' : 'appInfo',
        protoName: 'appInfo',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
                .create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload>(
        2, _omitFieldNames ? '' : 'encodedPayload',
        protoName: 'encodedPayload',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
                .create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload>(
        5, _omitFieldNames ? '' : 'subPayload',
        protoName: 'subPayload',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload?
      _defaultInstance;

  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
      get appInfo => $_getN(0);
  @$pb.TagNumber(1)
  set appInfo(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
              value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAppInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
      ensureAppInfo() => $_ensure(0);

  @$pb.TagNumber(2)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
      get encodedPayload => $_getN(1);
  @$pb.TagNumber(2)
  set encodedPayload(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
              value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEncodedPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncodedPayload() => $_clearField(2);
  @$pb.TagNumber(2)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload
      ensureEncodedPayload() => $_ensure(1);

  @$pb.TagNumber(5)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      get subPayload => $_getN(2);
  @$pb.TagNumber(5)
  set subPayload(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
              value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSubPayload() => $_has(2);
  @$pb.TagNumber(5)
  void clearSubPayload() => $_clearField(5);
  @$pb.TagNumber(5)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      ensureSubPayload() => $_ensure(2);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo({
    $core.String? packageName,
    $fixnum.Int64? seven,
  }) {
    final result = create();
    if (packageName != null) result.packageName = packageName;
    if (seven != null) result.seven = seven;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.AppInfo',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'packageName', protoName: 'packageName')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'seven', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
              ._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get packageName => $_getSZ(0);
  @$pb.TagNumber(1)
  set packageName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPackageName() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackageName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get seven => $_getI64(1);
  @$pb.TagNumber(2)
  set seven($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeven() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeven() => $_clearField(2);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package({
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload?
        payload,
  }) {
    final result = create();
    if (payload != null) result.payload = payload;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package',
      createEmptyInstance: create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload>(
        1, _omitFieldNames ? '' : 'payload',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
      create() =>
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package>(
          create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package?
      _defaultInstance;

  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      get payload => $_getN(0);
  @$pb.TagNumber(1)
  set payload(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
              value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayload() => $_clearField(1);
  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload
      ensurePayload() => $_ensure(0);
}

class AcquireResponseWrapper_AcquireResponse_AcquirePayload
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload({
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper?
        purchase,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package? package,
  }) {
    final result = create();
    if (purchase != null) result.purchase = purchase;
    if (package != null) result.package = package;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_AcquirePayload._();

  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_AcquirePayload.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.AcquirePayload',
      createEmptyInstance: create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper>(
        3, _omitFieldNames ? '' : 'purchase',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
                .create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package>(
        4, _omitFieldNames ? '' : 'package',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_AcquirePayload copyWith(
          void Function(AcquireResponseWrapper_AcquireResponse_AcquirePayload)
              updates) =>
      super.copyWith((message) => updates(
              message as AcquireResponseWrapper_AcquireResponse_AcquirePayload))
          as AcquireResponseWrapper_AcquireResponse_AcquirePayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload create() =>
      AcquireResponseWrapper_AcquireResponse_AcquirePayload._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_AcquirePayload createEmptyInstance() =>
      create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AcquireResponseWrapper_AcquireResponse_AcquirePayload>(create);
  static AcquireResponseWrapper_AcquireResponse_AcquirePayload?
      _defaultInstance;

  @$pb.TagNumber(3)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
      get purchase => $_getN(0);
  @$pb.TagNumber(3)
  set purchase(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
              value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPurchase() => $_has(0);
  @$pb.TagNumber(3)
  void clearPurchase() => $_clearField(3);
  @$pb.TagNumber(3)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper
      ensurePurchase() => $_ensure(0);

  @$pb.TagNumber(4)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package get package =>
      $_getN(1);
  @$pb.TagNumber(4)
  set package(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
              value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPackage() => $_has(1);
  @$pb.TagNumber(4)
  void clearPackage() => $_clearField(4);
  @$pb.TagNumber(4)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package
      ensurePackage() => $_ensure(1);
}

class AcquireResponseWrapper_AcquireResponse_Response_Payload_Data
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_Response_Payload_Data({
    $core.String? key,
    $core.int? value,
  }) {
    final result = create();
    if (key != null) result.key = key;
    if (value != null) result.value = value;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data._();

  factory AcquireResponseWrapper_AcquireResponse_Response_Payload_Data.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_Response_Payload_Data.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.Response.Payload.Data',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aI(5, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data copyWith(
          void Function(
                  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_Response_Payload_Data))
          as AcquireResponseWrapper_AcquireResponse_Response_Payload_Data;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_Response_Payload_Data
      create() =>
          AcquireResponseWrapper_AcquireResponse_Response_Payload_Data._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_Response_Payload_Data
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AcquireResponseWrapper_AcquireResponse_Response_Payload_Data>(create);
  static AcquireResponseWrapper_AcquireResponse_Response_Payload_Data?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(5)
  $core.int get value => $_getIZ(1);
  @$pb.TagNumber(5)
  set value($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(5)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(5)
  void clearValue() => $_clearField(5);
}

class AcquireResponseWrapper_AcquireResponse_Response_Payload
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_Response_Payload({
    AcquireResponseWrapper_AcquireResponse_Response_Payload_Data? data,
  }) {
    final result = create();
    if (data != null) result.data = data;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_Response_Payload._();

  factory AcquireResponseWrapper_AcquireResponse_Response_Payload.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_Response_Payload.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.Response.Payload',
      createEmptyInstance: create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_Response_Payload_Data>(
        1, _omitFieldNames ? '' : 'data',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_Response_Payload_Data.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_Response_Payload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_Response_Payload copyWith(
          void Function(AcquireResponseWrapper_AcquireResponse_Response_Payload)
              updates) =>
      super.copyWith((message) => updates(message
              as AcquireResponseWrapper_AcquireResponse_Response_Payload))
          as AcquireResponseWrapper_AcquireResponse_Response_Payload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_Response_Payload create() =>
      AcquireResponseWrapper_AcquireResponse_Response_Payload._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_Response_Payload
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_Response_Payload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AcquireResponseWrapper_AcquireResponse_Response_Payload>(create);
  static AcquireResponseWrapper_AcquireResponse_Response_Payload?
      _defaultInstance;

  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data get data =>
      $_getN(0);
  @$pb.TagNumber(1)
  set data(
          AcquireResponseWrapper_AcquireResponse_Response_Payload_Data value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);
  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse_Response_Payload_Data ensureData() =>
      $_ensure(0);
}

class AcquireResponseWrapper_AcquireResponse_Response
    extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse_Response({
    $core.int? status,
    AcquireResponseWrapper_AcquireResponse_Response_Payload? payload,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (payload != null) result.payload = payload;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse_Response._();

  factory AcquireResponseWrapper_AcquireResponse_Response.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse_Response.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AcquireResponseWrapper.AcquireResponse.Response',
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'status')
    ..aOM<AcquireResponseWrapper_AcquireResponse_Response_Payload>(
        2, _omitFieldNames ? '' : 'payload',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_Response_Payload.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse_Response copyWith(
          void Function(AcquireResponseWrapper_AcquireResponse_Response)
              updates) =>
      super.copyWith((message) => updates(
              message as AcquireResponseWrapper_AcquireResponse_Response))
          as AcquireResponseWrapper_AcquireResponse_Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_Response create() =>
      AcquireResponseWrapper_AcquireResponse_Response._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse_Response createEmptyInstance() =>
      create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse_Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AcquireResponseWrapper_AcquireResponse_Response>(create);
  static AcquireResponseWrapper_AcquireResponse_Response? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get status => $_getIZ(0);
  @$pb.TagNumber(1)
  set status($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  AcquireResponseWrapper_AcquireResponse_Response_Payload get payload =>
      $_getN(1);
  @$pb.TagNumber(2)
  set payload(AcquireResponseWrapper_AcquireResponse_Response_Payload value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField(2);
  @$pb.TagNumber(2)
  AcquireResponseWrapper_AcquireResponse_Response_Payload ensurePayload() =>
      $_ensure(1);
}

class AcquireResponseWrapper_AcquireResponse extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper_AcquireResponse({
    AcquireResponseWrapper_AcquireResponse_AcquirePayload? acquirePayload,
  }) {
    final result = create();
    if (acquirePayload != null) result.acquirePayload = acquirePayload;
    return result;
  }

  AcquireResponseWrapper_AcquireResponse._();

  factory AcquireResponseWrapper_AcquireResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper_AcquireResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireResponseWrapper.AcquireResponse',
      createEmptyInstance: create)
    ..aOM<AcquireResponseWrapper_AcquireResponse_AcquirePayload>(
        94, _omitFieldNames ? '' : 'acquirePayload',
        protoName: 'acquirePayload',
        subBuilder:
            AcquireResponseWrapper_AcquireResponse_AcquirePayload.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper_AcquireResponse copyWith(
          void Function(AcquireResponseWrapper_AcquireResponse) updates) =>
      super.copyWith((message) =>
              updates(message as AcquireResponseWrapper_AcquireResponse))
          as AcquireResponseWrapper_AcquireResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse create() =>
      AcquireResponseWrapper_AcquireResponse._();
  @$core.override
  AcquireResponseWrapper_AcquireResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper_AcquireResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AcquireResponseWrapper_AcquireResponse>(create);
  static AcquireResponseWrapper_AcquireResponse? _defaultInstance;

  @$pb.TagNumber(94)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload get acquirePayload =>
      $_getN(0);
  @$pb.TagNumber(94)
  set acquirePayload(
          AcquireResponseWrapper_AcquireResponse_AcquirePayload value) =>
      $_setField(94, value);
  @$pb.TagNumber(94)
  $core.bool hasAcquirePayload() => $_has(0);
  @$pb.TagNumber(94)
  void clearAcquirePayload() => $_clearField(94);
  @$pb.TagNumber(94)
  AcquireResponseWrapper_AcquireResponse_AcquirePayload
      ensureAcquirePayload() => $_ensure(0);
}

class AcquireResponseWrapper extends $pb.GeneratedMessage {
  factory AcquireResponseWrapper({
    AcquireResponseWrapper_AcquireResponse? acquireResponse,
  }) {
    final result = create();
    if (acquireResponse != null) result.acquireResponse = acquireResponse;
    return result;
  }

  AcquireResponseWrapper._();

  factory AcquireResponseWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcquireResponseWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcquireResponseWrapper',
      createEmptyInstance: create)
    ..aOM<AcquireResponseWrapper_AcquireResponse>(
        1, _omitFieldNames ? '' : 'acquireResponse',
        protoName: 'acquireResponse',
        subBuilder: AcquireResponseWrapper_AcquireResponse.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcquireResponseWrapper copyWith(
          void Function(AcquireResponseWrapper) updates) =>
      super.copyWith((message) => updates(message as AcquireResponseWrapper))
          as AcquireResponseWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper create() => AcquireResponseWrapper._();
  @$core.override
  AcquireResponseWrapper createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AcquireResponseWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcquireResponseWrapper>(create);
  static AcquireResponseWrapper? _defaultInstance;

  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse get acquireResponse => $_getN(0);
  @$pb.TagNumber(1)
  set acquireResponse(AcquireResponseWrapper_AcquireResponse value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAcquireResponse() => $_has(0);
  @$pb.TagNumber(1)
  void clearAcquireResponse() => $_clearField(1);
  @$pb.TagNumber(1)
  AcquireResponseWrapper_AcquireResponse ensureAcquireResponse() => $_ensure(0);
}

class Field extends $pb.GeneratedMessage {
  factory Field() => create();

  Field._();

  factory Field.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Field.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Field',
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Field clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Field copyWith(void Function(Field) updates) =>
      super.copyWith((message) => updates(message as Field)) as Field;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Field create() => Field._();
  @$core.override
  Field createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Field getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Field>(create);
  static Field? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
