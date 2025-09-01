package main

import (
    "flag"
    "fmt"
    "os"
    "path/filepath"
    "time"

    "homesetup/internal/brew"
    "homesetup/internal/profile"
)

func usage() {
    fmt.Println("homesetup <plan|diff|apply> [--dry-run]")
}

func main() {
    if len(os.Args) < 2 {
        usage()
        os.Exit(0)
    }
    cmd := os.Args[1]
    fs := flag.NewFlagSet(cmd, flag.ExitOnError)
    dryRun := fs.Bool("dry-run", true, "dry-run (no changes)")
    _ = fs.Parse(os.Args[2:])

    // Resolve repo root as current working dir
    cwd, _ := os.Getwd()
    repoRoot := cwd

    // Resolve active profile (defaults to base)
    prof := profile.ActiveProfile()

    switch cmd {
    case "plan":
        fmt.Printf("[+] Profile: %s\n", prof)
        composed, err := brew.ComposeBrewfile(repoRoot, prof, time.Now())
        if err != nil {
            fmt.Fprintf(os.Stderr, "compose Brewfile: %v\n", err)
        }
        if composed != "" {
            rel, _ := filepath.Rel(repoRoot, composed)
            fmt.Printf("[+] Composed Brewfile: %s\n", rel)
        } else {
            fmt.Println("[+] Using base Brewfile (no profile extras)")
        }
        fmt.Printf("[+] Dry-run: %v\n", *dryRun)
    case "diff":
        fmt.Printf("[+] Profile: %s\n", prof)
        fmt.Println("[+] Use 'make diff' to generate a Markdown report")
    case "apply":
        fmt.Printf("[+] Profile: %s\n", prof)
        if *dryRun {
            fmt.Println("[+] Dry-run apply: use 'make apply' for full pipeline")
        } else {
            fmt.Println("[+] For now, run 'make apply' (shell pipeline)")
        }
    default:
        usage()
    }
}

