package POOF::Example::Lock;

use strict;
use warnings;

use base qw(POOF);

#-------------------------------------------------------------------------------
# init 

sub _init : Method Private
{
    my $obj = shift;
    my $args = $obj->SUPER::_init( @_ );
    
    $obj->{'uniquePattern'} = '1234';
    
    return $args;
}

#-------------------------------------------------------------------------------
# properties

sub uniquePattern : Property Private
{
    {
        'type' => 'string',
        'default' => '',
    }
}

sub state : Property Private
{
    {
        'type' => 'boolean',
        'default' => 1,
    }
}

#-------------------------------------------------------------------------------
# methods

sub Lock : Method Public
{
    my $obj = shift;
    my $key = shift;
    
    if ($obj->validKey($key))
    {
        if ($obj->{'state'} == 0)
        {
            $obj->{'state'} = 1;
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

sub Unlock : Method Public
{
    my $obj = shift;
    my $key = shift;
    
    if ($obj->validKey($key))
    {
        if ($obj->{'state'} == 1)
        {
            $obj->{'state'} = 0;
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

sub validKey : Method Private
{
    my $obj = shift;
    my $key = shift;
    
    if (ref $key eq 'POOF::Example::Key')
    {
        if ($key->UniquePattern eq $obj->{'uniquePattern'})
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

sub GetState : Method Public
{
    my $obj = shift;
    return $obj->{'state'};
}
    

1;