#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;
use Storable ;
use function ;

my $usage = "$0 {fn_description}" ;

my $ARGC = @ARGV ;
($ARGC == 1) or die("usage:$usage\n") ;
my $name = $ARGV[0] ;

my %task = () ;

my $desc = $dir_description . "/" . $name ;

if ( ! -e $desc ){
	print STDERR "can not find '$name' in '$dir_description'\n" ;
	exit(-1) ;
}

my $cmd_exec = `cat $desc/desc | grep "exec" | awk -F":" '{print \$2}'` ;
chomp($cmd_exec) ;

#my $datestr = `date +\%y\%m\%d-\%H\%M\%S-\%s` ;
#chomp($datestr) ;
my $datestr = get_datestr() ;

my $uuid = `echo "$name.$datestr.$$" | sha1sum | awk '{print \$1}'` ;
chomp($uuid) ;

$task{"name"} = $name ;
$task{"exec"} = $cmd_exec ;
$task{"uuid"} = $uuid ;
$task{"time"} = $datestr ;

my $dir_new = "$dir_task.new/$name.$datestr.$uuid" ;

print Dumper(\%task) ;
`cp -rL $desc $dir_new` ;
store \%task, "$dir_new/storable.task.new" ;

exit 0 ;
