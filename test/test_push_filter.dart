import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtsp_photo_app/providers/push_provider.dart';
import 'package:rtsp_photo_app/models/push_data.dart';
import 'package:rtsp_photo_app/config/app_config.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '人脸推送过滤测试',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late PushProvider pushProvider;
  int testCounter = 0;

  @override
  void initState() {
    super.initState();
    pushProvider = PushProvider();
  }

  void _addTestData() {
    testCounter++;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final recordType = testCounter % 2 == 0 ? 'portrait_stranger' : 'portrait_known';
    
    // 创建测试数据
    final testData = PushData.fromJson({
      'imgUrl': 'https://picsum.photos/80/100?random=$testCounter',
      'name': '测试人员$testCounter',
      'serialNumber': 'test_serial_$testCounter',
      'objectId': 'test_object_$testCounter',
      'eventId': '',
      'dataType': 'OBJECT_FACE',
      'recordType': recordType,
      'platformType': 'LOCAL',
      'portraitImage': {
        'url': 'https://picsum.photos/80/100?random=$testCounter',
        'format': null
      },
      'panoramicImage': {
        'url': 'https://picsum.photos/400/300?random=$testCounter',
        'format': null
      },
      'capturedTime': currentTime,
      'receivedTime': currentTime,
      'createTime': currentTime,
      'viewInfo': {
        'viewed': 0,
        'confirmed': 0,
        'username': null,
        'operateTime': null
      },
      'score': 0,
      'deviceInfo': {
        'device': {
          'identifierId': 'test_device_$testCounter',
          'deviceName': '测试设备$testCounter',
          'deviceCode': 'TEST_DEVICE',
          'platformIdentifierId': 'test_platform',
          'platformType': 'LOCAL',
          'deviceType': 'CAMERA',
          'position': '[0,0]',
          'rtspAddress': 'rtsp://test.com/stream',
          'rtspDeputyAddress': ''
        },
        'deviceGroup': {
          'identifierId': 'test_group',
          'name': '测试设备组',
          'mapUrl': 'test/map',
          'mapWidth': 450,
          'mapHeight': 300
        }
      },
      'taskInfo': {
        'task': {
          'taskId': 'test_task_$testCounter',
          'taskName': '测试任务',
          'taskType': 'portrait',
          'detectType': 'portrait_tailing'
        },
        'roi': {
          'ruleId': '',
          'roiId': null,
          'roiNum': '',
          'roiName': '',
          'roiType': null,
          'extendJson': null,
          'verticeList': [
            {"x": 0, "y": 0},
            {"x": 1, "y": 0},
            {"x": 1, "y": 1},
            {"x": 0, "y": 1},
            {"x": 0, "y": 0}
          ]
        }
      },
      'stackeds': [
        {
          'width': 62,
          'top': 1040,
          'left': 721,
          'height': 40
        }
      ],
      'attrs': {
        'age_lower_limit': {'value': '25.0', 'score': 1},
        'age_up_limit': {'value': '35.0', 'score': 1},
        'gender_code': {'value': 'MALE', 'score': 0.99981314}
      },
      'particular': {
        'score': 0,
        'mask': 'NONE',
        'helmet': 'NONE',
        'associationId': '',
        'portraitDb': {
          'portraitDbId': 0,
          'identifierId': '',
          'libId': '',
          'libImportType': '',
          'featureDbId': '',
          'type': 0,
          'name': ''
        },
        'portrait': {
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
        'type': 1,
        'face': {
          'quality': 0.95155376,
          'rectangle': {
            'vertices': [
              {'x': 31, 'y': 20},
              {'x': 93, 'y': 60}
            ]
          },
          'track_id': 2977 + testCounter,
          'angle': {
            'yaw': -5.4852967,
            'pitch': 10.742178,
            'roll': -0.8645517
          },
          'landmarks': [],
          'attributes_with_score': {},
          'face_score': 0.6319155,
          'faceId': 'test_face_$testCounter'
        },
        'portrait_image_location': {
          'panoramic_image_size': {'width': 1920, 'height': 1080},
          'portrait_image_in_panoramic': {'vertices': []},
          'portrait_in_panoramic': {'vertices': []}
        },
        'object_id': 'test_object_$testCounter'
      }
    });
    
    pushProvider.addPushData(testData);
  }

  void _addSamePersonData() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    String faceId;
    String objectId;
    String name;
    String recordType;
    String imgUrl;
    
    if (pushProvider.pushData.isNotEmpty) {
      // 如果有现有数据，使用第一个数据的faceId
      final existingData = pushProvider.pushData.first;
      faceId = existingData.applet.face.faceId;
      objectId = existingData.objectId;
      name = existingData.name;
      recordType = existingData.recordType;
      imgUrl = existingData.imgUrl;
      print('使用现有数据的faceId: $faceId');
    } else {
      // 如果没有数据，使用固定的测试faceId
      faceId = 'test_face_same_person';
      objectId = 'test_object_same_person';
      name = '测试同一人';
      recordType = 'portrait_known';
      imgUrl = 'https://picsum.photos/80/100?random=same';
      print('使用固定测试faceId: $faceId');
    }
    
    // 创建相同人员的数据（使用相同的faceId）
    final samePersonData = PushData.fromJson({
      'imgUrl': imgUrl,
      'name': name,
      'serialNumber': 'test_serial_same',
      'objectId': objectId,
      'eventId': '',
      'dataType': 'OBJECT_FACE',
      'recordType': recordType,
      'platformType': 'LOCAL',
      'portraitImage': {
        'url': imgUrl,
        'format': null
      },
      'panoramicImage': {
        'url': 'https://picsum.photos/400/300?random=same',
        'format': null
      },
      'capturedTime': currentTime,
      'receivedTime': currentTime,
      'createTime': currentTime,
      'viewInfo': {
        'viewed': 0,
        'confirmed': 0,
        'username': null,
        'operateTime': null
      },
      'score': 0,
      'deviceInfo': {
        'device': {
          'identifierId': 'test_device_same',
          'deviceName': '测试设备',
          'deviceCode': 'TEST_DEVICE',
          'platformIdentifierId': 'test_platform',
          'platformType': 'LOCAL',
          'deviceType': 'CAMERA',
          'position': '[0,0]',
          'rtspAddress': 'rtsp://test.com/stream',
          'rtspDeputyAddress': ''
        },
        'deviceGroup': {
          'identifierId': 'test_group',
          'name': '测试设备组',
          'mapUrl': 'test/map',
          'mapWidth': 450,
          'mapHeight': 300
        }
      },
      'taskInfo': {
        'task': {
          'taskId': 'test_task_same',
          'taskName': '测试任务',
          'taskType': 'portrait',
          'detectType': 'portrait_tailing'
        },
        'roi': {
          'ruleId': '',
          'roiId': null,
          'roiNum': '',
          'roiName': '',
          'roiType': null,
          'extendJson': null,
          'verticeList': [
            {"x": 0, "y": 0},
            {"x": 1, "y": 0},
            {"x": 1, "y": 1},
            {"x": 0, "y": 1},
            {"x": 0, "y": 0}
          ]
        }
      },
      'stackeds': [
        {
          'width': 62,
          'top': 1040,
          'left': 721,
          'height': 40
        }
      ],
      'attrs': {
        'age_lower_limit': {'value': '25.0', 'score': 1},
        'age_up_limit': {'value': '35.0', 'score': 1},
        'gender_code': {'value': 'MALE', 'score': 0.99981314}
      },
      'particular': {
        'score': 0,
        'mask': 'NONE',
        'helmet': 'NONE',
        'associationId': '',
        'portraitDb': {
          'portraitDbId': 0,
          'identifierId': '',
          'libId': '',
          'libImportType': '',
          'featureDbId': '',
          'type': 0,
          'name': ''
        },
        'portrait': {
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
        'type': 1,
        'face': {
          'quality': 0.95155376,
          'rectangle': {
            'vertices': [
              {'x': 31, 'y': 20},
              {'x': 93, 'y': 60}
            ]
          },
          'track_id': 2977,
          'angle': {
            'yaw': -5.4852967,
            'pitch': 10.742178,
            'roll': -0.8645517
          },
          'landmarks': [],
          'attributes_with_score': {},
          'face_score': 0.6319155,
          'faceId': faceId // 使用相同的faceId
        },
        'portrait_image_location': {
          'panoramic_image_size': {'width': 1920, 'height': 1080},
          'portrait_image_in_panoramic': {'vertices': []},
          'portrait_in_panoramic': {'vertices': []}
        },
        'object_id': objectId
      }
    });
    
    pushProvider.addPushData(samePersonData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('人脸推送过滤测试'),
        backgroundColor: Colors.red[800],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[900]!,
              Colors.red[800]!,
              Colors.red[700]!,
            ],
          ),
        ),
        child: Column(
          children: [
            // 控制按钮
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _addTestData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[800],
                    ),
                    child: Text('添加新人脸'),
                  ),
                  ElevatedButton(
                    onPressed: _addSamePersonData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red[800],
                    ),
                    child: Text('添加同一个人'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      pushProvider.cleanupExpiredFilters();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('清理过滤记录'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      pushProvider.clearAllFilters();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('清空所有过滤'),
                  ),
                ],
              ),
            ),
            
            // 配置信息
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '配置信息:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '同一个人过滤时间: ${AppConfig.personFilterTimeWindow / 1000}秒',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    '已知人员显示时间: ${AppConfig.knownPersonDisplayTime / 1000}秒',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    '陌生人显示时间: ${AppConfig.strangerDisplayTime / 1000}秒',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '当前时间: ${DateTime.now()}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  Text(
                    '过滤记录数量: ${pushProvider.filterRecordCount}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  if (pushProvider.lastPersonTime.isNotEmpty) ...[
                    Text(
                      '过滤记录详情:',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    ...pushProvider.lastPersonTime.entries.take(3).map((entry) => Text(
                      '  ${entry.key}: ${DateTime.fromMillisecondsSinceEpoch(entry.value)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                    )),
                  ],
                  if (pushProvider.pushData.isNotEmpty) ...[
                    Text(
                      '最新人脸FaceId: ${pushProvider.pushData.first.applet.face.faceId}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                    Text(
                      '最新人脸时间: ${DateTime.fromMillisecondsSinceEpoch(pushProvider.pushData.first.capturedTime)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            
            // 人脸列表
            Expanded(
              child: ChangeNotifierProvider.value(
                value: pushProvider,
                child: Consumer<PushProvider>(
                  builder: (context, provider, child) {
                    if (provider.pushData.isEmpty) {
                      return Center(
                        child: Text(
                          '暂无数据，点击按钮添加测试数据',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: provider.pushData.length,
                      itemBuilder: (context, index) {
                        final data = provider.pushData[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '人脸 ${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'ObjectId: ${data.objectId}',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              Text(
                                'FaceId: ${data.applet.face.faceId}',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              Text(
                                '类型: ${data.recordType}',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                              Text(
                                '时间: ${DateTime.fromMillisecondsSinceEpoch(data.capturedTime)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    pushProvider.dispose();
    super.dispose();
  }
} 