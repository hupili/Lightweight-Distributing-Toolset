#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 3) or die("$0 {target} {local} {remote}\n") ;

my ($target, $local, $remote) = @ARGV ;
if ( ! exists $h_host{$target} ){
	print STDERR "$target: host does not exists\n" ;
	return -1 ;
}
my $home = $h_host{$target}->{"home"} ;
my $ret = system qq( scp -C -r $local "$target:$home/$remote" ) ;

exit ($ret >> 8) ;
