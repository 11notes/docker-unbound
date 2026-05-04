package main

import (
  "github.com/11notes/go-eleven"
)

const APP_BIN string = "unbound"
const APP_CONFIG string = "UNBOUND_CONFIG"
const APP_CONFIG_FILE string = "/unbound/etc/default.conf"

func main(){
	// write env to file if set
	eleven.Container.EnvToFile(APP_CONFIG, APP_CONFIG_FILE)

	// start app and replace process with it
	eleven.Container.Run("/usr/local/bin", APP_BIN, []string{"-p", "-d", "-c", APP_CONFIG_FILE})
}