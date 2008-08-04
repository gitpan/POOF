package POOF::Example::Vehicle;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 


#-------------------------------------------------------------------------------
# properties

sub PassengerCapacity : Property Protected
{
    {
        'type' => 'integer',
        'default' => 0,
    }
}

sub CargoCapacity : Property Protected
{
    {
        'type' => 'float',
        'default' => 0.0,
    }
}

#-------------------------------------------------------------------------------
# methods


1;