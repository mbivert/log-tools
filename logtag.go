package main

import (
	"flag"
	"os"
	"io/ioutil"
	"log"
	"regexp"
	"encoding/json"
	"strings"
	"bufio"
	"strconv"
	"fmt"
)

var cols map[string]int

// see the encoding.TextMarshaler interface
func (r *JsonRegexp) UnmarshalText(text []byte) error {
    re, err := regexp.Compile(string(text))
    if err != nil {
        return err
    }
    *r = JsonRegexp{*re}
    return nil
}

func (x *JsonColString) UnmarshalText(text []byte) error {
	y := string(text)
	if _, ok := cols[y]; !ok {
        return fmt.Errorf("'%s': unknown column", y)
    }
    *x = JsonColString{y}
    return nil
}

var ifs string
var ofs string
var ots string
var fns []string
var rules []Rule

func init() {
	var s string
	var rfn string

	flag.StringVar(&ifs,   "ifs",   "␜",   "Input Field Separator")
	flag.StringVar(&ofs,   "ofs",   "␜",   "Output Field Separator")
	flag.StringVar(&s,     "cols",  "",    "Input columns name, coma separated")
	flag.StringVar(&ots,   "ts",    ",",   "Output Tag Separator")
	flag.StringVar(&rfn,   "rules", "",    "Path to rules' file")
	ohf := flag.Bool("openbsd-httpd-fw", false, "Input is from logtweak -openbsd-httpd-fw")

	flag.Parse()

	// convenience
	if *ohf {
		s = "domain,date,ts,method,path,status,version,country,ip,values,agent"
	}

	fns = flag.Args()
	if len(fns) == 0 {
		fns = append(fns, "/dev/stdin")
	}

	cols = make(map[string]int)
	for n, s := range strings.Split(s, ",") {
		cols[s] = n
	}

	rules = make([]Rule, 0)
	if rfn != "" {
		v, err := ioutil.ReadFile(rfn)
		if err != nil {
			log.Fatal("rules file:", err)
		}

		var rs []Rule

		if err := json.Unmarshal(v, &rs); err != nil {
			log.Fatal(rfn, ":", err)
		}
		rules = append(rules, rs...)
	}
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
			fs := strings.Split(s.Text(), ifs)
			fs, err = tag(cols, fs)
			if err != nil {
				log.Println(fn+":"+strconv.Itoa(n), err, s.Text())
			} else {
				fmt.Println(strings.Join(fs, ofs))
			}
		}
		if s.Err() != nil {
			log.Fatal(fn, ": ", err);
		}
	}
}
