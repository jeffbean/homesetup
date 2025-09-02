package main

import (
    "flag"
    "fmt"
    "homesetup/internal/actions"
    "log/slog"
    "os"
)

func usage() {
    fmt.Println("homesetup <plan|apply|apply-dotfiles|brew|devpod up|shell|down>")
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
    case "devpod":
        args := fs.Args()
        if len(args) == 0 {
            usage()
            return
        }
        switch args[0] {
        case "up":
            err = actions.DevpodUp()
        case "shell":
            err = actions.DevpodShell()
        case "down":
            err = actions.DevpodDown()
        default:
            usage()
        }
    default:
        usage()
    }
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
