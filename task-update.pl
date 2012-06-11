#!/usr/bin/perl -w

use strict ;
use config ;
use function ;
use Data::Dumper ;
use Storable ;
use List::Util ("shuffle", "sum") ;

#======functions=====

sub get_machine_ok{
	my @tmp = () ;
	print ">>start monitor:", `date` ;
	`./monitor.pl` ;
	print ">>end monitor:", `date` ;
	print ">>start stat:", `date` ;
	`./statistics.pl` ;
	print ">>end stat:", `date` ;
	print ">>start analyze:", `date` ;
	my $ref_machine = retrieve 'storable.stat.machine' ;
	my $cur_time = get_datestr() ;
	my $hour = substr($cur_time, 7, 2) ;
	my $max_cpu = 0 ;
	my $max_cpu_me = 0 ;
	my $max_dtask = 0 ; 
	if ( $hour >= 23 || $hour <= 8 ) {
		#night !!!! oh yeah~ I can launch more task
		$max_cpu = $h_limit{"max_cpu_night"} ;
		$max_cpu_me = $h_limit{"max_cpu_me_night"} ;
		$max_dtask = $h_limit{"max_dtask_night"} ;
	} else {
		$max_cpu = $h_limit{"max_cpu_day"} ;
		$max_cpu_me = $h_limit{"max_cpu_me_day"} ;
		$max_dtask = $h_limit{"max_dtask_day"} ;
	}
	#print $max_cpu, ",", $max_cpu_me, "\n" ;
	#print $hour ;
	for my $mkey((keys %$ref_machine)){
		my $m = $ref_machine->{$mkey} ;
		#print Dumper($m) ;	
		#check if this machine is available ;
		#TODO:check under what condition 
		#the "available" field does not exist
		if ( exists $m->{"available"} 
			&& $m->{"available"} eq 1 
			&& $m->{"cpu"} < $max_cpu 
			&& $m->{"myuser"} < $max_cpu_me 
			&& $m->{"dtask"} < $max_dtask){
			push @tmp, $mkey ;
			#print $m, "\n" ;
			#print "=== found available machine:\n" ;
			#$find = 1 ;
			#print Dumper($m) ;				
		}
	}
	print ">>end analyze:", `date` ;
	return @tmp ;
}


#============ main =========

#==== check lock to avoid multiple update.pl running====
my $mylock = "lock/update.pl.lock" ;
if ( -f $mylock ){
	print STDERR "update.pl.lock exists! exit..\n" ;
	exit(-1) ;
}

`echo \`date\` > $mylock` ;

#==== init environment ====

`mkdir -p $tmp/result` ;

#==== load task record file ===
if ( ! -e "storable.task.data" ){
	#system("touch storable.task.data") ;
	my %tmp_hash = () ;
	store \%tmp_hash, 'storable.task.data' ;
}
my $ref_task = retrieve 'storable.task.data' ;

#==== add new task ====
print ">>start add new:", `date` ;
my @a_new = `ls -1 $dir_task.new` ;
for my $new_task(@a_new){
	chomp($new_task) ;
	my $dir_nt = "$dir_task.new/$new_task" ;
	my $ref_newtask = retrieve "$dir_nt/storable.task.new" ;
	#print Dumper($ref_newtask) ;
	my $uuid = $ref_newtask->{"uuid"} ;
	$ref_newtask->{"status"} = "new" ;
	$ref_task->{$uuid} = $ref_newtask ;
	`mv $dir_nt $dir_task` ;
}
print ">>end add new:", `date` ;

my @a_machine_ok = () ;

#==== run new task ====
print ">>start run new:", `date` ;
for my $key(keys %$ref_task){
	my %cur_task = %{$ref_task->{$key}} ;
	if ( $cur_task{"status"} eq "new" ){
		if ( (scalar @a_machine_ok) == 0){
			#no ok machine in current queue
			#wait for a gap and then scan
			sleep $gap_new_task ;

			#statistics.pl communicate with current script 
			#using the following storable file. 
			#TODO:this ugly architecrure should be modifed 
			#in the future 
			store $ref_task, 'storable.task.data' ;

			@a_machine_ok = get_machine_ok() ;
			if ((scalar @a_machine_ok) == 0){
				#still no machine available
				#stop scheduling new tasks
				print "no ok machines now! stop scheduling new dtasks\n" ;
				last ;
			} else {
				print "ok machines: @a_machine_ok\n" ;
			}
		}

		my $hostname = pop @a_machine_ok ;
		my $uuid = $key ;
		my $home = $h_host{$hostname}->{"home"} ;
		my $working = "$home/$uuid" ;
		my $dir_local = 
		"$dir_task/" . 
		join(".", $cur_task{"name"}, $cur_task{"time"}, $cur_task{"uuid"}) ;
		my $dir_remote = $uuid ;
		my $exec = $cur_task{"exec"} ;

		print "hostname:$hostname\n" ;
		print "local dir:$dir_local\n" ;
		print "remote dir:$dir_remote\n" ;
		#my $ret0 = system qq( ./execute.pl $hostname "mkdir -p $working") ;
		#print "mkdir: $ret0\n" ;

		my $ret0 = -1 ;
		my $ret1 = -1 ;
		my $ret2 = -1 ;

		$ret0 = system qq( ./execute.pl $hostname "rm -rf $working") ;
		print "rmr: $ret0\n" ;

		if ( $ret0 == 0 ){
			$ret1 = system qq( ./put.pl $hostname $dir_local/ $dir_remote) ;
			print "copy file: $ret1\n" ;
		}

		if ( $ret1 == 0 ){
			my $cmd = qq(./tools/run.sh $home $working $exec) ;
			$ret2 = system qq(./execute.pl $hostname "$cmd") ;	
			print "cmd:$cmd\n" ;
			print "execute: $ret2\n" ;
		}

		if ( $ret2 == 0 ){
			#execute successfully, mark as running
			$ref_task->{$key}->{"status"} = "running" ;
			$ref_task->{$key}->{"machine"} = $hostname ;
			$ref_task->{$key}->{"time_start"} = get_datestr() ; 
		} else {
			#TODO: it fails here most probably due to 
			#uninitialized machines. 
			last ;
		}

	} # if status ...
}
print ">>end run new:", `date` ;

#==== check running tasks

print ">>start check running:", `date` ;

my $cmd_check_running = "" ;
for my $key(keys %$ref_task){
	my %cur_task = %{$ref_task->{$key}} ;
	if ( $cur_task{"status"} eq "running" ){
		my $machine = $cur_task{"machine"} ;
		if ( ! exists $h_host{$machine} ){
			#TODO:this is the deleted machine
			#try to find more mature way of handling this case
			next ;
		}
		my $uuid = $cur_task{"uuid"} ;
		my $home = $h_host{$machine}->{"home"} ;
		my $working = "$home/$uuid" ;

		my $ref_machine = retrieve 'storable.stat.machine' ;
		if ( $ref_machine->{$machine}->{"available"} eq 0 ){
			#the machine becomes unavailable when the task is running. 
			#TODO: mark the task as killed
			next ;
		}
		$cmd_check_running .=
		qq(./execute.pl $machine "./tools/check.sh $home/$uuid" | grep "^check" | sed 's/^check://g' > $tmp/result/$uuid\n) ;
	}
}

#print $cmd_check_running ;
open f_cmd, ">$tmp/check_running_cmd" ;
print f_cmd $cmd_check_running ;
close f_cmd ;
system qq( cat $tmp/check_running_cmd | ./multiprocess.pl $multi_exe_count $multi_exe_timeout &> $tmp/check_running_log) ;

my @a_finished = `cd $tmp/result/ ; grep ^0 * | sed 's/:0//g'` ;
#print "@a_finished" ;
for my $key(@a_finished){
	chomp($key) ;
	my %cur_task = %{$ref_task->{$key}} ;
	my $machine = $cur_task{"machine"} ;
	my $uuid = $cur_task{"uuid"} ;
	my $home = $h_host{$machine}->{"home"} ;
	my $working = "$home/$uuid" ;
	print "$key\n" ;
	my $ret = 0 ;
	my $ret1 = -1 ;
	if ( $ret == 0 ){
		#finished !! yeah!
		my $dir_local = 
		"$dir_task/" . 
		join(".", $cur_task{"name"}, $cur_task{"time"}, $cur_task{"uuid"}) ;
		my $dir_remote = $uuid ;
		my $subdir = "" ;
		if ( defined $cur_task{"d_fetch"} ) {
			$subdir = $cur_task{"d_fetch"} ;
			#$subdir =~ s/\s//g ;
		}
		$ret1 = system qq(./get.pl $machine $dir_remote/$subdir $dir_local/result) ;
		print "fetch result: $ret1\n" ;
	}

	my $ret2 = -1 ;
	if ( $ret1 == 0 ){
		$ret2 = system qq( ./execute.pl $machine "rm -rf $working") ;
		print "clear working directory: $ret2\n" ;
	}

	if ( $ret2 == 0 ){
		my $cur_time = get_datestr() ;
		$ref_task->{$key}->{"status"} = "finish" ;
		$ref_task->{$key}->{"time_finish"} = $cur_time ;
	}
}

print ">>end check running:", `date` ;

#==== check finished/killed tasks
print ">>start check finished:", `date` ;
for my $key(keys %$ref_task){
	my %cur_task = %{$ref_task->{$key}} ;
	if ( $cur_task{"status"} eq "finish" 
	 || $cur_task{"status"} eq "killed" 
	){
		my $dir_local = 
			"$dir_task/" . 
			join(".", $cur_task{"name"}, $cur_task{"time"}, $cur_task{"uuid"}) ;
		store \%cur_task, "$dir_local/storable.task.end" ;
		my $ret = system qq( mv $dir_local $dir_task.finish/) ;
		print "moving $dir_local : $ret\n" ;
		if ( $ret == 0 ){
			#yeah! the task cycle eventually finished. 
			delete $ref_task->{$key} ;
		}
	}
}
print ">>end check finished:", `date` ;

#==== store the task data

#print "=== current task data:\n" ;
#print Dumper($ref_task) ;
store $ref_task, 'storable.task.data' ;

#==== clean up working environment ====
#print "$tmp\n" ;
`rm -rf $tmp` ;

#==== unlock 
`rm -f $mylock` ;

exit 0 ;
