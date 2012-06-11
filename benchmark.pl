#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;
use Storable ;

#$tmp = "tmp/23937" ;

`mkdir -p $tmp` ;
`mkdir -p $tmp/ping` ;
`mkdir -p $tmp/ssh` ;
`mkdir -p $tmp/testback` ;
`mkdir -p $tmp/put` ;
`mkdir -p $tmp/get` ;

#====== read candidate machines =====
my %h_host_candidate = () ;
my @a_host_candidate = () ;
for my $line(`cat $fn_host_candidate`){
	chomp($line) ;
	my @a_line = split "\t", $line ;
	push @a_host_candidate, {
		"hostname" => $a_line[0] ,
		"system" => $a_line[1] ,
		"home" => $a_line[2] 
	} ;
	$h_host_candidate{$a_line[0]} = {
		"hostname" => $a_line[0] ,
		"system" => $a_line[1] ,
		"home" => $a_line[2] 
	} ;
} ;

#print join("\n", @a_host_candidate), "\n" ;

#====== default values =====
for (values %h_host_candidate){
	$_->{"ping"} = 0 ;
	$_->{"ssh"} = 0 ;
	$_->{"alive"} = 0 ;
	$_->{"get_ok"} = 0 ;
	$_->{"get_time"} = 0 ;
	$_->{"get_rate"} = 0 ;
	$_->{"put_ok"} = 0 ;
	$_->{"put_time"} = 0 ;
	$_->{"put_rate"} = 0 ;
}

#====== test alive =====

my $multi_ping = "" ;
my $multi_ssh = "" ;
for (values %h_host_candidate){
	my $hostname = $_->{"hostname"} ;
	$multi_ping .= qq(ping -c 1 -W 10 $hostname ; echo \$? > $tmp/ping/$hostname \n) ;
	$multi_ssh .= qq(ssh $hostname 'hostname; pwd; whoami; ps' ; echo \$? > $tmp/ssh/$hostname \n) ;
}

open f_multi, ">$tmp/multi_ping" ;
print f_multi $multi_ping ;
close f_multi ;
open f_multi, ">$tmp/multi_ssh" ;
print f_multi $multi_ssh ;
close f_multi ;

`cat $tmp/multi_ping | ./multiprocess.pl $multi_bm_count $multi_bm_timeout &> $tmp/ping.log` ;
`cat $tmp/multi_ssh | ./multiprocess.pl $multi_bm_count $multi_bm_timeout &> $tmp/ssh.log` ;

for (`cd $tmp/ping ; grep "^0" * | sed 's/:0\$//g'`){
	chomp ;
	$h_host_candidate{$_}->{"ping"} = 1 ;
}
for (`cd $tmp/ssh ; grep "^0" * | sed 's/:0\$//g'`){
	chomp ;
	$h_host_candidate{$_}->{"ssh"} = 1 ;
}
for (values %h_host_candidate){
	#if ( $_->{"ping"} && $_->{"ssh"} ){
	if ( $_->{"ssh"} ){
		$_->{"alive"} = 1 ;
	}
	#some machine is alive but the ping 
	#is filtered by their FW
}

#====== test up/down speed
#`rm -f $tmp/testfile` ;
#for (1..10000){
#	my $rnd = rand ;
#	`echo $rnd >> $tmp/testfile` ;
#}
open f_test, ">$tmp/testfile" ;
for (1..$bm_rand_num){
	my $rnd = rand ;
	print f_test $rnd ;
}
close f_test ;

my $multi_get = "" ;
my $multi_put = "" ;
for (values %h_host_candidate){
	#change it to == 1
	if ( $_->{"alive"} == 1 ){
		my $hostname = $_->{"hostname"} ;			
		$multi_put .= qq(begin=`date +%s`; scp -l $multi_bm_put_bw $tmp/testfile $hostname:/tmp; ret=\$?; end=`date +%s`; echo "\$begin,\$end,\$ret" > $tmp/put/$hostname \n) ;
		$multi_get .= qq(begin=`date +%s`; scp -l $multi_bm_get_bw $hostname:/tmp/testfile $tmp/testback/\$\$; ret=\$?; end=`date +%s`; echo "\$begin,\$end,\$ret" > $tmp/get/$hostname \n) ;
	}
}

open f_multi, ">$tmp/multi_put" ;
print f_multi $multi_put ;
close f_multi ;
open f_multi, ">$tmp/multi_get" ;
print f_multi $multi_get ;
close f_multi ;

`cat $tmp/multi_put | ./multiprocess.pl $multi_bm_put_count $multi_bm_put_timeout &> $tmp/put.log` ;
`cat $tmp/multi_get | ./multiprocess.pl $multi_bm_get_count $multi_bm_get_timeout &> $tmp/get.log` ;

my $size = `ls -l $tmp/testfile | awk '{print \$5}'` ;
chomp($size) ;
for (`cd $tmp/put; grep -P '^\\d+,\\d+,0\$' * | sed 's/:/,/g'`){
	chomp ;
	my $line = $_ ;
	my @a_line = split ",", $line ;
	my $hostname = $a_line[0] ;
	my $start = $a_line[1] ;
	my $end = $a_line[2] ;
	my $ret = $a_line[3] ; 
	my $span = $end - $start ;
	if ( $ret == 0 ) {
		$h_host_candidate{$hostname}->{"put_ok"} = 1 ;
		$h_host_candidate{$hostname}->{"put_time"} = $span ;
		if ( $span > 0 ) {
			$h_host_candidate{$hostname}->{"put_rate"} = $size / $span ;
		}
	}
}
for (`cd $tmp/get; grep -P '^\\d+,\\d+,0\$' * | sed 's/:/,/g'`){
	chomp ;
	my $line = $_ ;
	my @a_line = split ",", $line ;
	my $hostname = $a_line[0] ;
	my $start = $a_line[1] ;
	my $end = $a_line[2] ;
	my $ret = $a_line[3] ; 
	my $span = $end - $start ;
	if ( $ret == 0 ) {
		$h_host_candidate{$hostname}->{"get_ok"} = 1 ;
		$h_host_candidate{$hostname}->{"get_time"} = $span ;
		if ( $span > 0 ) {
			$h_host_candidate{$hostname}->{"get_rate"} = $size / $span ;
		}
	}
}

#===== update available machines
open f_host_avail, ">$fn_hostlist" ;
for (values %h_host_candidate){
	my $hostname = $_->{"hostname"} ;
	my $system = $_->{"system"} ;
	my $home = $_->{"home"} ;
	if ( $_->{"alive"}
		&& $_->{"get_ok"}
		&& $_->{"put_ok"}
		&& $_->{"get_rate"} >= $bm_get_limit
		&& $_->{"put_rate"} >= $bm_put_limit
	) {
		print f_host_avail "$hostname\t$system\t$home\n" ;
		print "$hostname:yes\n" ;
	} else {
		print "$hostname:no\n" ;
	}
}
close f_host_avail ;

#====== clean and store information

#`rm  -rf $tmp` ;
store \%h_host_candidate, "storable.bm.host" ;

exit 0 ;
