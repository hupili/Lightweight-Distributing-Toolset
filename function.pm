package function ;

use strict ;
use base 'Exporter' ;
use config ;

our @EXPORT = qw(
&get_datestr
) ;

sub get_datestr{
	my $datestr = `date +\%y\%m\%d-\%H\%M\%S-\%s` ;
	chomp($datestr) ;
	return $datestr ;
}
