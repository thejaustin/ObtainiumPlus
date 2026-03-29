import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:obtainium/custom_errors.dart';
import 'package:obtainium/utils/crash_analytics.dart';
import 'package:obtainium/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wrapper for async operations with comprehensive error handling
class SafeAsync {
  /// Execute async operation with automatic error handling and logging
  static Future<T?> run<T>({
    required Future<T> Function() operation,
    required String operationName,
    Function(dynamic error, StackTrace? stack)? onError,
    Function(T result)? onSuccess,
    bool logToSentry = true,
    bool rethrow = false,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      talker.debug('Operation completed successfully: $operationName');
      return result;
    } catch (e, stack) {
      // Log to talker
      talker.handle(e, stack, 'Operation failed: $operationName');

      // Log to crash analytics
      await CrashAnalytics.recordCrash(
        errorType: e.runtimeType.toString(),
        errorMessage: '$operationName: ${e.toString()}',
      );

      // Report to Sentry if requested
      if (logToSentry) {
        await Sentry.captureException(e, stackTrace: stack);
      }

      // Call custom error handler if provided
      onError?.call(e, stack);
      
      // Rethrow if requested
      if (rethrow) rethrow;
      
      return null;
    }
  }

  /// Execute sync operation with error handling
  static T? runSync<T>({
    required T Function() operation,
    required String operationName,
    Function(dynamic error)? onError,
    bool rethrow = false,
  }) {
    try {
      final result = operation();
      talker.debug('Sync operation completed successfully: $operationName');
      return result;
    } catch (e, stack) {
      talker.handle(e, stack, 'Sync operation failed: $operationName');
      onError?.call(e);
      if (rethrow) rethrow;
      return null;
    }
  }

  /// Wrap File operations with safe error handling
  static Future<Uint8List?> safeReadFile(File file, {String? label}) async {
    return run(
      operation: () async => await file.readAsBytes(),
      operationName: label ?? 'Read file: ${file.path}',
      onError: (e, _) {
        // File doesn't exist or is corrupted - delete if exists
        try {
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      },
    );
  }

  /// Wrap Directory operations with safe error handling
  static Future<bool> safeCreateDir(Directory dir, {bool recursive = false}) async {
    final result = await run(
      operation: () async {
        await dir.create(recursive: recursive);
        return true;
      },
      operationName: 'Create directory: ${dir.path}',
      rethrow: false,
    );
    return result ?? false;
  }

  /// Execute with timeout protection
  static Future<T?> withTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    required String operationName,
    T? defaultValue,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      talker.warning('$operationName timed out after ${timeout.inSeconds}s');
      await CrashAnalytics.recordCrash(
        errorType: 'TimeoutException',
        errorMessage: '$operationName timed out after ${timeout.inSeconds}s',
      );
      return defaultValue;
    } catch (e, stack) {
      talker.handle(e, stack, 'Operation failed: $operationName');
      await CrashAnalytics.recordCrash(
        errorType: e.runtimeType.toString(),
        errorMessage: '$operationName: ${e.toString()}',
      );
      if (e is! ObtainiumError || e.unexpected) {
        await Sentry.captureException(e, stackTrace: stack);
      }
      return defaultValue;
    }
  }

  /// Retry operation with exponential backoff
  static Future<T?> retry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt >= maxRetries) {
          talker.warning('$operationName failed after $maxRetries attempts: $e');
          await CrashAnalytics.recordCrash(
            errorType: e.runtimeType.toString(),
            errorMessage: '$operationName failed after $maxRetries attempts',
          );
          if (e is! ObtainiumError || (e is ObtainiumError && e.unexpected)) {
            await Sentry.captureException(e);
          }
          return null;
        }
        
        // Wait with exponential backoff
        final delay = baseDelay * (1 << attempt);
        await Future.delayed(delay);
      }
    }
    
    return null;
  }
}

/// Extension for safer Future operations
extension SafeFuture<T> on Future<T> {
  /// Catch errors without breaking the chain
  Future<T?> catchAndLog({
    required String operationName,
    Function(dynamic error, StackTrace? stack)? onError,
  }) async {
    try {
      return await this;
    } catch (e, stack) {
      talker.handle(e, stack, 'Operation failed: $operationName');
      await CrashAnalytics.recordCrash(
        errorType: e.runtimeType.toString(),
        errorMessage: '$operationName: ${e.toString()}',
      );
      if (e is! ObtainiumError || (e is ObtainiumError && e.unexpected)) {
        await Sentry.captureException(e, stackTrace: stack);
      }
      onError?.call(e, stack);
      return null;
    }
  }
}
