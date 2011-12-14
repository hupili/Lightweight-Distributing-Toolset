#!/usr/bin/perl -w

use strict ;
use config ;
use function ;
use Data::Dumper ;
use Storable ;
use List::Util ("shuffle", "sum") ;

#==== load task record file ===
if ( ! -e "storable.task.data" ){
	#system("touch storable.task.data") ;
	my %tmp = () ;
	store \%tmp, 'storable.task.data' ;
}
my $ref_task = retrieve 'storable.task.data' ;

#==== add new task ====
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

#==== run new task ====
for my $key(keys %$ref_task){
	my %cur_task = %{$ref_task->{$key}} ;
	if ( $cur_task{"status"} eq "new" ){
	#if (1){
		#print $key ;
		#print get_datestr() ;
		`./monitor.pl` ;
		`./statistics.pl` ;
		my $ref_machine = retrieve 'storable.stat.machine' ;
		my $cur_time = get_datestr() ;
		my $hour = substr($cur_time, 7, 2) ;
		my $max_cpu = 0 ;
		my $max_cpu_me = 0 ;
		if ( $hour >= 23 || $hour <= 8 ) {
			#night !!!! oh yeah~ I can launch more task
			$max_cpu = $h_limit{"max_cpu_night"} ;
			$max_cpu_me = $h_limit{"max_cpu_me_night"} ;
		} else {
			$max_cpu = $h_limit{"max_cpu_day"} ;
			$max_cpu_me = $h_limit{"max_cpu_me_day"} ;
		}
		#print $max_cpu, ",", $max_cpu_me, "\n" ;
		#print $hour ;
		my $find = 0 ; #any available machine?
		for my $mkey(shuffle(keys %$ref_machine)){
			my $m = $ref_machine->{$mkey} ;
			#print Dumper($m) ;	
			#check if this machine is available ;
			if ( $m->{"cpu"} < $max_cpu && $m->{"$myuser"} < $max_cpu_me ){
				#print $m, "\n" ;
				print "=== found available machine:\n" ;
				$find = 1 ;
				print Dumper($m) ;				

				my $hostname = $mkey ;
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
				}

				#if one task succeed, wait a few seconds
				#this is to let the process run fully 
				#before we deploy new process on this machine
				sleep 5 ;

				last ;
			} # if cpu
		} # for all machine
		if ( ! $find ){
			#if we can not find available machine for this task. 
			#there is no need to check for other task
			last ; #end new running
		}
	} # if status ...
}

#==== check running tasks
for my $key(keys %$ref_task){
	my %cur_task = %{$ref_task->{$key}} ;
	if ( $cur_task{"status"} eq "running" ){
		my $machine = $cur_task{"machine"} ;
		my $uuid = $cur_task{"uuid"} ;
		my $home = $h_host{$machine}->{"home"} ;
		my $working = "$home/$uuid" ;
		
		#my $ret = system qq(./execute.pl $machine "./tools/check.sh $home/$uuid") ;
		my $ret = `./execute.pl $machine "./tools/check.sh $home/$uuid"` ;
		chomp($ret) ;
		print "checking $machine, $uuid: $ret\n" ;

		my $ret1 = -1 ;
		if ( $ret == 0 ){
			#finished !! yeah!
			my $dir_local = 
				"$dir_task/" . 
				join(".", $cur_task{"name"}, $cur_task{"time"}, $cur_task{"uuid"}) ;
			my $dir_remote = $uuid ;
			$ret1 = system qq(./get.pl $machine $dir_remote $dir_local/result) ;
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
}

#==== check finished tasks
for my $key(keys %$ref_task){
	my %cur_task = %{$ref_task->{$key}} ;
	if ( $cur_task{"status"} eq "finish" ){
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

#==== store the task data

print "=== current task data:\n" ;
print Dumper($ref_task) ;
store $ref_task, 'storable.task.data' ;

exit 0 ;
