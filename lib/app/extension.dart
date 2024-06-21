import 'package:isar/isar.dart';
import 'package:movie/isar/repo.dart';
import 'package:movie/isar/schema/history_schema.dart';
import 'package:movie/isar/schema/mirror_schema.dart';
import 'package:movie/isar/schema/parse_schema.dart';
import 'package:movie/isar/schema/settings_schema.dart';
import 'package:movie/shared/enum.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// remove this(mixin object 杀伤力太大)
extension ISettingMixin on Object {
  IsarCollection<SettingsIsarModel> get settingAs => IsarRepository().settingAs;
  SettingsIsarModel get settingAsValue => IsarRepository().settingsSingleModel;

  IsarCollection<HistoryIsarModel> get historyAs =>
      IsarRepository().isar.historyIsarModels;

  IsarCollection<ParseIsarModel> get parseAs =>
      IsarRepository().isar.parseIsarModels;

  IsarCollection<MirrorIsarModel> get mirrorAs =>
      IsarRepository().isar.mirrorIsarModels;

  Isar get isarInstance => IsarRepository().isar;

  T getSettingAsKeyIdent<T>(SettingsAllKey key) {
    return getSettingAsKey(key) as T;
  }

  /// the code is shit|_・)
  ///
  /// disgustingε(┬┬﹏┬┬)3
  ///
  /// (っ ̯ -｡)
  getSettingAsKey(SettingsAllKey key) {
    var curr = settingAsValue;
    if (key == SettingsAllKey.themeMode) {
      return curr.themeMode;
    } else if (key == SettingsAllKey.iosCanBeUseSystemBrowser) {
      return curr.iosCanBeUseSystemBrowser;
    } else if (key == SettingsAllKey.macosPlayUseIINA) {
      return curr.macosPlayUseIINA;
    } else if (key == SettingsAllKey.isNsfw) {
      return curr.isNSFW;
    } else if (key == SettingsAllKey.mirrorIndex) {
      return curr.mirrorIndex;
    } else if (key == SettingsAllKey.mirrorTextarea) {
      return curr.mirrorTextarea;
    } else if (key == SettingsAllKey.showPlayTips) {
      return curr.showPlayTips;
    } else if (key == SettingsAllKey.webviewPlayType) {
      return curr.webviewPlayType;
    }
    return curr.id;
  }

  /// the code is shit|_・)
  ///
  /// disgustingε(┬┬﹏┬┬)3
  ///
  /// (っ ̯ -｡)
  updateSetting(SettingsAllKey key, dynamic value) {
    var curr = settingAsValue;
    if (key == SettingsAllKey.themeMode) {
      curr.themeMode = value;
    } else if (key == SettingsAllKey.iosCanBeUseSystemBrowser) {
      curr.iosCanBeUseSystemBrowser = value;
    } else if (key == SettingsAllKey.macosPlayUseIINA) {
      curr.macosPlayUseIINA = value;
    } else if (key == SettingsAllKey.isNsfw) {
      curr.isNSFW = value;
    } else if (key == SettingsAllKey.mirrorIndex) {
      curr.mirrorIndex = value;
    } else if (key == SettingsAllKey.mirrorTextarea) {
      curr.mirrorTextarea = value;
    } else if (key == SettingsAllKey.showPlayTips) {
      curr.showPlayTips = value;
    } else if (key == SettingsAllKey.webviewPlayType) {
      curr.webviewPlayType = value;
    } else {
      return;
    }
    IsarRepository().isar.writeTxnSync(() {
      settingAs.putSync(curr);
    });
  }
}

extension Mixxxx on String {
  openURL() async {
    await canLaunchUrlString(this)
        ? await launchUrlString(this)
        : throw 'Could not launch $this';
  }

  openToIINA() async {
    return 'iina://weblink?url=$this&new_window=1'.openURL();
  }
}
