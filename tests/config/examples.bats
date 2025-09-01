#!/usr/bin/env bats

@test "ssh and gpg example configs exist" {
  [ -f config/examples/ssh/config ]
  [ -f config/examples/gpg-agent.conf ]
}
