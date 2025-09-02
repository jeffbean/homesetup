package main

import (
    "flag"
    "fmt"
    "homesetup/internal/actions"
    "log/slog"
    "os"
)

func usage() {
	fmt.Println("homesetup <plan|apply|apply-dotfiles|brew>")
}

func main() {
    // setup default slog logger (text to stderr)
    slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{})))
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
