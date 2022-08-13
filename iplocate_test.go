package main

import (
	"testing"
	"fmt"
	"strings"
)

func TestIpv4Num(t *testing.T) {
	doTests(t, []test{
		{
			"0.0.0.0 -> 0",
			ipv4Num,
			[]interface{}{"0.0.0.0"},
			[]interface{}{
				0,
				nil,
			},
		},
		{
			"127.0.0.1 -> (127<<24)+1",
			ipv4Num,
			[]interface{}{"127.0.0.1"},
			[]interface{}{
				(127<<24)+1,
				nil,
			},
		},
		{
			"Invalid IPv4",
			ipv4Num,
			[]interface{}{"noise"},
			[]interface{}{
				0,
				fmt.Errorf("'noise' is not an IPv4"),
			},
		},
	})
}

func TestParseIp2LocLine(t *testing.T) {
	// A bare nil break the current comparison routine.
	var null *Ip2LocLine

	doTests(t, []test{
		{
			"~empty line",
			parseIp2LocLine,
			[]interface{}{[]string{}},
			[]interface{}{
				null,
				fmt.Errorf("not enough fields"),
			},
		},
		{
			"Invalid starting IP",
			parseIp2LocLine,
			[]interface{}{[]string{"XXX","16777215","-","-"}},
			[]interface{}{
				null,
				fmt.Errorf("'XXX' is not an integer"),
			},
		},
		{
			"Invalid ending IP",
			parseIp2LocLine,
			[]interface{}{[]string{"16777215","YYY","-","-"}},
			[]interface{}{
				null,
				fmt.Errorf("'YYY' is not an integer"),
			},
		},
		{
			"half-full correct line",
			parseIp2LocLine,
			[]interface{}{[]string{"0","16777215","-","-"}},
			[]interface{}{
				&Ip2LocLine{
					0, 16777215, "-", "-",
				},
				nil,
			},
		},
		{
			"full correct line",
			parseIp2LocLine,
			[]interface{}{[]string{"16777216","16777471","US","United States of America"}},
			[]interface{}{
				&Ip2LocLine{
					16777216, 16777471, "US", "United States of America",
				},
				nil,
			},
		},
		{
			"Can read valid IP2LOCATION-LITE-DB11.CSV lines",
			parseIp2LocLine,
			[]interface{}{[]string{
				"16797696","16797951","JP","Japan","Shimane",
				"Matsue","35.467000","133.050000",
				"690-0015","+09:00",
			}},
			[]interface{}{
				&Ip2LocLine{
					16797696, 16797951, "JP", "Japan",
				},
				nil,
			},
		},
	})
}

func TestParseIp2Loc(t *testing.T) {
//	var null []*Ip2LocLine

	doTests(t, []test{
		{
			"Quoted fields with coma (CSV handling works)",
			parseIp2Loc,
			[]interface{}{strings.NewReader(`"86155264","86157311","PS","Palestine, State of"`)},
			[]interface{}{
				[]*Ip2LocLine{
					&Ip2LocLine{
						86155264,86157311,"PS","Palestine, State of",
					},
				},
				nil,
			},
		},
	})
}

func TestLocateIp(t *testing.T) {
	var i2n = func(s string) int {
		n, _ := ipv4Num(s)
		return n
	}
	doTests(t, []test{
		{
			"empty db/not an IP",
			locateIp,
			[]interface{}{[]*Ip2LocLine{}, "1.0.3"},
			[]interface{}{
				"",
				fmt.Errorf("'1.0.3' is not an IPv4"),
			},
		},
		{
			"empty db",
			locateIp,
			[]interface{}{[]*Ip2LocLine{}, "1.0.3.200"},
			[]interface{}{
				"Unknown",
				nil,
			},
		},
		{
			"non-empty db; unknown IP",
			locateIp,
			[]interface{}{[]*Ip2LocLine{
				&Ip2LocLine{
					i2n("1.0.0.0"),
					i2n("1.0.0.255"),
					"US",
					"United States of America",
				},
				&Ip2LocLine{
					i2n("1.0.1.0"),
					i2n("1.0.3.255"),
					"CN",
					"China",
				},
			}, "1.0.4.200"},
			[]interface{}{
				"Unknown",
				nil,
			},
		},
		{
			"non-empty db; Chinese IP",
			locateIp,
			[]interface{}{[]*Ip2LocLine{
				&Ip2LocLine{
					i2n("1.0.0.0"),
					i2n("1.0.0.255"),
					"US",
					"United States of America",
				},
				&Ip2LocLine{
					i2n("1.0.1.0"),
					i2n("1.0.3.255"),
					"CN",
					"China",
				},
			}, "1.0.3.200"},
			[]interface{}{
				"China",
				nil,
			},
		},
	})
}
