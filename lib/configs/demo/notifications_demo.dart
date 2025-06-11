class NotificationsDemo {
  static List<Map<String, String>> notifications = [
    {
      'title': 'outlook来自乌萨奇的回复',
      'content': '晚上咱可以一起吃饭去啊，你看啥时候走合适，挺喜欢的哈哈哈哈'
    },
    {
      'title': '第十八届全国大学生软件创新大赛-软件设计创新赛-全国赛入围名单',
      'content': """尊敬的参赛者，
您好！
经过6个月以来的激烈角逐，第十八届全国大学生软件创新大赛现已进入激烈的全国赛阶段。自大赛启动以来，我们见证了众多杰出参赛者团队凭借其创意、技术和热情呈现了许多高水平的作品，充分展示了当前大学生对软件开发与创新的热情和能力。
如若您收到本通知，恭喜您所在的团队已成功晋级至全国赛。您的团队的创意和努力获得了评审团的认可，但前路依然充满挑战。全国赛将更加严格地评审技术实现、创新性、应用价值及团队表现。
全国共计114支团队进入到全国赛阶段，其中14支团队直接晋级全国赛决赛，其余100支团队将继续通过全国赛复赛的选拔角逐全国赛决赛的名额。全国赛入围名单请参考附件。"""
    },
    {
      'title': 'Codeforces Round 1014 (Div. 2)',
      'content': """Hello, Usagi537.
Welcome to the regular Codeforces round.
I'm glad to invite you to take part in Codeforces Round 1014 (Div. 2). It starts on Saturday, March, 29, 2025 14:35 (UTC). The contest duration is 2 hours. The allowed programming languages are C/C++, Pascal, Perl, Java, C#, Python (2 and 3), Ruby, PHP, Haskell, Scala, OCaml, D, Go, JavaScript and Kotlin.
Problems are prepared by k1sara and sergeev.PRO. Don't miss the round!"""
    },
    {
      'title': '连接到 Microsoft 帐户的新应用',
      'content': """Microsoft 帐户
新应用有权访问你的数据
Gmail iOS 已连接到 Microsoft 帐户 ji**7@outlook.com。
如果未授予此访问权限，请从帐户中删除应用。
管理应用
也可以选择退出或更改接收安全通知的位置。
谢谢!
Microsoft 帐户团队"""
    }
  ];

  static Map<String, String> getNotifications(int index) {
    return notifications[index];
  }

}