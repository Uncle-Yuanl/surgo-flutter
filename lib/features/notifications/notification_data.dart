import 'package:flutter/material.dart';

/// Existing prototype fixtures shared by the dropdown and all-notifications page.
/// No new messages, persistence, read status or backend is invented.
class SurgoNotification {
  const SurgoNotification(this.id, this.icon, this.titleZh, this.titleEn,
      this.detailZh, this.detailEn);
  final String id, titleZh, titleEn, detailZh, detailEn;
  final IconData icon;
  String title(bool zh) => zh ? titleZh : titleEn;
  String detail(bool zh) => zh ? detailZh : detailEn;
}

const surgoNotifications = [
  SurgoNotification(
      'mock-score',
      Icons.notifications_none,
      '模考成绩已更新',
      'Mock score updated',
      '阅读模考 7.0 · 10 分钟前',
      'Reading mock 7.0 · 10 min ago'),
  SurgoNotification(
      'daily-reminder',
      Icons.calendar_today_outlined,
      '今日训练提醒',
      'Today’s training reminder',
      '写作 Task 2 还剩 1 篇 · 1 小时前',
      '1 Task 2 essay left · 1 hour ago'),
  SurgoNotification(
      'weekly-report',
      Icons.person_outline,
      '学习周报已生成',
      'Weekly report ready',
      '本周训练 4 天 · 昨天',
      'Trained 4 days this week · Yesterday'),
];
