import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

final Logger _logger = Logger('SystemInfoService');

class SystemInfoService {
  static final SystemInfoService _instance = SystemInfoService._internal();
  factory SystemInfoService() => _instance;
  SystemInfoService._internal();

  /// 收集并记录系统信息
  Future<void> collectAndLogSystemInfo() async {
    _logger.info('开始收集系统信息...');
    
    try {
      final systemInfo = await _collectAllSystemInfo();
      _logger.info('系统信息: $systemInfo');
      _logger.info('系统信息收集完成');
    } catch (e, stackTrace) {
      _logger.severe('收集系统信息时发生错误', e, stackTrace);
    }
  }

  /// 收集所有系统信息并整合为一个字符串
  Future<String> _collectAllSystemInfo() async {
    final List<String> infoParts = [];
    
    try {
      // 收集网络信息
      final networkInfo = await _getNetworkInfo();
      infoParts.add('网络: $networkInfo');
      
      // 收集设备信息
      final deviceInfo = await _getDeviceInfo();
      infoParts.add('设备: $deviceInfo');
      
      // 收集应用信息
      final appInfo = await _getAppInfo();
      infoParts.add('应用: $appInfo');
      
      // 收集平台信息
      final platformInfo = _getPlatformInfo();
      infoParts.add('平台: $platformInfo');
      
    } catch (e) {
      infoParts.add('错误: $e');
    }
    
    return infoParts.join(' | ');
  }

  /// 获取网络信息
  Future<String> _getNetworkInfo() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      String connectionType = '未知';
      
      switch (connectivityResult) {
        case ConnectivityResult.mobile:
          connectionType = '移动网络';
          break;
        case ConnectivityResult.wifi:
          connectionType = 'WiFi';
          break;
        case ConnectivityResult.ethernet:
          connectionType = '以太网';
          break;
        case ConnectivityResult.vpn:
          connectionType = 'VPN';
          break;
        case ConnectivityResult.bluetooth:
          connectionType = '蓝牙';
          break;
        case ConnectivityResult.other:
          connectionType = '其他';
          break;
        case ConnectivityResult.none:
          connectionType = '无网络';
          break;
      }
      
      // 检查网络可达性
      bool isReachable = false;
      try {
        final result = await InternetAddress.lookup('google.com');
        isReachable = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (e) {
        isReachable = false;
      }
      
      return '$connectionType${isReachable ? '(可达)' : '(不可达)'}';
    } catch (e) {
      return '获取失败';
    }
  }

  /// 获取设备信息
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (iOS ${iosInfo.systemVersion})';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        return '${macOsInfo.computerName} (macOS ${macOsInfo.osRelease})';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return '${windowsInfo.computerName} (Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion})';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return '${linuxInfo.name} (${linuxInfo.version})';
      }
      
      return '未知设备';
    } catch (e) {
      return '获取失败';
    }
  }

  /// 获取应用信息
  Future<String> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final flutterVersion = const String.fromEnvironment('FLUTTER_VERSION', defaultValue: '未知');
      return '${packageInfo.appName} v${packageInfo.version} (Flutter $flutterVersion)';
    } catch (e) {
      return '获取失败';
    }
  }

  /// 获取平台信息
  String _getPlatformInfo() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion} (${Platform.localeName})';
    } catch (e) {
      return '获取失败';
    }
  }
} 