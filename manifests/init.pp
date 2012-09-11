class nsis($root_folder='/usr/local/src',$make_public=true) {

	# Include wget so we can use it to download latest tar.gz from nsis official website.
	include wget

	# Default exec path
	$exec_path = '/usr/bin:/bin'

	# Some packages are redundant, likely could be reduced at lot if packages are declared 
	# one by one with a forced order.
	$required_packages = [  "build-essential", "unzip", "scons", "mingw32", "mingw32-binutils", "mingw32-runtime", "mingw32-ocaml", "mingw-w64", "lib32gcc1", "lib32gcc1-dbg", "lib32gomp1", "lib32stdc++6", "lib32stdc++6-4.3-dbg", "lib32z1", "libc6-dev-i386", "lib32stdc++6-4.4-dbg", "libstdc++5", "gcc-4.3-multilib", "g++-multilib", "openssl", "curl", "libcurl4-openssl-dev" ]
	package { $required_packages: ensure => latest }

	# Check root folder exist & download 
	file { "$root_folder":
        	ensure => directory,
	        owner => deploy,
        	group => deploy,
	        mode => '0644',
	} 
        wget::fetch { 'nsis-src-download' :
		source => 'http://sourceforge.net/projects/nsis/files/NSIS%202/2.46/nsis-2.46-src.tar.bz2/download',
		destination => "$root_folder/nsis-2.46-src.tar.bz2",
		require => File[$root_folder]
	}
	wget::fetch {'nsis-zip-download' :
		source => 'http://sourceforge.net/projects/nsis/files/NSIS%202/2.46/nsis-2.46.zip/download',
		destination => "$root_folder/nsis-2.46.zip",
		require => Wget::Fetch["nsis-src-download"],
	}
	wget::fetch {'osslsigncode-download' :
		source => 'http://downloads.sourceforge.net/project/osslsigncode/osslsigncode/osslsigncode-1.4.tar.gz',
		destination => "$root_folder/osslsigncode-1.4.tar.gz",
		require => Wget::Fetch["nsis-zip-download"]
	} 

	# Install osslsigncode
	exec { "uncompress-osslsigncode" :
		command => 'tar xzf osslsigncode-1.4.tar.gz',
		path => "$exec_path",
		onlyif => "test ! -d $root_folder/osslsigncode-1.4",
		require => Wget::Fetch["osslsigncode-download"],
		cwd => $root_folder
	}
        exec { "configure-osslsigncode" :
		command => 'configure',
		path => "$exec_path:$root_folder/osslsigncode-1.4",
		onlyif => "test ! -f $root_folder/osslsigncode-1.4/Makefile",
		cwd => "$root_folder/osslsigncode-1.4",
		require => Exec["uncompress-osslsigncode"],
	}
        exec { "make-osslsigncode" :
		command => 'make',
		path => "$exec_path",
		onlyif => "test ! -f $root_folder/osslsigncode-1.4/osslsigncode",
		cwd => "$root_folder/osslsigncode-1.4",
		require => Exec["configure-osslsigncode"],
	}
        exec { "make-install-osslsigncode" :
		command => 'make install',
		path => "$exec_path",
		onlyif => "test ! -f /usr/local/bin/osslsigncode",
		cwd => "$root_folder/osslsigncode-1.4",
		require => Exec["make-osslsigncode"],
	}

	# Uncompress NSIS Zip & Nsis SRC
  	# Will fail if osslsigncode did not install.
	exec { "uncompress-nsis-zip" :
		command => 'unzip nsis-2.46.zip',
		path => "$exec_path",
		onlyif => "test ! -d $root_folder/nsis-2.46",
		cwd => $root_folder,
		require => Exec["make-install-osslsigncode"]
	}
	exec { "uncompress-nsis-src" :
		command => 'tar xjf nsis-2.46-src.tar.bz2',
		path => "$exec_path",
		onlyif => "test ! -d $root_folder/nsis-2.46-src",
		cwd => $root_folder,
		require => Exec["uncompress-nsis-zip"]
	}

	# Actually Install nsis
        exec { "install-nsis" :
		command => "scons SKIPSTUBS=all SKIPPLUGINS=all SKIPUTILS=all SKIPMISC=all NSIS_CONFIG_CONST_DATA=no PREFIX=$root_folder/nsis-2.46 install-compiler",
		path => "$exec_path:$root_folder/nsis-2.46-src",
		timeout => 120,
		onlyif => "test ! -f $root_folder/nsis-2.46/bin/makensis",
		cwd => "$root_folder/nsis-2.46-src",
		require => Exec["uncompress-nsis-src"],
	}

	# Fix internal link problem on linux nsis installs:
	file { "$root_folder/nsis-2.46/share":
                ensure => directory,
		require => Exec["install-nsis"]
        } 
    	file { "$root_folder/nsis-2.46/share/nsis":
	      ensure => link,
	      target => "../",	 
	      require => File["$root_folder/nsis-2.46/share"]
	}

	if $make_public == true {
		file { "/usr/local/bin/makensis":
			ensure => link,
			target => "$root_folder/nsis-2.46/bin/makensis",
			require => Exec["install-nsis"]
		}
	}
}
