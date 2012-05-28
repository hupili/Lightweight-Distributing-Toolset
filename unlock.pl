#!/usr/bin/perl -w

use strict ;
use config ;

my $usage = "$0 {lock}" ;

my $ARGC = @ARGV ;
($ARGC == 1) or die("usage:$usage\n") ;
my $lock = $ARGV[0] ;

if ( ! -e "lock/$lock" ){
	print STDERR "no such lock: $lock\n" ;	
	exit 255 ;
}

`rm -f lock/$lock` ;


exit 0 ;
