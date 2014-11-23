################################################################################
# This file is an attempt to extract all functions for
# the script from the script itself
################################################################################


################################################################################
# functions
################################################################################


########################################
# local router functions


########################################
# dhcp_reset
dhcp_renew() {
	dhcp_release
	dhcp_renew_o
}

########################################
# release_dhcp
dhcp_release() {
	kill -USR2 `ps | grep -v awk | awk '/udhcpc/ {print $1}'`
	sleep 2
}

########################################
# dhcp_renew_o
# the o stands for original or only
dhcp_renew_o() {
	kill -USR1 `ps | grep -v awk | awk '/udhcpc/ {print $1}'`
	sleep 2
}


########################################
# modem functions


########################################
# zipb_enable
zipb_enable() {
	(	sleep 1; echo -e "$modemuser\r" 
		sleep 1; echo -e "$modempass\r"
		sleep 1; echo -e "zipb enable\r"
		sleep 1; echo -e "user logout\r") | telnet $modemip
}


########################################
# zipb_disable
zipb_disable() {
	(	sleep 1; echo -e "$modemuser\r" 
		sleep 1; echo -e "$modempass\r"
		sleep 1; echo -e "zipb disable\r"
		sleep 1; echo -e "user logout\r") | telnet $modemip
}

########################################
# zipb_configure
zipb_configure() {
	(	sleep 1
		sleep 1 ; echo -e "$modemuser\r"
		sleep 1 ; echo -e "$modempass\r"
		sleep 1 ; echo -e "zipb disable\r"
		sleep 1 ; echo -e "zipb set lan interface ethernet-0\r"
		sleep 1 ; echo -e "zipb set lan ipaddress 0.0.0.0\r"
		sleep 1 ; echo -e "zipb set lan leasetime 40\r"
		sleep 1 ; echo -e "zipb set lan mask 0.0.0.0\r"
		sleep 1 ; echo -e "zipb set lan powerdowntime 120\r"
		sleep 1 ; echo -e "zipb set lan spoofmethod 'Use PPP server address'\r"
		sleep 1 ; echo -e "zipb set lan subnetselect Natural\r"
		sleep 1 ; echo -e "zipb set wan interface ppp-0\r"
		sleep 1 ; echo -e "zipb enable\r"
		sleep 1 ; echo -e "system config save\r"
		sleep 1 ; echo -e "user logout\r"	) | telnet $modemip
}

########################################
# zipb_configure_public_device
zipb_reset() {
	(	
		sleep 1 ; echo -e "$modemuser\r"
		sleep 1 ; echo -e "$modempass\r"
		sleep 1 ; echo -e "zipb clear public device\r"
		sleep 2 ; echo -e "zipb set public device $routername\r"
		sleep 5 ; echo -e "dhcpserver forcerenew all"
		sleep 1 ; echo -e "user logout\r"	) | telnet $modemip
}

########################################
# modem_reset
modem_reset() {
	(	sleep 1; echo -e "$modemuser\r" 
		sleep 1; echo -e "$modempass\r"
		sleep 1; echo -e "system restart\r"
		sleep 1; echo -e "user logout\r") | telnet $modemip
}

########################################
# modem_safe_config
modem_save_config() {
	(	sleep 1
		sleep 1 ; echo -e "$modemuser\r"
		sleep 1 ; echo -e "$modempass\r"
		sleep 1 ; echo -e "system config save\r"
		sleep 1 ; echo -e "user logout\r"	) | telnet $modemip
}

########################################
# log
log(){
	# write syslog
	logger -t $ident $1
}

############################################################
# end of functions 
############################################################
