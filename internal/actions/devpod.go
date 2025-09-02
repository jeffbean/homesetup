package actions

import (
    "errors"
    "fmt"
    "os"
    "os/exec"
    "path/filepath"
    "log/slog"
)

func ensureDocker() error {
    if _, err := exec.LookPath("docker"); err != nil {
        return errors.New("docker not installed")
    }
    return nil
}

func DevpodUp() error {
    if err := ensureDocker(); err != nil { return err }
    // Build image
    if _, err := os.Stat("Dockerfile.devpod"); err == nil {
        if err := run("docker", "build", "-t", "devpod-base:latest", "-f", "Dockerfile.devpod", "."); err != nil {
            slog.Error("docker build failed", slog.Any("err", err))
            return err
        }
    } else {
        slog.Warn("Dockerfile.devpod not found; expecting image pre-built", slog.String("file", "Dockerfile.devpod"))
    }
    // Remove existing container if present
    _ = exec.Command("docker", "rm", "-f", "devpod").Run()

    // Run container
    cwd, _ := os.Getwd()
    if err := run("docker", "run", "-d",
        "--name", "devpod",
        "-v", fmt.Sprintf("%s:/work", cwd),
        "-w", "/work",
        "-e", "HOME=/home/dev",
        "devpod-base:latest"); err != nil {
        slog.Error("docker run failed", slog.Any("err", err))
        return err
    }
    // Copy homesetup binary if present and run apply inside
    bin := filepath.Join("bin", "homesetup")
    if fi, err := os.Stat(bin); err == nil && fi.Mode().Perm()&0100 != 0 {
        _ = run("docker", "cp", bin, "devpod:/usr/local/bin/homesetup")
        if err := run("docker", "exec", "-u", "dev", "-w", "/work", "devpod", "homesetup", "apply"); err != nil {
            slog.Warn("homesetup apply inside devpod failed", slog.Any("err", err))
        }
    } else {
        slog.Warn("homesetup binary not found; skipping apply", slog.String("path", bin))
    }
    slog.Info("devpod up", slog.String("workdir", cwd))
    return nil
}

func DevpodShell() error {
    if err := ensureDocker(); err != nil { return err }
    return run("docker", "exec", "-it", "-u", "dev", "-w", "/work", "devpod", "zsh")
}

func DevpodDown() error {
    if err := ensureDocker(); err != nil { return err }
    if err := run("docker", "rm", "-f", "devpod"); err != nil {
        slog.Warn("docker rm failed", slog.Any("err", err))
        return err
    }
    slog.Info("devpod down")
    return nil
}

