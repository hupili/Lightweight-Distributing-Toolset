#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("$0 {remote} {local}\n") ;

my ($remote, $local) = @ARGV ;
my $ret = 0 ;
for (@a_host){
	my $hostname = $_->{"hostname"} ;
	my $home = $_->{"home"} ;
	`mkdir -p $local/d.$hostname` ;
	my $r = system qq( scp -r $hostname:$home/$remote $local/d.$hostname ) ;
	$ret |= $r ;
}

exit $ret ;
