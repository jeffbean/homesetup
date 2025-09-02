package main

import (
    "flag"
    "fmt"
    "os"
    "homesetup/internal/actions"
)













func usage() {
	fmt.Println("homesetup <plan|apply|apply-dotfiles|brew>")
}

func main() {
	if len(os.Args) < 2 {
		usage()
		return
	}
	cmd := os.Args[1]
	fs := flag.NewFlagSet(cmd, flag.ExitOnError)
	// flag.ExitOnError allows us to ignore this error.
	_ = fs.Parse(os.Args[2:])

	var err error
	switch cmd {
	case "plan":
		err = actions.Plan()
	case "apply-dotfiles":
		err = actions.ApplyDotfiles()
	case "apply":
		err = actions.Apply()
	case "brew":
		err = actions.BrewInstall()
	default:
		usage()
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
