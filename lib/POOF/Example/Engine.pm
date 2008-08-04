package POOF::Example::Engine;

use strict;
use warnings;

use base qw(POOF);


#-------------------------------------------------------------------------------
# init 


#-------------------------------------------------------------------------------
# properties

sub Cylinders : Property Public
{
    {
        'type' => 'integer',
        'default' => 0,
    }
}

sub Displacement : Property Public
{
    {
        'type' => 'float',
        'default' => 0.0,
    }
}

sub state : Property Private
{
    {
        'type' => 'boolean',
        'default' => 0
    }
}

#-------------------------------------------------------------------------------
# methods

sub StartEngine : Method Public
{
    my $obj = shift;
    
    if ($obj->{'state'} == 1)
    {
        return 0;
    }
    else
    {
        $obj->{'state'} = 1;
        return 1;
    }
}

sub StopEngine : Method Public
{
    my $obj = shift;
    
    if ($obj->{'state'} == 0)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

sub GetState : Method Public
{
    my $obj = shift;
    return $obj->{'state'};
}



1;