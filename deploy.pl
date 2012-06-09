#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;

my $multi_cmd = "" ;

for (@a_host){
	my %h = %$_ ;
	my $hostname = $h{"hostname"} ;
	my $home = $h{"home"} ;
	$multi_cmd .= qq(ssh $hostname "mkdir -p $home" ; echo \$? > $tmp/result/$hostname\n) ;
}

`mkdir -p $tmp/result` ;
#print $multi_cmd ;
open f_cmd, ">$tmp/multi_cmd" ;
print f_cmd $multi_cmd ;
close f_cmd ;
system qq( cat $tmp/multi_cmd | ./multiprocess.pl $multi_exe_count $multi_exe_timeout &> $tmp/multi_log) ;

print "make home folder result====\n" ;
for (`cd $tmp/result ; ls -1 .`){
	chomp ;
	my $f = $_ ;
	my $r = `cat $tmp/result/$f` ;
	chomp($r) ;
	print "$f:$r\n" ;
}

print "copy 'tools' result====\n" ;
my $ret = system qq(./put-all.pl tools tools) ;

#`rm -rf $tmp` ;

exit ($ret >> 8) ;
