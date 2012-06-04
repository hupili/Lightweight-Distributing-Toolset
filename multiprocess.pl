#!/usr/bin/perl -w
#hupili
#2012060x
#
#The interface to distribute linux commands 
#locally using fork()

use strict;
use POSIX ;

my $usage = "$0 {max_proc} {timeout}" ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("usage:$usage\n") ;
our $max_proc = $ARGV[0] ;
our $timeout = $ARGV[1] ;

#Currently, this fifo is only used to 
#signal parent process that there may 
#be some events. So we don't impose a
#lock on this fifo. 
our $tmpfifo = "tmpfifo.$$" ;
if ( system("mkfifo $tmpfifo") != 0 ){
	die("mkfifo failed\n") ;	
}

#my $ppid = $$ ;

my $line_no = 0 ;

our %h_process = () ;
sub check_and_wait{
	my $_read_length_once = 3 ;
	while ( scalar keys %h_process >= $max_proc){
		#reach maximum number of processes
		#wait for someone to exit

		my $wait_time = $timeout ;
		for (values %h_process){
			my $used = time - $_->{"start_time"} ;
			if ( $wait_time > $timeout - $used ){
				$wait_time = $timeout - $used ;
			}
		}

		print "wait for : $wait_time\n" ;
			
		my $bits = "" ;
		my $fh ;
		open $fh, "cat $tmpfifo |" ;
		vec($bits, fileno($fh), 1) = 1 ;
		my $nfound = select($bits, undef, undef, $wait_time) ;
		print "nfound: $nfound\n" ;
		my $tmp = "" ;
		if ( $nfound ){
			while (1) {
				my $rret = read($fh, $tmp, $_read_length_once) ;
				if ( (! defined($rret)) || $rret == 0 ){
					last ;
				}
			}
		}
		close($fh) ;

		#check for finished process
		while (1) { 
			my $pid = waitpid(-1, POSIX::WNOHANG) ;
			if ( $pid > 0 ) {
				print "process finished: $pid\n" ;
				#supposed to be a finished process 
				delete $h_process{$pid} ;
			} else {
				last ;
			}
		}

		#check for timeout process
		for (values %h_process){
			my $pid = $_->{"pid"} ;
			my $start_time = $_->{"start_time"} ;
			if ( time - $start_time > $timeout ){
				#kill 
				#send negative signal number to kill process group. 
				#possible numbers.
				#9: KILL
				#15: TERM
				kill(-9, $pid) ;
				delete $h_process{$pid} ;
				print "process timeout and killed: $pid\n" ;
			}	
		}
	}
}

#================ main ==============

while (<STDIN>){
	$line_no ++ ;
	chomp ;
	my $cmd = $_ ;
	print "$line_no : $cmd\n" ;	
	my $pid = fork() ;
	if ( ! defined($pid) ){
		print "$line_no : failed creating process\n" ;
	} elsif ( $pid == 0 ){
		#child process, execute the command
		my $cret = system("$cmd") ;
		system qq(echo "$$:finished" > $tmpfifo) ;
		#sleep(2) ;
		exit($cret) ;
	} else {
		$h_process{$pid}->{"pid"} = $pid ;
		$h_process{$pid}->{"start_time"} = time ;
		#parent process
		#waitpid($pid, 0) ;
		check_and_wait() ;
	}
}

check_and_wait() ;

#for (keys %h_process){
#	waitpid($_, 0) ;
#}

`rm -f $tmpfifo` ;

exit 0 
