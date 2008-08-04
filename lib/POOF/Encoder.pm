package POOF::Encoder;

use strict;
use base qw(POOF);
use Tie::IxHash;
use Class::ISA;
use Carp qw(confess);

use Data::Dumper;

sub _init : Method Protected
{
    my $obj = shift;
    my %args = @_;
    
    my @dkeys = grep { defined $args{$_} } $obj->Group('Init');
    @$obj{ @dkeys } = @args{ @dkeys }; 
}

sub Object : Property Protected
{
    {
        'type' => 'POOF',
        'groups' => [qw(Init)],
    }
}

sub SeenProps : Property Public
{
    {
        'type' => 'hash',
        'default' => {},
    }
}

sub SeenGroups : Property Public
{
    {
        'type' => 'hash',
        'default' => {},
    }
}

sub CreateEncodedKeysForGroups : Method Public
{
    my ($obj,@groups) = @_;
    
    # reset the seen
    $obj->{'SeenProps'} = {};
    $obj->{'SeenGroups'} = {};
    
    my $p = 0;
    
    return
    (
        grep
        {
            ++$p % 2
        }
        $obj->CreateEncodingMap
        (
            $obj->{'Object'},
            [@groups]
        )
    );
}

sub CreateEncodingMap : Method Protected
{
    my ($obj,$ref,$groups,$parent) = @_;
    tie (my %map, 'Tie::IxHash');
    
    # preventing warnings
    $parent ||= '';
    
    my @contained;
    
    foreach my $group (@{$groups})
    {
        
        # let's make sure we only process once
        next if $obj->{'SeenGroups'}->{ $parent ? "$parent-$group" : $group }++;
            
        my @props = eval { ($ref->Group($group)) };
        confess "parent $parent\n$@\n" if $@;
        
        foreach my $prop (@props)
        {
            # let's make sure we only process once if they are in multiple groups
            next if $obj->{'SeenProps'}->{ $parent ? "$parent-$prop" : $prop }++;
            
            if ($obj->_Relationship(ref($ref->{$prop}),'POOF::Collection') =~ /^(?:self|child)$/o)
            {
                # deal with the collection
                for(my $i=0; $i<= $#{$ref->{$prop}}; $i++)
                {
                    push
                    (
                        @contained,
                        [
                            $ref->{$prop}->[$i],   # new ref
                            $groups,               # groups to look at
                            "$parent-$prop-$i",    # new parent
                        ]
                    )
                }

                # let's instantiate one to have a place holder for new ones on the form
                push
                (
                    @contained,
                    [
                        $ref->{$prop}->[0]->pReInstantiateSelf
                        (
                            RaiseException=>$POOF::RaiseException
                        ),                    # new ref
                        $groups,              # groups to look at
                        "$parent-$prop-|",    # new parent
                    ]
                );
                    
            }
            elsif($obj->IsPOOFObj($ref->{$prop},$prop) || ref($ref->{$prop}) eq 'HASH')
            {
                # deal with the nested object
                push
                (
                    @contained,
                    [
                        $ref->{$prop},      # new ref
                        $groups,            # groups to look at
                        (
                            $parent
                                ? "$parent-$prop"
                                : $prop
                        ),                  # new parent
                    ]
                );
            }
            elsif(not ref($ref->{$prop}))
            {
                # simple prop
                my $key = $parent ? "$parent-$prop" : $prop;
                
                $map{ $key } =
                {
                    'object'    => $ref,
                    'name'      => $prop,
                    'value'     => $ref->{$prop},
                    'class'     => ref($ref),
                    'poof'      => $obj->IsPOOFObj($ref,$prop),
                    'error'     => $ref->GetErrors->{$prop}
                };
            }
            else
            {
                warn "Error: $prop is not a simple property and I don't know what do to with it\n";
                warn Dumper($ref->{$prop}),"\n";
            }
        }
        
        # now let's recurse
        foreach my $args (@contained)
        {
            %map =
            (
                %map,
                $obj->CreateEncodingMap(@{$args})
            );
        }
    }
    return %map;
}


sub _Relationship
{
    my $obj = shift;
    my ($class1,$class2) = map { $_ ? ref $_ ? ref $_ : $_ : '' } @_;

    return 'self' if $class1 eq $class2;

    my %family1 = map { $_ => 1 } Class::ISA::super_path( $class1 );
    my %family2 = map { $_ => 1 } Class::ISA::super_path( $class2 );

    return
        exists $family1{ $class2 }
            ? 'child'
            : exists $family2{ $class1 } 
                ? 'parent' 
                : 'unrelated';
}

sub IsPOOFObj
{
    my ($obj,$ref,$prop) = @_;
    return
        $obj->_Relationship($ref, 'POOF') =~ /^(?:self|child)$/
            ? 1
            : 0;
}


1;
__END__