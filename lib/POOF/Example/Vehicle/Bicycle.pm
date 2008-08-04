package POOF::Example::Vehicle::Bicycle;

use strict;
use warnings;

use base qw(POOF::Example::Vehicle);

use POOF::Example::Wheel;

#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my ($args) = $obj->SUPER::_init( @_ );
    
    $obj->{'Wheels'}  = POOF::Example::Wheel->new;
    
    return (@_);
}

#-------------------------------------------------------------------------------
# properties

sub Wheels : Property Protected
{
    {
        'type' => 'POOF::Example::Wheel'
    }
}

sub Frame : Property Protected
{
    {
        'type' => 'string'
    }
}

sub HandleBar : Property Protected
{
    {
        'type' => 'string'
    }
};

sub Seat : Property Protected
{
    {
        'type' => 'string'
    }
};

#-------------------------------------------------------------------------------
# methods

1;