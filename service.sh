
set_ttl_65()
{
	echo 65 > /proc/sys/net/ipv4/ip_default_ttl
}

set_hl_65()
{
	echo 65 > /proc/sys/net/ipv6/conf/all/hop_limit
}

filter_interface_ipv4()
{
	table="$1"
	int="$2"

	iptables -t filter -D OUTPUT  -o "$int" -j $table
	iptables -t filter -D FORWARD -o "$int" -j $table

	iptables -t filter -I OUTPUT  -o "$int" -j $table
	iptables -t filter -I FORWARD -o "$int" -j $table
}

filter_interface_ipv6()
{
	table="$1"
	int="$2"

	ip6tables -t filter -D OUTPUT  -o "$int" -j $table
	ip6tables -t filter -D FORWARD -o "$int" -j $table

	ip6tables -t filter -I OUTPUT  -o "$int" -j $table
	ip6tables -t filter -I FORWARD -o "$int" -j $table
}

filter_ttl_63()
{
	table="$1"

	if grep -q ttl /proc/net/ip_tables_matches
	then
		iptables -t filter -F $table
		iptables -t filter -N $table

		iptables -t filter -A $table -m ttl --ttl-lt 63 -j REJECT
		iptables -t filter -A $table -m ttl --ttl-eq 63 -j RETURN
		iptables -t filter -A $table -j CONNMARK --set-mark 65

         	filter_interface_ipv4 $table 'ap0'
                filter_interface_ipv4 $table 'dummy0'
                filter_interface_ipv4 $table 'eth0'
                filter_interface_ipv4 $table 'lo'
                filter_interface_ipv4 $table 'p2p0'
                filter_interface_ipv4 $table 'rndis0'
                filter_interface_ipv4 $table 'rmnet0'
                filter_interface_ipv4 $table 'rmnet1'
                filter_interface_ipv4 $table 'rmnet_data0'
                filter_interface_ipv4 $table 'rmnet_data1'
                filter_interface_ipv4 $table 'rmnet_data2'
                filter_interface_ipv4 $table 'rmnet_ipa0'
                filter_interface_ipv4 $table 'rmnet_mhi0'
                filter_interface_ipv4 $table 'rmnet_usb0'
                filter_interface_ipv4 $table 'swlan0'
                filter_interface_ipv4 $table 'tun0'
                filter_interface_ipv4 $table 'usb0'

		ip rule add fwmark 64 table 164
		ip route add default dev lo table 164
		ip route flush cache
	fi
}

filter_hl_63()
{
	table="$1"

	if grep -q hl /proc/net/ip6_tables_matches
	then
		ip6tables -t filter -F $table
		ip6tables -t filter -N $table

		ip6tables -t filter -A $table -m hl --hl-lt 63 -j REJECT
		ip6tables -t filter -A $table -m hl --hl-eq 63 -j RETURN
		ip6tables -t filter -A $table -j CONNMARK --set-mark 65

		filter_interface_ipv6 $table 'rmnet_+'
		filter_interface_ipv6 $table 'rev_rmnet_+'
		filter_interface_ipv6 $table 'v4-rmnet_+'
		filter_interface_ipv6 $table 'ipv6_vti_+'

		ip rule add fwmark 64 table 164
		ip route add default dev lo table 164
		ip route flush cache
	fi
}


settings put global tether_dun_required 0

if [ -x "$(command -v iptables)" ]
then
	if grep -q TTL /proc/net/ip_tables_targets
	then
	        iptables -t mangle -A PREROUTING -j TTL --ttl-set 65
		iptables -t mangle -A POSTROUTING -j TTL --ttl-set 65
	else
		set_ttl_65
		filter_ttl_63 sort_out_interface
	fi
else
	set_ttl_65
fi


if [ -x "$(command -v ip6tables)" ]
then
	if grep -q HL /proc/net/ip6_tables_targets
	then
	        ip6tables -t mangle -A PREROUTING -j HL --hl-set 65
		ip6tables -t mangle -A POSTROUTING -j HL --hl-set 65
	else
		set_hl_65
		filter_hl_63 sort_out_interface
	fi
else
	set_hl_65
fi

