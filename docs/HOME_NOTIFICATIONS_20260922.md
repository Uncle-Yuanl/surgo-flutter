# 首页与通知：2026-09-22 用户追加要求

这四项是用户明确要求的新设计/交互，不是H5原样迁移差异；后续视觉复核不得回退这些变更。原H5保持只读。

## 实现

- 首页插图：已有完整素材 `assets/images/otter6.png`，88×110、BoxFit.contain；与欢迎文字在同一Row，按钮放在下方，不再使用裁切素材/叠放遮挡。
- 金刚区六个入口标签：先10→14px，用户18:48反馈太大后缩小一号至13px；字重600、横向滚动区域110px不变。其他文字不随之缩小。
- 首页考试倒计时/目标分：正文10.5→13px；强调数字12.5→15px；正文颜色加深。
- 通知下拉：标题13→15px、说明10→13px、分组标题10→13px、查看全部12→14px。
- “查看全部”进入独立原生 `AllNotificationsPage`，使用手机框内Navigator `/notifications` 路由；返回保留原页面。复用原型已有三条消息，未虚构新增通知/服务器/已读状态。
- 新页消息点击仍使用原下拉已有的report动作。141个H5源路由清单不因此被改成142；通知页是新授权扩展。

## 文件

- `lib/pages/home_page.dart`
- `lib/widgets/global_menu.dart`
- `lib/features/notifications/notification_data.dart`
- `lib/features/notifications/notifications_page.dart`
- `test/home_notifications_revision_test.dart`

## 验证

- 中英各2项专项测试，共4项通过：图像不与CTA重叠、正确完整素材和fit；字号；查看全部进入3条消息页、返回、消息点击进入报告。
- `python tool/verify_handover.py`：30项全部通过；`flutter analyze`零问题；全部268测试通过；生产Web release成功。
- 日志：`docs/verification/summary.json`，2026-09-22T18:30:37.746390+08:00。
- 四个H5源文件SHA256与 `artifacts/visual_audit/baseline_20260922.json`逐项一致，H5 git状态干净。
- Preview生产实际点击：考试入口→首页→消息通知→查看全部→全部消息通知→返回首页，已完成。
- 会话截图证据（不是磁盘文件）：首页 `ca4fc7f4-cca0-4b96-9a79-e8e76e464009`；下拉 `92a92a5d-2937-4374-93b1-57a016b61121`；全部消息 `07a7cc4f-0245-4eb3-9d31-0b039c9fbf10`。

## 范围说明

本四项已验证，不表示原141路由×中英文的全部视觉/关键状态验收完成。全量视觉审计继续按原清单保留待验或有差异，不据路由数声明完全还原。未提交Git、未推送、未远程部署。
