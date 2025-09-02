package actions

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

func ApplyDotfiles() error {
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

func Apply() error {
	if err := ApplyDotfiles(); err != nil {
		return err
	}
	if _, err := exec.LookPath("tmux"); err == nil {
		_ = run("tmux", "source-file", filepath.Join(os.Getenv("HOME"), ".tmux.conf"))
	}
	fmt.Println("[+] Dotfiles stowed. If your prompt changed, run: exec zsh -l")
	return nil
}
