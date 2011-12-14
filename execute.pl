#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("$0 {target} {cmd}\n") ;

my ($target, $cmd) = @ARGV ;
my $home = $h_host{$target}->{"home"} ;
my $ret = system qq( ssh $target "cd $home; $cmd" ) ;

exit $ret ;
