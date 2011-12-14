#!/usr/bin/perl -w

use strict ;
use config ;
use function ;
use Data::Dumper ;
use Storable ;

#==== load task record file ===
if ( ! -e "storable.task.data" ){
	#system("touch storable.task.data") ;
	my %tmp = () ;
	store \%tmp, 'storable.task.data' ;
}
my $ref_task = retrieve 'storable.task.data' ;

print Dumper($ref_task) ;

exit 0 ;
