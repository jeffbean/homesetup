package actions

import (
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

func Plan() error {
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
