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
    // Build homesetup inside the container for correct OS/arch, then apply
    buildCmd := "mkdir -p ~/.local/bin && (command -v go >/dev/null 2>&1 && go build -o ~/.local/bin/homesetup ./cmd/homesetup || echo 'Go not found in devpod; skipping build')"
    if err := run("docker", "exec", "-u", "dev", "-w", "/work", "devpod", "bash", "-lc", buildCmd); err != nil {
        slog.Warn("homesetup build inside devpod failed", slog.Any("err", err))
    }
    if err := run("docker", "exec", "-u", "dev", "-w", "/work", "devpod", "bash", "-lc", "~/.local/bin/homesetup apply || true"); err != nil {
        slog.Warn("homesetup apply inside devpod failed", slog.Any("err", err))
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
