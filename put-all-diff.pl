#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("$0 {local} {remote}\n") ;

my ($local, $remote) = @ARGV ;
my $ret = 0 ;
for (@a_host){
	my $hostname = $_->{"hostname"} ;
	my $home = $_->{"home"} ;
	my $subdir = $hostname ;
	my $r = system qq( scp -r $local/$subdir/* $hostname:$home/$remote ) ;
	$ret |= $r ;
}

exit $ret ;
