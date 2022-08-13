package main

import (
	"strings"
	"regexp"
	"fmt"
)

type JsonRegexp struct {
	regexp.Regexp
}

type JsonColString struct {
	string
}

type Rule struct {
	Exprs      map[JsonColString]JsonRegexp `json:exprs`
	Tags       []string                     `json:tags`
	Continue   bool                         `json:continue`
}

func tag(cols map[string]int, fs []string) ([]string, error) {
	tags := make([]string, 0)
	for _, r := range rules {
		for f, e := range r.Exprs {
			if cols[f.string] >= len(fs) {
				return nil, fmt.Errorf("Not enough fields to reach '%s' in %s'", f, fs)
			}
			if ! e.MatchString(fs[cols[f.string]]) {
				goto skip
			}
		}

		tags = append(tags, r.Tags...)
		if !r.Continue {
			break;
		}

		skip:
	}
	return append(fs, strings.Join(tags, ots)), nil
}
