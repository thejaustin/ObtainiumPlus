// This is a generated file - do not edit.
//
// Generated from AcquireApp.proto.

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

@$core.Deprecated('Use acquireRequestDescriptor instead')
const AcquireRequest$json = {
  '1': 'AcquireRequest',
  '2': [
    {
      '1': 'package',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AcquireRequest.Package',
      '10': 'package'
    },
    {'1': 'f8', '3': 8, '4': 1, '5': 11, '6': '.Field', '10': 'f8'},
    {
      '1': 'version',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.AcquireRequest.Version',
      '10': 'version'
    },
    {'1': 'offerType', '3': 13, '4': 1, '5': 13, '10': 'offerType'},
    {'1': 'f15', '3': 15, '4': 1, '5': 13, '10': 'f15'},
    {'1': 'nonce', '3': 22, '4': 1, '5': 9, '10': 'nonce'},
    {'1': 'f25', '3': 25, '4': 1, '5': 13, '10': 'f25'},
    {
      '1': 'm30',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.AcquireRequest.Message30',
      '10': 'm30'
    },
  ],
  '3': [
    AcquireRequest_Package$json,
    AcquireRequest_Version$json,
    AcquireRequest_Message30$json
  ],
};

@$core.Deprecated('Use acquireRequestDescriptor instead')
const AcquireRequest_Package$json = {
  '1': 'Package',
  '2': [
    {
      '1': 'payload',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AcquireRequest.Package.Payload',
      '10': 'payload'
    },
    {'1': 'f2', '3': 2, '4': 1, '5': 13, '10': 'f2'},
  ],
  '3': [AcquireRequest_Package_Payload$json],
};

@$core.Deprecated('Use acquireRequestDescriptor instead')
const AcquireRequest_Package_Payload$json = {
  '1': 'Payload',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
    {'1': 'f2', '3': 2, '4': 1, '5': 13, '10': 'f2'},
    {'1': 'f3', '3': 3, '4': 1, '5': 13, '10': 'f3'},
  ],
};

@$core.Deprecated('Use acquireRequestDescriptor instead')
const AcquireRequest_Version$json = {
  '1': 'Version',
  '2': [
    {'1': 'versionCode', '3': 1, '4': 1, '5': 4, '10': 'versionCode'},
    {'1': 'f3', '3': 3, '4': 1, '5': 13, '10': 'f3'},
  ],
};

@$core.Deprecated('Use acquireRequestDescriptor instead')
const AcquireRequest_Message30$json = {
  '1': 'Message30',
  '2': [
    {'1': 'f1', '3': 1, '4': 1, '5': 13, '10': 'f1'},
    {'1': 'f2', '3': 2, '4': 1, '5': 13, '10': 'f2'},
  ],
};

/// Descriptor for `AcquireRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acquireRequestDescriptor = $convert.base64Decode(
    'Cg5BY3F1aXJlUmVxdWVzdBIxCgdwYWNrYWdlGAEgASgLMhcuQWNxdWlyZVJlcXVlc3QuUGFja2'
    'FnZVIHcGFja2FnZRIWCgJmOBgIIAEoCzIGLkZpZWxkUgJmOBIxCgd2ZXJzaW9uGAwgASgLMhcu'
    'QWNxdWlyZVJlcXVlc3QuVmVyc2lvblIHdmVyc2lvbhIcCglvZmZlclR5cGUYDSABKA1SCW9mZm'
    'VyVHlwZRIQCgNmMTUYDyABKA1SA2YxNRIUCgVub25jZRgWIAEoCVIFbm9uY2USEAoDZjI1GBkg'
    'ASgNUgNmMjUSKwoDbTMwGB4gASgLMhkuQWNxdWlyZVJlcXVlc3QuTWVzc2FnZTMwUgNtMzAaoQ'
    'EKB1BhY2thZ2USOQoHcGF5bG9hZBgBIAEoCzIfLkFjcXVpcmVSZXF1ZXN0LlBhY2thZ2UuUGF5'
    'bG9hZFIHcGF5bG9hZBIOCgJmMhgCIAEoDVICZjIaSwoHUGF5bG9hZBIgCgtwYWNrYWdlTmFtZR'
    'gBIAEoCVILcGFja2FnZU5hbWUSDgoCZjIYAiABKA1SAmYyEg4KAmYzGAMgASgNUgJmMxo7CgdW'
    'ZXJzaW9uEiAKC3ZlcnNpb25Db2RlGAEgASgEUgt2ZXJzaW9uQ29kZRIOCgJmMxgDIAEoDVICZj'
    'MaKwoJTWVzc2FnZTMwEg4KAmYxGAEgASgNUgJmMRIOCgJmMhgCIAEoDVICZjI=');

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper$json = {
  '1': 'AcquireResponseWrapper',
  '2': [
    {
      '1': 'acquireResponse',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AcquireResponseWrapper.AcquireResponse',
      '10': 'acquireResponse'
    },
  ],
  '3': [AcquireResponseWrapper_AcquireResponse$json],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse$json = {
  '1': 'AcquireResponse',
  '2': [
    {
      '1': 'acquirePayload',
      '3': 94,
      '4': 1,
      '5': 11,
      '6': '.AcquireResponseWrapper.AcquireResponse.AcquirePayload',
      '10': 'acquirePayload'
    },
  ],
  '3': [
    AcquireResponseWrapper_AcquireResponse_AcquirePayload$json,
    AcquireResponseWrapper_AcquireResponse_Response$json
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload$json = {
  '1': 'AcquirePayload',
  '2': [
    {
      '1': 'purchase',
      '3': 3,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper',
      '10': 'purchase'
    },
    {
      '1': 'package',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package',
      '10': 'package'
    },
  ],
  '3': [
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper$json,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package$json
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper$json =
    {
  '1': 'PurchaseWrapper',
  '2': [
    {'1': 'status', '3': 7, '4': 1, '5': 5, '10': 'status'},
    {
      '1': 'm8',
      '3': 8,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Message8',
      '10': 'm8'
    },
    {'1': 'signature', '3': 9, '4': 1, '5': 9, '10': 'signature'},
    {
      '1': 'response',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.AcquireResponseWrapper.AcquireResponse.Response',
      '10': 'response'
    },
    {
      '1': 'gamePurchase',
      '3': 12,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase',
      '9': 0,
      '10': 'gamePurchase'
    },
    {
      '1': 'appPurchase',
      '3': 15,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase',
      '9': 0,
      '10': 'appPurchase'
    },
  ],
  '3': [
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase$json,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8$json,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing$json
  ],
  '8': [
    {'1': 'purchase'},
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase$json =
    {
  '1': 'Purchase',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {
      '1': 'properties',
      '3': 2,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase.Properties',
      '10': 'properties'
    },
  ],
  '3': [
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties$json,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry$json
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Properties$json =
    {
  '1': 'Properties',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.Purchase.Entry',
      '10': 'entries'
    },
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Purchase_Entry$json =
    {
  '1': 'Entry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'boolValue', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'boolValue'},
    {'1': 'intValue', '3': 4, '4': 1, '5': 5, '9': 0, '10': 'intValue'},
  ],
  '8': [
    {'1': 'data'},
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_Message8$json =
    {
  '1': 'Message8',
  '2': [
    {
      '1': 'someThings',
      '3': 1,
      '4': 3,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.PurchaseWrapper.SomeThing',
      '10': 'someThings'
    },
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_PurchaseWrapper_SomeThing$json =
    {
  '1': 'SomeThing',
  '2': [
    {'1': 'f1', '3': 1, '4': 1, '5': 5, '10': 'f1'},
    {'1': 'f2', '3': 2, '4': 1, '5': 5, '10': 'f2'},
    {'1': 'f3', '3': 3, '4': 1, '5': 11, '6': '.Field', '10': 'f3'},
    {'1': 'f4', '3': 4, '4': 1, '5': 11, '6': '.Field', '10': 'f4'},
    {'1': 'f6', '3': 6, '4': 1, '5': 9, '10': 'f6'},
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package$json = {
  '1': 'Package',
  '2': [
    {
      '1': 'payload',
      '3': 1,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.Payload',
      '10': 'payload'
    },
  ],
  '3': [
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload$json,
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo$json
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload$json =
    {
  '1': 'Payload',
  '2': [
    {
      '1': 'appInfo',
      '3': 1,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.AppInfo',
      '10': 'appInfo'
    },
    {
      '1': 'encodedPayload',
      '3': 2,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.Payload.EncodedPayload',
      '10': 'encodedPayload'
    },
    {
      '1': 'subPayload',
      '3': 5,
      '4': 1,
      '5': 11,
      '6':
          '.AcquireResponseWrapper.AcquireResponse.AcquirePayload.Package.Payload',
      '10': 'subPayload'
    },
  ],
  '3': [
    AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload$json
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_Payload_EncodedPayload$json =
    {
  '1': 'EncodedPayload',
  '2': [
    {'1': 'encoded', '3': 1, '4': 1, '5': 9, '10': 'encoded'},
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_AcquirePayload_Package_AppInfo$json =
    {
  '1': 'AppInfo',
  '2': [
    {'1': 'packageName', '3': 1, '4': 1, '5': 9, '10': 'packageName'},
    {'1': 'seven', '3': 2, '4': 1, '5': 4, '10': 'seven'},
  ],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 5, '10': 'status'},
    {
      '1': 'payload',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.AcquireResponseWrapper.AcquireResponse.Response.Payload',
      '10': 'payload'
    },
  ],
  '3': [AcquireResponseWrapper_AcquireResponse_Response_Payload$json],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_Response_Payload$json = {
  '1': 'Payload',
  '2': [
    {
      '1': 'data',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.AcquireResponseWrapper.AcquireResponse.Response.Payload.Data',
      '10': 'data'
    },
  ],
  '3': [AcquireResponseWrapper_AcquireResponse_Response_Payload_Data$json],
};

@$core.Deprecated('Use acquireResponseWrapperDescriptor instead')
const AcquireResponseWrapper_AcquireResponse_Response_Payload_Data$json = {
  '1': 'Data',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 5, '4': 1, '5': 5, '10': 'value'},
  ],
};

/// Descriptor for `AcquireResponseWrapper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List acquireResponseWrapperDescriptor = $convert.base64Decode(
    'ChZBY3F1aXJlUmVzcG9uc2VXcmFwcGVyElEKD2FjcXVpcmVSZXNwb25zZRgBIAEoCzInLkFjcX'
    'VpcmVSZXNwb25zZVdyYXBwZXIuQWNxdWlyZVJlc3BvbnNlUg9hY3F1aXJlUmVzcG9uc2Ua1xEK'
    'D0FjcXVpcmVSZXNwb25zZRJeCg5hY3F1aXJlUGF5bG9hZBheIAEoCzI2LkFjcXVpcmVSZXNwb2'
    '5zZVdyYXBwZXIuQWNxdWlyZVJlc3BvbnNlLkFjcXVpcmVQYXlsb2FkUg5hY3F1aXJlUGF5bG9h'
    'ZBrbDgoOQWNxdWlyZVBheWxvYWQSYgoIcHVyY2hhc2UYAyABKAsyRi5BY3F1aXJlUmVzcG9uc2'
    'VXcmFwcGVyLkFjcXVpcmVSZXNwb25zZS5BY3F1aXJlUGF5bG9hZC5QdXJjaGFzZVdyYXBwZXJS'
    'CHB1cmNoYXNlElgKB3BhY2thZ2UYBCABKAsyPi5BY3F1aXJlUmVzcG9uc2VXcmFwcGVyLkFjcX'
    'VpcmVSZXNwb25zZS5BY3F1aXJlUGF5bG9hZC5QYWNrYWdlUgdwYWNrYWdlGtgICg9QdXJjaGFz'
    'ZVdyYXBwZXISFgoGc3RhdHVzGAcgASgFUgZzdGF0dXMSXwoCbTgYCCABKAsyTy5BY3F1aXJlUm'
    'VzcG9uc2VXcmFwcGVyLkFjcXVpcmVSZXNwb25zZS5BY3F1aXJlUGF5bG9hZC5QdXJjaGFzZVdy'
    'YXBwZXIuTWVzc2FnZThSAm04EhwKCXNpZ25hdHVyZRgJIAEoCVIJc2lnbmF0dXJlEkwKCHJlc3'
    'BvbnNlGAogASgLMjAuQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3F1aXJlUmVzcG9uc2UuUmVz'
    'cG9uc2VSCHJlc3BvbnNlEnUKDGdhbWVQdXJjaGFzZRgMIAEoCzJPLkFjcXVpcmVSZXNwb25zZV'
    'dyYXBwZXIuQWNxdWlyZVJlc3BvbnNlLkFjcXVpcmVQYXlsb2FkLlB1cmNoYXNlV3JhcHBlci5Q'
    'dXJjaGFzZUgAUgxnYW1lUHVyY2hhc2UScwoLYXBwUHVyY2hhc2UYDyABKAsyTy5BY3F1aXJlUm'
    'VzcG9uc2VXcmFwcGVyLkFjcXVpcmVSZXNwb25zZS5BY3F1aXJlUGF5bG9hZC5QdXJjaGFzZVdy'
    'YXBwZXIuUHVyY2hhc2VIAFILYXBwUHVyY2hhc2Ua/AIKCFB1cmNoYXNlEhQKBWxhYmVsGAEgAS'
    'gJUgVsYWJlbBJ6Cgpwcm9wZXJ0aWVzGAIgASgLMlouQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5B'
    'Y3F1aXJlUmVzcG9uc2UuQWNxdWlyZVBheWxvYWQuUHVyY2hhc2VXcmFwcGVyLlB1cmNoYXNlLl'
    'Byb3BlcnRpZXNSCnByb3BlcnRpZXMafQoKUHJvcGVydGllcxJvCgdlbnRyaWVzGAEgAygLMlUu'
    'QWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3F1aXJlUmVzcG9uc2UuQWNxdWlyZVBheWxvYWQuUH'
    'VyY2hhc2VXcmFwcGVyLlB1cmNoYXNlLkVudHJ5UgdlbnRyaWVzGl8KBUVudHJ5EhAKA2tleRgB'
    'IAEoCVIDa2V5Eh4KCWJvb2xWYWx1ZRgCIAEoCUgAUglib29sVmFsdWUSHAoIaW50VmFsdWUYBC'
    'ABKAVIAFIIaW50VmFsdWVCBgoEZGF0YRp8CghNZXNzYWdlOBJwCgpzb21lVGhpbmdzGAEgAygL'
    'MlAuQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3F1aXJlUmVzcG9uc2UuQWNxdWlyZVBheWxvYW'
    'QuUHVyY2hhc2VXcmFwcGVyLlNvbWVUaGluZ1IKc29tZVRoaW5ncxprCglTb21lVGhpbmcSDgoC'
    'ZjEYASABKAVSAmYxEg4KAmYyGAIgASgFUgJmMhIWCgJmMxgDIAEoCzIGLkZpZWxkUgJmMxIWCg'
    'JmNBgEIAEoCzIGLkZpZWxkUgJmNBIOCgJmNhgGIAEoCVICZjZCCgoIcHVyY2hhc2UarwQKB1Bh'
    'Y2thZ2USYAoHcGF5bG9hZBgBIAEoCzJGLkFjcXVpcmVSZXNwb25zZVdyYXBwZXIuQWNxdWlyZV'
    'Jlc3BvbnNlLkFjcXVpcmVQYXlsb2FkLlBhY2thZ2UuUGF5bG9hZFIHcGF5bG9hZBr+AgoHUGF5'
    'bG9hZBJgCgdhcHBJbmZvGAEgASgLMkYuQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3F1aXJlUm'
    'VzcG9uc2UuQWNxdWlyZVBheWxvYWQuUGFja2FnZS5BcHBJbmZvUgdhcHBJbmZvEn0KDmVuY29k'
    'ZWRQYXlsb2FkGAIgASgLMlUuQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3F1aXJlUmVzcG9uc2'
    'UuQWNxdWlyZVBheWxvYWQuUGFja2FnZS5QYXlsb2FkLkVuY29kZWRQYXlsb2FkUg5lbmNvZGVk'
    'UGF5bG9hZBJmCgpzdWJQYXlsb2FkGAUgASgLMkYuQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3'
    'F1aXJlUmVzcG9uc2UuQWNxdWlyZVBheWxvYWQuUGFja2FnZS5QYXlsb2FkUgpzdWJQYXlsb2Fk'
    'GioKDkVuY29kZWRQYXlsb2FkEhgKB2VuY29kZWQYASABKAlSB2VuY29kZWQaQQoHQXBwSW5mbx'
    'IgCgtwYWNrYWdlTmFtZRgBIAEoCVILcGFja2FnZU5hbWUSFAoFc2V2ZW4YAiABKARSBXNldmVu'
    'GoUCCghSZXNwb25zZRIWCgZzdGF0dXMYASABKAVSBnN0YXR1cxJSCgdwYXlsb2FkGAIgASgLMj'
    'guQWNxdWlyZVJlc3BvbnNlV3JhcHBlci5BY3F1aXJlUmVzcG9uc2UuUmVzcG9uc2UuUGF5bG9h'
    'ZFIHcGF5bG9hZBqMAQoHUGF5bG9hZBJRCgRkYXRhGAEgASgLMj0uQWNxdWlyZVJlc3BvbnNlV3'
    'JhcHBlci5BY3F1aXJlUmVzcG9uc2UuUmVzcG9uc2UuUGF5bG9hZC5EYXRhUgRkYXRhGi4KBERh'
    'dGESEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYBSABKAVSBXZhbHVl');

@$core.Deprecated('Use fieldDescriptor instead')
const Field$json = {
  '1': 'Field',
};

/// Descriptor for `Field`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fieldDescriptor =
    $convert.base64Decode('CgVGaWVsZA==');
