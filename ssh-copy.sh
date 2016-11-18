#!/usr/bin/expect
set IP [lindex $argv 0]
set timeout 30
set password [lindex $argv 1]
spawn ssh-copy-id $IP
expect {
"no)" {send "yes\r"; exp_continue}
"password:" {send "$password\r"}
eof { exit }
}

expect eof
exit
