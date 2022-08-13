package main

import (
	"flag"
	"bufio"
	"log"
	"os"
	"strings"
	"time"
	"strconv"
	"fmt"
	"regexp"
)

var cols = map[string]int{
	"domain"   : 0,
	"ip"       : 1,
	"?"        : 2,
	"user?"    : 3,
	"date"     : 4,
	"method"   : 5,
	"path"     : 6,
	"values"   : 7,
	"version"  : 8,
	"status"   : 9,
	"size"     : 10,
	"referer?" : 11,
	"agent"    : 12,
	"fw-ip"    : 13,
	"??"       : 14,
}

type stringsFlag []string

func (i *stringsFlag) String() string {
	return "my string representation"
}

func (i *stringsFlag) Set(v string) error {
	*i = append(*i, v)
	return nil
}

var ire    *regexp.Regexp
var ifs    string
var ofs    string
var sfn    string
var ipdbfn string

var ip2loc []*Ip2LocLine

var fns []string

var skips stringsFlag
var skipsre []*regexp.Regexp

var begin, end time.Time

func init() {
	var err error
	dfmt := "2006-01-02 15:04:05"

	flag.StringVar(&ifs,    "ifs",  "␜",                    "Input Field Separator")
	flag.StringVar(&ofs,    "ofs",  "␜",                    "Output Field Separator")
	flag.StringVar(&ipdbfn, "ipdb", "/etc/ip2location.csv", "IP location database")
	flag.Var(&skips, "skip", "Lines to be skipped")
	b := flag.String("begin", "1900-01-01", "Begin date (YYYY-MM-DD))")
	e := flag.String("end",   "3000-01-01", "End date (YYYY-MM-DD)")
	r := flag.String("ire", "", "Input regex")
	ohf := flag.Bool("openbsd-httpd-fw", false, "OpenBSD's httpd(8) log parsing, fw format")

	flag.Parse()

	if *ohf {
		*r = obsdhttpfwre
		skips = append(skips, `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d*Z .* logfile turned over$`)
	}

	if ip2loc, err = loadIp2Loc(ipdbfn); err != nil {
		log.Fatal(err)
	}

	fns = flag.Args()
	if len(fns) == 0 {
		fns = append(fns, "/dev/stdin")
	}

	begin, err = time.Parse(dfmt, *b + " 00:00:00")
	if err != nil {
		log.Fatal("-begin incorrect format: ", err)
	}

	end, err = time.Parse(dfmt, *e + " 23:59:59")
	if err != nil {
		log.Fatal("-end incorrect format: ", err)
	}

	if *r != "" {
		if ire, err = regexp.Compile(*r); err != nil {
			log.Fatal("ire: bad regexp: ", err)
		}
	}

	for i := 0; i < len(skips); i++ {
		var re *regexp.Regexp
		if re, err = regexp.Compile(skips[i]); err != nil {
			log.Fatal("skips: bad regexp: ", err)
		}
		skipsre = append(skipsre, re)
	}
}

func tweak(fs []string) ([]string, error) {
	dfmt := "02/Jan/2006:15:04:05 -0700"

	t, err := time.Parse(dfmt, fs[cols["date"]])
	if err != nil {
		return nil, err
	}

	// Skip line when not on period
	if t.Before(begin) || t.After(end) {
		return nil, nil
	}

	// https://www.acunetix.com/websitesecurity/crlf-injection/
	// NOTE: disabled: find a real case, and add a test
//	path := fs[cols["path"]]
//	path = strings.ReplaceAll(path, "\r", "")
//	path = strings.ReplaceAll(path, "\n", "")

	// Guess the correct ip field
	ip := fs[cols["ip"]]
	if !isRealIP(ip) {
		ip = fs[cols["fw-ip"]];
	}

	country := ""
	if isRealIP(ip) {
		country, err = locateIp(ip2loc, ip)
		if err != nil {
			return nil, err
		}
	}

	return []string{
		fs[cols["domain"]],
		fs[cols["date"]],
		strconv.FormatInt(t.Unix(), 10),
		fs[cols["method"]],
		fs[cols["path"]],
		fs[cols["status"]],
		fs[cols["version"]],
		country,
		ip,
		fs[cols["values"]],
		fs[cols["agent"]],
	}, nil
}

func main() {
	for _, fn := range fns {
		f, err := os.Open(fn)
		if err != nil {
			log.Fatal(fn, ": ", err);
		}
		if fn == "/dev/stdin" {
			fn = ""
		}
		defer f.Close()
		s := bufio.NewScanner(f)
		for n := 1; s.Scan(); n++ {
			var fs []string

			for i := 0; i < len(skipsre); i++ {
				if skipsre[i].MatchString(strings.ReplaceAll(s.Text(), ofs, "")) {
					goto NextLine
				}
			}

			if ire != nil {
				fs2 := ire.FindAllStringSubmatch(s.Text(), -1)
				if len(fs2) > 0 {
					fs = fs2[0][1:len(fs2[0])]
				} else {
					fmt.Fprintf(os.Stderr, "%s:%d: Regexp failed on %s\n", fn, n, s.Text())
					goto NextLine
				}
			} else {
				fs = strings.Split(s.Text(), ifs)
			}
			fs, err = tweak(fs)
			if err != nil {
				fmt.Fprintf(os.Stderr, "%s:%d: %s %s\n", fn, err, s.Text())
			} else if fs != nil {
				fmt.Println(strings.Join(fs, ofs))
			}
			NextLine:
		}
		if s.Err() != nil {
			log.Fatal(fn, ": ", err)
		}
	}
}
