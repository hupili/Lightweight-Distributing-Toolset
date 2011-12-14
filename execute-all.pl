#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 1) or die("$0 {cmd}\n") ;

my $cmd = $ARGV[0] ;

for (@a_host){
	#print Dumper($_) ;
	#next ;
	my %h = %{$_} ;
	my $hostname = $h{"hostname"} ;
	my $home = $h{"home"} ;
	print "[$hostname][begin]\n" ;
	system qq( ssh $hostname "cd $home; $cmd" ) ;
	print "[$hostname][end]\n" ;
}

exit 0 ;
