import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/rtsp_player.dart';
import '../widgets/photo_gallery.dart';
import '../config/app_config.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String rtspUrl = AppConfig.defaultRtspUrl;
  String apiUrl = AppConfig.defaultApiUrl;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rtspUrl = prefs.getString('rtsp_url') ?? AppConfig.defaultRtspUrl;
      apiUrl = prefs.getString('api_url') ?? AppConfig.defaultApiUrl;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadSettings(); // 返回时重新加载设置
            },
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // RTSP视频流区域 - 占据屏幕上方60%
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800, width: 2),
                ),
                child: RtspPlayer(rtspUrl: rtspUrl),
              ),
            ),
            
            // 分隔线
            Container(
              height: 2,
              color: Colors.grey.shade800,
            ),
            
            // 照片展示区域 - 占据屏幕下方40%
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  border: Border.all(color: Colors.grey.shade800, width: 2),
                ),
                child: const PhotoGallery(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 