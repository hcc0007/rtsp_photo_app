import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_info.dart';

class PersonItem extends StatelessWidget {
  final PersonInfo personInfo;
  final VoidCallback? onTap;

  const PersonItem({
    super.key,
    required this.personInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 100,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade700, width: 1),
          color: _getBackgroundColor(), // 根据人员类型设置背景颜色
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // 背景图片
              CachedNetworkImage(
                imageUrl: _getImageUrl(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // 底部信息栏
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 性别图标
                        Icon(
                          _getGenderIcon(),
                          color: Colors.white,
                          size: 12,
                        ),
                        // 年龄信息
                        Text(
                          _getAgeText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 右上角状态指示器
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getImageUrl() {
    // 优先使用portraitImage的url，如果没有则使用panoramicImage
    if (personInfo.portraitImage.url.isNotEmpty) {
      return personInfo.portraitImage.url;
    } else if (personInfo.panoramicImage.url.isNotEmpty) {
      return personInfo.panoramicImage.url;
    }
    // 如果没有图片，返回空字符串，会显示错误占位符
    return '';
  }

  IconData _getGenderIcon() {
    final genderCode = personInfo.attrs['gender_code']?['value'] as String?;
    if (genderCode == 'MALE') {
      return Icons.male;
    } else if (genderCode == 'FEMALE') {
      return Icons.female;
    }
    return Icons.person;
  }

  String _getAgeText() {
    final ageLower = personInfo.attrs['age_lower_limit']?['value'] as String?;
    final ageUpper = personInfo.attrs['age_up_limit']?['value'] as String?;
    
    if (ageLower != null && ageUpper != null) {
      final lower = double.tryParse(ageLower)?.toInt();
      final upper = double.tryParse(ageUpper)?.toInt();
      if (lower != null && upper != null) {
        return '$lower-$upper';
      }
    }
    return '';
  }

  Color _getBackgroundColor() {
    // 根据recordType设置背景颜色
    switch (personInfo.recordType) {
      case 'portrait_stranger':
        return Colors.red.withValues(alpha: 0.3); // 陌生人 - 淡红色背景
      case 'portrait_known':
        return Colors.green.withValues(alpha: 0.3); // 已知人员 - 淡绿色背景
      default:
        return Colors.orange.withValues(alpha: 0.3); // 其他状态 - 淡橙色背景
    }
  }

  Color _getStatusColor() {
    // 根据recordType或其他状态信息返回不同的颜色
    switch (personInfo.recordType) {
      case 'portrait_stranger':
        return Colors.red; // 陌生人
      case 'portrait_known':
        return Colors.green; // 已知人员
      default:
        return Colors.orange; // 其他状态
    }
  }
} 