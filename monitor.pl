#!/usr/bin/perl -w

use strict ;
use config ;
use Data::Dumper ;
use Storable ;

my $ARGC = @ARGV ;
#($ARGC == 1) or die("$0 {cmd}\n") ;

#available peers
my @a_available = () ;

#remote execute and paraphraze 
my %h_peer = () ;
`./execute-all.pl "ps ax o user,pcpu,rss,pid,cmd" > tmp.monitor` ;
my @a_ps = `cat tmp.monitor` ;
my $cur_peer = -1 ;
my $cur_cmd_start = -1 ;
for (@a_ps){
	my $line = $_ ;
	chomp($line) ;
	#print $line, "\n" ;
	#cutting information by peer
	if ( $line =~ /\[(.+)\]\[begin\]/ ){
		$cur_peer = $1 ;
		$cur_cmd_start = -1 ;
		$h_peer{$cur_peer} = [] ;
		next ;
	}
	#print $line, "\n" ;
	if ( $line =~ /\[$cur_peer\]\[end:(\d+),(\d+)\]/ ){
		if ( $1 eq 0 && $2 eq 0 ){
			push @a_available, $cur_peer ;
		}
		next ;
	}
	#print $line, "\n" ;

	#find the character where "CMD" section start
	if ( $cur_cmd_start == -1 ){
		#print $line, "\n" ;
		$cur_cmd_start = index($line, "CMD") ; 	
		#print $cur_cmd_start, "\n" ;
	} else {
		my %tmp = () ;
		$tmp{"cmd"} = substr($line, $cur_cmd_start) ;
		$line = substr($line, 0, $cur_cmd_start) ;
		my @a_line = split /\s+/, $line ;
		@tmp{("user", "pcpu", "rss", "pid")} = @a_line ;
		push @{$h_peer{$cur_peer}}, \%tmp ;
		#print "@a_line\n" ;
	}
}

#====
#print Dumper(\%h_peer) ;
store \%h_peer, 'storable.mon.data' ;
store \@a_available, 'storable.mon.available' ;

exit 0 ;
