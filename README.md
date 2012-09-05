puppet-nsis
====================


Class to install Nullsoft Software installer version 2.46 plus osslsigncode version 1.4

OS Fully Tested: Debian Squeeze with puppet 2.7 from backports.


Class Optional Arguments
---------------------
+ root_folder 		=> Full path to folder where all sourcecode will be downloaded, uncompressed and compiled. 
+ make_public 		=> True or False - Create symlinks for binaries that did not create themselves, default true.


Class Details
---------------------

+ Requires wget module from https://github.com/liquidstate/puppet-wget
+ Based on linux install guide by John Mendez ( http://www.xdevsoftware.com/blog/post/How-to-Install-the-Nullsoft-Installer-NSIS-on-Linux-.aspx )
+ Code by Guzman Braso - guruHub - www.guruhub.com.uy


Example call:
---------------------
'''
class { 'nsis':
	root_folder => '/usr/local/src',
	make_public => true
}
'''
