package POOF::Example::Wheels;

use strict;
use warnings;

use base qw(POOF::Collection);


#-------------------------------------------------------------------------------
# init 


#-------------------------------------------------------------------------------
# properties

#-------------------------------------------------------------------------------
# methods

sub Count : Method Public
{
    my ($obj) = @_;
    return @{$obj};
}



1;