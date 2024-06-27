package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"regexp"
	"slices"
	"strings"
	"sync"

	"github.com/charmbracelet/log"
	"github.com/imroc/req/v3"
	"github.com/sourcegraph/conc/pool"
)

var pornWords = newSet()

// https://github.com/takayama-lily/takayamabot/blob/9b19baf835823ccc117b13744010e34e82dcd84c/bridge.js#L268C15-L268C654
var pornWord1 = `
%E6%AF%8D%E7%8B%97
%E7%9C%8B%E6%89%B9
%E6%97%A5%E6%89%B9
%E9%A6%99%E6%89%B9
%E6%89%B9%E9%87%8C
%E6%88%90%E4%BA%BA
%E6%97%A0%E7%A0%81
%E8%8B%8D%E4%BA%95%E7%A9%BA
b%E9%87%8C
%E5%AB%A9b
%E5%AB%A9%E6%AF%94
%E5%B0%8F%E4%BE%BF
%E5%A4%A7%E4%BE%BF
%E7%B2%AA
%E5%B1%8E
%E5%B0%BF
%E6%B7%A6
%E5%B1%84
%E5%B1%8C
%E5%A5%B8
%E6%B7%AB
%E7%A9%B4
%E8%82%8F
%E8%82%9B
%E9%AA%9A
%E9%80%BC
%E5%A6%93
%E8%89%B9
%E5%AD%90%E5%AE%AB
%E6%9C%88%E7%BB%8F
%E5%8D%B1%E9%99%A9%E6%9C%9F
%E5%AE%89%E5%85%A8%E6%9C%9F
%E6%88%B4%E5%A5%97
%E6%97%A0%E5%A5%97
%E5%86%85%E5%B0%84
%E4%B8%AD%E5%87%BA
%E5%B0%84%E5%9C%A8%E9%87%8C
%E5%B0%84%E5%9C%A8%E5%A4%96
%E7%B2%BE%E5%AD%90
%E5%8D%B5%E5%AD%90
%E5%8F%97%E7%B2%BE
%E5%B9%BC%E5%A5%B3
%E5%AB%A9%E5%B9%BC
%E7%B2%89%E5%AB%A9
%E6%97%A5%E6%88%91
%E6%97%A5%E7%83%82
%E8%8D%89%E6%88%91
%E8%8D%89%E7%83%82
%E5%B9%B2%E6%88%91
%E6%97%A5%E6%AD%BB
%E8%8D%89%E6%AD%BB
%E5%B9%B2%E6%AD%BB
%E7%8B%82%E8%8D%89
%E7%8B%82%E5%B9%B2
%E7%8B%82%E6%8F%92
%E7%8B%82%E6%93%8D
%E6%97%A5%E6%AF%94
%E8%8D%89%E6%AF%94
%E6%90%9E%E6%88%91
%E8%88%94%E6%88%91
%E8%88%94%E9%98%B4
%E6%B5%AA%E5%A5%B3
%E6%B5%AA%E8%B4%A7
%E6%B5%AA%E9%80%BC
%E6%B5%AA%E5%A6%87
%E5%8F%91%E6%B5%AA
%E6%B5%AA%E5%8F%AB
%E6%B7%AB%E8%8D%A1
%E6%B7%AB%E4%B9%B1
%E8%8D%A1%E5%A6%87
%E8%8D%A1%E5%A5%B3
%E8%8D%A1%E8%B4%A7
%E6%93%8D%E7%83%82
%E6%8A%BD%E6%8F%92
%E8%A2%AB%E5%B9%B2
%E8%A2%AB%E8%8D%89
%E8%A2%AB%E6%93%8D
%E8%A2%AB%E6%97%A5
%E8%A2%AB%E4%B8%8A
%E8%A2%AB%E8%89%B9
%E8%A2%AB%E6%8F%92
%E8%A2%AB%E5%B0%84
%E5%B0%84%E7%88%86
%E5%B0%84%E4%BA%86
%E9%A2%9C%E5%B0%84
%E5%B0%84%E8%84%B8
%E6%8C%89%E6%91%A9%E6%A3%92
%E8%82%89%E7%A9%B4
%E5%B0%8F%E7%A9%B4
%E9%98%B4%E6%A0%B8
%E9%98%B4%E6%88%B7
%E9%98%B4%E9%98%9C
%E9%98%B4%E8%92%82
%E9%98%B4%E5%9B%8A
%E9%98%B4%E9%83%A8
%E9%98%B4%E9%81%93
%E9%98%B4%E5%94%87
%E9%98%B4%E8%8C%8E
%E8%82%89%E6%A3%92
%E9%98%B3%E5%85%B7
%E9%BE%9F%E5%A4%B4
%E5%8B%83%E8%B5%B7
%E7%88%B1%E6%B6%B2
%E8%9C%9C%E6%B6%B2
%E7%B2%BE%E6%B6%B2
%E9%A3%9F%E7%B2%BE
%E5%92%BD%E7%B2%BE
%E5%90%83%E7%B2%BE
%E5%90%B8%E7%B2%BE
%E5%90%9E%E7%B2%BE
%E5%96%B7%E7%B2%BE
%E5%B0%84%E7%B2%BE
%E9%81%97%E7%B2%BE
%E6%A2%A6%E9%81%97
%E6%B7%B1%E5%96%89
%E4%BA%BA%E5%85%BD
%E5%85%BD%E4%BA%A4
%E6%BB%A5%E4%BA%A4
%E6%8B%B3%E4%BA%A4
%E4%B9%B1%E4%BA%A4
%E7%BE%A4%E4%BA%A4
%E8%82%9B%E4%BA%A4
%E8%B6%B3%E4%BA%A4
%E8%84%9A%E4%BA%A4
%E5%8F%A3%E7%88%86
%E5%8F%A3%E6%B4%BB
%E5%8F%A3%E4%BA%A4
%E4%B9%B3%E4%BA%A4
%E4%B9%B3%E6%88%BF
%E4%B9%B3%E5%A4%B4
%E4%B9%B3%E6%B2%9F
%E5%B7%A8%E4%B9%B3
%E7%8E%89%E4%B9%B3
%E8%B1%AA%E4%B9%B3
%E6%9A%B4%E4%B9%B3
%E7%88%86%E4%B9%B3
%E4%B9%B3%E7%88%86
%E4%B9%B3%E9%A6%96
%E4%B9%B3%E7%BD%A9
%E5%A5%B6%E5%AD%90
%E5%A5%B6%E7%BD%A9
%E6%91%B8%E5%A5%B6
%E8%83%B8%E7%BD%A9
%E6%91%B8%E8%83%B8
%E8%83%B8%E9%83%A8
%E8%83%B8%E6%8E%A8
%E6%8E%A8%E6%B2%B9
%E5%A4%A7%E4%BF%9D%E5%81%A5
%E9%BB%84%E7%89%87
%E7%88%BD%E7%89%87
a%E7%89%87
%E9%87%8E%E6%88%98
%E5%8F%AB%E5%BA%8A
%E9%9C%B2%E5%87%BA
%E9%9C%B2b
%E6%BC%8F%E5%87%BA
%E6%BC%8Fb
%E4%B9%B1%E4%BC%A6
%E8%BD%AE%E5%A5%B8
%E8%BD%AE%E6%9A%B4
%E8%BD%AE%E6%93%8D
%E5%BC%BA%E5%A5%B8
%E5%BC%BA%E6%9A%B4
%E6%83%85%E8%89%B2
%E8%89%B2%E6%83%85
%E5%85%A8%E8%A3%B8
%E8%A3%B8%E4%BD%93
%E6%9E%9C%E4%BD%93
%E9%85%A5%E7%97%92
%E6%8D%8F%E5%BC%84
%E5%A5%97%E5%BC%84
%E4%BD%93%E4%BD%8D
%E9%AA%91%E4%B9%98
%E5%90%8E%E5%85%A5
%E4%BA%8C%E7%A9%B4
%E4%B8%89%E7%A9%B4
%E5%AC%B2
%E8%B0%83%E6%95%99
%E5%87%8C%E8%BE%B1
%E9%A5%A5%E6%B8%B4
%E5%A5%BD%E6%83%B3%E8%A6%81
%E6%80%A7%E4%BA%A4
%E6%80%A7%E5%A5%B4
%E6%80%A7%E8%99%90
%E6%80%A7%E6%AC%B2
%E6%80%A7%E8%A1%8C%E4%B8%BA
%E6%80%A7%E7%88%B1
%E5%81%9A%E7%88%B1
%E4%BD%9C%E7%88%B1
%E6%89%8B%E6%B7%AB
%E6%92%B8%E7%AE%A1
%E8%87%AA%E6%85%B0
%E7%97%B4%E5%A5%B3
%E9%B8%A18
%E9%B8%A1ba
%E9%B8%A1%E9%B8%A1
%E9%B8%A1%E5%B7%B4
%E9%B8%A1%E5%90%A7
%E9%B8%A1%E5%84%BF
%E8%82%89%E4%BE%BF%E5%99%A8
%E6%B3%84%E6%AC%B2
%E5%8F%91%E6%B3%84
%E9%AB%98%E6%BD%AE
%E6%BD%AE%E5%90%B9
%E6%BD%AE%E5%96%B7
%E7%88%BD%E6%AD%BB
%E7%88%BD%E7%BF%BB
%E7%88%BD%E7%88%86
%E4%BD%A0%E5%A6%88
%E5%B1%81%E7%9C%BC
%E5%90%8E%E5%BA%AD
%E8%8F%8A%E8%8A%B1
%E6%8F%B4%E4%BA%A4
%E6%93%8D%E6%AD%BB
%E6%8F%92%E6%AD%BB
`

func decodeURL(uri string) string {
	u, err := url.Parse(uri)
	if err != nil {
		return uri
	}
	return u.String()
}

var ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"

func init() {
	req.SetUserAgent(ua)
}

// https://github.com/golang-collections/collections/blob/master/set/set.go
type (
	Set struct {
		hash map[any]nothing
	}

	nothing struct{}
)

func newSet(initial ...any) *Set {
	s := &Set{make(map[any]nothing)}

	for _, v := range initial {
		s.Insert(v)
	}

	return s
}

func (this *Set) Insert(element any) {
	this.hash[element] = nothing{}
}

func (this *Set) Check(body string) bool {
	for cx := range this.hash {
		x := cx.(string)
		if strings.Contains(body, x) {
			return true
		}
	}
	return false
}

func isHTML(input string) bool {
	input = strings.ToLower(input)
	htmlMarkers := []string{"html", "<!d", "<body"}

	for _, htmlMarker := range htmlMarkers {
		if strings.Contains(input, htmlMarker) {
			return true
		}
	}

	return false
}

func isJSON(input string) bool {
	input = strings.ToLower(input)
	matched, _ := regexp.MatchString(`\s*[{\[]`, input)
	return matched
}

func isXML(message string) bool {
	header1 := regexp.QuoteMeta("<?xml version='1.0' encoding='UTF-8'?>")
	header2 := regexp.QuoteMeta("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
	valid, err := regexp.MatchString("^("+header1+"|"+header2+")", message)

	if err != nil {
		log.Error("xml.isXML: Could not process file. ", "err", err)
		return false
	}

	if valid {
		return true
	}

	return false
}

type Result struct {
	OK     bool
	Time   float64
	Reason string
	Data   string
	Name   string
	Nsfw   bool
	URL    string
}

type GithubIssueComment struct {
	Body string `json:"body"`
}

func isOK(body string) bool {
	var cx = strings.TrimSpace(body)
	if len(cx) == 0 {
		return false
	}
	// 错误的魔法值
	if cx == "err{0}" {
		return false
	}
	if isHTML(cx) {
		return false
	}
	return isXML(body) || isJSON(body)
}

func getGithubIssueComments(token string) []string {
	// hard-code
	var url = `https://api.github.com/repos/waifu-project/movie/issues/45/comments`
	var githubIssueComments []GithubIssueComment
	req.SetQueryParam("per_page", "100").SetBearerAuthToken(token).SetSuccessResult(&githubIssueComments).MustGet(url)
	var result []string
	for _, comment := range githubIssueComments {
		result = append(result, comment.Body)
	}
	return result
}

type ParseResult struct {
	Text string
	URL  string
}

func getItemWithText(text string) []ParseResult {
	var result []ParseResult
	var lines = strings.Split(strings.TrimSpace(text), "\n")
	var skip = true
	for _, _line := range lines {
		var line = strings.TrimSpace(_line)
		if strings.HasPrefix(line, "-----") {
			skip = false
			continue
		}
		if skip {
			continue
		}
		var syb = " "
		if strings.Contains(line, ",") {
			syb = ","
		}
		var ss = strings.Split(line, syb)
		if len(ss) <= 1 {
			continue
		}
		result = append(result, ParseResult{ss[0], ss[1]})
	}
	return result
}

func runTaskCheck(pool *pool.Pool, list []ParseResult) []Result {
	var cx sync.Map // map[int][Result]
	for idx, item := range list {
		pool.Go(func() {
			resp, err := req.Get(item.URL)
			log.Info("检查资源", "名称", item.Text, "链接", item.URL)
			var result Result
			result.Name = item.Text
			if err != nil {
				result.Reason = err.Error()
				log.Error("检查资源失败", "名称", item.Text, "链接", item.URL)
			} else {
				var body, err = resp.ToString()
				if err != nil {
					result.OK = false
					log.Error("检查资源失败", "名称", item.Text, "链接", item.URL)
				} else {
					if isOK(body) {
						if pornWords.Check(body) {
							result.Nsfw = true
						}
						result.URL = item.URL
						log.Info("检查资源成功", "名称", item.Text, "链接", item.URL, "NSFW", result.Nsfw)
						result.OK = true
					}
				}
			}
			cx.Store(idx, result)
		})
	}
	pool.Wait()
	var result []Result
	cx.Range(func(key, value any) bool {
		result = append(result, value.(Result))
		return true
	})
	return result
}

func isFileExist(name string) bool {
	if len(name) == 0 {
		return false
	}
	_, err := os.Stat(name)
	return err == nil || !os.IsNotExist(err)
}

func getPornWords() []string {
	var file = "porn.txt"
	if !isFileExist(file) {
		var url = `https://github.com/KATEhuang920909/qiji_compet/raw/22bf28ba7b1ec1e54ae72f171acc7f4f24a02cf9/数据集/NEW_DATA/dicts/色情敏感词.txt`
		req.SetOutputFile(file).MustGet(url)
	}
	buf, err := os.ReadFile(file)
	if err != nil {
		panic(err)
	}
	var lines = strings.Split(string(buf), "\n")
	var porn1 = strings.Split(pornWord1, "\n")
	for _, p := range porn1 {
		lines = append(lines, decodeURL(p))
	}
	return lines
}

type v1 struct {
	Name   string `json:"name"`
	Nsfw   bool   `json:"nsfw"`
	API    v1API  `json:"api"`
	Status bool   `json:"status"`
}

type v1API struct {
	Root string `json:"root"`
	Path string `json:"path"`
}

func main() {
	cx := pool.New().WithMaxGoroutines(12 /* 3 | 6 | 9 */)
	log.Info("开始获取评论列表")
	for _, item := range getPornWords() {
		if len(item) == 0 || item == "伦理片" || item == "伦理电影" || item == "sm" || item == "写真" {
			continue
		}
		pornWords.Insert(item)
	}
	var token = os.Getenv("GITHUB_TOKEN")
	var commentBody = getGithubIssueComments(token)
	log.Info("获取评论列表完成")
	var list []ParseResult
	for _, text := range commentBody {
		for _, val := range getItemWithText(text) {
			// 去重
			if slices.ContainsFunc(list, func(r ParseResult) bool { return r.URL == val.URL }) {
				continue
			}
			log.Info("添加单个资源到列表", "名称", val.Text, "链接", val.URL)
			list = append(list, val)
		}
	}
	if len(list) == 0 {
		log.Error("从 github 评论中未获取到资源")
	}
	log.Info("开始检查资源(共", len(list), "个)")
	var result = runTaskCheck(cx, list)
	var correct = 0
	var err = 0
	var output []v1
	for _, val := range result {
		if val.OK {
			correct++
			var cx, err = url.Parse(val.URL)
			if err != nil {
				panic(err)
			}
			var root = fmt.Sprintf("%s://%s", cx.Scheme, cx.Host)
			var data = v1{Name: val.Name, Nsfw: val.Nsfw, API: v1API{Root: root, Path: cx.Path}, Status: true}
			output = append(output, data)
		} else {
			err++
		}
	}
	log.Info("检查完成", "可用", correct, "不可用", err)
	var outputFile = os.Getenv("OUTPUT")
	if outputFile != "" {
		buf, err := json.MarshalIndent(output, "", "\t")
		if err != nil {
			panic(err)
		}
		os.WriteFile(outputFile, buf, 0644)
	}
}
