#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;
use List::Util ("sum", "shuffle", "reduce") ;
use Storable ;

my $ARGC = @ARGV ;

#"cmd", "user", "pcpu", "rss", "pid"

my $ref_available = retrieve 'storable.mon.available' ; 
my $ref_peer = retrieve 'storable.mon.data' ;
my %h_peer = %{$ref_peer} ;

my $ref_task = retrieve 'storable.task.data' ;

my %h_user = () ;
my %h_machine = () ;

for my $peer(keys %h_peer){
	$h_machine{$peer}->{"myuser"} = 0 ;
	$h_machine{$peer}->{"available"} = 0 ;
	for my $record(@{$h_peer{$peer}}){
		$h_user{$record->{"user"}}->{"task"} ++ ;	
		$h_user{$record->{"user"}}->{"cpu"} += $record->{"pcpu"} ;	
		$h_user{$record->{"user"}}->{"mem"} += $record->{"rss"} ;	
		$h_user{$record->{"user"}}->{"workingon"}->{$peer} = 1;

		$h_machine{$peer}->{"task"} ++ ;
		$h_machine{$peer}->{"cpu"} += $record->{"pcpu"} ;	
		$h_machine{$peer}->{"mem"} += $record->{"rss"} ;	
		if ( $record->{"user"} eq "$myuser" ){
			$h_machine{$peer}->{"myuser"} += $record->{"pcpu"} ;
		}
	}
}

for my $m(@$ref_available){
	$h_machine{$m}->{"available"} = 1 ;
}

for my $p(values %$ref_task){
	my $m = $p->{"machine"} ;	
	if ( ! defined($m) ){
		next ; #should be a new task without an assigned machine
	}
	#print "test:$m\n" ;
	if ( ! defined($h_machine{$m}->{"dtask"}) ){
		$h_machine{$m}->{"dtask"} = 1 ; 
	} else {
		$h_machine{$m}->{"dtask"} ++ ; 
	}
}

for my $m(keys %h_machine){
	$h_machine{$m}->{"machine"} = $m ;
	if ( ! defined($h_machine{$m}->{"dtask"}) ){
		$h_machine{$m}->{"dtask"} = 0 ; 
	}
}

#print Dumper(\%h_user) ;
print Dumper(\%h_machine) ;

store \%h_user, 'storable.stat.user' ;
store \%h_machine, 'storable.stat.machine' ;

exit 0 ;
