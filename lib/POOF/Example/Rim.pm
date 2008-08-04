package POOF::Example::Rim;

use strict;
use warnings;

use Carp qw(croak);
use base qw(POOF);


#-------------------------------------------------------------------------------
# init 

#-------------------------------------------------------------------------------
# properties

sub diameter : Property Public
{
    {
        'type' => 'float',
        'default' => 15.5,
        'groups' => [qw(init)]
    }
}

sub width : Property Public
{
    {
        'type' => 'float',
        'default' => 8.5,
        'groups' => [qw(init)]
    }
}

sub alloy : Property Public
{
    {
        'type' => 'string',
        'default' => 'Aluminum',
        'groups' => [qw(init)]
    }
}

sub trim : Property Public
{
    {
        'type' => 'string',
        'default' => 'Trundra Xtreme',
        'groups' => [qw(init)]
        
    }
}

sub make : Property Public
{
    {
        'type' => 'string',
        'default' => 'Rims-R-US',
        'groups' => [qw(init)]
    }
}

#-------------------------------------------------------------------------------
# methods

sub Make : Method Public _virtual
{
    my $obj = shift;
    return $obj->{'make'};
}

sub Model : Method Public
{
    my $obj = shift;
    return $obj->Size . qq| : $obj->{'trim'} ($obj->{'alloy'})|;
}

sub Size : Method Public
{
    my $obj = shift;
    return qq|$obj->{'diameter'}/$obj->{'width'}|;
}

1;