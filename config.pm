package config ;

use strict ;
use base 'Exporter' ;
use FindBin qw($Bin $Script) ;

our @EXPORT = qw(
$tmp
$dir_task
$dir_description
$dir_execute
$myuser
$test
$fn_execute
$dir_execute
@a_host
%h_host
%h_limit
$multi_exe_timeout
$multi_exe_count
$multi_scp_timeout
$multi_scp_count
$gap_new_task
$fn_host_candidate
$fn_hostlist
) ;

our $gap_new_task = 1 ;

our $multi_exe_timeout = 100 ; #seconds
our $multi_exe_count = 100 ; #concurrent process
our $multi_scp_timeout = 1200 ; #seconds
our $multi_scp_count = 20 ; #concurrent process

our $dir_task = "task" ;
our $dir_description = "description" ;

our %h_limit = (
	max_cpu_day => 1000, 
	max_cpu_night => 1000, 
	max_cpu_me_day => 1000, 
	max_cpu_me_night => 1000, 
	max_dtask_day => 1, 
	max_dtask_night => 1, 
) ;

our $fn_execute = "$Bin/$Script" ;
our $dir_execute = $Bin ;

#used for monitor, important....
our $myuser = "hpl011" ;

#====== calculate candidate hosts ====
our @a_host = () ;
our %h_host = () ;
our $fn_host_candidate = "host.list" ;
our $fn_hostlist = "host.list.available" ;

if ( ! -e $fn_hostlist ){
	`cp -f $fn_host_candidate $fn_hostlist` ;
}

for my $line(`cat $fn_hostlist`){
	chomp($line) ;
	my @a_line = split "\t", $line ;
	push @a_host, {
		"hostname" => $a_line[0] ,
		"system" => $a_line[1] ,
		"home" => $a_line[2] 
	} ;
	$h_host{$a_line[0]} = {
		"hostname" => $a_line[0] ,
		"system" => $a_line[1] ,
		"home" => $a_line[2] 
	} ;
} ;

our $tmp = "$Bin/tmp/$$" ;

1;

