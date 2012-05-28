#!/usr/bin/perl -w

#kill dtask

use strict ;
use config ;
use function ;
use Data::Dumper ;
use Storable ;
use List::Util ("shuffle", "sum") ;

my $usage = "$0 {uuid}" ;

my $ARGC = @ARGV ;
($ARGC == 1) or die("usage:$usage\n") ;
my $uuid = $ARGV[0] ;


my $ret = system("./lock.pl update.pl.lock task-kill") ;
if ( $ret != 0 ){
	exit(-1) ;
}

#==== load task record file ===
if ( ! -e "storable.task.data" ){
	#my %tmp = () ;
	#store \%tmp, 'storable.task.data' ;
	print STDERR "error: can not find 'storable.task.data'\n" ;
}
my $ref_task = retrieve 'storable.task.data' ;

#print Dumper($ref_task) ;

if ( defined($ref_task->{$uuid}) ){
	my $t = $ref_task->{$uuid} ;
	my $m = $t->{"machine"} ;
	my $cmd_kill = $t->{"kill"} ;
	system qq(./execute.pl $m "cd $uuid; $cmd_kill") ;
	$t->{"status"} = "killed" ;
	store $ref_task, 'storable.task.data' ;
} else {
	print STDERR "error: can not find task $uuid\n" ;
}

system("./unlock.pl update.pl.lock") ;
exit 0 ;
