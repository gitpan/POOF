package POOF::Example::Wheel;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 


#-------------------------------------------------------------------------------
# properties

sub Tire : Property Public
{
    {
        'type' => 'POOF::Example::Tire',
    }
}

sub Rim : Property Public
{
    {
        'type' => 'POOF::Example::Rim',
    }
}

#-------------------------------------------------------------------------------
# methods



1;