import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cupertino_settings/flutter_cupertino_settings.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:movie/app/extension.dart';
import 'package:movie/app/modules/home/controllers/home_controller.dart';
import 'package:movie/app/modules/home/views/parse_vip_manage.dart';
import 'package:movie/app/modules/home/views/source_help.dart';
import 'package:movie/app/widget/window_appbar.dart';
import 'package:movie/git_info.dart';
import 'package:movie/shared/enum.dart';
import 'package:movie/shared/manage.dart';
import 'package:movie/app/modules/home/views/cupertino_license.dart';
import 'package:xi/utils/helper.dart';
import 'package:xi/utils/source.dart';

import 'nsfwtable.dart';

enum GetBackResultType {
  /// 失败
  fail,

  /// 成功
  success
}

enum HandleDiglogTapType {
  /// 清空
  clean,

  /// 获取配置
  kget,
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final HomeController home = Get.find<HomeController>();

  Future<String> loadAsset() async {
    return await rootBundle.loadString('assets/data/source_help.txt');
  }

  String sourceHelpText = "";

  bool _isDark = false;

  bool get isDark {
    return _isDark;
  }

  set isDark(bool newVal) {
    updateSetting(SettingsAllKey.themeMode, SystemThemeMode.dark);
    setState(() {
      _isDark = newVal;
    });
    Get.changeThemeMode(newVal ? ThemeMode.dark : ThemeMode.light);
  }

  bool _autoDarkMode = false;

  set autoDarkMode(bool newVal) {
    if (newVal) {
      updateSetting(SettingsAllKey.themeMode, SystemThemeMode.system);
    }
    setState(() {
      _autoDarkMode = newVal;
    });
    if (!newVal) {
      _isDark = Get.isPlatformDarkMode;
      Get.changeThemeMode(!_isDark ? ThemeMode.light : ThemeMode.dark);
      return;
    }
    if (GetPlatform.isWindows) {
      var mode = getWindowsThemeMode();
      Get.changeTheme(ThemeData(brightness: mode));
    }
    Get.changeThemeMode(ThemeMode.system);
  }

  bool get autoDarkMode {
    return _autoDarkMode;
  }

  @override
  void initState() {
    setState(() {
      var themeMode =
          getSettingAsKeyIdent<SystemThemeMode>(SettingsAllKey.themeMode);
      _isDark = themeMode.isDark;
      _autoDarkMode = themeMode.isSytem;
      _canBeShowIosBrowser =
          getSettingAsKeyIdent<bool>(SettingsAllKey.iosCanBeUseSystemBrowser);
      _macosPlayUseIINA = home.macosPlayUseIINA;
    });
    loadSourceHelp();
    addMirrorMangerTextareaLister();
    super.initState();
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  addMirrorMangerTextareaLister() {
    editingControllerValue =
        getSettingAsKeyIdent<String>(SettingsAllKey.mirrorTextarea);
    _editingController.addListener(() {
      updateSetting(SettingsAllKey.mirrorTextarea, editingControllerValue);
    });
  }

  loadSourceHelp() async {
    var data = await loadAsset();
    setState(() {
      sourceHelpText = data;
    });
  }

  bool get showNSFW {
    return (home.isNsfw || nShowNSFW >= 10);
  }

  set showNSFW(newVal) {
    setState(() {
      nShowNSFW = !newVal ? 0 : 10;
    });
  }

  int _nShowNSFW = 0;

  int get nShowNSFW => _nShowNSFW;

  set nShowNSFW(newVal) {
    setState(() {
      _nShowNSFW = newVal;
    });
  }

  final TextEditingController _editingController = TextEditingController();

  String get editingControllerValue {
    return _editingController.text.trim();
  }

  set editingControllerValue(String newVal) {
    _editingController.text = newVal;
  }

  handleDiglogTap(HandleDiglogTapType type) async {
    switch (type) {
      case HandleDiglogTapType.clean:
        editingControllerValue = "";
        EasyLoading.showInfo("解析内容已经清空!");
        break;
      case HandleDiglogTapType.kget:
        if (editingControllerValue.isEmpty) {
          EasyLoading.showError("内容为空, 请填写url!");
          return;
        }
        var target = SourceUtils.getSources(editingControllerValue);
        if (target.isEmpty) {
          EasyLoading.showError("没有找到匹配的源!");
          return;
        }
        Get.dialog(
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(
                    height: 42,
                  ),
                  CupertinoButton.filled(
                    child: const Text(
                      "关闭",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
          ),
          barrierColor: CupertinoColors.black.withOpacity(.9),
        );
        var data = await SourceUtils.runTaks(target);
        Get.back();
        if (data.isEmpty) {
          EasyLoading.showError("获取的内容为空!");
          return;
        }
        var easyData = SourceUtils.mergeMirror(
          SpiderManage.extend,
          data,
          diff: true,
        );
        var addLen = easyData[0];
        if (addLen > 0) {
          var listData = easyData[1];
          SpiderManage.mergeSpider(listData);
        }
        var showMessage = "获取成功, 已合并$addLen个源!";
        if (addLen <= 0) {
          showMessage = "获取成功, 没有新的源!";
        }
        EasyLoading.showSuccess(showMessage);
        break;
      default:
    }
  }

  /// 是否显示`ios`默认浏览器设置
  /// linux no support this options!!
  bool canBeShowIosBrowserSettings =
      !GetPlatform.isLinux && (GetPlatform.isIOS || kDebugMode);

  bool _canBeShowIosBrowser = true;

  bool _macosPlayUseIINA = false;

  bool get macosPlayUseIINA {
    return _macosPlayUseIINA;
  }

  set macosPlayUseIINA(newVal) {
    _macosPlayUseIINA = newVal;
    setState(() {});
    home.macosPlayUseIINA = newVal;
  }

  handleCleanCache() {
    home.clearCache();
    home.confirmAlert(
      "已删除缓存, 部分内容重启之后生效!",
      showCancel: false,
      confirmText: "我知道了",
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const WindowAppBar(
        title: Text("设置"),
        centerTitle: true,
        actions: [SizedBox.shrink()],
      ),
      body: CupertinoSettings(
        items: <Widget>[
          const CSHeader('常规设置'),
          !autoDarkMode
              ? CSControl(
                  nameWidget: const Text('深色'),
                  contentWidget: CupertinoSwitch(
                    value: isDark,
                    onChanged: (bool value) {
                      isDark = value;
                    },
                  ),
                  style: const CSWidgetStyle(
                    icon: Icon(
                      Icons.settings_brightness,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          CSControl(
            nameWidget: const Text('深色跟随系统'),
            contentWidget: CupertinoSwitch(
              value: autoDarkMode,
              onChanged: (bool value) {
                autoDarkMode = value;
              },
            ),
            style: const CSWidgetStyle(
              icon: Icon(
                CupertinoIcons.moon_stars_fill,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => const ParseVipManagePageView());
            },
            child: CSControl(
              nameWidget: const Text('解析线路管理'),
              style: const CSWidgetStyle(
                icon: Icon(
                  Icons.add_box,
                ),
              ),
            ),
          ),
          GestureDetector(
            child: CSControl(
              nameWidget: const Text("视频源管理"),
              style: const CSWidgetStyle(
                icon: Icon(
                  Icons.video_library,
                ),
              ),
            ),
            onTap: () {
              var cx =
                  getSettingAsKeyIdent<String>(SettingsAllKey.mirrorTextarea)
                      .trim();
              if (cx.isNotEmpty && cx != editingControllerValue) {
                editingControllerValue = cx;
              }
              Get.defaultDialog(
                actions: [
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: const Text("清空"),
                    onPressed: () {
                      handleDiglogTap(HandleDiglogTapType.clean);
                    },
                  ),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: const Text("获取配置"),
                    onPressed: () {
                      handleDiglogTap(HandleDiglogTapType.kget);
                    },
                  ),
                ],
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 12,
                ),
                title: "我的视频源网络地址",
                titleStyle: const TextStyle(
                  fontSize: 16,
                ),
                content: SizedBox(
                  height: Get.height * .2,
                  width: context.widthTransformer(dividedBy: 1),
                  child: Card(
                    color: const Color.fromRGBO(0, 0, 0, .02),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _editingController,
                        maxLines: 10,
                        decoration: InputDecoration.collapsed(
                          hintText: sourceHelpText,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          canBeShowIosBrowserSettings
              ? CSControl(
                  nameWidget: const Text('iOS播放使用内置浏览器'),
                  contentWidget: CupertinoSwitch(
                    value: _canBeShowIosBrowser,
                    onChanged: (bool value) async {
                      setState(() {
                        _canBeShowIosBrowser = value;
                      });
                      home.iosCanBeUseSystemBrowser = value;
                    },
                  ),
                  style: const CSWidgetStyle(
                    icon: Icon(
                      Icons.airplay_rounded,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          showNSFW
              ? CSControl(
                  nameWidget: const Text('NSFW'),
                  contentWidget: CupertinoSwitch(
                    value: home.isNsfw,
                    onChanged: (bool value) async {
                      if (value) {
                        var result = await showCupertinoModalBottomSheet(
                          context: context,
                          builder: (_) => SizedBox(
                            width: double.infinity,
                            height: Get.height * .72,
                            child: const NsfwTableView(),
                          ),
                        );
                        if (result == GetBackResultType.success) {
                          home.isNsfw = true;
                          showNSFW = true;
                          home.update();
                          return;
                        }
                      }
                      showNSFW = false;
                      home.isNsfw = false;
                      home.update();
                    },
                  ),
                  style: const CSWidgetStyle(
                    icon: Icon(
                      Icons.stop_screen_share,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          if (GetPlatform.isMacOS)
            CSControl(
              nameWidget: const Text('播放使用IINA(默认内置播放器)'),
              contentWidget: CupertinoSwitch(
                value: macosPlayUseIINA,
                onChanged: (bool value) async {
                  if (value) {
                    final bool isInstall = checkInstalledIINA();
                    if (!isInstall) {
                      EasyLoading.showError("未安装IINA, 请先安装!");
                      return;
                    }
                  }
                  macosPlayUseIINA = value;
                },
              ),
              style: const CSWidgetStyle(
                icon: Icon(
                  CupertinoIcons.play_rectangle,
                ),
              ),
            ),
          const CSHeader('其他设置'),
          GestureDetector(
            onTap: () {
              Get.to(() => const SourceHelpTable());
            },
            child: CSControl(
              nameWidget: const Text("视频源帮助"),
              style: const CSWidgetStyle(
                icon: Icon(
                  CupertinoIcons.arrow_down_right_square_fill,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              var ctx = Get.context;
              if (ctx == null) return;
              showCupertinoDialog(
                builder: (BuildContext context) => CupertinoAlertDialog(
                  title: const Text('提示'),
                  content: const Text("将删除所有缓存, 包括视频源和一些设置"),
                  actions: <CupertinoDialogAction>[
                    CupertinoDialogAction(
                      child: const Text(
                        '我想想',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        Get.back();
                        handleCleanCache();
                      },
                      child: const Text(
                        '确定',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                context: ctx,
              );
            },
            child: CSControl(
              nameWidget: const Text("清除缓存"),
              style: const CSWidgetStyle(
                icon: Icon(
                  CupertinoIcons.clear_thick_circled,
                ),
              ),
            ),
          ),
          CSButton(
            CSButtonType.DEFAULT,
            "Licenses",
            () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (_) => SizedBox(
                  width: double.infinity,
                  height: Get.height * .72,
                  child: cupertinoLicensePage,
                ),
              );
            },
          ),
          const SizedBox(
            height: 24,
          ),
          GestureDetector(
            onTap: () {
              if (showNSFW) {
                showNSFW = false;
              } else {
                setState(() {
                  nShowNSFW++;
                });
              }
            },
            child: Builder(builder: (context) {
              var firstWriteYear = '2020';
              String currentYearString = DateTime.now().year.toString();
              var text =
                  '© YOYO播放器 $firstWriteYear-$currentYearString $gitTag($gitCommit)';
              return CSDescription(text);
            }),
          ),
        ],
      ),
    );
  }
}
