#!/usr/bin/perl -w

use strict ;
use config ;

my $usage = "$0 {lock} {message}" ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("usage:$usage\n") ;
my $lock = $ARGV[0] ;
my $message = $ARGV[1] ;

if ( -e "lock/$lock" ){
	print STDERR "$lock is already locked!\n" ;	
	exit 255 ;
}

`touch lock/$lock` ;
`echo \`date\` >> lock/$lock` ;
`echo $message >> lock/$lock` ;

exit 0 ;
