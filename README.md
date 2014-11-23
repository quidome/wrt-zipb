# Description
I've used these scripts for a while on my tomato wrt router. I needed the public IP address of my internet connection on my WRT router and this required me to use zipb functionality on the copperjet 1616-2P. Both the copperjet and its zipb implementation are a bit unstable.

This script keeps an eye on the ip configuration and fixes the zipb setup whenever needed. The script also recognizes problems with enabling zipb and resets the copperjet whenever needed.

# Installation
I ran the scripts from /jffs/bin.
I kept check states in /tmp/fail_count

From the tomato job scheduler I ran the modem_check.sh every minute and modem_reset.sh once a week (in the middle of the night).

There isn't much more to these scripts than that.

