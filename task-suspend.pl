#!/usr/bin/perl -w

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
	if ( $t->{"status"} eq "new" ){
		#only new process can be suspended
		$t->{"status"} = "suspended" ;
		store $ref_task, 'storable.task.data' ;
	}
} else {
	print STDERR "error: can not find task $uuid\n" ;
}

exit 0 ;
