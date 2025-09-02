package actions

import (
    "fmt"
    "os"
    "os/exec"
)

func BrewInstall() error {
    if _, err := exec.LookPath("brew"); err != nil {
        return fmt.Errorf("Homebrew not installed")
    }
    bf := brewfile()
    if _, err := os.Stat(bf); err != nil {
        return fmt.Errorf("Brewfile not found: %s", bf)
    }
    return run("brew", "bundle", "--file="+bf)
}

