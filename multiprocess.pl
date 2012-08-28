#!/usr/bin/perl -w
#hupili
#2012060x
#
#The interface to distribute linux commands 
#locally using fork()

use strict ;
use POSIX ;
use Proc::ProcessTable ;

our $_kill_signal = 9 ;

our $_fatal = 1 ;
our $_warning = 2 ;
our $_notice = 4 ;
our $_debug = 8 ;
#our $_output_level = $_fatal | $_warning | $_notice | $_debug ;
our $_output_level = $_fatal | $_warning | $_notice ;

our $_read_length_once = 1000 ;
our $_gap_read_fifo = 0 ;
our $_gap_fork_fail = 5 ;

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

my $line_no = 0 ;

sub print_log{
	my ($level, $message) = @_ ;
	my @_type = ("NULL", "FATAL", "WARNING", "NOTICE", "DEBUG") ;
	($_output_level & $level) && print "[$_type[$level]]$message" ;
}

sub recursive_kill{
	my $parent = shift ;
	my $proc_table=Proc::ProcessTable->new();
	foreach my $proc (@{$proc_table->table()}) {
		recursive_kill($proc->{pid}) if ($proc->{ppid} == $parent) ;
	}
	kill($_kill_signal, $parent) ;
}

our %h_process = () ;
sub check_and_wait{
	my ($termination) = @_ ;
	while ( ((scalar keys %h_process >= $max_proc)
		|| $termination)
		&& (scalar keys %h_process > 0) ){

		print_log($_debug, "$termination\t", scalar keys %h_process, "\n") ;

		my $wait_time = $timeout ;
		for (values %h_process){
			my $used = time - $_->{"start_time"} ;
			if ( $wait_time > $timeout - $used ){
				$wait_time = $timeout - $used ;
			}
		}

		print_log($_notice, "wait for : $wait_time\n") ;
		$wait_time ++ ; #avoid boundary case
			
		my $bits = "" ;
		vec($bits, fileno($fh_fifo), 1) = 1 ;
		my $nfound = select($bits, undef, undef, $wait_time) ;
		if ( $nfound ){
			print_log($_notice, "end of wait, triggered by signal in pipe\n") ;
		} else {
			print_log($_notice, "end of wait, triggered by timeout\n") ;
		}
		my $tmp = "" ;
		if ( $nfound ){
			print_log($_debug, "==found signal in pipe\n") ;
			while (1) {
				my $rret = read($fh_fifo, $tmp, $_read_length_once) ;
				if ( (! defined($rret)) || $rret == 0 ){
					last ;
				}
				print_log($_debug, $tmp) ;
			}
			print_log($_debug, "==pipe read end\n") ;
			#reopen to read next signal
			close($fh_fifo) ;
			open $fh_fifo, "cat $tmpfifo |" ;

			#mark1: see mark2 below
			#sleep $_gap_read_fifo ;
			select(undef, undef, undef, $_gap_read_fifo) ;
		}

		for (keys %h_process){
			my $pid = waitpid(-1, POSIX::WNOHANG) ;
			my $nret = $? ;
			print_log($_debug, "checking if process finish. waitpid return value: $pid\n") ;
			if ( $pid > 0 ) {
				my $ret_up = $nret >> 8 ;
				my $ret_low = $nret & 0xff ;
				print_log($_notice, "get one zombie process:[$pid,$ret_low,$ret_up]\n") ;
				if ( defined $h_process{$pid} ){	
					my $no = $h_process{$pid}->{"no"} ;
					if ( defined $h_process{$pid}->{"killed"} 
					&& defined $h_process{$pid}->{"killed"} == 1 ){
						print_log($_notice, "process killed: [$pid, $no]\n") ;
					} else {
						print_log($_notice, "process finished: [$pid, $no]\n") ;
					}
					delete $h_process{$pid} ;
				} else {
					#killed process
					#can we reach here?
					print_log($_warning, "get one zombie process that is not in our list:$pid\n") ;
				}
			} 
		}

		#check for timeout process
		for (values %h_process){
			my $pid = $_->{"pid"} ;
			my $start_time = $_->{"start_time"} ;
			my $no = $_->{"no"} ;
			#print "checking if process timeout: [$pid, $no]\n" ;
			print_log($_debug, "checking if process timeout: [$pid, $no]\n") ;
			if ( time - $start_time > $timeout ){
				#kill 
				#send negative signal number to kill process group. 
				#possible numbers.
				#9: KILL
				#15: TERM
				print_log($_notice, "process timeout and killing: [$pid, $no]\n") ;
				$h_process{$pid}->{"killed"} = 1 ; 
				recursive_kill($pid) ;
			}	
		}
	}
}

#================ main ==============

print_log($_notice, `date` . ":start multiprocess\n") ;

my @a_input = () ;
while (<STDIN>){
	chomp ;
	push @a_input, $_ ;
}

for (@a_input){
	if ( /^\s*$/ ){
		next ;		
	}
	$line_no ++ ;
	chomp ;
	my $cmd = $_ ;
	print_log($_notice, "$line_no : $cmd\n") ;	
	my $pid = fork() ;
	if ( ! defined($pid) ){
		#print "$line_no : failed creating process\n" ;
		print_log($_warning, "$line_no : failed creating process\n") ;
		sleep($_gap_fork_fail) ;
	} elsif ( $pid == 0 ){
		#child process, execute the command
		my $cret = exec qq($cmd ; ret=\$? ; echo "$$: finished executing: $cmd\n" > $tmpfifo; exit \$ret) ;

		#mark2: see also mark1
		#at least one of the tailing '&' and '_gap_read_fifo'
		#is essential. Using '&', the child process can return 
		#immediately, thus the waitpid in parent can succeed. 
		#If not, the child process will wait for the other side 
		#to read through the pipe and then exit. In this case, 
		#the parent should sleep for a moment before calling 
		#'waitpid()' to successfully collect the zombie child. 
		#In the current situation, neither operation symboled by 
		#mark1 nor mark2 is activated.

		#only fail to find the command can lead to here. 
		system qq(echo "$$:can not exec: $cmd\n" > $tmpfifo) ;
		exit($cret) ;
	} else {
		$h_process{$pid}->{"pid"} = $pid ;
		$h_process{$pid}->{"no"} = $line_no ;
		$h_process{$pid}->{"start_time"} = time ;
		check_and_wait(0) ;
	}
}

check_and_wait(1) ;

print_log($_notice, `date` . ":end multiprocess\n") ;

#closing the handle takes much time. 
#sometimes 1 min. I decide to delete before closing. 
#it depends on the recursively created process to terminate. 
#I have the following ugly way to handle it....
`echo "let me go..." > $tmpfifo` ;

close($fh_fifo) ;
`rm -f $tmpfifo` ;
print_log($_notice, `date` . ":handle closed\n") ;

exit 0 
