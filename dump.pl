#!/usr/bin/perl -w

use strict ;
#use config ;
#use function ;
use Data::Dumper ;
use Storable ;

my $usage = "$0 {fn_data}" ;

my $ARGC = @ARGV ;
($ARGC == 1) or die("usage:$usage\n") ;
my $filename = $ARGV[0] ;

my $ref = retrieve($filename) ;
print Dumper($ref) ;

exit 0 ;
