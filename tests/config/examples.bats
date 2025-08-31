#!/usr/bin/env bats

@test "ssh and gpg example configs exist" {
  [ -f config/ssh/config.example ]
  [ -f config/gpg-agent.conf.example ]
}

