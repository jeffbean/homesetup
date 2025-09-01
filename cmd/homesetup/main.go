package main

import (
    "flag"
    "fmt"
    "os"
    "path/filepath"
    "time"

    "homesetup/internal/brew"
    dsl "homesetup/internal/dsl"
    "homesetup/internal/desired"
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
    case "desired":
        fmt.Printf("[+] Profile: %s\n", prof)
        composed, err := brew.ComposeBrewfile(repoRoot, prof, time.Now())
        brewfile := filepath.Join(repoRoot, "Brewfile")
        if composed != "" { brewfile = composed }
        if err != nil { fmt.Fprintf(os.Stderr, "compose Brewfile: %v\n", err) }
        d, err := desired.ParseBrewfile(brewfile)
        if err != nil { fmt.Fprintf(os.Stderr, "parse Brewfile: %v\n", err); os.Exit(1) }
        dir, err := desired.WriteDesiredSnapshot(repoRoot, time.Now(), d)
        if err != nil { fmt.Fprintf(os.Stderr, "write desired: %v\n", err); os.Exit(1) }
        rel, _ := filepath.Rel(repoRoot, dir)
        fmt.Printf("[+] Desired snapshot written: %s\n", rel)
    case "files":
        if fs.NArg() == 0 {
            fmt.Println("usage: homesetup files <plan|apply> [--dry-run]")
            os.Exit(2)
        }
        sub := fs.Arg(0)
        specs, err := dsl.LoadFilesSpec(filepath.Join(repoRoot, "config", "files"))
        if err != nil {
            fmt.Fprintf(os.Stderr, "load specs: %v\n", err)
            os.Exit(1)
        }
        plans := dsl.PlanFiles(repoRoot, specs)
        switch sub {
        case "plan":
            for _, p := range plans {
                fmt.Printf("%s %s\n", p.Action, p.Path)
            }
        case "apply":
            if *dryRun {
                fmt.Println("[+] Dry-run: not writing files. Use --dry-run=false to apply.")
                for _, p := range plans {
                    fmt.Printf("%s %s\n", p.Action, p.Path)
                }
                return
            }
            if err := dsl.ApplyFiles(repoRoot, plans); err != nil {
                fmt.Fprintf(os.Stderr, "apply: %v\n", err)
                os.Exit(1)
            }
        default:
            fmt.Println("usage: homesetup files <plan|apply> [--dry-run]")
        }
    default:
        usage()
    }
}
