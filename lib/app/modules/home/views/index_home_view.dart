import 'package:command_palette/command_palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:movie/app/modules/home/controllers/home_controller.dart';
import 'package:movie/app/routes/app_pages.dart';
import 'package:movie/app/widget/k_body.dart';
import 'package:movie/app/widget/k_empty_mirror.dart';
import 'package:movie/app/widget/k_error_stack.dart';
import 'package:movie/app/widget/movie_card_item.dart';
import 'package:movie/app/widget/window_appbar.dart';
import 'package:movie/config.dart';
import 'package:movie/spider/abstract/spider_movie.dart';
import 'package:movie/spider/abstract/spider_serialize.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class ScrollDownIntent extends Intent {}

class ScrollUpIntent extends Intent {}

class CategoryNextIntent extends Intent {}

class CategoryPrevIntent extends Intent {}

class IndexHomeView extends StatefulWidget {
  const IndexHomeView({Key? key}) : super(key: key);

  @override
  _IndexHomeViewState createState() => _IndexHomeViewState();
}

class _IndexHomeViewState extends State<IndexHomeView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const IndexHomeViewPage();
  }

  @override
  bool get wantKeepAlive => true;
}

class IndexHomeViewPage extends GetView<HomeController> {
  const IndexHomeViewPage({super.key});

  int get cardCount {
    bool isLandscape = Get.context!.isLandscape;
    if (GetPlatform.isMobile && !isLandscape) return 3;
    var w = controller.windowLastSize.width;
    if (w >= 1000) return 5;
    return 3;
  }

  /// 错误日志
  String get errorMsg => controller.indexHomeLoadDataErrorMessage;

  /// 错误日志最大展示行数
  int get errorMsgMaxLines => 12;

  handleClickItem(MirrorOnceItemSerialize subItem) async {
    var data = subItem;
    if (subItem.videos.isEmpty) {
      var id = subItem.id;
      var _textStyle =
          Theme.of(Get.context as BuildContext).textTheme.bodyMedium!.copyWith(
                color: CupertinoColors.systemBlue,
              );
      Get.dialog(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                "加载中",
                style: _textStyle,
              ),
            ],
          ),
        ),
        barrierColor: CupertinoColors.inactiveGray.withOpacity(.9),
      );
      data = await controller.currentMirrorItem.getDetail(
        id,
      );
      Get.back();
    }
    Get.toNamed(
      Routes.PLAY,
      arguments: data,
    );
  }

  /// 每个卡片的高度
  /// 用设备高度 * 0.33
  /// 横屏情况下 * 0.42
  double get _cardOnceHeight {
    double scan = .27;
    if (cardCount >= 5) scan = .42;
    return Get.height * scan;
  }

  double get _calcImageWidth {
    var width = controller.windowLastSize.width;
    // 桌面平台
    if (width >= 500) return 120;
    return width * .6;
  }

  bool get indexEnablePullDown {
    return !controller.isLoading;
  }

  bool get indexEnablePullUp {
    return !controller.isLoading && controller.homedata.isNotEmpty;
  }

  String get currentTitle {
    try {
      return controller.currentMirrorItem.meta.name;
    } catch (e) {
      return APP_TITLE;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (homeview) => Scaffold(
        appBar: WindowAppBar(
          iosBackStyle: true,
          title: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
            ),
            child: Text(
              currentTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),
          actions: [
            if (!controller.mirrorListIsEmpty)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: CupertinoButton(
                  child: const Icon(
                    Icons.movie,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    homeview.showMirrorModel(context);
                  },
                ),
              ),
          ],
        ),
        body: Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            // ctrl-p
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP):
                ScrollUpIntent(),
            // ctrl-n
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
                ScrollDownIntent(),
            // cmd-shift-[
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift,
                LogicalKeyboardKey.braceLeft): CategoryPrevIntent(),
            // cmd-shift-]
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift,
                LogicalKeyboardKey.braceRight): CategoryNextIntent(),
          },
          child: Actions(
            actions: {
              ScrollUpIntent: CallbackAction(
                onInvoke: (_) {
                  print("upupupup");
                  return null;
                },
              ),
              ScrollDownIntent: CallbackAction(
                onInvoke: (_) {
                  print("downdowndowndown");
                  return null;
                },
              ),
              CategoryPrevIntent: CallbackAction(
                onInvoke: (_) {
                  print("prev");
                  return null;
                },
              ),
              CategoryNextIntent: CallbackAction(
                onInvoke: (_) {
                  print("next");
                  return null;
                },
              ),
              TabSwitchLeftIntent: CallbackAction(
                onInvoke: (_) {
                  print("333");
                  return null;
                },
              ),
            },
            child: Focus(
              parentNode: controller.focusNode,
              focusNode: controller.homeFocusNode,
              autofocus: true,
              skipTraversal: true,
              child: KBody(
                child: Column(
                  children: [
                    AnimatedContainer(
                      width: double.infinity,
                      height: controller.currentCategoryer.isNotEmpty ? 42 : 0,
                      duration: const Duration(
                        milliseconds: 420,
                      ),
                      curve: Curves.decelerate,
                      child: ListView.builder(
                        itemCount: controller.currentCategoryer.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: ((context, index) {
                          SpiderQueryCategory curr =
                              controller.currentCategoryer[index];
                          // XXX(d1y): 默认为全部
                          bool isCurr = curr.id ==
                              (controller.currentCategoryerNow?.id ??
                                  kAllCategoryPoint);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.2,
                              vertical: 6.2,
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              color: isCurr ? CupertinoColors.systemBlue : null,
                              child: Text(
                                curr.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isCurr
                                      ? Colors.white
                                      : Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .color,
                                ),
                              ),
                              onPressed: () {
                                // XXX(d1y): 不允许点击当前分类
                                if (curr.id ==
                                    controller.currentCategoryerNow?.id) return;
                                controller.setCurrentCategoryerNow(curr);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: Builder(builder: (context) {
                        if (controller.mirrorListIsEmpty) {
                          return KEmptyMirror(
                            cx: controller,
                            width: _calcImageWidth,
                          );
                        }
                        return SmartRefresher(
                          enablePullDown: indexEnablePullDown,
                          enablePullUp: indexEnablePullUp,
                          header: const WaterDropHeader(
                            refresh: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoActivityIndicator(),
                                SizedBox(
                                  width: 12,
                                ),
                                Text("加载中"),
                              ],
                            ),
                            complete: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.smiley),
                                SizedBox(
                                  width: 12,
                                ),
                                Text("加载完成"),
                              ],
                            ),
                          ),
                          footer: CustomFooter(
                            builder: (BuildContext context, LoadStatus? mode) {
                              Widget body;
                              if (mode == LoadStatus.idle) {
                                body = const Text("上划加载更多");
                              } else if (mode == LoadStatus.loading) {
                                body = const CupertinoActivityIndicator();
                              } else if (mode == LoadStatus.failed) {
                                body = const Text("加载失败, 请重试");
                              } else if (mode == LoadStatus.canLoading) {
                                body = const Text("释放以加载更多");
                              } else {
                                body = const Text("没有更多数据");
                              }
                              return Center(
                                child: body,
                              );
                            },
                          ),
                          scrollController: ScrollController(),
                          controller: homeview.refreshController,
                          onLoading: homeview.refreshOnLoading,
                          onRefresh: homeview.refreshOnRefresh,
                          child: Builder(
                            builder: (_) {
                              if (homeview.isLoading) {
                                return const SizedBox.shrink();
                              }
                              if (homeview.homedata.isEmpty) {
                                if (errorMsg.isNotEmpty) {
                                  return Center(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          Image.asset(
                                            "assets/images/error.png",
                                            width: Get.width * .24,
                                          ),
                                          const SizedBox(
                                            height: 24,
                                          ),
                                          CupertinoButton.filled(
                                            child: const Text(
                                              "重新加载",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12.0,
                                              horizontal: 24.0,
                                            ),
                                            onPressed: () {
                                              homeview.updateHomeData(
                                                  isFirst: true);
                                            },
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),
                                          KErrorStack(
                                            msg: errorMsg,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Center(
                                    child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "assets/images/error.png",
                                      width: Get.width * .24,
                                    ),
                                    const SizedBox(height: 24),
                                    const Text("当前请求列表为空"),
                                  ],
                                ));
                              }
                              return WaterfallFlow.builder(
                                controller: ScrollController(),
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cardCount,
                                  crossAxisSpacing: 5.0,
                                  mainAxisSpacing: 5.0,
                                ),
                                itemCount: homeview.homedata.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var subItem = homeview.homedata[index];
                                  var _scale = index % 2 == 0 ? 1 : .8;
                                  var _h = _cardOnceHeight * _scale;
                                  return SizedBox(
                                    height: _h,
                                    child: MovieCardItem(
                                      imageUrl: subItem.smallCoverImage,
                                      title: subItem.title,
                                      onTap: () {
                                        handleClickItem(subItem);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
