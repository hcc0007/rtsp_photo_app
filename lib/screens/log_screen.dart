import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rtsp_photo_app/config/app_config.dart';
import 'dart:async';
import '../utils/global_log_manager.dart';

class LogScreen extends StatefulWidget {
  static const String routeName = '/logs';
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  Timer? _refreshTimer;
  final GlobalLogManager _logManager = GlobalLogManager();
  String _selectedLevel = 'ALL';
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 定期刷新日志显示
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据过滤条件获取日志
    List<String> displayLogs;
    if (_searchKeyword.isNotEmpty) {
      displayLogs = _logManager.searchLogs(_searchKeyword);
    } else if (_selectedLevel != 'ALL') {
      displayLogs = _logManager.filterLogsByLevel(_selectedLevel);
    } else {
      displayLogs = _logManager.getLatestLogs(100);
    }
    
    final stats = _logManager.getLogStatistics();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志记录'),
        foregroundColor: Colors.white,
        backgroundColor: AppConfig.theme,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索日志',
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '过滤日志',
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '导出日志',
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: '生成示例日志',
            onPressed: _generateSampleLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '清空日志',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计信息
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Text('总日志: ${_logManager.logCount}'),
                    const Spacer(),
                    if (_searchKeyword.isNotEmpty)
                      Text('搜索: $_searchKeyword')
                    else if (_selectedLevel != 'ALL')
                      Text('过滤: $_selectedLevel')
                    else
                      const Text('显示最新100条'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (stats['ERROR'] != null)
                      Text('错误: ${stats['ERROR']} ', style: const TextStyle(color: Colors.red)),
                    if (stats['WARN'] != null)
                      Text('警告: ${stats['WARN']} ', style: const TextStyle(color: Colors.orange)),
                    if (stats['INFO'] != null)
                      Text('信息: ${stats['INFO']} ', style: const TextStyle(color: Colors.blue)),
                    if (stats['DEBUG'] != null)
                      Text('调试: ${stats['DEBUG']} ', style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          // 日志列表
          Expanded(
            child: ListView.builder(
              itemCount: displayLogs.length,
              itemBuilder: (context, index) {
                final log = displayLogs[index];
                Color textColor = Colors.black;
                
                if (log.contains('ERROR')) {
                  textColor = Colors.red;
                } else if (log.contains('WARN')) {
                  textColor = Colors.orange;
                } else if (log.contains('INFO')) {
                  textColor = Colors.blue;
                } else if (log.contains('DEBUG')) {
                  textColor = Colors.green;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _generateSampleLogs() {
    final logger = Logger('Sample');
    logger.finest('这是最详细的调试信息');
    logger.finer('这是较详细的调试信息');
    logger.fine('这是调试信息');
    logger.config('这是配置信息');
    logger.info('这是一般信息');
    logger.warning('这是警告信息');
    logger.severe('这是严重错误信息');

    // 生成一些错误日志
    try {
      throw Exception('这是一个模拟的错误');
    } catch (e, stackTrace) {
      logger.severe('捕获到异常', e, stackTrace);
    }
  }

  void _clearLogs() {
    setState(() {
      _logManager.clearLogs();
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索日志'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入搜索关键词',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchKeyword = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchKeyword = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('过滤日志'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('全部'),
              value: 'ALL',
              groupValue: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('错误'),
              value: 'ERROR',
              groupValue: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('警告'),
              value: 'WARN',
              groupValue: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('信息'),
              value: 'INFO',
              groupValue: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('调试'),
              value: 'DEBUG',
              groupValue: _selectedLevel,
              onChanged: (value) {
                setState(() {
                  _selectedLevel = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs() async {
    final filePath = await _logManager.exportLogs();
    if (filePath != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('日志已导出到: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导出日志失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
