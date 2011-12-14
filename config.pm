package config ;

use strict ;
use base 'Exporter' ;
use FindBin qw($Bin $Script) ;

our @EXPORT = qw(
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
) ;

our $dir_task = "task" ;
our $dir_description = "description" ;

our %h_limit = (
	max_cpu_day => 1100, 
	max_cpu_night => 1100, 
	max_cpu_me_day => 1100, 
	max_cpu_me_night => 1100, 
) ;

our $fn_execute = "$Bin/$Script" ;
our $dir_execute = $Bin ;

our @a_host = () ;
our %h_host = () ;
my $fn_hostlist = "host.list" ;
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

1;

