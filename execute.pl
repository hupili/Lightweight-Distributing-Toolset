#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("$0 {target} {cmd}\n") ;
my ($target, $cmd) = @ARGV ;

if ( ! exists($h_host{$target}) ){
	die("Specified host does not exist!\n") ;
}

my $home = $h_host{$target}->{"home"} ;
my $hostname = $h_host{$target}->{"hostname"} ;
print "[$hostname][begin]\n" ;
my $nret = system qq( ssh $target "cd $home; $cmd" ) ;
my $ret_low = $nret & 0xff ; 
my $ret_high = $nret >> 8 ;
print "[$hostname][end:$ret_low,$ret_high]\n" ;

exit $nret ;
