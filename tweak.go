package main

var obsdhttpfwre = `^([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) \[([^\]]+)\] "([^ ]+) (?:([^ \?]*)(\?[^ ]*)?(?: ([^"]+))?)?" ([0-9]+) ([0-9]+) "([^"]*)" "(.*)" (-|[0-9\.]+) (-|[0-9]+)$`

var obsdauthisore = `(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.[0-9]+Z) [^ ]+ sshd\[[0-9]+\]: (?|Accepted publickey for ([^ ]+) from ([0-9][^ ]+)|Received disconnect from ()([0-9][^ ]+)|User ([^ ]+)() not allowed|error: kex_exchange_identification:()()|Connection closed by ()([0-9][^ ]+)|Connection closed by invalid user ([^ ]+) ([0-9][^ ]+)|Connection closed by authenticating user ([^ ]+) ([0-9][^ ]+)|banner exchange: Connection from ()([0-9][^ ]+)|()()) `

func isRealIP(ip string) bool {
	return ip != "" && ip != "127.0.0.1" && ip != "-"
}
