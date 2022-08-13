package main

import (
	"flag"
	"fmt"
	"log"
	"os"
)

var ipdbfn string
var ip2loc []*Ip2LocLine
var ips    []string

func init() {
	var err error
	flag.StringVar(&ipdbfn, "ipdb", "/etc/ip2location.csv", "IP location database")

	flag.Parse()

	if ip2loc, err = loadIp2Loc(ipdbfn); err != nil {
		log.Fatal(err)
	}
	ips = flag.Args()
}

func main() {
	for _, ip := range ips {
		country, err := locateIp(ip2loc, ip)
		if err != nil {
			fmt.Fprintf(os.Stderr, "'%s': cannot localize, %s\n", ip, err)
		} else {
			fmt.Println(country)
		}
	}
}