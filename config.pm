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
$multi_bm_count
$multi_bm_timeout
$multi_bm_put_count
$multi_bm_put_timeout 
$multi_bm_put_bw
$multi_bm_get_count
$multi_bm_get_timeout
$multi_bm_get_bw
$gap_new_task
$fn_host_candidate
$fn_hostlist
$bm_rand_num
$bm_get_limit
$bm_put_limit
) ;

our $gap_new_task = 1 ;

our $multi_exe_timeout = 100 ; #seconds
our $multi_exe_count = 100 ; #concurrent process
our $multi_scp_timeout = 1200 ; #seconds
our $multi_scp_count = 20 ; #concurrent process

our $multi_bm_count = 100 ;
our $multi_bm_timeout = 100 ;
our $multi_bm_put_count = 30 ;
our $multi_bm_put_timeout = 180 ; #finish 1.7M file at 10 KB/s rate
our $multi_bm_put_bw = 2000 ; # Kbits/s
our $multi_bm_get_count = 30 ;
our $multi_bm_get_timeout = 180 ; #finish 1.7M file at 10 KB/s rate
our $multi_bm_get_bw = 2000 ; # Kbits/s

our $bm_rand_num = 100000 ;
our $bm_get_limit = 10000 ; #10KB/s
our $bm_put_limit = 10000 ;


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

