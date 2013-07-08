class openswan (
	$server_ip       = $::ipaddress,
	$virtual_private = '%v4:10.0.0.0/8,%v4:172.16.0.0/12,%v4192.168.0.0/16',
) {

	package { 'openswan':
		ensure => installed,
	}

	concat { '/etc/ipsec.conf':
		owner   => 'root',
		group   => 'root',
		mode    => 0644,
		require => Package['openswan'],
	}

	concat::fragment { 'ipsec config setup':
		content => template('openswan/ipsec.conf-setup.erb'),
		target  => '/etc/ipsec.conf',
		order   => '00',
	}

	define connection (
		$server_ip                   = $::openswan::server_ip,
		$public_ip                   = $::openswan::server_ip,
		$peer_ip                     = '%any',
		$auto                        = 'ignore',
		$private_subnet_prefixlength = '24',
	) {
		concat::fragment { "ipsec connection ${name}":
			content => template('openswan/ipsec.conf-connection.erb'),
			target  => '/etc/ipsec.conf',
			order   => '50',
		}
	}

	concat { '/etc/ipsec.secret':
		owner   => 'root',
		group   => 'root',
		mode    => 0600,
		require => Package['openswan'],
	}

	concat::fragment { 'ipsec.secret preamble':
		content => "# secrets\n",
		target  => '/etc/ipsec.secret',
		order   => '00',
	}

	define secret (
		$id      = "@${::openswan::server_ip}",
		$peer_ip = '%any',
		$secret,
	) {
		concat::fragment { "ipsec secret ${name}":
			target  => '/etc/ipsec.secret',
			content => template('openswan/ipsec.secret.erb'),
		}
	}

	service { 'ipsec':
		ensure    => running,
		subscribe => File['/etc/ipsec.conf'],
	}

}
