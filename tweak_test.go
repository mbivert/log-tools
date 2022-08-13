package main


import (
	"testing"
	"regexp"
)

// Helper to validate special regexp
func applyRe(r, s string) ([]string) {
	var re *regexp.Regexp
	var err error
	if re, err = regexp.Compile(r); err != nil {
		panic("re: bad regexp: "+err.Error())
	}
	fs := re.FindAllStringSubmatch(s, -1)
	if len(fs) == 0 || len(fs[0]) < 2 {
		return []string{}
	}
	return fs[0][1:len(fs[0])]
}


func TestIsRealIP(t *testing.T) {
	doTests(t, []test{
		{
			"empty string is not a real ip",
			isRealIP,
			[]interface{}{""},
			[]interface{}{false},
		},
		{
			"'-' is not a real IP",
			isRealIP,
			[]interface{}{"-"},
			[]interface{}{false},
		},
		{
			"127.0.0.2 is a 'real' IP",
			isRealIP,
			[]interface{}{"127.0.0.2"},
			[]interface{}{true},
		},
	})
}

func TestOpenBSDHTTPFwRe(t *testing.T) {
	doTests(t, []test{
		{
			"empty string is not a real ip",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`http-to-https 167.94.138.62 - - [23/Jul/2022:09:09:58 +0200] "<UNKNOWN> " 400 0 "" "" - -`,
			},
			[]interface{}{[]string{
				"http-to-https",
				"167.94.138.62",
				"-",
				"-",
				"23/Jul/2022:09:09:58 +0200",
				"<UNKNOWN>",
				"",
				"",
				"",
				"400",
				"0",
				"",
				"",
				"-",
				"-",
			}},
		},
		{
			"Full valid request",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`tales.mbivert.com 127.0.0.1 - - [23/Jul/2022:09:34:25 +0200] "GET /fr/de-quelques-outils-pour-acme-plan9/?x=1 HTTP/1.1" 200 13105 "https://tales.mbivert.com/fr/" "Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)" 114.119.136.109 -`,
			},
			[]interface{}{[]string{
				"tales.mbivert.com",
				"127.0.0.1",
				"-",
				"-",
				"23/Jul/2022:09:34:25 +0200",
				"GET",
				"/fr/de-quelques-outils-pour-acme-plan9/",
				"?x=1",
				"HTTP/1.1",
				"200",
				"13105",
				"https://tales.mbivert.com/fr/",
				"Mozilla/5.0 (Linux; Android 7.0;) AppleWebKit/537.36 (KHTML, like Gecko) Mobile Safari/537.36 (compatible; PetalBot;+https://webmaster.petalsearch.com/site/petalbot)",
				"114.119.136.109",
				"-",
			}},
		},
		{
			"Valid 301",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`http-to-https 221.2.163.231 - - [03/Jul/2022:01:53:00 +0200] "GET / HTTP/1.1" 301 0 "" "Mozilla/5.0" - -`,
			},
			[]interface{}{[]string{
				"http-to-https",
				"221.2.163.231",
				"-",
				"-",
				"03/Jul/2022:01:53:00 +0200",
				"GET",
				"/",
				"",
				"HTTP/1.1",
				"301",
				"0",
				"",
				"Mozilla/5.0",
				"-",
				"-",
			}},
		},
		{
			"Quote injection",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`http-to-https 221.2.163.231 - - [03/Jul/2022:01:53:00 +0200] "GET / HTTP/1.1" 301 0 "" ""Mozilla/5.0" - -`,
			},
			[]interface{}{[]string{
				"http-to-https",
				"221.2.163.231",
				"-",
				"-",
				"03/Jul/2022:01:53:00 +0200",
				"GET",
				"/",
				"",
				"HTTP/1.1",
				"301",
				"0",
				"",
				`"Mozilla/5.0`,
				"-",
				"-",
			}},
		},
		{
			"Random request",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`www.zhongmu.eu 127.0.0.1 - - [26/Jun/2022:00:13:06 +0200] "GET / HTTP/1.1" 301 0 "" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36" 8.26.182.26 -`,
			},
			[]interface{}{[]string{
				"www.zhongmu.eu",
				"127.0.0.1",
				"-",
				"-",
				"26/Jun/2022:00:13:06 +0200",
				"GET",
				"/",
				"",
				"HTTP/1.1",
				"301",
				"0",
				"",
				"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36",
				"8.26.182.26",
				"-",
			}},
		},
		{
			"CONNECT, not followed by a path (/ started)",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`http-to-https 89.248.165.52 - - [07/Aug/2022:00:47:29 +0200] "CONNECT hotmail-com.olc.protection.outlook.com:25 HTTP/1.1" 400 0 "" "" - -`,
			},
			[]interface{}{[]string{
				"http-to-https",
				"89.248.165.52",
				"-",
				"-",
				"07/Aug/2022:00:47:29 +0200",
				"CONNECT",
				"hotmail-com.olc.protection.outlook.com:25",
				"",
				"HTTP/1.1",
				"400",
				"0",
				"",
				"",
				"-",
				"-",
			}},
		},
		{
			"OPTIONS, no HTTP version",
			applyRe,
			[]interface{}{
				obsdhttpfwre,
				`http-to-https 172.104.159.48 - - [31/Jul/2022:09:30:29 +0200] "OPTIONS /" 400 0 "" "" - -`,
			},
			[]interface{}{[]string{
				"http-to-https",
				"172.104.159.48",
				"-",
				"-",
				"31/Jul/2022:09:30:29 +0200",
				"OPTIONS",
				"/",
				"",
				"",
				"400",
				"0",
				"",
				"",
				"-",
				"-",
			}},
		},
		//
	})
}
