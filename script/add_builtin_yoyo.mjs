import fs from 'fs'
import { execSync } from 'child_process'

function wget(url, path) {
  const cmd = `wget ${url} -O ${path}`
  console.log(cmd)
  execSync(cmd)
}

// https://stackoverflow.com/a/1349426
function makeid(length) {
  let result = '';
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const charactersLength = characters.length;
  let counter = 0;
  while (counter < length) {
    result += characters.charAt(Math.floor(Math.random() * charactersLength));
    counter += 1;
  }
  return result;
}


;(async ()=> {
  // console.log("该脚本会自动将社区维护的 yoyo.json 添加到内建支持中")
  const yoyoJSONFile = 'y.json'
  if (!fs.existsSync(yoyoJSONFile)) {
    wget('https://cdn.jsdelivr.net/gh/waifu-project/v1@latest/yoyo.json', yoyoJSONFile)
  }
  /** @type {Array<SourceItem>}  */
  const data = JSON.parse(fs.readFileSync(yoyoJSONFile).toString('utf8'))
  let codegen = `import 'package:xi/adapters/mac_cms.dart';\n\n`
  codegen += 'var list$ = [\n'
  const p = `MacCMSSpider`
  data.forEach(item=> {
    const id = makeid(9)
    const line = `  ${p}(name: "${item.name}", root_url: "${item.api.root}", api_path: "${item.api.path}", nsfw: ${item.nsfw}, id: "${id}", status: true),\n`
    codegen += line
  })
  codegen += '];\n'

  const file1 = "../lib/builtin/maccms/maccms.dart"
  const file2 = "../lib/isar/schema/settings_schema.dart"
  if (!fs.existsSync(file1) || !fs.existsSync(file2)) {
    throw new Error("操作文件不存在")
  }
  fs.writeFileSync(file1, codegen)

  // default enable nsfw
  execSync(`sed -i '' 's/isNSFW = false/isNSFW = true/' ${file2}`)
})()
