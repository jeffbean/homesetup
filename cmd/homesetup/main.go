package main

import (
    "flag"
    "fmt"
    "os"
    "os/exec"
    "path/filepath"
)

func brewfile() string {
    if bf := os.Getenv("HS_BREWFILE"); bf != "" {
        return bf
    }
    return filepath.Join("config", "Brewfile")
}

func run(name string, args ...string) error {
    cmd := exec.Command(name, args...)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    cmd.Stdin = os.Stdin
    return cmd.Run()
}

func plan() error {
    fmt.Println("[+] Homebrew dry-run (bundle check)")
    bf := brewfile()
    if _, err := os.Stat(bf); err == nil {
        _ = run("brew", "bundle", "check", "--file="+bf)
    } else {
        fmt.Printf("Brewfile not found: %s\n", bf)
    }
    fmt.Println("---")
    fmt.Println("[+] Dotfiles stow preview (no changes)")
    if _, err := exec.LookPath("stow"); err == nil {
        if _, err := os.Stat("dotfiles"); err == nil {
            entries, _ := os.ReadDir("dotfiles")
            for _, e := range entries {
                if e.IsDir() {
                    fmt.Printf("Preview: %s\n", e.Name())
                    _ = run("stow", "-nvt", os.Getenv("HOME"), "-d", "dotfiles", e.Name())
                }
            }
        } else {
            fmt.Println("dotfiles directory not found")
        }
    } else {
        fmt.Println("stow not installed (brew install stow)")
    }
    return nil
}

func applyDotfiles() error {
    if _, err := exec.LookPath("stow"); err != nil {
        return fmt.Errorf("stow not installed (brew install stow)")
    }
    if _, err := os.Stat("dotfiles"); err != nil {
        return fmt.Errorf("dotfiles directory not found")
    }
    entries, _ := os.ReadDir("dotfiles")
    for _, e := range entries {
        if e.IsDir() {
            fmt.Printf("Stowing: %s\n", e.Name())
            if err := run("stow", "--no-folding", "-d", "dotfiles", "-vt", os.Getenv("HOME"), e.Name()); err != nil {
                return err
            }
        }
    }
    return nil
}

func apply() error {
    if err := applyDotfiles(); err != nil {
        return err
    }
    // Reload tmux config if tmux exists
    if _, err := exec.LookPath("tmux"); err == nil {
        _ = run("tmux", "source-file", filepath.Join(os.Getenv("HOME"), ".tmux.conf"))
    }
    fmt.Println("[+] Dotfiles stowed. If your prompt changed, run: exec zsh -l")
    return nil
}

func brewInstall() error {
    if _, err := exec.LookPath("brew"); err != nil {
        return fmt.Errorf("Homebrew not installed")
    }
    bf := brewfile()
    if _, err := os.Stat(bf); err != nil {
        return fmt.Errorf("Brewfile not found: %s", bf)
    }
    return run("brew", "bundle", "--file="+bf)
}

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
    _ = fs.Parse(os.Args[2:])
    var err error
    switch cmd {
    case "plan":
        err = plan()
    case "apply-dotfiles":
        err = applyDotfiles()
    case "apply":
        err = apply()
    case "brew":
        err = brewInstall()
    default:
        usage()
    }
    if err != nil {
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
}

