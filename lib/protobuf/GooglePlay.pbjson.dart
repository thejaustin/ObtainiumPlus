// This is a generated file - do not edit.
//
// Generated from GooglePlay.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use androidAppDeliveryDataDescriptor instead')
const AndroidAppDeliveryData$json = {
  '1': 'AndroidAppDeliveryData',
  '2': [
    {'1': 'downloadSize', '3': 1, '4': 1, '5': 3, '10': 'downloadSize'},
    {'1': 'sha1', '3': 2, '4': 1, '5': 9, '10': 'sha1'},
    {'1': 'downloadUrl', '3': 3, '4': 1, '5': 9, '10': 'downloadUrl'},
    {
      '1': 'additionalFile',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.AppFileMetadata',
      '10': 'additionalFile'
    },
    {
      '1': 'downloadAuthCookie',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.HttpCookie',
      '10': 'downloadAuthCookie'
    },
    {'1': 'forwardLocked', '3': 6, '4': 1, '5': 8, '10': 'forwardLocked'},
    {'1': 'refundTimeout', '3': 7, '4': 1, '5': 3, '10': 'refundTimeout'},
    {
      '1': 'serverInitiated',
      '3': 8,
      '4': 1,
      '5': 8,
      '7': 'true',
      '10': 'serverInitiated'
    },
    {
      '1': 'postInstallRefundWindowMillis',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'postInstallRefundWindowMillis'
    },
    {
      '1': 'immediateStartNeeded',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'immediateStartNeeded'
    },
    {
      '1': 'patchData',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppPatchData',
      '10': 'patchData'
    },
    {
      '1': 'encryptionParams',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.EncryptionParams',
      '10': 'encryptionParams'
    },
    {
      '1': 'compressedDownloadUrl',
      '3': 13,
      '4': 1,
      '5': 9,
      '10': 'compressedDownloadUrl'
    },
    {'1': 'compressedSize', '3': 14, '4': 1, '5': 3, '10': 'compressedSize'},
    {
      '1': 'splitDeliveryData',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.SplitDeliveryData',
      '10': 'splitDeliveryData'
    },
    {'1': 'installLocation', '3': 16, '4': 1, '5': 5, '10': 'installLocation'},
    {'1': 'type', '3': 17, '4': 1, '5': 3, '10': 'type'},
    {
      '1': 'compressedAppData',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.CompressedAppData',
      '10': 'compressedAppData'
    },
    {'1': 'sha256', '3': 19, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `AndroidAppDeliveryData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidAppDeliveryDataDescriptor = $convert.base64Decode(
    'ChZBbmRyb2lkQXBwRGVsaXZlcnlEYXRhEiIKDGRvd25sb2FkU2l6ZRgBIAEoA1IMZG93bmxvYW'
    'RTaXplEhIKBHNoYTEYAiABKAlSBHNoYTESIAoLZG93bmxvYWRVcmwYAyABKAlSC2Rvd25sb2Fk'
    'VXJsEjgKDmFkZGl0aW9uYWxGaWxlGAQgAygLMhAuQXBwRmlsZU1ldGFkYXRhUg5hZGRpdGlvbm'
    'FsRmlsZRI7ChJkb3dubG9hZEF1dGhDb29raWUYBSADKAsyCy5IdHRwQ29va2llUhJkb3dubG9h'
    'ZEF1dGhDb29raWUSJAoNZm9yd2FyZExvY2tlZBgGIAEoCFINZm9yd2FyZExvY2tlZBIkCg1yZW'
    'Z1bmRUaW1lb3V0GAcgASgDUg1yZWZ1bmRUaW1lb3V0Ei4KD3NlcnZlckluaXRpYXRlZBgIIAEo'
    'CDoEdHJ1ZVIPc2VydmVySW5pdGlhdGVkEkQKHXBvc3RJbnN0YWxsUmVmdW5kV2luZG93TWlsbG'
    'lzGAkgASgDUh1wb3N0SW5zdGFsbFJlZnVuZFdpbmRvd01pbGxpcxIyChRpbW1lZGlhdGVTdGFy'
    'dE5lZWRlZBgKIAEoCFIUaW1tZWRpYXRlU3RhcnROZWVkZWQSMgoJcGF0Y2hEYXRhGAsgASgLMh'
    'QuQW5kcm9pZEFwcFBhdGNoRGF0YVIJcGF0Y2hEYXRhEj0KEGVuY3J5cHRpb25QYXJhbXMYDCAB'
    'KAsyES5FbmNyeXB0aW9uUGFyYW1zUhBlbmNyeXB0aW9uUGFyYW1zEjQKFWNvbXByZXNzZWREb3'
    'dubG9hZFVybBgNIAEoCVIVY29tcHJlc3NlZERvd25sb2FkVXJsEiYKDmNvbXByZXNzZWRTaXpl'
    'GA4gASgDUg5jb21wcmVzc2VkU2l6ZRJAChFzcGxpdERlbGl2ZXJ5RGF0YRgPIAMoCzISLlNwbG'
    'l0RGVsaXZlcnlEYXRhUhFzcGxpdERlbGl2ZXJ5RGF0YRIoCg9pbnN0YWxsTG9jYXRpb24YECAB'
    'KAVSD2luc3RhbGxMb2NhdGlvbhISCgR0eXBlGBEgASgDUgR0eXBlEkAKEWNvbXByZXNzZWRBcH'
    'BEYXRhGBIgASgLMhIuQ29tcHJlc3NlZEFwcERhdGFSEWNvbXByZXNzZWRBcHBEYXRhEhYKBnNo'
    'YTI1NhgTIAEoCVIGc2hhMjU2');

@$core.Deprecated('Use splitDeliveryDataDescriptor instead')
const SplitDeliveryData$json = {
  '1': 'SplitDeliveryData',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'downloadSize', '3': 2, '4': 1, '5': 3, '10': 'downloadSize'},
    {'1': 'compressedSize', '3': 3, '4': 1, '5': 3, '10': 'compressedSize'},
    {'1': 'sha1', '3': 4, '4': 1, '5': 9, '10': 'sha1'},
    {'1': 'downloadUrl', '3': 5, '4': 1, '5': 9, '10': 'downloadUrl'},
    {
      '1': 'compressedDownloadUrl',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'compressedDownloadUrl'
    },
    {
      '1': 'patchData',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppPatchData',
      '10': 'patchData'
    },
    {
      '1': 'compressedAppData',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.CompressedAppData',
      '10': 'compressedAppData'
    },
    {'1': 'sha256', '3': 9, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `SplitDeliveryData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List splitDeliveryDataDescriptor = $convert.base64Decode(
    'ChFTcGxpdERlbGl2ZXJ5RGF0YRISCgRuYW1lGAEgASgJUgRuYW1lEiIKDGRvd25sb2FkU2l6ZR'
    'gCIAEoA1IMZG93bmxvYWRTaXplEiYKDmNvbXByZXNzZWRTaXplGAMgASgDUg5jb21wcmVzc2Vk'
    'U2l6ZRISCgRzaGExGAQgASgJUgRzaGExEiAKC2Rvd25sb2FkVXJsGAUgASgJUgtkb3dubG9hZF'
    'VybBI0ChVjb21wcmVzc2VkRG93bmxvYWRVcmwYBiABKAlSFWNvbXByZXNzZWREb3dubG9hZFVy'
    'bBIyCglwYXRjaERhdGEYByABKAsyFC5BbmRyb2lkQXBwUGF0Y2hEYXRhUglwYXRjaERhdGESQA'
    'oRY29tcHJlc3NlZEFwcERhdGEYCCABKAsyEi5Db21wcmVzc2VkQXBwRGF0YVIRY29tcHJlc3Nl'
    'ZEFwcERhdGESFgoGc2hhMjU2GAkgASgJUgZzaGEyNTY=');

@$core.Deprecated('Use androidAppPatchDataDescriptor instead')
const AndroidAppPatchData$json = {
  '1': 'AndroidAppPatchData',
  '2': [
    {'1': 'baseVersionCode', '3': 1, '4': 1, '5': 5, '10': 'baseVersionCode'},
    {'1': 'baseSha1', '3': 2, '4': 1, '5': 9, '10': 'baseSha1'},
    {'1': 'downloadUrl', '3': 3, '4': 1, '5': 9, '10': 'downloadUrl'},
    {'1': 'patchFormat', '3': 4, '4': 1, '5': 5, '7': '1', '10': 'patchFormat'},
    {'1': 'maxPatchSize', '3': 5, '4': 1, '5': 3, '10': 'maxPatchSize'},
  ],
};

/// Descriptor for `AndroidAppPatchData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidAppPatchDataDescriptor = $convert.base64Decode(
    'ChNBbmRyb2lkQXBwUGF0Y2hEYXRhEigKD2Jhc2VWZXJzaW9uQ29kZRgBIAEoBVIPYmFzZVZlcn'
    'Npb25Db2RlEhoKCGJhc2VTaGExGAIgASgJUghiYXNlU2hhMRIgCgtkb3dubG9hZFVybBgDIAEo'
    'CVILZG93bmxvYWRVcmwSIwoLcGF0Y2hGb3JtYXQYBCABKAU6ATFSC3BhdGNoRm9ybWF0EiIKDG'
    '1heFBhdGNoU2l6ZRgFIAEoA1IMbWF4UGF0Y2hTaXpl');

@$core.Deprecated('Use compressedAppDataDescriptor instead')
const CompressedAppData$json = {
  '1': 'CompressedAppData',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 3, '10': 'type'},
    {'1': 'size', '3': 2, '4': 1, '5': 3, '10': 'size'},
    {'1': 'downloadUrl', '3': 3, '4': 1, '5': 9, '10': 'downloadUrl'},
  ],
};

/// Descriptor for `CompressedAppData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compressedAppDataDescriptor = $convert.base64Decode(
    'ChFDb21wcmVzc2VkQXBwRGF0YRISCgR0eXBlGAEgASgDUgR0eXBlEhIKBHNpemUYAiABKANSBH'
    'NpemUSIAoLZG93bmxvYWRVcmwYAyABKAlSC2Rvd25sb2FkVXJs');

@$core.Deprecated('Use appFileMetadataDescriptor instead')
const AppFileMetadata$json = {
  '1': 'AppFileMetadata',
  '2': [
    {'1': 'fileType', '3': 1, '4': 1, '5': 5, '10': 'fileType'},
    {'1': 'versionCode', '3': 2, '4': 1, '5': 5, '10': 'versionCode'},
    {'1': 'size', '3': 3, '4': 1, '5': 3, '10': 'size'},
    {'1': 'downloadUrl', '3': 4, '4': 1, '5': 9, '10': 'downloadUrl'},
    {
      '1': 'patchData',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppPatchData',
      '10': 'patchData'
    },
    {'1': 'compressedSize', '3': 6, '4': 1, '5': 3, '10': 'compressedSize'},
    {
      '1': 'compressedDownloadUrl',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'compressedDownloadUrl'
    },
    {'1': 'sha1', '3': 8, '4': 1, '5': 9, '10': 'sha1'},
  ],
};

/// Descriptor for `AppFileMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appFileMetadataDescriptor = $convert.base64Decode(
    'Cg9BcHBGaWxlTWV0YWRhdGESGgoIZmlsZVR5cGUYASABKAVSCGZpbGVUeXBlEiAKC3ZlcnNpb2'
    '5Db2RlGAIgASgFUgt2ZXJzaW9uQ29kZRISCgRzaXplGAMgASgDUgRzaXplEiAKC2Rvd25sb2Fk'
    'VXJsGAQgASgJUgtkb3dubG9hZFVybBIyCglwYXRjaERhdGEYBSABKAsyFC5BbmRyb2lkQXBwUG'
    'F0Y2hEYXRhUglwYXRjaERhdGESJgoOY29tcHJlc3NlZFNpemUYBiABKANSDmNvbXByZXNzZWRT'
    'aXplEjQKFWNvbXByZXNzZWREb3dubG9hZFVybBgHIAEoCVIVY29tcHJlc3NlZERvd25sb2FkVX'
    'JsEhIKBHNoYTEYCCABKAlSBHNoYTE=');

@$core.Deprecated('Use encryptionParamsDescriptor instead')
const EncryptionParams$json = {
  '1': 'EncryptionParams',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 5, '10': 'version'},
    {'1': 'encryptionKey', '3': 2, '4': 1, '5': 9, '10': 'encryptionKey'},
    {'1': 'hMacKey', '3': 3, '4': 1, '5': 9, '10': 'hMacKey'},
  ],
};

/// Descriptor for `EncryptionParams`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptionParamsDescriptor = $convert.base64Decode(
    'ChBFbmNyeXB0aW9uUGFyYW1zEhgKB3ZlcnNpb24YASABKAVSB3ZlcnNpb24SJAoNZW5jcnlwdG'
    'lvbktleRgCIAEoCVINZW5jcnlwdGlvbktleRIYCgdoTWFjS2V5GAMgASgJUgdoTWFjS2V5');

@$core.Deprecated('Use httpCookieDescriptor instead')
const HttpCookie$json = {
  '1': 'HttpCookie',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `HttpCookie`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List httpCookieDescriptor = $convert.base64Decode(
    'CgpIdHRwQ29va2llEhIKBG5hbWUYASABKAlSBG5hbWUSFAoFdmFsdWUYAiABKAlSBXZhbHVl');

@$core.Deprecated('Use addressDescriptor instead')
const Address$json = {
  '1': 'Address',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'addressLine1', '3': 2, '4': 1, '5': 9, '10': 'addressLine1'},
    {'1': 'addressLine2', '3': 3, '4': 1, '5': 9, '10': 'addressLine2'},
    {'1': 'city', '3': 4, '4': 1, '5': 9, '10': 'city'},
    {'1': 'state', '3': 5, '4': 1, '5': 9, '10': 'state'},
    {'1': 'postalCode', '3': 6, '4': 1, '5': 9, '10': 'postalCode'},
    {'1': 'postalCountry', '3': 7, '4': 1, '5': 9, '10': 'postalCountry'},
    {
      '1': 'dependentLocality',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'dependentLocality'
    },
    {'1': 'sortingCode', '3': 9, '4': 1, '5': 9, '10': 'sortingCode'},
    {'1': 'languageCode', '3': 10, '4': 1, '5': 9, '10': 'languageCode'},
    {'1': 'phoneNumber', '3': 11, '4': 1, '5': 9, '10': 'phoneNumber'},
    {
      '1': 'deprecatedIsReduced',
      '3': 12,
      '4': 1,
      '5': 8,
      '10': 'deprecatedIsReduced'
    },
    {'1': 'firstName', '3': 13, '4': 1, '5': 9, '10': 'firstName'},
    {'1': 'lastName', '3': 14, '4': 1, '5': 9, '10': 'lastName'},
    {'1': 'email', '3': 15, '4': 1, '5': 9, '10': 'email'},
  ],
};

/// Descriptor for `Address`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addressDescriptor = $convert.base64Decode(
    'CgdBZGRyZXNzEhIKBG5hbWUYASABKAlSBG5hbWUSIgoMYWRkcmVzc0xpbmUxGAIgASgJUgxhZG'
    'RyZXNzTGluZTESIgoMYWRkcmVzc0xpbmUyGAMgASgJUgxhZGRyZXNzTGluZTISEgoEY2l0eRgE'
    'IAEoCVIEY2l0eRIUCgVzdGF0ZRgFIAEoCVIFc3RhdGUSHgoKcG9zdGFsQ29kZRgGIAEoCVIKcG'
    '9zdGFsQ29kZRIkCg1wb3N0YWxDb3VudHJ5GAcgASgJUg1wb3N0YWxDb3VudHJ5EiwKEWRlcGVu'
    'ZGVudExvY2FsaXR5GAggASgJUhFkZXBlbmRlbnRMb2NhbGl0eRIgCgtzb3J0aW5nQ29kZRgJIA'
    'EoCVILc29ydGluZ0NvZGUSIgoMbGFuZ3VhZ2VDb2RlGAogASgJUgxsYW5ndWFnZUNvZGUSIAoL'
    'cGhvbmVOdW1iZXIYCyABKAlSC3Bob25lTnVtYmVyEjAKE2RlcHJlY2F0ZWRJc1JlZHVjZWQYDC'
    'ABKAhSE2RlcHJlY2F0ZWRJc1JlZHVjZWQSHAoJZmlyc3ROYW1lGA0gASgJUglmaXJzdE5hbWUS'
    'GgoIbGFzdE5hbWUYDiABKAlSCGxhc3ROYW1lEhQKBWVtYWlsGA8gASgJUgVlbWFpbA==');

@$core.Deprecated('Use browseLinkDescriptor instead')
const BrowseLink$json = {
  '1': 'BrowseLink',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'dataUrl', '3': 3, '4': 1, '5': 9, '10': 'dataUrl'},
    {
      '1': 'serverLogsCookie',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'icon', '3': 5, '4': 1, '5': 11, '6': '.Image', '10': 'icon'},
  ],
};

/// Descriptor for `BrowseLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List browseLinkDescriptor = $convert.base64Decode(
    'CgpCcm93c2VMaW5rEhIKBG5hbWUYASABKAlSBG5hbWUSGAoHZGF0YVVybBgDIAEoCVIHZGF0YV'
    'VybBIqChBzZXJ2ZXJMb2dzQ29va2llGAQgASgMUhBzZXJ2ZXJMb2dzQ29va2llEhoKBGljb24Y'
    'BSABKAsyBi5JbWFnZVIEaWNvbg==');

@$core.Deprecated('Use browseResponseDescriptor instead')
const BrowseResponse$json = {
  '1': 'BrowseResponse',
  '2': [
    {'1': 'contentsUrl', '3': 1, '4': 1, '5': 9, '10': 'contentsUrl'},
    {'1': 'promoUrl', '3': 2, '4': 1, '5': 9, '10': 'promoUrl'},
    {
      '1': 'category',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.BrowseLink',
      '10': 'category'
    },
    {
      '1': 'breadcrumb',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.BrowseLink',
      '10': 'breadcrumb'
    },
    {
      '1': 'quickLink',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.QuickLink',
      '10': 'quickLink'
    },
    {
      '1': 'serverLogsCookie',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'title', '3': 7, '4': 1, '5': 9, '10': 'title'},
    {'1': 'backendId', '3': 8, '4': 1, '5': 5, '10': 'backendId'},
    {
      '1': 'browseTab',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.BrowseTab',
      '10': 'browseTab'
    },
    {'1': 'landingTabIndex', '3': 10, '4': 1, '5': 5, '10': 'landingTabIndex'},
    {
      '1': 'quickLinkTabIndex',
      '3': 11,
      '4': 1,
      '5': 5,
      '10': 'quickLinkTabIndex'
    },
    {
      '1': 'quickLinkFallbackTabIndex',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'quickLinkFallbackTabIndex'
    },
    {'1': 'isFamilySafe', '3': 14, '4': 1, '5': 8, '10': 'isFamilySafe'},
    {'1': 'shareUrl', '3': 18, '4': 1, '5': 9, '10': 'shareUrl'},
  ],
};

/// Descriptor for `BrowseResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List browseResponseDescriptor = $convert.base64Decode(
    'Cg5Ccm93c2VSZXNwb25zZRIgCgtjb250ZW50c1VybBgBIAEoCVILY29udGVudHNVcmwSGgoIcH'
    'JvbW9VcmwYAiABKAlSCHByb21vVXJsEicKCGNhdGVnb3J5GAMgAygLMgsuQnJvd3NlTGlua1II'
    'Y2F0ZWdvcnkSKwoKYnJlYWRjcnVtYhgEIAMoCzILLkJyb3dzZUxpbmtSCmJyZWFkY3J1bWISKA'
    'oJcXVpY2tMaW5rGAUgAygLMgouUXVpY2tMaW5rUglxdWlja0xpbmsSKgoQc2VydmVyTG9nc0Nv'
    'b2tpZRgGIAEoDFIQc2VydmVyTG9nc0Nvb2tpZRIUCgV0aXRsZRgHIAEoCVIFdGl0bGUSHAoJYm'
    'Fja2VuZElkGAggASgFUgliYWNrZW5kSWQSKAoJYnJvd3NlVGFiGAkgASgLMgouQnJvd3NlVGFi'
    'Uglicm93c2VUYWISKAoPbGFuZGluZ1RhYkluZGV4GAogASgFUg9sYW5kaW5nVGFiSW5kZXgSLA'
    'oRcXVpY2tMaW5rVGFiSW5kZXgYCyABKAVSEXF1aWNrTGlua1RhYkluZGV4EjwKGXF1aWNrTGlu'
    'a0ZhbGxiYWNrVGFiSW5kZXgYDCABKAVSGXF1aWNrTGlua0ZhbGxiYWNrVGFiSW5kZXgSIgoMaX'
    'NGYW1pbHlTYWZlGA4gASgIUgxpc0ZhbWlseVNhZmUSGgoIc2hhcmVVcmwYEiABKAlSCHNoYXJl'
    'VXJs');

@$core.Deprecated('Use directPurchaseDescriptor instead')
const DirectPurchase$json = {
  '1': 'DirectPurchase',
  '2': [
    {'1': 'detailsUrl', '3': 1, '4': 1, '5': 9, '10': 'detailsUrl'},
    {'1': 'purchaseItemId', '3': 2, '4': 1, '5': 9, '10': 'purchaseItemId'},
    {'1': 'parentItemId', '3': 3, '4': 1, '5': 9, '10': 'parentItemId'},
    {'1': 'offerType', '3': 4, '4': 1, '5': 5, '7': '1', '10': 'offerType'},
  ],
};

/// Descriptor for `DirectPurchase`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List directPurchaseDescriptor = $convert.base64Decode(
    'Cg5EaXJlY3RQdXJjaGFzZRIeCgpkZXRhaWxzVXJsGAEgASgJUgpkZXRhaWxzVXJsEiYKDnB1cm'
    'NoYXNlSXRlbUlkGAIgASgJUg5wdXJjaGFzZUl0ZW1JZBIiCgxwYXJlbnRJdGVtSWQYAyABKAlS'
    'DHBhcmVudEl0ZW1JZBIfCglvZmZlclR5cGUYBCABKAU6ATFSCW9mZmVyVHlwZQ==');

@$core.Deprecated('Use redeemGiftCardDescriptor instead')
const RedeemGiftCard$json = {
  '1': 'RedeemGiftCard',
  '2': [
    {'1': 'prefillCode', '3': 1, '4': 1, '5': 9, '10': 'prefillCode'},
    {'1': 'partnerPayload', '3': 2, '4': 1, '5': 9, '10': 'partnerPayload'},
  ],
};

/// Descriptor for `RedeemGiftCard`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemGiftCardDescriptor = $convert.base64Decode(
    'Cg5SZWRlZW1HaWZ0Q2FyZBIgCgtwcmVmaWxsQ29kZRgBIAEoCVILcHJlZmlsbENvZGUSJgoOcG'
    'FydG5lclBheWxvYWQYAiABKAlSDnBhcnRuZXJQYXlsb2Fk');

@$core.Deprecated('Use resolvedLinkDescriptor instead')
const ResolvedLink$json = {
  '1': 'ResolvedLink',
  '2': [
    {'1': 'detailsUrl', '3': 1, '4': 1, '5': 9, '10': 'detailsUrl'},
    {'1': 'browseUrl', '3': 2, '4': 1, '5': 9, '10': 'browseUrl'},
    {'1': 'searchUrl', '3': 3, '4': 1, '5': 9, '10': 'searchUrl'},
    {
      '1': 'directPurchase',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.DirectPurchase',
      '10': 'directPurchase'
    },
    {'1': 'homeUrl', '3': 5, '4': 1, '5': 9, '10': 'homeUrl'},
    {
      '1': 'redeemGiftCard',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.RedeemGiftCard',
      '10': 'redeemGiftCard'
    },
    {
      '1': 'serverLogsCookie',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'DocId', '3': 8, '4': 1, '5': 11, '6': '.DocId', '10': 'DocId'},
    {'1': 'wishlistUrl', '3': 9, '4': 1, '5': 9, '10': 'wishlistUrl'},
    {'1': 'backend', '3': 10, '4': 1, '5': 5, '10': 'backend'},
    {'1': 'query', '3': 11, '4': 1, '5': 9, '10': 'query'},
    {'1': 'myAccountUrl', '3': 12, '4': 1, '5': 9, '10': 'myAccountUrl'},
    {
      '1': 'helpCenter',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.HelpCenter',
      '10': 'helpCenter'
    },
  ],
};

/// Descriptor for `ResolvedLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolvedLinkDescriptor = $convert.base64Decode(
    'CgxSZXNvbHZlZExpbmsSHgoKZGV0YWlsc1VybBgBIAEoCVIKZGV0YWlsc1VybBIcCglicm93c2'
    'VVcmwYAiABKAlSCWJyb3dzZVVybBIcCglzZWFyY2hVcmwYAyABKAlSCXNlYXJjaFVybBI3Cg5k'
    'aXJlY3RQdXJjaGFzZRgEIAEoCzIPLkRpcmVjdFB1cmNoYXNlUg5kaXJlY3RQdXJjaGFzZRIYCg'
    'dob21lVXJsGAUgASgJUgdob21lVXJsEjcKDnJlZGVlbUdpZnRDYXJkGAYgASgLMg8uUmVkZWVt'
    'R2lmdENhcmRSDnJlZGVlbUdpZnRDYXJkEioKEHNlcnZlckxvZ3NDb29raWUYByABKAxSEHNlcn'
    'ZlckxvZ3NDb29raWUSHAoFRG9jSWQYCCABKAsyBi5Eb2NJZFIFRG9jSWQSIAoLd2lzaGxpc3RV'
    'cmwYCSABKAlSC3dpc2hsaXN0VXJsEhgKB2JhY2tlbmQYCiABKAVSB2JhY2tlbmQSFAoFcXVlcn'
    'kYCyABKAlSBXF1ZXJ5EiIKDG15QWNjb3VudFVybBgMIAEoCVIMbXlBY2NvdW50VXJsEisKCmhl'
    'bHBDZW50ZXIYDSABKAsyCy5IZWxwQ2VudGVyUgpoZWxwQ2VudGVy');

@$core.Deprecated('Use helpCenterDescriptor instead')
const HelpCenter$json = {
  '1': 'HelpCenter',
  '2': [
    {'1': 'contextId', '3': 1, '4': 1, '5': 9, '10': 'contextId'},
  ],
};

/// Descriptor for `HelpCenter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List helpCenterDescriptor = $convert
    .base64Decode('CgpIZWxwQ2VudGVyEhwKCWNvbnRleHRJZBgBIAEoCVIJY29udGV4dElk');

@$core.Deprecated('Use quickLinkDescriptor instead')
const QuickLink$json = {
  '1': 'QuickLink',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'image', '3': 2, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'link', '3': 3, '4': 1, '5': 11, '6': '.ResolvedLink', '10': 'link'},
    {'1': 'displayRequired', '3': 4, '4': 1, '5': 8, '10': 'displayRequired'},
    {
      '1': 'serverLogsCookie',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'backendId', '3': 6, '4': 1, '5': 5, '10': 'backendId'},
    {'1': 'prismStyle', '3': 7, '4': 1, '5': 8, '10': 'prismStyle'},
  ],
};

/// Descriptor for `QuickLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quickLinkDescriptor = $convert.base64Decode(
    'CglRdWlja0xpbmsSEgoEbmFtZRgBIAEoCVIEbmFtZRIcCgVpbWFnZRgCIAEoCzIGLkltYWdlUg'
    'VpbWFnZRIhCgRsaW5rGAMgASgLMg0uUmVzb2x2ZWRMaW5rUgRsaW5rEigKD2Rpc3BsYXlSZXF1'
    'aXJlZBgEIAEoCFIPZGlzcGxheVJlcXVpcmVkEioKEHNlcnZlckxvZ3NDb29raWUYBSABKAxSEH'
    'NlcnZlckxvZ3NDb29raWUSHAoJYmFja2VuZElkGAYgASgFUgliYWNrZW5kSWQSHgoKcHJpc21T'
    'dHlsZRgHIAEoCFIKcHJpc21TdHlsZQ==');

@$core.Deprecated('Use browseTabDescriptor instead')
const BrowseTab$json = {
  '1': 'BrowseTab',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'serverLogsCookie',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'listUrl', '3': 3, '4': 1, '5': 9, '10': 'listUrl'},
    {
      '1': 'browseLink',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.BrowseLink',
      '10': 'browseLink'
    },
    {
      '1': 'quickLink',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.QuickLink',
      '10': 'quickLink'
    },
    {'1': 'quickLinkTitle', '3': 6, '4': 1, '5': 9, '10': 'quickLinkTitle'},
    {'1': 'categoriesTitle', '3': 7, '4': 1, '5': 9, '10': 'categoriesTitle'},
    {'1': 'backendId', '3': 8, '4': 1, '5': 5, '10': 'backendId'},
    {
      '1': 'highlightsBannerUrl',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'highlightsBannerUrl'
    },
  ],
};

/// Descriptor for `BrowseTab`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List browseTabDescriptor = $convert.base64Decode(
    'CglCcm93c2VUYWISFAoFdGl0bGUYASABKAlSBXRpdGxlEioKEHNlcnZlckxvZ3NDb29raWUYAi'
    'ABKAxSEHNlcnZlckxvZ3NDb29raWUSGAoHbGlzdFVybBgDIAEoCVIHbGlzdFVybBIrCgpicm93'
    'c2VMaW5rGAQgAygLMgsuQnJvd3NlTGlua1IKYnJvd3NlTGluaxIoCglxdWlja0xpbmsYBSADKA'
    'syCi5RdWlja0xpbmtSCXF1aWNrTGluaxImCg5xdWlja0xpbmtUaXRsZRgGIAEoCVIOcXVpY2tM'
    'aW5rVGl0bGUSKAoPY2F0ZWdvcmllc1RpdGxlGAcgASgJUg9jYXRlZ29yaWVzVGl0bGUSHAoJYm'
    'Fja2VuZElkGAggASgFUgliYWNrZW5kSWQSMAoTaGlnaGxpZ2h0c0Jhbm5lclVybBgJIAEoCVIT'
    'aGlnaGxpZ2h0c0Jhbm5lclVybA==');

@$core.Deprecated('Use buyResponseDescriptor instead')
const BuyResponse$json = {
  '1': 'BuyResponse',
  '2': [
    {
      '1': 'purchaseResponse',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.PurchaseNotificationResponse',
      '10': 'purchaseResponse'
    },
    {
      '1': 'checkoutinfo',
      '3': 2,
      '4': 1,
      '5': 10,
      '6': '.BuyResponse.CheckoutInfo',
      '10': 'checkoutinfo'
    },
    {'1': 'continueViaUrl', '3': 8, '4': 1, '5': 9, '10': 'continueViaUrl'},
    {
      '1': 'purchaseStatusUrl',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'purchaseStatusUrl'
    },
    {
      '1': 'checkoutServiceId',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'checkoutServiceId'
    },
    {
      '1': 'checkoutTokenRequired',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'checkoutTokenRequired'
    },
    {'1': 'baseCheckoutUrl', '3': 14, '4': 1, '5': 9, '10': 'baseCheckoutUrl'},
    {'1': 'tosCheckboxHtml', '3': 37, '4': 3, '5': 9, '10': 'tosCheckboxHtml'},
    {
      '1': 'iabPermissionError',
      '3': 38,
      '4': 1,
      '5': 5,
      '10': 'iabPermissionError'
    },
    {
      '1': 'purchaseStatusResponse',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.PurchaseStatusResponse',
      '10': 'purchaseStatusResponse'
    },
    {'1': 'purchaseCookie', '3': 46, '4': 1, '5': 9, '10': 'purchaseCookie'},
    {
      '1': 'challenge',
      '3': 49,
      '4': 1,
      '5': 11,
      '6': '.Challenge',
      '10': 'challenge'
    },
    {
      '1': 'addInstrumentPromptHtml',
      '3': 50,
      '4': 1,
      '5': 9,
      '10': 'addInstrumentPromptHtml'
    },
    {
      '1': 'confirmButtonText',
      '3': 51,
      '4': 1,
      '5': 9,
      '10': 'confirmButtonText'
    },
    {
      '1': 'permissionErrorTitleText',
      '3': 52,
      '4': 1,
      '5': 9,
      '10': 'permissionErrorTitleText'
    },
    {
      '1': 'permissionErrorMessageText',
      '3': 53,
      '4': 1,
      '5': 9,
      '10': 'permissionErrorMessageText'
    },
    {
      '1': 'serverLogsCookie',
      '3': 54,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {
      '1': 'encodedDeliveryToken',
      '3': 55,
      '4': 1,
      '5': 9,
      '10': 'encodedDeliveryToken'
    },
    {'1': 'unknownToken', '3': 56, '4': 1, '5': 9, '10': 'unknownToken'},
  ],
  '3': [BuyResponse_CheckoutInfo$json],
};

@$core.Deprecated('Use buyResponseDescriptor instead')
const BuyResponse_CheckoutInfo$json = {
  '1': 'CheckoutInfo',
  '2': [
    {'1': 'item', '3': 3, '4': 1, '5': 11, '6': '.LineItem', '10': 'item'},
    {
      '1': 'subItem',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.LineItem',
      '10': 'subItem'
    },
    {
      '1': 'checkoutoption',
      '3': 5,
      '4': 3,
      '5': 10,
      '6': '.BuyResponse.CheckoutInfo.CheckoutOption',
      '10': 'checkoutoption'
    },
    {
      '1': 'deprecatedCheckoutUrl',
      '3': 10,
      '4': 1,
      '5': 9,
      '10': 'deprecatedCheckoutUrl'
    },
    {
      '1': 'addInstrumentUrl',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'addInstrumentUrl'
    },
    {'1': 'footerHtml', '3': 20, '4': 3, '5': 9, '10': 'footerHtml'},
    {
      '1': 'eligibleInstrumentFamily',
      '3': 31,
      '4': 3,
      '5': 5,
      '10': 'eligibleInstrumentFamily'
    },
    {'1': 'footnoteHtml', '3': 36, '4': 3, '5': 9, '10': 'footnoteHtml'},
    {
      '1': 'eligibleInstrument',
      '3': 44,
      '4': 3,
      '5': 11,
      '6': '.Instrument',
      '10': 'eligibleInstrument'
    },
  ],
  '3': [BuyResponse_CheckoutInfo_CheckoutOption$json],
};

@$core.Deprecated('Use buyResponseDescriptor instead')
const BuyResponse_CheckoutInfo_CheckoutOption$json = {
  '1': 'CheckoutOption',
  '2': [
    {'1': 'formOfPayment', '3': 6, '4': 1, '5': 9, '10': 'formOfPayment'},
    {
      '1': 'encodedAdjustedCart',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'encodedAdjustedCart'
    },
    {'1': 'instrumentId', '3': 15, '4': 1, '5': 9, '10': 'instrumentId'},
    {'1': 'item', '3': 16, '4': 3, '5': 11, '6': '.LineItem', '10': 'item'},
    {
      '1': 'subItem',
      '3': 17,
      '4': 3,
      '5': 11,
      '6': '.LineItem',
      '10': 'subItem'
    },
    {'1': 'total', '3': 18, '4': 1, '5': 11, '6': '.LineItem', '10': 'total'},
    {'1': 'footerHtml', '3': 19, '4': 3, '5': 9, '10': 'footerHtml'},
    {
      '1': 'instrumentFamily',
      '3': 29,
      '4': 1,
      '5': 5,
      '10': 'instrumentFamily'
    },
    {
      '1': 'deprecatedInstrumentInapplicableReason',
      '3': 30,
      '4': 3,
      '5': 5,
      '10': 'deprecatedInstrumentInapplicableReason'
    },
    {
      '1': 'selectedInstrument',
      '3': 32,
      '4': 1,
      '5': 8,
      '10': 'selectedInstrument'
    },
    {
      '1': 'summary',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.LineItem',
      '10': 'summary'
    },
    {'1': 'footnoteHtml', '3': 35, '4': 3, '5': 9, '10': 'footnoteHtml'},
    {
      '1': 'instrument',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.Instrument',
      '10': 'instrument'
    },
    {'1': 'purchaseCookie', '3': 45, '4': 1, '5': 9, '10': 'purchaseCookie'},
    {'1': 'disabledReason', '3': 48, '4': 3, '5': 9, '10': 'disabledReason'},
  ],
};

/// Descriptor for `BuyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buyResponseDescriptor = $convert.base64Decode(
    'CgtCdXlSZXNwb25zZRJJChBwdXJjaGFzZVJlc3BvbnNlGAEgASgLMh0uUHVyY2hhc2VOb3RpZm'
    'ljYXRpb25SZXNwb25zZVIQcHVyY2hhc2VSZXNwb25zZRI9CgxjaGVja291dGluZm8YAiABKAoy'
    'GS5CdXlSZXNwb25zZS5DaGVja291dEluZm9SDGNoZWNrb3V0aW5mbxImCg5jb250aW51ZVZpYV'
    'VybBgIIAEoCVIOY29udGludWVWaWFVcmwSLAoRcHVyY2hhc2VTdGF0dXNVcmwYCSABKAlSEXB1'
    'cmNoYXNlU3RhdHVzVXJsEiwKEWNoZWNrb3V0U2VydmljZUlkGAwgASgJUhFjaGVja291dFNlcn'
    'ZpY2VJZBI0ChVjaGVja291dFRva2VuUmVxdWlyZWQYDSABKAhSFWNoZWNrb3V0VG9rZW5SZXF1'
    'aXJlZBIoCg9iYXNlQ2hlY2tvdXRVcmwYDiABKAlSD2Jhc2VDaGVja291dFVybBIoCg90b3NDaG'
    'Vja2JveEh0bWwYJSADKAlSD3Rvc0NoZWNrYm94SHRtbBIuChJpYWJQZXJtaXNzaW9uRXJyb3IY'
    'JiABKAVSEmlhYlBlcm1pc3Npb25FcnJvchJPChZwdXJjaGFzZVN0YXR1c1Jlc3BvbnNlGCcgAS'
    'gLMhcuUHVyY2hhc2VTdGF0dXNSZXNwb25zZVIWcHVyY2hhc2VTdGF0dXNSZXNwb25zZRImCg5w'
    'dXJjaGFzZUNvb2tpZRguIAEoCVIOcHVyY2hhc2VDb29raWUSKAoJY2hhbGxlbmdlGDEgASgLMg'
    'ouQ2hhbGxlbmdlUgljaGFsbGVuZ2USOAoXYWRkSW5zdHJ1bWVudFByb21wdEh0bWwYMiABKAlS'
    'F2FkZEluc3RydW1lbnRQcm9tcHRIdG1sEiwKEWNvbmZpcm1CdXR0b25UZXh0GDMgASgJUhFjb2'
    '5maXJtQnV0dG9uVGV4dBI6ChhwZXJtaXNzaW9uRXJyb3JUaXRsZVRleHQYNCABKAlSGHBlcm1p'
    'c3Npb25FcnJvclRpdGxlVGV4dBI+ChpwZXJtaXNzaW9uRXJyb3JNZXNzYWdlVGV4dBg1IAEoCV'
    'IacGVybWlzc2lvbkVycm9yTWVzc2FnZVRleHQSKgoQc2VydmVyTG9nc0Nvb2tpZRg2IAEoDFIQ'
    'c2VydmVyTG9nc0Nvb2tpZRIyChRlbmNvZGVkRGVsaXZlcnlUb2tlbhg3IAEoCVIUZW5jb2RlZE'
    'RlbGl2ZXJ5VG9rZW4SIgoMdW5rbm93blRva2VuGDggASgJUgx1bmtub3duVG9rZW4a0QgKDENo'
    'ZWNrb3V0SW5mbxIdCgRpdGVtGAMgASgLMgkuTGluZUl0ZW1SBGl0ZW0SIwoHc3ViSXRlbRgEIA'
    'MoCzIJLkxpbmVJdGVtUgdzdWJJdGVtElAKDmNoZWNrb3V0b3B0aW9uGAUgAygKMiguQnV5UmVz'
    'cG9uc2UuQ2hlY2tvdXRJbmZvLkNoZWNrb3V0T3B0aW9uUg5jaGVja291dG9wdGlvbhI0ChVkZX'
    'ByZWNhdGVkQ2hlY2tvdXRVcmwYCiABKAlSFWRlcHJlY2F0ZWRDaGVja291dFVybBIqChBhZGRJ'
    'bnN0cnVtZW50VXJsGAsgASgJUhBhZGRJbnN0cnVtZW50VXJsEh4KCmZvb3Rlckh0bWwYFCADKA'
    'lSCmZvb3Rlckh0bWwSOgoYZWxpZ2libGVJbnN0cnVtZW50RmFtaWx5GB8gAygFUhhlbGlnaWJs'
    'ZUluc3RydW1lbnRGYW1pbHkSIgoMZm9vdG5vdGVIdG1sGCQgAygJUgxmb290bm90ZUh0bWwSOw'
    'oSZWxpZ2libGVJbnN0cnVtZW50GCwgAygLMgsuSW5zdHJ1bWVudFISZWxpZ2libGVJbnN0cnVt'
    'ZW50GosFCg5DaGVja291dE9wdGlvbhIkCg1mb3JtT2ZQYXltZW50GAYgASgJUg1mb3JtT2ZQYX'
    'ltZW50EjAKE2VuY29kZWRBZGp1c3RlZENhcnQYByABKAlSE2VuY29kZWRBZGp1c3RlZENhcnQS'
    'IgoMaW5zdHJ1bWVudElkGA8gASgJUgxpbnN0cnVtZW50SWQSHQoEaXRlbRgQIAMoCzIJLkxpbm'
    'VJdGVtUgRpdGVtEiMKB3N1Ykl0ZW0YESADKAsyCS5MaW5lSXRlbVIHc3ViSXRlbRIfCgV0b3Rh'
    'bBgSIAEoCzIJLkxpbmVJdGVtUgV0b3RhbBIeCgpmb290ZXJIdG1sGBMgAygJUgpmb290ZXJIdG'
    '1sEioKEGluc3RydW1lbnRGYW1pbHkYHSABKAVSEGluc3RydW1lbnRGYW1pbHkSVgomZGVwcmVj'
    'YXRlZEluc3RydW1lbnRJbmFwcGxpY2FibGVSZWFzb24YHiADKAVSJmRlcHJlY2F0ZWRJbnN0cn'
    'VtZW50SW5hcHBsaWNhYmxlUmVhc29uEi4KEnNlbGVjdGVkSW5zdHJ1bWVudBggIAEoCFISc2Vs'
    'ZWN0ZWRJbnN0cnVtZW50EiMKB3N1bW1hcnkYISABKAsyCS5MaW5lSXRlbVIHc3VtbWFyeRIiCg'
    'xmb290bm90ZUh0bWwYIyADKAlSDGZvb3Rub3RlSHRtbBIrCgppbnN0cnVtZW50GCsgASgLMgsu'
    'SW5zdHJ1bWVudFIKaW5zdHJ1bWVudBImCg5wdXJjaGFzZUNvb2tpZRgtIAEoCVIOcHVyY2hhc2'
    'VDb29raWUSJgoOZGlzYWJsZWRSZWFzb24YMCADKAlSDmRpc2FibGVkUmVhc29u');

@$core.Deprecated('Use lineItemDescriptor instead')
const LineItem$json = {
  '1': 'LineItem',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'offer', '3': 3, '4': 1, '5': 11, '6': '.Offer', '10': 'offer'},
    {'1': 'amount', '3': 4, '4': 1, '5': 11, '6': '.Money', '10': 'amount'},
  ],
};

/// Descriptor for `LineItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lineItemDescriptor = $convert.base64Decode(
    'CghMaW5lSXRlbRISCgRuYW1lGAEgASgJUgRuYW1lEiAKC2Rlc2NyaXB0aW9uGAIgASgJUgtkZX'
    'NjcmlwdGlvbhIcCgVvZmZlchgDIAEoCzIGLk9mZmVyUgVvZmZlchIeCgZhbW91bnQYBCABKAsy'
    'Bi5Nb25leVIGYW1vdW50');

@$core.Deprecated('Use moneyDescriptor instead')
const Money$json = {
  '1': 'Money',
  '2': [
    {'1': 'micros', '3': 1, '4': 1, '5': 3, '10': 'micros'},
    {'1': 'currencyCode', '3': 2, '4': 1, '5': 9, '10': 'currencyCode'},
    {'1': 'formattedAmount', '3': 3, '4': 1, '5': 9, '10': 'formattedAmount'},
  ],
};

/// Descriptor for `Money`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moneyDescriptor = $convert.base64Decode(
    'CgVNb25leRIWCgZtaWNyb3MYASABKANSBm1pY3JvcxIiCgxjdXJyZW5jeUNvZGUYAiABKAlSDG'
    'N1cnJlbmN5Q29kZRIoCg9mb3JtYXR0ZWRBbW91bnQYAyABKAlSD2Zvcm1hdHRlZEFtb3VudA==');

@$core.Deprecated('Use purchaseNotificationResponseDescriptor instead')
const PurchaseNotificationResponse$json = {
  '1': 'PurchaseNotificationResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 5, '10': 'status'},
    {
      '1': 'debugInfo',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.DebugInfo',
      '10': 'debugInfo'
    },
    {
      '1': 'localizedErrorMessage',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'localizedErrorMessage'
    },
    {'1': 'purchaseId', '3': 4, '4': 1, '5': 9, '10': 'purchaseId'},
  ],
};

/// Descriptor for `PurchaseNotificationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseNotificationResponseDescriptor = $convert.base64Decode(
    'ChxQdXJjaGFzZU5vdGlmaWNhdGlvblJlc3BvbnNlEhYKBnN0YXR1cxgBIAEoBVIGc3RhdHVzEi'
    'gKCWRlYnVnSW5mbxgCIAEoCzIKLkRlYnVnSW5mb1IJZGVidWdJbmZvEjQKFWxvY2FsaXplZEVy'
    'cm9yTWVzc2FnZRgDIAEoCVIVbG9jYWxpemVkRXJyb3JNZXNzYWdlEh4KCnB1cmNoYXNlSWQYBC'
    'ABKAlSCnB1cmNoYXNlSWQ=');

@$core.Deprecated('Use purchaseStatusResponseDescriptor instead')
const PurchaseStatusResponse$json = {
  '1': 'PurchaseStatusResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 5, '10': 'status'},
    {'1': 'statusMsg', '3': 2, '4': 1, '5': 9, '10': 'statusMsg'},
    {'1': 'statusTitle', '3': 3, '4': 1, '5': 9, '10': 'statusTitle'},
    {'1': 'briefMessage', '3': 4, '4': 1, '5': 9, '10': 'briefMessage'},
    {'1': 'infoUrl', '3': 5, '4': 1, '5': 9, '10': 'infoUrl'},
    {
      '1': 'libraryUpdate',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.LibraryUpdate',
      '10': 'libraryUpdate'
    },
    {
      '1': 'rejectedInstrument',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.Instrument',
      '10': 'rejectedInstrument'
    },
    {
      '1': 'appDeliveryData',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppDeliveryData',
      '10': 'appDeliveryData'
    },
  ],
};

/// Descriptor for `PurchaseStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseStatusResponseDescriptor = $convert.base64Decode(
    'ChZQdXJjaGFzZVN0YXR1c1Jlc3BvbnNlEhYKBnN0YXR1cxgBIAEoBVIGc3RhdHVzEhwKCXN0YX'
    'R1c01zZxgCIAEoCVIJc3RhdHVzTXNnEiAKC3N0YXR1c1RpdGxlGAMgASgJUgtzdGF0dXNUaXRs'
    'ZRIiCgxicmllZk1lc3NhZ2UYBCABKAlSDGJyaWVmTWVzc2FnZRIYCgdpbmZvVXJsGAUgASgJUg'
    'dpbmZvVXJsEjQKDWxpYnJhcnlVcGRhdGUYBiABKAsyDi5MaWJyYXJ5VXBkYXRlUg1saWJyYXJ5'
    'VXBkYXRlEjsKEnJlamVjdGVkSW5zdHJ1bWVudBgHIAEoCzILLkluc3RydW1lbnRSEnJlamVjdG'
    'VkSW5zdHJ1bWVudBJBCg9hcHBEZWxpdmVyeURhdGEYCCABKAsyFy5BbmRyb2lkQXBwRGVsaXZl'
    'cnlEYXRhUg9hcHBEZWxpdmVyeURhdGE=');

@$core.Deprecated('Use purchaseHistoryDetailsDescriptor instead')
const PurchaseHistoryDetails$json = {
  '1': 'PurchaseHistoryDetails',
  '2': [
    {
      '1': 'purchaseTimestampMillis',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'purchaseTimestampMillis'
    },
    {
      '1': 'purchaseDetailsHtml',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'purchaseDetailsHtml'
    },
    {'1': 'offer', '3': 5, '4': 1, '5': 11, '6': '.Offer', '10': 'offer'},
    {'1': 'purchaseStatus', '3': 6, '4': 1, '5': 9, '10': 'purchaseStatus'},
    {'1': 'titleBylineHtml', '3': 7, '4': 1, '5': 9, '10': 'titleBylineHtml'},
    {
      '1': 'clientRefundContext',
      '3': 8,
      '4': 1,
      '5': 12,
      '10': 'clientRefundContext'
    },
    {
      '1': 'purchaseDetailsImage',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.Image',
      '10': 'purchaseDetailsImage'
    },
  ],
};

/// Descriptor for `PurchaseHistoryDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseHistoryDetailsDescriptor = $convert.base64Decode(
    'ChZQdXJjaGFzZUhpc3RvcnlEZXRhaWxzEjgKF3B1cmNoYXNlVGltZXN0YW1wTWlsbGlzGAIgAS'
    'gDUhdwdXJjaGFzZVRpbWVzdGFtcE1pbGxpcxIwChNwdXJjaGFzZURldGFpbHNIdG1sGAMgASgJ'
    'UhNwdXJjaGFzZURldGFpbHNIdG1sEhwKBW9mZmVyGAUgASgLMgYuT2ZmZXJSBW9mZmVyEiYKDn'
    'B1cmNoYXNlU3RhdHVzGAYgASgJUg5wdXJjaGFzZVN0YXR1cxIoCg90aXRsZUJ5bGluZUh0bWwY'
    'ByABKAlSD3RpdGxlQnlsaW5lSHRtbBIwChNjbGllbnRSZWZ1bmRDb250ZXh0GAggASgMUhNjbG'
    'llbnRSZWZ1bmRDb250ZXh0EjoKFHB1cmNoYXNlRGV0YWlsc0ltYWdlGAkgASgLMgYuSW1hZ2VS'
    'FHB1cmNoYXNlRGV0YWlsc0ltYWdl');

@$core.Deprecated('Use billingProfileResponseDescriptor instead')
const BillingProfileResponse$json = {
  '1': 'BillingProfileResponse',
  '2': [
    {'1': 'result', '3': 1, '4': 1, '5': 5, '10': 'result'},
    {
      '1': 'billingProfile',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.BillingProfile',
      '10': 'billingProfile'
    },
    {'1': 'userMessageHtml', '3': 3, '4': 1, '5': 9, '10': 'userMessageHtml'},
  ],
};

/// Descriptor for `BillingProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingProfileResponseDescriptor = $convert.base64Decode(
    'ChZCaWxsaW5nUHJvZmlsZVJlc3BvbnNlEhYKBnJlc3VsdBgBIAEoBVIGcmVzdWx0EjcKDmJpbG'
    'xpbmdQcm9maWxlGAIgASgLMg8uQmlsbGluZ1Byb2ZpbGVSDmJpbGxpbmdQcm9maWxlEigKD3Vz'
    'ZXJNZXNzYWdlSHRtbBgDIAEoCVIPdXNlck1lc3NhZ2VIdG1s');

@$core.Deprecated('Use checkInstrumentResponseDescriptor instead')
const CheckInstrumentResponse$json = {
  '1': 'CheckInstrumentResponse',
  '2': [
    {
      '1': 'userHasValidInstrument',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'userHasValidInstrument'
    },
    {
      '1': 'checkoutTokenRequired',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'checkoutTokenRequired'
    },
    {
      '1': 'instrument',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.Instrument',
      '10': 'instrument'
    },
    {
      '1': 'eligibleInstrument',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.Instrument',
      '10': 'eligibleInstrument'
    },
  ],
};

/// Descriptor for `CheckInstrumentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkInstrumentResponseDescriptor = $convert.base64Decode(
    'ChdDaGVja0luc3RydW1lbnRSZXNwb25zZRI2ChZ1c2VySGFzVmFsaWRJbnN0cnVtZW50GAEgAS'
    'gIUhZ1c2VySGFzVmFsaWRJbnN0cnVtZW50EjQKFWNoZWNrb3V0VG9rZW5SZXF1aXJlZBgCIAEo'
    'CFIVY2hlY2tvdXRUb2tlblJlcXVpcmVkEisKCmluc3RydW1lbnQYBCADKAsyCy5JbnN0cnVtZW'
    '50UgppbnN0cnVtZW50EjsKEmVsaWdpYmxlSW5zdHJ1bWVudBgFIAMoCzILLkluc3RydW1lbnRS'
    'EmVsaWdpYmxlSW5zdHJ1bWVudA==');

@$core.Deprecated('Use instrumentSetupInfoResponseDescriptor instead')
const InstrumentSetupInfoResponse$json = {
  '1': 'InstrumentSetupInfoResponse',
  '2': [
    {
      '1': 'setupInfo',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.InstrumentSetupInfo',
      '10': 'setupInfo'
    },
    {
      '1': 'checkoutTokenRequired',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'checkoutTokenRequired'
    },
  ],
};

/// Descriptor for `InstrumentSetupInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instrumentSetupInfoResponseDescriptor =
    $convert.base64Decode(
        'ChtJbnN0cnVtZW50U2V0dXBJbmZvUmVzcG9uc2USMgoJc2V0dXBJbmZvGAEgAygLMhQuSW5zdH'
        'J1bWVudFNldHVwSW5mb1IJc2V0dXBJbmZvEjQKFWNoZWNrb3V0VG9rZW5SZXF1aXJlZBgCIAEo'
        'CFIVY2hlY2tvdXRUb2tlblJlcXVpcmVk');

@$core.Deprecated('Use redeemGiftCardRequestDescriptor instead')
const RedeemGiftCardRequest$json = {
  '1': 'RedeemGiftCardRequest',
  '2': [
    {'1': 'giftCardPin', '3': 1, '4': 1, '5': 9, '10': 'giftCardPin'},
    {'1': 'address', '3': 2, '4': 1, '5': 11, '6': '.Address', '10': 'address'},
    {
      '1': 'acceptedLegalDocumentId',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'acceptedLegalDocumentId'
    },
    {'1': 'checkoutToken', '3': 4, '4': 1, '5': 9, '10': 'checkoutToken'},
  ],
};

/// Descriptor for `RedeemGiftCardRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemGiftCardRequestDescriptor = $convert.base64Decode(
    'ChVSZWRlZW1HaWZ0Q2FyZFJlcXVlc3QSIAoLZ2lmdENhcmRQaW4YASABKAlSC2dpZnRDYXJkUG'
    'luEiIKB2FkZHJlc3MYAiABKAsyCC5BZGRyZXNzUgdhZGRyZXNzEjgKF2FjY2VwdGVkTGVnYWxE'
    'b2N1bWVudElkGAMgAygJUhdhY2NlcHRlZExlZ2FsRG9jdW1lbnRJZBIkCg1jaGVja291dFRva2'
    'VuGAQgASgJUg1jaGVja291dFRva2Vu');

@$core.Deprecated('Use redeemGiftCardResponseDescriptor instead')
const RedeemGiftCardResponse$json = {
  '1': 'RedeemGiftCardResponse',
  '2': [
    {'1': 'result', '3': 1, '4': 1, '5': 5, '10': 'result'},
    {'1': 'userMessageHtml', '3': 2, '4': 1, '5': 9, '10': 'userMessageHtml'},
    {'1': 'balanceHtml', '3': 3, '4': 1, '5': 9, '10': 'balanceHtml'},
    {
      '1': 'addressChallenge',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.AddressChallenge',
      '10': 'addressChallenge'
    },
    {
      '1': 'checkoutTokenRequired',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'checkoutTokenRequired'
    },
  ],
};

/// Descriptor for `RedeemGiftCardResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemGiftCardResponseDescriptor = $convert.base64Decode(
    'ChZSZWRlZW1HaWZ0Q2FyZFJlc3BvbnNlEhYKBnJlc3VsdBgBIAEoBVIGcmVzdWx0EigKD3VzZX'
    'JNZXNzYWdlSHRtbBgCIAEoCVIPdXNlck1lc3NhZ2VIdG1sEiAKC2JhbGFuY2VIdG1sGAMgASgJ'
    'UgtiYWxhbmNlSHRtbBI9ChBhZGRyZXNzQ2hhbGxlbmdlGAQgASgLMhEuQWRkcmVzc0NoYWxsZW'
    '5nZVIQYWRkcmVzc0NoYWxsZW5nZRI0ChVjaGVja291dFRva2VuUmVxdWlyZWQYBSABKAhSFWNo'
    'ZWNrb3V0VG9rZW5SZXF1aXJlZA==');

@$core.Deprecated('Use updateInstrumentRequestDescriptor instead')
const UpdateInstrumentRequest$json = {
  '1': 'UpdateInstrumentRequest',
  '2': [
    {
      '1': 'instrument',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.Instrument',
      '10': 'instrument'
    },
    {'1': 'checkoutToken', '3': 2, '4': 1, '5': 9, '10': 'checkoutToken'},
  ],
};

/// Descriptor for `UpdateInstrumentRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateInstrumentRequestDescriptor = $convert.base64Decode(
    'ChdVcGRhdGVJbnN0cnVtZW50UmVxdWVzdBIrCgppbnN0cnVtZW50GAEgASgLMgsuSW5zdHJ1bW'
    'VudFIKaW5zdHJ1bWVudBIkCg1jaGVja291dFRva2VuGAIgASgJUg1jaGVja291dFRva2Vu');

@$core.Deprecated('Use updateInstrumentResponseDescriptor instead')
const UpdateInstrumentResponse$json = {
  '1': 'UpdateInstrumentResponse',
  '2': [
    {'1': 'result', '3': 1, '4': 1, '5': 5, '10': 'result'},
    {'1': 'instrumentId', '3': 2, '4': 1, '5': 9, '10': 'instrumentId'},
    {'1': 'userMessageHtml', '3': 3, '4': 1, '5': 9, '10': 'userMessageHtml'},
    {
      '1': 'errorInputField',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.InputValidationError',
      '10': 'errorInputField'
    },
    {
      '1': 'checkoutTokenRequired',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'checkoutTokenRequired'
    },
    {
      '1': 'redeemedOffer',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.RedeemedPromoOffer',
      '10': 'redeemedOffer'
    },
  ],
};

/// Descriptor for `UpdateInstrumentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateInstrumentResponseDescriptor = $convert.base64Decode(
    'ChhVcGRhdGVJbnN0cnVtZW50UmVzcG9uc2USFgoGcmVzdWx0GAEgASgFUgZyZXN1bHQSIgoMaW'
    '5zdHJ1bWVudElkGAIgASgJUgxpbnN0cnVtZW50SWQSKAoPdXNlck1lc3NhZ2VIdG1sGAMgASgJ'
    'Ug91c2VyTWVzc2FnZUh0bWwSPwoPZXJyb3JJbnB1dEZpZWxkGAQgAygLMhUuSW5wdXRWYWxpZG'
    'F0aW9uRXJyb3JSD2Vycm9ySW5wdXRGaWVsZBI0ChVjaGVja291dFRva2VuUmVxdWlyZWQYBSAB'
    'KAhSFWNoZWNrb3V0VG9rZW5SZXF1aXJlZBI5Cg1yZWRlZW1lZE9mZmVyGAYgASgLMhMuUmVkZW'
    'VtZWRQcm9tb09mZmVyUg1yZWRlZW1lZE9mZmVy');

@$core.Deprecated('Use initiateAssociationResponseDescriptor instead')
const InitiateAssociationResponse$json = {
  '1': 'InitiateAssociationResponse',
  '2': [
    {'1': 'userToken', '3': 1, '4': 1, '5': 9, '10': 'userToken'},
  ],
};

/// Descriptor for `InitiateAssociationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List initiateAssociationResponseDescriptor =
    $convert.base64Decode(
        'ChtJbml0aWF0ZUFzc29jaWF0aW9uUmVzcG9uc2USHAoJdXNlclRva2VuGAEgASgJUgl1c2VyVG'
        '9rZW4=');

@$core.Deprecated('Use verifyAssociationResponseDescriptor instead')
const VerifyAssociationResponse$json = {
  '1': 'VerifyAssociationResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 5, '10': 'status'},
    {
      '1': 'billingAddress',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.Address',
      '10': 'billingAddress'
    },
    {
      '1': 'carrierTos',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarrierTos',
      '10': 'carrierTos'
    },
    {
      '1': 'carrierErrorMessage',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'carrierErrorMessage'
    },
  ],
};

/// Descriptor for `VerifyAssociationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifyAssociationResponseDescriptor = $convert.base64Decode(
    'ChlWZXJpZnlBc3NvY2lhdGlvblJlc3BvbnNlEhYKBnN0YXR1cxgBIAEoBVIGc3RhdHVzEjAKDm'
    'JpbGxpbmdBZGRyZXNzGAIgASgLMgguQWRkcmVzc1IOYmlsbGluZ0FkZHJlc3MSKwoKY2Fycmll'
    'clRvcxgDIAEoCzILLkNhcnJpZXJUb3NSCmNhcnJpZXJUb3MSMAoTY2FycmllckVycm9yTWVzc2'
    'FnZRgEIAEoCVITY2FycmllckVycm9yTWVzc2FnZQ==');

@$core.Deprecated('Use addressChallengeDescriptor instead')
const AddressChallenge$json = {
  '1': 'AddressChallenge',
  '2': [
    {
      '1': 'responseAddressParam',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'responseAddressParam'
    },
    {
      '1': 'responseCheckboxesParam',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'responseCheckboxesParam'
    },
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'descriptionHtml', '3': 4, '4': 1, '5': 9, '10': 'descriptionHtml'},
    {
      '1': 'checkbox',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.FormCheckbox',
      '10': 'checkbox'
    },
    {'1': 'address', '3': 6, '4': 1, '5': 11, '6': '.Address', '10': 'address'},
    {
      '1': 'errorInputField',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.InputValidationError',
      '10': 'errorInputField'
    },
    {'1': 'errorHtml', '3': 8, '4': 1, '5': 9, '10': 'errorHtml'},
    {'1': 'requiredField', '3': 9, '4': 3, '5': 5, '10': 'requiredField'},
    {
      '1': 'supportedCountry',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.Country',
      '10': 'supportedCountry'
    },
  ],
};

/// Descriptor for `AddressChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addressChallengeDescriptor = $convert.base64Decode(
    'ChBBZGRyZXNzQ2hhbGxlbmdlEjIKFHJlc3BvbnNlQWRkcmVzc1BhcmFtGAEgASgJUhRyZXNwb2'
    '5zZUFkZHJlc3NQYXJhbRI4ChdyZXNwb25zZUNoZWNrYm94ZXNQYXJhbRgCIAEoCVIXcmVzcG9u'
    'c2VDaGVja2JveGVzUGFyYW0SFAoFdGl0bGUYAyABKAlSBXRpdGxlEigKD2Rlc2NyaXB0aW9uSH'
    'RtbBgEIAEoCVIPZGVzY3JpcHRpb25IdG1sEikKCGNoZWNrYm94GAUgAygLMg0uRm9ybUNoZWNr'
    'Ym94UghjaGVja2JveBIiCgdhZGRyZXNzGAYgASgLMgguQWRkcmVzc1IHYWRkcmVzcxI/Cg9lcn'
    'JvcklucHV0RmllbGQYByADKAsyFS5JbnB1dFZhbGlkYXRpb25FcnJvclIPZXJyb3JJbnB1dEZp'
    'ZWxkEhwKCWVycm9ySHRtbBgIIAEoCVIJZXJyb3JIdG1sEiQKDXJlcXVpcmVkRmllbGQYCSADKA'
    'VSDXJlcXVpcmVkRmllbGQSNAoQc3VwcG9ydGVkQ291bnRyeRgKIAMoCzIILkNvdW50cnlSEHN1'
    'cHBvcnRlZENvdW50cnk=');

@$core.Deprecated('Use authenticationChallengeDescriptor instead')
const AuthenticationChallenge$json = {
  '1': 'AuthenticationChallenge',
  '2': [
    {
      '1': 'authenticationType',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'authenticationType'
    },
    {
      '1': 'responseAuthenticationTypeParam',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'responseAuthenticationTypeParam'
    },
    {
      '1': 'responseRetryCountParam',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'responseRetryCountParam'
    },
    {'1': 'pinHeaderText', '3': 4, '4': 1, '5': 9, '10': 'pinHeaderText'},
    {
      '1': 'pinDescriptionTextHtml',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'pinDescriptionTextHtml'
    },
    {'1': 'gaiaHeaderText', '3': 6, '4': 1, '5': 9, '10': 'gaiaHeaderText'},
    {
      '1': 'gaiaDescriptionTextHtml',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'gaiaDescriptionTextHtml'
    },
    {
      '1': 'gaiaFooterTextHtml',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'gaiaFooterTextHtml'
    },
    {
      '1': 'gaiaOptOutCheckbox',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.FormCheckbox',
      '10': 'gaiaOptOutCheckbox'
    },
    {
      '1': 'gaiaOptOutDescriptionTextHtml',
      '3': 10,
      '4': 1,
      '5': 9,
      '10': 'gaiaOptOutDescriptionTextHtml'
    },
  ],
};

/// Descriptor for `AuthenticationChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List authenticationChallengeDescriptor = $convert.base64Decode(
    'ChdBdXRoZW50aWNhdGlvbkNoYWxsZW5nZRIuChJhdXRoZW50aWNhdGlvblR5cGUYASABKAVSEm'
    'F1dGhlbnRpY2F0aW9uVHlwZRJICh9yZXNwb25zZUF1dGhlbnRpY2F0aW9uVHlwZVBhcmFtGAIg'
    'ASgJUh9yZXNwb25zZUF1dGhlbnRpY2F0aW9uVHlwZVBhcmFtEjgKF3Jlc3BvbnNlUmV0cnlDb3'
    'VudFBhcmFtGAMgASgJUhdyZXNwb25zZVJldHJ5Q291bnRQYXJhbRIkCg1waW5IZWFkZXJUZXh0'
    'GAQgASgJUg1waW5IZWFkZXJUZXh0EjYKFnBpbkRlc2NyaXB0aW9uVGV4dEh0bWwYBSABKAlSFn'
    'BpbkRlc2NyaXB0aW9uVGV4dEh0bWwSJgoOZ2FpYUhlYWRlclRleHQYBiABKAlSDmdhaWFIZWFk'
    'ZXJUZXh0EjgKF2dhaWFEZXNjcmlwdGlvblRleHRIdG1sGAcgASgJUhdnYWlhRGVzY3JpcHRpb2'
    '5UZXh0SHRtbBIuChJnYWlhRm9vdGVyVGV4dEh0bWwYCCABKAlSEmdhaWFGb290ZXJUZXh0SHRt'
    'bBI9ChJnYWlhT3B0T3V0Q2hlY2tib3gYCSABKAsyDS5Gb3JtQ2hlY2tib3hSEmdhaWFPcHRPdX'
    'RDaGVja2JveBJECh1nYWlhT3B0T3V0RGVzY3JpcHRpb25UZXh0SHRtbBgKIAEoCVIdZ2FpYU9w'
    'dE91dERlc2NyaXB0aW9uVGV4dEh0bWw=');

@$core.Deprecated('Use challengeDescriptor instead')
const Challenge$json = {
  '1': 'Challenge',
  '2': [
    {
      '1': 'addressChallenge',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AddressChallenge',
      '10': 'addressChallenge'
    },
    {
      '1': 'authenticationChallenge',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.AuthenticationChallenge',
      '10': 'authenticationChallenge'
    },
    {
      '1': 'webViewChallenge',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.WebViewChallenge',
      '10': 'webViewChallenge'
    },
  ],
};

/// Descriptor for `Challenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List challengeDescriptor = $convert.base64Decode(
    'CglDaGFsbGVuZ2USPQoQYWRkcmVzc0NoYWxsZW5nZRgBIAEoCzIRLkFkZHJlc3NDaGFsbGVuZ2'
    'VSEGFkZHJlc3NDaGFsbGVuZ2USUgoXYXV0aGVudGljYXRpb25DaGFsbGVuZ2UYAiABKAsyGC5B'
    'dXRoZW50aWNhdGlvbkNoYWxsZW5nZVIXYXV0aGVudGljYXRpb25DaGFsbGVuZ2USPQoQd2ViVm'
    'lld0NoYWxsZW5nZRgDIAEoCzIRLldlYlZpZXdDaGFsbGVuZ2VSEHdlYlZpZXdDaGFsbGVuZ2U=');

@$core.Deprecated('Use countryDescriptor instead')
const Country$json = {
  '1': 'Country',
  '2': [
    {'1': 'regionCode', '3': 1, '4': 1, '5': 9, '10': 'regionCode'},
    {'1': 'displayName', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `Country`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List countryDescriptor = $convert.base64Decode(
    'CgdDb3VudHJ5Eh4KCnJlZ2lvbkNvZGUYASABKAlSCnJlZ2lvbkNvZGUSIAoLZGlzcGxheU5hbW'
    'UYAiABKAlSC2Rpc3BsYXlOYW1l');

@$core.Deprecated('Use formCheckboxDescriptor instead')
const FormCheckbox$json = {
  '1': 'FormCheckbox',
  '2': [
    {'1': 'description', '3': 1, '4': 1, '5': 9, '10': 'description'},
    {'1': 'checked', '3': 2, '4': 1, '5': 8, '10': 'checked'},
    {'1': 'required', '3': 3, '4': 1, '5': 8, '10': 'required'},
    {'1': 'id', '3': 4, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `FormCheckbox`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formCheckboxDescriptor = $convert.base64Decode(
    'CgxGb3JtQ2hlY2tib3gSIAoLZGVzY3JpcHRpb24YASABKAlSC2Rlc2NyaXB0aW9uEhgKB2NoZW'
    'NrZWQYAiABKAhSB2NoZWNrZWQSGgoIcmVxdWlyZWQYAyABKAhSCHJlcXVpcmVkEg4KAmlkGAQg'
    'ASgJUgJpZA==');

@$core.Deprecated('Use inputValidationErrorDescriptor instead')
const InputValidationError$json = {
  '1': 'InputValidationError',
  '2': [
    {'1': 'inputField', '3': 1, '4': 1, '5': 5, '10': 'inputField'},
    {'1': 'errorMessage', '3': 2, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `InputValidationError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputValidationErrorDescriptor = $convert.base64Decode(
    'ChRJbnB1dFZhbGlkYXRpb25FcnJvchIeCgppbnB1dEZpZWxkGAEgASgFUgppbnB1dEZpZWxkEi'
    'IKDGVycm9yTWVzc2FnZRgCIAEoCVIMZXJyb3JNZXNzYWdl');

@$core.Deprecated('Use webViewChallengeDescriptor instead')
const WebViewChallenge$json = {
  '1': 'WebViewChallenge',
  '2': [
    {'1': 'startUrl', '3': 1, '4': 1, '5': 9, '10': 'startUrl'},
    {'1': 'targetUrlRegexp', '3': 2, '4': 1, '5': 9, '10': 'targetUrlRegexp'},
    {
      '1': 'cancelButtonDisplayLabel',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'cancelButtonDisplayLabel'
    },
    {
      '1': 'responseTargetUrlParam',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'responseTargetUrlParam'
    },
    {'1': 'cancelUrlRegexp', '3': 5, '4': 1, '5': 9, '10': 'cancelUrlRegexp'},
    {'1': 'title', '3': 6, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `WebViewChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webViewChallengeDescriptor = $convert.base64Decode(
    'ChBXZWJWaWV3Q2hhbGxlbmdlEhoKCHN0YXJ0VXJsGAEgASgJUghzdGFydFVybBIoCg90YXJnZX'
    'RVcmxSZWdleHAYAiABKAlSD3RhcmdldFVybFJlZ2V4cBI6ChhjYW5jZWxCdXR0b25EaXNwbGF5'
    'TGFiZWwYAyABKAlSGGNhbmNlbEJ1dHRvbkRpc3BsYXlMYWJlbBI2ChZyZXNwb25zZVRhcmdldF'
    'VybFBhcmFtGAQgASgJUhZyZXNwb25zZVRhcmdldFVybFBhcmFtEigKD2NhbmNlbFVybFJlZ2V4'
    'cBgFIAEoCVIPY2FuY2VsVXJsUmVnZXhwEhQKBXRpdGxlGAYgASgJUgV0aXRsZQ==');

@$core.Deprecated('Use addCreditCardPromoOfferDescriptor instead')
const AddCreditCardPromoOffer$json = {
  '1': 'AddCreditCardPromoOffer',
  '2': [
    {'1': 'headerText', '3': 1, '4': 1, '5': 9, '10': 'headerText'},
    {'1': 'descriptionHtml', '3': 2, '4': 1, '5': 9, '10': 'descriptionHtml'},
    {'1': 'image', '3': 3, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {
      '1': 'introductoryTextHtml',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'introductoryTextHtml'
    },
    {'1': 'offerTitle', '3': 5, '4': 1, '5': 9, '10': 'offerTitle'},
    {
      '1': 'noActionDescription',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'noActionDescription'
    },
    {
      '1': 'termsAndConditionsHtml',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'termsAndConditionsHtml'
    },
  ],
};

/// Descriptor for `AddCreditCardPromoOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addCreditCardPromoOfferDescriptor = $convert.base64Decode(
    'ChdBZGRDcmVkaXRDYXJkUHJvbW9PZmZlchIeCgpoZWFkZXJUZXh0GAEgASgJUgpoZWFkZXJUZX'
    'h0EigKD2Rlc2NyaXB0aW9uSHRtbBgCIAEoCVIPZGVzY3JpcHRpb25IdG1sEhwKBWltYWdlGAMg'
    'ASgLMgYuSW1hZ2VSBWltYWdlEjIKFGludHJvZHVjdG9yeVRleHRIdG1sGAQgASgJUhRpbnRyb2'
    'R1Y3RvcnlUZXh0SHRtbBIeCgpvZmZlclRpdGxlGAUgASgJUgpvZmZlclRpdGxlEjAKE25vQWN0'
    'aW9uRGVzY3JpcHRpb24YBiABKAlSE25vQWN0aW9uRGVzY3JpcHRpb24SNgoWdGVybXNBbmRDb2'
    '5kaXRpb25zSHRtbBgHIAEoCVIWdGVybXNBbmRDb25kaXRpb25zSHRtbA==');

@$core.Deprecated('Use availablePromoOfferDescriptor instead')
const AvailablePromoOffer$json = {
  '1': 'AvailablePromoOffer',
  '2': [
    {
      '1': 'addCreditCardOffer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AddCreditCardPromoOffer',
      '10': 'addCreditCardOffer'
    },
  ],
};

/// Descriptor for `AvailablePromoOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availablePromoOfferDescriptor = $convert.base64Decode(
    'ChNBdmFpbGFibGVQcm9tb09mZmVyEkgKEmFkZENyZWRpdENhcmRPZmZlchgBIAEoCzIYLkFkZE'
    'NyZWRpdENhcmRQcm9tb09mZmVyUhJhZGRDcmVkaXRDYXJkT2ZmZXI=');

@$core.Deprecated('Use checkPromoOfferResponseDescriptor instead')
const CheckPromoOfferResponse$json = {
  '1': 'CheckPromoOfferResponse',
  '2': [
    {
      '1': 'availableOffer',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.AvailablePromoOffer',
      '10': 'availableOffer'
    },
    {
      '1': 'redeemedOffer',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.RedeemedPromoOffer',
      '10': 'redeemedOffer'
    },
    {
      '1': 'checkoutTokenRequired',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'checkoutTokenRequired'
    },
  ],
};

/// Descriptor for `CheckPromoOfferResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkPromoOfferResponseDescriptor = $convert.base64Decode(
    'ChdDaGVja1Byb21vT2ZmZXJSZXNwb25zZRI8Cg5hdmFpbGFibGVPZmZlchgBIAMoCzIULkF2YW'
    'lsYWJsZVByb21vT2ZmZXJSDmF2YWlsYWJsZU9mZmVyEjkKDXJlZGVlbWVkT2ZmZXIYAiABKAsy'
    'Ey5SZWRlZW1lZFByb21vT2ZmZXJSDXJlZGVlbWVkT2ZmZXISNAoVY2hlY2tvdXRUb2tlblJlcX'
    'VpcmVkGAMgASgIUhVjaGVja291dFRva2VuUmVxdWlyZWQ=');

@$core.Deprecated('Use redeemedPromoOfferDescriptor instead')
const RedeemedPromoOffer$json = {
  '1': 'RedeemedPromoOffer',
  '2': [
    {'1': 'headerText', '3': 1, '4': 1, '5': 9, '10': 'headerText'},
    {'1': 'descriptionHtml', '3': 2, '4': 1, '5': 9, '10': 'descriptionHtml'},
    {'1': 'image', '3': 3, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
  ],
};

/// Descriptor for `RedeemedPromoOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemedPromoOfferDescriptor = $convert.base64Decode(
    'ChJSZWRlZW1lZFByb21vT2ZmZXISHgoKaGVhZGVyVGV4dBgBIAEoCVIKaGVhZGVyVGV4dBIoCg'
    '9kZXNjcmlwdGlvbkh0bWwYAiABKAlSD2Rlc2NyaXB0aW9uSHRtbBIcCgVpbWFnZRgDIAEoCzIG'
    'LkltYWdlUgVpbWFnZQ==');

@$core.Deprecated('Use docIdDescriptor instead')
const DocId$json = {
  '1': 'DocId',
  '2': [
    {'1': 'backendDocId', '3': 1, '4': 1, '5': 9, '10': 'backendDocId'},
    {'1': 'type', '3': 2, '4': 1, '5': 5, '7': '1', '10': 'type'},
    {'1': 'backend', '3': 3, '4': 1, '5': 5, '10': 'backend'},
  ],
};

/// Descriptor for `DocId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List docIdDescriptor = $convert.base64Decode(
    'CgVEb2NJZBIiCgxiYWNrZW5kRG9jSWQYASABKAlSDGJhY2tlbmREb2NJZBIVCgR0eXBlGAIgAS'
    'gFOgExUgR0eXBlEhgKB2JhY2tlbmQYAyABKAVSB2JhY2tlbmQ=');

@$core.Deprecated('Use installDescriptor instead')
const Install$json = {
  '1': 'Install',
  '2': [
    {'1': 'androidId', '3': 1, '4': 1, '5': 6, '10': 'androidId'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'bundled', '3': 3, '4': 1, '5': 8, '10': 'bundled'},
    {'1': 'pending', '3': 4, '4': 1, '5': 8, '10': 'pending'},
    {'1': 'lastUpdated', '3': 5, '4': 1, '5': 3, '10': 'lastUpdated'},
  ],
};

/// Descriptor for `Install`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List installDescriptor = $convert.base64Decode(
    'CgdJbnN0YWxsEhwKCWFuZHJvaWRJZBgBIAEoBlIJYW5kcm9pZElkEhgKB3ZlcnNpb24YAiABKA'
    'VSB3ZlcnNpb24SGAoHYnVuZGxlZBgDIAEoCFIHYnVuZGxlZBIYCgdwZW5kaW5nGAQgASgIUgdw'
    'ZW5kaW5nEiAKC2xhc3RVcGRhdGVkGAUgASgDUgtsYXN0VXBkYXRlZA==');

@$core.Deprecated('Use groupLicenseKeyDescriptor instead')
const GroupLicenseKey$json = {
  '1': 'GroupLicenseKey',
  '2': [
    {
      '1': 'dasher_customer_id',
      '3': 1,
      '4': 1,
      '5': 6,
      '10': 'dasherCustomerId'
    },
    {'1': 'docId', '3': 2, '4': 1, '5': 11, '6': '.DocId', '10': 'docId'},
    {
      '1': 'licensed_offer_type',
      '3': 3,
      '4': 1,
      '5': 5,
      '7': '1',
      '10': 'licensedOfferType'
    },
    {'1': 'type', '3': 4, '4': 1, '5': 5, '10': 'type'},
    {
      '1': 'rental_period_days',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'rentalPeriodDays'
    },
  ],
};

/// Descriptor for `GroupLicenseKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupLicenseKeyDescriptor = $convert.base64Decode(
    'Cg9Hcm91cExpY2Vuc2VLZXkSLAoSZGFzaGVyX2N1c3RvbWVyX2lkGAEgASgGUhBkYXNoZXJDdX'
    'N0b21lcklkEhwKBWRvY0lkGAIgASgLMgYuRG9jSWRSBWRvY0lkEjEKE2xpY2Vuc2VkX29mZmVy'
    'X3R5cGUYAyABKAU6ATFSEWxpY2Vuc2VkT2ZmZXJUeXBlEhIKBHR5cGUYBCABKAVSBHR5cGUSLA'
    'oScmVudGFsX3BlcmlvZF9kYXlzGAUgASgFUhByZW50YWxQZXJpb2REYXlz');

@$core.Deprecated('Use licenseTermsDescriptor instead')
const LicenseTerms$json = {
  '1': 'LicenseTerms',
  '2': [
    {
      '1': 'groupLicenseKey',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.GroupLicenseKey',
      '10': 'groupLicenseKey'
    },
  ],
};

/// Descriptor for `LicenseTerms`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List licenseTermsDescriptor = $convert.base64Decode(
    'CgxMaWNlbnNlVGVybXMSOgoPZ3JvdXBMaWNlbnNlS2V5GAEgASgLMhAuR3JvdXBMaWNlbnNlS2'
    'V5Ug9ncm91cExpY2Vuc2VLZXk=');

@$core.Deprecated('Use offerDescriptor instead')
const Offer$json = {
  '1': 'Offer',
  '2': [
    {'1': 'micros', '3': 1, '4': 1, '5': 3, '10': 'micros'},
    {'1': 'currencyCode', '3': 2, '4': 1, '5': 9, '10': 'currencyCode'},
    {'1': 'formattedAmount', '3': 3, '4': 1, '5': 9, '10': 'formattedAmount'},
    {
      '1': 'convertedPrice',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.Offer',
      '10': 'convertedPrice'
    },
    {
      '1': 'checkoutFlowRequired',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'checkoutFlowRequired'
    },
    {'1': 'fullPriceMicros', '3': 6, '4': 1, '5': 3, '10': 'fullPriceMicros'},
    {
      '1': 'formattedFullAmount',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'formattedFullAmount'
    },
    {'1': 'offerType', '3': 8, '4': 1, '5': 5, '7': '1', '10': 'offerType'},
    {
      '1': 'rentalTerms',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.RentalTerms',
      '10': 'rentalTerms'
    },
    {'1': 'onSaleDate', '3': 10, '4': 1, '5': 3, '10': 'onSaleDate'},
    {'1': 'promotionLabel', '3': 11, '4': 3, '5': 9, '10': 'promotionLabel'},
    {
      '1': 'subscriptionTerms',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.SubscriptionTerms',
      '10': 'subscriptionTerms'
    },
    {'1': 'formattedName', '3': 13, '4': 1, '5': 9, '10': 'formattedName'},
    {
      '1': 'formattedDescription',
      '3': 14,
      '4': 1,
      '5': 9,
      '10': 'formattedDescription'
    },
    {'1': 'preorder', '3': 15, '4': 1, '5': 8, '10': 'preorder'},
    {
      '1': 'onSaleDateDisplayTimeZoneOffsetMillis',
      '3': 16,
      '4': 1,
      '5': 5,
      '10': 'onSaleDateDisplayTimeZoneOffsetMillis'
    },
    {
      '1': 'licensedOfferType',
      '3': 17,
      '4': 1,
      '5': 5,
      '10': 'licensedOfferType'
    },
    {
      '1': 'subscriptionContentTerms',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.SubscriptionContentTerms',
      '10': 'subscriptionContentTerms'
    },
    {'1': 'offerId', '3': 19, '4': 1, '5': 9, '10': 'offerId'},
    {
      '1': 'preorderFulfillmentDisplayDate',
      '3': 20,
      '4': 1,
      '5': 3,
      '10': 'preorderFulfillmentDisplayDate'
    },
    {
      '1': 'licenseTerms',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.LicenseTerms',
      '10': 'licenseTerms'
    },
    {'1': 'sale', '3': 22, '4': 1, '5': 8, '10': 'sale'},
    {
      '1': 'voucherTerms',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.VoucherTerms',
      '10': 'voucherTerms'
    },
    {
      '1': 'offerPayment',
      '3': 24,
      '4': 3,
      '5': 11,
      '6': '.OfferPayment',
      '10': 'offerPayment'
    },
    {
      '1': 'repeatLastPayment',
      '3': 25,
      '4': 1,
      '5': 8,
      '10': 'repeatLastPayment'
    },
    {'1': 'buyButtonLabel', '3': 26, '4': 1, '5': 9, '10': 'buyButtonLabel'},
    {
      '1': 'instantPurchaseEnabled',
      '3': 27,
      '4': 1,
      '5': 8,
      '10': 'instantPurchaseEnabled'
    },
    {
      '1': 'saleEndTimestamp',
      '3': 30,
      '4': 1,
      '5': 3,
      '10': 'saleEndTimestamp'
    },
    {'1': 'saleMessage', '3': 31, '4': 1, '5': 9, '10': 'saleMessage'},
  ],
};

/// Descriptor for `Offer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List offerDescriptor = $convert.base64Decode(
    'CgVPZmZlchIWCgZtaWNyb3MYASABKANSBm1pY3JvcxIiCgxjdXJyZW5jeUNvZGUYAiABKAlSDG'
    'N1cnJlbmN5Q29kZRIoCg9mb3JtYXR0ZWRBbW91bnQYAyABKAlSD2Zvcm1hdHRlZEFtb3VudBIu'
    'Cg5jb252ZXJ0ZWRQcmljZRgEIAMoCzIGLk9mZmVyUg5jb252ZXJ0ZWRQcmljZRIyChRjaGVja2'
    '91dEZsb3dSZXF1aXJlZBgFIAEoCFIUY2hlY2tvdXRGbG93UmVxdWlyZWQSKAoPZnVsbFByaWNl'
    'TWljcm9zGAYgASgDUg9mdWxsUHJpY2VNaWNyb3MSMAoTZm9ybWF0dGVkRnVsbEFtb3VudBgHIA'
    'EoCVITZm9ybWF0dGVkRnVsbEFtb3VudBIfCglvZmZlclR5cGUYCCABKAU6ATFSCW9mZmVyVHlw'
    'ZRIuCgtyZW50YWxUZXJtcxgJIAEoCzIMLlJlbnRhbFRlcm1zUgtyZW50YWxUZXJtcxIeCgpvbl'
    'NhbGVEYXRlGAogASgDUgpvblNhbGVEYXRlEiYKDnByb21vdGlvbkxhYmVsGAsgAygJUg5wcm9t'
    'b3Rpb25MYWJlbBJAChFzdWJzY3JpcHRpb25UZXJtcxgMIAEoCzISLlN1YnNjcmlwdGlvblRlcm'
    '1zUhFzdWJzY3JpcHRpb25UZXJtcxIkCg1mb3JtYXR0ZWROYW1lGA0gASgJUg1mb3JtYXR0ZWRO'
    'YW1lEjIKFGZvcm1hdHRlZERlc2NyaXB0aW9uGA4gASgJUhRmb3JtYXR0ZWREZXNjcmlwdGlvbh'
    'IaCghwcmVvcmRlchgPIAEoCFIIcHJlb3JkZXISVAolb25TYWxlRGF0ZURpc3BsYXlUaW1lWm9u'
    'ZU9mZnNldE1pbGxpcxgQIAEoBVIlb25TYWxlRGF0ZURpc3BsYXlUaW1lWm9uZU9mZnNldE1pbG'
    'xpcxIsChFsaWNlbnNlZE9mZmVyVHlwZRgRIAEoBVIRbGljZW5zZWRPZmZlclR5cGUSVQoYc3Vi'
    'c2NyaXB0aW9uQ29udGVudFRlcm1zGBIgASgLMhkuU3Vic2NyaXB0aW9uQ29udGVudFRlcm1zUh'
    'hzdWJzY3JpcHRpb25Db250ZW50VGVybXMSGAoHb2ZmZXJJZBgTIAEoCVIHb2ZmZXJJZBJGCh5w'
    'cmVvcmRlckZ1bGZpbGxtZW50RGlzcGxheURhdGUYFCABKANSHnByZW9yZGVyRnVsZmlsbG1lbn'
    'REaXNwbGF5RGF0ZRIxCgxsaWNlbnNlVGVybXMYFSABKAsyDS5MaWNlbnNlVGVybXNSDGxpY2Vu'
    'c2VUZXJtcxISCgRzYWxlGBYgASgIUgRzYWxlEjEKDHZvdWNoZXJUZXJtcxgXIAEoCzINLlZvdW'
    'NoZXJUZXJtc1IMdm91Y2hlclRlcm1zEjEKDG9mZmVyUGF5bWVudBgYIAMoCzINLk9mZmVyUGF5'
    'bWVudFIMb2ZmZXJQYXltZW50EiwKEXJlcGVhdExhc3RQYXltZW50GBkgASgIUhFyZXBlYXRMYX'
    'N0UGF5bWVudBImCg5idXlCdXR0b25MYWJlbBgaIAEoCVIOYnV5QnV0dG9uTGFiZWwSNgoWaW5z'
    'dGFudFB1cmNoYXNlRW5hYmxlZBgbIAEoCFIWaW5zdGFudFB1cmNoYXNlRW5hYmxlZBIqChBzYW'
    'xlRW5kVGltZXN0YW1wGB4gASgDUhBzYWxlRW5kVGltZXN0YW1wEiAKC3NhbGVNZXNzYWdlGB8g'
    'ASgJUgtzYWxlTWVzc2FnZQ==');

@$core.Deprecated('Use monthAndDayDescriptor instead')
const MonthAndDay$json = {
  '1': 'MonthAndDay',
  '2': [
    {'1': 'month', '3': 1, '4': 1, '5': 13, '10': 'month'},
    {'1': 'day', '3': 2, '4': 1, '5': 13, '10': 'day'},
  ],
};

/// Descriptor for `MonthAndDay`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List monthAndDayDescriptor = $convert.base64Decode(
    'CgtNb250aEFuZERheRIUCgVtb250aBgBIAEoDVIFbW9udGgSEAoDZGF5GAIgASgNUgNkYXk=');

@$core.Deprecated('Use offerPaymentPeriodDescriptor instead')
const OfferPaymentPeriod$json = {
  '1': 'OfferPaymentPeriod',
  '2': [
    {
      '1': 'duration',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.TimePeriod',
      '10': 'duration'
    },
    {'1': 'start', '3': 2, '4': 1, '5': 11, '6': '.MonthAndDay', '10': 'start'},
    {'1': 'end', '3': 3, '4': 1, '5': 11, '6': '.MonthAndDay', '10': 'end'},
  ],
};

/// Descriptor for `OfferPaymentPeriod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List offerPaymentPeriodDescriptor = $convert.base64Decode(
    'ChJPZmZlclBheW1lbnRQZXJpb2QSJwoIZHVyYXRpb24YASABKAsyCy5UaW1lUGVyaW9kUghkdX'
    'JhdGlvbhIiCgVzdGFydBgCIAEoCzIMLk1vbnRoQW5kRGF5UgVzdGFydBIeCgNlbmQYAyABKAsy'
    'DC5Nb250aEFuZERheVIDZW5k');

@$core.Deprecated('Use offerPaymentOverrideDescriptor instead')
const OfferPaymentOverride$json = {
  '1': 'OfferPaymentOverride',
  '2': [
    {'1': 'micros', '3': 1, '4': 1, '5': 3, '10': 'micros'},
    {'1': 'start', '3': 2, '4': 1, '5': 11, '6': '.MonthAndDay', '10': 'start'},
    {'1': 'end', '3': 3, '4': 1, '5': 11, '6': '.MonthAndDay', '10': 'end'},
  ],
};

/// Descriptor for `OfferPaymentOverride`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List offerPaymentOverrideDescriptor = $convert.base64Decode(
    'ChRPZmZlclBheW1lbnRPdmVycmlkZRIWCgZtaWNyb3MYASABKANSBm1pY3JvcxIiCgVzdGFydB'
    'gCIAEoCzIMLk1vbnRoQW5kRGF5UgVzdGFydBIeCgNlbmQYAyABKAsyDC5Nb250aEFuZERheVID'
    'ZW5k');

@$core.Deprecated('Use offerPaymentDescriptor instead')
const OfferPayment$json = {
  '1': 'OfferPayment',
  '2': [
    {'1': 'micros', '3': 1, '4': 1, '5': 3, '10': 'micros'},
    {'1': 'currencyCode', '3': 2, '4': 1, '5': 9, '10': 'currencyCode'},
    {
      '1': 'offerPaymentPeriod',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.OfferPaymentPeriod',
      '10': 'offerPaymentPeriod'
    },
    {
      '1': 'offerPaymentOverride',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.OfferPaymentOverride',
      '10': 'offerPaymentOverride'
    },
  ],
};

/// Descriptor for `OfferPayment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List offerPaymentDescriptor = $convert.base64Decode(
    'CgxPZmZlclBheW1lbnQSFgoGbWljcm9zGAEgASgDUgZtaWNyb3MSIgoMY3VycmVuY3lDb2RlGA'
    'IgASgJUgxjdXJyZW5jeUNvZGUSQwoSb2ZmZXJQYXltZW50UGVyaW9kGAMgASgLMhMuT2ZmZXJQ'
    'YXltZW50UGVyaW9kUhJvZmZlclBheW1lbnRQZXJpb2QSSQoUb2ZmZXJQYXltZW50T3ZlcnJpZG'
    'UYBCADKAsyFS5PZmZlclBheW1lbnRPdmVycmlkZVIUb2ZmZXJQYXltZW50T3ZlcnJpZGU=');

@$core.Deprecated('Use voucherTermsDescriptor instead')
const VoucherTerms$json = {
  '1': 'VoucherTerms',
};

/// Descriptor for `VoucherTerms`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voucherTermsDescriptor =
    $convert.base64Decode('CgxWb3VjaGVyVGVybXM=');

@$core.Deprecated('Use rentalTermsDescriptor instead')
const RentalTerms$json = {
  '1': 'RentalTerms',
  '2': [
    {
      '1': 'dEPRECATEDGrantPeriodSeconds',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'dEPRECATEDGrantPeriodSeconds'
    },
    {
      '1': 'dEPRECATEDActivatePeriodSeconds',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'dEPRECATEDActivatePeriodSeconds'
    },
    {
      '1': 'grantPeriod',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.TimePeriod',
      '10': 'grantPeriod'
    },
    {
      '1': 'activatePeriod',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.TimePeriod',
      '10': 'activatePeriod'
    },
  ],
};

/// Descriptor for `RentalTerms`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rentalTermsDescriptor = $convert.base64Decode(
    'CgtSZW50YWxUZXJtcxJCChxkRVBSRUNBVEVER3JhbnRQZXJpb2RTZWNvbmRzGAEgASgFUhxkRV'
    'BSRUNBVEVER3JhbnRQZXJpb2RTZWNvbmRzEkgKH2RFUFJFQ0FURURBY3RpdmF0ZVBlcmlvZFNl'
    'Y29uZHMYAiABKAVSH2RFUFJFQ0FURURBY3RpdmF0ZVBlcmlvZFNlY29uZHMSLQoLZ3JhbnRQZX'
    'Jpb2QYAyABKAsyCy5UaW1lUGVyaW9kUgtncmFudFBlcmlvZBIzCg5hY3RpdmF0ZVBlcmlvZBgE'
    'IAEoCzILLlRpbWVQZXJpb2RSDmFjdGl2YXRlUGVyaW9k');

@$core.Deprecated('Use signedDataDescriptor instead')
const SignedData$json = {
  '1': 'SignedData',
  '2': [
    {'1': 'signedData', '3': 1, '4': 1, '5': 9, '10': 'signedData'},
    {'1': 'signature', '3': 2, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `SignedData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signedDataDescriptor = $convert.base64Decode(
    'CgpTaWduZWREYXRhEh4KCnNpZ25lZERhdGEYASABKAlSCnNpZ25lZERhdGESHAoJc2lnbmF0dX'
    'JlGAIgASgJUglzaWduYXR1cmU=');

@$core.Deprecated('Use subscriptionContentTermsDescriptor instead')
const SubscriptionContentTerms$json = {
  '1': 'SubscriptionContentTerms',
  '2': [
    {
      '1': 'requiredSubscription',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.DocId',
      '10': 'requiredSubscription'
    },
  ],
};

/// Descriptor for `SubscriptionContentTerms`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionContentTermsDescriptor =
    $convert.base64Decode(
        'ChhTdWJzY3JpcHRpb25Db250ZW50VGVybXMSOgoUcmVxdWlyZWRTdWJzY3JpcHRpb24YASABKA'
        'syBi5Eb2NJZFIUcmVxdWlyZWRTdWJzY3JpcHRpb24=');

@$core.Deprecated('Use groupLicenseInfoDescriptor instead')
const GroupLicenseInfo$json = {
  '1': 'GroupLicenseInfo',
  '2': [
    {
      '1': 'licensedOfferType',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'licensedOfferType'
    },
    {'1': 'gaiaGroupId', '3': 2, '4': 1, '5': 6, '10': 'gaiaGroupId'},
  ],
};

/// Descriptor for `GroupLicenseInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupLicenseInfoDescriptor = $convert.base64Decode(
    'ChBHcm91cExpY2Vuc2VJbmZvEiwKEWxpY2Vuc2VkT2ZmZXJUeXBlGAEgASgFUhFsaWNlbnNlZE'
    '9mZmVyVHlwZRIgCgtnYWlhR3JvdXBJZBgCIAEoBlILZ2FpYUdyb3VwSWQ=');

@$core.Deprecated('Use licensedDocumentInfoDescriptor instead')
const LicensedDocumentInfo$json = {
  '1': 'LicensedDocumentInfo',
  '2': [
    {'1': 'gaiaGroupId', '3': 1, '4': 3, '5': 6, '10': 'gaiaGroupId'},
  ],
};

/// Descriptor for `LicensedDocumentInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List licensedDocumentInfoDescriptor = $convert.base64Decode(
    'ChRMaWNlbnNlZERvY3VtZW50SW5mbxIgCgtnYWlhR3JvdXBJZBgBIAMoBlILZ2FpYUdyb3VwSW'
    'Q=');

@$core.Deprecated('Use ownershipInfoDescriptor instead')
const OwnershipInfo$json = {
  '1': 'OwnershipInfo',
  '2': [
    {
      '1': 'initiationTimestamp',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'initiationTimestamp'
    },
    {
      '1': 'validUntilTimestamp',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'validUntilTimestamp'
    },
    {'1': 'autoRenewing', '3': 3, '4': 1, '5': 8, '10': 'autoRenewing'},
    {
      '1': 'refundTimeoutTimestamp',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'refundTimeoutTimestamp'
    },
    {
      '1': 'postDeliveryRefundWindowMillis',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'postDeliveryRefundWindowMillis'
    },
    {
      '1': 'developerPurchaseInfo',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.SignedData',
      '10': 'developerPurchaseInfo'
    },
    {'1': 'preOrdered', '3': 7, '4': 1, '5': 8, '10': 'preOrdered'},
    {'1': 'hidden', '3': 8, '4': 1, '5': 8, '10': 'hidden'},
    {
      '1': 'rentalTerms',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.RentalTerms',
      '10': 'rentalTerms'
    },
    {
      '1': 'groupLicenseInfo',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.GroupLicenseInfo',
      '10': 'groupLicenseInfo'
    },
    {
      '1': 'licensedDocumentInfo',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.LicensedDocumentInfo',
      '10': 'licensedDocumentInfo'
    },
    {'1': 'quantity', '3': 12, '4': 1, '5': 5, '10': 'quantity'},
    {
      '1': 'libraryExpirationTimestamp',
      '3': 14,
      '4': 1,
      '5': 3,
      '10': 'libraryExpirationTimestamp'
    },
  ],
};

/// Descriptor for `OwnershipInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ownershipInfoDescriptor = $convert.base64Decode(
    'Cg1Pd25lcnNoaXBJbmZvEjAKE2luaXRpYXRpb25UaW1lc3RhbXAYASABKANSE2luaXRpYXRpb2'
    '5UaW1lc3RhbXASMAoTdmFsaWRVbnRpbFRpbWVzdGFtcBgCIAEoA1ITdmFsaWRVbnRpbFRpbWVz'
    'dGFtcBIiCgxhdXRvUmVuZXdpbmcYAyABKAhSDGF1dG9SZW5ld2luZxI2ChZyZWZ1bmRUaW1lb3'
    'V0VGltZXN0YW1wGAQgASgDUhZyZWZ1bmRUaW1lb3V0VGltZXN0YW1wEkYKHnBvc3REZWxpdmVy'
    'eVJlZnVuZFdpbmRvd01pbGxpcxgFIAEoA1IecG9zdERlbGl2ZXJ5UmVmdW5kV2luZG93TWlsbG'
    'lzEkEKFWRldmVsb3BlclB1cmNoYXNlSW5mbxgGIAEoCzILLlNpZ25lZERhdGFSFWRldmVsb3Bl'
    'clB1cmNoYXNlSW5mbxIeCgpwcmVPcmRlcmVkGAcgASgIUgpwcmVPcmRlcmVkEhYKBmhpZGRlbh'
    'gIIAEoCFIGaGlkZGVuEi4KC3JlbnRhbFRlcm1zGAkgASgLMgwuUmVudGFsVGVybXNSC3JlbnRh'
    'bFRlcm1zEj0KEGdyb3VwTGljZW5zZUluZm8YCiABKAsyES5Hcm91cExpY2Vuc2VJbmZvUhBncm'
    '91cExpY2Vuc2VJbmZvEkkKFGxpY2Vuc2VkRG9jdW1lbnRJbmZvGAsgASgLMhUuTGljZW5zZWRE'
    'b2N1bWVudEluZm9SFGxpY2Vuc2VkRG9jdW1lbnRJbmZvEhoKCHF1YW50aXR5GAwgASgFUghxdW'
    'FudGl0eRI+ChpsaWJyYXJ5RXhwaXJhdGlvblRpbWVzdGFtcBgOIAEoA1IabGlicmFyeUV4cGly'
    'YXRpb25UaW1lc3RhbXA=');

@$core.Deprecated('Use subscriptionTermsDescriptor instead')
const SubscriptionTerms$json = {
  '1': 'SubscriptionTerms',
  '2': [
    {
      '1': 'recurringPeriod',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.TimePeriod',
      '10': 'recurringPeriod'
    },
    {
      '1': 'trialPeriod',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.TimePeriod',
      '10': 'trialPeriod'
    },
  ],
};

/// Descriptor for `SubscriptionTerms`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionTermsDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpcHRpb25UZXJtcxI1Cg9yZWN1cnJpbmdQZXJpb2QYASABKAsyCy5UaW1lUGVyaW'
    '9kUg9yZWN1cnJpbmdQZXJpb2QSLQoLdHJpYWxQZXJpb2QYAiABKAsyCy5UaW1lUGVyaW9kUgt0'
    'cmlhbFBlcmlvZA==');

@$core.Deprecated('Use timePeriodDescriptor instead')
const TimePeriod$json = {
  '1': 'TimePeriod',
  '2': [
    {'1': 'unit', '3': 1, '4': 1, '5': 5, '10': 'unit'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `TimePeriod`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timePeriodDescriptor = $convert.base64Decode(
    'CgpUaW1lUGVyaW9kEhIKBHVuaXQYASABKAVSBHVuaXQSFAoFY291bnQYAiABKAVSBWNvdW50');

@$core.Deprecated('Use billingAddressSpecDescriptor instead')
const BillingAddressSpec$json = {
  '1': 'BillingAddressSpec',
  '2': [
    {
      '1': 'billingAddressType',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'billingAddressType'
    },
    {'1': 'requiredField', '3': 2, '4': 3, '5': 5, '10': 'requiredField'},
  ],
};

/// Descriptor for `BillingAddressSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingAddressSpecDescriptor = $convert.base64Decode(
    'ChJCaWxsaW5nQWRkcmVzc1NwZWMSLgoSYmlsbGluZ0FkZHJlc3NUeXBlGAEgASgFUhJiaWxsaW'
    '5nQWRkcmVzc1R5cGUSJAoNcmVxdWlyZWRGaWVsZBgCIAMoBVINcmVxdWlyZWRGaWVsZA==');

@$core.Deprecated('Use billingProfileDescriptor instead')
const BillingProfile$json = {
  '1': 'BillingProfile',
  '2': [
    {
      '1': 'instrument',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.Instrument',
      '10': 'instrument'
    },
    {
      '1': 'selectedExternalInstrumentId',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'selectedExternalInstrumentId'
    },
    {
      '1': 'billingProfileOption',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.BillingProfileOption',
      '10': 'billingProfileOption'
    },
  ],
};

/// Descriptor for `BillingProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingProfileDescriptor = $convert.base64Decode(
    'Cg5CaWxsaW5nUHJvZmlsZRIrCgppbnN0cnVtZW50GAEgAygLMgsuSW5zdHJ1bWVudFIKaW5zdH'
    'J1bWVudBJCChxzZWxlY3RlZEV4dGVybmFsSW5zdHJ1bWVudElkGAIgASgJUhxzZWxlY3RlZEV4'
    'dGVybmFsSW5zdHJ1bWVudElkEkkKFGJpbGxpbmdQcm9maWxlT3B0aW9uGAMgAygLMhUuQmlsbG'
    'luZ1Byb2ZpbGVPcHRpb25SFGJpbGxpbmdQcm9maWxlT3B0aW9u');

@$core.Deprecated('Use billingProfileOptionDescriptor instead')
const BillingProfileOption$json = {
  '1': 'BillingProfileOption',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'displayTitle', '3': 2, '4': 1, '5': 9, '10': 'displayTitle'},
    {
      '1': 'externalInstrumentId',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'externalInstrumentId'
    },
    {
      '1': 'topupInfo',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.TopupInfo',
      '10': 'topupInfo'
    },
    {
      '1': 'carrierBillingInstrumentStatus',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarrierBillingInstrumentStatus',
      '10': 'carrierBillingInstrumentStatus'
    },
  ],
};

/// Descriptor for `BillingProfileOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingProfileOptionDescriptor = $convert.base64Decode(
    'ChRCaWxsaW5nUHJvZmlsZU9wdGlvbhISCgR0eXBlGAEgASgFUgR0eXBlEiIKDGRpc3BsYXlUaX'
    'RsZRgCIAEoCVIMZGlzcGxheVRpdGxlEjIKFGV4dGVybmFsSW5zdHJ1bWVudElkGAMgASgJUhRl'
    'eHRlcm5hbEluc3RydW1lbnRJZBIoCgl0b3B1cEluZm8YBCABKAsyCi5Ub3B1cEluZm9SCXRvcH'
    'VwSW5mbxJnCh5jYXJyaWVyQmlsbGluZ0luc3RydW1lbnRTdGF0dXMYBSABKAsyHy5DYXJyaWVy'
    'QmlsbGluZ0luc3RydW1lbnRTdGF0dXNSHmNhcnJpZXJCaWxsaW5nSW5zdHJ1bWVudFN0YXR1cw'
    '==');

@$core.Deprecated('Use carrierBillingCredentialsDescriptor instead')
const CarrierBillingCredentials$json = {
  '1': 'CarrierBillingCredentials',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
    {'1': 'expiration', '3': 2, '4': 1, '5': 3, '10': 'expiration'},
  ],
};

/// Descriptor for `CarrierBillingCredentials`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List carrierBillingCredentialsDescriptor =
    $convert.base64Decode(
        'ChlDYXJyaWVyQmlsbGluZ0NyZWRlbnRpYWxzEhQKBXZhbHVlGAEgASgJUgV2YWx1ZRIeCgpleH'
        'BpcmF0aW9uGAIgASgDUgpleHBpcmF0aW9u');

@$core.Deprecated('Use carrierBillingInstrumentDescriptor instead')
const CarrierBillingInstrument$json = {
  '1': 'CarrierBillingInstrument',
  '2': [
    {'1': 'instrumentKey', '3': 1, '4': 1, '5': 9, '10': 'instrumentKey'},
    {'1': 'accountType', '3': 2, '4': 1, '5': 9, '10': 'accountType'},
    {'1': 'currencyCode', '3': 3, '4': 1, '5': 9, '10': 'currencyCode'},
    {'1': 'transactionLimit', '3': 4, '4': 1, '5': 3, '10': 'transactionLimit'},
    {
      '1': 'subscriberIdentifier',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'subscriberIdentifier'
    },
    {
      '1': 'encryptedSubscriberInfo',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EncryptedSubscriberInfo',
      '10': 'encryptedSubscriberInfo'
    },
    {
      '1': 'credentials',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.CarrierBillingCredentials',
      '10': 'credentials'
    },
    {
      '1': 'acceptedCarrierTos',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.CarrierTos',
      '10': 'acceptedCarrierTos'
    },
  ],
};

/// Descriptor for `CarrierBillingInstrument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List carrierBillingInstrumentDescriptor = $convert.base64Decode(
    'ChhDYXJyaWVyQmlsbGluZ0luc3RydW1lbnQSJAoNaW5zdHJ1bWVudEtleRgBIAEoCVINaW5zdH'
    'J1bWVudEtleRIgCgthY2NvdW50VHlwZRgCIAEoCVILYWNjb3VudFR5cGUSIgoMY3VycmVuY3lD'
    'b2RlGAMgASgJUgxjdXJyZW5jeUNvZGUSKgoQdHJhbnNhY3Rpb25MaW1pdBgEIAEoA1IQdHJhbn'
    'NhY3Rpb25MaW1pdBIyChRzdWJzY3JpYmVySWRlbnRpZmllchgFIAEoCVIUc3Vic2NyaWJlcklk'
    'ZW50aWZpZXISUgoXZW5jcnlwdGVkU3Vic2NyaWJlckluZm8YBiABKAsyGC5FbmNyeXB0ZWRTdW'
    'JzY3JpYmVySW5mb1IXZW5jcnlwdGVkU3Vic2NyaWJlckluZm8SPAoLY3JlZGVudGlhbHMYByAB'
    'KAsyGi5DYXJyaWVyQmlsbGluZ0NyZWRlbnRpYWxzUgtjcmVkZW50aWFscxI7ChJhY2NlcHRlZE'
    'NhcnJpZXJUb3MYCCABKAsyCy5DYXJyaWVyVG9zUhJhY2NlcHRlZENhcnJpZXJUb3M=');

@$core.Deprecated('Use carrierBillingInstrumentStatusDescriptor instead')
const CarrierBillingInstrumentStatus$json = {
  '1': 'CarrierBillingInstrumentStatus',
  '2': [
    {
      '1': 'carrierTos',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarrierTos',
      '10': 'carrierTos'
    },
    {
      '1': 'associationRequired',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'associationRequired'
    },
    {'1': 'passwordRequired', '3': 3, '4': 1, '5': 8, '10': 'passwordRequired'},
    {
      '1': 'carrierPasswordPrompt',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.PasswordPrompt',
      '10': 'carrierPasswordPrompt'
    },
    {'1': 'apiVersion', '3': 5, '4': 1, '5': 5, '10': 'apiVersion'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'deviceAssociation',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.DeviceAssociation',
      '10': 'deviceAssociation'
    },
    {
      '1': 'carrierSupportPhoneNumber',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'carrierSupportPhoneNumber'
    },
  ],
};

/// Descriptor for `CarrierBillingInstrumentStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List carrierBillingInstrumentStatusDescriptor = $convert.base64Decode(
    'Ch5DYXJyaWVyQmlsbGluZ0luc3RydW1lbnRTdGF0dXMSKwoKY2FycmllclRvcxgBIAEoCzILLk'
    'NhcnJpZXJUb3NSCmNhcnJpZXJUb3MSMAoTYXNzb2NpYXRpb25SZXF1aXJlZBgCIAEoCFITYXNz'
    'b2NpYXRpb25SZXF1aXJlZBIqChBwYXNzd29yZFJlcXVpcmVkGAMgASgIUhBwYXNzd29yZFJlcX'
    'VpcmVkEkUKFWNhcnJpZXJQYXNzd29yZFByb21wdBgEIAEoCzIPLlBhc3N3b3JkUHJvbXB0UhVj'
    'YXJyaWVyUGFzc3dvcmRQcm9tcHQSHgoKYXBpVmVyc2lvbhgFIAEoBVIKYXBpVmVyc2lvbhISCg'
    'RuYW1lGAYgASgJUgRuYW1lEkAKEWRldmljZUFzc29jaWF0aW9uGAcgASgLMhIuRGV2aWNlQXNz'
    'b2NpYXRpb25SEWRldmljZUFzc29jaWF0aW9uEjwKGWNhcnJpZXJTdXBwb3J0UGhvbmVOdW1iZX'
    'IYCCABKAlSGWNhcnJpZXJTdXBwb3J0UGhvbmVOdW1iZXI=');

@$core.Deprecated('Use carrierTosDescriptor instead')
const CarrierTos$json = {
  '1': 'CarrierTos',
  '2': [
    {
      '1': 'dcbTos',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarrierTosEntry',
      '10': 'dcbTos'
    },
    {
      '1': 'piiTos',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarrierTosEntry',
      '10': 'piiTos'
    },
    {
      '1': 'needsDcbTosAcceptance',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'needsDcbTosAcceptance'
    },
    {
      '1': 'needsPiiTosAcceptance',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'needsPiiTosAcceptance'
    },
  ],
};

/// Descriptor for `CarrierTos`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List carrierTosDescriptor = $convert.base64Decode(
    'CgpDYXJyaWVyVG9zEigKBmRjYlRvcxgBIAEoCzIQLkNhcnJpZXJUb3NFbnRyeVIGZGNiVG9zEi'
    'gKBnBpaVRvcxgCIAEoCzIQLkNhcnJpZXJUb3NFbnRyeVIGcGlpVG9zEjQKFW5lZWRzRGNiVG9z'
    'QWNjZXB0YW5jZRgDIAEoCFIVbmVlZHNEY2JUb3NBY2NlcHRhbmNlEjQKFW5lZWRzUGlpVG9zQW'
    'NjZXB0YW5jZRgEIAEoCFIVbmVlZHNQaWlUb3NBY2NlcHRhbmNl');

@$core.Deprecated('Use carrierTosEntryDescriptor instead')
const CarrierTosEntry$json = {
  '1': 'CarrierTosEntry',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `CarrierTosEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List carrierTosEntryDescriptor = $convert.base64Decode(
    'Cg9DYXJyaWVyVG9zRW50cnkSEAoDdXJsGAEgASgJUgN1cmwSGAoHdmVyc2lvbhgCIAEoCVIHdm'
    'Vyc2lvbg==');

@$core.Deprecated('Use creditCardInstrumentDescriptor instead')
const CreditCardInstrument$json = {
  '1': 'CreditCardInstrument',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'escrowHandle', '3': 2, '4': 1, '5': 9, '10': 'escrowHandle'},
    {'1': 'lastDigits', '3': 3, '4': 1, '5': 9, '10': 'lastDigits'},
    {'1': 'expirationMonth', '3': 4, '4': 1, '5': 5, '10': 'expirationMonth'},
    {'1': 'expirationYear', '3': 5, '4': 1, '5': 5, '10': 'expirationYear'},
    {
      '1': 'escrowEfeParam',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.EfeParam',
      '10': 'escrowEfeParam'
    },
  ],
};

/// Descriptor for `CreditCardInstrument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List creditCardInstrumentDescriptor = $convert.base64Decode(
    'ChRDcmVkaXRDYXJkSW5zdHJ1bWVudBISCgR0eXBlGAEgASgFUgR0eXBlEiIKDGVzY3Jvd0hhbm'
    'RsZRgCIAEoCVIMZXNjcm93SGFuZGxlEh4KCmxhc3REaWdpdHMYAyABKAlSCmxhc3REaWdpdHMS'
    'KAoPZXhwaXJhdGlvbk1vbnRoGAQgASgFUg9leHBpcmF0aW9uTW9udGgSJgoOZXhwaXJhdGlvbl'
    'llYXIYBSABKAVSDmV4cGlyYXRpb25ZZWFyEjEKDmVzY3Jvd0VmZVBhcmFtGAYgAygLMgkuRWZl'
    'UGFyYW1SDmVzY3Jvd0VmZVBhcmFt');

@$core.Deprecated('Use deviceAssociationDescriptor instead')
const DeviceAssociation$json = {
  '1': 'DeviceAssociation',
  '2': [
    {
      '1': 'userTokenRequestMessage',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'userTokenRequestMessage'
    },
    {
      '1': 'userTokenRequestAddress',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'userTokenRequestAddress'
    },
  ],
};

/// Descriptor for `DeviceAssociation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceAssociationDescriptor = $convert.base64Decode(
    'ChFEZXZpY2VBc3NvY2lhdGlvbhI4Chd1c2VyVG9rZW5SZXF1ZXN0TWVzc2FnZRgBIAEoCVIXdX'
    'NlclRva2VuUmVxdWVzdE1lc3NhZ2USOAoXdXNlclRva2VuUmVxdWVzdEFkZHJlc3MYAiABKAlS'
    'F3VzZXJUb2tlblJlcXVlc3RBZGRyZXNz');

@$core.Deprecated('Use disabledInfoDescriptor instead')
const DisabledInfo$json = {
  '1': 'DisabledInfo',
  '2': [
    {'1': 'disabledReason', '3': 1, '4': 1, '5': 5, '10': 'disabledReason'},
    {
      '1': 'disabledMessageHtml',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'disabledMessageHtml'
    },
    {'1': 'errorMessage', '3': 3, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `DisabledInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disabledInfoDescriptor = $convert.base64Decode(
    'CgxEaXNhYmxlZEluZm8SJgoOZGlzYWJsZWRSZWFzb24YASABKAVSDmRpc2FibGVkUmVhc29uEj'
    'AKE2Rpc2FibGVkTWVzc2FnZUh0bWwYAiABKAlSE2Rpc2FibGVkTWVzc2FnZUh0bWwSIgoMZXJy'
    'b3JNZXNzYWdlGAMgASgJUgxlcnJvck1lc3NhZ2U=');

@$core.Deprecated('Use efeParamDescriptor instead')
const EfeParam$json = {
  '1': 'EfeParam',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 5, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `EfeParam`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List efeParamDescriptor = $convert.base64Decode(
    'CghFZmVQYXJhbRIQCgNrZXkYASABKAVSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU=');

@$core.Deprecated('Use instrumentDescriptor instead')
const Instrument$json = {
  '1': 'Instrument',
  '2': [
    {'1': 'instrumentId', '3': 1, '4': 1, '5': 9, '10': 'instrumentId'},
    {
      '1': 'billingAddress',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.Address',
      '10': 'billingAddress'
    },
    {
      '1': 'creditCard',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CreditCardInstrument',
      '10': 'creditCard'
    },
    {
      '1': 'carrierBilling',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarrierBillingInstrument',
      '10': 'carrierBilling'
    },
    {
      '1': 'billingAddressSpec',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.BillingAddressSpec',
      '10': 'billingAddressSpec'
    },
    {'1': 'instrumentFamily', '3': 6, '4': 1, '5': 5, '10': 'instrumentFamily'},
    {
      '1': 'carrierBillingStatus',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.CarrierBillingInstrumentStatus',
      '10': 'carrierBillingStatus'
    },
    {'1': 'displayTitle', '3': 8, '4': 1, '5': 9, '10': 'displayTitle'},
    {
      '1': 'topupInfoDeprecated',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.TopupInfo',
      '10': 'topupInfoDeprecated'
    },
    {'1': 'version', '3': 10, '4': 1, '5': 5, '10': 'version'},
    {
      '1': 'storedValue',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.StoredValueInstrument',
      '10': 'storedValue'
    },
    {
      '1': 'disabledInfo',
      '3': 12,
      '4': 3,
      '5': 11,
      '6': '.DisabledInfo',
      '10': 'disabledInfo'
    },
  ],
};

/// Descriptor for `Instrument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instrumentDescriptor = $convert.base64Decode(
    'CgpJbnN0cnVtZW50EiIKDGluc3RydW1lbnRJZBgBIAEoCVIMaW5zdHJ1bWVudElkEjAKDmJpbG'
    'xpbmdBZGRyZXNzGAIgASgLMgguQWRkcmVzc1IOYmlsbGluZ0FkZHJlc3MSNQoKY3JlZGl0Q2Fy'
    'ZBgDIAEoCzIVLkNyZWRpdENhcmRJbnN0cnVtZW50UgpjcmVkaXRDYXJkEkEKDmNhcnJpZXJCaW'
    'xsaW5nGAQgASgLMhkuQ2FycmllckJpbGxpbmdJbnN0cnVtZW50Ug5jYXJyaWVyQmlsbGluZxJD'
    'ChJiaWxsaW5nQWRkcmVzc1NwZWMYBSABKAsyEy5CaWxsaW5nQWRkcmVzc1NwZWNSEmJpbGxpbm'
    'dBZGRyZXNzU3BlYxIqChBpbnN0cnVtZW50RmFtaWx5GAYgASgFUhBpbnN0cnVtZW50RmFtaWx5'
    'ElMKFGNhcnJpZXJCaWxsaW5nU3RhdHVzGAcgASgLMh8uQ2FycmllckJpbGxpbmdJbnN0cnVtZW'
    '50U3RhdHVzUhRjYXJyaWVyQmlsbGluZ1N0YXR1cxIiCgxkaXNwbGF5VGl0bGUYCCABKAlSDGRp'
    'c3BsYXlUaXRsZRI8ChN0b3B1cEluZm9EZXByZWNhdGVkGAkgASgLMgouVG9wdXBJbmZvUhN0b3'
    'B1cEluZm9EZXByZWNhdGVkEhgKB3ZlcnNpb24YCiABKAVSB3ZlcnNpb24SOAoLc3RvcmVkVmFs'
    'dWUYCyABKAsyFi5TdG9yZWRWYWx1ZUluc3RydW1lbnRSC3N0b3JlZFZhbHVlEjEKDGRpc2FibG'
    'VkSW5mbxgMIAMoCzINLkRpc2FibGVkSW5mb1IMZGlzYWJsZWRJbmZv');

@$core.Deprecated('Use instrumentSetupInfoDescriptor instead')
const InstrumentSetupInfo$json = {
  '1': 'InstrumentSetupInfo',
  '2': [
    {'1': 'instrumentFamily', '3': 1, '4': 1, '5': 5, '10': 'instrumentFamily'},
    {'1': 'supported', '3': 2, '4': 1, '5': 8, '10': 'supported'},
    {
      '1': 'addressChallenge',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.AddressChallenge',
      '10': 'addressChallenge'
    },
    {'1': 'balance', '3': 4, '4': 1, '5': 11, '6': '.Money', '10': 'balance'},
    {'1': 'footerHtml', '3': 5, '4': 3, '5': 9, '10': 'footerHtml'},
  ],
};

/// Descriptor for `InstrumentSetupInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instrumentSetupInfoDescriptor = $convert.base64Decode(
    'ChNJbnN0cnVtZW50U2V0dXBJbmZvEioKEGluc3RydW1lbnRGYW1pbHkYASABKAVSEGluc3RydW'
    '1lbnRGYW1pbHkSHAoJc3VwcG9ydGVkGAIgASgIUglzdXBwb3J0ZWQSPQoQYWRkcmVzc0NoYWxs'
    'ZW5nZRgDIAEoCzIRLkFkZHJlc3NDaGFsbGVuZ2VSEGFkZHJlc3NDaGFsbGVuZ2USIAoHYmFsYW'
    '5jZRgEIAEoCzIGLk1vbmV5UgdiYWxhbmNlEh4KCmZvb3Rlckh0bWwYBSADKAlSCmZvb3Rlckh0'
    'bWw=');

@$core.Deprecated('Use passwordPromptDescriptor instead')
const PasswordPrompt$json = {
  '1': 'PasswordPrompt',
  '2': [
    {'1': 'prompt', '3': 1, '4': 1, '5': 9, '10': 'prompt'},
    {
      '1': 'forgotPasswordUrl',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'forgotPasswordUrl'
    },
  ],
};

/// Descriptor for `PasswordPrompt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List passwordPromptDescriptor = $convert.base64Decode(
    'Cg5QYXNzd29yZFByb21wdBIWCgZwcm9tcHQYASABKAlSBnByb21wdBIsChFmb3Jnb3RQYXNzd2'
    '9yZFVybBgCIAEoCVIRZm9yZ290UGFzc3dvcmRVcmw=');

@$core.Deprecated('Use storedValueInstrumentDescriptor instead')
const StoredValueInstrument$json = {
  '1': 'StoredValueInstrument',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'balance', '3': 2, '4': 1, '5': 11, '6': '.Money', '10': 'balance'},
    {
      '1': 'topupInfo',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.TopupInfo',
      '10': 'topupInfo'
    },
  ],
};

/// Descriptor for `StoredValueInstrument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List storedValueInstrumentDescriptor = $convert.base64Decode(
    'ChVTdG9yZWRWYWx1ZUluc3RydW1lbnQSEgoEdHlwZRgBIAEoBVIEdHlwZRIgCgdiYWxhbmNlGA'
    'IgASgLMgYuTW9uZXlSB2JhbGFuY2USKAoJdG9wdXBJbmZvGAMgASgLMgouVG9wdXBJbmZvUgl0'
    'b3B1cEluZm8=');

@$core.Deprecated('Use topupInfoDescriptor instead')
const TopupInfo$json = {
  '1': 'TopupInfo',
  '2': [
    {
      '1': 'optionsContainerDocIdDeprecated',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'optionsContainerDocIdDeprecated'
    },
    {'1': 'optionsListUrl', '3': 2, '4': 1, '5': 9, '10': 'optionsListUrl'},
    {'1': 'subtitle', '3': 3, '4': 1, '5': 9, '10': 'subtitle'},
    {
      '1': 'optionsContainerDocId',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.DocId',
      '10': 'optionsContainerDocId'
    },
  ],
};

/// Descriptor for `TopupInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List topupInfoDescriptor = $convert.base64Decode(
    'CglUb3B1cEluZm8SSAofb3B0aW9uc0NvbnRhaW5lckRvY0lkRGVwcmVjYXRlZBgBIAEoCVIfb3'
    'B0aW9uc0NvbnRhaW5lckRvY0lkRGVwcmVjYXRlZBImCg5vcHRpb25zTGlzdFVybBgCIAEoCVIO'
    'b3B0aW9uc0xpc3RVcmwSGgoIc3VidGl0bGUYAyABKAlSCHN1YnRpdGxlEjwKFW9wdGlvbnNDb2'
    '50YWluZXJEb2NJZBgEIAEoCzIGLkRvY0lkUhVvcHRpb25zQ29udGFpbmVyRG9jSWQ=');

@$core.Deprecated('Use consumePurchaseResponseDescriptor instead')
const ConsumePurchaseResponse$json = {
  '1': 'ConsumePurchaseResponse',
  '2': [
    {
      '1': 'libraryUpdate',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.LibraryUpdate',
      '10': 'libraryUpdate'
    },
    {'1': 'status', '3': 2, '4': 1, '5': 5, '10': 'status'},
  ],
};

/// Descriptor for `ConsumePurchaseResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List consumePurchaseResponseDescriptor =
    $convert.base64Decode(
        'ChdDb25zdW1lUHVyY2hhc2VSZXNwb25zZRI0Cg1saWJyYXJ5VXBkYXRlGAEgASgLMg4uTGlicm'
        'FyeVVwZGF0ZVINbGlicmFyeVVwZGF0ZRIWCgZzdGF0dXMYAiABKAVSBnN0YXR1cw==');

@$core.Deprecated('Use containerMetadataDescriptor instead')
const ContainerMetadata$json = {
  '1': 'ContainerMetadata',
  '2': [
    {'1': 'browseUrl', '3': 1, '4': 1, '5': 9, '10': 'browseUrl'},
    {'1': 'nextPageUrl', '3': 2, '4': 1, '5': 9, '10': 'nextPageUrl'},
    {'1': 'relevance', '3': 3, '4': 1, '5': 1, '10': 'relevance'},
    {'1': 'estimatedResults', '3': 4, '4': 1, '5': 3, '10': 'estimatedResults'},
    {'1': 'analyticsCookie', '3': 5, '4': 1, '5': 9, '10': 'analyticsCookie'},
    {'1': 'ordered', '3': 6, '4': 1, '5': 8, '10': 'ordered'},
    {
      '1': 'containerView',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.ContainerView',
      '10': 'containerView'
    },
    {'1': 'leftIcon', '3': 8, '4': 1, '5': 11, '6': '.Image', '10': 'leftIcon'},
  ],
};

/// Descriptor for `ContainerMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List containerMetadataDescriptor = $convert.base64Decode(
    'ChFDb250YWluZXJNZXRhZGF0YRIcCglicm93c2VVcmwYASABKAlSCWJyb3dzZVVybBIgCgtuZX'
    'h0UGFnZVVybBgCIAEoCVILbmV4dFBhZ2VVcmwSHAoJcmVsZXZhbmNlGAMgASgBUglyZWxldmFu'
    'Y2USKgoQZXN0aW1hdGVkUmVzdWx0cxgEIAEoA1IQZXN0aW1hdGVkUmVzdWx0cxIoCg9hbmFseX'
    'RpY3NDb29raWUYBSABKAlSD2FuYWx5dGljc0Nvb2tpZRIYCgdvcmRlcmVkGAYgASgIUgdvcmRl'
    'cmVkEjQKDWNvbnRhaW5lclZpZXcYByADKAsyDi5Db250YWluZXJWaWV3Ug1jb250YWluZXJWaW'
    'V3EiIKCGxlZnRJY29uGAggASgLMgYuSW1hZ2VSCGxlZnRJY29u');

@$core.Deprecated('Use containerViewDescriptor instead')
const ContainerView$json = {
  '1': 'ContainerView',
  '2': [
    {'1': 'selected', '3': 1, '4': 1, '5': 8, '10': 'selected'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'listUrl', '3': 3, '4': 1, '5': 9, '10': 'listUrl'},
    {
      '1': 'serverLogsCookie',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
  ],
};

/// Descriptor for `ContainerView`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List containerViewDescriptor = $convert.base64Decode(
    'Cg1Db250YWluZXJWaWV3EhoKCHNlbGVjdGVkGAEgASgIUghzZWxlY3RlZBIUCgV0aXRsZRgCIA'
    'EoCVIFdGl0bGUSGAoHbGlzdFVybBgDIAEoCVIHbGlzdFVybBIqChBzZXJ2ZXJMb2dzQ29va2ll'
    'GAQgASgMUhBzZXJ2ZXJMb2dzQ29va2ll');

@$core.Deprecated('Use flagContentResponseDescriptor instead')
const FlagContentResponse$json = {
  '1': 'FlagContentResponse',
};

/// Descriptor for `FlagContentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flagContentResponseDescriptor =
    $convert.base64Decode('ChNGbGFnQ29udGVudFJlc3BvbnNl');

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest$json = {
  '1': 'ClientDownloadRequest',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'digests',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ClientDownloadRequest.Digests',
      '10': 'digests'
    },
    {'1': 'length', '3': 3, '4': 1, '5': 3, '10': 'length'},
    {
      '1': 'resources',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.ClientDownloadRequest.Resource',
      '10': 'resources'
    },
    {
      '1': 'signature',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.ClientDownloadRequest.SignatureInfo',
      '10': 'signature'
    },
    {'1': 'userInitiated', '3': 6, '4': 1, '5': 8, '10': 'userInitiated'},
    {'1': 'clientAsn', '3': 8, '4': 3, '5': 9, '10': 'clientAsn'},
    {'1': 'fileBasename', '3': 9, '4': 1, '5': 9, '10': 'fileBasename'},
    {'1': 'downloadType', '3': 10, '4': 1, '5': 5, '10': 'downloadType'},
    {'1': 'locale', '3': 11, '4': 1, '5': 9, '10': 'locale'},
    {
      '1': 'apkInfo',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.ClientDownloadRequest.ApkInfo',
      '10': 'apkInfo'
    },
    {'1': 'androidId', '3': 13, '4': 1, '5': 6, '10': 'androidId'},
    {
      '1': 'originatingPackages',
      '3': 15,
      '4': 3,
      '5': 9,
      '10': 'originatingPackages'
    },
    {
      '1': 'originatingSignature',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.ClientDownloadRequest.SignatureInfo',
      '10': 'originatingSignature'
    },
  ],
  '3': [
    ClientDownloadRequest_ApkInfo$json,
    ClientDownloadRequest_CertificateChain$json,
    ClientDownloadRequest_Digests$json,
    ClientDownloadRequest_Resource$json,
    ClientDownloadRequest_SignatureInfo$json
  ],
};

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest_ApkInfo$json = {
  '1': 'ApkInfo',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
    {'1': 'versionCode', '3': 2, '4': 1, '5': 5, '10': 'versionCode'},
  ],
};

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest_CertificateChain$json = {
  '1': 'CertificateChain',
  '2': [
    {
      '1': 'element',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ClientDownloadRequest.CertificateChain.Element',
      '10': 'element'
    },
  ],
  '3': [ClientDownloadRequest_CertificateChain_Element$json],
};

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest_CertificateChain_Element$json = {
  '1': 'Element',
  '2': [
    {'1': 'certificate', '3': 1, '4': 1, '5': 12, '10': 'certificate'},
    {
      '1': 'parsedSuccessfully',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'parsedSuccessfully'
    },
    {'1': 'subject', '3': 3, '4': 1, '5': 12, '10': 'subject'},
    {'1': 'issuer', '3': 4, '4': 1, '5': 12, '10': 'issuer'},
    {'1': 'fingerprint', '3': 5, '4': 1, '5': 12, '10': 'fingerprint'},
    {'1': 'expiryTime', '3': 6, '4': 1, '5': 3, '10': 'expiryTime'},
    {'1': 'startTime', '3': 7, '4': 1, '5': 3, '10': 'startTime'},
  ],
};

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest_Digests$json = {
  '1': 'Digests',
  '2': [
    {'1': 'sha256', '3': 1, '4': 1, '5': 12, '10': 'sha256'},
    {'1': 'sha1', '3': 2, '4': 1, '5': 12, '10': 'sha1'},
    {'1': 'md5', '3': 3, '4': 1, '5': 12, '10': 'md5'},
  ],
};

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest_Resource$json = {
  '1': 'Resource',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'type', '3': 2, '4': 1, '5': 5, '10': 'type'},
    {'1': 'remoteIp', '3': 3, '4': 1, '5': 12, '10': 'remoteIp'},
    {'1': 'referrer', '3': 4, '4': 1, '5': 9, '10': 'referrer'},
  ],
};

@$core.Deprecated('Use clientDownloadRequestDescriptor instead')
const ClientDownloadRequest_SignatureInfo$json = {
  '1': 'SignatureInfo',
  '2': [
    {
      '1': 'certificateChain',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ClientDownloadRequest.CertificateChain',
      '10': 'certificateChain'
    },
    {'1': 'trusted', '3': 2, '4': 1, '5': 8, '10': 'trusted'},
  ],
};

/// Descriptor for `ClientDownloadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientDownloadRequestDescriptor = $convert.base64Decode(
    'ChVDbGllbnREb3dubG9hZFJlcXVlc3QSEAoDdXJsGAEgASgJUgN1cmwSOAoHZGlnZXN0cxgCIA'
    'EoCzIeLkNsaWVudERvd25sb2FkUmVxdWVzdC5EaWdlc3RzUgdkaWdlc3RzEhYKBmxlbmd0aBgD'
    'IAEoA1IGbGVuZ3RoEj0KCXJlc291cmNlcxgEIAMoCzIfLkNsaWVudERvd25sb2FkUmVxdWVzdC'
    '5SZXNvdXJjZVIJcmVzb3VyY2VzEkIKCXNpZ25hdHVyZRgFIAEoCzIkLkNsaWVudERvd25sb2Fk'
    'UmVxdWVzdC5TaWduYXR1cmVJbmZvUglzaWduYXR1cmUSJAoNdXNlckluaXRpYXRlZBgGIAEoCF'
    'INdXNlckluaXRpYXRlZBIcCgljbGllbnRBc24YCCADKAlSCWNsaWVudEFzbhIiCgxmaWxlQmFz'
    'ZW5hbWUYCSABKAlSDGZpbGVCYXNlbmFtZRIiCgxkb3dubG9hZFR5cGUYCiABKAVSDGRvd25sb2'
    'FkVHlwZRIWCgZsb2NhbGUYCyABKAlSBmxvY2FsZRI4CgdhcGtJbmZvGAwgASgLMh4uQ2xpZW50'
    'RG93bmxvYWRSZXF1ZXN0LkFwa0luZm9SB2Fwa0luZm8SHAoJYW5kcm9pZElkGA0gASgGUglhbm'
    'Ryb2lkSWQSMAoTb3JpZ2luYXRpbmdQYWNrYWdlcxgPIAMoCVITb3JpZ2luYXRpbmdQYWNrYWdl'
    'cxJYChRvcmlnaW5hdGluZ1NpZ25hdHVyZRgRIAEoCzIkLkNsaWVudERvd25sb2FkUmVxdWVzdC'
    '5TaWduYXR1cmVJbmZvUhRvcmlnaW5hdGluZ1NpZ25hdHVyZRpNCgdBcGtJbmZvEiAKC3BhY2th'
    'Z2VOYW1lGAEgASgJUgtwYWNrYWdlTmFtZRIgCgt2ZXJzaW9uQ29kZRgCIAEoBVILdmVyc2lvbk'
    'NvZGUazQIKEENlcnRpZmljYXRlQ2hhaW4SSQoHZWxlbWVudBgBIAMoCzIvLkNsaWVudERvd25s'
    'b2FkUmVxdWVzdC5DZXJ0aWZpY2F0ZUNoYWluLkVsZW1lbnRSB2VsZW1lbnQa7QEKB0VsZW1lbn'
    'QSIAoLY2VydGlmaWNhdGUYASABKAxSC2NlcnRpZmljYXRlEi4KEnBhcnNlZFN1Y2Nlc3NmdWxs'
    'eRgCIAEoCFIScGFyc2VkU3VjY2Vzc2Z1bGx5EhgKB3N1YmplY3QYAyABKAxSB3N1YmplY3QSFg'
    'oGaXNzdWVyGAQgASgMUgZpc3N1ZXISIAoLZmluZ2VycHJpbnQYBSABKAxSC2ZpbmdlcnByaW50'
    'Eh4KCmV4cGlyeVRpbWUYBiABKANSCmV4cGlyeVRpbWUSHAoJc3RhcnRUaW1lGAcgASgDUglzdG'
    'FydFRpbWUaRwoHRGlnZXN0cxIWCgZzaGEyNTYYASABKAxSBnNoYTI1NhISCgRzaGExGAIgASgM'
    'UgRzaGExEhAKA21kNRgDIAEoDFIDbWQ1GmgKCFJlc291cmNlEhAKA3VybBgBIAEoCVIDdXJsEh'
    'IKBHR5cGUYAiABKAVSBHR5cGUSGgoIcmVtb3RlSXAYAyABKAxSCHJlbW90ZUlwEhoKCHJlZmVy'
    'cmVyGAQgASgJUghyZWZlcnJlchp+Cg1TaWduYXR1cmVJbmZvElMKEGNlcnRpZmljYXRlQ2hhaW'
    '4YASADKAsyJy5DbGllbnREb3dubG9hZFJlcXVlc3QuQ2VydGlmaWNhdGVDaGFpblIQY2VydGlm'
    'aWNhdGVDaGFpbhIYCgd0cnVzdGVkGAIgASgIUgd0cnVzdGVk');

@$core.Deprecated('Use clientDownloadResponseDescriptor instead')
const ClientDownloadResponse$json = {
  '1': 'ClientDownloadResponse',
  '2': [
    {'1': 'verdict', '3': 1, '4': 1, '5': 5, '10': 'verdict'},
    {
      '1': 'moreInfo',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ClientDownloadResponse.MoreInfo',
      '10': 'moreInfo'
    },
    {'1': 'token', '3': 3, '4': 1, '5': 12, '10': 'token'},
  ],
  '3': [ClientDownloadResponse_MoreInfo$json],
};

@$core.Deprecated('Use clientDownloadResponseDescriptor instead')
const ClientDownloadResponse_MoreInfo$json = {
  '1': 'MoreInfo',
  '2': [
    {'1': 'description', '3': 1, '4': 1, '5': 9, '10': 'description'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `ClientDownloadResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientDownloadResponseDescriptor = $convert.base64Decode(
    'ChZDbGllbnREb3dubG9hZFJlc3BvbnNlEhgKB3ZlcmRpY3QYASABKAVSB3ZlcmRpY3QSPAoIbW'
    '9yZUluZm8YAiABKAsyIC5DbGllbnREb3dubG9hZFJlc3BvbnNlLk1vcmVJbmZvUghtb3JlSW5m'
    'bxIUCgV0b2tlbhgDIAEoDFIFdG9rZW4aPgoITW9yZUluZm8SIAoLZGVzY3JpcHRpb24YASABKA'
    'lSC2Rlc2NyaXB0aW9uEhAKA3VybBgCIAEoCVIDdXJs');

@$core.Deprecated('Use clientDownloadStatsRequestDescriptor instead')
const ClientDownloadStatsRequest$json = {
  '1': 'ClientDownloadStatsRequest',
  '2': [
    {'1': 'userDecision', '3': 1, '4': 1, '5': 5, '10': 'userDecision'},
    {'1': 'token', '3': 2, '4': 1, '5': 12, '10': 'token'},
  ],
};

/// Descriptor for `ClientDownloadStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientDownloadStatsRequestDescriptor =
    $convert.base64Decode(
        'ChpDbGllbnREb3dubG9hZFN0YXRzUmVxdWVzdBIiCgx1c2VyRGVjaXNpb24YASABKAVSDHVzZX'
        'JEZWNpc2lvbhIUCgV0b2tlbhgCIAEoDFIFdG9rZW4=');

@$core.Deprecated('Use debugInfoDescriptor instead')
const DebugInfo$json = {
  '1': 'DebugInfo',
  '2': [
    {'1': 'message', '3': 1, '4': 3, '5': 9, '10': 'message'},
    {
      '1': 'timing',
      '3': 2,
      '4': 3,
      '5': 10,
      '6': '.DebugInfo.Timing',
      '10': 'timing'
    },
  ],
  '3': [DebugInfo_Timing$json],
};

@$core.Deprecated('Use debugInfoDescriptor instead')
const DebugInfo_Timing$json = {
  '1': 'Timing',
  '2': [
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'timeInMs', '3': 4, '4': 1, '5': 1, '10': 'timeInMs'},
  ],
};

/// Descriptor for `DebugInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugInfoDescriptor = $convert.base64Decode(
    'CglEZWJ1Z0luZm8SGAoHbWVzc2FnZRgBIAMoCVIHbWVzc2FnZRIpCgZ0aW1pbmcYAiADKAoyES'
    '5EZWJ1Z0luZm8uVGltaW5nUgZ0aW1pbmcaOAoGVGltaW5nEhIKBG5hbWUYAyABKAlSBG5hbWUS'
    'GgoIdGltZUluTXMYBCABKAFSCHRpbWVJbk1z');

@$core.Deprecated('Use debugSettingsResponseDescriptor instead')
const DebugSettingsResponse$json = {
  '1': 'DebugSettingsResponse',
  '2': [
    {
      '1': 'playCountryOverride',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'playCountryOverride'
    },
    {
      '1': 'playCountryDebugInfo',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'playCountryDebugInfo'
    },
  ],
};

/// Descriptor for `DebugSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List debugSettingsResponseDescriptor = $convert.base64Decode(
    'ChVEZWJ1Z1NldHRpbmdzUmVzcG9uc2USMAoTcGxheUNvdW50cnlPdmVycmlkZRgBIAEoCVITcG'
    'xheUNvdW50cnlPdmVycmlkZRIyChRwbGF5Q291bnRyeURlYnVnSW5mbxgCIAEoCVIUcGxheUNv'
    'dW50cnlEZWJ1Z0luZm8=');

@$core.Deprecated('Use deliveryResponseDescriptor instead')
const DeliveryResponse$json = {
  '1': 'DeliveryResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 5, '7': '1', '10': 'status'},
    {
      '1': 'appDeliveryData',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppDeliveryData',
      '10': 'appDeliveryData'
    },
  ],
};

/// Descriptor for `DeliveryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deliveryResponseDescriptor = $convert.base64Decode(
    'ChBEZWxpdmVyeVJlc3BvbnNlEhkKBnN0YXR1cxgBIAEoBToBMVIGc3RhdHVzEkEKD2FwcERlbG'
    'l2ZXJ5RGF0YRgCIAEoCzIXLkFuZHJvaWRBcHBEZWxpdmVyeURhdGFSD2FwcERlbGl2ZXJ5RGF0'
    'YQ==');

@$core.Deprecated('Use bulkDetailsEntryDescriptor instead')
const BulkDetailsEntry$json = {
  '1': 'BulkDetailsEntry',
  '2': [
    {'1': 'item', '3': 1, '4': 1, '5': 11, '6': '.Item', '10': 'item'},
  ],
};

/// Descriptor for `BulkDetailsEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bulkDetailsEntryDescriptor = $convert.base64Decode(
    'ChBCdWxrRGV0YWlsc0VudHJ5EhkKBGl0ZW0YASABKAsyBS5JdGVtUgRpdGVt');

@$core.Deprecated('Use bulkDetailsRequestDescriptor instead')
const BulkDetailsRequest$json = {
  '1': 'BulkDetailsRequest',
  '2': [
    {'1': 'DocId', '3': 1, '4': 3, '5': 9, '10': 'DocId'},
    {
      '1': 'includeChildDocs',
      '3': 2,
      '4': 1,
      '5': 8,
      '7': 'true',
      '10': 'includeChildDocs'
    },
    {'1': 'includeDetails', '3': 3, '4': 1, '5': 8, '10': 'includeDetails'},
    {
      '1': 'sourcePackageName',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'sourcePackageName'
    },
    {
      '1': 'installedVersionCode',
      '3': 7,
      '4': 3,
      '5': 5,
      '10': 'installedVersionCode'
    },
  ],
};

/// Descriptor for `BulkDetailsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bulkDetailsRequestDescriptor = $convert.base64Decode(
    'ChJCdWxrRGV0YWlsc1JlcXVlc3QSFAoFRG9jSWQYASADKAlSBURvY0lkEjAKEGluY2x1ZGVDaG'
    'lsZERvY3MYAiABKAg6BHRydWVSEGluY2x1ZGVDaGlsZERvY3MSJgoOaW5jbHVkZURldGFpbHMY'
    'AyABKAhSDmluY2x1ZGVEZXRhaWxzEiwKEXNvdXJjZVBhY2thZ2VOYW1lGAQgASgJUhFzb3VyY2'
    'VQYWNrYWdlTmFtZRIyChRpbnN0YWxsZWRWZXJzaW9uQ29kZRgHIAMoBVIUaW5zdGFsbGVkVmVy'
    'c2lvbkNvZGU=');

@$core.Deprecated('Use bulkDetailsResponseDescriptor instead')
const BulkDetailsResponse$json = {
  '1': 'BulkDetailsResponse',
  '2': [
    {
      '1': 'entry',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.BulkDetailsEntry',
      '10': 'entry'
    },
  ],
};

/// Descriptor for `BulkDetailsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bulkDetailsResponseDescriptor = $convert.base64Decode(
    'ChNCdWxrRGV0YWlsc1Jlc3BvbnNlEicKBWVudHJ5GAEgAygLMhEuQnVsa0RldGFpbHNFbnRyeV'
    'IFZW50cnk=');

@$core.Deprecated('Use detailsResponseDescriptor instead')
const DetailsResponse$json = {
  '1': 'DetailsResponse',
  '2': [
    {'1': 'analyticsCookie', '3': 2, '4': 1, '5': 9, '10': 'analyticsCookie'},
    {
      '1': 'userReview',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.Review',
      '10': 'userReview'
    },
    {'1': 'item', '3': 4, '4': 1, '5': 11, '6': '.Item', '10': 'item'},
    {'1': 'footerHtml', '3': 5, '4': 1, '5': 9, '10': 'footerHtml'},
    {
      '1': 'serverLogsCookie',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {
      '1': 'discoveryBadge',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.DiscoveryBadge',
      '10': 'discoveryBadge'
    },
    {
      '1': 'enableReviews',
      '3': 8,
      '4': 1,
      '5': 8,
      '7': 'true',
      '10': 'enableReviews'
    },
    {
      '1': 'features',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.Features',
      '10': 'features'
    },
    {
      '1': 'detailsStreamUrl',
      '3': 13,
      '4': 1,
      '5': 9,
      '10': 'detailsStreamUrl'
    },
    {'1': 'userReviewUrl', '3': 14, '4': 1, '5': 9, '10': 'userReviewUrl'},
    {
      '1': 'postAcquireDetailsStreamUrl',
      '3': 17,
      '4': 1,
      '5': 9,
      '10': 'postAcquireDetailsStreamUrl'
    },
  ],
};

/// Descriptor for `DetailsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detailsResponseDescriptor = $convert.base64Decode(
    'Cg9EZXRhaWxzUmVzcG9uc2USKAoPYW5hbHl0aWNzQ29va2llGAIgASgJUg9hbmFseXRpY3NDb2'
    '9raWUSJwoKdXNlclJldmlldxgDIAEoCzIHLlJldmlld1IKdXNlclJldmlldxIZCgRpdGVtGAQg'
    'ASgLMgUuSXRlbVIEaXRlbRIeCgpmb290ZXJIdG1sGAUgASgJUgpmb290ZXJIdG1sEioKEHNlcn'
    'ZlckxvZ3NDb29raWUYBiABKAxSEHNlcnZlckxvZ3NDb29raWUSNwoOZGlzY292ZXJ5QmFkZ2UY'
    'ByADKAsyDy5EaXNjb3ZlcnlCYWRnZVIOZGlzY292ZXJ5QmFkZ2USKgoNZW5hYmxlUmV2aWV3cx'
    'gIIAEoCDoEdHJ1ZVINZW5hYmxlUmV2aWV3cxIlCghmZWF0dXJlcxgMIAEoCzIJLkZlYXR1cmVz'
    'UghmZWF0dXJlcxIqChBkZXRhaWxzU3RyZWFtVXJsGA0gASgJUhBkZXRhaWxzU3RyZWFtVXJsEi'
    'QKDXVzZXJSZXZpZXdVcmwYDiABKAlSDXVzZXJSZXZpZXdVcmwSQAobcG9zdEFjcXVpcmVEZXRh'
    'aWxzU3RyZWFtVXJsGBEgASgJUhtwb3N0QWNxdWlyZURldGFpbHNTdHJlYW1Vcmw=');

@$core.Deprecated('Use discoveryBadgeDescriptor instead')
const DiscoveryBadge$json = {
  '1': 'DiscoveryBadge',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'image', '3': 2, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'backgroundColor', '3': 3, '4': 1, '5': 5, '10': 'backgroundColor'},
    {
      '1': 'badgeContainer1',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.DiscoveryBadgeLink',
      '10': 'badgeContainer1'
    },
    {
      '1': 'serverLogsCookie',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'isPlusOne', '3': 6, '4': 1, '5': 8, '10': 'isPlusOne'},
    {'1': 'aggregateRating', '3': 7, '4': 1, '5': 2, '10': 'aggregateRating'},
    {'1': 'userStarRating', '3': 8, '4': 1, '5': 5, '10': 'userStarRating'},
    {'1': 'downloadCount', '3': 9, '4': 1, '5': 9, '10': 'downloadCount'},
    {'1': 'downloadUnits', '3': 10, '4': 1, '5': 9, '10': 'downloadUnits'},
    {
      '1': 'contentDescription',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'contentDescription'
    },
    {
      '1': 'playerBadge',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.PlayerBadge',
      '10': 'playerBadge'
    },
    {
      '1': 'familyAgeRangeBadge',
      '3': 13,
      '4': 1,
      '5': 12,
      '10': 'familyAgeRangeBadge'
    },
    {
      '1': 'familyCategoryBadge',
      '3': 14,
      '4': 1,
      '5': 12,
      '10': 'familyCategoryBadge'
    },
  ],
};

/// Descriptor for `DiscoveryBadge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoveryBadgeDescriptor = $convert.base64Decode(
    'Cg5EaXNjb3ZlcnlCYWRnZRIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSHAoFaW1hZ2UYAiABKAsyBi'
    '5JbWFnZVIFaW1hZ2USKAoPYmFja2dyb3VuZENvbG9yGAMgASgFUg9iYWNrZ3JvdW5kQ29sb3IS'
    'PQoPYmFkZ2VDb250YWluZXIxGAQgASgLMhMuRGlzY292ZXJ5QmFkZ2VMaW5rUg9iYWRnZUNvbn'
    'RhaW5lcjESKgoQc2VydmVyTG9nc0Nvb2tpZRgFIAEoDFIQc2VydmVyTG9nc0Nvb2tpZRIcCglp'
    'c1BsdXNPbmUYBiABKAhSCWlzUGx1c09uZRIoCg9hZ2dyZWdhdGVSYXRpbmcYByABKAJSD2FnZ3'
    'JlZ2F0ZVJhdGluZxImCg51c2VyU3RhclJhdGluZxgIIAEoBVIOdXNlclN0YXJSYXRpbmcSJAoN'
    'ZG93bmxvYWRDb3VudBgJIAEoCVINZG93bmxvYWRDb3VudBIkCg1kb3dubG9hZFVuaXRzGAogAS'
    'gJUg1kb3dubG9hZFVuaXRzEi4KEmNvbnRlbnREZXNjcmlwdGlvbhgLIAEoCVISY29udGVudERl'
    'c2NyaXB0aW9uEi4KC3BsYXllckJhZGdlGAwgASgLMgwuUGxheWVyQmFkZ2VSC3BsYXllckJhZG'
    'dlEjAKE2ZhbWlseUFnZVJhbmdlQmFkZ2UYDSABKAxSE2ZhbWlseUFnZVJhbmdlQmFkZ2USMAoT'
    'ZmFtaWx5Q2F0ZWdvcnlCYWRnZRgOIAEoDFITZmFtaWx5Q2F0ZWdvcnlCYWRnZQ==');

@$core.Deprecated('Use playerBadgeDescriptor instead')
const PlayerBadge$json = {
  '1': 'PlayerBadge',
  '2': [
    {
      '1': 'overlayIcon',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.Image',
      '10': 'overlayIcon'
    },
  ],
};

/// Descriptor for `PlayerBadge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playerBadgeDescriptor = $convert.base64Decode(
    'CgtQbGF5ZXJCYWRnZRIoCgtvdmVybGF5SWNvbhgBIAEoCzIGLkltYWdlUgtvdmVybGF5SWNvbg'
    '==');

@$core.Deprecated('Use discoveryBadgeLinkDescriptor instead')
const DiscoveryBadgeLink$json = {
  '1': 'DiscoveryBadgeLink',
  '2': [
    {'1': 'link', '3': 1, '4': 1, '5': 11, '6': '.Link', '10': 'link'},
    {'1': 'userReviewsUrl', '3': 2, '4': 1, '5': 9, '10': 'userReviewsUrl'},
    {'1': 'criticReviewsUrl', '3': 3, '4': 1, '5': 9, '10': 'criticReviewsUrl'},
  ],
};

/// Descriptor for `DiscoveryBadgeLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List discoveryBadgeLinkDescriptor = $convert.base64Decode(
    'ChJEaXNjb3ZlcnlCYWRnZUxpbmsSGQoEbGluaxgBIAEoCzIFLkxpbmtSBGxpbmsSJgoOdXNlcl'
    'Jldmlld3NVcmwYAiABKAlSDnVzZXJSZXZpZXdzVXJsEioKEGNyaXRpY1Jldmlld3NVcmwYAyAB'
    'KAlSEGNyaXRpY1Jldmlld3NVcmw=');

@$core.Deprecated('Use featuresDescriptor instead')
const Features$json = {
  '1': 'Features',
  '2': [
    {
      '1': 'featurePresence',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.Feature',
      '10': 'featurePresence'
    },
    {
      '1': 'featureRating',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.Feature',
      '10': 'featureRating'
    },
  ],
};

/// Descriptor for `Features`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List featuresDescriptor = $convert.base64Decode(
    'CghGZWF0dXJlcxIyCg9mZWF0dXJlUHJlc2VuY2UYASADKAsyCC5GZWF0dXJlUg9mZWF0dXJlUH'
    'Jlc2VuY2USLgoNZmVhdHVyZVJhdGluZxgCIAMoCzIILkZlYXR1cmVSDWZlYXR1cmVSYXRpbmc=');

@$core.Deprecated('Use featureDescriptor instead')
const Feature$json = {
  '1': 'Feature',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'value', '3': 3, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `Feature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List featureDescriptor = $convert.base64Decode(
    'CgdGZWF0dXJlEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIUCgV2YWx1ZRgDIAEoCVIFdmFsdWU=');

@$core.Deprecated('Use deviceConfigurationProtoDescriptor instead')
const DeviceConfigurationProto$json = {
  '1': 'DeviceConfigurationProto',
  '2': [
    {'1': 'touchScreen', '3': 1, '4': 1, '5': 5, '10': 'touchScreen'},
    {'1': 'keyboard', '3': 2, '4': 1, '5': 5, '10': 'keyboard'},
    {'1': 'navigation', '3': 3, '4': 1, '5': 5, '10': 'navigation'},
    {'1': 'screenLayout', '3': 4, '4': 1, '5': 5, '10': 'screenLayout'},
    {'1': 'hasHardKeyboard', '3': 5, '4': 1, '5': 8, '10': 'hasHardKeyboard'},
    {
      '1': 'hasFiveWayNavigation',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'hasFiveWayNavigation'
    },
    {'1': 'screenDensity', '3': 7, '4': 1, '5': 5, '10': 'screenDensity'},
    {'1': 'glEsVersion', '3': 8, '4': 1, '5': 5, '10': 'glEsVersion'},
    {
      '1': 'systemSharedLibrary',
      '3': 9,
      '4': 3,
      '5': 9,
      '10': 'systemSharedLibrary'
    },
    {
      '1': 'systemAvailableFeature',
      '3': 10,
      '4': 3,
      '5': 9,
      '10': 'systemAvailableFeature'
    },
    {'1': 'nativePlatform', '3': 11, '4': 3, '5': 9, '10': 'nativePlatform'},
    {'1': 'screenWidth', '3': 12, '4': 1, '5': 5, '10': 'screenWidth'},
    {'1': 'screenHeight', '3': 13, '4': 1, '5': 5, '10': 'screenHeight'},
    {
      '1': 'systemSupportedLocale',
      '3': 14,
      '4': 3,
      '5': 9,
      '10': 'systemSupportedLocale'
    },
    {'1': 'glExtension', '3': 15, '4': 3, '5': 9, '10': 'glExtension'},
    {'1': 'deviceClass', '3': 16, '4': 1, '5': 5, '10': 'deviceClass'},
    {
      '1': 'maxApkDownloadSizeMb',
      '3': 17,
      '4': 1,
      '5': 5,
      '7': '50',
      '10': 'maxApkDownloadSizeMb'
    },
    {
      '1': 'smallestScreenWidthDP',
      '3': 18,
      '4': 1,
      '5': 5,
      '10': 'smallestScreenWidthDP'
    },
    {
      '1': 'lowRamDevice',
      '3': 19,
      '4': 1,
      '5': 5,
      '7': '0',
      '10': 'lowRamDevice'
    },
    {
      '1': 'totalMemoryBytes',
      '3': 20,
      '4': 1,
      '5': 3,
      '7': '8354971648',
      '10': 'totalMemoryBytes'
    },
    {
      '1': 'maxNumOf_CPUCores',
      '3': 21,
      '4': 1,
      '5': 5,
      '7': '8',
      '10': 'maxNumOfCPUCores'
    },
    {
      '1': 'deviceFeature',
      '3': 26,
      '4': 3,
      '5': 11,
      '6': '.DeviceFeature',
      '10': 'deviceFeature'
    },
    {'1': 'unknown28', '3': 28, '4': 1, '5': 5, '7': '0', '10': 'unknown28'},
    {'1': 'unknown30', '3': 30, '4': 1, '5': 5, '7': '4', '10': 'unknown30'},
  ],
};

/// Descriptor for `DeviceConfigurationProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceConfigurationProtoDescriptor = $convert.base64Decode(
    'ChhEZXZpY2VDb25maWd1cmF0aW9uUHJvdG8SIAoLdG91Y2hTY3JlZW4YASABKAVSC3RvdWNoU2'
    'NyZWVuEhoKCGtleWJvYXJkGAIgASgFUghrZXlib2FyZBIeCgpuYXZpZ2F0aW9uGAMgASgFUgpu'
    'YXZpZ2F0aW9uEiIKDHNjcmVlbkxheW91dBgEIAEoBVIMc2NyZWVuTGF5b3V0EigKD2hhc0hhcm'
    'RLZXlib2FyZBgFIAEoCFIPaGFzSGFyZEtleWJvYXJkEjIKFGhhc0ZpdmVXYXlOYXZpZ2F0aW9u'
    'GAYgASgIUhRoYXNGaXZlV2F5TmF2aWdhdGlvbhIkCg1zY3JlZW5EZW5zaXR5GAcgASgFUg1zY3'
    'JlZW5EZW5zaXR5EiAKC2dsRXNWZXJzaW9uGAggASgFUgtnbEVzVmVyc2lvbhIwChNzeXN0ZW1T'
    'aGFyZWRMaWJyYXJ5GAkgAygJUhNzeXN0ZW1TaGFyZWRMaWJyYXJ5EjYKFnN5c3RlbUF2YWlsYW'
    'JsZUZlYXR1cmUYCiADKAlSFnN5c3RlbUF2YWlsYWJsZUZlYXR1cmUSJgoObmF0aXZlUGxhdGZv'
    'cm0YCyADKAlSDm5hdGl2ZVBsYXRmb3JtEiAKC3NjcmVlbldpZHRoGAwgASgFUgtzY3JlZW5XaW'
    'R0aBIiCgxzY3JlZW5IZWlnaHQYDSABKAVSDHNjcmVlbkhlaWdodBI0ChVzeXN0ZW1TdXBwb3J0'
    'ZWRMb2NhbGUYDiADKAlSFXN5c3RlbVN1cHBvcnRlZExvY2FsZRIgCgtnbEV4dGVuc2lvbhgPIA'
    'MoCVILZ2xFeHRlbnNpb24SIAoLZGV2aWNlQ2xhc3MYECABKAVSC2RldmljZUNsYXNzEjYKFG1h'
    'eEFwa0Rvd25sb2FkU2l6ZU1iGBEgASgFOgI1MFIUbWF4QXBrRG93bmxvYWRTaXplTWISNAoVc2'
    '1hbGxlc3RTY3JlZW5XaWR0aERQGBIgASgFUhVzbWFsbGVzdFNjcmVlbldpZHRoRFASJQoMbG93'
    'UmFtRGV2aWNlGBMgASgFOgEwUgxsb3dSYW1EZXZpY2USNgoQdG90YWxNZW1vcnlCeXRlcxgUIA'
    'EoAzoKODM1NDk3MTY0OFIQdG90YWxNZW1vcnlCeXRlcxIuChFtYXhOdW1PZl9DUFVDb3JlcxgV'
    'IAEoBToBOFIQbWF4TnVtT2ZDUFVDb3JlcxI0Cg1kZXZpY2VGZWF0dXJlGBogAygLMg4uRGV2aW'
    'NlRmVhdHVyZVINZGV2aWNlRmVhdHVyZRIfCgl1bmtub3duMjgYHCABKAU6ATBSCXVua25vd24y'
    'OBIfCgl1bmtub3duMzAYHiABKAU6ATRSCXVua25vd24zMA==');

@$core.Deprecated('Use deviceFeatureDescriptor instead')
const DeviceFeature$json = {
  '1': 'DeviceFeature',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `DeviceFeature`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceFeatureDescriptor = $convert.base64Decode(
    'Cg1EZXZpY2VGZWF0dXJlEhIKBG5hbWUYASABKAlSBG5hbWUSFAoFdmFsdWUYAiABKAVSBXZhbH'
    'Vl');

@$core.Deprecated('Use documentDescriptor instead')
const Document$json = {
  '1': 'Document',
  '2': [
    {'1': 'DocId', '3': 1, '4': 1, '5': 11, '6': '.DocId', '10': 'DocId'},
    {
      '1': 'fetchDocId',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.DocId',
      '10': 'fetchDocId'
    },
    {
      '1': 'sampleDocId',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.DocId',
      '10': 'sampleDocId'
    },
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {'1': 'snippet', '3': 6, '4': 3, '5': 9, '10': 'snippet'},
    {
      '1': 'priceDeprecated',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.Offer',
      '10': 'priceDeprecated'
    },
    {
      '1': 'availability',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.Availability',
      '10': 'availability'
    },
    {'1': 'image', '3': 10, '4': 3, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'child', '3': 11, '4': 3, '5': 11, '6': '.Document', '10': 'child'},
    {
      '1': 'aggregateRating',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.AggregateRating',
      '10': 'aggregateRating'
    },
    {'1': 'offer', '3': 14, '4': 3, '5': 11, '6': '.Offer', '10': 'offer'},
    {
      '1': 'translatedSnippet',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.TranslatedText',
      '10': 'translatedSnippet'
    },
    {
      '1': 'documentVariant',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.DocumentVariant',
      '10': 'documentVariant'
    },
    {'1': 'categoryId', '3': 17, '4': 3, '5': 9, '10': 'categoryId'},
    {
      '1': 'decoration',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.Document',
      '10': 'decoration'
    },
    {'1': 'parent', '3': 19, '4': 3, '5': 11, '6': '.Document', '10': 'parent'},
    {
      '1': 'privacyPolicyUrl',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'privacyPolicyUrl'
    },
    {'1': 'consumptionUrl', '3': 21, '4': 1, '5': 9, '10': 'consumptionUrl'},
    {
      '1': 'estimatedNumChildren',
      '3': 22,
      '4': 1,
      '5': 5,
      '10': 'estimatedNumChildren'
    },
    {'1': 'subtitle', '3': 23, '4': 1, '5': 9, '10': 'subtitle'},
  ],
};

/// Descriptor for `Document`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentDescriptor = $convert.base64Decode(
    'CghEb2N1bWVudBIcCgVEb2NJZBgBIAEoCzIGLkRvY0lkUgVEb2NJZBImCgpmZXRjaERvY0lkGA'
    'IgASgLMgYuRG9jSWRSCmZldGNoRG9jSWQSKAoLc2FtcGxlRG9jSWQYAyABKAsyBi5Eb2NJZFIL'
    'c2FtcGxlRG9jSWQSFAoFdGl0bGUYBCABKAlSBXRpdGxlEhAKA3VybBgFIAEoCVIDdXJsEhgKB3'
    'NuaXBwZXQYBiADKAlSB3NuaXBwZXQSMAoPcHJpY2VEZXByZWNhdGVkGAcgASgLMgYuT2ZmZXJS'
    'D3ByaWNlRGVwcmVjYXRlZBIxCgxhdmFpbGFiaWxpdHkYCSABKAsyDS5BdmFpbGFiaWxpdHlSDG'
    'F2YWlsYWJpbGl0eRIcCgVpbWFnZRgKIAMoCzIGLkltYWdlUgVpbWFnZRIfCgVjaGlsZBgLIAMo'
    'CzIJLkRvY3VtZW50UgVjaGlsZBI6Cg9hZ2dyZWdhdGVSYXRpbmcYDSABKAsyEC5BZ2dyZWdhdG'
    'VSYXRpbmdSD2FnZ3JlZ2F0ZVJhdGluZxIcCgVvZmZlchgOIAMoCzIGLk9mZmVyUgVvZmZlchI9'
    'ChF0cmFuc2xhdGVkU25pcHBldBgPIAMoCzIPLlRyYW5zbGF0ZWRUZXh0UhF0cmFuc2xhdGVkU2'
    '5pcHBldBI6Cg9kb2N1bWVudFZhcmlhbnQYECADKAsyEC5Eb2N1bWVudFZhcmlhbnRSD2RvY3Vt'
    'ZW50VmFyaWFudBIeCgpjYXRlZ29yeUlkGBEgAygJUgpjYXRlZ29yeUlkEikKCmRlY29yYXRpb2'
    '4YEiADKAsyCS5Eb2N1bWVudFIKZGVjb3JhdGlvbhIhCgZwYXJlbnQYEyADKAsyCS5Eb2N1bWVu'
    'dFIGcGFyZW50EioKEHByaXZhY3lQb2xpY3lVcmwYFCABKAlSEHByaXZhY3lQb2xpY3lVcmwSJg'
    'oOY29uc3VtcHRpb25VcmwYFSABKAlSDmNvbnN1bXB0aW9uVXJsEjIKFGVzdGltYXRlZE51bUNo'
    'aWxkcmVuGBYgASgFUhRlc3RpbWF0ZWROdW1DaGlsZHJlbhIaCghzdWJ0aXRsZRgXIAEoCVIIc3'
    'VidGl0bGU=');

@$core.Deprecated('Use documentVariantDescriptor instead')
const DocumentVariant$json = {
  '1': 'DocumentVariant',
  '2': [
    {'1': 'variationType', '3': 1, '4': 1, '5': 5, '10': 'variationType'},
    {'1': 'rule', '3': 2, '4': 1, '5': 11, '6': '.Rule', '10': 'rule'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'snippet', '3': 4, '4': 3, '5': 9, '10': 'snippet'},
    {'1': 'recentChanges', '3': 5, '4': 1, '5': 9, '10': 'recentChanges'},
    {
      '1': 'autoTranslation',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.TranslatedText',
      '10': 'autoTranslation'
    },
    {'1': 'offer', '3': 7, '4': 3, '5': 11, '6': '.Offer', '10': 'offer'},
    {'1': 'channelId', '3': 9, '4': 1, '5': 3, '10': 'channelId'},
    {'1': 'child', '3': 10, '4': 3, '5': 11, '6': '.Document', '10': 'child'},
    {
      '1': 'decoration',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.Document',
      '10': 'decoration'
    },
    {'1': 'image', '3': 12, '4': 3, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'categoryId', '3': 13, '4': 3, '5': 9, '10': 'categoryId'},
    {'1': 'subtitle', '3': 14, '4': 1, '5': 9, '10': 'subtitle'},
  ],
};

/// Descriptor for `DocumentVariant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentVariantDescriptor = $convert.base64Decode(
    'Cg9Eb2N1bWVudFZhcmlhbnQSJAoNdmFyaWF0aW9uVHlwZRgBIAEoBVINdmFyaWF0aW9uVHlwZR'
    'IZCgRydWxlGAIgASgLMgUuUnVsZVIEcnVsZRIUCgV0aXRsZRgDIAEoCVIFdGl0bGUSGAoHc25p'
    'cHBldBgEIAMoCVIHc25pcHBldBIkCg1yZWNlbnRDaGFuZ2VzGAUgASgJUg1yZWNlbnRDaGFuZ2'
    'VzEjkKD2F1dG9UcmFuc2xhdGlvbhgGIAMoCzIPLlRyYW5zbGF0ZWRUZXh0Ug9hdXRvVHJhbnNs'
    'YXRpb24SHAoFb2ZmZXIYByADKAsyBi5PZmZlclIFb2ZmZXISHAoJY2hhbm5lbElkGAkgASgDUg'
    'ljaGFubmVsSWQSHwoFY2hpbGQYCiADKAsyCS5Eb2N1bWVudFIFY2hpbGQSKQoKZGVjb3JhdGlv'
    'bhgLIAMoCzIJLkRvY3VtZW50UgpkZWNvcmF0aW9uEhwKBWltYWdlGAwgAygLMgYuSW1hZ2VSBW'
    'ltYWdlEh4KCmNhdGVnb3J5SWQYDSADKAlSCmNhdGVnb3J5SWQSGgoIc3VidGl0bGUYDiABKAlS'
    'CHN1YnRpdGxl');

@$core.Deprecated('Use sectionImageDescriptor instead')
const SectionImage$json = {
  '1': 'SectionImage',
  '2': [
    {
      '1': 'imageContainer',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ImageContainer',
      '10': 'imageContainer'
    },
  ],
};

/// Descriptor for `SectionImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionImageDescriptor = $convert.base64Decode(
    'CgxTZWN0aW9uSW1hZ2USNwoOaW1hZ2VDb250YWluZXIYASADKAsyDy5JbWFnZUNvbnRhaW5lcl'
    'IOaW1hZ2VDb250YWluZXI=');

@$core.Deprecated('Use imageContainerDescriptor instead')
const ImageContainer$json = {
  '1': 'ImageContainer',
  '2': [
    {'1': 'image', '3': 4, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
  ],
};

/// Descriptor for `ImageContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageContainerDescriptor = $convert.base64Decode(
    'Cg5JbWFnZUNvbnRhaW5lchIcCgVpbWFnZRgEIAEoCzIGLkltYWdlUgVpbWFnZQ==');

@$core.Deprecated('Use imageDescriptor instead')
const Image$json = {
  '1': 'Image',
  '2': [
    {'1': 'imageType', '3': 1, '4': 1, '5': 5, '10': 'imageType'},
    {
      '1': 'dimension',
      '3': 2,
      '4': 1,
      '5': 10,
      '6': '.Image.Dimension',
      '10': 'dimension'
    },
    {'1': 'imageUrl', '3': 5, '4': 1, '5': 9, '10': 'imageUrl'},
    {'1': 'altTextLocalized', '3': 6, '4': 1, '5': 9, '10': 'altTextLocalized'},
    {'1': 'secureUrl', '3': 7, '4': 1, '5': 9, '10': 'secureUrl'},
    {
      '1': 'positionInSequence',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'positionInSequence'
    },
    {
      '1': 'supportsFifeUrlOptions',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'supportsFifeUrlOptions'
    },
    {
      '1': 'citation',
      '3': 10,
      '4': 1,
      '5': 10,
      '6': '.Image.Citation',
      '10': 'citation'
    },
    {'1': 'durationSeconds', '3': 14, '4': 1, '5': 5, '10': 'durationSeconds'},
    {'1': 'fillColorRGB', '3': 15, '4': 1, '5': 9, '10': 'fillColorRGB'},
    {'1': 'autogen', '3': 16, '4': 1, '5': 8, '10': 'autogen'},
    {
      '1': 'attribution',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.Attribution',
      '10': 'attribution'
    },
    {
      '1': 'backgroundColorRgb',
      '3': 19,
      '4': 1,
      '5': 9,
      '10': 'backgroundColorRgb'
    },
    {
      '1': 'palette',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.ImagePalette',
      '10': 'palette'
    },
    {'1': 'deviceClass', '3': 21, '4': 1, '5': 5, '10': 'deviceClass'},
    {
      '1': 'supportsFifeMonogramOption',
      '3': 22,
      '4': 1,
      '5': 8,
      '10': 'supportsFifeMonogramOption'
    },
    {'1': 'imageUrlAlt', '3': 28, '4': 1, '5': 9, '10': 'imageUrlAlt'},
  ],
  '3': [Image_Dimension$json, Image_Citation$json],
};

@$core.Deprecated('Use imageDescriptor instead')
const Image_Dimension$json = {
  '1': 'Dimension',
  '2': [
    {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
    {'1': 'aspectRatio', '3': 18, '4': 1, '5': 5, '10': 'aspectRatio'},
  ],
};

@$core.Deprecated('Use imageDescriptor instead')
const Image_Citation$json = {
  '1': 'Citation',
  '2': [
    {'1': 'titleLocalized', '3': 11, '4': 1, '5': 9, '10': 'titleLocalized'},
    {'1': 'url', '3': 12, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `Image`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imageDescriptor = $convert.base64Decode(
    'CgVJbWFnZRIcCglpbWFnZVR5cGUYASABKAVSCWltYWdlVHlwZRIuCglkaW1lbnNpb24YAiABKA'
    'oyEC5JbWFnZS5EaW1lbnNpb25SCWRpbWVuc2lvbhIaCghpbWFnZVVybBgFIAEoCVIIaW1hZ2VV'
    'cmwSKgoQYWx0VGV4dExvY2FsaXplZBgGIAEoCVIQYWx0VGV4dExvY2FsaXplZBIcCglzZWN1cm'
    'VVcmwYByABKAlSCXNlY3VyZVVybBIuChJwb3NpdGlvbkluU2VxdWVuY2UYCCABKAVSEnBvc2l0'
    'aW9uSW5TZXF1ZW5jZRI2ChZzdXBwb3J0c0ZpZmVVcmxPcHRpb25zGAkgASgIUhZzdXBwb3J0c0'
    'ZpZmVVcmxPcHRpb25zEisKCGNpdGF0aW9uGAogASgKMg8uSW1hZ2UuQ2l0YXRpb25SCGNpdGF0'
    'aW9uEigKD2R1cmF0aW9uU2Vjb25kcxgOIAEoBVIPZHVyYXRpb25TZWNvbmRzEiIKDGZpbGxDb2'
    'xvclJHQhgPIAEoCVIMZmlsbENvbG9yUkdCEhgKB2F1dG9nZW4YECABKAhSB2F1dG9nZW4SLgoL'
    'YXR0cmlidXRpb24YESABKAsyDC5BdHRyaWJ1dGlvblILYXR0cmlidXRpb24SLgoSYmFja2dyb3'
    'VuZENvbG9yUmdiGBMgASgJUhJiYWNrZ3JvdW5kQ29sb3JSZ2ISJwoHcGFsZXR0ZRgUIAEoCzIN'
    'LkltYWdlUGFsZXR0ZVIHcGFsZXR0ZRIgCgtkZXZpY2VDbGFzcxgVIAEoBVILZGV2aWNlQ2xhc3'
    'MSPgoac3VwcG9ydHNGaWZlTW9ub2dyYW1PcHRpb24YFiABKAhSGnN1cHBvcnRzRmlmZU1vbm9n'
    'cmFtT3B0aW9uEiAKC2ltYWdlVXJsQWx0GBwgASgJUgtpbWFnZVVybEFsdBpbCglEaW1lbnNpb2'
    '4SFAoFd2lkdGgYAyABKAVSBXdpZHRoEhYKBmhlaWdodBgEIAEoBVIGaGVpZ2h0EiAKC2FzcGVj'
    'dFJhdGlvGBIgASgFUgthc3BlY3RSYXRpbxpECghDaXRhdGlvbhImCg50aXRsZUxvY2FsaXplZB'
    'gLIAEoCVIOdGl0bGVMb2NhbGl6ZWQSEAoDdXJsGAwgASgJUgN1cmw=');

@$core.Deprecated('Use attributionDescriptor instead')
const Attribution$json = {
  '1': 'Attribution',
  '2': [
    {'1': 'sourceTitle', '3': 1, '4': 1, '5': 9, '10': 'sourceTitle'},
    {'1': 'sourceUrl', '3': 2, '4': 1, '5': 9, '10': 'sourceUrl'},
    {'1': 'licenseTitle', '3': 3, '4': 1, '5': 9, '10': 'licenseTitle'},
    {'1': 'licenseUrl', '3': 4, '4': 1, '5': 9, '10': 'licenseUrl'},
  ],
};

/// Descriptor for `Attribution`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attributionDescriptor = $convert.base64Decode(
    'CgtBdHRyaWJ1dGlvbhIgCgtzb3VyY2VUaXRsZRgBIAEoCVILc291cmNlVGl0bGUSHAoJc291cm'
    'NlVXJsGAIgASgJUglzb3VyY2VVcmwSIgoMbGljZW5zZVRpdGxlGAMgASgJUgxsaWNlbnNlVGl0'
    'bGUSHgoKbGljZW5zZVVybBgEIAEoCVIKbGljZW5zZVVybA==');

@$core.Deprecated('Use imagePaletteDescriptor instead')
const ImagePalette$json = {
  '1': 'ImagePalette',
  '2': [
    {'1': 'lightVibrantRGB', '3': 1, '4': 1, '5': 9, '10': 'lightVibrantRGB'},
    {'1': 'vibrantRGB', '3': 2, '4': 1, '5': 9, '10': 'vibrantRGB'},
    {'1': 'darkVibrantRGB', '3': 3, '4': 1, '5': 9, '10': 'darkVibrantRGB'},
    {'1': 'lightMutedRGB', '3': 4, '4': 1, '5': 9, '10': 'lightMutedRGB'},
    {'1': 'mutedRGB', '3': 5, '4': 1, '5': 9, '10': 'mutedRGB'},
    {'1': 'darkMutedRGB', '3': 6, '4': 1, '5': 9, '10': 'darkMutedRGB'},
  ],
};

/// Descriptor for `ImagePalette`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List imagePaletteDescriptor = $convert.base64Decode(
    'CgxJbWFnZVBhbGV0dGUSKAoPbGlnaHRWaWJyYW50UkdCGAEgASgJUg9saWdodFZpYnJhbnRSR0'
    'ISHgoKdmlicmFudFJHQhgCIAEoCVIKdmlicmFudFJHQhImCg5kYXJrVmlicmFudFJHQhgDIAEo'
    'CVIOZGFya1ZpYnJhbnRSR0ISJAoNbGlnaHRNdXRlZFJHQhgEIAEoCVINbGlnaHRNdXRlZFJHQh'
    'IaCghtdXRlZFJHQhgFIAEoCVIIbXV0ZWRSR0ISIgoMZGFya011dGVkUkdCGAYgASgJUgxkYXJr'
    'TXV0ZWRSR0I=');

@$core.Deprecated('Use translatedTextDescriptor instead')
const TranslatedText$json = {
  '1': 'TranslatedText',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
    {'1': 'sourceLocale', '3': 2, '4': 1, '5': 9, '10': 'sourceLocale'},
    {'1': 'targetLocale', '3': 3, '4': 1, '5': 9, '10': 'targetLocale'},
  ],
};

/// Descriptor for `TranslatedText`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List translatedTextDescriptor = $convert.base64Decode(
    'Cg5UcmFuc2xhdGVkVGV4dBISCgR0ZXh0GAEgASgJUgR0ZXh0EiIKDHNvdXJjZUxvY2FsZRgCIA'
    'EoCVIMc291cmNlTG9jYWxlEiIKDHRhcmdldExvY2FsZRgDIAEoCVIMdGFyZ2V0TG9jYWxl');

@$core.Deprecated('Use plusOneDataDescriptor instead')
const PlusOneData$json = {
  '1': 'PlusOneData',
  '2': [
    {'1': 'setByUser', '3': 1, '4': 1, '5': 8, '10': 'setByUser'},
    {'1': 'total', '3': 2, '4': 1, '5': 3, '10': 'total'},
    {'1': 'circlesTotal', '3': 3, '4': 1, '5': 3, '10': 'circlesTotal'},
    {
      '1': 'circlesPeople',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.PlusPerson',
      '10': 'circlesPeople'
    },
  ],
};

/// Descriptor for `PlusOneData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List plusOneDataDescriptor = $convert.base64Decode(
    'CgtQbHVzT25lRGF0YRIcCglzZXRCeVVzZXIYASABKAhSCXNldEJ5VXNlchIUCgV0b3RhbBgCIA'
    'EoA1IFdG90YWwSIgoMY2lyY2xlc1RvdGFsGAMgASgDUgxjaXJjbGVzVG90YWwSMQoNY2lyY2xl'
    'c1Blb3BsZRgEIAMoCzILLlBsdXNQZXJzb25SDWNpcmNsZXNQZW9wbGU=');

@$core.Deprecated('Use plusPersonDescriptor instead')
const PlusPerson$json = {
  '1': 'PlusPerson',
  '2': [
    {'1': 'displayName', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'profileImageUrl', '3': 4, '4': 1, '5': 9, '10': 'profileImageUrl'},
  ],
};

/// Descriptor for `PlusPerson`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List plusPersonDescriptor = $convert.base64Decode(
    'CgpQbHVzUGVyc29uEiAKC2Rpc3BsYXlOYW1lGAIgASgJUgtkaXNwbGF5TmFtZRIoCg9wcm9maW'
    'xlSW1hZ2VVcmwYBCABKAlSD3Byb2ZpbGVJbWFnZVVybA==');

@$core.Deprecated('Use appDetailsDescriptor instead')
const AppDetails$json = {
  '1': 'AppDetails',
  '2': [
    {'1': 'developerName', '3': 1, '4': 1, '5': 9, '10': 'developerName'},
    {
      '1': 'majorVersionNumber',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'majorVersionNumber'
    },
    {'1': 'versionCode', '3': 3, '4': 1, '5': 3, '10': 'versionCode'},
    {'1': 'versionString', '3': 4, '4': 1, '5': 9, '10': 'versionString'},
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
    {'1': 'appCategory', '3': 7, '4': 3, '5': 9, '10': 'appCategory'},
    {'1': 'contentRating', '3': 8, '4': 1, '5': 5, '10': 'contentRating'},
    {'1': 'infoDownloadSize', '3': 9, '4': 1, '5': 3, '10': 'infoDownloadSize'},
    {'1': 'permission', '3': 10, '4': 3, '5': 9, '10': 'permission'},
    {'1': 'developerEmail', '3': 11, '4': 1, '5': 9, '10': 'developerEmail'},
    {
      '1': 'developerWebsite',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'developerWebsite'
    },
    {'1': 'infoDownload', '3': 13, '4': 1, '5': 9, '10': 'infoDownload'},
    {'1': 'packageName', '3': 14, '4': 1, '5': 9, '10': 'packageName'},
    {
      '1': 'recentChangesHtml',
      '3': 15,
      '4': 1,
      '5': 9,
      '10': 'recentChangesHtml'
    },
    {'1': 'infoUpdatedOn', '3': 16, '4': 1, '5': 9, '10': 'infoUpdatedOn'},
    {'1': 'file', '3': 17, '4': 3, '5': 11, '6': '.FileMetadata', '10': 'file'},
    {'1': 'appType', '3': 18, '4': 1, '5': 9, '10': 'appType'},
    {'1': 'certificateHash', '3': 19, '4': 3, '5': 9, '10': 'certificateHash'},
    {
      '1': 'variesWithDevice',
      '3': 21,
      '4': 1,
      '5': 8,
      '7': 'true',
      '10': 'variesWithDevice'
    },
    {
      '1': 'certificateSet',
      '3': 22,
      '4': 3,
      '5': 11,
      '6': '.CertificateSet',
      '10': 'certificateSet'
    },
    {
      '1': 'autoAcquireFreeAppIfHigherVersionAvailableTag',
      '3': 23,
      '4': 3,
      '5': 9,
      '10': 'autoAcquireFreeAppIfHigherVersionAvailableTag'
    },
    {'1': 'hasInstantLink', '3': 24, '4': 1, '5': 8, '10': 'hasInstantLink'},
    {'1': 'splitId', '3': 25, '4': 3, '5': 9, '10': 'splitId'},
    {'1': 'gamepadRequired', '3': 26, '4': 1, '5': 8, '10': 'gamepadRequired'},
    {
      '1': 'externallyHosted',
      '3': 27,
      '4': 1,
      '5': 8,
      '10': 'externallyHosted'
    },
    {
      '1': 'everExternallyHosted',
      '3': 28,
      '4': 1,
      '5': 8,
      '10': 'everExternallyHosted'
    },
    {'1': 'installNotes', '3': 30, '4': 1, '5': 9, '10': 'installNotes'},
    {'1': 'installLocation', '3': 31, '4': 1, '5': 5, '10': 'installLocation'},
    {
      '1': 'targetSdkVersion',
      '3': 32,
      '4': 1,
      '5': 5,
      '10': 'targetSdkVersion'
    },
    {
      '1': 'hasPreregistrationPromoCode',
      '3': 33,
      '4': 1,
      '5': 9,
      '10': 'hasPreregistrationPromoCode'
    },
    {
      '1': 'dependencies',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.Dependencies',
      '10': 'dependencies'
    },
    {
      '1': 'testingProgramInfo',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.TestingProgramInfo',
      '10': 'testingProgramInfo'
    },
    {
      '1': 'earlyAccessInfo',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.EarlyAccessInfo',
      '10': 'earlyAccessInfo'
    },
    {
      '1': 'editorChoice',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.EditorChoice',
      '10': 'editorChoice'
    },
    {'1': 'instantLink', '3': 43, '4': 1, '5': 9, '10': 'instantLink'},
    {
      '1': 'developerAddress',
      '3': 45,
      '4': 1,
      '5': 9,
      '10': 'developerAddress'
    },
    {
      '1': 'publisher',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.Publisher',
      '10': 'publisher'
    },
    {'1': 'categoryName', '3': 48, '4': 1, '5': 9, '10': 'categoryName'},
    {'1': 'downloadCount', '3': 53, '4': 1, '5': 3, '10': 'downloadCount'},
    {
      '1': 'downloadLabelDisplay',
      '3': 61,
      '4': 1,
      '5': 9,
      '10': 'downloadLabelDisplay'
    },
    {
      '1': 'appLaunch',
      '3': 64,
      '4': 1,
      '5': 11,
      '6': '.AppLaunch',
      '10': 'appLaunch'
    },
    {
      '1': 'tagGroup',
      '3': 66,
      '4': 1,
      '5': 11,
      '6': '.TagGroup',
      '10': 'tagGroup'
    },
    {'1': 'inAppProduct', '3': 67, '4': 1, '5': 9, '10': 'inAppProduct'},
    {
      '1': 'downloadLabelAbbreviated',
      '3': 77,
      '4': 1,
      '5': 9,
      '10': 'downloadLabelAbbreviated'
    },
    {'1': 'downloadLabel', '3': 78, '4': 1, '5': 9, '10': 'downloadLabel'},
    {
      '1': 'compatibility',
      '3': 82,
      '4': 1,
      '5': 11,
      '6': '.Compatibility',
      '10': 'compatibility'
    },
    {
      '1': 'support',
      '3': 86,
      '4': 1,
      '5': 11,
      '6': '.Support',
      '10': 'support'
    },
  ],
};

/// Descriptor for `AppDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appDetailsDescriptor = $convert.base64Decode(
    'CgpBcHBEZXRhaWxzEiQKDWRldmVsb3Blck5hbWUYASABKAlSDWRldmVsb3Blck5hbWUSLgoSbW'
    'Fqb3JWZXJzaW9uTnVtYmVyGAIgASgFUhJtYWpvclZlcnNpb25OdW1iZXISIAoLdmVyc2lvbkNv'
    'ZGUYAyABKANSC3ZlcnNpb25Db2RlEiQKDXZlcnNpb25TdHJpbmcYBCABKAlSDXZlcnNpb25TdH'
    'JpbmcSFAoFdGl0bGUYBSABKAlSBXRpdGxlEiAKC2FwcENhdGVnb3J5GAcgAygJUgthcHBDYXRl'
    'Z29yeRIkCg1jb250ZW50UmF0aW5nGAggASgFUg1jb250ZW50UmF0aW5nEioKEGluZm9Eb3dubG'
    '9hZFNpemUYCSABKANSEGluZm9Eb3dubG9hZFNpemUSHgoKcGVybWlzc2lvbhgKIAMoCVIKcGVy'
    'bWlzc2lvbhImCg5kZXZlbG9wZXJFbWFpbBgLIAEoCVIOZGV2ZWxvcGVyRW1haWwSKgoQZGV2ZW'
    'xvcGVyV2Vic2l0ZRgMIAEoCVIQZGV2ZWxvcGVyV2Vic2l0ZRIiCgxpbmZvRG93bmxvYWQYDSAB'
    'KAlSDGluZm9Eb3dubG9hZBIgCgtwYWNrYWdlTmFtZRgOIAEoCVILcGFja2FnZU5hbWUSLAoRcm'
    'VjZW50Q2hhbmdlc0h0bWwYDyABKAlSEXJlY2VudENoYW5nZXNIdG1sEiQKDWluZm9VcGRhdGVk'
    'T24YECABKAlSDWluZm9VcGRhdGVkT24SIQoEZmlsZRgRIAMoCzINLkZpbGVNZXRhZGF0YVIEZm'
    'lsZRIYCgdhcHBUeXBlGBIgASgJUgdhcHBUeXBlEigKD2NlcnRpZmljYXRlSGFzaBgTIAMoCVIP'
    'Y2VydGlmaWNhdGVIYXNoEjAKEHZhcmllc1dpdGhEZXZpY2UYFSABKAg6BHRydWVSEHZhcmllc1'
    'dpdGhEZXZpY2USNwoOY2VydGlmaWNhdGVTZXQYFiADKAsyDy5DZXJ0aWZpY2F0ZVNldFIOY2Vy'
    'dGlmaWNhdGVTZXQSZAotYXV0b0FjcXVpcmVGcmVlQXBwSWZIaWdoZXJWZXJzaW9uQXZhaWxhYm'
    'xlVGFnGBcgAygJUi1hdXRvQWNxdWlyZUZyZWVBcHBJZkhpZ2hlclZlcnNpb25BdmFpbGFibGVU'
    'YWcSJgoOaGFzSW5zdGFudExpbmsYGCABKAhSDmhhc0luc3RhbnRMaW5rEhgKB3NwbGl0SWQYGS'
    'ADKAlSB3NwbGl0SWQSKAoPZ2FtZXBhZFJlcXVpcmVkGBogASgIUg9nYW1lcGFkUmVxdWlyZWQS'
    'KgoQZXh0ZXJuYWxseUhvc3RlZBgbIAEoCFIQZXh0ZXJuYWxseUhvc3RlZBIyChRldmVyRXh0ZX'
    'JuYWxseUhvc3RlZBgcIAEoCFIUZXZlckV4dGVybmFsbHlIb3N0ZWQSIgoMaW5zdGFsbE5vdGVz'
    'GB4gASgJUgxpbnN0YWxsTm90ZXMSKAoPaW5zdGFsbExvY2F0aW9uGB8gASgFUg9pbnN0YWxsTG'
    '9jYXRpb24SKgoQdGFyZ2V0U2RrVmVyc2lvbhggIAEoBVIQdGFyZ2V0U2RrVmVyc2lvbhJAChto'
    'YXNQcmVyZWdpc3RyYXRpb25Qcm9tb0NvZGUYISABKAlSG2hhc1ByZXJlZ2lzdHJhdGlvblByb2'
    '1vQ29kZRIxCgxkZXBlbmRlbmNpZXMYIiABKAsyDS5EZXBlbmRlbmNpZXNSDGRlcGVuZGVuY2ll'
    'cxJDChJ0ZXN0aW5nUHJvZ3JhbUluZm8YIyABKAsyEy5UZXN0aW5nUHJvZ3JhbUluZm9SEnRlc3'
    'RpbmdQcm9ncmFtSW5mbxI6Cg9lYXJseUFjY2Vzc0luZm8YJCABKAsyEC5FYXJseUFjY2Vzc0lu'
    'Zm9SD2Vhcmx5QWNjZXNzSW5mbxIxCgxlZGl0b3JDaG9pY2UYKSABKAsyDS5FZGl0b3JDaG9pY2'
    'VSDGVkaXRvckNob2ljZRIgCgtpbnN0YW50TGluaxgrIAEoCVILaW5zdGFudExpbmsSKgoQZGV2'
    'ZWxvcGVyQWRkcmVzcxgtIAEoCVIQZGV2ZWxvcGVyQWRkcmVzcxIoCglwdWJsaXNoZXIYLiABKA'
    'syCi5QdWJsaXNoZXJSCXB1Ymxpc2hlchIiCgxjYXRlZ29yeU5hbWUYMCABKAlSDGNhdGVnb3J5'
    'TmFtZRIkCg1kb3dubG9hZENvdW50GDUgASgDUg1kb3dubG9hZENvdW50EjIKFGRvd25sb2FkTG'
    'FiZWxEaXNwbGF5GD0gASgJUhRkb3dubG9hZExhYmVsRGlzcGxheRIoCglhcHBMYXVuY2gYQCAB'
    'KAsyCi5BcHBMYXVuY2hSCWFwcExhdW5jaBIlCgh0YWdHcm91cBhCIAEoCzIJLlRhZ0dyb3VwUg'
    'h0YWdHcm91cBIiCgxpbkFwcFByb2R1Y3QYQyABKAlSDGluQXBwUHJvZHVjdBI6Chhkb3dubG9h'
    'ZExhYmVsQWJicmV2aWF0ZWQYTSABKAlSGGRvd25sb2FkTGFiZWxBYmJyZXZpYXRlZBIkCg1kb3'
    'dubG9hZExhYmVsGE4gASgJUg1kb3dubG9hZExhYmVsEjQKDWNvbXBhdGliaWxpdHkYUiABKAsy'
    'Di5Db21wYXRpYmlsaXR5Ug1jb21wYXRpYmlsaXR5EiIKB3N1cHBvcnQYViABKAsyCC5TdXBwb3'
    'J0UgdzdXBwb3J0');

@$core.Deprecated('Use appLaunchDescriptor instead')
const AppLaunch$json = {
  '1': 'AppLaunch',
  '2': [
    {'1': 'date', '3': 1, '4': 1, '5': 9, '10': 'date'},
    {
      '1': 'time',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.AppLaunch.Time',
      '10': 'time'
    },
  ],
  '3': [AppLaunch_Time$json],
};

@$core.Deprecated('Use appLaunchDescriptor instead')
const AppLaunch_Time$json = {
  '1': 'Time',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'unknown', '3': 2, '4': 1, '5': 3, '10': 'unknown'},
  ],
};

/// Descriptor for `AppLaunch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appLaunchDescriptor = $convert.base64Decode(
    'CglBcHBMYXVuY2gSEgoEZGF0ZRgBIAEoCVIEZGF0ZRIjCgR0aW1lGAIgASgLMg8uQXBwTGF1bm'
    'NoLlRpbWVSBHRpbWUaPgoEVGltZRIcCgl0aW1lc3RhbXAYASABKANSCXRpbWVzdGFtcBIYCgd1'
    'bmtub3duGAIgASgDUgd1bmtub3du');

@$core.Deprecated('Use tagGroupDescriptor instead')
const TagGroup$json = {
  '1': 'TagGroup',
  '2': [
    {'1': 'type1', '3': 1, '4': 1, '5': 11, '6': '.TagType', '10': 'type1'},
    {'1': 'type2', '3': 2, '4': 1, '5': 11, '6': '.TagType', '10': 'type2'},
    {'1': 'type3', '3': 3, '4': 1, '5': 11, '6': '.TagType', '10': 'type3'},
    {'1': 'type4', '3': 4, '4': 1, '5': 11, '6': '.TagType', '10': 'type4'},
    {'1': 'type5', '3': 5, '4': 1, '5': 11, '6': '.TagType', '10': 'type5'},
    {'1': 'type6', '3': 6, '4': 1, '5': 11, '6': '.TagType', '10': 'type6'},
  ],
};

/// Descriptor for `TagGroup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagGroupDescriptor = $convert.base64Decode(
    'CghUYWdHcm91cBIeCgV0eXBlMRgBIAEoCzIILlRhZ1R5cGVSBXR5cGUxEh4KBXR5cGUyGAIgAS'
    'gLMgguVGFnVHlwZVIFdHlwZTISHgoFdHlwZTMYAyABKAsyCC5UYWdUeXBlUgV0eXBlMxIeCgV0'
    'eXBlNBgEIAEoCzIILlRhZ1R5cGVSBXR5cGU0Eh4KBXR5cGU1GAUgASgLMgguVGFnVHlwZVIFdH'
    'lwZTUSHgoFdHlwZTYYBiABKAsyCC5UYWdUeXBlUgV0eXBlNg==');

@$core.Deprecated('Use tagTypeDescriptor instead')
const TagType$json = {
  '1': 'TagType',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.TagEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `TagType`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagTypeDescriptor = $convert.base64Decode(
    'CgdUYWdUeXBlEiMKB2VudHJpZXMYASADKAsyCS5UYWdFbnRyeVIHZW50cmllcw==');

@$core.Deprecated('Use tagEntryDescriptor instead')
const TagEntry$json = {
  '1': 'TagEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'metadata',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.TagMetadata',
      '10': 'metadata'
    },
    {'1': 'category', '3': 3, '4': 1, '5': 9, '10': 'category'},
  ],
};

/// Descriptor for `TagEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagEntryDescriptor = $convert.base64Decode(
    'CghUYWdFbnRyeRISCgRuYW1lGAEgASgJUgRuYW1lEigKCG1ldGFkYXRhGAIgASgLMgwuVGFnTW'
    'V0YWRhdGFSCG1ldGFkYXRhEhoKCGNhdGVnb3J5GAMgASgJUghjYXRlZ29yeQ==');

@$core.Deprecated('Use tagMetadataDescriptor instead')
const TagMetadata$json = {
  '1': 'TagMetadata',
  '2': [
    {
      '1': 'category',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.TagData',
      '9': 0,
      '10': 'category'
    },
    {
      '1': 'search',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.TagData',
      '9': 0,
      '10': 'search'
    },
  ],
  '8': [
    {'1': 'metadata'},
  ],
};

/// Descriptor for `TagMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagMetadataDescriptor = $convert.base64Decode(
    'CgtUYWdNZXRhZGF0YRImCghjYXRlZ29yeRgDIAEoCzIILlRhZ0RhdGFIAFIIY2F0ZWdvcnkSIg'
    'oGc2VhcmNoGAQgASgLMgguVGFnRGF0YUgAUgZzZWFyY2hCCgoIbWV0YWRhdGE=');

@$core.Deprecated('Use tagDataDescriptor instead')
const TagData$json = {
  '1': 'TagData',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `TagData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tagDataDescriptor = $convert.base64Decode(
    'CgdUYWdEYXRhEhAKA3VybBgBIAEoCVIDdXJsEhQKBWxhYmVsGAIgASgJUgVsYWJlbA==');

@$core.Deprecated('Use supportDescriptor instead')
const Support$json = {
  '1': 'Support',
  '2': [
    {'1': 'developerName', '3': 1, '4': 1, '5': 9, '10': 'developerName'},
    {'1': 'developerEmail', '3': 2, '4': 1, '5': 9, '10': 'developerEmail'},
    {'1': 'developerAddress', '3': 3, '4': 1, '5': 9, '10': 'developerAddress'},
    {
      '1': 'developerPhoneNumber',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'developerPhoneNumber'
    },
  ],
};

/// Descriptor for `Support`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List supportDescriptor = $convert.base64Decode(
    'CgdTdXBwb3J0EiQKDWRldmVsb3Blck5hbWUYASABKAlSDWRldmVsb3Blck5hbWUSJgoOZGV2ZW'
    'xvcGVyRW1haWwYAiABKAlSDmRldmVsb3BlckVtYWlsEioKEGRldmVsb3BlckFkZHJlc3MYAyAB'
    'KAlSEGRldmVsb3BlckFkZHJlc3MSMgoUZGV2ZWxvcGVyUGhvbmVOdW1iZXIYBCABKAlSFGRldm'
    'Vsb3BlclBob25lTnVtYmVy');

@$core.Deprecated('Use compatibilityDescriptor instead')
const Compatibility$json = {
  '1': 'Compatibility',
  '2': [
    {
      '1': 'activeDevices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ActiveDevice',
      '10': 'activeDevices'
    },
  ],
};

/// Descriptor for `Compatibility`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compatibilityDescriptor = $convert.base64Decode(
    'Cg1Db21wYXRpYmlsaXR5EjMKDWFjdGl2ZURldmljZXMYASADKAsyDS5BY3RpdmVEZXZpY2VSDW'
    'FjdGl2ZURldmljZXM=');

@$core.Deprecated('Use activeDeviceDescriptor instead')
const ActiveDevice$json = {
  '1': 'ActiveDevice',
  '2': [
    {'1': 'requiredOS', '3': 1, '4': 1, '5': 9, '10': 'requiredOS'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `ActiveDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeDeviceDescriptor = $convert.base64Decode(
    'CgxBY3RpdmVEZXZpY2USHgoKcmVxdWlyZWRPUxgBIAEoCVIKcmVxdWlyZWRPUxISCgRuYW1lGA'
    'IgASgJUgRuYW1l');

@$core.Deprecated('Use modifyLibraryDescriptor instead')
const ModifyLibrary$json = {
  '1': 'ModifyLibrary',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'packageToAdd', '3': 2, '4': 1, '5': 9, '10': 'packageToAdd'},
    {'1': 'packageToRemove', '3': 3, '4': 1, '5': 9, '10': 'packageToRemove'},
  ],
};

/// Descriptor for `ModifyLibrary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modifyLibraryDescriptor = $convert.base64Decode(
    'Cg1Nb2RpZnlMaWJyYXJ5Eg4KAmlkGAEgASgJUgJpZBIiCgxwYWNrYWdlVG9BZGQYAiABKAlSDH'
    'BhY2thZ2VUb0FkZBIoCg9wYWNrYWdlVG9SZW1vdmUYAyABKAlSD3BhY2thZ2VUb1JlbW92ZQ==');

@$core.Deprecated('Use publisherDescriptor instead')
const Publisher$json = {
  '1': 'Publisher',
  '2': [
    {
      '1': 'publisherStream',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.PublisherStream',
      '10': 'publisherStream'
    },
  ],
};

/// Descriptor for `Publisher`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publisherDescriptor = $convert.base64Decode(
    'CglQdWJsaXNoZXISOgoPcHVibGlzaGVyU3RyZWFtGAIgASgLMhAuUHVibGlzaGVyU3RyZWFtUg'
    '9wdWJsaXNoZXJTdHJlYW0=');

@$core.Deprecated('Use publisherStreamDescriptor instead')
const PublisherStream$json = {
  '1': 'PublisherStream',
  '2': [
    {'1': 'moreUrl', '3': 3, '4': 1, '5': 9, '10': 'moreUrl'},
    {'1': 'query', '3': 11, '4': 1, '5': 9, '10': 'query'},
    {'1': 'browseUrl', '3': 83, '4': 1, '5': 9, '10': 'browseUrl'},
  ],
};

/// Descriptor for `PublisherStream`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publisherStreamDescriptor = $convert.base64Decode(
    'Cg9QdWJsaXNoZXJTdHJlYW0SGAoHbW9yZVVybBgDIAEoCVIHbW9yZVVybBIUCgVxdWVyeRgLIA'
    'EoCVIFcXVlcnkSHAoJYnJvd3NlVXJsGFMgASgJUglicm93c2VVcmw=');

@$core.Deprecated('Use editorChoiceDescriptor instead')
const EditorChoice$json = {
  '1': 'EditorChoice',
  '2': [
    {'1': 'bulletins', '3': 1, '4': 3, '5': 9, '10': 'bulletins'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'stream', '3': 3, '4': 1, '5': 11, '6': '.SubStream', '10': 'stream'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 5, '4': 1, '5': 9, '10': 'subtitle'},
  ],
};

/// Descriptor for `EditorChoice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editorChoiceDescriptor = $convert.base64Decode(
    'CgxFZGl0b3JDaG9pY2USHAoJYnVsbGV0aW5zGAEgAygJUglidWxsZXRpbnMSIAoLZGVzY3JpcH'
    'Rpb24YAiABKAlSC2Rlc2NyaXB0aW9uEiIKBnN0cmVhbRgDIAEoCzIKLlN1YlN0cmVhbVIGc3Ry'
    'ZWFtEhQKBXRpdGxlGAQgASgJUgV0aXRsZRIaCghzdWJ0aXRsZRgFIAEoCVIIc3VidGl0bGU=');

@$core.Deprecated('Use certificateSetDescriptor instead')
const CertificateSet$json = {
  '1': 'CertificateSet',
  '2': [
    {'1': 'certificateHash', '3': 1, '4': 1, '5': 9, '10': 'certificateHash'},
    {'1': 'sha256', '3': 2, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `CertificateSet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List certificateSetDescriptor = $convert.base64Decode(
    'Cg5DZXJ0aWZpY2F0ZVNldBIoCg9jZXJ0aWZpY2F0ZUhhc2gYASABKAlSD2NlcnRpZmljYXRlSG'
    'FzaBIWCgZzaGEyNTYYAiABKAlSBnNoYTI1Ng==');

@$core.Deprecated('Use dependenciesDescriptor instead')
const Dependencies$json = {
  '1': 'Dependencies',
  '2': [
    {'1': 'unknown', '3': 1, '4': 1, '5': 5, '10': 'unknown'},
    {'1': 'size', '3': 2, '4': 1, '5': 3, '10': 'size'},
    {
      '1': 'dependency',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.Dependency',
      '10': 'dependency'
    },
    {'1': 'targetSdk', '3': 4, '4': 1, '5': 5, '10': 'targetSdk'},
    {'1': 'unknown2', '3': 5, '4': 1, '5': 5, '10': 'unknown2'},
    {'1': 'splitApks', '3': 11, '4': 3, '5': 9, '10': 'splitApks'},
    {
      '1': 'libraryDependency',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.LibraryDependency',
      '10': 'libraryDependency'
    },
  ],
};

/// Descriptor for `Dependencies`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dependenciesDescriptor = $convert.base64Decode(
    'CgxEZXBlbmRlbmNpZXMSGAoHdW5rbm93bhgBIAEoBVIHdW5rbm93bhISCgRzaXplGAIgASgDUg'
    'RzaXplEisKCmRlcGVuZGVuY3kYAyADKAsyCy5EZXBlbmRlbmN5UgpkZXBlbmRlbmN5EhwKCXRh'
    'cmdldFNkaxgEIAEoBVIJdGFyZ2V0U2RrEhoKCHVua25vd24yGAUgASgFUgh1bmtub3duMhIcCg'
    'lzcGxpdEFwa3MYCyADKAlSCXNwbGl0QXBrcxJAChFsaWJyYXJ5RGVwZW5kZW5jeRgNIAMoCzIS'
    'LkxpYnJhcnlEZXBlbmRlbmN5UhFsaWJyYXJ5RGVwZW5kZW5jeQ==');

@$core.Deprecated('Use dependencyDescriptor instead')
const Dependency$json = {
  '1': 'Dependency',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'unknown4', '3': 4, '4': 1, '5': 5, '10': 'unknown4'},
  ],
};

/// Descriptor for `Dependency`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dependencyDescriptor = $convert.base64Decode(
    'CgpEZXBlbmRlbmN5EiAKC3BhY2thZ2VOYW1lGAEgASgJUgtwYWNrYWdlTmFtZRIYCgd2ZXJzaW'
    '9uGAIgASgFUgd2ZXJzaW9uEhoKCHVua25vd240GAQgASgFUgh1bmtub3duNA==');

@$core.Deprecated('Use libraryDependencyDescriptor instead')
const LibraryDependency$json = {
  '1': 'LibraryDependency',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
    {'1': 'versionCode', '3': 2, '4': 1, '5': 3, '10': 'versionCode'},
  ],
};

/// Descriptor for `LibraryDependency`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryDependencyDescriptor = $convert.base64Decode(
    'ChFMaWJyYXJ5RGVwZW5kZW5jeRIgCgtwYWNrYWdlTmFtZRgBIAEoCVILcGFja2FnZU5hbWUSIA'
    'oLdmVyc2lvbkNvZGUYAiABKANSC3ZlcnNpb25Db2Rl');

@$core.Deprecated('Use testingProgramInfoDescriptor instead')
const TestingProgramInfo$json = {
  '1': 'TestingProgramInfo',
  '2': [
    {'1': 'subscribed', '3': 2, '4': 1, '5': 8, '10': 'subscribed'},
    {
      '1': 'subscribedAndInstalled',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'subscribedAndInstalled'
    },
    {'1': 'email', '3': 5, '4': 1, '5': 9, '10': 'email'},
    {'1': 'displayName', '3': 7, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'image', '3': 6, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
  ],
};

/// Descriptor for `TestingProgramInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testingProgramInfoDescriptor = $convert.base64Decode(
    'ChJUZXN0aW5nUHJvZ3JhbUluZm8SHgoKc3Vic2NyaWJlZBgCIAEoCFIKc3Vic2NyaWJlZBI2Ch'
    'ZzdWJzY3JpYmVkQW5kSW5zdGFsbGVkGAMgASgIUhZzdWJzY3JpYmVkQW5kSW5zdGFsbGVkEhQK'
    'BWVtYWlsGAUgASgJUgVlbWFpbBIgCgtkaXNwbGF5TmFtZRgHIAEoCVILZGlzcGxheU5hbWUSHA'
    'oFaW1hZ2UYBiABKAsyBi5JbWFnZVIFaW1hZ2U=');

@$core.Deprecated('Use earlyAccessInfoDescriptor instead')
const EarlyAccessInfo$json = {
  '1': 'EarlyAccessInfo',
  '2': [
    {'1': 'email', '3': 3, '4': 1, '5': 9, '10': 'email'},
  ],
};

/// Descriptor for `EarlyAccessInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List earlyAccessInfoDescriptor = $convert
    .base64Decode('Cg9FYXJseUFjY2Vzc0luZm8SFAoFZW1haWwYAyABKAlSBWVtYWls');

@$core.Deprecated('Use documentDetailsDescriptor instead')
const DocumentDetails$json = {
  '1': 'DocumentDetails',
  '2': [
    {
      '1': 'appDetails',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AppDetails',
      '10': 'appDetails'
    },
    {
      '1': 'subscriptionDetails',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.SubscriptionDetails',
      '10': 'subscriptionDetails'
    },
  ],
};

/// Descriptor for `DocumentDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentDetailsDescriptor = $convert.base64Decode(
    'Cg9Eb2N1bWVudERldGFpbHMSKwoKYXBwRGV0YWlscxgBIAEoCzILLkFwcERldGFpbHNSCmFwcE'
    'RldGFpbHMSRgoTc3Vic2NyaXB0aW9uRGV0YWlscxgHIAEoCzIULlN1YnNjcmlwdGlvbkRldGFp'
    'bHNSE3N1YnNjcmlwdGlvbkRldGFpbHM=');

@$core.Deprecated('Use patchDetailsDescriptor instead')
const PatchDetails$json = {
  '1': 'PatchDetails',
  '2': [
    {'1': 'baseVersionCode', '3': 1, '4': 1, '5': 5, '10': 'baseVersionCode'},
    {'1': 'size', '3': 2, '4': 1, '5': 3, '10': 'size'},
  ],
};

/// Descriptor for `PatchDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List patchDetailsDescriptor = $convert.base64Decode(
    'CgxQYXRjaERldGFpbHMSKAoPYmFzZVZlcnNpb25Db2RlGAEgASgFUg9iYXNlVmVyc2lvbkNvZG'
    'USEgoEc2l6ZRgCIAEoA1IEc2l6ZQ==');

@$core.Deprecated('Use fileMetadataDescriptor instead')
const FileMetadata$json = {
  '1': 'FileMetadata',
  '2': [
    {'1': 'fileType', '3': 1, '4': 1, '5': 5, '10': 'fileType'},
    {'1': 'versionCode', '3': 2, '4': 1, '5': 5, '10': 'versionCode'},
    {'1': 'size', '3': 3, '4': 1, '5': 3, '10': 'size'},
    {'1': 'splitId', '3': 4, '4': 1, '5': 9, '10': 'splitId'},
    {'1': 'compressedSize', '3': 5, '4': 1, '5': 3, '10': 'compressedSize'},
    {
      '1': 'patchDetails',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.PatchDetails',
      '10': 'patchDetails'
    },
  ],
};

/// Descriptor for `FileMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileMetadataDescriptor = $convert.base64Decode(
    'CgxGaWxlTWV0YWRhdGESGgoIZmlsZVR5cGUYASABKAVSCGZpbGVUeXBlEiAKC3ZlcnNpb25Db2'
    'RlGAIgASgFUgt2ZXJzaW9uQ29kZRISCgRzaXplGAMgASgDUgRzaXplEhgKB3NwbGl0SWQYBCAB'
    'KAlSB3NwbGl0SWQSJgoOY29tcHJlc3NlZFNpemUYBSABKANSDmNvbXByZXNzZWRTaXplEjEKDH'
    'BhdGNoRGV0YWlscxgGIAMoCzINLlBhdGNoRGV0YWlsc1IMcGF0Y2hEZXRhaWxz');

@$core.Deprecated('Use subscriptionDetailsDescriptor instead')
const SubscriptionDetails$json = {
  '1': 'SubscriptionDetails',
  '2': [
    {
      '1': 'subscriptionPeriod',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'subscriptionPeriod'
    },
  ],
};

/// Descriptor for `SubscriptionDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionDetailsDescriptor = $convert.base64Decode(
    'ChNTdWJzY3JpcHRpb25EZXRhaWxzEi4KEnN1YnNjcmlwdGlvblBlcmlvZBgBIAEoBVISc3Vic2'
    'NyaXB0aW9uUGVyaW9k');

@$core.Deprecated('Use bucketDescriptor instead')
const Bucket$json = {
  '1': 'Bucket',
  '2': [
    {'1': 'multiCorpus', '3': 2, '4': 1, '5': 8, '10': 'multiCorpus'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'iconUrl', '3': 4, '4': 1, '5': 9, '10': 'iconUrl'},
    {'1': 'fullContentsUrl', '3': 5, '4': 1, '5': 9, '10': 'fullContentsUrl'},
    {'1': 'relevance', '3': 6, '4': 1, '5': 1, '10': 'relevance'},
    {'1': 'estimatedResults', '3': 7, '4': 1, '5': 3, '10': 'estimatedResults'},
    {'1': 'analyticsCookie', '3': 8, '4': 1, '5': 9, '10': 'analyticsCookie'},
    {
      '1': 'fullContentsListUrl',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'fullContentsListUrl'
    },
    {'1': 'nextPageUrl', '3': 10, '4': 1, '5': 9, '10': 'nextPageUrl'},
    {'1': 'ordered', '3': 11, '4': 1, '5': 8, '10': 'ordered'},
  ],
};

/// Descriptor for `Bucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bucketDescriptor = $convert.base64Decode(
    'CgZCdWNrZXQSIAoLbXVsdGlDb3JwdXMYAiABKAhSC211bHRpQ29ycHVzEhQKBXRpdGxlGAMgAS'
    'gJUgV0aXRsZRIYCgdpY29uVXJsGAQgASgJUgdpY29uVXJsEigKD2Z1bGxDb250ZW50c1VybBgF'
    'IAEoCVIPZnVsbENvbnRlbnRzVXJsEhwKCXJlbGV2YW5jZRgGIAEoAVIJcmVsZXZhbmNlEioKEG'
    'VzdGltYXRlZFJlc3VsdHMYByABKANSEGVzdGltYXRlZFJlc3VsdHMSKAoPYW5hbHl0aWNzQ29v'
    'a2llGAggASgJUg9hbmFseXRpY3NDb29raWUSMAoTZnVsbENvbnRlbnRzTGlzdFVybBgJIAEoCV'
    'ITZnVsbENvbnRlbnRzTGlzdFVybBIgCgtuZXh0UGFnZVVybBgKIAEoCVILbmV4dFBhZ2VVcmwS'
    'GAoHb3JkZXJlZBgLIAEoCFIHb3JkZXJlZA==');

@$core.Deprecated('Use listResponseDescriptor instead')
const ListResponse$json = {
  '1': 'ListResponse',
  '2': [
    {'1': 'bucket', '3': 1, '4': 3, '5': 11, '6': '.Bucket', '10': 'bucket'},
    {'1': 'item', '3': 2, '4': 1, '5': 11, '6': '.Item', '10': 'item'},
  ],
};

/// Descriptor for `ListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listResponseDescriptor = $convert.base64Decode(
    'CgxMaXN0UmVzcG9uc2USHwoGYnVja2V0GAEgAygLMgcuQnVja2V0UgZidWNrZXQSGQoEaXRlbR'
    'gCIAEoCzIFLkl0ZW1SBGl0ZW0=');

@$core.Deprecated('Use itemDescriptor instead')
const Item$json = {
  '1': 'Item',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'subId', '3': 2, '4': 1, '5': 9, '10': 'subId'},
    {'1': 'type', '3': 3, '4': 1, '5': 5, '10': 'type'},
    {'1': 'categoryId', '3': 4, '4': 1, '5': 5, '10': 'categoryId'},
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
    {'1': 'creator', '3': 6, '4': 1, '5': 9, '10': 'creator'},
    {'1': 'descriptionHtml', '3': 7, '4': 1, '5': 9, '10': 'descriptionHtml'},
    {'1': 'offer', '3': 8, '4': 3, '5': 11, '6': '.Offer', '10': 'offer'},
    {
      '1': 'availability',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.Availability',
      '10': 'availability'
    },
    {'1': 'image', '3': 10, '4': 3, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'subItem', '3': 11, '4': 3, '5': 11, '6': '.Item', '10': 'subItem'},
    {
      '1': 'containerMetadata',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.ContainerMetadata',
      '10': 'containerMetadata'
    },
    {
      '1': 'details',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.DocumentDetails',
      '10': 'details'
    },
    {
      '1': 'aggregateRating',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.AggregateRating',
      '10': 'aggregateRating'
    },
    {
      '1': 'annotations',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.Annotations',
      '10': 'annotations'
    },
    {'1': 'detailsUrl', '3': 16, '4': 1, '5': 9, '10': 'detailsUrl'},
    {'1': 'shareUrl', '3': 17, '4': 1, '5': 9, '10': 'shareUrl'},
    {'1': 'reviewsUrl', '3': 18, '4': 1, '5': 9, '10': 'reviewsUrl'},
    {'1': 'backendUrl', '3': 19, '4': 1, '5': 9, '10': 'backendUrl'},
    {
      '1': 'purchaseDetailsUrl',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'purchaseDetailsUrl'
    },
    {'1': 'detailsReusable', '3': 21, '4': 1, '5': 8, '10': 'detailsReusable'},
    {'1': 'subtitle', '3': 22, '4': 1, '5': 9, '10': 'subtitle'},
    {
      '1': 'translatedDescriptionHtml',
      '3': 23,
      '4': 1,
      '5': 9,
      '10': 'translatedDescriptionHtml'
    },
    {
      '1': 'serverLogsCookie',
      '3': 24,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {
      '1': 'appInfo',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.AppInfo',
      '10': 'appInfo'
    },
    {'1': 'mature', '3': 26, '4': 1, '5': 8, '10': 'mature'},
    {
      '1': 'promotionalDescription',
      '3': 27,
      '4': 1,
      '5': 9,
      '10': 'promotionalDescription'
    },
    {
      '1': 'availableForPreregistration',
      '3': 29,
      '4': 1,
      '5': 8,
      '10': 'availableForPreregistration'
    },
    {'1': 'tip', '3': 30, '4': 3, '5': 11, '6': '.ReviewTip', '10': 'tip'},
    {
      '1': 'reviewSnippetsUrl',
      '3': 31,
      '4': 1,
      '5': 9,
      '10': 'reviewSnippetsUrl'
    },
    {
      '1': 'forceShareability',
      '3': 32,
      '4': 1,
      '5': 8,
      '10': 'forceShareability'
    },
    {
      '1': 'useWishlistAsPrimaryAction',
      '3': 33,
      '4': 1,
      '5': 8,
      '10': 'useWishlistAsPrimaryAction'
    },
    {
      '1': 'reviewQuestionsUrl',
      '3': 34,
      '4': 1,
      '5': 9,
      '10': 'reviewQuestionsUrl'
    },
    {
      '1': 'reviewSummaryUrl',
      '3': 39,
      '4': 1,
      '5': 9,
      '10': 'reviewSummaryUrl'
    },
    {
      '1': 'contentRating',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.ContentRating',
      '10': 'contentRating'
    },
  ],
};

/// Descriptor for `Item`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List itemDescriptor = $convert.base64Decode(
    'CgRJdGVtEg4KAmlkGAEgASgJUgJpZBIUCgVzdWJJZBgCIAEoCVIFc3ViSWQSEgoEdHlwZRgDIA'
    'EoBVIEdHlwZRIeCgpjYXRlZ29yeUlkGAQgASgFUgpjYXRlZ29yeUlkEhQKBXRpdGxlGAUgASgJ'
    'UgV0aXRsZRIYCgdjcmVhdG9yGAYgASgJUgdjcmVhdG9yEigKD2Rlc2NyaXB0aW9uSHRtbBgHIA'
    'EoCVIPZGVzY3JpcHRpb25IdG1sEhwKBW9mZmVyGAggAygLMgYuT2ZmZXJSBW9mZmVyEjEKDGF2'
    'YWlsYWJpbGl0eRgJIAEoCzINLkF2YWlsYWJpbGl0eVIMYXZhaWxhYmlsaXR5EhwKBWltYWdlGA'
    'ogAygLMgYuSW1hZ2VSBWltYWdlEh8KB3N1Ykl0ZW0YCyADKAsyBS5JdGVtUgdzdWJJdGVtEkAK'
    'EWNvbnRhaW5lck1ldGFkYXRhGAwgASgLMhIuQ29udGFpbmVyTWV0YWRhdGFSEWNvbnRhaW5lck'
    '1ldGFkYXRhEioKB2RldGFpbHMYDSABKAsyEC5Eb2N1bWVudERldGFpbHNSB2RldGFpbHMSOgoP'
    'YWdncmVnYXRlUmF0aW5nGA4gASgLMhAuQWdncmVnYXRlUmF0aW5nUg9hZ2dyZWdhdGVSYXRpbm'
    'cSLgoLYW5ub3RhdGlvbnMYDyABKAsyDC5Bbm5vdGF0aW9uc1ILYW5ub3RhdGlvbnMSHgoKZGV0'
    'YWlsc1VybBgQIAEoCVIKZGV0YWlsc1VybBIaCghzaGFyZVVybBgRIAEoCVIIc2hhcmVVcmwSHg'
    'oKcmV2aWV3c1VybBgSIAEoCVIKcmV2aWV3c1VybBIeCgpiYWNrZW5kVXJsGBMgASgJUgpiYWNr'
    'ZW5kVXJsEi4KEnB1cmNoYXNlRGV0YWlsc1VybBgUIAEoCVIScHVyY2hhc2VEZXRhaWxzVXJsEi'
    'gKD2RldGFpbHNSZXVzYWJsZRgVIAEoCFIPZGV0YWlsc1JldXNhYmxlEhoKCHN1YnRpdGxlGBYg'
    'ASgJUghzdWJ0aXRsZRI8Chl0cmFuc2xhdGVkRGVzY3JpcHRpb25IdG1sGBcgASgJUhl0cmFuc2'
    'xhdGVkRGVzY3JpcHRpb25IdG1sEioKEHNlcnZlckxvZ3NDb29raWUYGCABKAxSEHNlcnZlckxv'
    'Z3NDb29raWUSIgoHYXBwSW5mbxgZIAEoCzIILkFwcEluZm9SB2FwcEluZm8SFgoGbWF0dXJlGB'
    'ogASgIUgZtYXR1cmUSNgoWcHJvbW90aW9uYWxEZXNjcmlwdGlvbhgbIAEoCVIWcHJvbW90aW9u'
    'YWxEZXNjcmlwdGlvbhJAChthdmFpbGFibGVGb3JQcmVyZWdpc3RyYXRpb24YHSABKAhSG2F2YW'
    'lsYWJsZUZvclByZXJlZ2lzdHJhdGlvbhIcCgN0aXAYHiADKAsyCi5SZXZpZXdUaXBSA3RpcBIs'
    'ChFyZXZpZXdTbmlwcGV0c1VybBgfIAEoCVIRcmV2aWV3U25pcHBldHNVcmwSLAoRZm9yY2VTaG'
    'FyZWFiaWxpdHkYICABKAhSEWZvcmNlU2hhcmVhYmlsaXR5Ej4KGnVzZVdpc2hsaXN0QXNQcmlt'
    'YXJ5QWN0aW9uGCEgASgIUhp1c2VXaXNobGlzdEFzUHJpbWFyeUFjdGlvbhIuChJyZXZpZXdRdW'
    'VzdGlvbnNVcmwYIiABKAlSEnJldmlld1F1ZXN0aW9uc1VybBIqChByZXZpZXdTdW1tYXJ5VXJs'
    'GCcgASgJUhByZXZpZXdTdW1tYXJ5VXJsEjQKDWNvbnRlbnRSYXRpbmcYMiABKAsyDi5Db250ZW'
    '50UmF0aW5nUg1jb250ZW50UmF0aW5n');

@$core.Deprecated('Use contentRatingDescriptor instead')
const ContentRating$json = {
  '1': 'ContentRating',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'recommendationAndDescriptionHtml',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'recommendationAndDescriptionHtml'
    },
    {
      '1': 'contentRatingImage',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.ContentRating.ContentRatingImage',
      '10': 'contentRatingImage'
    },
    {'1': 'recommendation', '3': 5, '4': 1, '5': 9, '10': 'recommendation'},
    {'1': 'description', '3': 6, '4': 1, '5': 9, '10': 'description'},
  ],
  '3': [ContentRating_ContentRatingImage$json],
};

@$core.Deprecated('Use contentRatingDescriptor instead')
const ContentRating_ContentRatingImage$json = {
  '1': 'ContentRatingImage',
  '2': [
    {
      '1': 'dimension',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.ContentRating.ContentRatingImage.Dimension',
      '10': 'dimension'
    },
    {
      '1': 'image',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.ContentRating.ContentRatingImage.Image',
      '10': 'image'
    },
  ],
  '3': [
    ContentRating_ContentRatingImage_Dimension$json,
    ContentRating_ContentRatingImage_Image$json
  ],
};

@$core.Deprecated('Use contentRatingDescriptor instead')
const ContentRating_ContentRatingImage_Dimension$json = {
  '1': 'Dimension',
  '2': [
    {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
  ],
};

@$core.Deprecated('Use contentRatingDescriptor instead')
const ContentRating_ContentRatingImage_Image$json = {
  '1': 'Image',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `ContentRating`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentRatingDescriptor = $convert.base64Decode(
    'Cg1Db250ZW50UmF0aW5nEhQKBXRpdGxlGAEgASgJUgV0aXRsZRJKCiByZWNvbW1lbmRhdGlvbk'
    'FuZERlc2NyaXB0aW9uSHRtbBgCIAEoCVIgcmVjb21tZW5kYXRpb25BbmREZXNjcmlwdGlvbkh0'
    'bWwSUQoSY29udGVudFJhdGluZ0ltYWdlGAMgASgLMiEuQ29udGVudFJhdGluZy5Db250ZW50Um'
    'F0aW5nSW1hZ2VSEmNvbnRlbnRSYXRpbmdJbWFnZRImCg5yZWNvbW1lbmRhdGlvbhgFIAEoCVIO'
    'cmVjb21tZW5kYXRpb24SIAoLZGVzY3JpcHRpb24YBiABKAlSC2Rlc2NyaXB0aW9uGvQBChJDb2'
    '50ZW50UmF0aW5nSW1hZ2USSQoJZGltZW5zaW9uGAMgASgLMisuQ29udGVudFJhdGluZy5Db250'
    'ZW50UmF0aW5nSW1hZ2UuRGltZW5zaW9uUglkaW1lbnNpb24SPQoFaW1hZ2UYBiABKAsyJy5Db2'
    '50ZW50UmF0aW5nLkNvbnRlbnRSYXRpbmdJbWFnZS5JbWFnZVIFaW1hZ2UaOQoJRGltZW5zaW9u'
    'EhQKBXdpZHRoGAMgASgFUgV3aWR0aBIWCgZoZWlnaHQYBCABKAVSBmhlaWdodBoZCgVJbWFnZR'
    'IQCgN1cmwYASABKAlSA3VybA==');

@$core.Deprecated('Use appInfoDescriptor instead')
const AppInfo$json = {
  '1': 'AppInfo',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'section',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.AppInfoSection',
      '10': 'section'
    },
  ],
};

/// Descriptor for `AppInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appInfoDescriptor = $convert.base64Decode(
    'CgdBcHBJbmZvEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIpCgdzZWN0aW9uGAIgAygLMg8uQXBwSW'
    '5mb1NlY3Rpb25SB3NlY3Rpb24=');

@$core.Deprecated('Use appInfoSectionDescriptor instead')
const AppInfoSection$json = {
  '1': 'AppInfoSection',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'container',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.AppInfoContainer',
      '10': 'container'
    },
  ],
};

/// Descriptor for `AppInfoSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appInfoSectionDescriptor = $convert.base64Decode(
    'Cg5BcHBJbmZvU2VjdGlvbhIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSLwoJY29udGFpbmVyGAMgAS'
    'gLMhEuQXBwSW5mb0NvbnRhaW5lclIJY29udGFpbmVy');

@$core.Deprecated('Use appInfoContainerDescriptor instead')
const AppInfoContainer$json = {
  '1': 'AppInfoContainer',
  '2': [
    {'1': 'image', '3': 1, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `AppInfoContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appInfoContainerDescriptor = $convert.base64Decode(
    'ChBBcHBJbmZvQ29udGFpbmVyEhwKBWltYWdlGAEgASgLMgYuSW1hZ2VSBWltYWdlEiAKC2Rlc2'
    'NyaXB0aW9uGAIgASgJUgtkZXNjcmlwdGlvbg==');

@$core.Deprecated('Use annotationsDescriptor instead')
const Annotations$json = {
  '1': 'Annotations',
  '2': [
    {
      '1': 'sectionRelated',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionRelated'
    },
    {
      '1': 'sectionMoreBy',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionMoreBy'
    },
    {'1': 'warning', '3': 4, '4': 3, '5': 11, '6': '.Warning', '10': 'warning'},
    {
      '1': 'sectionBodyOfWork',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionBodyOfWork'
    },
    {
      '1': 'sectionCoreContent',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionCoreContent'
    },
    {
      '1': 'overlayMetaData',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.OverlayMetaData',
      '10': 'overlayMetaData'
    },
    {
      '1': 'badgeForCreator',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.Badge',
      '10': 'badgeForCreator'
    },
    {
      '1': 'infoBadge',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.Badge',
      '10': 'infoBadge'
    },
    {
      '1': 'annotationLink',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.AnnotationLink',
      '10': 'annotationLink'
    },
    {
      '1': 'sectionCrossSell',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionCrossSell'
    },
    {
      '1': 'sectionRelatedItemType',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionRelatedItemType'
    },
    {
      '1': 'promotedDoc',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.PromotedDoc',
      '10': 'promotedDoc'
    },
    {'1': 'offerNote', '3': 14, '4': 1, '5': 9, '10': 'offerNote'},
    {
      '1': 'privacyPolicyUrl',
      '3': 18,
      '4': 1,
      '5': 9,
      '10': 'privacyPolicyUrl'
    },
    {
      '1': 'suggestion_reasons',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.SuggestionReasons',
      '10': 'suggestionReasons'
    },
    {
      '1': 'optimalDeviceClassWarning',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.Warning',
      '10': 'optimalDeviceClassWarning'
    },
    {
      '1': 'badgeContainer',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.BadgeContainer',
      '10': 'badgeContainer'
    },
    {
      '1': 'sectionSuggestForRating',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionSuggestForRating'
    },
    {
      '1': 'sectionPurchaseCrossSell',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionPurchaseCrossSell'
    },
    {
      '1': 'overflowLink',
      '3': 25,
      '4': 3,
      '5': 11,
      '6': '.OverflowLink',
      '10': 'overflowLink'
    },
    {'1': 'attributionHtml', '3': 27, '4': 1, '5': 9, '10': 'attributionHtml'},
    {
      '1': 'purchaseHistoryDetails',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.PurchaseHistoryDetails',
      '10': 'purchaseHistoryDetails'
    },
    {
      '1': 'badgeForLegacyRating',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.Badge',
      '10': 'badgeForLegacyRating'
    },
    {
      '1': 'voucherInfo',
      '3': 30,
      '4': 3,
      '5': 11,
      '6': '.VoucherInfo',
      '10': 'voucherInfo'
    },
    {
      '1': 'sectionFeaturedApps',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionFeaturedApps'
    },
    {
      '1': 'detailsPageCluster',
      '3': 34,
      '4': 3,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'detailsPageCluster'
    },
    {
      '1': 'videoAnnotations',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.VideoAnnotations',
      '10': 'videoAnnotations'
    },
    {
      '1': 'sectionPurchaseRelatedTopics',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.SectionMetaData',
      '10': 'sectionPurchaseRelatedTopics'
    },
    {
      '1': 'mySubscriptionDetails',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.MySubscriptionDetails',
      '10': 'mySubscriptionDetails'
    },
    {
      '1': 'myRewardDetails',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.MyRewardDetails',
      '10': 'myRewardDetails'
    },
    {
      '1': 'featureBadge',
      '3': 39,
      '4': 3,
      '5': 11,
      '6': '.Badge',
      '10': 'featureBadge'
    },
    {
      '1': 'snippet',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.Snippet',
      '10': 'snippet'
    },
    {'1': 'downloadsLabel', '3': 48, '4': 1, '5': 9, '10': 'downloadsLabel'},
    {
      '1': 'badgeForRating',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.Badge',
      '10': 'badgeForRating'
    },
    {
      '1': 'categoryInfo',
      '3': 53,
      '4': 1,
      '5': 11,
      '6': '.CategoryInfo',
      '10': 'categoryInfo'
    },
    {
      '1': 'reasons',
      '3': 60,
      '4': 1,
      '5': 11,
      '6': '.EditorReason',
      '10': 'reasons'
    },
    {
      '1': 'topChartStream',
      '3': 65,
      '4': 1,
      '5': 11,
      '6': '.Stream',
      '10': 'topChartStream'
    },
    {'1': 'categoryName', '3': 66, '4': 1, '5': 9, '10': 'categoryName'},
    {'1': 'chip', '3': 71, '4': 3, '5': 11, '6': '.Chip', '10': 'chip'},
    {
      '1': 'displayBadge',
      '3': 72,
      '4': 3,
      '5': 11,
      '6': '.Badge',
      '10': 'displayBadge'
    },
    {'1': 'liveStreamUrl', '3': 80, '4': 1, '5': 9, '10': 'liveStreamUrl'},
    {
      '1': 'promotionStreamUrl',
      '3': 85,
      '4': 1,
      '5': 9,
      '10': 'promotionStreamUrl'
    },
    {
      '1': 'overlayMetaDataExtra',
      '3': 91,
      '4': 1,
      '5': 11,
      '6': '.OverlayMetaData',
      '10': 'overlayMetaDataExtra'
    },
    {
      '1': 'sectionImage',
      '3': 94,
      '4': 1,
      '5': 11,
      '6': '.SectionImage',
      '10': 'sectionImage'
    },
    {
      '1': 'categoryStream',
      '3': 97,
      '4': 1,
      '5': 11,
      '6': '.SubStream',
      '10': 'categoryStream'
    },
  ],
};

/// Descriptor for `Annotations`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List annotationsDescriptor = $convert.base64Decode(
    'CgtBbm5vdGF0aW9ucxI4Cg5zZWN0aW9uUmVsYXRlZBgBIAEoCzIQLlNlY3Rpb25NZXRhRGF0YV'
    'IOc2VjdGlvblJlbGF0ZWQSNgoNc2VjdGlvbk1vcmVCeRgCIAEoCzIQLlNlY3Rpb25NZXRhRGF0'
    'YVINc2VjdGlvbk1vcmVCeRIiCgd3YXJuaW5nGAQgAygLMgguV2FybmluZ1IHd2FybmluZxI+Ch'
    'FzZWN0aW9uQm9keU9mV29yaxgFIAEoCzIQLlNlY3Rpb25NZXRhRGF0YVIRc2VjdGlvbkJvZHlP'
    'ZldvcmsSQAoSc2VjdGlvbkNvcmVDb250ZW50GAYgASgLMhAuU2VjdGlvbk1ldGFEYXRhUhJzZW'
    'N0aW9uQ29yZUNvbnRlbnQSOgoPb3ZlcmxheU1ldGFEYXRhGAcgASgLMhAuT3ZlcmxheU1ldGFE'
    'YXRhUg9vdmVybGF5TWV0YURhdGESMAoPYmFkZ2VGb3JDcmVhdG9yGAggAygLMgYuQmFkZ2VSD2'
    'JhZGdlRm9yQ3JlYXRvchIkCglpbmZvQmFkZ2UYCSADKAsyBi5CYWRnZVIJaW5mb0JhZGdlEjcK'
    'DmFubm90YXRpb25MaW5rGAogASgLMg8uQW5ub3RhdGlvbkxpbmtSDmFubm90YXRpb25MaW5rEj'
    'wKEHNlY3Rpb25Dcm9zc1NlbGwYCyABKAsyEC5TZWN0aW9uTWV0YURhdGFSEHNlY3Rpb25Dcm9z'
    'c1NlbGwSSAoWc2VjdGlvblJlbGF0ZWRJdGVtVHlwZRgMIAEoCzIQLlNlY3Rpb25NZXRhRGF0YV'
    'IWc2VjdGlvblJlbGF0ZWRJdGVtVHlwZRIuCgtwcm9tb3RlZERvYxgNIAMoCzIMLlByb21vdGVk'
    'RG9jUgtwcm9tb3RlZERvYxIcCglvZmZlck5vdGUYDiABKAlSCW9mZmVyTm90ZRIqChBwcml2YW'
    'N5UG9saWN5VXJsGBIgASgJUhBwcml2YWN5UG9saWN5VXJsEkEKEnN1Z2dlc3Rpb25fcmVhc29u'
    'cxgTIAEoCzISLlN1Z2dlc3Rpb25SZWFzb25zUhFzdWdnZXN0aW9uUmVhc29ucxJGChlvcHRpbW'
    'FsRGV2aWNlQ2xhc3NXYXJuaW5nGBQgASgLMgguV2FybmluZ1IZb3B0aW1hbERldmljZUNsYXNz'
    'V2FybmluZxI3Cg5iYWRnZUNvbnRhaW5lchgVIAEoCzIPLkJhZGdlQ29udGFpbmVyUg5iYWRnZU'
    'NvbnRhaW5lchJKChdzZWN0aW9uU3VnZ2VzdEZvclJhdGluZxgWIAEoCzIQLlNlY3Rpb25NZXRh'
    'RGF0YVIXc2VjdGlvblN1Z2dlc3RGb3JSYXRpbmcSTAoYc2VjdGlvblB1cmNoYXNlQ3Jvc3NTZW'
    'xsGBggASgLMhAuU2VjdGlvbk1ldGFEYXRhUhhzZWN0aW9uUHVyY2hhc2VDcm9zc1NlbGwSMQoM'
    'b3ZlcmZsb3dMaW5rGBkgAygLMg0uT3ZlcmZsb3dMaW5rUgxvdmVyZmxvd0xpbmsSKAoPYXR0cm'
    'lidXRpb25IdG1sGBsgASgJUg9hdHRyaWJ1dGlvbkh0bWwSTwoWcHVyY2hhc2VIaXN0b3J5RGV0'
    'YWlscxgcIAEoCzIXLlB1cmNoYXNlSGlzdG9yeURldGFpbHNSFnB1cmNoYXNlSGlzdG9yeURldG'
    'FpbHMSOgoUYmFkZ2VGb3JMZWdhY3lSYXRpbmcYHSABKAsyBi5CYWRnZVIUYmFkZ2VGb3JMZWdh'
    'Y3lSYXRpbmcSLgoLdm91Y2hlckluZm8YHiADKAsyDC5Wb3VjaGVySW5mb1ILdm91Y2hlckluZm'
    '8SQgoTc2VjdGlvbkZlYXR1cmVkQXBwcxggIAEoCzIQLlNlY3Rpb25NZXRhRGF0YVITc2VjdGlv'
    'bkZlYXR1cmVkQXBwcxJAChJkZXRhaWxzUGFnZUNsdXN0ZXIYIiADKAsyEC5TZWN0aW9uTWV0YU'
    'RhdGFSEmRldGFpbHNQYWdlQ2x1c3RlchI9ChB2aWRlb0Fubm90YXRpb25zGCMgASgLMhEuVmlk'
    'ZW9Bbm5vdGF0aW9uc1IQdmlkZW9Bbm5vdGF0aW9ucxJUChxzZWN0aW9uUHVyY2hhc2VSZWxhdG'
    'VkVG9waWNzGCQgASgLMhAuU2VjdGlvbk1ldGFEYXRhUhxzZWN0aW9uUHVyY2hhc2VSZWxhdGVk'
    'VG9waWNzEkwKFW15U3Vic2NyaXB0aW9uRGV0YWlscxglIAEoCzIWLk15U3Vic2NyaXB0aW9uRG'
    'V0YWlsc1IVbXlTdWJzY3JpcHRpb25EZXRhaWxzEjoKD215UmV3YXJkRGV0YWlscxgmIAEoCzIQ'
    'Lk15UmV3YXJkRGV0YWlsc1IPbXlSZXdhcmREZXRhaWxzEioKDGZlYXR1cmVCYWRnZRgnIAMoCz'
    'IGLkJhZGdlUgxmZWF0dXJlQmFkZ2USIgoHc25pcHBldBgqIAEoCzIILlNuaXBwZXRSB3NuaXBw'
    'ZXQSJgoOZG93bmxvYWRzTGFiZWwYMCABKAlSDmRvd25sb2Fkc0xhYmVsEi4KDmJhZGdlRm9yUm'
    'F0aW5nGDIgASgLMgYuQmFkZ2VSDmJhZGdlRm9yUmF0aW5nEjEKDGNhdGVnb3J5SW5mbxg1IAEo'
    'CzINLkNhdGVnb3J5SW5mb1IMY2F0ZWdvcnlJbmZvEicKB3JlYXNvbnMYPCABKAsyDS5FZGl0b3'
    'JSZWFzb25SB3JlYXNvbnMSLwoOdG9wQ2hhcnRTdHJlYW0YQSABKAsyBy5TdHJlYW1SDnRvcENo'
    'YXJ0U3RyZWFtEiIKDGNhdGVnb3J5TmFtZRhCIAEoCVIMY2F0ZWdvcnlOYW1lEhkKBGNoaXAYRy'
    'ADKAsyBS5DaGlwUgRjaGlwEioKDGRpc3BsYXlCYWRnZRhIIAMoCzIGLkJhZGdlUgxkaXNwbGF5'
    'QmFkZ2USJAoNbGl2ZVN0cmVhbVVybBhQIAEoCVINbGl2ZVN0cmVhbVVybBIuChJwcm9tb3Rpb2'
    '5TdHJlYW1VcmwYVSABKAlSEnByb21vdGlvblN0cmVhbVVybBJEChRvdmVybGF5TWV0YURhdGFF'
    'eHRyYRhbIAEoCzIQLk92ZXJsYXlNZXRhRGF0YVIUb3ZlcmxheU1ldGFEYXRhRXh0cmESMQoMc2'
    'VjdGlvbkltYWdlGF4gASgLMg0uU2VjdGlvbkltYWdlUgxzZWN0aW9uSW1hZ2USMgoOY2F0ZWdv'
    'cnlTdHJlYW0YYSABKAsyCi5TdWJTdHJlYW1SDmNhdGVnb3J5U3RyZWFt');

@$core.Deprecated('Use editorReasonDescriptor instead')
const EditorReason$json = {
  '1': 'EditorReason',
  '2': [
    {'1': 'bulletin', '3': 1, '4': 3, '5': 9, '10': 'bulletin'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `EditorReason`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List editorReasonDescriptor = $convert.base64Decode(
    'CgxFZGl0b3JSZWFzb24SGgoIYnVsbGV0aW4YASADKAlSCGJ1bGxldGluEiAKC2Rlc2NyaXB0aW'
    '9uGAIgASgJUgtkZXNjcmlwdGlvbg==');

@$core.Deprecated('Use sectionMetaDataDescriptor instead')
const SectionMetaData$json = {
  '1': 'SectionMetaData',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 9, '10': 'header'},
    {'1': 'listUrl', '3': 2, '4': 1, '5': 9, '10': 'listUrl'},
    {'1': 'browseUrl', '3': 3, '4': 1, '5': 9, '10': 'browseUrl'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `SectionMetaData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionMetaDataDescriptor = $convert.base64Decode(
    'Cg9TZWN0aW9uTWV0YURhdGESFgoGaGVhZGVyGAEgASgJUgZoZWFkZXISGAoHbGlzdFVybBgCIA'
    'EoCVIHbGlzdFVybBIcCglicm93c2VVcmwYAyABKAlSCWJyb3dzZVVybBIgCgtkZXNjcmlwdGlv'
    'bhgEIAEoCVILZGVzY3JpcHRpb24=');

@$core.Deprecated('Use overlayMetaDataDescriptor instead')
const OverlayMetaData$json = {
  '1': 'OverlayMetaData',
  '2': [
    {
      '1': 'overlayHeader',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.OverlayHeader',
      '10': 'overlayHeader'
    },
    {
      '1': 'overlayTitle',
      '3': 181,
      '4': 1,
      '5': 11,
      '6': '.OverlayTitle',
      '10': 'overlayTitle'
    },
    {
      '1': 'overlayDescription',
      '3': 182,
      '4': 1,
      '5': 11,
      '6': '.OverlayDescription',
      '10': 'overlayDescription'
    },
  ],
};

/// Descriptor for `OverlayMetaData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List overlayMetaDataDescriptor = $convert.base64Decode(
    'Cg9PdmVybGF5TWV0YURhdGESNAoNb3ZlcmxheUhlYWRlchgBIAEoCzIOLk92ZXJsYXlIZWFkZX'
    'JSDW92ZXJsYXlIZWFkZXISMgoMb3ZlcmxheVRpdGxlGLUBIAEoCzINLk92ZXJsYXlUaXRsZVIM'
    'b3ZlcmxheVRpdGxlEkQKEm92ZXJsYXlEZXNjcmlwdGlvbhi2ASABKAsyEy5PdmVybGF5RGVzY3'
    'JpcHRpb25SEm92ZXJsYXlEZXNjcmlwdGlvbg==');

@$core.Deprecated('Use overlayHeaderDescriptor instead')
const OverlayHeader$json = {
  '1': 'OverlayHeader',
};

/// Descriptor for `OverlayHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List overlayHeaderDescriptor =
    $convert.base64Decode('Cg1PdmVybGF5SGVhZGVy');

@$core.Deprecated('Use overlayTitleDescriptor instead')
const OverlayTitle$json = {
  '1': 'OverlayTitle',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'compositeImage',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CompositeImage',
      '10': 'compositeImage'
    },
  ],
};

/// Descriptor for `OverlayTitle`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List overlayTitleDescriptor = $convert.base64Decode(
    'CgxPdmVybGF5VGl0bGUSFAoFdGl0bGUYASABKAlSBXRpdGxlEjcKDmNvbXBvc2l0ZUltYWdlGA'
    'MgASgLMg8uQ29tcG9zaXRlSW1hZ2VSDmNvbXBvc2l0ZUltYWdl');

@$core.Deprecated('Use compositeImageDescriptor instead')
const CompositeImage$json = {
  '1': 'CompositeImage',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'url', '3': 5, '4': 1, '5': 9, '10': 'url'},
    {'1': 'typeAlt', '3': 9, '4': 1, '5': 5, '10': 'typeAlt'},
    {'1': 'title', '3': 24, '4': 1, '5': 9, '10': 'title'},
    {'1': 'urlAlt', '3': 28, '4': 1, '5': 9, '10': 'urlAlt'},
  ],
};

/// Descriptor for `CompositeImage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List compositeImageDescriptor = $convert.base64Decode(
    'Cg5Db21wb3NpdGVJbWFnZRISCgR0eXBlGAEgASgFUgR0eXBlEhAKA3VybBgFIAEoCVIDdXJsEh'
    'gKB3R5cGVBbHQYCSABKAVSB3R5cGVBbHQSFAoFdGl0bGUYGCABKAlSBXRpdGxlEhYKBnVybEFs'
    'dBgcIAEoCVIGdXJsQWx0');

@$core.Deprecated('Use overlayDescriptionDescriptor instead')
const OverlayDescription$json = {
  '1': 'OverlayDescription',
  '2': [
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `OverlayDescription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List overlayDescriptionDescriptor = $convert.base64Decode(
    'ChJPdmVybGF5RGVzY3JpcHRpb24SIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9u');

@$core.Deprecated('Use suggestionReasonsDescriptor instead')
const SuggestionReasons$json = {
  '1': 'SuggestionReasons',
  '2': [
    {'1': 'reason', '3': 2, '4': 3, '5': 11, '6': '.Reason', '10': 'reason'},
    {
      '1': 'neutralDismissal',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.Dismissal',
      '10': 'neutralDismissal'
    },
    {
      '1': 'positiveDismissal',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.Dismissal',
      '10': 'positiveDismissal'
    },
  ],
};

/// Descriptor for `SuggestionReasons`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List suggestionReasonsDescriptor = $convert.base64Decode(
    'ChFTdWdnZXN0aW9uUmVhc29ucxIfCgZyZWFzb24YAiADKAsyBy5SZWFzb25SBnJlYXNvbhI2Ch'
    'BuZXV0cmFsRGlzbWlzc2FsGAQgASgLMgouRGlzbWlzc2FsUhBuZXV0cmFsRGlzbWlzc2FsEjgK'
    'EXBvc2l0aXZlRGlzbWlzc2FsGAUgASgLMgouRGlzbWlzc2FsUhFwb3NpdGl2ZURpc21pc3NhbA'
    '==');

@$core.Deprecated('Use reasonDescriptor instead')
const Reason$json = {
  '1': 'Reason',
  '2': [
    {'1': 'descriptionHtml', '3': 3, '4': 1, '5': 9, '10': 'descriptionHtml'},
    {
      '1': 'reasonPlusOne',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.ReasonPlusOne',
      '10': 'reasonPlusOne'
    },
    {
      '1': 'reasonReview',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.ReasonReview',
      '10': 'reasonReview'
    },
    {
      '1': 'dismissal',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.Dismissal',
      '10': 'dismissal'
    },
    {
      '1': 'reasonUserAction',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.ReasonUserAction',
      '10': 'reasonUserAction'
    },
  ],
};

/// Descriptor for `Reason`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasonDescriptor = $convert.base64Decode(
    'CgZSZWFzb24SKAoPZGVzY3JpcHRpb25IdG1sGAMgASgJUg9kZXNjcmlwdGlvbkh0bWwSNAoNcm'
    'Vhc29uUGx1c09uZRgEIAEoCzIOLlJlYXNvblBsdXNPbmVSDXJlYXNvblBsdXNPbmUSMQoMcmVh'
    'c29uUmV2aWV3GAUgASgLMg0uUmVhc29uUmV2aWV3UgxyZWFzb25SZXZpZXcSKAoJZGlzbWlzc2'
    'FsGAcgASgLMgouRGlzbWlzc2FsUglkaXNtaXNzYWwSPQoQcmVhc29uVXNlckFjdGlvbhgJIAEo'
    'CzIRLlJlYXNvblVzZXJBY3Rpb25SEHJlYXNvblVzZXJBY3Rpb24=');

@$core.Deprecated('Use reasonPlusOneDescriptor instead')
const ReasonPlusOne$json = {
  '1': 'ReasonPlusOne',
  '2': [
    {
      '1': 'localizedDescriptionHtml',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'localizedDescriptionHtml'
    },
    {
      '1': 'userProfile',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.UserProfile',
      '10': 'userProfile'
    },
  ],
};

/// Descriptor for `ReasonPlusOne`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasonPlusOneDescriptor = $convert.base64Decode(
    'Cg1SZWFzb25QbHVzT25lEjoKGGxvY2FsaXplZERlc2NyaXB0aW9uSHRtbBgBIAEoCVIYbG9jYW'
    'xpemVkRGVzY3JpcHRpb25IdG1sEi4KC3VzZXJQcm9maWxlGAMgAygLMgwuVXNlclByb2ZpbGVS'
    'C3VzZXJQcm9maWxl');

@$core.Deprecated('Use reasonReviewDescriptor instead')
const ReasonReview$json = {
  '1': 'ReasonReview',
  '2': [
    {'1': 'review', '3': 1, '4': 1, '5': 11, '6': '.Review', '10': 'review'},
  ],
};

/// Descriptor for `ReasonReview`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasonReviewDescriptor = $convert.base64Decode(
    'CgxSZWFzb25SZXZpZXcSHwoGcmV2aWV3GAEgASgLMgcuUmV2aWV3UgZyZXZpZXc=');

@$core.Deprecated('Use reasonUserActionDescriptor instead')
const ReasonUserAction$json = {
  '1': 'ReasonUserAction',
  '2': [
    {
      '1': 'userProfile',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.UserProfile',
      '10': 'userProfile'
    },
    {
      '1': 'localizedDescriptionHtml',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'localizedDescriptionHtml'
    },
  ],
};

/// Descriptor for `ReasonUserAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reasonUserActionDescriptor = $convert.base64Decode(
    'ChBSZWFzb25Vc2VyQWN0aW9uEi4KC3VzZXJQcm9maWxlGAEgASgLMgwuVXNlclByb2ZpbGVSC3'
    'VzZXJQcm9maWxlEjoKGGxvY2FsaXplZERlc2NyaXB0aW9uSHRtbBgCIAEoCVIYbG9jYWxpemVk'
    'RGVzY3JpcHRpb25IdG1s');

@$core.Deprecated('Use dismissalDescriptor instead')
const Dismissal$json = {
  '1': 'Dismissal',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'descriptionHtml', '3': 2, '4': 1, '5': 9, '10': 'descriptionHtml'},
  ],
};

/// Descriptor for `Dismissal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dismissalDescriptor = $convert.base64Decode(
    'CglEaXNtaXNzYWwSEAoDdXJsGAEgASgJUgN1cmwSKAoPZGVzY3JpcHRpb25IdG1sGAIgASgJUg'
    '9kZXNjcmlwdGlvbkh0bWw=');

@$core.Deprecated('Use snippetDescriptor instead')
const Snippet$json = {
  '1': 'Snippet',
  '2': [
    {'1': 'snippetHtml', '3': 1, '4': 1, '5': 9, '10': 'snippetHtml'},
  ],
};

/// Descriptor for `Snippet`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snippetDescriptor = $convert.base64Decode(
    'CgdTbmlwcGV0EiAKC3NuaXBwZXRIdG1sGAEgASgJUgtzbmlwcGV0SHRtbA==');

@$core.Deprecated('Use myRewardDetailsDescriptor instead')
const MyRewardDetails$json = {
  '1': 'MyRewardDetails',
  '2': [
    {
      '1': 'expirationTimeMillis',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'expirationTimeMillis'
    },
    {
      '1': 'expirationDescription',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'expirationDescription'
    },
    {'1': 'buttonLabel', '3': 3, '4': 1, '5': 9, '10': 'buttonLabel'},
    {
      '1': 'linkAction',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.Link',
      '10': 'linkAction'
    },
  ],
};

/// Descriptor for `MyRewardDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List myRewardDetailsDescriptor = $convert.base64Decode(
    'Cg9NeVJld2FyZERldGFpbHMSMgoUZXhwaXJhdGlvblRpbWVNaWxsaXMYASABKANSFGV4cGlyYX'
    'Rpb25UaW1lTWlsbGlzEjQKFWV4cGlyYXRpb25EZXNjcmlwdGlvbhgCIAEoCVIVZXhwaXJhdGlv'
    'bkRlc2NyaXB0aW9uEiAKC2J1dHRvbkxhYmVsGAMgASgJUgtidXR0b25MYWJlbBIlCgpsaW5rQW'
    'N0aW9uGAQgASgLMgUuTGlua1IKbGlua0FjdGlvbg==');

@$core.Deprecated('Use mySubscriptionDetailsDescriptor instead')
const MySubscriptionDetails$json = {
  '1': 'MySubscriptionDetails',
  '2': [
    {
      '1': 'subscriptionStatusHtml',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'subscriptionStatusHtml'
    },
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'titleByLineHtml', '3': 3, '4': 1, '5': 9, '10': 'titleByLineHtml'},
    {'1': 'formattedPrice', '3': 4, '4': 1, '5': 9, '10': 'formattedPrice'},
    {'1': 'priceByLineHtml', '3': 5, '4': 1, '5': 9, '10': 'priceByLineHtml'},
    {
      '1': 'cancelSubscription',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'cancelSubscription'
    },
    {
      '1': 'paymentDeclinedLearnMoreLink',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.Link',
      '10': 'paymentDeclinedLearnMoreLink'
    },
    {'1': 'inTrialPeriod', '3': 8, '4': 1, '5': 8, '10': 'inTrialPeriod'},
    {
      '1': 'titleByLineIcon',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.Image',
      '10': 'titleByLineIcon'
    },
  ],
};

/// Descriptor for `MySubscriptionDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mySubscriptionDetailsDescriptor = $convert.base64Decode(
    'ChVNeVN1YnNjcmlwdGlvbkRldGFpbHMSNgoWc3Vic2NyaXB0aW9uU3RhdHVzSHRtbBgBIAEoCV'
    'IWc3Vic2NyaXB0aW9uU3RhdHVzSHRtbBIUCgV0aXRsZRgCIAEoCVIFdGl0bGUSKAoPdGl0bGVC'
    'eUxpbmVIdG1sGAMgASgJUg90aXRsZUJ5TGluZUh0bWwSJgoOZm9ybWF0dGVkUHJpY2UYBCABKA'
    'lSDmZvcm1hdHRlZFByaWNlEigKD3ByaWNlQnlMaW5lSHRtbBgFIAEoCVIPcHJpY2VCeUxpbmVI'
    'dG1sEi4KEmNhbmNlbFN1YnNjcmlwdGlvbhgGIAEoCFISY2FuY2VsU3Vic2NyaXB0aW9uEkkKHH'
    'BheW1lbnREZWNsaW5lZExlYXJuTW9yZUxpbmsYByABKAsyBS5MaW5rUhxwYXltZW50RGVjbGlu'
    'ZWRMZWFybk1vcmVMaW5rEiQKDWluVHJpYWxQZXJpb2QYCCABKAhSDWluVHJpYWxQZXJpb2QSMA'
    'oPdGl0bGVCeUxpbmVJY29uGAkgASgLMgYuSW1hZ2VSD3RpdGxlQnlMaW5lSWNvbg==');

@$core.Deprecated('Use videoAnnotationsDescriptor instead')
const VideoAnnotations$json = {
  '1': 'VideoAnnotations',
  '2': [
    {'1': 'bundle', '3': 1, '4': 1, '5': 8, '10': 'bundle'},
    {
      '1': 'bundleContentListUrl',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'bundleContentListUrl'
    },
    {
      '1': 'extrasContentListUrl',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'extrasContentListUrl'
    },
    {
      '1': 'alsoAvailableInListUrl',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'alsoAvailableInListUrl'
    },
    {
      '1': 'bundleDocId',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.DocId',
      '10': 'bundleDocId'
    },
  ],
};

/// Descriptor for `VideoAnnotations`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List videoAnnotationsDescriptor = $convert.base64Decode(
    'ChBWaWRlb0Fubm90YXRpb25zEhYKBmJ1bmRsZRgBIAEoCFIGYnVuZGxlEjIKFGJ1bmRsZUNvbn'
    'RlbnRMaXN0VXJsGAIgASgJUhRidW5kbGVDb250ZW50TGlzdFVybBIyChRleHRyYXNDb250ZW50'
    'TGlzdFVybBgDIAEoCVIUZXh0cmFzQ29udGVudExpc3RVcmwSNgoWYWxzb0F2YWlsYWJsZUluTG'
    'lzdFVybBgEIAEoCVIWYWxzb0F2YWlsYWJsZUluTGlzdFVybBIoCgtidW5kbGVEb2NJZBgFIAMo'
    'CzIGLkRvY0lkUgtidW5kbGVEb2NJZA==');

@$core.Deprecated('Use voucherInfoDescriptor instead')
const VoucherInfo$json = {
  '1': 'VoucherInfo',
  '2': [
    {'1': 'item', '3': 1, '4': 1, '5': 11, '6': '.Item', '10': 'item'},
    {'1': 'offer', '3': 2, '4': 3, '5': 11, '6': '.Offer', '10': 'offer'},
  ],
};

/// Descriptor for `VoucherInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List voucherInfoDescriptor = $convert.base64Decode(
    'CgtWb3VjaGVySW5mbxIZCgRpdGVtGAEgASgLMgUuSXRlbVIEaXRlbRIcCgVvZmZlchgCIAMoCz'
    'IGLk9mZmVyUgVvZmZlcg==');

@$core.Deprecated('Use badgeContainerDescriptor instead')
const BadgeContainer$json = {
  '1': 'BadgeContainer',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'image', '3': 2, '4': 3, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'badge', '3': 3, '4': 3, '5': 11, '6': '.Badge', '10': 'badge'},
  ],
};

/// Descriptor for `BadgeContainer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List badgeContainerDescriptor = $convert.base64Decode(
    'Cg5CYWRnZUNvbnRhaW5lchIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSHAoFaW1hZ2UYAiADKAsyBi'
    '5JbWFnZVIFaW1hZ2USHAoFYmFkZ2UYAyADKAsyBi5CYWRnZVIFYmFkZ2U=');

@$core.Deprecated('Use overflowLinkDescriptor instead')
const OverflowLink$json = {
  '1': 'OverflowLink',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'link', '3': 2, '4': 1, '5': 11, '6': '.Link', '10': 'link'},
  ],
};

/// Descriptor for `OverflowLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List overflowLinkDescriptor = $convert.base64Decode(
    'CgxPdmVyZmxvd0xpbmsSFAoFdGl0bGUYASABKAlSBXRpdGxlEhkKBGxpbmsYAiABKAsyBS5MaW'
    '5rUgRsaW5r');

@$core.Deprecated('Use promotedDocDescriptor instead')
const PromotedDoc$json = {
  '1': 'PromotedDoc',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'subtitle', '3': 2, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'image', '3': 3, '4': 3, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'detailsUrl', '3': 5, '4': 1, '5': 9, '10': 'detailsUrl'},
  ],
};

/// Descriptor for `PromotedDoc`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List promotedDocDescriptor = $convert.base64Decode(
    'CgtQcm9tb3RlZERvYxIUCgV0aXRsZRgBIAEoCVIFdGl0bGUSGgoIc3VidGl0bGUYAiABKAlSCH'
    'N1YnRpdGxlEhwKBWltYWdlGAMgAygLMgYuSW1hZ2VSBWltYWdlEiAKC2Rlc2NyaXB0aW9uGAQg'
    'ASgJUgtkZXNjcmlwdGlvbhIeCgpkZXRhaWxzVXJsGAUgASgJUgpkZXRhaWxzVXJs');

@$core.Deprecated('Use warningDescriptor instead')
const Warning$json = {
  '1': 'Warning',
  '2': [
    {'1': 'localizedMessage', '3': 1, '4': 1, '5': 9, '10': 'localizedMessage'},
  ],
};

/// Descriptor for `Warning`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List warningDescriptor = $convert.base64Decode(
    'CgdXYXJuaW5nEioKEGxvY2FsaXplZE1lc3NhZ2UYASABKAlSEGxvY2FsaXplZE1lc3NhZ2U=');

@$core.Deprecated('Use annotationLinkDescriptor instead')
const AnnotationLink$json = {
  '1': 'AnnotationLink',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {
      '1': 'resolvedLink',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ResolvedLink',
      '10': 'resolvedLink'
    },
    {'1': 'uriBackend', '3': 3, '4': 1, '5': 5, '10': 'uriBackend'},
  ],
};

/// Descriptor for `AnnotationLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List annotationLinkDescriptor = $convert.base64Decode(
    'Cg5Bbm5vdGF0aW9uTGluaxIQCgN1cmkYASABKAlSA3VyaRIxCgxyZXNvbHZlZExpbmsYAiABKA'
    'syDS5SZXNvbHZlZExpbmtSDHJlc29sdmVkTGluaxIeCgp1cmlCYWNrZW5kGAMgASgFUgp1cmlC'
    'YWNrZW5k');

@$core.Deprecated('Use ratedDescriptor instead')
const Rated$json = {
  '1': 'Rated',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'image', '3': 2, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {
      '1': 'learnMoreHtmlLink',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'learnMoreHtmlLink'
    },
  ],
};

/// Descriptor for `Rated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ratedDescriptor = $convert.base64Decode(
    'CgVSYXRlZBIUCgVsYWJlbBgBIAEoCVIFbGFiZWwSHAoFaW1hZ2UYAiABKAsyBi5JbWFnZVIFaW'
    '1hZ2USLAoRbGVhcm5Nb3JlSHRtbExpbmsYBCABKAlSEWxlYXJuTW9yZUh0bWxMaW5r');

@$core.Deprecated('Use badgeDescriptor instead')
const Badge$json = {
  '1': 'Badge',
  '2': [
    {'1': 'major', '3': 1, '4': 1, '5': 9, '10': 'major'},
    {'1': 'image', '3': 2, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'minor', '3': 3, '4': 1, '5': 9, '10': 'minor'},
    {'1': 'minorHtml', '3': 4, '4': 1, '5': 9, '10': 'minorHtml'},
    {
      '1': 'subBadge',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.SubBadge',
      '10': 'subBadge'
    },
    {'1': 'link', '3': 7, '4': 1, '5': 11, '6': '.StreamLink', '10': 'link'},
    {'1': 'description', '3': 8, '4': 1, '5': 9, '10': 'description'},
    {
      '1': 'stream',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.SubStream',
      '10': 'stream'
    },
  ],
};

/// Descriptor for `Badge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List badgeDescriptor = $convert.base64Decode(
    'CgVCYWRnZRIUCgVtYWpvchgBIAEoCVIFbWFqb3ISHAoFaW1hZ2UYAiABKAsyBi5JbWFnZVIFaW'
    '1hZ2USFAoFbWlub3IYAyABKAlSBW1pbm9yEhwKCW1pbm9ySHRtbBgEIAEoCVIJbWlub3JIdG1s'
    'EiUKCHN1YkJhZGdlGAYgASgLMgkuU3ViQmFkZ2VSCHN1YkJhZGdlEh8KBGxpbmsYByABKAsyCy'
    '5TdHJlYW1MaW5rUgRsaW5rEiAKC2Rlc2NyaXB0aW9uGAggASgJUgtkZXNjcmlwdGlvbhIiCgZz'
    'dHJlYW0YDCABKAsyCi5TdWJTdHJlYW1SBnN0cmVhbQ==');

@$core.Deprecated('Use subBadgeDescriptor instead')
const SubBadge$json = {
  '1': 'SubBadge',
  '2': [
    {'1': 'image', '3': 1, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'description', '3': 4, '4': 1, '5': 9, '10': 'description'},
    {'1': 'link', '3': 5, '4': 1, '5': 11, '6': '.StreamLink', '10': 'link'},
  ],
};

/// Descriptor for `SubBadge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subBadgeDescriptor = $convert.base64Decode(
    'CghTdWJCYWRnZRIcCgVpbWFnZRgBIAEoCzIGLkltYWdlUgVpbWFnZRIgCgtkZXNjcmlwdGlvbh'
    'gEIAEoCVILZGVzY3JpcHRpb24SHwoEbGluaxgFIAEoCzILLlN0cmVhbUxpbmtSBGxpbms=');

@$core.Deprecated('Use streamDescriptor instead')
const Stream$json = {
  '1': 'Stream',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'stream', '3': 2, '4': 1, '5': 11, '6': '.SubStream', '10': 'stream'},
    {'1': 'subtitle', '3': 3, '4': 1, '5': 9, '10': 'subtitle'},
    {'1': 'browseUrl', '3': 83, '4': 1, '5': 9, '10': 'browseUrl'},
  ],
};

/// Descriptor for `Stream`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamDescriptor = $convert.base64Decode(
    'CgZTdHJlYW0SFAoFdGl0bGUYASABKAlSBXRpdGxlEiIKBnN0cmVhbRgCIAEoCzIKLlN1YlN0cm'
    'VhbVIGc3RyZWFtEhoKCHN1YnRpdGxlGAMgASgJUghzdWJ0aXRsZRIcCglicm93c2VVcmwYUyAB'
    'KAlSCWJyb3dzZVVybA==');

@$core.Deprecated('Use subStreamDescriptor instead')
const SubStream$json = {
  '1': 'SubStream',
  '2': [
    {'1': 'link', '3': 2, '4': 1, '5': 11, '6': '.StreamLink', '10': 'link'},
  ],
};

/// Descriptor for `SubStream`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subStreamDescriptor = $convert.base64Decode(
    'CglTdWJTdHJlYW0SHwoEbGluaxgCIAEoCzILLlN0cmVhbUxpbmtSBGxpbms=');

@$core.Deprecated('Use linkDescriptor instead')
const Link$json = {
  '1': 'Link',
  '2': [
    {'1': 'uri', '3': 1, '4': 1, '5': 9, '10': 'uri'},
    {
      '1': 'resolvedLink',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ResolvedLink',
      '10': 'resolvedLink'
    },
    {'1': 'uriBackend', '3': 3, '4': 1, '5': 5, '10': 'uriBackend'},
  ],
};

/// Descriptor for `Link`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List linkDescriptor = $convert.base64Decode(
    'CgRMaW5rEhAKA3VyaRgBIAEoCVIDdXJpEjEKDHJlc29sdmVkTGluaxgCIAEoCzINLlJlc29sdm'
    'VkTGlua1IMcmVzb2x2ZWRMaW5rEh4KCnVyaUJhY2tlbmQYAyABKAVSCnVyaUJhY2tlbmQ=');

@$core.Deprecated('Use streamLinkDescriptor instead')
const StreamLink$json = {
  '1': 'StreamLink',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'streamUrl', '3': 2, '4': 1, '5': 9, '10': 'streamUrl'},
    {'1': 'searchUrl', '3': 3, '4': 1, '5': 9, '10': 'searchUrl'},
    {'1': 'subCategoryUrl', '3': 5, '4': 1, '5': 9, '10': 'subCategoryUrl'},
    {'1': 'searchQuery', '3': 11, '4': 1, '5': 9, '10': 'searchQuery'},
  ],
};

/// Descriptor for `StreamLink`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamLinkDescriptor = $convert.base64Decode(
    'CgpTdHJlYW1MaW5rEhAKA3VybBgBIAEoCVIDdXJsEhwKCXN0cmVhbVVybBgCIAEoCVIJc3RyZW'
    'FtVXJsEhwKCXNlYXJjaFVybBgDIAEoCVIJc2VhcmNoVXJsEiYKDnN1YkNhdGVnb3J5VXJsGAUg'
    'ASgJUg5zdWJDYXRlZ29yeVVybBIgCgtzZWFyY2hRdWVyeRgLIAEoCVILc2VhcmNoUXVlcnk=');

@$core.Deprecated('Use chipDescriptor instead')
const Chip$json = {
  '1': 'Chip',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'stream', '3': 2, '4': 1, '5': 11, '6': '.SubStream', '10': 'stream'},
  ],
};

/// Descriptor for `Chip`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chipDescriptor = $convert.base64Decode(
    'CgRDaGlwEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIiCgZzdHJlYW0YAiABKAsyCi5TdWJTdHJlYW'
    '1SBnN0cmVhbQ==');

@$core.Deprecated('Use categoryInfoDescriptor instead')
const CategoryInfo$json = {
  '1': 'CategoryInfo',
  '2': [
    {'1': 'category', '3': 1, '4': 1, '5': 9, '10': 'category'},
    {'1': 'appCategory', '3': 2, '4': 1, '5': 9, '10': 'appCategory'},
  ],
};

/// Descriptor for `CategoryInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryInfoDescriptor = $convert.base64Decode(
    'CgxDYXRlZ29yeUluZm8SGgoIY2F0ZWdvcnkYASABKAlSCGNhdGVnb3J5EiAKC2FwcENhdGVnb3'
    'J5GAIgASgJUgthcHBDYXRlZ29yeQ==');

@$core.Deprecated('Use encryptedSubscriberInfoDescriptor instead')
const EncryptedSubscriberInfo$json = {
  '1': 'EncryptedSubscriberInfo',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 9, '10': 'data'},
    {'1': 'encryptedKey', '3': 2, '4': 1, '5': 9, '10': 'encryptedKey'},
    {'1': 'signature', '3': 3, '4': 1, '5': 9, '10': 'signature'},
    {'1': 'initVector', '3': 4, '4': 1, '5': 9, '10': 'initVector'},
    {'1': 'googleKeyVersion', '3': 5, '4': 1, '5': 5, '10': 'googleKeyVersion'},
    {
      '1': 'carrierKeyVersion',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'carrierKeyVersion'
    },
  ],
};

/// Descriptor for `EncryptedSubscriberInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedSubscriberInfoDescriptor = $convert.base64Decode(
    'ChdFbmNyeXB0ZWRTdWJzY3JpYmVySW5mbxISCgRkYXRhGAEgASgJUgRkYXRhEiIKDGVuY3J5cH'
    'RlZEtleRgCIAEoCVIMZW5jcnlwdGVkS2V5EhwKCXNpZ25hdHVyZRgDIAEoCVIJc2lnbmF0dXJl'
    'Eh4KCmluaXRWZWN0b3IYBCABKAlSCmluaXRWZWN0b3ISKgoQZ29vZ2xlS2V5VmVyc2lvbhgFIA'
    'EoBVIQZ29vZ2xlS2V5VmVyc2lvbhIsChFjYXJyaWVyS2V5VmVyc2lvbhgGIAEoBVIRY2Fycmll'
    'cktleVZlcnNpb24=');

@$core.Deprecated('Use availabilityDescriptor instead')
const Availability$json = {
  '1': 'Availability',
  '2': [
    {'1': 'restriction', '3': 5, '4': 1, '5': 5, '10': 'restriction'},
    {'1': 'offerType', '3': 6, '4': 1, '5': 5, '10': 'offerType'},
    {'1': 'rule', '3': 7, '4': 1, '5': 11, '6': '.Rule', '10': 'rule'},
    {
      '1': 'perdeviceavailabilityrestriction',
      '3': 9,
      '4': 3,
      '5': 10,
      '6': '.Availability.PerDeviceAvailabilityRestriction',
      '10': 'perdeviceavailabilityrestriction'
    },
    {
      '1': 'availableIfOwned',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'availableIfOwned'
    },
    {
      '1': 'install',
      '3': 14,
      '4': 3,
      '5': 11,
      '6': '.Install',
      '10': 'install'
    },
    {
      '1': 'filterInfo',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.FilterEvaluationInfo',
      '10': 'filterInfo'
    },
    {
      '1': 'ownershipInfo',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.OwnershipInfo',
      '10': 'ownershipInfo'
    },
    {
      '1': 'availabilityProblem',
      '3': 18,
      '4': 3,
      '5': 11,
      '6': '.AvailabilityProblem',
      '10': 'availabilityProblem'
    },
    {'1': 'hidden', '3': 21, '4': 1, '5': 8, '10': 'hidden'},
  ],
  '3': [Availability_PerDeviceAvailabilityRestriction$json],
};

@$core.Deprecated('Use availabilityDescriptor instead')
const Availability_PerDeviceAvailabilityRestriction$json = {
  '1': 'PerDeviceAvailabilityRestriction',
  '2': [
    {'1': 'androidId', '3': 10, '4': 1, '5': 6, '10': 'androidId'},
    {
      '1': 'deviceRestriction',
      '3': 11,
      '4': 1,
      '5': 5,
      '10': 'deviceRestriction'
    },
    {'1': 'channelId', '3': 12, '4': 1, '5': 3, '10': 'channelId'},
    {
      '1': 'filterInfo',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.FilterEvaluationInfo',
      '10': 'filterInfo'
    },
  ],
};

/// Descriptor for `Availability`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availabilityDescriptor = $convert.base64Decode(
    'CgxBdmFpbGFiaWxpdHkSIAoLcmVzdHJpY3Rpb24YBSABKAVSC3Jlc3RyaWN0aW9uEhwKCW9mZm'
    'VyVHlwZRgGIAEoBVIJb2ZmZXJUeXBlEhkKBHJ1bGUYByABKAsyBS5SdWxlUgRydWxlEnoKIHBl'
    'cmRldmljZWF2YWlsYWJpbGl0eXJlc3RyaWN0aW9uGAkgAygKMi4uQXZhaWxhYmlsaXR5LlBlck'
    'RldmljZUF2YWlsYWJpbGl0eVJlc3RyaWN0aW9uUiBwZXJkZXZpY2VhdmFpbGFiaWxpdHlyZXN0'
    'cmljdGlvbhIqChBhdmFpbGFibGVJZk93bmVkGA0gASgIUhBhdmFpbGFibGVJZk93bmVkEiIKB2'
    'luc3RhbGwYDiADKAsyCC5JbnN0YWxsUgdpbnN0YWxsEjUKCmZpbHRlckluZm8YECABKAsyFS5G'
    'aWx0ZXJFdmFsdWF0aW9uSW5mb1IKZmlsdGVySW5mbxI0Cg1vd25lcnNoaXBJbmZvGBEgASgLMg'
    '4uT3duZXJzaGlwSW5mb1INb3duZXJzaGlwSW5mbxJGChNhdmFpbGFiaWxpdHlQcm9ibGVtGBIg'
    'AygLMhQuQXZhaWxhYmlsaXR5UHJvYmxlbVITYXZhaWxhYmlsaXR5UHJvYmxlbRIWCgZoaWRkZW'
    '4YFSABKAhSBmhpZGRlbhrDAQogUGVyRGV2aWNlQXZhaWxhYmlsaXR5UmVzdHJpY3Rpb24SHAoJ'
    'YW5kcm9pZElkGAogASgGUglhbmRyb2lkSWQSLAoRZGV2aWNlUmVzdHJpY3Rpb24YCyABKAVSEW'
    'RldmljZVJlc3RyaWN0aW9uEhwKCWNoYW5uZWxJZBgMIAEoA1IJY2hhbm5lbElkEjUKCmZpbHRl'
    'ckluZm8YDyABKAsyFS5GaWx0ZXJFdmFsdWF0aW9uSW5mb1IKZmlsdGVySW5mbw==');

@$core.Deprecated('Use availabilityProblemDescriptor instead')
const AvailabilityProblem$json = {
  '1': 'AvailabilityProblem',
  '2': [
    {'1': 'problemType', '3': 1, '4': 1, '5': 5, '10': 'problemType'},
    {'1': 'missingValue', '3': 2, '4': 3, '5': 9, '10': 'missingValue'},
  ],
};

/// Descriptor for `AvailabilityProblem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List availabilityProblemDescriptor = $convert.base64Decode(
    'ChNBdmFpbGFiaWxpdHlQcm9ibGVtEiAKC3Byb2JsZW1UeXBlGAEgASgFUgtwcm9ibGVtVHlwZR'
    'IiCgxtaXNzaW5nVmFsdWUYAiADKAlSDG1pc3NpbmdWYWx1ZQ==');

@$core.Deprecated('Use filterEvaluationInfoDescriptor instead')
const FilterEvaluationInfo$json = {
  '1': 'FilterEvaluationInfo',
  '2': [
    {
      '1': 'ruleEvaluation',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.RuleEvaluation',
      '10': 'ruleEvaluation'
    },
  ],
};

/// Descriptor for `FilterEvaluationInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List filterEvaluationInfoDescriptor = $convert.base64Decode(
    'ChRGaWx0ZXJFdmFsdWF0aW9uSW5mbxI3Cg5ydWxlRXZhbHVhdGlvbhgBIAMoCzIPLlJ1bGVFdm'
    'FsdWF0aW9uUg5ydWxlRXZhbHVhdGlvbg==');

@$core.Deprecated('Use ruleDescriptor instead')
const Rule$json = {
  '1': 'Rule',
  '2': [
    {'1': 'negate', '3': 1, '4': 1, '5': 8, '10': 'negate'},
    {'1': 'operator', '3': 2, '4': 1, '5': 5, '10': 'operator'},
    {'1': 'key', '3': 3, '4': 1, '5': 5, '10': 'key'},
    {'1': 'stringArg', '3': 4, '4': 3, '5': 9, '10': 'stringArg'},
    {'1': 'longArg', '3': 5, '4': 3, '5': 3, '10': 'longArg'},
    {'1': 'doubleArg', '3': 6, '4': 3, '5': 1, '10': 'doubleArg'},
    {'1': 'subRule', '3': 7, '4': 3, '5': 11, '6': '.Rule', '10': 'subRule'},
    {'1': 'responseCode', '3': 8, '4': 1, '5': 5, '10': 'responseCode'},
    {'1': 'comment', '3': 9, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'stringArgHash', '3': 10, '4': 3, '5': 6, '10': 'stringArgHash'},
    {'1': 'constArg', '3': 11, '4': 3, '5': 5, '10': 'constArg'},
    {
      '1': 'availabilityProblemType',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'availabilityProblemType'
    },
    {
      '1': 'includeMissingValues',
      '3': 13,
      '4': 1,
      '5': 8,
      '10': 'includeMissingValues'
    },
  ],
};

/// Descriptor for `Rule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ruleDescriptor = $convert.base64Decode(
    'CgRSdWxlEhYKBm5lZ2F0ZRgBIAEoCFIGbmVnYXRlEhoKCG9wZXJhdG9yGAIgASgFUghvcGVyYX'
    'RvchIQCgNrZXkYAyABKAVSA2tleRIcCglzdHJpbmdBcmcYBCADKAlSCXN0cmluZ0FyZxIYCgds'
    'b25nQXJnGAUgAygDUgdsb25nQXJnEhwKCWRvdWJsZUFyZxgGIAMoAVIJZG91YmxlQXJnEh8KB3'
    'N1YlJ1bGUYByADKAsyBS5SdWxlUgdzdWJSdWxlEiIKDHJlc3BvbnNlQ29kZRgIIAEoBVIMcmVz'
    'cG9uc2VDb2RlEhgKB2NvbW1lbnQYCSABKAlSB2NvbW1lbnQSJAoNc3RyaW5nQXJnSGFzaBgKIA'
    'MoBlINc3RyaW5nQXJnSGFzaBIaCghjb25zdEFyZxgLIAMoBVIIY29uc3RBcmcSOAoXYXZhaWxh'
    'YmlsaXR5UHJvYmxlbVR5cGUYDCABKAVSF2F2YWlsYWJpbGl0eVByb2JsZW1UeXBlEjIKFGluY2'
    'x1ZGVNaXNzaW5nVmFsdWVzGA0gASgIUhRpbmNsdWRlTWlzc2luZ1ZhbHVlcw==');

@$core.Deprecated('Use ruleEvaluationDescriptor instead')
const RuleEvaluation$json = {
  '1': 'RuleEvaluation',
  '2': [
    {'1': 'rule', '3': 1, '4': 1, '5': 11, '6': '.Rule', '10': 'rule'},
    {
      '1': 'actualStringValue',
      '3': 2,
      '4': 3,
      '5': 9,
      '10': 'actualStringValue'
    },
    {'1': 'actualLongValue', '3': 3, '4': 3, '5': 3, '10': 'actualLongValue'},
    {'1': 'actualBoolValue', '3': 4, '4': 3, '5': 8, '10': 'actualBoolValue'},
    {
      '1': 'actualDoubleValue',
      '3': 5,
      '4': 3,
      '5': 1,
      '10': 'actualDoubleValue'
    },
  ],
};

/// Descriptor for `RuleEvaluation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ruleEvaluationDescriptor = $convert.base64Decode(
    'Cg5SdWxlRXZhbHVhdGlvbhIZCgRydWxlGAEgASgLMgUuUnVsZVIEcnVsZRIsChFhY3R1YWxTdH'
    'JpbmdWYWx1ZRgCIAMoCVIRYWN0dWFsU3RyaW5nVmFsdWUSKAoPYWN0dWFsTG9uZ1ZhbHVlGAMg'
    'AygDUg9hY3R1YWxMb25nVmFsdWUSKAoPYWN0dWFsQm9vbFZhbHVlGAQgAygIUg9hY3R1YWxCb2'
    '9sVmFsdWUSLAoRYWN0dWFsRG91YmxlVmFsdWUYBSADKAFSEWFjdHVhbERvdWJsZVZhbHVl');

@$core.Deprecated('Use libraryAppDetailsDescriptor instead')
const LibraryAppDetails$json = {
  '1': 'LibraryAppDetails',
  '2': [
    {'1': 'certificateHash', '3': 2, '4': 1, '5': 9, '10': 'certificateHash'},
    {
      '1': 'refundTimeoutTimestamp',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'refundTimeoutTimestamp'
    },
    {
      '1': 'postDeliveryRefundWindowMillis',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'postDeliveryRefundWindowMillis'
    },
  ],
};

/// Descriptor for `LibraryAppDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryAppDetailsDescriptor = $convert.base64Decode(
    'ChFMaWJyYXJ5QXBwRGV0YWlscxIoCg9jZXJ0aWZpY2F0ZUhhc2gYAiABKAlSD2NlcnRpZmljYX'
    'RlSGFzaBI2ChZyZWZ1bmRUaW1lb3V0VGltZXN0YW1wGAMgASgDUhZyZWZ1bmRUaW1lb3V0VGlt'
    'ZXN0YW1wEkYKHnBvc3REZWxpdmVyeVJlZnVuZFdpbmRvd01pbGxpcxgEIAEoA1IecG9zdERlbG'
    'l2ZXJ5UmVmdW5kV2luZG93TWlsbGlz');

@$core.Deprecated('Use libraryInAppDetailsDescriptor instead')
const LibraryInAppDetails$json = {
  '1': 'LibraryInAppDetails',
  '2': [
    {
      '1': 'signedPurchaseData',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'signedPurchaseData'
    },
    {'1': 'signature', '3': 2, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `LibraryInAppDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryInAppDetailsDescriptor = $convert.base64Decode(
    'ChNMaWJyYXJ5SW5BcHBEZXRhaWxzEi4KEnNpZ25lZFB1cmNoYXNlRGF0YRgBIAEoCVISc2lnbm'
    'VkUHVyY2hhc2VEYXRhEhwKCXNpZ25hdHVyZRgCIAEoCVIJc2lnbmF0dXJl');

@$core.Deprecated('Use libraryMutationDescriptor instead')
const LibraryMutation$json = {
  '1': 'LibraryMutation',
  '2': [
    {'1': 'DocId', '3': 1, '4': 1, '5': 11, '6': '.DocId', '10': 'DocId'},
    {'1': 'offerType', '3': 2, '4': 1, '5': 5, '10': 'offerType'},
    {'1': 'documentHash', '3': 3, '4': 1, '5': 3, '10': 'documentHash'},
    {'1': 'deleted', '3': 4, '4': 1, '5': 8, '10': 'deleted'},
    {
      '1': 'appDetails',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.LibraryAppDetails',
      '10': 'appDetails'
    },
    {
      '1': 'subscriptionDetails',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.LibrarySubscriptionDetails',
      '10': 'subscriptionDetails'
    },
    {
      '1': 'inAppDetails',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.LibraryInAppDetails',
      '10': 'inAppDetails'
    },
  ],
};

/// Descriptor for `LibraryMutation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryMutationDescriptor = $convert.base64Decode(
    'Cg9MaWJyYXJ5TXV0YXRpb24SHAoFRG9jSWQYASABKAsyBi5Eb2NJZFIFRG9jSWQSHAoJb2ZmZX'
    'JUeXBlGAIgASgFUglvZmZlclR5cGUSIgoMZG9jdW1lbnRIYXNoGAMgASgDUgxkb2N1bWVudEhh'
    'c2gSGAoHZGVsZXRlZBgEIAEoCFIHZGVsZXRlZBIyCgphcHBEZXRhaWxzGAUgASgLMhIuTGlicm'
    'FyeUFwcERldGFpbHNSCmFwcERldGFpbHMSTQoTc3Vic2NyaXB0aW9uRGV0YWlscxgGIAEoCzIb'
    'LkxpYnJhcnlTdWJzY3JpcHRpb25EZXRhaWxzUhNzdWJzY3JpcHRpb25EZXRhaWxzEjgKDGluQX'
    'BwRGV0YWlscxgHIAEoCzIULkxpYnJhcnlJbkFwcERldGFpbHNSDGluQXBwRGV0YWlscw==');

@$core.Deprecated('Use librarySubscriptionDetailsDescriptor instead')
const LibrarySubscriptionDetails$json = {
  '1': 'LibrarySubscriptionDetails',
  '2': [
    {
      '1': 'initiationTimestamp',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'initiationTimestamp'
    },
    {
      '1': 'validUntilTimestamp',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'validUntilTimestamp'
    },
    {'1': 'autoRenewing', '3': 3, '4': 1, '5': 8, '10': 'autoRenewing'},
    {
      '1': 'trialUntilTimestamp',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'trialUntilTimestamp'
    },
    {
      '1': 'signedPurchaseData',
      '3': 5,
      '4': 1,
      '5': 9,
      '10': 'signedPurchaseData'
    },
    {'1': 'signature', '3': 6, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `LibrarySubscriptionDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List librarySubscriptionDetailsDescriptor = $convert.base64Decode(
    'ChpMaWJyYXJ5U3Vic2NyaXB0aW9uRGV0YWlscxIwChNpbml0aWF0aW9uVGltZXN0YW1wGAEgAS'
    'gDUhNpbml0aWF0aW9uVGltZXN0YW1wEjAKE3ZhbGlkVW50aWxUaW1lc3RhbXAYAiABKANSE3Zh'
    'bGlkVW50aWxUaW1lc3RhbXASIgoMYXV0b1JlbmV3aW5nGAMgASgIUgxhdXRvUmVuZXdpbmcSMA'
    'oTdHJpYWxVbnRpbFRpbWVzdGFtcBgEIAEoA1ITdHJpYWxVbnRpbFRpbWVzdGFtcBIuChJzaWdu'
    'ZWRQdXJjaGFzZURhdGEYBSABKAlSEnNpZ25lZFB1cmNoYXNlRGF0YRIcCglzaWduYXR1cmUYBi'
    'ABKAlSCXNpZ25hdHVyZQ==');

@$core.Deprecated('Use libraryUpdateDescriptor instead')
const LibraryUpdate$json = {
  '1': 'LibraryUpdate',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 5, '10': 'status'},
    {'1': 'corpus', '3': 2, '4': 1, '5': 5, '10': 'corpus'},
    {'1': 'serverToken', '3': 3, '4': 1, '5': 12, '10': 'serverToken'},
    {
      '1': 'mutation',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.LibraryMutation',
      '10': 'mutation'
    },
    {'1': 'hasMore', '3': 5, '4': 1, '5': 8, '10': 'hasMore'},
    {'1': 'libraryId', '3': 6, '4': 1, '5': 9, '10': 'libraryId'},
  ],
};

/// Descriptor for `LibraryUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryUpdateDescriptor = $convert.base64Decode(
    'Cg1MaWJyYXJ5VXBkYXRlEhYKBnN0YXR1cxgBIAEoBVIGc3RhdHVzEhYKBmNvcnB1cxgCIAEoBV'
    'IGY29ycHVzEiAKC3NlcnZlclRva2VuGAMgASgMUgtzZXJ2ZXJUb2tlbhIsCghtdXRhdGlvbhgE'
    'IAMoCzIQLkxpYnJhcnlNdXRhdGlvblIIbXV0YXRpb24SGAoHaGFzTW9yZRgFIAEoCFIHaGFzTW'
    '9yZRIcCglsaWJyYXJ5SWQYBiABKAlSCWxpYnJhcnlJZA==');

@$core.Deprecated('Use androidAppNotificationDataDescriptor instead')
const AndroidAppNotificationData$json = {
  '1': 'AndroidAppNotificationData',
  '2': [
    {'1': 'versionCode', '3': 1, '4': 1, '5': 5, '10': 'versionCode'},
    {'1': 'assetId', '3': 2, '4': 1, '5': 9, '10': 'assetId'},
  ],
};

/// Descriptor for `AndroidAppNotificationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidAppNotificationDataDescriptor =
    $convert.base64Decode(
        'ChpBbmRyb2lkQXBwTm90aWZpY2F0aW9uRGF0YRIgCgt2ZXJzaW9uQ29kZRgBIAEoBVILdmVyc2'
        'lvbkNvZGUSGAoHYXNzZXRJZBgCIAEoCVIHYXNzZXRJZA==');

@$core.Deprecated('Use inAppNotificationDataDescriptor instead')
const InAppNotificationData$json = {
  '1': 'InAppNotificationData',
  '2': [
    {'1': 'checkoutOrderId', '3': 1, '4': 1, '5': 9, '10': 'checkoutOrderId'},
    {
      '1': 'inAppNotificationId',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'inAppNotificationId'
    },
  ],
};

/// Descriptor for `InAppNotificationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inAppNotificationDataDescriptor = $convert.base64Decode(
    'ChVJbkFwcE5vdGlmaWNhdGlvbkRhdGESKAoPY2hlY2tvdXRPcmRlcklkGAEgASgJUg9jaGVja2'
    '91dE9yZGVySWQSMAoTaW5BcHBOb3RpZmljYXRpb25JZBgCIAEoCVITaW5BcHBOb3RpZmljYXRp'
    'b25JZA==');

@$core.Deprecated('Use libraryDirtyDataDescriptor instead')
const LibraryDirtyData$json = {
  '1': 'LibraryDirtyData',
  '2': [
    {'1': 'backend', '3': 1, '4': 1, '5': 5, '10': 'backend'},
    {'1': 'libraryId', '3': 2, '4': 1, '5': 9, '10': 'libraryId'},
  ],
};

/// Descriptor for `LibraryDirtyData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List libraryDirtyDataDescriptor = $convert.base64Decode(
    'ChBMaWJyYXJ5RGlydHlEYXRhEhgKB2JhY2tlbmQYASABKAVSB2JhY2tlbmQSHAoJbGlicmFyeU'
    'lkGAIgASgJUglsaWJyYXJ5SWQ=');

@$core.Deprecated('Use notificationDescriptor instead')
const Notification$json = {
  '1': 'Notification',
  '2': [
    {'1': 'notificationType', '3': 1, '4': 1, '5': 5, '10': 'notificationType'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'DocId', '3': 4, '4': 1, '5': 11, '6': '.DocId', '10': 'DocId'},
    {'1': 'docTitle', '3': 5, '4': 1, '5': 9, '10': 'docTitle'},
    {'1': 'userEmail', '3': 6, '4': 1, '5': 9, '10': 'userEmail'},
    {
      '1': 'appData',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppNotificationData',
      '10': 'appData'
    },
    {
      '1': 'appDeliveryData',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.AndroidAppDeliveryData',
      '10': 'appDeliveryData'
    },
    {
      '1': 'purchaseRemovalData',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.PurchaseRemovalData',
      '10': 'purchaseRemovalData'
    },
    {
      '1': 'userNotificationData',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.UserNotificationData',
      '10': 'userNotificationData'
    },
    {
      '1': 'inAppNotificationData',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.InAppNotificationData',
      '10': 'inAppNotificationData'
    },
    {
      '1': 'purchaseDeclinedData',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.PurchaseDeclinedData',
      '10': 'purchaseDeclinedData'
    },
    {'1': 'notificationId', '3': 13, '4': 1, '5': 9, '10': 'notificationId'},
    {
      '1': 'libraryUpdate',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.LibraryUpdate',
      '10': 'libraryUpdate'
    },
    {
      '1': 'libraryDirtyData',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.LibraryDirtyData',
      '10': 'libraryDirtyData'
    },
  ],
};

/// Descriptor for `Notification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationDescriptor = $convert.base64Decode(
    'CgxOb3RpZmljYXRpb24SKgoQbm90aWZpY2F0aW9uVHlwZRgBIAEoBVIQbm90aWZpY2F0aW9uVH'
    'lwZRIcCgl0aW1lc3RhbXAYAyABKANSCXRpbWVzdGFtcBIcCgVEb2NJZBgEIAEoCzIGLkRvY0lk'
    'UgVEb2NJZBIaCghkb2NUaXRsZRgFIAEoCVIIZG9jVGl0bGUSHAoJdXNlckVtYWlsGAYgASgJUg'
    'l1c2VyRW1haWwSNQoHYXBwRGF0YRgHIAEoCzIbLkFuZHJvaWRBcHBOb3RpZmljYXRpb25EYXRh'
    'UgdhcHBEYXRhEkEKD2FwcERlbGl2ZXJ5RGF0YRgIIAEoCzIXLkFuZHJvaWRBcHBEZWxpdmVyeU'
    'RhdGFSD2FwcERlbGl2ZXJ5RGF0YRJGChNwdXJjaGFzZVJlbW92YWxEYXRhGAkgASgLMhQuUHVy'
    'Y2hhc2VSZW1vdmFsRGF0YVITcHVyY2hhc2VSZW1vdmFsRGF0YRJJChR1c2VyTm90aWZpY2F0aW'
    '9uRGF0YRgKIAEoCzIVLlVzZXJOb3RpZmljYXRpb25EYXRhUhR1c2VyTm90aWZpY2F0aW9uRGF0'
    'YRJMChVpbkFwcE5vdGlmaWNhdGlvbkRhdGEYCyABKAsyFi5JbkFwcE5vdGlmaWNhdGlvbkRhdG'
    'FSFWluQXBwTm90aWZpY2F0aW9uRGF0YRJJChRwdXJjaGFzZURlY2xpbmVkRGF0YRgMIAEoCzIV'
    'LlB1cmNoYXNlRGVjbGluZWREYXRhUhRwdXJjaGFzZURlY2xpbmVkRGF0YRImCg5ub3RpZmljYX'
    'Rpb25JZBgNIAEoCVIObm90aWZpY2F0aW9uSWQSNAoNbGlicmFyeVVwZGF0ZRgOIAEoCzIOLkxp'
    'YnJhcnlVcGRhdGVSDWxpYnJhcnlVcGRhdGUSPQoQbGlicmFyeURpcnR5RGF0YRgPIAEoCzIRLk'
    'xpYnJhcnlEaXJ0eURhdGFSEGxpYnJhcnlEaXJ0eURhdGE=');

@$core.Deprecated('Use purchaseDeclinedDataDescriptor instead')
const PurchaseDeclinedData$json = {
  '1': 'PurchaseDeclinedData',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 5, '10': 'reason'},
    {'1': 'showNotification', '3': 2, '4': 1, '5': 8, '10': 'showNotification'},
  ],
};

/// Descriptor for `PurchaseDeclinedData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseDeclinedDataDescriptor = $convert.base64Decode(
    'ChRQdXJjaGFzZURlY2xpbmVkRGF0YRIWCgZyZWFzb24YASABKAVSBnJlYXNvbhIqChBzaG93Tm'
    '90aWZpY2F0aW9uGAIgASgIUhBzaG93Tm90aWZpY2F0aW9u');

@$core.Deprecated('Use purchaseRemovalDataDescriptor instead')
const PurchaseRemovalData$json = {
  '1': 'PurchaseRemovalData',
  '2': [
    {'1': 'malicious', '3': 1, '4': 1, '5': 8, '10': 'malicious'},
  ],
};

/// Descriptor for `PurchaseRemovalData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List purchaseRemovalDataDescriptor =
    $convert.base64Decode(
        'ChNQdXJjaGFzZVJlbW92YWxEYXRhEhwKCW1hbGljaW91cxgBIAEoCFIJbWFsaWNpb3Vz');

@$core.Deprecated('Use userNotificationDataDescriptor instead')
const UserNotificationData$json = {
  '1': 'UserNotificationData',
  '2': [
    {
      '1': 'notificationTitle',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'notificationTitle'
    },
    {'1': 'notificationText', '3': 2, '4': 1, '5': 9, '10': 'notificationText'},
    {'1': 'tickerText', '3': 3, '4': 1, '5': 9, '10': 'tickerText'},
    {'1': 'dialogTitle', '3': 4, '4': 1, '5': 9, '10': 'dialogTitle'},
    {'1': 'dialogText', '3': 5, '4': 1, '5': 9, '10': 'dialogText'},
  ],
};

/// Descriptor for `UserNotificationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userNotificationDataDescriptor = $convert.base64Decode(
    'ChRVc2VyTm90aWZpY2F0aW9uRGF0YRIsChFub3RpZmljYXRpb25UaXRsZRgBIAEoCVIRbm90aW'
    'ZpY2F0aW9uVGl0bGUSKgoQbm90aWZpY2F0aW9uVGV4dBgCIAEoCVIQbm90aWZpY2F0aW9uVGV4'
    'dBIeCgp0aWNrZXJUZXh0GAMgASgJUgp0aWNrZXJUZXh0EiAKC2RpYWxvZ1RpdGxlGAQgASgJUg'
    'tkaWFsb2dUaXRsZRIeCgpkaWFsb2dUZXh0GAUgASgJUgpkaWFsb2dUZXh0');

@$core.Deprecated('Use aggregateRatingDescriptor instead')
const AggregateRating$json = {
  '1': 'AggregateRating',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '7': '1', '10': 'type'},
    {'1': 'starRating', '3': 2, '4': 1, '5': 2, '10': 'starRating'},
    {'1': 'ratingsCount', '3': 3, '4': 1, '5': 4, '10': 'ratingsCount'},
    {'1': 'oneStarRatings', '3': 4, '4': 1, '5': 4, '10': 'oneStarRatings'},
    {'1': 'twoStarRatings', '3': 5, '4': 1, '5': 4, '10': 'twoStarRatings'},
    {'1': 'threeStarRatings', '3': 6, '4': 1, '5': 4, '10': 'threeStarRatings'},
    {'1': 'fourStarRatings', '3': 7, '4': 1, '5': 4, '10': 'fourStarRatings'},
    {'1': 'fiveStarRatings', '3': 8, '4': 1, '5': 4, '10': 'fiveStarRatings'},
    {'1': 'thumbsUpCount', '3': 9, '4': 1, '5': 4, '10': 'thumbsUpCount'},
    {'1': 'thumbsDownCount', '3': 10, '4': 1, '5': 4, '10': 'thumbsDownCount'},
    {'1': 'commentCount', '3': 11, '4': 1, '5': 4, '10': 'commentCount'},
    {
      '1': 'bayesianMeanRating',
      '3': 12,
      '4': 1,
      '5': 1,
      '10': 'bayesianMeanRating'
    },
    {'1': 'tip', '3': 13, '4': 3, '5': 11, '6': '.Tip', '10': 'tip'},
    {'1': 'ratingLabel', '3': 17, '4': 1, '5': 9, '10': 'ratingLabel'},
    {
      '1': 'ratingCountLabelAbbreviated',
      '3': 18,
      '4': 1,
      '5': 9,
      '10': 'ratingCountLabelAbbreviated'
    },
    {
      '1': 'ratingCountLabel',
      '3': 19,
      '4': 1,
      '5': 9,
      '10': 'ratingCountLabel'
    },
  ],
};

/// Descriptor for `AggregateRating`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aggregateRatingDescriptor = $convert.base64Decode(
    'Cg9BZ2dyZWdhdGVSYXRpbmcSFQoEdHlwZRgBIAEoBToBMVIEdHlwZRIeCgpzdGFyUmF0aW5nGA'
    'IgASgCUgpzdGFyUmF0aW5nEiIKDHJhdGluZ3NDb3VudBgDIAEoBFIMcmF0aW5nc0NvdW50EiYK'
    'Dm9uZVN0YXJSYXRpbmdzGAQgASgEUg5vbmVTdGFyUmF0aW5ncxImCg50d29TdGFyUmF0aW5ncx'
    'gFIAEoBFIOdHdvU3RhclJhdGluZ3MSKgoQdGhyZWVTdGFyUmF0aW5ncxgGIAEoBFIQdGhyZWVT'
    'dGFyUmF0aW5ncxIoCg9mb3VyU3RhclJhdGluZ3MYByABKARSD2ZvdXJTdGFyUmF0aW5ncxIoCg'
    '9maXZlU3RhclJhdGluZ3MYCCABKARSD2ZpdmVTdGFyUmF0aW5ncxIkCg10aHVtYnNVcENvdW50'
    'GAkgASgEUg10aHVtYnNVcENvdW50EigKD3RodW1ic0Rvd25Db3VudBgKIAEoBFIPdGh1bWJzRG'
    '93bkNvdW50EiIKDGNvbW1lbnRDb3VudBgLIAEoBFIMY29tbWVudENvdW50Ei4KEmJheWVzaWFu'
    'TWVhblJhdGluZxgMIAEoAVISYmF5ZXNpYW5NZWFuUmF0aW5nEhYKA3RpcBgNIAMoCzIELlRpcF'
    'IDdGlwEiAKC3JhdGluZ0xhYmVsGBEgASgJUgtyYXRpbmdMYWJlbBJAChtyYXRpbmdDb3VudExh'
    'YmVsQWJicmV2aWF0ZWQYEiABKAlSG3JhdGluZ0NvdW50TGFiZWxBYmJyZXZpYXRlZBIqChByYX'
    'RpbmdDb3VudExhYmVsGBMgASgJUhByYXRpbmdDb3VudExhYmVs');

@$core.Deprecated('Use tipDescriptor instead')
const Tip$json = {
  '1': 'Tip',
  '2': [
    {'1': 'tipId', '3': 1, '4': 1, '5': 9, '10': 'tipId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'polarity', '3': 3, '4': 1, '5': 5, '10': 'polarity'},
    {'1': 'reviewCount', '3': 4, '4': 1, '5': 3, '10': 'reviewCount'},
    {'1': 'language', '3': 5, '4': 1, '5': 9, '10': 'language'},
    {'1': 'snippetReviewId', '3': 6, '4': 3, '5': 9, '10': 'snippetReviewId'},
  ],
};

/// Descriptor for `Tip`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tipDescriptor = $convert.base64Decode(
    'CgNUaXASFAoFdGlwSWQYASABKAlSBXRpcElkEhIKBHRleHQYAiABKAlSBHRleHQSGgoIcG9sYX'
    'JpdHkYAyABKAVSCHBvbGFyaXR5EiAKC3Jldmlld0NvdW50GAQgASgDUgtyZXZpZXdDb3VudBIa'
    'CghsYW5ndWFnZRgFIAEoCVIIbGFuZ3VhZ2USKAoPc25pcHBldFJldmlld0lkGAYgAygJUg9zbm'
    'lwcGV0UmV2aWV3SWQ=');

@$core.Deprecated('Use reviewTipDescriptor instead')
const ReviewTip$json = {
  '1': 'ReviewTip',
  '2': [
    {'1': 'tipUrl', '3': 1, '4': 1, '5': 9, '10': 'tipUrl'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'polarity', '3': 3, '4': 1, '5': 5, '10': 'polarity'},
    {'1': 'reviewCount', '3': 4, '4': 1, '5': 3, '10': 'reviewCount'},
  ],
};

/// Descriptor for `ReviewTip`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewTipDescriptor = $convert.base64Decode(
    'CglSZXZpZXdUaXASFgoGdGlwVXJsGAEgASgJUgZ0aXBVcmwSEgoEdGV4dBgCIAEoCVIEdGV4dB'
    'IaCghwb2xhcml0eRgDIAEoBVIIcG9sYXJpdHkSIAoLcmV2aWV3Q291bnQYBCABKANSC3Jldmll'
    'd0NvdW50');

@$core.Deprecated('Use acceptTosResponseDescriptor instead')
const AcceptTosResponse$json = {
  '1': 'AcceptTosResponse',
};

/// Descriptor for `AcceptTosResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acceptTosResponseDescriptor =
    $convert.base64Decode('ChFBY2NlcHRUb3NSZXNwb25zZQ==');

@$core.Deprecated('Use carrierBillingConfigDescriptor instead')
const CarrierBillingConfig$json = {
  '1': 'CarrierBillingConfig',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'apiVersion', '3': 3, '4': 1, '5': 5, '10': 'apiVersion'},
    {'1': 'provisioningUrl', '3': 4, '4': 1, '5': 9, '10': 'provisioningUrl'},
    {'1': 'credentialsUrl', '3': 5, '4': 1, '5': 9, '10': 'credentialsUrl'},
    {'1': 'tosRequired', '3': 6, '4': 1, '5': 8, '10': 'tosRequired'},
    {
      '1': 'perTransactionCredentialsRequired',
      '3': 7,
      '4': 1,
      '5': 8,
      '10': 'perTransactionCredentialsRequired'
    },
    {
      '1': 'sendSubscriberIdWithCarrierBillingRequests',
      '3': 8,
      '4': 1,
      '5': 8,
      '10': 'sendSubscriberIdWithCarrierBillingRequests'
    },
  ],
};

/// Descriptor for `CarrierBillingConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List carrierBillingConfigDescriptor = $convert.base64Decode(
    'ChRDYXJyaWVyQmlsbGluZ0NvbmZpZxIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbm'
    'FtZRIeCgphcGlWZXJzaW9uGAMgASgFUgphcGlWZXJzaW9uEigKD3Byb3Zpc2lvbmluZ1VybBgE'
    'IAEoCVIPcHJvdmlzaW9uaW5nVXJsEiYKDmNyZWRlbnRpYWxzVXJsGAUgASgJUg5jcmVkZW50aW'
    'Fsc1VybBIgCgt0b3NSZXF1aXJlZBgGIAEoCFILdG9zUmVxdWlyZWQSTAohcGVyVHJhbnNhY3Rp'
    'b25DcmVkZW50aWFsc1JlcXVpcmVkGAcgASgIUiFwZXJUcmFuc2FjdGlvbkNyZWRlbnRpYWxzUm'
    'VxdWlyZWQSXgoqc2VuZFN1YnNjcmliZXJJZFdpdGhDYXJyaWVyQmlsbGluZ1JlcXVlc3RzGAgg'
    'ASgIUipzZW5kU3Vic2NyaWJlcklkV2l0aENhcnJpZXJCaWxsaW5nUmVxdWVzdHM=');

@$core.Deprecated('Use billingConfigDescriptor instead')
const BillingConfig$json = {
  '1': 'BillingConfig',
  '2': [
    {
      '1': 'carrierBillingConfig',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarrierBillingConfig',
      '10': 'carrierBillingConfig'
    },
    {'1': 'maxIabApiVersion', '3': 2, '4': 1, '5': 5, '10': 'maxIabApiVersion'},
  ],
};

/// Descriptor for `BillingConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List billingConfigDescriptor = $convert.base64Decode(
    'Cg1CaWxsaW5nQ29uZmlnEkkKFGNhcnJpZXJCaWxsaW5nQ29uZmlnGAEgASgLMhUuQ2Fycmllck'
    'JpbGxpbmdDb25maWdSFGNhcnJpZXJCaWxsaW5nQ29uZmlnEioKEG1heElhYkFwaVZlcnNpb24Y'
    'AiABKAVSEG1heElhYkFwaVZlcnNpb24=');

@$core.Deprecated('Use corpusMetadataDescriptor instead')
const CorpusMetadata$json = {
  '1': 'CorpusMetadata',
  '2': [
    {'1': 'backend', '3': 1, '4': 1, '5': 5, '10': 'backend'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'landingUrl', '3': 3, '4': 1, '5': 9, '10': 'landingUrl'},
    {'1': 'libraryName', '3': 4, '4': 1, '5': 9, '10': 'libraryName'},
    {'1': 'recsWidgetUrl', '3': 6, '4': 1, '5': 9, '10': 'recsWidgetUrl'},
    {'1': 'shopName', '3': 7, '4': 1, '5': 9, '10': 'shopName'},
  ],
};

/// Descriptor for `CorpusMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List corpusMetadataDescriptor = $convert.base64Decode(
    'Cg5Db3JwdXNNZXRhZGF0YRIYCgdiYWNrZW5kGAEgASgFUgdiYWNrZW5kEhIKBG5hbWUYAiABKA'
    'lSBG5hbWUSHgoKbGFuZGluZ1VybBgDIAEoCVIKbGFuZGluZ1VybBIgCgtsaWJyYXJ5TmFtZRgE'
    'IAEoCVILbGlicmFyeU5hbWUSJAoNcmVjc1dpZGdldFVybBgGIAEoCVINcmVjc1dpZGdldFVybB'
    'IaCghzaG9wTmFtZRgHIAEoCVIIc2hvcE5hbWU=');

@$core.Deprecated('Use experimentsDescriptor instead')
const Experiments$json = {
  '1': 'Experiments',
  '2': [
    {'1': 'experimentId', '3': 1, '4': 3, '5': 9, '10': 'experimentId'},
  ],
};

/// Descriptor for `Experiments`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List experimentsDescriptor = $convert.base64Decode(
    'CgtFeHBlcmltZW50cxIiCgxleHBlcmltZW50SWQYASADKAlSDGV4cGVyaW1lbnRJZA==');

@$core.Deprecated('Use selfUpdateConfigDescriptor instead')
const SelfUpdateConfig$json = {
  '1': 'SelfUpdateConfig',
  '2': [
    {
      '1': 'latestClientVersionCode',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'latestClientVersionCode'
    },
  ],
};

/// Descriptor for `SelfUpdateConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selfUpdateConfigDescriptor = $convert.base64Decode(
    'ChBTZWxmVXBkYXRlQ29uZmlnEjgKF2xhdGVzdENsaWVudFZlcnNpb25Db2RlGAEgASgFUhdsYX'
    'Rlc3RDbGllbnRWZXJzaW9uQ29kZQ==');

@$core.Deprecated('Use tocResponseDescriptor instead')
const TocResponse$json = {
  '1': 'TocResponse',
  '2': [
    {
      '1': 'corpus',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.CorpusMetadata',
      '10': 'corpus'
    },
    {
      '1': 'tosVersionDeprecated',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'tosVersionDeprecated'
    },
    {'1': 'tosContent', '3': 3, '4': 1, '5': 9, '10': 'tosContent'},
    {'1': 'homeUrl', '3': 4, '4': 1, '5': 9, '10': 'homeUrl'},
    {
      '1': 'experiments',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.Experiments',
      '10': 'experiments'
    },
    {
      '1': 'tosCheckboxTextMarketingEmails',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'tosCheckboxTextMarketingEmails'
    },
    {'1': 'tosToken', '3': 7, '4': 1, '5': 9, '10': 'tosToken'},
    {
      '1': 'userSettings',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.UserSettings',
      '10': 'userSettings'
    },
    {'1': 'iconOverrideUrl', '3': 9, '4': 1, '5': 9, '10': 'iconOverrideUrl'},
    {
      '1': 'selfUpdateConfig',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.SelfUpdateConfig',
      '10': 'selfUpdateConfig'
    },
    {
      '1': 'requiresUploadDeviceConfig',
      '3': 11,
      '4': 1,
      '5': 8,
      '10': 'requiresUploadDeviceConfig'
    },
    {
      '1': 'billingConfig',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.BillingConfig',
      '10': 'billingConfig'
    },
    {'1': 'recsWidgetUrl', '3': 13, '4': 1, '5': 9, '10': 'recsWidgetUrl'},
    {'1': 'socialHomeUrl', '3': 15, '4': 1, '5': 9, '10': 'socialHomeUrl'},
    {
      '1': 'ageVerificationRequired',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'ageVerificationRequired'
    },
    {
      '1': 'gPlusSignupEnabled',
      '3': 17,
      '4': 1,
      '5': 8,
      '10': 'gPlusSignupEnabled'
    },
    {'1': 'redeemEnabled', '3': 18, '4': 1, '5': 8, '10': 'redeemEnabled'},
    {'1': 'helpUrl', '3': 19, '4': 1, '5': 9, '10': 'helpUrl'},
    {'1': 'themeId', '3': 20, '4': 1, '5': 5, '10': 'themeId'},
    {
      '1': 'entertainmentHomeUrl',
      '3': 21,
      '4': 1,
      '5': 9,
      '10': 'entertainmentHomeUrl'
    },
    {'1': 'cookie', '3': 22, '4': 1, '5': 9, '10': 'cookie'},
  ],
};

/// Descriptor for `TocResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tocResponseDescriptor = $convert.base64Decode(
    'CgtUb2NSZXNwb25zZRInCgZjb3JwdXMYASADKAsyDy5Db3JwdXNNZXRhZGF0YVIGY29ycHVzEj'
    'IKFHRvc1ZlcnNpb25EZXByZWNhdGVkGAIgASgFUhR0b3NWZXJzaW9uRGVwcmVjYXRlZBIeCgp0'
    'b3NDb250ZW50GAMgASgJUgp0b3NDb250ZW50EhgKB2hvbWVVcmwYBCABKAlSB2hvbWVVcmwSLg'
    'oLZXhwZXJpbWVudHMYBSABKAsyDC5FeHBlcmltZW50c1ILZXhwZXJpbWVudHMSRgoedG9zQ2hl'
    'Y2tib3hUZXh0TWFya2V0aW5nRW1haWxzGAYgASgJUh50b3NDaGVja2JveFRleHRNYXJrZXRpbm'
    'dFbWFpbHMSGgoIdG9zVG9rZW4YByABKAlSCHRvc1Rva2VuEjEKDHVzZXJTZXR0aW5ncxgIIAEo'
    'CzINLlVzZXJTZXR0aW5nc1IMdXNlclNldHRpbmdzEigKD2ljb25PdmVycmlkZVVybBgJIAEoCV'
    'IPaWNvbk92ZXJyaWRlVXJsEj0KEHNlbGZVcGRhdGVDb25maWcYCiABKAsyES5TZWxmVXBkYXRl'
    'Q29uZmlnUhBzZWxmVXBkYXRlQ29uZmlnEj4KGnJlcXVpcmVzVXBsb2FkRGV2aWNlQ29uZmlnGA'
    'sgASgIUhpyZXF1aXJlc1VwbG9hZERldmljZUNvbmZpZxI0Cg1iaWxsaW5nQ29uZmlnGAwgASgL'
    'Mg4uQmlsbGluZ0NvbmZpZ1INYmlsbGluZ0NvbmZpZxIkCg1yZWNzV2lkZ2V0VXJsGA0gASgJUg'
    '1yZWNzV2lkZ2V0VXJsEiQKDXNvY2lhbEhvbWVVcmwYDyABKAlSDXNvY2lhbEhvbWVVcmwSOAoX'
    'YWdlVmVyaWZpY2F0aW9uUmVxdWlyZWQYECABKAhSF2FnZVZlcmlmaWNhdGlvblJlcXVpcmVkEi'
    '4KEmdQbHVzU2lnbnVwRW5hYmxlZBgRIAEoCFISZ1BsdXNTaWdudXBFbmFibGVkEiQKDXJlZGVl'
    'bUVuYWJsZWQYEiABKAhSDXJlZGVlbUVuYWJsZWQSGAoHaGVscFVybBgTIAEoCVIHaGVscFVybB'
    'IYCgd0aGVtZUlkGBQgASgFUgd0aGVtZUlkEjIKFGVudGVydGFpbm1lbnRIb21lVXJsGBUgASgJ'
    'UhRlbnRlcnRhaW5tZW50SG9tZVVybBIWCgZjb29raWUYFiABKAlSBmNvb2tpZQ==');

@$core.Deprecated('Use userSettingsDescriptor instead')
const UserSettings$json = {
  '1': 'UserSettings',
  '2': [
    {
      '1': 'tosCheckboxMarketingEmailsOptedIn',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'tosCheckboxMarketingEmailsOptedIn'
    },
    {
      '1': 'privacySetting',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.PrivacySetting',
      '10': 'privacySetting'
    },
  ],
};

/// Descriptor for `UserSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userSettingsDescriptor = $convert.base64Decode(
    'CgxVc2VyU2V0dGluZ3MSTAohdG9zQ2hlY2tib3hNYXJrZXRpbmdFbWFpbHNPcHRlZEluGAEgAS'
    'gIUiF0b3NDaGVja2JveE1hcmtldGluZ0VtYWlsc09wdGVkSW4SNwoOcHJpdmFjeVNldHRpbmcY'
    'AiABKAsyDy5Qcml2YWN5U2V0dGluZ1IOcHJpdmFjeVNldHRpbmc=');

@$core.Deprecated('Use privacySettingDescriptor instead')
const PrivacySetting$json = {
  '1': 'PrivacySetting',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'currentStatus', '3': 2, '4': 1, '5': 5, '10': 'currentStatus'},
    {'1': 'enabledByDefault', '3': 3, '4': 1, '5': 8, '10': 'enabledByDefault'},
  ],
};

/// Descriptor for `PrivacySetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List privacySettingDescriptor = $convert.base64Decode(
    'Cg5Qcml2YWN5U2V0dGluZxISCgR0eXBlGAEgASgFUgR0eXBlEiQKDWN1cnJlbnRTdGF0dXMYAi'
    'ABKAVSDWN1cnJlbnRTdGF0dXMSKgoQZW5hYmxlZEJ5RGVmYXVsdBgDIAEoCFIQZW5hYmxlZEJ5'
    'RGVmYXVsdA==');

@$core.Deprecated('Use payloadDescriptor instead')
const Payload$json = {
  '1': 'Payload',
  '2': [
    {
      '1': 'listResponse',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ListResponse',
      '10': 'listResponse'
    },
    {
      '1': 'detailsResponse',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.DetailsResponse',
      '10': 'detailsResponse'
    },
    {
      '1': 'reviewResponse',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.ReviewResponse',
      '10': 'reviewResponse'
    },
    {
      '1': 'buyResponse',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.BuyResponse',
      '10': 'buyResponse'
    },
    {
      '1': 'searchResponse',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.SearchResponse',
      '10': 'searchResponse'
    },
    {
      '1': 'tocResponse',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.TocResponse',
      '10': 'tocResponse'
    },
    {
      '1': 'browseResponse',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.BrowseResponse',
      '10': 'browseResponse'
    },
    {
      '1': 'purchaseStatusResponse',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.PurchaseStatusResponse',
      '10': 'purchaseStatusResponse'
    },
    {'1': 'logResponse', '3': 10, '4': 1, '5': 9, '10': 'logResponse'},
    {
      '1': 'flagContentResponse',
      '3': 13,
      '4': 1,
      '5': 9,
      '10': 'flagContentResponse'
    },
    {
      '1': 'bulkDetailsResponse',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.BulkDetailsResponse',
      '10': 'bulkDetailsResponse'
    },
    {
      '1': 'deliveryResponse',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.DeliveryResponse',
      '10': 'deliveryResponse'
    },
    {
      '1': 'acceptTosResponse',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.AcceptTosResponse',
      '10': 'acceptTosResponse'
    },
    {
      '1': 'checkPromoOfferResponse',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.CheckPromoOfferResponse',
      '10': 'checkPromoOfferResponse'
    },
    {
      '1': 'instrumentSetupInfoResponse',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.InstrumentSetupInfoResponse',
      '10': 'instrumentSetupInfoResponse'
    },
    {
      '1': 'androidCheckinResponse',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.AndroidCheckinResponse',
      '10': 'androidCheckinResponse'
    },
    {
      '1': 'uploadDeviceConfigResponse',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.UploadDeviceConfigResponse',
      '10': 'uploadDeviceConfigResponse'
    },
    {
      '1': 'searchSuggestResponse',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.SearchSuggestResponse',
      '10': 'searchSuggestResponse'
    },
    {
      '1': 'consumePurchaseResponse',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.ConsumePurchaseResponse',
      '10': 'consumePurchaseResponse'
    },
    {
      '1': 'billingProfileResponse',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.BillingProfileResponse',
      '10': 'billingProfileResponse'
    },
    {
      '1': 'debugSettingsResponse',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.DebugSettingsResponse',
      '10': 'debugSettingsResponse'
    },
    {
      '1': 'checkIabPromoResponse',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.CheckIabPromoResponse',
      '10': 'checkIabPromoResponse'
    },
    {
      '1': 'userActivitySettingsResponse',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.UserActivitySettingsResponse',
      '10': 'userActivitySettingsResponse'
    },
    {
      '1': 'recordUserActivityResponse',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.RecordUserActivityResponse',
      '10': 'recordUserActivityResponse'
    },
    {
      '1': 'redeemCodeResponse',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.RedeemCodeResponse',
      '10': 'redeemCodeResponse'
    },
    {
      '1': 'selfUpdateResponse',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.SelfUpdateResponse',
      '10': 'selfUpdateResponse'
    },
    {
      '1': 'getInitialInstrumentFlowStateResponse',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.GetInitialInstrumentFlowStateResponse',
      '10': 'getInitialInstrumentFlowStateResponse'
    },
    {
      '1': 'createInstrumentResponse',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.CreateInstrumentResponse',
      '10': 'createInstrumentResponse'
    },
    {
      '1': 'challengeResponse',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.ChallengeResponse',
      '10': 'challengeResponse'
    },
    {
      '1': 'backupDeviceChoicesResponse',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.BackDeviceChoicesResponse',
      '10': 'backupDeviceChoicesResponse'
    },
    {
      '1': 'backupDocumentChoicesResponse',
      '3': 45,
      '4': 1,
      '5': 11,
      '6': '.BackupDocumentChoicesResponse',
      '10': 'backupDocumentChoicesResponse'
    },
    {
      '1': 'earlyUpdateResponse',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.EarlyUpdateResponse',
      '10': 'earlyUpdateResponse'
    },
    {
      '1': 'preloadsResponse',
      '3': 47,
      '4': 1,
      '5': 11,
      '6': '.PreloadsResponse',
      '10': 'preloadsResponse'
    },
    {
      '1': 'myAccountsResponse',
      '3': 48,
      '4': 1,
      '5': 11,
      '6': '.MyAccountsResponse',
      '10': 'myAccountsResponse'
    },
    {
      '1': 'contentFilterResponse',
      '3': 49,
      '4': 1,
      '5': 11,
      '6': '.ContentFilterResponse',
      '10': 'contentFilterResponse'
    },
    {
      '1': 'experimentsResponse',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.ExperimentsResponse',
      '10': 'experimentsResponse'
    },
    {
      '1': 'surveyResponse',
      '3': 51,
      '4': 1,
      '5': 11,
      '6': '.SurveyResponse',
      '10': 'surveyResponse'
    },
    {
      '1': 'pingResponse',
      '3': 52,
      '4': 1,
      '5': 11,
      '6': '.PingResponse',
      '10': 'pingResponse'
    },
    {
      '1': 'updateUserSettingResponse',
      '3': 53,
      '4': 1,
      '5': 11,
      '6': '.UpdateUserSettingResponse',
      '10': 'updateUserSettingResponse'
    },
    {
      '1': 'getUserSettingsResponse',
      '3': 54,
      '4': 1,
      '5': 11,
      '6': '.GetUserSettingsResponse',
      '10': 'getUserSettingsResponse'
    },
    {
      '1': 'getSharingSettingsResponse',
      '3': 56,
      '4': 1,
      '5': 11,
      '6': '.GetSharingSettingsResponse',
      '10': 'getSharingSettingsResponse'
    },
    {
      '1': 'updateSharingSettingsResponse',
      '3': 57,
      '4': 1,
      '5': 11,
      '6': '.UpdateSharingSettingsResponse',
      '10': 'updateSharingSettingsResponse'
    },
    {
      '1': 'reviewSnippetsResponse',
      '3': 58,
      '4': 1,
      '5': 11,
      '6': '.ReviewSnippetsResponse',
      '10': 'reviewSnippetsResponse'
    },
    {
      '1': 'documentSharingStateResponse',
      '3': 59,
      '4': 1,
      '5': 11,
      '6': '.DocumentSharingStateResponse',
      '10': 'documentSharingStateResponse'
    },
    {
      '1': 'moduleDeliveryResponse',
      '3': 70,
      '4': 1,
      '5': 11,
      '6': '.ModuleDeliveryResponse',
      '10': 'moduleDeliveryResponse'
    },
    {
      '1': 'testingProgramResponse',
      '3': 80,
      '4': 1,
      '5': 11,
      '6': '.TestingProgramResponse',
      '10': 'testingProgramResponse'
    },
    {
      '1': 'reviewSummaryResponse',
      '3': 129,
      '4': 1,
      '5': 11,
      '6': '.ReviewResponse',
      '10': 'reviewSummaryResponse'
    },
  ],
};

/// Descriptor for `Payload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List payloadDescriptor = $convert.base64Decode(
    'CgdQYXlsb2FkEjEKDGxpc3RSZXNwb25zZRgBIAEoCzINLkxpc3RSZXNwb25zZVIMbGlzdFJlc3'
    'BvbnNlEjoKD2RldGFpbHNSZXNwb25zZRgCIAEoCzIQLkRldGFpbHNSZXNwb25zZVIPZGV0YWls'
    'c1Jlc3BvbnNlEjcKDnJldmlld1Jlc3BvbnNlGAMgASgLMg8uUmV2aWV3UmVzcG9uc2VSDnJldm'
    'lld1Jlc3BvbnNlEi4KC2J1eVJlc3BvbnNlGAQgASgLMgwuQnV5UmVzcG9uc2VSC2J1eVJlc3Bv'
    'bnNlEjcKDnNlYXJjaFJlc3BvbnNlGAUgASgLMg8uU2VhcmNoUmVzcG9uc2VSDnNlYXJjaFJlc3'
    'BvbnNlEi4KC3RvY1Jlc3BvbnNlGAYgASgLMgwuVG9jUmVzcG9uc2VSC3RvY1Jlc3BvbnNlEjcK'
    'DmJyb3dzZVJlc3BvbnNlGAcgASgLMg8uQnJvd3NlUmVzcG9uc2VSDmJyb3dzZVJlc3BvbnNlEk'
    '8KFnB1cmNoYXNlU3RhdHVzUmVzcG9uc2UYCCABKAsyFy5QdXJjaGFzZVN0YXR1c1Jlc3BvbnNl'
    'UhZwdXJjaGFzZVN0YXR1c1Jlc3BvbnNlEiAKC2xvZ1Jlc3BvbnNlGAogASgJUgtsb2dSZXNwb2'
    '5zZRIwChNmbGFnQ29udGVudFJlc3BvbnNlGA0gASgJUhNmbGFnQ29udGVudFJlc3BvbnNlEkYK'
    'E2J1bGtEZXRhaWxzUmVzcG9uc2UYEyABKAsyFC5CdWxrRGV0YWlsc1Jlc3BvbnNlUhNidWxrRG'
    'V0YWlsc1Jlc3BvbnNlEj0KEGRlbGl2ZXJ5UmVzcG9uc2UYFSABKAsyES5EZWxpdmVyeVJlc3Bv'
    'bnNlUhBkZWxpdmVyeVJlc3BvbnNlEkAKEWFjY2VwdFRvc1Jlc3BvbnNlGBYgASgLMhIuQWNjZX'
    'B0VG9zUmVzcG9uc2VSEWFjY2VwdFRvc1Jlc3BvbnNlElIKF2NoZWNrUHJvbW9PZmZlclJlc3Bv'
    'bnNlGBggASgLMhguQ2hlY2tQcm9tb09mZmVyUmVzcG9uc2VSF2NoZWNrUHJvbW9PZmZlclJlc3'
    'BvbnNlEl4KG2luc3RydW1lbnRTZXR1cEluZm9SZXNwb25zZRgZIAEoCzIcLkluc3RydW1lbnRT'
    'ZXR1cEluZm9SZXNwb25zZVIbaW5zdHJ1bWVudFNldHVwSW5mb1Jlc3BvbnNlEk8KFmFuZHJvaW'
    'RDaGVja2luUmVzcG9uc2UYGiABKAsyFy5BbmRyb2lkQ2hlY2tpblJlc3BvbnNlUhZhbmRyb2lk'
    'Q2hlY2tpblJlc3BvbnNlElsKGnVwbG9hZERldmljZUNvbmZpZ1Jlc3BvbnNlGBwgASgLMhsuVX'
    'Bsb2FkRGV2aWNlQ29uZmlnUmVzcG9uc2VSGnVwbG9hZERldmljZUNvbmZpZ1Jlc3BvbnNlEkwK'
    'FXNlYXJjaFN1Z2dlc3RSZXNwb25zZRgoIAEoCzIWLlNlYXJjaFN1Z2dlc3RSZXNwb25zZVIVc2'
    'VhcmNoU3VnZ2VzdFJlc3BvbnNlElIKF2NvbnN1bWVQdXJjaGFzZVJlc3BvbnNlGB4gASgLMhgu'
    'Q29uc3VtZVB1cmNoYXNlUmVzcG9uc2VSF2NvbnN1bWVQdXJjaGFzZVJlc3BvbnNlEk8KFmJpbG'
    'xpbmdQcm9maWxlUmVzcG9uc2UYHyABKAsyFy5CaWxsaW5nUHJvZmlsZVJlc3BvbnNlUhZiaWxs'
    'aW5nUHJvZmlsZVJlc3BvbnNlEkwKFWRlYnVnU2V0dGluZ3NSZXNwb25zZRgiIAEoCzIWLkRlYn'
    'VnU2V0dGluZ3NSZXNwb25zZVIVZGVidWdTZXR0aW5nc1Jlc3BvbnNlEkwKFWNoZWNrSWFiUHJv'
    'bW9SZXNwb25zZRgjIAEoCzIWLkNoZWNrSWFiUHJvbW9SZXNwb25zZVIVY2hlY2tJYWJQcm9tb1'
    'Jlc3BvbnNlEmEKHHVzZXJBY3Rpdml0eVNldHRpbmdzUmVzcG9uc2UYJCABKAsyHS5Vc2VyQWN0'
    'aXZpdHlTZXR0aW5nc1Jlc3BvbnNlUhx1c2VyQWN0aXZpdHlTZXR0aW5nc1Jlc3BvbnNlElsKGn'
    'JlY29yZFVzZXJBY3Rpdml0eVJlc3BvbnNlGCUgASgLMhsuUmVjb3JkVXNlckFjdGl2aXR5UmVz'
    'cG9uc2VSGnJlY29yZFVzZXJBY3Rpdml0eVJlc3BvbnNlEkMKEnJlZGVlbUNvZGVSZXNwb25zZR'
    'gmIAEoCzITLlJlZGVlbUNvZGVSZXNwb25zZVIScmVkZWVtQ29kZVJlc3BvbnNlEkMKEnNlbGZV'
    'cGRhdGVSZXNwb25zZRgnIAEoCzITLlNlbGZVcGRhdGVSZXNwb25zZVISc2VsZlVwZGF0ZVJlc3'
    'BvbnNlEnwKJWdldEluaXRpYWxJbnN0cnVtZW50Rmxvd1N0YXRlUmVzcG9uc2UYKSABKAsyJi5H'
    'ZXRJbml0aWFsSW5zdHJ1bWVudEZsb3dTdGF0ZVJlc3BvbnNlUiVnZXRJbml0aWFsSW5zdHJ1bW'
    'VudEZsb3dTdGF0ZVJlc3BvbnNlElUKGGNyZWF0ZUluc3RydW1lbnRSZXNwb25zZRgqIAEoCzIZ'
    'LkNyZWF0ZUluc3RydW1lbnRSZXNwb25zZVIYY3JlYXRlSW5zdHJ1bWVudFJlc3BvbnNlEkAKEW'
    'NoYWxsZW5nZVJlc3BvbnNlGCsgASgLMhIuQ2hhbGxlbmdlUmVzcG9uc2VSEWNoYWxsZW5nZVJl'
    'c3BvbnNlElwKG2JhY2t1cERldmljZUNob2ljZXNSZXNwb25zZRgsIAEoCzIaLkJhY2tEZXZpY2'
    'VDaG9pY2VzUmVzcG9uc2VSG2JhY2t1cERldmljZUNob2ljZXNSZXNwb25zZRJkCh1iYWNrdXBE'
    'b2N1bWVudENob2ljZXNSZXNwb25zZRgtIAEoCzIeLkJhY2t1cERvY3VtZW50Q2hvaWNlc1Jlc3'
    'BvbnNlUh1iYWNrdXBEb2N1bWVudENob2ljZXNSZXNwb25zZRJGChNlYXJseVVwZGF0ZVJlc3Bv'
    'bnNlGC4gASgLMhQuRWFybHlVcGRhdGVSZXNwb25zZVITZWFybHlVcGRhdGVSZXNwb25zZRI9Ch'
    'BwcmVsb2Fkc1Jlc3BvbnNlGC8gASgLMhEuUHJlbG9hZHNSZXNwb25zZVIQcHJlbG9hZHNSZXNw'
    'b25zZRJDChJteUFjY291bnRzUmVzcG9uc2UYMCABKAsyEy5NeUFjY291bnRzUmVzcG9uc2VSEm'
    '15QWNjb3VudHNSZXNwb25zZRJMChVjb250ZW50RmlsdGVyUmVzcG9uc2UYMSABKAsyFi5Db250'
    'ZW50RmlsdGVyUmVzcG9uc2VSFWNvbnRlbnRGaWx0ZXJSZXNwb25zZRJGChNleHBlcmltZW50c1'
    'Jlc3BvbnNlGDIgASgLMhQuRXhwZXJpbWVudHNSZXNwb25zZVITZXhwZXJpbWVudHNSZXNwb25z'
    'ZRI3Cg5zdXJ2ZXlSZXNwb25zZRgzIAEoCzIPLlN1cnZleVJlc3BvbnNlUg5zdXJ2ZXlSZXNwb2'
    '5zZRIxCgxwaW5nUmVzcG9uc2UYNCABKAsyDS5QaW5nUmVzcG9uc2VSDHBpbmdSZXNwb25zZRJY'
    'Chl1cGRhdGVVc2VyU2V0dGluZ1Jlc3BvbnNlGDUgASgLMhouVXBkYXRlVXNlclNldHRpbmdSZX'
    'Nwb25zZVIZdXBkYXRlVXNlclNldHRpbmdSZXNwb25zZRJSChdnZXRVc2VyU2V0dGluZ3NSZXNw'
    'b25zZRg2IAEoCzIYLkdldFVzZXJTZXR0aW5nc1Jlc3BvbnNlUhdnZXRVc2VyU2V0dGluZ3NSZX'
    'Nwb25zZRJbChpnZXRTaGFyaW5nU2V0dGluZ3NSZXNwb25zZRg4IAEoCzIbLkdldFNoYXJpbmdT'
    'ZXR0aW5nc1Jlc3BvbnNlUhpnZXRTaGFyaW5nU2V0dGluZ3NSZXNwb25zZRJkCh11cGRhdGVTaG'
    'FyaW5nU2V0dGluZ3NSZXNwb25zZRg5IAEoCzIeLlVwZGF0ZVNoYXJpbmdTZXR0aW5nc1Jlc3Bv'
    'bnNlUh11cGRhdGVTaGFyaW5nU2V0dGluZ3NSZXNwb25zZRJPChZyZXZpZXdTbmlwcGV0c1Jlc3'
    'BvbnNlGDogASgLMhcuUmV2aWV3U25pcHBldHNSZXNwb25zZVIWcmV2aWV3U25pcHBldHNSZXNw'
    'b25zZRJhChxkb2N1bWVudFNoYXJpbmdTdGF0ZVJlc3BvbnNlGDsgASgLMh0uRG9jdW1lbnRTaG'
    'FyaW5nU3RhdGVSZXNwb25zZVIcZG9jdW1lbnRTaGFyaW5nU3RhdGVSZXNwb25zZRJPChZtb2R1'
    'bGVEZWxpdmVyeVJlc3BvbnNlGEYgASgLMhcuTW9kdWxlRGVsaXZlcnlSZXNwb25zZVIWbW9kdW'
    'xlRGVsaXZlcnlSZXNwb25zZRJPChZ0ZXN0aW5nUHJvZ3JhbVJlc3BvbnNlGFAgASgLMhcuVGVz'
    'dGluZ1Byb2dyYW1SZXNwb25zZVIWdGVzdGluZ1Byb2dyYW1SZXNwb25zZRJGChVyZXZpZXdTdW'
    '1tYXJ5UmVzcG9uc2UYgQEgASgLMg8uUmV2aWV3UmVzcG9uc2VSFXJldmlld1N1bW1hcnlSZXNw'
    'b25zZQ==');

@$core.Deprecated('Use checkIabPromoResponseDescriptor instead')
const CheckIabPromoResponse$json = {
  '1': 'CheckIabPromoResponse',
};

/// Descriptor for `CheckIabPromoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkIabPromoResponseDescriptor =
    $convert.base64Decode('ChVDaGVja0lhYlByb21vUmVzcG9uc2U=');

@$core.Deprecated('Use userActivitySettingsResponseDescriptor instead')
const UserActivitySettingsResponse$json = {
  '1': 'UserActivitySettingsResponse',
};

/// Descriptor for `UserActivitySettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userActivitySettingsResponseDescriptor =
    $convert.base64Decode('ChxVc2VyQWN0aXZpdHlTZXR0aW5nc1Jlc3BvbnNl');

@$core.Deprecated('Use recordUserActivityResponseDescriptor instead')
const RecordUserActivityResponse$json = {
  '1': 'RecordUserActivityResponse',
};

/// Descriptor for `RecordUserActivityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordUserActivityResponseDescriptor =
    $convert.base64Decode('ChpSZWNvcmRVc2VyQWN0aXZpdHlSZXNwb25zZQ==');

@$core.Deprecated('Use redeemCodeResponseDescriptor instead')
const RedeemCodeResponse$json = {
  '1': 'RedeemCodeResponse',
};

/// Descriptor for `RedeemCodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List redeemCodeResponseDescriptor =
    $convert.base64Decode('ChJSZWRlZW1Db2RlUmVzcG9uc2U=');

@$core.Deprecated('Use selfUpdateResponseDescriptor instead')
const SelfUpdateResponse$json = {
  '1': 'SelfUpdateResponse',
};

/// Descriptor for `SelfUpdateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List selfUpdateResponseDescriptor =
    $convert.base64Decode('ChJTZWxmVXBkYXRlUmVzcG9uc2U=');

@$core.Deprecated('Use getInitialInstrumentFlowStateResponseDescriptor instead')
const GetInitialInstrumentFlowStateResponse$json = {
  '1': 'GetInitialInstrumentFlowStateResponse',
};

/// Descriptor for `GetInitialInstrumentFlowStateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInitialInstrumentFlowStateResponseDescriptor =
    $convert
        .base64Decode('CiVHZXRJbml0aWFsSW5zdHJ1bWVudEZsb3dTdGF0ZVJlc3BvbnNl');

@$core.Deprecated('Use createInstrumentResponseDescriptor instead')
const CreateInstrumentResponse$json = {
  '1': 'CreateInstrumentResponse',
};

/// Descriptor for `CreateInstrumentResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createInstrumentResponseDescriptor =
    $convert.base64Decode('ChhDcmVhdGVJbnN0cnVtZW50UmVzcG9uc2U=');

@$core.Deprecated('Use challengeResponseDescriptor instead')
const ChallengeResponse$json = {
  '1': 'ChallengeResponse',
};

/// Descriptor for `ChallengeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List challengeResponseDescriptor =
    $convert.base64Decode('ChFDaGFsbGVuZ2VSZXNwb25zZQ==');

@$core.Deprecated('Use backDeviceChoicesResponseDescriptor instead')
const BackDeviceChoicesResponse$json = {
  '1': 'BackDeviceChoicesResponse',
};

/// Descriptor for `BackDeviceChoicesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backDeviceChoicesResponseDescriptor =
    $convert.base64Decode('ChlCYWNrRGV2aWNlQ2hvaWNlc1Jlc3BvbnNl');

@$core.Deprecated('Use backupDocumentChoicesResponseDescriptor instead')
const BackupDocumentChoicesResponse$json = {
  '1': 'BackupDocumentChoicesResponse',
};

/// Descriptor for `BackupDocumentChoicesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backupDocumentChoicesResponseDescriptor =
    $convert.base64Decode('Ch1CYWNrdXBEb2N1bWVudENob2ljZXNSZXNwb25zZQ==');

@$core.Deprecated('Use earlyUpdateResponseDescriptor instead')
const EarlyUpdateResponse$json = {
  '1': 'EarlyUpdateResponse',
};

/// Descriptor for `EarlyUpdateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List earlyUpdateResponseDescriptor =
    $convert.base64Decode('ChNFYXJseVVwZGF0ZVJlc3BvbnNl');

@$core.Deprecated('Use preloadsResponseDescriptor instead')
const PreloadsResponse$json = {
  '1': 'PreloadsResponse',
  '2': [
    {
      '1': 'configPreload',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.PreloadsResponse.Preload',
      '10': 'configPreload'
    },
    {
      '1': 'appPreload',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.PreloadsResponse.Preload',
      '10': 'appPreload'
    },
  ],
  '3': [PreloadsResponse_Preload$json],
};

@$core.Deprecated('Use preloadsResponseDescriptor instead')
const PreloadsResponse_Preload$json = {
  '1': 'Preload',
  '2': [
    {'1': 'DocId', '3': 1, '4': 1, '5': 11, '6': '.DocId', '10': 'DocId'},
    {'1': 'versionCode', '3': 2, '4': 1, '5': 5, '10': 'versionCode'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'icon', '3': 4, '4': 1, '5': 11, '6': '.Image', '10': 'icon'},
    {'1': 'deliveryToken', '3': 5, '4': 1, '5': 9, '10': 'deliveryToken'},
    {'1': 'installLocation', '3': 6, '4': 1, '5': 5, '10': 'installLocation'},
    {'1': 'size', '3': 7, '4': 1, '5': 3, '10': 'size'},
  ],
};

/// Descriptor for `PreloadsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preloadsResponseDescriptor = $convert.base64Decode(
    'ChBQcmVsb2Fkc1Jlc3BvbnNlEj8KDWNvbmZpZ1ByZWxvYWQYASABKAsyGS5QcmVsb2Fkc1Jlc3'
    'BvbnNlLlByZWxvYWRSDWNvbmZpZ1ByZWxvYWQSOQoKYXBwUHJlbG9hZBgCIAMoCzIZLlByZWxv'
    'YWRzUmVzcG9uc2UuUHJlbG9hZFIKYXBwUHJlbG9hZBrfAQoHUHJlbG9hZBIcCgVEb2NJZBgBIA'
    'EoCzIGLkRvY0lkUgVEb2NJZBIgCgt2ZXJzaW9uQ29kZRgCIAEoBVILdmVyc2lvbkNvZGUSFAoF'
    'dGl0bGUYAyABKAlSBXRpdGxlEhoKBGljb24YBCABKAsyBi5JbWFnZVIEaWNvbhIkCg1kZWxpdm'
    'VyeVRva2VuGAUgASgJUg1kZWxpdmVyeVRva2VuEigKD2luc3RhbGxMb2NhdGlvbhgGIAEoBVIP'
    'aW5zdGFsbExvY2F0aW9uEhIKBHNpemUYByABKANSBHNpemU=');

@$core.Deprecated('Use myAccountsResponseDescriptor instead')
const MyAccountsResponse$json = {
  '1': 'MyAccountsResponse',
};

/// Descriptor for `MyAccountsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List myAccountsResponseDescriptor =
    $convert.base64Decode('ChJNeUFjY291bnRzUmVzcG9uc2U=');

@$core.Deprecated('Use contentFilterResponseDescriptor instead')
const ContentFilterResponse$json = {
  '1': 'ContentFilterResponse',
};

/// Descriptor for `ContentFilterResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contentFilterResponseDescriptor =
    $convert.base64Decode('ChVDb250ZW50RmlsdGVyUmVzcG9uc2U=');

@$core.Deprecated('Use experimentsResponseDescriptor instead')
const ExperimentsResponse$json = {
  '1': 'ExperimentsResponse',
};

/// Descriptor for `ExperimentsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List experimentsResponseDescriptor =
    $convert.base64Decode('ChNFeHBlcmltZW50c1Jlc3BvbnNl');

@$core.Deprecated('Use surveyResponseDescriptor instead')
const SurveyResponse$json = {
  '1': 'SurveyResponse',
};

/// Descriptor for `SurveyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List surveyResponseDescriptor =
    $convert.base64Decode('Cg5TdXJ2ZXlSZXNwb25zZQ==');

@$core.Deprecated('Use pingResponseDescriptor instead')
const PingResponse$json = {
  '1': 'PingResponse',
};

/// Descriptor for `PingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingResponseDescriptor =
    $convert.base64Decode('CgxQaW5nUmVzcG9uc2U=');

@$core.Deprecated('Use updateUserSettingResponseDescriptor instead')
const UpdateUserSettingResponse$json = {
  '1': 'UpdateUserSettingResponse',
};

/// Descriptor for `UpdateUserSettingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateUserSettingResponseDescriptor =
    $convert.base64Decode('ChlVcGRhdGVVc2VyU2V0dGluZ1Jlc3BvbnNl');

@$core.Deprecated('Use getUserSettingsResponseDescriptor instead')
const GetUserSettingsResponse$json = {
  '1': 'GetUserSettingsResponse',
};

/// Descriptor for `GetUserSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserSettingsResponseDescriptor =
    $convert.base64Decode('ChdHZXRVc2VyU2V0dGluZ3NSZXNwb25zZQ==');

@$core.Deprecated('Use getSharingSettingsResponseDescriptor instead')
const GetSharingSettingsResponse$json = {
  '1': 'GetSharingSettingsResponse',
};

/// Descriptor for `GetSharingSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSharingSettingsResponseDescriptor =
    $convert.base64Decode('ChpHZXRTaGFyaW5nU2V0dGluZ3NSZXNwb25zZQ==');

@$core.Deprecated('Use updateSharingSettingsResponseDescriptor instead')
const UpdateSharingSettingsResponse$json = {
  '1': 'UpdateSharingSettingsResponse',
};

/// Descriptor for `UpdateSharingSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateSharingSettingsResponseDescriptor =
    $convert.base64Decode('Ch1VcGRhdGVTaGFyaW5nU2V0dGluZ3NSZXNwb25zZQ==');

@$core.Deprecated('Use reviewSnippetsResponseDescriptor instead')
const ReviewSnippetsResponse$json = {
  '1': 'ReviewSnippetsResponse',
};

/// Descriptor for `ReviewSnippetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewSnippetsResponseDescriptor =
    $convert.base64Decode('ChZSZXZpZXdTbmlwcGV0c1Jlc3BvbnNl');

@$core.Deprecated('Use documentSharingStateResponseDescriptor instead')
const DocumentSharingStateResponse$json = {
  '1': 'DocumentSharingStateResponse',
};

/// Descriptor for `DocumentSharingStateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List documentSharingStateResponseDescriptor =
    $convert.base64Decode('ChxEb2N1bWVudFNoYXJpbmdTdGF0ZVJlc3BvbnNl');

@$core.Deprecated('Use moduleDeliveryResponseDescriptor instead')
const ModuleDeliveryResponse$json = {
  '1': 'ModuleDeliveryResponse',
};

/// Descriptor for `ModuleDeliveryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moduleDeliveryResponseDescriptor =
    $convert.base64Decode('ChZNb2R1bGVEZWxpdmVyeVJlc3BvbnNl');

@$core.Deprecated('Use preFetchDescriptor instead')
const PreFetch$json = {
  '1': 'PreFetch',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'response',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ResponseWrapper',
      '10': 'response'
    },
    {'1': 'etag', '3': 3, '4': 1, '5': 9, '10': 'etag'},
    {'1': 'ttl', '3': 4, '4': 1, '5': 3, '10': 'ttl'},
    {'1': 'softTtl', '3': 5, '4': 1, '5': 3, '10': 'softTtl'},
  ],
};

/// Descriptor for `PreFetch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List preFetchDescriptor = $convert.base64Decode(
    'CghQcmVGZXRjaBIQCgN1cmwYASABKAlSA3VybBIsCghyZXNwb25zZRgCIAEoCzIQLlJlc3Bvbn'
    'NlV3JhcHBlclIIcmVzcG9uc2USEgoEZXRhZxgDIAEoCVIEZXRhZxIQCgN0dGwYBCABKANSA3R0'
    'bBIYCgdzb2Z0VHRsGAUgASgDUgdzb2Z0VHRs');

@$core.Deprecated('Use serverMetadataDescriptor instead')
const ServerMetadata$json = {
  '1': 'ServerMetadata',
  '2': [
    {'1': 'latencyMillis', '3': 1, '4': 1, '5': 3, '10': 'latencyMillis'},
  ],
};

/// Descriptor for `ServerMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverMetadataDescriptor = $convert.base64Decode(
    'Cg5TZXJ2ZXJNZXRhZGF0YRIkCg1sYXRlbmN5TWlsbGlzGAEgASgDUg1sYXRlbmN5TWlsbGlz');

@$core.Deprecated('Use targetsDescriptor instead')
const Targets$json = {
  '1': 'Targets',
  '2': [
    {'1': 'targetId', '3': 1, '4': 3, '5': 3, '10': 'targetId'},
    {'1': 'signature', '3': 2, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `Targets`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List targetsDescriptor = $convert.base64Decode(
    'CgdUYXJnZXRzEhoKCHRhcmdldElkGAEgAygDUgh0YXJnZXRJZBIcCglzaWduYXR1cmUYAiABKA'
    'xSCXNpZ25hdHVyZQ==');

@$core.Deprecated('Use serverCookieDescriptor instead')
const ServerCookie$json = {
  '1': 'ServerCookie',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'token', '3': 2, '4': 1, '5': 12, '10': 'token'},
  ],
};

/// Descriptor for `ServerCookie`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverCookieDescriptor = $convert.base64Decode(
    'CgxTZXJ2ZXJDb29raWUSEgoEdHlwZRgBIAEoBVIEdHlwZRIUCgV0b2tlbhgCIAEoDFIFdG9rZW'
    '4=');

@$core.Deprecated('Use serverCookiesDescriptor instead')
const ServerCookies$json = {
  '1': 'ServerCookies',
  '2': [
    {
      '1': 'serverCookie',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ServerCookie',
      '10': 'serverCookie'
    },
  ],
};

/// Descriptor for `ServerCookies`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverCookiesDescriptor = $convert.base64Decode(
    'Cg1TZXJ2ZXJDb29raWVzEjEKDHNlcnZlckNvb2tpZRgBIAMoCzINLlNlcnZlckNvb2tpZVIMc2'
    'VydmVyQ29va2ll');

@$core.Deprecated('Use responseWrapperDescriptor instead')
const ResponseWrapper$json = {
  '1': 'ResponseWrapper',
  '2': [
    {'1': 'payload', '3': 1, '4': 1, '5': 11, '6': '.Payload', '10': 'payload'},
    {
      '1': 'commands',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ServerCommands',
      '10': 'commands'
    },
    {
      '1': 'preFetch',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.PreFetch',
      '10': 'preFetch'
    },
    {
      '1': 'notification',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.Notification',
      '10': 'notification'
    },
    {
      '1': 'serverMetadata',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.ServerMetadata',
      '10': 'serverMetadata'
    },
    {'1': 'targets', '3': 6, '4': 1, '5': 11, '6': '.Targets', '10': 'targets'},
    {
      '1': 'serverCookies',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.ServerCookies',
      '10': 'serverCookies'
    },
    {
      '1': 'serverLogsCookie',
      '3': 9,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
  ],
};

/// Descriptor for `ResponseWrapper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseWrapperDescriptor = $convert.base64Decode(
    'Cg9SZXNwb25zZVdyYXBwZXISIgoHcGF5bG9hZBgBIAEoCzIILlBheWxvYWRSB3BheWxvYWQSKw'
    'oIY29tbWFuZHMYAiABKAsyDy5TZXJ2ZXJDb21tYW5kc1IIY29tbWFuZHMSJQoIcHJlRmV0Y2gY'
    'AyABKAsyCS5QcmVGZXRjaFIIcHJlRmV0Y2gSMQoMbm90aWZpY2F0aW9uGAQgAygLMg0uTm90aW'
    'ZpY2F0aW9uUgxub3RpZmljYXRpb24SNwoOc2VydmVyTWV0YWRhdGEYBSABKAsyDy5TZXJ2ZXJN'
    'ZXRhZGF0YVIOc2VydmVyTWV0YWRhdGESIgoHdGFyZ2V0cxgGIAEoCzIILlRhcmdldHNSB3Rhcm'
    'dldHMSNAoNc2VydmVyQ29va2llcxgHIAEoCzIOLlNlcnZlckNvb2tpZXNSDXNlcnZlckNvb2tp'
    'ZXMSKgoQc2VydmVyTG9nc0Nvb2tpZRgJIAEoDFIQc2VydmVyTG9nc0Nvb2tpZQ==');

@$core.Deprecated('Use responseWrapperApiDescriptor instead')
const ResponseWrapperApi$json = {
  '1': 'ResponseWrapperApi',
  '2': [
    {
      '1': 'payload',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.PayloadApi',
      '10': 'payload'
    },
  ],
};

/// Descriptor for `ResponseWrapperApi`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseWrapperApiDescriptor = $convert.base64Decode(
    'ChJSZXNwb25zZVdyYXBwZXJBcGkSJQoHcGF5bG9hZBgBIAEoCzILLlBheWxvYWRBcGlSB3BheW'
    'xvYWQ=');

@$core.Deprecated('Use payloadApiDescriptor instead')
const PayloadApi$json = {
  '1': 'PayloadApi',
  '2': [
    {
      '1': 'userProfileResponse',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.UserProfileResponse',
      '10': 'userProfileResponse'
    },
  ],
};

/// Descriptor for `PayloadApi`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List payloadApiDescriptor = $convert.base64Decode(
    'CgpQYXlsb2FkQXBpEkYKE3VzZXJQcm9maWxlUmVzcG9uc2UYBSABKAsyFC5Vc2VyUHJvZmlsZV'
    'Jlc3BvbnNlUhN1c2VyUHJvZmlsZVJlc3BvbnNl');

@$core.Deprecated('Use userProfileResponseDescriptor instead')
const UserProfileResponse$json = {
  '1': 'UserProfileResponse',
  '2': [
    {
      '1': 'userProfile',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.UserProfile',
      '10': 'userProfile'
    },
  ],
};

/// Descriptor for `UserProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfileResponseDescriptor = $convert.base64Decode(
    'ChNVc2VyUHJvZmlsZVJlc3BvbnNlEi4KC3VzZXJQcm9maWxlGAEgASgLMgwuVXNlclByb2ZpbG'
    'VSC3VzZXJQcm9maWxl');

@$core.Deprecated('Use serverCommandsDescriptor instead')
const ServerCommands$json = {
  '1': 'ServerCommands',
  '2': [
    {'1': 'clearCache', '3': 1, '4': 1, '5': 8, '10': 'clearCache'},
    {
      '1': 'displayErrorMessage',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'displayErrorMessage'
    },
    {
      '1': 'logErrorStacktrace',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'logErrorStacktrace'
    },
  ],
};

/// Descriptor for `ServerCommands`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverCommandsDescriptor = $convert.base64Decode(
    'Cg5TZXJ2ZXJDb21tYW5kcxIeCgpjbGVhckNhY2hlGAEgASgIUgpjbGVhckNhY2hlEjAKE2Rpc3'
    'BsYXlFcnJvck1lc3NhZ2UYAiABKAlSE2Rpc3BsYXlFcnJvck1lc3NhZ2USLgoSbG9nRXJyb3JT'
    'dGFja3RyYWNlGAMgASgJUhJsb2dFcnJvclN0YWNrdHJhY2U=');

@$core.Deprecated('Use getReviewsResponseDescriptor instead')
const GetReviewsResponse$json = {
  '1': 'GetReviewsResponse',
  '2': [
    {'1': 'review', '3': 1, '4': 3, '5': 11, '6': '.Review', '10': 'review'},
    {'1': 'matchingCount', '3': 2, '4': 1, '5': 3, '10': 'matchingCount'},
  ],
};

/// Descriptor for `GetReviewsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getReviewsResponseDescriptor = $convert.base64Decode(
    'ChJHZXRSZXZpZXdzUmVzcG9uc2USHwoGcmV2aWV3GAEgAygLMgcuUmV2aWV3UgZyZXZpZXcSJA'
    'oNbWF0Y2hpbmdDb3VudBgCIAEoA1INbWF0Y2hpbmdDb3VudA==');

@$core.Deprecated('Use reviewDescriptor instead')
const Review$json = {
  '1': 'Review',
  '2': [
    {'1': 'authorName', '3': 1, '4': 1, '5': 9, '10': 'authorName'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'version', '3': 4, '4': 1, '5': 9, '10': 'version'},
    {'1': 'timestamp', '3': 5, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'starRating', '3': 6, '4': 1, '5': 5, '10': 'starRating'},
    {'1': 'title', '3': 7, '4': 1, '5': 9, '10': 'title'},
    {'1': 'comment', '3': 8, '4': 1, '5': 9, '10': 'comment'},
    {'1': 'commentId', '3': 9, '4': 1, '5': 9, '10': 'commentId'},
    {'1': 'deviceName', '3': 19, '4': 1, '5': 9, '10': 'deviceName'},
    {'1': 'replyText', '3': 29, '4': 1, '5': 9, '10': 'replyText'},
    {'1': 'replyTimeStamp', '3': 30, '4': 1, '5': 3, '10': 'replyTimeStamp'},
    {
      '1': 'author',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.ReviewAuthor',
      '10': 'author'
    },
    {
      '1': 'userProfile',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.UserProfile',
      '10': 'userProfile'
    },
    {
      '1': 'sentiment',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.Image',
      '10': 'sentiment'
    },
    {'1': 'helpfulCount', '3': 35, '4': 1, '5': 5, '10': 'helpfulCount'},
    {'1': 'thumbsUpCount', '3': 38, '4': 1, '5': 3, '10': 'thumbsUpCount'},
  ],
};

/// Descriptor for `Review`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewDescriptor = $convert.base64Decode(
    'CgZSZXZpZXcSHgoKYXV0aG9yTmFtZRgBIAEoCVIKYXV0aG9yTmFtZRIQCgN1cmwYAiABKAlSA3'
    'VybBIWCgZzb3VyY2UYAyABKAlSBnNvdXJjZRIYCgd2ZXJzaW9uGAQgASgJUgd2ZXJzaW9uEhwK'
    'CXRpbWVzdGFtcBgFIAEoA1IJdGltZXN0YW1wEh4KCnN0YXJSYXRpbmcYBiABKAVSCnN0YXJSYX'
    'RpbmcSFAoFdGl0bGUYByABKAlSBXRpdGxlEhgKB2NvbW1lbnQYCCABKAlSB2NvbW1lbnQSHAoJ'
    'Y29tbWVudElkGAkgASgJUgljb21tZW50SWQSHgoKZGV2aWNlTmFtZRgTIAEoCVIKZGV2aWNlTm'
    'FtZRIcCglyZXBseVRleHQYHSABKAlSCXJlcGx5VGV4dBImCg5yZXBseVRpbWVTdGFtcBgeIAEo'
    'A1IOcmVwbHlUaW1lU3RhbXASJQoGYXV0aG9yGB8gASgLMg0uUmV2aWV3QXV0aG9yUgZhdXRob3'
    'ISLgoLdXNlclByb2ZpbGUYISABKAsyDC5Vc2VyUHJvZmlsZVILdXNlclByb2ZpbGUSJAoJc2Vu'
    'dGltZW50GCIgASgLMgYuSW1hZ2VSCXNlbnRpbWVudBIiCgxoZWxwZnVsQ291bnQYIyABKAVSDG'
    'hlbHBmdWxDb3VudBIkCg10aHVtYnNVcENvdW50GCYgASgDUg10aHVtYnNVcENvdW50');

@$core.Deprecated('Use criticReviewsResponseDescriptor instead')
const CriticReviewsResponse$json = {
  '1': 'CriticReviewsResponse',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'image', '3': 2, '4': 1, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'totalNumReviews', '3': 3, '4': 1, '5': 13, '10': 'totalNumReviews'},
    {
      '1': 'percentFavorable',
      '3': 4,
      '4': 1,
      '5': 13,
      '10': 'percentFavorable'
    },
    {'1': 'sourceText', '3': 5, '4': 1, '5': 9, '10': 'sourceText'},
    {'1': 'source', '3': 6, '4': 1, '5': 11, '6': '.Link', '10': 'source'},
    {'1': 'review', '3': 7, '4': 3, '5': 11, '6': '.Review', '10': 'review'},
  ],
};

/// Descriptor for `CriticReviewsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List criticReviewsResponseDescriptor = $convert.base64Decode(
    'ChVDcml0aWNSZXZpZXdzUmVzcG9uc2USFAoFdGl0bGUYASABKAlSBXRpdGxlEhwKBWltYWdlGA'
    'IgASgLMgYuSW1hZ2VSBWltYWdlEigKD3RvdGFsTnVtUmV2aWV3cxgDIAEoDVIPdG90YWxOdW1S'
    'ZXZpZXdzEioKEHBlcmNlbnRGYXZvcmFibGUYBCABKA1SEHBlcmNlbnRGYXZvcmFibGUSHgoKc2'
    '91cmNlVGV4dBgFIAEoCVIKc291cmNlVGV4dBIdCgZzb3VyY2UYBiABKAsyBS5MaW5rUgZzb3Vy'
    'Y2USHwoGcmV2aWV3GAcgAygLMgcuUmV2aWV3UgZyZXZpZXc=');

@$core.Deprecated('Use reviewAuthorDescriptor instead')
const ReviewAuthor$json = {
  '1': 'ReviewAuthor',
  '2': [
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar', '3': 5, '4': 1, '5': 11, '6': '.Image', '10': 'avatar'},
  ],
};

/// Descriptor for `ReviewAuthor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewAuthorDescriptor = $convert.base64Decode(
    'CgxSZXZpZXdBdXRob3ISEgoEbmFtZRgCIAEoCVIEbmFtZRIeCgZhdmF0YXIYBSABKAsyBi5JbW'
    'FnZVIGYXZhdGFy');

@$core.Deprecated('Use userProfileDescriptor instead')
const UserProfile$json = {
  '1': 'UserProfile',
  '2': [
    {'1': 'profileId', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'personId', '3': 2, '4': 1, '5': 9, '10': 'personId'},
    {'1': 'profileType', '3': 3, '4': 1, '5': 5, '10': 'profileType'},
    {'1': 'personType', '3': 4, '4': 1, '5': 5, '10': 'personType'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
    {'1': 'image', '3': 10, '4': 3, '5': 11, '6': '.Image', '10': 'image'},
    {'1': 'profileUrl', '3': 19, '4': 1, '5': 9, '10': 'profileUrl'},
    {
      '1': 'profileDescription',
      '3': 22,
      '4': 1,
      '5': 9,
      '10': 'profileDescription'
    },
  ],
};

/// Descriptor for `UserProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userProfileDescriptor = $convert.base64Decode(
    'CgtVc2VyUHJvZmlsZRIcCglwcm9maWxlSWQYASABKAlSCXByb2ZpbGVJZBIaCghwZXJzb25JZB'
    'gCIAEoCVIIcGVyc29uSWQSIAoLcHJvZmlsZVR5cGUYAyABKAVSC3Byb2ZpbGVUeXBlEh4KCnBl'
    'cnNvblR5cGUYBCABKAVSCnBlcnNvblR5cGUSEgoEbmFtZRgFIAEoCVIEbmFtZRIcCgVpbWFnZR'
    'gKIAMoCzIGLkltYWdlUgVpbWFnZRIeCgpwcm9maWxlVXJsGBMgASgJUgpwcm9maWxlVXJsEi4K'
    'EnByb2ZpbGVEZXNjcmlwdGlvbhgWIAEoCVIScHJvZmlsZURlc2NyaXB0aW9u');

@$core.Deprecated('Use reviewResponseDescriptor instead')
const ReviewResponse$json = {
  '1': 'ReviewResponse',
  '2': [
    {
      '1': 'userReviewsResponse',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.GetReviewsResponse',
      '10': 'userReviewsResponse'
    },
    {'1': 'nextPageUrl', '3': 2, '4': 1, '5': 9, '10': 'nextPageUrl'},
    {
      '1': 'userReview',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.Review',
      '10': 'userReview'
    },
    {
      '1': 'suggestionsListUrl',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'suggestionsListUrl'
    },
    {
      '1': 'criticReviewsResponse',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CriticReviewsResponse',
      '10': 'criticReviewsResponse'
    },
  ],
};

/// Descriptor for `ReviewResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reviewResponseDescriptor = $convert.base64Decode(
    'Cg5SZXZpZXdSZXNwb25zZRJFChN1c2VyUmV2aWV3c1Jlc3BvbnNlGAEgASgLMhMuR2V0UmV2aW'
    'V3c1Jlc3BvbnNlUhN1c2VyUmV2aWV3c1Jlc3BvbnNlEiAKC25leHRQYWdlVXJsGAIgASgJUgtu'
    'ZXh0UGFnZVVybBInCgp1c2VyUmV2aWV3GAMgASgLMgcuUmV2aWV3Ugp1c2VyUmV2aWV3Ei4KEn'
    'N1Z2dlc3Rpb25zTGlzdFVybBgEIAEoCVISc3VnZ2VzdGlvbnNMaXN0VXJsEkwKFWNyaXRpY1Jl'
    'dmlld3NSZXNwb25zZRgFIAEoCzIWLkNyaXRpY1Jldmlld3NSZXNwb25zZVIVY3JpdGljUmV2aW'
    'V3c1Jlc3BvbnNl');

@$core.Deprecated('Use relatedSearchDescriptor instead')
const RelatedSearch$json = {
  '1': 'RelatedSearch',
  '2': [
    {'1': 'searchUrl', '3': 1, '4': 1, '5': 9, '10': 'searchUrl'},
    {'1': 'header', '3': 2, '4': 1, '5': 9, '10': 'header'},
    {'1': 'backendId', '3': 3, '4': 1, '5': 5, '10': 'backendId'},
    {'1': 'docType', '3': 4, '4': 1, '5': 5, '7': '1', '10': 'docType'},
    {'1': 'current', '3': 5, '4': 1, '5': 8, '10': 'current'},
  ],
};

/// Descriptor for `RelatedSearch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List relatedSearchDescriptor = $convert.base64Decode(
    'Cg1SZWxhdGVkU2VhcmNoEhwKCXNlYXJjaFVybBgBIAEoCVIJc2VhcmNoVXJsEhYKBmhlYWRlch'
    'gCIAEoCVIGaGVhZGVyEhwKCWJhY2tlbmRJZBgDIAEoBVIJYmFja2VuZElkEhsKB2RvY1R5cGUY'
    'BCABKAU6ATFSB2RvY1R5cGUSGAoHY3VycmVudBgFIAEoCFIHY3VycmVudA==');

@$core.Deprecated('Use searchResponseDescriptor instead')
const SearchResponse$json = {
  '1': 'SearchResponse',
  '2': [
    {'1': 'originalQuery', '3': 1, '4': 1, '5': 9, '10': 'originalQuery'},
    {'1': 'suggestedQuery', '3': 2, '4': 1, '5': 9, '10': 'suggestedQuery'},
    {'1': 'aggregateQuery', '3': 3, '4': 1, '5': 8, '10': 'aggregateQuery'},
    {'1': 'bucket', '3': 4, '4': 3, '5': 11, '6': '.Bucket', '10': 'bucket'},
    {'1': 'item', '3': 5, '4': 3, '5': 11, '6': '.Item', '10': 'item'},
    {
      '1': 'relatedSearch',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.RelatedSearch',
      '10': 'relatedSearch'
    },
    {
      '1': 'serverLogsCookie',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'serverLogsCookie'
    },
    {'1': 'fullPageReplaced', '3': 8, '4': 1, '5': 8, '10': 'fullPageReplaced'},
    {'1': 'containsSnow', '3': 9, '4': 1, '5': 8, '10': 'containsSnow'},
    {'1': 'nextPageUrl', '3': 10, '4': 1, '5': 9, '10': 'nextPageUrl'},
  ],
};

/// Descriptor for `SearchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchResponseDescriptor = $convert.base64Decode(
    'Cg5TZWFyY2hSZXNwb25zZRIkCg1vcmlnaW5hbFF1ZXJ5GAEgASgJUg1vcmlnaW5hbFF1ZXJ5Ei'
    'YKDnN1Z2dlc3RlZFF1ZXJ5GAIgASgJUg5zdWdnZXN0ZWRRdWVyeRImCg5hZ2dyZWdhdGVRdWVy'
    'eRgDIAEoCFIOYWdncmVnYXRlUXVlcnkSHwoGYnVja2V0GAQgAygLMgcuQnVja2V0UgZidWNrZX'
    'QSGQoEaXRlbRgFIAMoCzIFLkl0ZW1SBGl0ZW0SNAoNcmVsYXRlZFNlYXJjaBgGIAMoCzIOLlJl'
    'bGF0ZWRTZWFyY2hSDXJlbGF0ZWRTZWFyY2gSKgoQc2VydmVyTG9nc0Nvb2tpZRgHIAEoDFIQc2'
    'VydmVyTG9nc0Nvb2tpZRIqChBmdWxsUGFnZVJlcGxhY2VkGAggASgIUhBmdWxsUGFnZVJlcGxh'
    'Y2VkEiIKDGNvbnRhaW5zU25vdxgJIAEoCFIMY29udGFpbnNTbm93EiAKC25leHRQYWdlVXJsGA'
    'ogASgJUgtuZXh0UGFnZVVybA==');

@$core.Deprecated('Use searchSuggestResponseDescriptor instead')
const SearchSuggestResponse$json = {
  '1': 'SearchSuggestResponse',
  '2': [
    {
      '1': 'entry',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.SearchSuggestEntry',
      '10': 'entry'
    },
  ],
};

/// Descriptor for `SearchSuggestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchSuggestResponseDescriptor = $convert.base64Decode(
    'ChVTZWFyY2hTdWdnZXN0UmVzcG9uc2USKQoFZW50cnkYASADKAsyEy5TZWFyY2hTdWdnZXN0RW'
    '50cnlSBWVudHJ5');

@$core.Deprecated('Use searchSuggestEntryDescriptor instead')
const SearchSuggestEntry$json = {
  '1': 'SearchSuggestEntry',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 5, '10': 'type'},
    {'1': 'suggestedQuery', '3': 2, '4': 1, '5': 9, '10': 'suggestedQuery'},
    {
      '1': 'imageContainer',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.SearchSuggestEntry.ImageContainer',
      '10': 'imageContainer'
    },
    {'1': 'title', '3': 6, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'packageNameContainer',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.SearchSuggestEntry.PackageNameContainer',
      '10': 'packageNameContainer'
    },
  ],
  '3': [
    SearchSuggestEntry_ImageContainer$json,
    SearchSuggestEntry_PackageNameContainer$json
  ],
};

@$core.Deprecated('Use searchSuggestEntryDescriptor instead')
const SearchSuggestEntry_ImageContainer$json = {
  '1': 'ImageContainer',
  '2': [
    {'1': 'imageUrl', '3': 5, '4': 1, '5': 9, '10': 'imageUrl'},
  ],
};

@$core.Deprecated('Use searchSuggestEntryDescriptor instead')
const SearchSuggestEntry_PackageNameContainer$json = {
  '1': 'PackageNameContainer',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
  ],
};

/// Descriptor for `SearchSuggestEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchSuggestEntryDescriptor = $convert.base64Decode(
    'ChJTZWFyY2hTdWdnZXN0RW50cnkSEgoEdHlwZRgBIAEoBVIEdHlwZRImCg5zdWdnZXN0ZWRRdW'
    'VyeRgCIAEoCVIOc3VnZ2VzdGVkUXVlcnkSSgoOaW1hZ2VDb250YWluZXIYBSABKAsyIi5TZWFy'
    'Y2hTdWdnZXN0RW50cnkuSW1hZ2VDb250YWluZXJSDmltYWdlQ29udGFpbmVyEhQKBXRpdGxlGA'
    'YgASgJUgV0aXRsZRJcChRwYWNrYWdlTmFtZUNvbnRhaW5lchgIIAEoCzIoLlNlYXJjaFN1Z2dl'
    'c3RFbnRyeS5QYWNrYWdlTmFtZUNvbnRhaW5lclIUcGFja2FnZU5hbWVDb250YWluZXIaLAoOSW'
    '1hZ2VDb250YWluZXISGgoIaW1hZ2VVcmwYBSABKAlSCGltYWdlVXJsGjgKFFBhY2thZ2VOYW1l'
    'Q29udGFpbmVyEiAKC3BhY2thZ2VOYW1lGAEgASgJUgtwYWNrYWdlTmFtZQ==');

@$core.Deprecated('Use testingProgramResponseDescriptor instead')
const TestingProgramResponse$json = {
  '1': 'TestingProgramResponse',
  '2': [
    {
      '1': 'result',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.TestingProgramResult',
      '10': 'result'
    },
  ],
};

/// Descriptor for `TestingProgramResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testingProgramResponseDescriptor =
    $convert.base64Decode(
        'ChZUZXN0aW5nUHJvZ3JhbVJlc3BvbnNlEi0KBnJlc3VsdBgCIAEoCzIVLlRlc3RpbmdQcm9ncm'
        'FtUmVzdWx0UgZyZXN1bHQ=');

@$core.Deprecated('Use testingProgramResultDescriptor instead')
const TestingProgramResult$json = {
  '1': 'TestingProgramResult',
  '2': [
    {
      '1': 'details',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.TestingProgramDetails',
      '10': 'details'
    },
  ],
};

/// Descriptor for `TestingProgramResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testingProgramResultDescriptor = $convert.base64Decode(
    'ChRUZXN0aW5nUHJvZ3JhbVJlc3VsdBIwCgdkZXRhaWxzGAQgASgLMhYuVGVzdGluZ1Byb2dyYW'
    '1EZXRhaWxzUgdkZXRhaWxz');

@$core.Deprecated('Use testingProgramDetailsDescriptor instead')
const TestingProgramDetails$json = {
  '1': 'TestingProgramDetails',
  '2': [
    {'1': 'subscribed', '3': 2, '4': 1, '5': 8, '10': 'subscribed'},
    {'1': 'id', '3': 3, '4': 1, '5': 3, '10': 'id'},
    {'1': 'unsubscribed', '3': 4, '4': 1, '5': 8, '10': 'unsubscribed'},
  ],
};

/// Descriptor for `TestingProgramDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testingProgramDetailsDescriptor = $convert.base64Decode(
    'ChVUZXN0aW5nUHJvZ3JhbURldGFpbHMSHgoKc3Vic2NyaWJlZBgCIAEoCFIKc3Vic2NyaWJlZB'
    'IOCgJpZBgDIAEoA1ICaWQSIgoMdW5zdWJzY3JpYmVkGAQgASgIUgx1bnN1YnNjcmliZWQ=');

@$core.Deprecated('Use logRequestDescriptor instead')
const LogRequest$json = {
  '1': 'LogRequest',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'downloadConfirmationQuery',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'downloadConfirmationQuery'
    },
  ],
};

/// Descriptor for `LogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logRequestDescriptor = $convert.base64Decode(
    'CgpMb2dSZXF1ZXN0EhwKCXRpbWVzdGFtcBgBIAEoA1IJdGltZXN0YW1wEjwKGWRvd25sb2FkQ2'
    '9uZmlybWF0aW9uUXVlcnkYAiABKAlSGWRvd25sb2FkQ29uZmlybWF0aW9uUXVlcnk=');

@$core.Deprecated('Use testingProgramRequestDescriptor instead')
const TestingProgramRequest$json = {
  '1': 'TestingProgramRequest',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
    {'1': 'subscribe', '3': 2, '4': 1, '5': 8, '10': 'subscribe'},
  ],
};

/// Descriptor for `TestingProgramRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testingProgramRequestDescriptor = $convert.base64Decode(
    'ChVUZXN0aW5nUHJvZ3JhbVJlcXVlc3QSIAoLcGFja2FnZU5hbWUYASABKAlSC3BhY2thZ2VOYW'
    '1lEhwKCXN1YnNjcmliZRgCIAEoCFIJc3Vic2NyaWJl');

@$core.Deprecated('Use uploadDeviceConfigRequestDescriptor instead')
const UploadDeviceConfigRequest$json = {
  '1': 'UploadDeviceConfigRequest',
  '2': [
    {
      '1': 'deviceConfiguration',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.DeviceConfigurationProto',
      '10': 'deviceConfiguration'
    },
    {'1': 'manufacturer', '3': 2, '4': 1, '5': 9, '10': 'manufacturer'},
    {
      '1': 'gcmRegistrationId',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'gcmRegistrationId'
    },
  ],
};

/// Descriptor for `UploadDeviceConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadDeviceConfigRequestDescriptor = $convert.base64Decode(
    'ChlVcGxvYWREZXZpY2VDb25maWdSZXF1ZXN0EksKE2RldmljZUNvbmZpZ3VyYXRpb24YASABKA'
    'syGS5EZXZpY2VDb25maWd1cmF0aW9uUHJvdG9SE2RldmljZUNvbmZpZ3VyYXRpb24SIgoMbWFu'
    'dWZhY3R1cmVyGAIgASgJUgxtYW51ZmFjdHVyZXISLAoRZ2NtUmVnaXN0cmF0aW9uSWQYAyABKA'
    'lSEWdjbVJlZ2lzdHJhdGlvbklk');

@$core.Deprecated('Use uploadDeviceConfigResponseDescriptor instead')
const UploadDeviceConfigResponse$json = {
  '1': 'UploadDeviceConfigResponse',
  '2': [
    {
      '1': 'uploadDeviceConfigToken',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'uploadDeviceConfigToken'
    },
  ],
};

/// Descriptor for `UploadDeviceConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadDeviceConfigResponseDescriptor =
    $convert.base64Decode(
        'ChpVcGxvYWREZXZpY2VDb25maWdSZXNwb25zZRI4Chd1cGxvYWREZXZpY2VDb25maWdUb2tlbh'
        'gBIAEoCVIXdXBsb2FkRGV2aWNlQ29uZmlnVG9rZW4=');

@$core.Deprecated('Use androidCheckinRequestDescriptor instead')
const AndroidCheckinRequest$json = {
  '1': 'AndroidCheckinRequest',
  '2': [
    {'1': 'imei', '3': 1, '4': 1, '5': 9, '10': 'imei'},
    {'1': 'id', '3': 2, '4': 1, '5': 3, '7': '0', '10': 'id'},
    {'1': 'digest', '3': 3, '4': 1, '5': 9, '10': 'digest'},
    {
      '1': 'checkin',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.AndroidCheckinProto',
      '10': 'checkin'
    },
    {'1': 'desiredBuild', '3': 5, '4': 1, '5': 9, '10': 'desiredBuild'},
    {'1': 'locale', '3': 6, '4': 1, '5': 9, '10': 'locale'},
    {'1': 'loggingId', '3': 7, '4': 1, '5': 3, '10': 'loggingId'},
    {'1': 'marketCheckin', '3': 8, '4': 1, '5': 9, '10': 'marketCheckin'},
    {'1': 'macAddr', '3': 9, '4': 3, '5': 9, '10': 'macAddr'},
    {'1': 'meid', '3': 10, '4': 1, '5': 9, '10': 'meid'},
    {'1': 'accountCookie', '3': 11, '4': 3, '5': 9, '10': 'accountCookie'},
    {'1': 'timeZone', '3': 12, '4': 1, '5': 9, '10': 'timeZone'},
    {'1': 'securityToken', '3': 13, '4': 1, '5': 6, '10': 'securityToken'},
    {'1': 'version', '3': 14, '4': 1, '5': 5, '10': 'version'},
    {'1': 'otaCert', '3': 15, '4': 3, '5': 9, '10': 'otaCert'},
    {'1': 'serialNumber', '3': 16, '4': 1, '5': 9, '10': 'serialNumber'},
    {'1': 'esn', '3': 17, '4': 1, '5': 9, '10': 'esn'},
    {
      '1': 'deviceConfiguration',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.DeviceConfigurationProto',
      '10': 'deviceConfiguration'
    },
    {'1': 'macAddrType', '3': 19, '4': 3, '5': 9, '10': 'macAddrType'},
    {'1': 'fragment', '3': 20, '4': 1, '5': 5, '10': 'fragment'},
    {'1': 'userName', '3': 21, '4': 1, '5': 9, '10': 'userName'},
    {
      '1': 'userSerialNumber',
      '3': 22,
      '4': 1,
      '5': 5,
      '10': 'userSerialNumber'
    },
  ],
};

/// Descriptor for `AndroidCheckinRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidCheckinRequestDescriptor = $convert.base64Decode(
    'ChVBbmRyb2lkQ2hlY2tpblJlcXVlc3QSEgoEaW1laRgBIAEoCVIEaW1laRIRCgJpZBgCIAEoAz'
    'oBMFICaWQSFgoGZGlnZXN0GAMgASgJUgZkaWdlc3QSLgoHY2hlY2tpbhgEIAEoCzIULkFuZHJv'
    'aWRDaGVja2luUHJvdG9SB2NoZWNraW4SIgoMZGVzaXJlZEJ1aWxkGAUgASgJUgxkZXNpcmVkQn'
    'VpbGQSFgoGbG9jYWxlGAYgASgJUgZsb2NhbGUSHAoJbG9nZ2luZ0lkGAcgASgDUglsb2dnaW5n'
    'SWQSJAoNbWFya2V0Q2hlY2tpbhgIIAEoCVINbWFya2V0Q2hlY2tpbhIYCgdtYWNBZGRyGAkgAy'
    'gJUgdtYWNBZGRyEhIKBG1laWQYCiABKAlSBG1laWQSJAoNYWNjb3VudENvb2tpZRgLIAMoCVIN'
    'YWNjb3VudENvb2tpZRIaCgh0aW1lWm9uZRgMIAEoCVIIdGltZVpvbmUSJAoNc2VjdXJpdHlUb2'
    'tlbhgNIAEoBlINc2VjdXJpdHlUb2tlbhIYCgd2ZXJzaW9uGA4gASgFUgd2ZXJzaW9uEhgKB290'
    'YUNlcnQYDyADKAlSB290YUNlcnQSIgoMc2VyaWFsTnVtYmVyGBAgASgJUgxzZXJpYWxOdW1iZX'
    'ISEAoDZXNuGBEgASgJUgNlc24SSwoTZGV2aWNlQ29uZmlndXJhdGlvbhgSIAEoCzIZLkRldmlj'
    'ZUNvbmZpZ3VyYXRpb25Qcm90b1ITZGV2aWNlQ29uZmlndXJhdGlvbhIgCgttYWNBZGRyVHlwZR'
    'gTIAMoCVILbWFjQWRkclR5cGUSGgoIZnJhZ21lbnQYFCABKAVSCGZyYWdtZW50EhoKCHVzZXJO'
    'YW1lGBUgASgJUgh1c2VyTmFtZRIqChB1c2VyU2VyaWFsTnVtYmVyGBYgASgFUhB1c2VyU2VyaW'
    'FsTnVtYmVy');

@$core.Deprecated('Use androidCheckinResponseDescriptor instead')
const AndroidCheckinResponse$json = {
  '1': 'AndroidCheckinResponse',
  '2': [
    {'1': 'statsOk', '3': 1, '4': 1, '5': 8, '10': 'statsOk'},
    {
      '1': 'intent',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.AndroidIntentProto',
      '10': 'intent'
    },
    {'1': 'timeMsec', '3': 3, '4': 1, '5': 3, '10': 'timeMsec'},
    {'1': 'digest', '3': 4, '4': 1, '5': 9, '10': 'digest'},
    {
      '1': 'setting',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.GservicesSetting',
      '10': 'setting'
    },
    {'1': 'marketOk', '3': 6, '4': 1, '5': 8, '10': 'marketOk'},
    {'1': 'androidId', '3': 7, '4': 1, '5': 6, '10': 'androidId'},
    {'1': 'securityToken', '3': 8, '4': 1, '5': 6, '10': 'securityToken'},
    {'1': 'settingsDiff', '3': 9, '4': 1, '5': 8, '10': 'settingsDiff'},
    {'1': 'deleteSetting', '3': 10, '4': 3, '5': 9, '10': 'deleteSetting'},
    {
      '1': 'deviceCheckinConsistencyToken',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'deviceCheckinConsistencyToken'
    },
  ],
};

/// Descriptor for `AndroidCheckinResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidCheckinResponseDescriptor = $convert.base64Decode(
    'ChZBbmRyb2lkQ2hlY2tpblJlc3BvbnNlEhgKB3N0YXRzT2sYASABKAhSB3N0YXRzT2sSKwoGaW'
    '50ZW50GAIgAygLMhMuQW5kcm9pZEludGVudFByb3RvUgZpbnRlbnQSGgoIdGltZU1zZWMYAyAB'
    'KANSCHRpbWVNc2VjEhYKBmRpZ2VzdBgEIAEoCVIGZGlnZXN0EisKB3NldHRpbmcYBSADKAsyES'
    '5Hc2VydmljZXNTZXR0aW5nUgdzZXR0aW5nEhoKCG1hcmtldE9rGAYgASgIUghtYXJrZXRPaxIc'
    'CglhbmRyb2lkSWQYByABKAZSCWFuZHJvaWRJZBIkCg1zZWN1cml0eVRva2VuGAggASgGUg1zZW'
    'N1cml0eVRva2VuEiIKDHNldHRpbmdzRGlmZhgJIAEoCFIMc2V0dGluZ3NEaWZmEiQKDWRlbGV0'
    'ZVNldHRpbmcYCiADKAlSDWRlbGV0ZVNldHRpbmcSRAodZGV2aWNlQ2hlY2tpbkNvbnNpc3Rlbm'
    'N5VG9rZW4YDCABKAlSHWRldmljZUNoZWNraW5Db25zaXN0ZW5jeVRva2Vu');

@$core.Deprecated('Use gservicesSettingDescriptor instead')
const GservicesSetting$json = {
  '1': 'GservicesSetting',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 12, '10': 'name'},
    {'1': 'value', '3': 2, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `GservicesSetting`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gservicesSettingDescriptor = $convert.base64Decode(
    'ChBHc2VydmljZXNTZXR0aW5nEhIKBG5hbWUYASABKAxSBG5hbWUSFAoFdmFsdWUYAiABKAxSBX'
    'ZhbHVl');

@$core.Deprecated('Use androidBuildProtoDescriptor instead')
const AndroidBuildProto$json = {
  '1': 'AndroidBuildProto',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'product', '3': 2, '4': 1, '5': 9, '10': 'product'},
    {'1': 'carrier', '3': 3, '4': 1, '5': 9, '10': 'carrier'},
    {'1': 'radio', '3': 4, '4': 1, '5': 9, '10': 'radio'},
    {'1': 'bootloader', '3': 5, '4': 1, '5': 9, '10': 'bootloader'},
    {'1': 'client', '3': 6, '4': 1, '5': 9, '10': 'client'},
    {'1': 'timestamp', '3': 7, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'googleServices', '3': 8, '4': 1, '5': 5, '10': 'googleServices'},
    {'1': 'device', '3': 9, '4': 1, '5': 9, '10': 'device'},
    {'1': 'sdkVersion', '3': 10, '4': 1, '5': 5, '10': 'sdkVersion'},
    {'1': 'model', '3': 11, '4': 1, '5': 9, '10': 'model'},
    {'1': 'manufacturer', '3': 12, '4': 1, '5': 9, '10': 'manufacturer'},
    {'1': 'buildProduct', '3': 13, '4': 1, '5': 9, '10': 'buildProduct'},
    {'1': 'otaInstalled', '3': 14, '4': 1, '5': 8, '10': 'otaInstalled'},
  ],
};

/// Descriptor for `AndroidBuildProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidBuildProtoDescriptor = $convert.base64Decode(
    'ChFBbmRyb2lkQnVpbGRQcm90bxIOCgJpZBgBIAEoCVICaWQSGAoHcHJvZHVjdBgCIAEoCVIHcH'
    'JvZHVjdBIYCgdjYXJyaWVyGAMgASgJUgdjYXJyaWVyEhQKBXJhZGlvGAQgASgJUgVyYWRpbxIe'
    'Cgpib290bG9hZGVyGAUgASgJUgpib290bG9hZGVyEhYKBmNsaWVudBgGIAEoCVIGY2xpZW50Eh'
    'wKCXRpbWVzdGFtcBgHIAEoA1IJdGltZXN0YW1wEiYKDmdvb2dsZVNlcnZpY2VzGAggASgFUg5n'
    'b29nbGVTZXJ2aWNlcxIWCgZkZXZpY2UYCSABKAlSBmRldmljZRIeCgpzZGtWZXJzaW9uGAogAS'
    'gFUgpzZGtWZXJzaW9uEhQKBW1vZGVsGAsgASgJUgVtb2RlbBIiCgxtYW51ZmFjdHVyZXIYDCAB'
    'KAlSDG1hbnVmYWN0dXJlchIiCgxidWlsZFByb2R1Y3QYDSABKAlSDGJ1aWxkUHJvZHVjdBIiCg'
    'xvdGFJbnN0YWxsZWQYDiABKAhSDG90YUluc3RhbGxlZA==');

@$core.Deprecated('Use androidCheckinProtoDescriptor instead')
const AndroidCheckinProto$json = {
  '1': 'AndroidCheckinProto',
  '2': [
    {
      '1': 'build',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AndroidBuildProto',
      '10': 'build'
    },
    {'1': 'lastCheckinMsec', '3': 2, '4': 1, '5': 3, '10': 'lastCheckinMsec'},
    {
      '1': 'event',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.AndroidEventProto',
      '10': 'event'
    },
    {
      '1': 'stat',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.AndroidStatisticProto',
      '10': 'stat'
    },
    {'1': 'requestedGroup', '3': 5, '4': 3, '5': 9, '10': 'requestedGroup'},
    {'1': 'cellOperator', '3': 6, '4': 1, '5': 9, '10': 'cellOperator'},
    {'1': 'simOperator', '3': 7, '4': 1, '5': 9, '10': 'simOperator'},
    {'1': 'roaming', '3': 8, '4': 1, '5': 9, '10': 'roaming'},
    {'1': 'userNumber', '3': 9, '4': 1, '5': 5, '10': 'userNumber'},
  ],
};

/// Descriptor for `AndroidCheckinProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidCheckinProtoDescriptor = $convert.base64Decode(
    'ChNBbmRyb2lkQ2hlY2tpblByb3RvEigKBWJ1aWxkGAEgASgLMhIuQW5kcm9pZEJ1aWxkUHJvdG'
    '9SBWJ1aWxkEigKD2xhc3RDaGVja2luTXNlYxgCIAEoA1IPbGFzdENoZWNraW5Nc2VjEigKBWV2'
    'ZW50GAMgAygLMhIuQW5kcm9pZEV2ZW50UHJvdG9SBWV2ZW50EioKBHN0YXQYBCADKAsyFi5Bbm'
    'Ryb2lkU3RhdGlzdGljUHJvdG9SBHN0YXQSJgoOcmVxdWVzdGVkR3JvdXAYBSADKAlSDnJlcXVl'
    'c3RlZEdyb3VwEiIKDGNlbGxPcGVyYXRvchgGIAEoCVIMY2VsbE9wZXJhdG9yEiAKC3NpbU9wZX'
    'JhdG9yGAcgASgJUgtzaW1PcGVyYXRvchIYCgdyb2FtaW5nGAggASgJUgdyb2FtaW5nEh4KCnVz'
    'ZXJOdW1iZXIYCSABKAVSCnVzZXJOdW1iZXI=');

@$core.Deprecated('Use androidEventProtoDescriptor instead')
const AndroidEventProto$json = {
  '1': 'AndroidEventProto',
  '2': [
    {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    {'1': 'timeMsec', '3': 3, '4': 1, '5': 3, '10': 'timeMsec'},
  ],
};

/// Descriptor for `AndroidEventProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidEventProtoDescriptor = $convert.base64Decode(
    'ChFBbmRyb2lkRXZlbnRQcm90bxIQCgN0YWcYASABKAlSA3RhZxIUCgV2YWx1ZRgCIAEoCVIFdm'
    'FsdWUSGgoIdGltZU1zZWMYAyABKANSCHRpbWVNc2Vj');

@$core.Deprecated('Use androidIntentProtoDescriptor instead')
const AndroidIntentProto$json = {
  '1': 'AndroidIntentProto',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'dataUri', '3': 2, '4': 1, '5': 9, '10': 'dataUri'},
    {'1': 'mimeType', '3': 3, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'javaClass', '3': 4, '4': 1, '5': 9, '10': 'javaClass'},
    {
      '1': 'extra',
      '3': 5,
      '4': 3,
      '5': 10,
      '6': '.AndroidIntentProto.Extra',
      '10': 'extra'
    },
  ],
  '3': [AndroidIntentProto_Extra$json],
};

@$core.Deprecated('Use androidIntentProtoDescriptor instead')
const AndroidIntentProto_Extra$json = {
  '1': 'Extra',
  '2': [
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {'1': 'value', '3': 7, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `AndroidIntentProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidIntentProtoDescriptor = $convert.base64Decode(
    'ChJBbmRyb2lkSW50ZW50UHJvdG8SFgoGYWN0aW9uGAEgASgJUgZhY3Rpb24SGAoHZGF0YVVyaR'
    'gCIAEoCVIHZGF0YVVyaRIaCghtaW1lVHlwZRgDIAEoCVIIbWltZVR5cGUSHAoJamF2YUNsYXNz'
    'GAQgASgJUglqYXZhQ2xhc3MSLwoFZXh0cmEYBSADKAoyGS5BbmRyb2lkSW50ZW50UHJvdG8uRX'
    'h0cmFSBWV4dHJhGjEKBUV4dHJhEhIKBG5hbWUYBiABKAlSBG5hbWUSFAoFdmFsdWUYByABKAlS'
    'BXZhbHVl');

@$core.Deprecated('Use androidStatisticProtoDescriptor instead')
const AndroidStatisticProto$json = {
  '1': 'AndroidStatisticProto',
  '2': [
    {'1': 'tag', '3': 1, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'count', '3': 2, '4': 1, '5': 5, '10': 'count'},
    {'1': 'sum', '3': 3, '4': 1, '5': 2, '10': 'sum'},
  ],
};

/// Descriptor for `AndroidStatisticProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidStatisticProtoDescriptor = $convert.base64Decode(
    'ChVBbmRyb2lkU3RhdGlzdGljUHJvdG8SEAoDdGFnGAEgASgJUgN0YWcSFAoFY291bnQYAiABKA'
    'VSBWNvdW50EhAKA3N1bRgDIAEoAlIDc3Vt');

@$core.Deprecated('Use clientLibraryStateDescriptor instead')
const ClientLibraryState$json = {
  '1': 'ClientLibraryState',
  '2': [
    {'1': 'corpus', '3': 1, '4': 1, '5': 5, '10': 'corpus'},
    {'1': 'serverToken', '3': 2, '4': 1, '5': 12, '10': 'serverToken'},
    {'1': 'hashCodeSum', '3': 3, '4': 1, '5': 3, '10': 'hashCodeSum'},
    {'1': 'librarySize', '3': 4, '4': 1, '5': 5, '10': 'librarySize'},
    {'1': 'libraryId', '3': 5, '4': 1, '5': 9, '10': 'libraryId'},
  ],
};

/// Descriptor for `ClientLibraryState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientLibraryStateDescriptor = $convert.base64Decode(
    'ChJDbGllbnRMaWJyYXJ5U3RhdGUSFgoGY29ycHVzGAEgASgFUgZjb3JwdXMSIAoLc2VydmVyVG'
    '9rZW4YAiABKAxSC3NlcnZlclRva2VuEiAKC2hhc2hDb2RlU3VtGAMgASgDUgtoYXNoQ29kZVN1'
    'bRIgCgtsaWJyYXJ5U2l6ZRgEIAEoBVILbGlicmFyeVNpemUSHAoJbGlicmFyeUlkGAUgASgJUg'
    'lsaWJyYXJ5SWQ=');

@$core.Deprecated('Use androidDataUsageProtoDescriptor instead')
const AndroidDataUsageProto$json = {
  '1': 'AndroidDataUsageProto',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 5, '10': 'version'},
    {
      '1': 'currentReportMsec',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'currentReportMsec'
    },
    {
      '1': 'keyToPackageNameMapping',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.KeyToPackageNameMapping',
      '10': 'keyToPackageNameMapping'
    },
    {
      '1': 'payloadLevelAppStat',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.PayloadLevelAppStat',
      '10': 'payloadLevelAppStat'
    },
    {
      '1': 'ipLayerNetworkStat',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.IpLayerNetworkStat',
      '10': 'ipLayerNetworkStat'
    },
  ],
};

/// Descriptor for `AndroidDataUsageProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidDataUsageProtoDescriptor = $convert.base64Decode(
    'ChVBbmRyb2lkRGF0YVVzYWdlUHJvdG8SGAoHdmVyc2lvbhgBIAEoBVIHdmVyc2lvbhIsChFjdX'
    'JyZW50UmVwb3J0TXNlYxgCIAEoA1IRY3VycmVudFJlcG9ydE1zZWMSUgoXa2V5VG9QYWNrYWdl'
    'TmFtZU1hcHBpbmcYAyADKAsyGC5LZXlUb1BhY2thZ2VOYW1lTWFwcGluZ1IXa2V5VG9QYWNrYW'
    'dlTmFtZU1hcHBpbmcSRgoTcGF5bG9hZExldmVsQXBwU3RhdBgEIAMoCzIULlBheWxvYWRMZXZl'
    'bEFwcFN0YXRSE3BheWxvYWRMZXZlbEFwcFN0YXQSQwoSaXBMYXllck5ldHdvcmtTdGF0GAUgAy'
    'gLMhMuSXBMYXllck5ldHdvcmtTdGF0UhJpcExheWVyTmV0d29ya1N0YXQ=');

@$core.Deprecated('Use androidUsageStatsReportDescriptor instead')
const AndroidUsageStatsReport$json = {
  '1': 'AndroidUsageStatsReport',
  '2': [
    {'1': 'androidId', '3': 1, '4': 1, '5': 3, '10': 'androidId'},
    {'1': 'loggingId', '3': 2, '4': 1, '5': 3, '10': 'loggingId'},
    {
      '1': 'usageStats',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.UsageStatsExtensionProto',
      '10': 'usageStats'
    },
  ],
};

/// Descriptor for `AndroidUsageStatsReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List androidUsageStatsReportDescriptor = $convert.base64Decode(
    'ChdBbmRyb2lkVXNhZ2VTdGF0c1JlcG9ydBIcCglhbmRyb2lkSWQYASABKANSCWFuZHJvaWRJZB'
    'IcCglsb2dnaW5nSWQYAiABKANSCWxvZ2dpbmdJZBI5Cgp1c2FnZVN0YXRzGAMgASgLMhkuVXNh'
    'Z2VTdGF0c0V4dGVuc2lvblByb3RvUgp1c2FnZVN0YXRz');

@$core.Deprecated('Use appBucketDescriptor instead')
const AppBucket$json = {
  '1': 'AppBucket',
  '2': [
    {'1': 'bucketStartMsec', '3': 1, '4': 1, '5': 3, '10': 'bucketStartMsec'},
    {
      '1': 'bucketDurationMsec',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'bucketDurationMsec'
    },
    {
      '1': 'statCounters',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.StatCounters',
      '10': 'statCounters'
    },
    {'1': 'operationCount', '3': 4, '4': 1, '5': 3, '10': 'operationCount'},
  ],
};

/// Descriptor for `AppBucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appBucketDescriptor = $convert.base64Decode(
    'CglBcHBCdWNrZXQSKAoPYnVja2V0U3RhcnRNc2VjGAEgASgDUg9idWNrZXRTdGFydE1zZWMSLg'
    'oSYnVja2V0RHVyYXRpb25Nc2VjGAIgASgDUhJidWNrZXREdXJhdGlvbk1zZWMSMQoMc3RhdENv'
    'dW50ZXJzGAMgAygLMg0uU3RhdENvdW50ZXJzUgxzdGF0Q291bnRlcnMSJgoOb3BlcmF0aW9uQ2'
    '91bnQYBCABKANSDm9wZXJhdGlvbkNvdW50');

@$core.Deprecated('Use counterDataDescriptor instead')
const CounterData$json = {
  '1': 'CounterData',
  '2': [
    {'1': 'bytes', '3': 1, '4': 1, '5': 3, '10': 'bytes'},
    {'1': 'packets', '3': 2, '4': 1, '5': 3, '10': 'packets'},
  ],
};

/// Descriptor for `CounterData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List counterDataDescriptor = $convert.base64Decode(
    'CgtDb3VudGVyRGF0YRIUCgVieXRlcxgBIAEoA1IFYnl0ZXMSGAoHcGFja2V0cxgCIAEoA1IHcG'
    'Fja2V0cw==');

@$core.Deprecated('Use ipLayerAppStatDescriptor instead')
const IpLayerAppStat$json = {
  '1': 'IpLayerAppStat',
  '2': [
    {'1': 'packageKey', '3': 1, '4': 1, '5': 5, '10': 'packageKey'},
    {'1': 'applicationTag', '3': 2, '4': 1, '5': 5, '10': 'applicationTag'},
    {
      '1': 'ipLayerAppBucket',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.AppBucket',
      '10': 'ipLayerAppBucket'
    },
  ],
};

/// Descriptor for `IpLayerAppStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ipLayerAppStatDescriptor = $convert.base64Decode(
    'Cg5JcExheWVyQXBwU3RhdBIeCgpwYWNrYWdlS2V5GAEgASgFUgpwYWNrYWdlS2V5EiYKDmFwcG'
    'xpY2F0aW9uVGFnGAIgASgFUg5hcHBsaWNhdGlvblRhZxI2ChBpcExheWVyQXBwQnVja2V0GAMg'
    'AygLMgouQXBwQnVja2V0UhBpcExheWVyQXBwQnVja2V0');

@$core.Deprecated('Use ipLayerNetworkBucketDescriptor instead')
const IpLayerNetworkBucket$json = {
  '1': 'IpLayerNetworkBucket',
  '2': [
    {'1': 'bucketStartMsec', '3': 1, '4': 1, '5': 3, '10': 'bucketStartMsec'},
    {
      '1': 'bucketDurationMsec',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'bucketDurationMsec'
    },
    {
      '1': 'statCounters',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.StatCounters',
      '10': 'statCounters'
    },
    {
      '1': 'networkActiveDuration',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'networkActiveDuration'
    },
  ],
};

/// Descriptor for `IpLayerNetworkBucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ipLayerNetworkBucketDescriptor = $convert.base64Decode(
    'ChRJcExheWVyTmV0d29ya0J1Y2tldBIoCg9idWNrZXRTdGFydE1zZWMYASABKANSD2J1Y2tldF'
    'N0YXJ0TXNlYxIuChJidWNrZXREdXJhdGlvbk1zZWMYAiABKANSEmJ1Y2tldER1cmF0aW9uTXNl'
    'YxIxCgxzdGF0Q291bnRlcnMYAyADKAsyDS5TdGF0Q291bnRlcnNSDHN0YXRDb3VudGVycxI0Ch'
    'VuZXR3b3JrQWN0aXZlRHVyYXRpb24YBCABKANSFW5ldHdvcmtBY3RpdmVEdXJhdGlvbg==');

@$core.Deprecated('Use ipLayerNetworkStatDescriptor instead')
const IpLayerNetworkStat$json = {
  '1': 'IpLayerNetworkStat',
  '2': [
    {'1': 'networkDetails', '3': 1, '4': 1, '5': 9, '10': 'networkDetails'},
    {'1': 'type', '3': 2, '4': 1, '5': 5, '10': 'type'},
    {
      '1': 'ipLayerNetworkBucket',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.IpLayerNetworkBucket',
      '10': 'ipLayerNetworkBucket'
    },
    {
      '1': 'ipLayerAppStat',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.IpLayerAppStat',
      '10': 'ipLayerAppStat'
    },
  ],
};

/// Descriptor for `IpLayerNetworkStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ipLayerNetworkStatDescriptor = $convert.base64Decode(
    'ChJJcExheWVyTmV0d29ya1N0YXQSJgoObmV0d29ya0RldGFpbHMYASABKAlSDm5ldHdvcmtEZX'
    'RhaWxzEhIKBHR5cGUYAiABKAVSBHR5cGUSSQoUaXBMYXllck5ldHdvcmtCdWNrZXQYAyADKAsy'
    'FS5JcExheWVyTmV0d29ya0J1Y2tldFIUaXBMYXllck5ldHdvcmtCdWNrZXQSNwoOaXBMYXllck'
    'FwcFN0YXQYBCADKAsyDy5JcExheWVyQXBwU3RhdFIOaXBMYXllckFwcFN0YXQ=');

@$core.Deprecated('Use keyToPackageNameMappingDescriptor instead')
const KeyToPackageNameMapping$json = {
  '1': 'KeyToPackageNameMapping',
  '2': [
    {'1': 'packageKey', '3': 1, '4': 1, '5': 5, '10': 'packageKey'},
    {'1': 'uidName', '3': 2, '4': 1, '5': 9, '10': 'uidName'},
    {
      '1': 'sharedPackage',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.PackageInfo',
      '10': 'sharedPackage'
    },
  ],
};

/// Descriptor for `KeyToPackageNameMapping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyToPackageNameMappingDescriptor = $convert.base64Decode(
    'ChdLZXlUb1BhY2thZ2VOYW1lTWFwcGluZxIeCgpwYWNrYWdlS2V5GAEgASgFUgpwYWNrYWdlS2'
    'V5EhgKB3VpZE5hbWUYAiABKAlSB3VpZE5hbWUSMgoNc2hhcmVkUGFja2FnZRgDIAMoCzIMLlBh'
    'Y2thZ2VJbmZvUg1zaGFyZWRQYWNrYWdl');

@$core.Deprecated('Use packageInfoDescriptor instead')
const PackageInfo$json = {
  '1': 'PackageInfo',
  '2': [
    {'1': 'pkgName', '3': 1, '4': 1, '5': 9, '10': 'pkgName'},
    {'1': 'versionCode', '3': 2, '4': 1, '5': 5, '10': 'versionCode'},
  ],
};

/// Descriptor for `PackageInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List packageInfoDescriptor = $convert.base64Decode(
    'CgtQYWNrYWdlSW5mbxIYCgdwa2dOYW1lGAEgASgJUgdwa2dOYW1lEiAKC3ZlcnNpb25Db2RlGA'
    'IgASgFUgt2ZXJzaW9uQ29kZQ==');

@$core.Deprecated('Use payloadLevelAppStatDescriptor instead')
const PayloadLevelAppStat$json = {
  '1': 'PayloadLevelAppStat',
  '2': [
    {'1': 'packageKey', '3': 1, '4': 1, '5': 5, '10': 'packageKey'},
    {'1': 'applicationTag', '3': 2, '4': 1, '5': 5, '10': 'applicationTag'},
    {
      '1': 'payloadLevelAppBucket',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.AppBucket',
      '10': 'payloadLevelAppBucket'
    },
  ],
};

/// Descriptor for `PayloadLevelAppStat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List payloadLevelAppStatDescriptor = $convert.base64Decode(
    'ChNQYXlsb2FkTGV2ZWxBcHBTdGF0Eh4KCnBhY2thZ2VLZXkYASABKAVSCnBhY2thZ2VLZXkSJg'
    'oOYXBwbGljYXRpb25UYWcYAiABKAVSDmFwcGxpY2F0aW9uVGFnEkAKFXBheWxvYWRMZXZlbEFw'
    'cEJ1Y2tldBgDIAMoCzIKLkFwcEJ1Y2tldFIVcGF5bG9hZExldmVsQXBwQnVja2V0');

@$core.Deprecated('Use statCountersDescriptor instead')
const StatCounters$json = {
  '1': 'StatCounters',
  '2': [
    {'1': 'networkProto', '3': 1, '4': 1, '5': 5, '10': 'networkProto'},
    {'1': 'direction', '3': 2, '4': 1, '5': 5, '10': 'direction'},
    {
      '1': 'counterData',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CounterData',
      '10': 'counterData'
    },
    {'1': 'fgBg', '3': 4, '4': 1, '5': 5, '10': 'fgBg'},
  ],
};

/// Descriptor for `StatCounters`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statCountersDescriptor = $convert.base64Decode(
    'CgxTdGF0Q291bnRlcnMSIgoMbmV0d29ya1Byb3RvGAEgASgFUgxuZXR3b3JrUHJvdG8SHAoJZG'
    'lyZWN0aW9uGAIgASgFUglkaXJlY3Rpb24SLgoLY291bnRlckRhdGEYAyABKAsyDC5Db3VudGVy'
    'RGF0YVILY291bnRlckRhdGESEgoEZmdCZxgEIAEoBVIEZmdCZw==');

@$core.Deprecated('Use usageStatsExtensionProtoDescriptor instead')
const UsageStatsExtensionProto$json = {
  '1': 'UsageStatsExtensionProto',
  '2': [
    {
      '1': 'dataUsage',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AndroidDataUsageProto',
      '10': 'dataUsage'
    },
  ],
};

/// Descriptor for `UsageStatsExtensionProto`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List usageStatsExtensionProtoDescriptor =
    $convert.base64Decode(
        'ChhVc2FnZVN0YXRzRXh0ZW5zaW9uUHJvdG8SNAoJZGF0YVVzYWdlGAEgASgLMhYuQW5kcm9pZE'
        'RhdGFVc2FnZVByb3RvUglkYXRhVXNhZ2U=');

@$core.Deprecated('Use modifyLibraryRequestDescriptor instead')
const ModifyLibraryRequest$json = {
  '1': 'ModifyLibraryRequest',
  '2': [
    {'1': 'libraryId', '3': 1, '4': 1, '5': 9, '10': 'libraryId'},
    {'1': 'addPackageName', '3': 2, '4': 3, '5': 9, '10': 'addPackageName'},
    {
      '1': 'removePackageName',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'removePackageName'
    },
  ],
};

/// Descriptor for `ModifyLibraryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modifyLibraryRequestDescriptor = $convert.base64Decode(
    'ChRNb2RpZnlMaWJyYXJ5UmVxdWVzdBIcCglsaWJyYXJ5SWQYASABKAlSCWxpYnJhcnlJZBImCg'
    '5hZGRQYWNrYWdlTmFtZRgCIAMoCVIOYWRkUGFja2FnZU5hbWUSLAoRcmVtb3ZlUGFja2FnZU5h'
    'bWUYAyADKAlSEXJlbW92ZVBhY2thZ2VOYW1l');

@$core.Deprecated('Use serverResponseDescriptor instead')
const ServerResponse$json = {
  '1': 'ServerResponse',
  '2': [
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ServerResponse.Error',
      '10': 'error'
    },
  ],
  '3': [ServerResponse_Error$json],
};

@$core.Deprecated('Use serverResponseDescriptor instead')
const ServerResponse_Error$json = {
  '1': 'Error',
  '2': [
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverResponseDescriptor = $convert.base64Decode(
    'Cg5TZXJ2ZXJSZXNwb25zZRIrCgVlcnJvchgCIAEoCzIVLlNlcnZlclJlc3BvbnNlLkVycm9yUg'
    'VlcnJvchohCgVFcnJvchIYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdl');
