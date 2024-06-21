// https://github.com/cuiocean/ZY-Player-APP/blob/main/utils/request.js

// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import '../abstract/spider_movie.dart';
import '../abstract/spider_serialize.dart';
import '../models/mac_cms/xml_data.dart';
import '../models/mac_cms/xml_search_data.dart';
import 'package:xml2json/xml2json.dart';
import 'package:path/path.dart' as path;

import '../utils/helper.dart';
import '../utils/http.dart';

/// 请求返回的内容
enum ResponseCustomType {
  xml,

  json,

  /// 未知
  unknow
}

class MacCMSSpider extends ISpider {
  final bool nsfw;
  final String jiexiUrl;
  final String name;
  final String logo;
  final String desc;
  final String root_url;
  final String api_path;
  final String id;
  final bool status;
  MacCMSSpider({
    this.nsfw = false,
    this.name = "",
    this.logo = "",
    this.desc = "",
    this.jiexiUrl = "",
    this.status = true,
    required this.id,
    required this.root_url,
    required this.api_path,
  });

  createUrl({
    required String suffix,
  }) {
    return root_url + suffix;
  }

  Options ops = Options(
    responseType: ResponseType.plain,
  );

  bool get hasJiexiUrl {
    return jiexiUrl.isNotEmpty;
  }

  /// 简单获取视频链接类型
  static MirrorSerializeVideoType easyGetVideoType(String rawUrl) {
    var ext = path.extension(rawUrl);
    switch (ext) {
      case '.m3u8':
      case '.m3u':
        return MirrorSerializeVideoType.m3u8;
      case '.mp4':
        return MirrorSerializeVideoType.mp4;
      default:
        return MirrorSerializeVideoType.iframe;
    }
  }

  /// 尽可能的拿到视频链接
  ///
  /// 规则:
  /// => `在线播放$https://vod3.jializyzm3u8.com/20210819/9VhEvIhE/index.m3u8`
  ///
  String easyGetVideoURL(dynamic raw) {
    if (raw == null) return "";
    var _raw = raw.toString().trim();
    if (isURL(_raw)) return _raw;
    var _block = _raw.split("\$");
    if (_block.length >= 3) return _raw;
    var sybIndex = _raw.indexOf("\$");
    if (sybIndex >= 0) {
      return _raw.substring(sybIndex + 1);
    }
    return "";
  }

  String get _responseParseFail => "接口返回值解析错误 :(";

  /// 检测一下请求之后返回的内容
  ///
  /// 如果是内容为 [ResponseCustomType.unknow] 则抛出异常
  void beforeTestResponseData(dynamic data) {
    ResponseCustomType _type = getResponseType(data);
    if (_type == ResponseCustomType.unknow) {
      throw AsyncError(
        _responseParseFail,
        StackTrace.fromString(_responseParseFail),
      );
      // return Future.error('解析失败');
    }
  }

  @override
  Future<MirrorOnceItemSerialize> getDetail(String movieId) async {
    var resp = await XHttp.dio.post(
      createUrl(suffix: api_path),
      queryParameters: {
        "ac": "videolist",
        "ids": movieId,
      },
      options: ops,
    );
    var x2j = Xml2Json();
    x2j.parse(resp.data);
    var _json = x2j.toBadgerfish();
    var _ = json.decode(_json);
    KBaseMovieXmlData xml = KBaseMovieXmlData.fromJson(_);
    var video = xml.rss.list.video;
    var cards = video.map(
      (e) {
        var __dd = e.dl.dd;
        List<MirrorSerializeVideoInfo> videos = __dd.map((item) {
          return MirrorSerializeVideoInfo(
            url: easyGetVideoURL(item.cData),
            name: item.flag,
            type: easyGetVideoType(item.cData),
          );
        }).toList();
        var pic = normalizeCoverImage(e.pic);
        return MirrorOnceItemSerialize(
          id: e.id,
          smallCoverImage: pic,
          title: e.name,
          videos: videos,
          desc: e.des,
        );
      },
    ).toList();
    if (cards.isEmpty) {
      throw UnimplementedError();
    }
    return cards[0];
  }

  @override
  Future<List<MirrorOnceItemSerialize>> getHome({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    var qs = {
      "ac": "videolist",
      "pg": page,
    };
    if (category != null && category.isNotEmpty) {
      qs['t'] = category;
    }
    var resp = await XHttp.dio.get(
      createUrl(suffix: api_path),
      queryParameters: qs,
      options: ops,
    );
    dynamic data = resp.data;
    beforeTestResponseData(data);
    var x2j = Xml2Json();
    x2j.parse(data);
    var _json = x2j.toBadgerfish();
    var _ = json.decode(_json);
    KBaseMovieXmlData xml = KBaseMovieXmlData.fromJson(_);
    var cards = xml.rss.list.video.map(
      (e) {
        var __dd = e.dl.dd;
        List<MirrorSerializeVideoInfo> videos = __dd.map((item) {
          return MirrorSerializeVideoInfo(
            url: easyGetVideoURL(item.cData),
            name: item.flag,
            type: easyGetVideoType(item.cData),
          );
        }).toList();
        var pic = normalizeCoverImage(e.pic);
        return MirrorOnceItemSerialize(
          id: e.id,
          smallCoverImage: pic,
          title: e.name,
          videos: videos,
          desc: e.des,
        );
      },
    ).toList();
    return cards;
  }

  /// 匹配的规则:
  ///   https://www.88zy.net/upload/vod/2020-10-26/202010261603727118.jpg\r\\n
  String normalizeCoverImage(String rawString) {
    String syb = r'\r\\n';
    var index = rawString.lastIndexOf(syb);
    var _offset = rawString.length - syb.length;
    if (index == _offset) return rawString.substring(0, index);
    return rawString;
  }

  ///   返回值比对 [kv]
  final Map<String, ResponseCustomType> _RespCheckkv = {
    "{\"": ResponseCustomType.json,
    "<?xml": ResponseCustomType.xml,
  };

  /// 获取返回内容的类型
  /// return [ResponseCustomType]
  ///
  /// 通过判断内容的首部分字符
  ///
  /// `json` 参考:
  /// ```markdown
  ///   `{"`
  /// ```
  ///
  /// `xml` 参考:
  /// ```makrdown
  ///   `<?xml`
  /// ```
  ResponseCustomType getResponseType(String checkText) {
    var _k = _RespCheckkv.keys.where((_key) {
      int _len = _key.length;
      var _sub = checkText.substring(0, _len);
      bool _if = _sub.contains(_key, 0);
      return _if;
    }).toList();

    if (_k.isNotEmpty) {
      return _RespCheckkv[_k[0]] as ResponseCustomType;
    }

    return ResponseCustomType.unknow;

    // String attrText = checkText.substring(0, 2);
    // String jsonSyb = "{\"";
    // String xmlSyb = "<?xml";
    // String attrText = checkText.substring(0, 5);
    // if (attrText == jsonSyb) {
    //   return ResponseCustomType.json;
    // }
    // return ResponseCustomType.xml;
  }

  @override
  Future<List<MirrorOnceItemSerialize>> getSearch({
    required String keyword,
    int page = 1,
    int limit = 10,
  }) async {
    var resp = await XHttp.dio.post(
      createUrl(suffix: api_path),
      queryParameters: {
        "ac": "videolist",
        // "t": limit,
        "pg": page,
        "wd": keyword,
      },
      options: ops,
    );
    dynamic data = resp.data;
    beforeTestResponseData(data);
    var x2j = Xml2Json();
    x2j.parse(data);
    var _json = x2j.toBadgerfish();
    KBaseMovieSearchXmlData searchData = kBaseMovieSearchXmlDataFromJson(_json);
    var defaultCoverImage = meta.logo;
    List<MirrorOnceItemSerialize> result = searchData.rss?.list?.video!
            .map(
              (e) => MirrorOnceItemSerialize(
                id: e.id ?? "",
                smallCoverImage: defaultCoverImage,
                title: e.name?.cdata ?? "",
              ),
            )
            .toList() ??
        [];
    return result;
  }

  @override
  bool get isNsfw => nsfw;

  @override
  SpiderItemMetaData get meta => SpiderItemMetaData(
        name: name,
        logo: logo,
        desc: desc,
        domain: root_url,
        id: id,
        status: status,
      );

  @override
  Future<List<SpiderQueryCategory>> getCategory() async {
    var path = createUrl(suffix: api_path);
    var resp = await XHttp.dio.get(path);
    dynamic data = resp.data;
    beforeTestResponseData(data);
    var x2j = Xml2Json();
    x2j.parse(data);
    var _json = x2j.toBadgerfish();
    var _ = json.decode(_json);
    KBaseMovieXmlData xml = KBaseMovieXmlData.fromJson(_);
    return xml.rss.category;
  }

  @override
  String toString() {
    var output = "\n";
    output += "name: $name\n";
    output += " url: $root_url$api_path";
    return output;
  }
}
