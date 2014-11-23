#!/bin/sh

# script found on the internet and heavily altered to fit my needs
# the script was written for a dd-wrt, I'm using tomato
# further more I encounter lots of problems which I totally wish to fix

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/jffs/sbin:/jffs/bin:/jffs/usr/sbin:/jffs/usr/bin

############################################################
# settings
############################################################
ident=modemcheck
pinghost=8.8.8.8
pinghostname=google-public-dns-a.google.com

# involved equipment
# wan
wanip=<your external ip address>
wanname=<fqdn of your external ip>

# modem
modemip=<ip address of your copperjet> # default: 172.19.3.1
modemname=<name of your copperjet>
modemuser=admin
modempass=admin # BBned Alice password: bb@l1cE322

# router
routerip=`ifconfig vlan1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
routername=<name of your wrt>

# threshold before reseting modem
zipb_threshold=5
inet_threshold=3


############################################################
# Load functions from seperate file
. f_zipb.sh



############################################################
# main script starts here
############################################################

# We'll have to figure out a way to make this setup stable. We're doing some checks
# - See if we can reach aapzak.nl website from here
# - See if we can reach external websites

# If external becomes unreachable, the modem probably has lost its connection
# the router won't be connecting automaticly till the next scheduled dhcp renew

# After modem reset:
# - %%ZIPB-0-ACTIVE%% Zipb is configured correctly
# - %%INET-5-UNREACABLE%% External websites are unreachable
#
# a dhcp renew should be performed on the router

# After dhcp renew inet is reachable but zipb seems to be disabled
# - %%ZIPB-5-INACTIVE%% Zipb is not configured correctly
# - %%INET-0-REACABLE%% External websites are reachable
#
# zipb should be reconfigured on the modem

#	inet	zipb	result
#	0		0		check/fix modem, fix internet, fix zipb
#	0		1		modem lost connection, renew lease
#	1		0		check/fix modem, fix zipb
#	1		1		do nothing



# What should the checks be like?

# outside reachable?
# yes:are we external interface?
# 	yes:OK, exit
# 	no:	can we reach modem?
# 		yes:fix zipb, exit
# 		no:	dhcpc_renew, exit
# no:	modem reachable?
# 	yes:fix internet, exit
# 	no:	dhcpc_renew, exit


# do all checks first:

# create file to keep track of failures:
touch /tmp/fail_count


# check and set external reachability
result_ext=`ping -c 1 $pinghost | grep -c from`
if [ $result_ext == 1 ]; then
	log "%%NET-0-REACHABILITY%% $pinghost reachable"
	sed -i '/e/d' /tmp/fail_count


	# see if dns is working
	result_dns=`ping -c 1 $pinghostname | grep -c from`
	if [ $result_dns == 1 ]; then
		log "%%NET-0-REACHABILITY%% $pinghostname reachable"
		sed -i '/d/d' /tmp/fail_count
	else
		# $pinghost not reachable
		log "%%NET-5-REACHABILITY%% $pinghostname unreachable"
		echo "d" >> /tmp/fail_count
	fi


else
	log "%%NET-5-REACHABILITY%% $pinghost unreachable"
	echo "e" >> /tmp/fail_count
fi




# check and set modem reachability
result_modem=`ping -c 1 $modemip | grep -c from`
if [ $result_modem == 1 ]; then
	log "%%ROUTER-0-REACHABILITY%% $modemname reachable"
	sed -i '/m/d' /tmp/fail_count
else
	log "%%ROUTER-5-REACHABILITY%% $modemname unreachable"
	echo "m" >> /tmp/fail_count
fi


# check and set zipb status
if [ "$routerip" == "$wanip" ]; then
	log "%%MODEM-0-ZIPB%% $routername has ip: $routerip"
	sed -i '/z/d' /tmp/fail_count
else
	log "%%MODEM-5-ZIPB%% $routername has ip: $routerip"
	echo "z" >> /tmp/fail_count
fi




# outside reachable?
if [ $result_ext == 1 ]; then
	# yes:are we external interface?
	if [ "$routerip" == "$wanip" ]; then
		# yes:OK, exit
		log "all well, exit"
		exit 0
	else
		# no:	can we reach modem?
		# check modem availability
		if [ $result_modem == 1 ]; then
			# yes:fix zipb, exit
			log "fix zipb and get outta here"

			# see how many failures we have
			if [ `grep -c z /tmp/fail_count` -ge $zipb_threshold ]; then
				# Three or more failures of trying to get zipb working
				log "$zipb_threshold failures, resetting modem"
				modem_reset
				> /tmp/fail_count
			else
				log "didn't reach $zipb_threshold failures, lets try the easy way"

				# show ourself to the modem
				log "showing ourself to the modem"
				dhcpc-renew ; sleep 5

				# configure zipb completely
				log "do a complete zipb config"
				zipb_configure ; sleep 5
				# reset zipb device
				log "reset zipb"
				zipb_reset ; sleep 5

				# dhcp_renew
				log "renew wan interface"
				dhcpc-renew
			fi

		else
			# no:	dhcpc_renew, exit
			log "dhcp renew and exit"
			dhcpc-release; sleep 2 ; dhcpc-renew
			exit 1
		fi
	fi
else
	# no:	modem reachable?

	# start with renewing ip
	log "no internet: renew dhcp"
	dhcpc-release; sleep 5 ; dhcpc-renew; sleep 5
	routerip=`ifconfig vlan1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
	log "routerip after renew: $routerip"


	# check and set modem reachability
	result_modem=`ping -c 1 $modemip | grep -c from`
	if [ $result_modem == 1 ]; then
		log "%%ROUTER-0-REACHABILITY%% $modemname reachable"
		sed -i '/m/d' /tmp/fail_count
	else
		log "%%ROUTER-5-REACHABILITY%% $modemname unreachable"
		echo "m" >> /tmp/fail_count
	fi


	if [ $result_modem == 1 ]; then
		# yes:fix internet, exit
		log "wow, gtg fix the internet"
		# be patient, no instant resetting:

		# see how many failures we have
		if [ `grep -c e /tmp/fail_count` -ge $inet_threshold ]; then
			# Three or more failures of pinging the outside
			log "$inet_threshold failures, resetting modem"
			modem_reset
			> /tmp/fail_count
		else
			log "didn't reach $inet_threshold failures, lets wait"
		fi
	else
		exit 1
	fi
fi

exit 0
