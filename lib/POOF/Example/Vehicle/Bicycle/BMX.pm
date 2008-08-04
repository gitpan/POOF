package POOF::Example::Vehicle::Bicycle::BMX;

use strict;
use warnings;

use base qw(POOF::Example::Vehicle::Bicycle);


#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my ($args) = $obj->SUPER::_init( @_ );
    
    $obj->{'PassengerCapacity'} = 1;
    $obj->{'CargoCapacity'} = 1;
    
    return (@_);
}

#-------------------------------------------------------------------------------
# properties

sub brand : Property Private
{
    {
        'type' => 'string',
        'default' => 'Mongoose',
        'groups' => [qw(init)]
    }
}

sub model : Property Private
{
    {
        'type' => 'string',
        'default' => 'Brawler 20',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub Brand : Method Public
{
    my $obj = shift;
    return $obj->{'brand'};
}

sub Model : Method Public
{
    my $obj = shift;
    return $obj->{'brand'};
}

1;