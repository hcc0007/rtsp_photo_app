import 'dart:io';
import 'dart:convert';

void main() async {
  print('开始测试推送数据...');
  
  // 模拟推送数据
  final testData = {
    'objectId': 'test_${DateTime.now().millisecondsSinceEpoch}',
    'createTime': DateTime.now().millisecondsSinceEpoch,
    'recordType': 'portrait_stranger',
    'name': 'Test Stranger',
    'serialNumber': 'test_serial_001',
    'eventId': 'test_event_001',
    'dataType': 'portrait',
    'platformType': 'test_platform',
    'portraitImage': {
      'url': 'https://via.placeholder.com/200x200/FF0000/FFFFFF?text=Test',
      'format': 'jpeg'
    },
    'panoramicImage': {
      'url': 'https://via.placeholder.com/400x300/00FF00/FFFFFF?text=Panoramic',
      'format': 'jpeg'
    },
    'capturedTime': DateTime.now().millisecondsSinceEpoch,
    'receivedTime': DateTime.now().millisecondsSinceEpoch,
    'viewInfo': {
      'viewed': 0,
      'confirmed': 0,
      'username': null,
      'operateTime': null
    },
    'score': 0.95,
    'deviceInfo': {
      'device': {
        'identifierId': 'test_device_001',
        'deviceName': 'Test Device',
        'deviceCode': 'TEST001',
        'platformIdentifierId': 'test_platform_001',
        'platformType': 'test',
        'deviceType': 'camera',
        'position': 'Test Position',
        'rtspAddress': 'rtsp://test.com/stream',
        'rtspDeputyAddress': null
      },
      'deviceGroup': {
        'identifierId': 'test_group_001',
        'name': 'Test Device Group',
        'mapUrl': null,
        'mapWidth': 0,
        'mapHeight': 0
      }
    },
    'taskInfo': {
      'task': {
        'taskId': 'test_task_001',
        'taskName': 'Test Task',
        'taskType': 'portrait',
        'detectType': 'portrait_detect'
      },
      'roi': {
        'ruleId': 'test_rule_001',
        'roiId': null,
        'roiNum': '',
        'roiName': '',
        'roiType': null,
        'extendJson': null,
        'verticeList': []
      }
    },
    'stackeds': [],
    'attrs': {},
    'particular': {
      'score': 0.95,
      'mask': '',
      'helmet': '',
      'associationId': '',
      'portraitDb': {
        'portraitDbId': 0,
        'identifierId': '',
        'libId': '',
        'libImportType': '',
        'featureDbId': '',
        'type': 0,
        'name': '',
        'enableState': 0,
        'activeState': 0,
        'activationTime': 0,
        'expirationTime': 0,
        'createTime': 0
      },
      'portrait': {
        'portraitId': null,
        'identifierId': null,
        'identity': null,
        'name': null,
        'gender': null,
        'phone': null,
        'company': null,
        'dept': null,
        'employeeNumber': null,
        'idNumber': null,
        'remark': null,
        'picUrl': null,
        'activationTime': null,
        'expirationTime': null,
        'activeState': null
      }
    },
    'applet': {
      'face': {
        'faceId': 'test_face_${DateTime.now().millisecondsSinceEpoch}',
        'attributes_with_score': {}
      }
    }
  };

  try {
    // 发送测试数据到本地服务器
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:8080/front/push'));
    request.headers.set('Content-Type', 'application/json; charset=utf-8');
    request.write(utf8.encode(jsonEncode(testData)));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('响应状态码: ${response.statusCode}');
    print('响应内容: $responseBody');
    
    if (response.statusCode == 200) {
      print('✅ 测试数据发送成功');
    } else {
      print('❌ 测试数据发送失败');
    }
    
    client.close();
  } catch (e) {
    print('❌ 发送测试数据时出错: $e');
  }
  
  print('测试完成');
} 