#!/usr/bin/perl -w
#hupili
#2012060x
#
#The interface to distribute linux commands 
#locally using fork()

use strict;
use POSIX ;

our $_fatal = 1 ;
our $_warning = 2 ;
our $_notice = 3 ;
our $_debug = 4 ;
our $_output_level = $_fatal | $_warning | $_notice | $_debug ;
our $_output_level = $_fatal | $_warning | $_notice ;

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
our $fh_fifo ;
open $fh_fifo, "cat $tmpfifo |" ;

#my $ppid = $$ ;

my $line_no = 0 ;

our %h_process = () ;
sub check_and_wait{
	my ($termination) = @_ ;
	my $_read_length_once = 1000 ;
	my $_gap_read_fifo = 0 ;
	while ( ((scalar keys %h_process >= $max_proc)
		|| $termination)
		&& (scalar keys %h_process > 0) ){
		#reach maximum number of processes
		#wait for someone to exit

		#print "$termination\t", scalar keys %h_process, "\n" ;

		my $wait_time = $timeout ;
		for (values %h_process){
			my $used = time - $_->{"start_time"} ;
			if ( $wait_time > $timeout - $used ){
				$wait_time = $timeout - $used ;
			}
		}

		print "wait for : $wait_time\n" ;
		$wait_time ++ ; #avoid boundary case
			
		my $bits = "" ;
		vec($bits, fileno($fh_fifo), 1) = 1 ;
		my $nfound = select($bits, undef, undef, $wait_time) ;
		print "nfound: $nfound\n" ;
		my $tmp = "" ;
		if ( $nfound ){
			print "==found signal in pipe\n" ;
			while (1) {
				my $rret = read($fh_fifo, $tmp, $_read_length_once) ;
				if ( (! defined($rret)) || $rret == 0 ){
					last ;
				}
				print $tmp ;
			}
			print "==pipe read end\n" ;
			#reopen to read next signal
			close($fh_fifo) ;
			open $fh_fifo, "cat $tmpfifo |" ;

			#mark1: see mark2 below
			sleep $_gap_read_fifo ;

			#check for finished process
			#for my $pid (keys %h_process){
			#while (1) { 
			for (keys %h_process){
				my $pid = waitpid(-1, POSIX::WNOHANG) ;
				print "checking if process finish: $pid\n" ;
				#my $r = waitpid($pid, POSIX::WNOHANG) ;
				#if ( $r > 0 ) {
				if ( $pid > 0 ) {
					my $no = $h_process{$pid}->{"no"} ;
					print "process finished: [$pid, $no]\n" ;
					#supposed to be a finished process 
					delete $h_process{$pid} ;
				} 
				#else {
				#	last ;
				#}
				#test 
				#last ;
			}
		}
		#print "close handle, begin\n" ;
		#a simple close will cause a block here...
		#my $cret = close($fh) ;
		#print "close $fh: $cret\n" ;
		#print "close handle, end\n" ;

		#check for timeout process
		for (values %h_process){
			my $pid = $_->{"pid"} ;
			my $start_time = $_->{"start_time"} ;
			my $no = $_->{"no"} ;
			print "checking if process timeout: [$pid, $no]\n" ;
			if ( time - $start_time > $timeout ){
				#kill 
				#send negative signal number to kill process group. 
				#possible numbers.
				#9: KILL
				#15: TERM
				print "process timeout and killed: [$pid, $no]\n" ;
				kill(-9, $pid) ;
				delete $h_process{$pid} ;
			}	
		}
	}
}

#================ main ==============

while (<STDIN>){
	if ( /^\s*$/ ){
		next ;		
	}
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
		#mark2: see also mark1
		#at least one of the tailing '&' and '_gap_read_fifo'
		#is essential. Using '&', the child process can return 
		#immediately, thus the waitpid in parent can succeed. 
		#If not, the child process will wait for the other side 
		#to read through the pipe and then exit. In this case, 
		#the parent should sleep for a moment before calling 
		#'waitpid()' to successfully collect the zombie child. 
		system qq(echo "$$:finished" > $tmpfifo &) ;
		#sleep(2) ;
		exit($cret) ;
	} else {
		$h_process{$pid}->{"pid"} = $pid ;
		$h_process{$pid}->{"no"} = $line_no ;
		$h_process{$pid}->{"start_time"} = time ;
		#parent process
		#waitpid($pid, 0) ;
		check_and_wait(0) ;
	}
}

check_and_wait(1) ;

close($fh_fifo) ;

#for (keys %h_process){
#	waitpid($_, 0) ;
#}

`rm -f $tmpfifo` ;

exit 0 
