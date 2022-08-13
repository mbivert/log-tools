package main

// https://www.ip2location.com/

import (
	"fmt"
	"encoding/csv"
	"os"
	"strconv"
	"io"
)

type Ip2LocLine struct {
	from    int
	to      int
	a2      string
	country string
}

// Surprisingly, net.IP doesn't seem to have helpers for that
// (https://commandcenter.blogspot.com/2012/04/byte-order-fallacy.html)
func ipv4Num(ip string) (int, error) {
	var a, b, c, d int
	_, err := fmt.Sscanf(ip, "%d.%d.%d.%d", &a, &b, &c, &d)
	if err != nil {
		return 0, fmt.Errorf("'%s' is not an IPv4", ip)
	}
	return (d<<0) | (c<<8) | (b<<16) | (a<<24), nil
}

func parseIp2LocLine(fs []string) (*Ip2LocLine, error) {
	if len(fs) < 4 {
		return nil, fmt.Errorf("not enough fields")
	}

	from, err := strconv.Atoi(fs[0])
	if err != nil {
		return nil, fmt.Errorf("'%s' is not an integer", fs[0])
	}
	to, err := strconv.Atoi(fs[1])
	if err != nil {
		return nil, fmt.Errorf("'%s' is not an integer", fs[1])
	}

	return &Ip2LocLine {
		from    : from,
		to      : to,
		a2      : fs[2],
		country : fs[3],
	}, nil
}

func parseIp2Loc(f io.Reader) ([]*Ip2LocLine, error) {
	var xs []*Ip2LocLine
	r := csv.NewReader(f)

	for n := 1;; n++ {
		var x *Ip2LocLine
		fs, err := r.Read()
		if err == io.EOF {
			break
		}
		if err == nil {
			x, err = parseIp2LocLine(fs)
		}
		if err != nil {
			return nil, fmt.Errorf("%d: %s", n, err)
		}
		xs = append(xs, x)
	}

	return xs, nil
}

func loadIp2Loc(fn string) ([]*Ip2LocLine, error) {
	var ip2loc []*Ip2LocLine
	fh, err := os.Open(fn)
	if err == nil {
		ip2loc, err = parseIp2Loc(fh)
	}
	if err != nil {
		return nil, fmt.Errorf("%s:%s", fn, err)
	}

	return ip2loc, nil
}

// we could be smarter
func locateIpNum(ip2loc []*Ip2LocLine, ipn int) string {
	for _, il := range ip2loc {
		if ipn >= il.from && ipn <= il.to {
			return il.country
		}
	}

	return "Unknown"
}

func locateIp(ip2loc []*Ip2LocLine, ip string) (string, error) {
	n, err := ipv4Num(ip)
	if err != nil {
		return "", err
	}

	return locateIpNum(ip2loc, n), nil
}
