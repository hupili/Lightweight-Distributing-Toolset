#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

for (@a_host){
	my %h = %$_ ;
	my $hostname = $h{"hostname"} ;
	my $home = $h{"home"} ;
	system qq(ssh $hostname "mkdir -p $home" ) ;
	system qq(scp -r tools $hostname:$home) ;
	#system qq(./put-all.pl tools tools) ;
}

exit 0 ;
