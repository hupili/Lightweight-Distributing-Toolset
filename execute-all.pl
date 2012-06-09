#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 1) or die("$0 {cmd}\n") ;

my $cmd = $ARGV[0] ;

my $multi_cmd = "" ;

#print $tmp ;
`mkdir -p $tmp/result` ;

for (@a_host){
	#print Dumper($_) ;
	#next ;
	my %h = %{$_} ;
	my $hostname = $h{"hostname"} ;
	$multi_cmd .= "./execute.pl $hostname '$cmd' &> $tmp/result/$hostname\n" ;
}

#print $multi_cmd ;
open f_cmd, ">$tmp/multi_cmd" ;
print f_cmd $multi_cmd ;
close f_cmd ;
system qq( cat $tmp/multi_cmd | ./multiprocess.pl $multi_exe_count $multi_exe_timeout &> $tmp/multi_log) ;

system qq( cat $tmp/result/* ) ;

`rm -rf $tmp` ;

exit 0 ;
