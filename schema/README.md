# Schema

`asset.json` 是源合集列表格式

```json
{
  "$schema": "https://raw.githubusercontent.com/waifu-project/movie/dev/schema/assets.json",
  "data": [
    {
      "title": "源名称",
      "url": "采集地址, 一般是地址合集",
      "msg": "源的说明, 一般是导入的时候用来提示的",
      "nsfw": "是否是 18+ 的源"
    }
  ]
}
```