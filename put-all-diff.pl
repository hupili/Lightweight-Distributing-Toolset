#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $ARGC = @ARGV ;
($ARGC == 2) or die("$0 {local} {remote}\n") ;
my ($local, $remote) = @ARGV ;

`mkdir -p $tmp/result` ;

my $multi_cmd = "" ;
for (@a_host){
	my $hostname = $_->{"hostname"} ;
	my $home = $_->{"home"} ;
	my $subdir = $hostname ;
	$multi_cmd .= qq(./put.pl $hostname $local/$subdir/* $remote ; echo \$? > $tmp/result/$hostname\n) ;
}

#print $multi_cmd ;
open f_cmd, ">$tmp/multi_cmd" ;
print f_cmd $multi_cmd ;
close f_cmd ;
system qq( cat $tmp/multi_cmd | ./multiprocess.pl $multi_scp_count $multi_scp_timeout &> $tmp/multi_log) ;

for my $f(`cd $tmp/result ; ls -1 .`){
	chomp($f) ;
	my $re = `cat $tmp/result/$f` ;
	chomp($re) ;
	print "$f:$re\n" ;
}

exit 0 ;
