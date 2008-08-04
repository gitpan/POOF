package POOF::Example::Tire;

use strict;
use warnings;

use Carp qw(croak);
use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub diameter : Property Private
{
    {
        'type' => 'float',
        'default' => 15.5,
        'groups' => [qw(init)]
    }
}

sub width : Property Private
{
    {
        'type' => 'float',
        'defauklt' => 8.5,
        'groups' => [qw(init)]
    }
}

sub height : Property Private
{
    {
        'type' => 'float',
        'default' => 7.25,
        'groups' => [qw(init)]
    }
}

sub threadType : Property Private
{
    {
        'type' => 'string',
        'default' => 'All Terrain THX',
        'groups' => [qw(init)]
    }
}

sub make : Property Private
{
    {
        'type' => 'string',
        'default' => 'GoodYear',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub Make : Method Public Virtual
{
    my $obj = shift;
    return $obj->{'make'};
}

sub Model : Method Public
{
    my $obj = shift;
    return $obj->Size . qq| : $obj->{'threadType'}|;
}

sub Size : Method Public
{
    my $obj = shift;
    return $obj->RimSize . qq|-$obj->{'height'}|;
}

sub RimSize : Method Public
{
    my $obj = shift;
    return qq|$obj->{'diameter'}/$obj->{'width'}|;
}

1;