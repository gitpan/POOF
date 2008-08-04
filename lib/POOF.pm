package POOF;

use 5.006;
use strict;
use warnings;

use B::Deparse;
use Attribute::Handlers;
use Scalar::Util qw(blessed refaddr);
use Data::Dumper;
use Carp qw(croak confess cluck);
use Class::ISA;


use POOF::Properties;
use POOF::DataType;

our $VERSION = '1.0';
our $TRACE = 0;
our $RAISE_EXCEPTION = 'trap';


#-------------------------------------------------------------------------------
use constant PROPERTIES      => { };
use constant PROPERTYINDEX   => { };
use constant METHODS         => { };
use constant GROUPS          => { };
use constant PROPBACKREF     => { };
use constant PROPBACKDOOR    => { };
use constant CLASSES         => { };
use constant METHODDISPATCH  => { };
use constant ENCFQCLASSNAMES => { };
use constant PROCESSEDFILES  => { };


#-------------------------------------------------------------------------------
# access levels
use constant ACCESSLEVEL =>
{
    'Private'   => 0,
    'Protected' => 1,
    'Public'    => 2,
};

#-------------------------------------------------------------------------------
sub new
{
    my $class = shift;
    my %args = @_;
    
    confess "This class cannot be instantiated as a stand along object, it must be inherited instead"
        if $class eq 'POOF';
    
    # define main constructor property definition array
    my @properties = _processParentProperties($class,{});
    
    # deal with self
    foreach my $property (@{ +PROPERTIES->{ $class } })
    {
        if (exists $property->{'name'})
        {
            # add to Properties.pm constructor args
            push(@properties,{
                'class'   => $class,
                'name'    => $property->{'name'},
                'access'  => $property->{'data'}->{'access'},
                'virtual' => $property->{'data'}->{'virtual'},
                'data'    => POOF::DataType->new($property->{'data'}),
                'datadef' => $property->{'data'}
            });
        }
    }
    
    my $obj;
    tie %{$obj}, 'POOF::Properties', \@properties, $class, \&Errors, \+GROUPS, \+PROPBACKREF, @_;
    bless $obj,$class;
    
    $obj->{'___refobj___'} = $obj;
    
    $RAISE_EXCEPTION = $args{'RaiseException'}
        if exists $args{'RaiseException'} && defined $args{'RaiseException'};
        
    $obj->_init( @_ );

    return $obj;
}

sub _processParentProperties
{
    my $class = shift;
    my $seen = shift;
    my @properties = @_;
    
    # deal with parents
    foreach my $parent (reverse Class::ISA::super_path($class))
    {
        next if $seen->{$parent}++;
        
        # process it's parents first
        @properties = _processParentProperties($parent,$seen,@properties)
            if (exists +PROPERTIES->{ $parent } && $parent ne 'POOF');
        
        # skip any non-defined parent
        next unless exists +PROPERTIES->{ $parent };
        
        # deal with each parent property
        foreach my $property (@{ +PROPERTIES->{ $parent } })
        {
            if (exists $property->{'name'})
            {
                # add to Properties.pm constructor args
                push(@properties,{
                    'class'   => $parent,
                    'name'    => $property->{'name'},
                    'access'  => $property->{'data'}->{'access'},
                    'virtual' => $property->{'data'}->{'virtual'},
                    'data'    => POOF::DataType->new($property->{'data'}),
                    'datadef' => $property->{'data'}
                });
            }
        }
    }
    
    return (@properties);
}

sub _init
{
    my $obj = shift;
    my %args = @_;
    return (@_);
}


#-------------------------------------------------------------------------------
# Error handling

my $ERRORS;
sub Errors
{
    my $obj = shift;
    my ($k,$e) = @_;
    
    $e->{'description'} = "$e->{'description'}"
        if ref($e);
    
    return
        @_ == 0
            ? scalar keys %{$ERRORS->{ refaddr($obj) }}
            : @_ == 1
                ? delete $ERRORS->{ refaddr($obj) }->{ $k }
                : @_ == 2
                    ? $obj->_AddError($k,$e) 
                    : undef;
}

sub GetErrors
{
    my $obj = shift;
    return
        ref $ERRORS->{ refaddr($obj) }
            ? $ERRORS->{ refaddr($obj) }
            : { };  
}

sub AllErrors
{
    my ($obj) = @_;
    return scalar(keys %{$obj->GetAllErrors});
}

sub GetAllErrors
{
    my ($obj,$parent) = @_;
    my $errors = {};

    $parent =
        $parent
            ? "$parent-"
            : '';
    
    if ($obj->_Relationship(ref($obj),'POOF::Collection') =~ /^(?:self|child)$/)
    {
        for(my $i=0; $i<=$#{$obj}; $i++)
        {
            # skip non initialized elements of collection
            next unless exists $obj->[$i];
            if ($obj->_Relationship(ref($obj->[$i]),'POOF') =~ /^(?:self|child)$/)
            {
                my $error = $obj->[$i]->GetAllErrors("$parent$i");
                %{$errors} = (%{$errors},%{$error})
                    if $error;
            }
        }
    }
    else
    {
        foreach my $prop (@{+PROPERTIES->{ ref($obj) }})
        {
            if ($obj->_Relationship(ref($obj->{$prop->{'name'}}),'POOF') =~ /^(?:self|child)$/)
            {
                my $error = $obj->{$prop->{'name'}}->GetAllErrors("$parent$prop->{'name'}");
                %{$errors} = (%{$errors},%{$error})
                    if $error;
            }
        }
    }
    
    my $myErrors = $obj->GetErrors;
    map { $errors->{"$parent$_"} = $myErrors->{$_} } keys %{$myErrors};
    return $errors;
}

sub _AddError
{
    my ($obj,$k,$e) = @_;
    unless ($RAISE_EXCEPTION eq 'trap')
    {
        my $error_string = "\nException for " . ref($obj) . "->{'$k'}\n" . "-"x50 . "\n"
            . "\n\tcode = $e->{'code'}"
            . "\n\tvalue = " . (defined $e->{'value'} ? $e->{'value'} : 'undef')
            . "\n\tdescription = $e->{'description'}";
            
        if ($RAISE_EXCEPTION eq 'warn')
        {
            warn $error_string;
        }
        elsif($RAISE_EXCEPTION eq 'print')
        {
            print $error_string;
        }
        elsif($RAISE_EXCEPTION eq 'cluck')
        {
            cluck $error_string ."\n\tstack = ";
        }
        elsif($RAISE_EXCEPTION eq 'confess')
        {
            confess $error_string ."\n\tstack = ";
        }
        elsif($RAISE_EXCEPTION eq 'croak')
        {
            croak $error_string;
        }
        elsif($RAISE_EXCEPTION eq 'die')
        {
            die $error_string;
        }
    }
    
    return $ERRORS->{ refaddr($obj) }->{ $k } = $e;
}

sub pRaiseException
{
    my ($obj,$val) = @_;
    return
        defined $val
            ? $RAISE_EXCEPTION = $val
            : $RAISE_EXCEPTION;
}

#-------------------------------------------------------------------------------
# Group operations

sub GetPropertiesOfGroups
{
    my $obj = shift;
    my %props;
    @props{ $obj->GetNamesOfGroup(@_) } = $obj->GetValuesOfGroup(@_);
    return (%props);
}

sub GetGroups
{
    my ($obj) = @_;
    return (keys %{ +GROUPS->{ ref $obj } });
}

sub GetNamesOfGroup
{
    my ($obj,$group) = @_;
    
    return
        defined $group && exists +GROUPS->{ ref $obj }->{ $group }
            ? (@{ +GROUPS->{ ref $obj }->{ $group } })
            : (); 
}

sub Group
{
    my ($obj,$group) = @_;
    return $obj->GetNamesOfGroup($group);
}

sub GroupEncoded
{
    my ($obj,$group) = @_;
    return (map { $obj->_encodeFullyQualifyClassName . '-' . $_  }  $obj->GetNamesOfGroup($group));
}

sub PropertyNamesEncoded
{
    my ($obj,$refObj,@names) = @_;
    my $class = ref $refObj;
    return (map { $obj->_encodeFullyQualifyClassName($refObj) . '-' . $_  }  @names );
}

sub GetValuesOfGroup
{
    my ($obj,$group) = @_;
    return
        defined $group && $obj->GetNamesOfGroup($group)
            ? (@{$obj}{ $obj->GetNamesOfGroup($group) })  
            : ();
}

sub ValidGroupName
{
    my $obj = ref $_[0] ? +shift : undef;
    my ($name) = @_;
    return
        $name !~ /^\s*$/  
            ? 1
            : 0; 
}

#-------------------------------------------------------------------------------


sub pSetPropertyDeeply
{
    my ($obj,$ref,$val,@path) = @_;
    my $level = shift @path;

    if (@path)
    {
        # look ahead to see if this is a collection
        if (ref($ref->{$level}) && $obj->_Relationship($ref->{$level},'POOF::Collection') =~ /^(?:self|child)$/o )
        {
            # it's a collection
            $obj->pSetPropertyDeeply($ref->{$level}->[ shift @path ],$val,@path);
        }
        else
        {
            # no it's not
            $obj->pSetPropertyDeeply($ref->{$level},$val,@path) 
        }
    }
    else
    {
        $ref->{$level} = $val;
    }
}

sub pGetPropertyDeeply
{
    my ($obj,$ref,@path) = @_;
    my $level = shift @path;
    return
        scalar (@path)
            ? ref($ref) eq 'ARRAY' 
                ? $obj->pGetPropertyDeeply($ref->[$level],@path)  
                : $obj->pGetPropertyDeeply($ref->{$level},@path)  
            : ref($ref) eq 'ARRAY'  
                ? $ref->[$level]
                : $ref->{$level};   
}

sub pInstantiate
{
    my ($obj,$prop) = @_;
    return
        $obj->pPropertyDefinition($prop)->{'otype'}->new 
        (
            $obj->GetPropertiesOfGroups('Application'),
            RaiseException => $POOF::RAISE_EXCEPTION
        );
}

sub pReInstantiateSelf
{ 
    my ($obj,%args) = @_;
    return
        ref($obj)->new(
            $obj->GetPropertiesOfGroups('Application'),
            %args
        );
}

#-------------------------------------------------------------------------------
# property definitions

sub pPropertyEnumOptions
{
    my ($obj,$propName) = @_;
    confess "There are no properties associated with " . ref($obj)
        unless exists +PROPBACKREF->{ ref($obj) };
    return +PROPBACKREF->{ ref($obj) }->EnumOptions($propName);
}

sub pPropertyDefinition
{
    my ($obj,$propName) = @_;
    confess "There are no properties associated with " . ref($obj)
        unless exists +PROPBACKREF->{ ref($obj) };
    
    return +PROPBACKREF->{ ref($obj) }->Definition($propName);
}

#-------------------------------------------------------------------------------
our $AUTOLOAD;
sub AUTOLOAD
{
	my $obj = shift;
    
	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion
    
    my $super =
        $AUTOLOAD =~ /\:SUPER\:/o
            ? 1
            : 0;
            
    my $class = ref($obj) || confess "$obj is not an object";

    # TDB: handle super correctly, if the parent does not have the method
    # then try his parent and so on until we hit the top, if no method
    # is found then throw and exeption.
	my $package =
        $super
            ? shift @{[ Class::ISA::super_path( $class ) ]}  
            : $class;
            
    # just return undef if we are dealing with built in methods like DESTROY
    return if $name eq 'DESTROY';

    if ($TRACE)
    {
        no warnings;
        warn qq|$AUTOLOAD for ($package) called from | . (caller(0))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(1))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(2))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(3))[0] . "\n";
        warn qq|$AUTOLOAD for ($package) called from | . (caller(4))[0] . "\n";
        warn "\twith " . scalar(@_) . " parameters\n";
        #warn "\tparams: " . Dumper(\@_) if @_;
    }
    
    
    # make sure we apply the inheritance rules the first time a class is used.
    $obj->_BuildMethodDispatch( $package )
        unless exists +METHODDISPATCH->{ $package };
    
    confess "$name method does not exist in class $package"
        unless (
            exists +METHODDISPATCH->{ $package }->{ $name }
            and exists +METHODDISPATCH->{ $package }->{ $name }->{'code'}
        );
        
    my $method = +METHODDISPATCH->{ $package }->{ $name }->{'code'};
    my $access = +METHODDISPATCH->{ $package }->{ $name }->{'access'};
 
    $access = 
        exists ACCESSLEVEL->{ $access }
            ? ACCESSLEVEL->{ $access }
            : ACCESSLEVEL->{ 'Public' };
	
    my $context = $obj->_AccessContext;

    confess "Illegal access of method $name"
        unless $access >= $context;
                      
    return &{$method}($obj,@_);
}


sub _BuildMethodDispatch
{
    my $obj = shift;
    my $package = shift;
    
    # get all parents
    my @parents = Class::ISA::super_path($package);
    
    # go through each class on the chain
    foreach my $parent (reverse @parents)
    {
        # non-defined parent will simply get and empty hash
        # and we'll skip to the next parent
        unless (exists +METHODS->{ $parent })
        {
            +METHODDISPATCH->{ $parent } = { };
            next;
        }
        
        # deal with each parent methods
        foreach my $name (keys %{ +METHODS->{ $parent } })
        {
            my $method = +METHODS->{ $parent }->{ $name };
            # skip any private property since they are not accessible
            # from this context, they are only accessible from the class in
            # which they are defined.
            next if $method->{'access'} eq 'Private';
            
            # croak if a method is redefined and it's not marked at virtual
            confess "A non-virtual $name has been redefined in $parent"
                if (exists +METHODDISPATCH->{ $package }->{ $name }
                    and +METHODDISPATCH->{ $package }->{ $name }->{'virtual'} != 1);
            
            # add method to dispatch table
            +METHODDISPATCH->{ $package }->{ $name } = $method;
        }
    }
    
    # deal with each method in this package
    foreach my $name (keys %{ +METHODS->{ $package } })
    {
        my $method = +METHODS->{ $package }->{ $name };
        
        # croak if a method is redefined and it's not marked at virtual
        confess "A non-virtual $name has been redefined in $package"
            if (exists +METHODDISPATCH->{ $package }->{ $name }
                and +METHODDISPATCH->{ $package }->{ $name }->{'virtual'} != 1);
        
        # add method to dispatch table
        +METHODDISPATCH->{ $package }->{ $name } = $method;
    }
}


sub _AccessContext
{
    my ($obj) = @_;
    my $self = ref($obj);
    
    my ($caller) = (caller(1))[0];
    
    my $relationship = $obj->_Relationship($caller,$self);
        
    return
        $relationship eq 'self'
            ? 0                         # 'private' 
            : $relationship eq 'child'
                ? 1                     # 'protected'
                : $relationship eq 'parent'
                    ? 1                 # 'protected' This is wierd shit, but I'm too tired now to fix it.
                    : 2                     # 'public';  
}

sub _CallerContext
{
    my ($obj) = @_;
    $obj->Trace if $TRACE;
    return (caller(1))[0];
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


sub _DumpAccessContext
{
    my $obj  = shift;
    my %caller;

    for(2 .. 5)
    {
        @caller{ qw(
            0-package
            1-filename
            2-line
            3-subr
            4-has_args
            5-wantarray
            6-evaltext
            7-is_required
            8-hints
            9-bitmask
        ) } = caller($_);

        last unless defined $caller{'0-package'};
        
        warn "\ncaller $_\n" . "-"x50 . "\n";
        $obj->_DumpCaller(\%caller);
    }
}

sub _DumpCore
{
    my ($obj) = @_;
    
    warn "Dumping Core\n";
    warn "-"x50 . "\n";
    warn "METHODS: ",Dumper( +METHODDISPATCH), "\n";
    warn "PROPERTYINDEX: ",Dumper( +PROPERTYINDEX), "\n";
    warn "PROPERTIES: ",Dumper( +PROPERTIES), "\n";
}


#-------------------------------------------------------------------------------
# function attribute handlers

sub Method      : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Property    : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Private     : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Protected   : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Public      : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Virtual     : ATTR(CODE,BEGIN) { _processFile(@_) }
sub Doc         : ATTR(CODE,BEGIN) { _processFile(@_) }


sub _processFile
{
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    
    return if $package =~ /POOF::TEMPORARYNAMESPACE/;
                        
    # convert package name to a path
    my ($filename) = map { exists $INC{"$_.pm"} ? $INC{"$_.pm"} : $0 } map { s!::!/!go; $_ } ($package);
    
    # just return if we already processed this file
    return if +PROCESSEDFILES->{$filename}++;

    my $source;
    my $exception;
    
    # try to open the file for reading or die with stack trace
    open(SOURCEFILE,$filename) || confess "Could not open $filename\n";
    { local $/ = undef; $source = <SOURCEFILE>; }
    close(SOURCEFILE);
    
    # let's rename the packages so we don't brack perl's inheritance stuff
    $source =~ s/^package\s+/package POOF::TEMPORARYNAMESPACE/g;
    
    # now let's evaluate the source using the same nasty string eval which is
    # the reason we have to jump through hoops here (caramba!).
    {
        # creating block to squelch perl's complaining
        no strict 'refs';
        no warnings 'redefine';
        eval $source;
        if($@)
        {
            $exception = $@;
            my ($error,$file) = split /\(eval \d+\)/, $exception;
            my ($replace,$line) = split /\] line /, $file;
            $exception = qq|$error [$filename]| . ($line ? " line $line" : $replace);
            die $exception;
        }
    }
    
    # split source into packages but keep the keyword package in each piece;
    my @packages = map { "package $_" } split(/^package\s+/,$source);
    
    # process each package one at a time
    foreach my $package (@packages)
    {
        next unless $package =~ m/^package\s+([^\s]+)\s*;/;
        my $tempclass = $1;
        my $class = $tempclass;
        
        $class =~ s/POOF::TEMPORARYNAMESPACE//g;
        
        # identify all properties and methods by steping through each line one at a time
        my @lines = split(/(?:\x0A|\x0D\x0A)/o,$package);
        foreach (@lines)
        {
            s/#.*$//;
            if(/\bsub\b\s*([^\s\{\(\:]+)\s*:\s*([^\{]+)\s*(\{|$)?/o)
            {
                
                chomp();
                my ($sub,$end) = ($1,$3 ? $3 : '');
                my %attrs = map { $_ => 1 } map { _trim($_) } split(/\s+/,$2);
                
                # classify into property or method
                if (exists $attrs{'Method'}) # process method
                {
                    # determine access
                    my $access = _determineAccess(%attrs);
                    # determine virtual
                    my $virtual = _determineVirtual(%attrs);
                        
                    # creating block to squelch perl's complaining
                    {
                        no strict 'refs';
                        no warnings 'redefine';
                        +METHODS->{ $class }->{ $sub }->{'code'} = \&{$class . '::' . $sub};
                    }
                    
                    # handle access
                    +METHODS->{ $class }->{ $sub }->{'access'} = $access;
                    
                    # handle virtual
                    +METHODS->{ $class }->{ $sub }->{'virtual'} = $virtual;
                    
                    ## handle documentation
                    #+METHODS->{ $class }->{ $sub }->{'doc'} = $doc;
                    
                }
                elsif(exists $attrs{'Property'}) # process property
                { 
                    
                    # determine access
                    my $access = _determineAccess(%attrs);
                    # determine virtual
                    my $virtual = _determineVirtual(%attrs);
                    
                    my $objdef;
                    # creating block to squelch perl's complaining
                    {
                        no strict 'refs';
                        no warnings 'redefine';
                        
                        $objdef = 
                            ref(&{$tempclass . '::' . $sub}) eq 'HASH'
                                ? &{$tempclass . '::' . $sub}
                                : { &{$tempclass . '::' . $sub} };
                    }
                    # this should return the hash that defines the property
                    %{$objdef} || confess "Properties must be defined by returning a hash ref with their attributes";
                    
                    unless (exists +PROPERTYINDEX->{ $class }->{ $sub })
                    {
                        push(@{ +PROPERTIES->{ $class } },{ 'name' => $sub });
                        +PROPERTYINDEX->{ $class }->{ $sub } = $#{ +PROPERTIES->{ $class } };
    
                        # handle groups
                        if (exists $objdef->{'groups'} && ref($objdef->{'groups'}) eq 'ARRAY')
                        {
                            foreach my $group (@{$objdef->{'groups'}})
                            {
                                #confess "Invalid group name ($group} used in property $sub"
                                #    unless ValidGroupName($group);
                            }
                        }
                    
                        +PROPERTIES->{ $class }->[ +PROPERTYINDEX->{ $class }->{ $sub } ]->{ 'data' } = { %{$objdef},access => $access, virtual => $virtual };
                    }
                }
                else
                {
                    # just skip, they might be using a non POOF function attribute or a Doc attribute
                    next;
                }
            }
            
        }
            
        my $table = eval '\\%' . $class . '::';
        foreach my $item (keys %{$table})
        {
            if (exists +PROPERTYINDEX->{ $class }->{ $item } || exists +METHODS->{ $class }->{ $item })
            {
                *{ $table->{$item} } = undef;
            }
        }
    }
}

sub _determineAccess
{
    my %attrs = @_;
    # go from most secure to least secure
    return 
        exists $attrs{'Private'}
            ? 'Private'  
            : exists $attrs{'Protected'}
                ? 'Protected' 
                : exists $attrs{'Public'}
                    ? 'Public'
                    : 'Protected'; # will default to procted if nothing has been specified 
}

sub _determineVirtual
{
    my %attrs = @_;
    # we make a distinction between properties and methods as they have different defaults
    return
        exists $attrs{'Property'}
            ? exists $attrs{'Virtual'}
                ? 1
                : exists $attrs{'NonVirtual'}
                    ? 0
                    : 0 # Properties default to Virtual
            : exists $attrs{'Method'}
                ? exists $attrs{'Virtual'}
                    ? 1
                    : 0 # Methods default to NonVirtual
                : 0;
}

sub _trim
{
    my ($dat) = @_;
    $dat =~ s/^\s*//go;
    $dat =~ s/\s*$//go;
    return $dat;
}

sub log2file
{
    open(FH,">>/tmp/debug_log") || die "Could not open debug_log to write\n($!)\n";
    print FH join(' ', @_) . "\n";
    close(FH)
}




1;
__END__

=head1 NAME

POOF - Perl extension that provides stronger typing, encapsulation and inheritance.

=head1 SYNOPSIS

    package MyClass;
    
    use base qw(POOF);
    
    # class properties
    sub Name : Property Public
    {
        {
            'type' => 'string',
            'default' => '',
            'regex' => qr/^.{0,128}$/,
        }
    }
    
    sub Age : Property Public
    {
        {
            'type' => 'integer',
            'default' => 0,
            'min' => 0,
            'max' => 120,
        }
    }
    
    sub marritalStatus : Property Private
    {
        {
            'type' => 'string',
            'default' => 'single',
            'regex' => qr/^(?single|married)$/
            'ifilter' => sub
            {
                my $val = shift;
                return lc $val;
            }
        }
    }
    
    sub spouse : Property Private
    {
        {
            'type' => 'string',
            'default' => 'single',
            'regex' => qr/^.{0,64}$/,
            'ifilter' => sub
            {
                my $val = shift;
                return lc $val;
            }
        }
    }
    
    sub opinionAboutPerl6 : Property Protected
    {
        {
            'type' => 'string',
            'default' => 'I am so worried, I don\'t sleep at night.'
        }
    }
      
    # class methods
    sub MarritalStatus : Method Public
    {
        my ($obj,$requester) = @_;
        if ($requester eq 'nefarious looking stranger')
        {
            return 'non of your business';
        }
        else
        {
            return $obj->{'marritalStatus'}
        }
    }
    
    sub GetMarried : Method Public
    {
        my ($obj,$new_spouse) = @_;
        
        $obj->{'spouse'} = $new_spouse;
        
        if ($obj->Errors)
        {
            my $errors = $obj->GetErrors;
            if (exists $errors->{'spouse'})
            {
                die "Problems, the marrige is off!! $errors->{'spouse'}\n";
                return 0;
            }
        }
        else
        {
            $obj->{'marritalStatus'} = 'married';
            return 1;
        }
    }
    
    sub OpinionAboutPerl6 : Method Public Virtual
    {
        my ($obj) = @_;
        return "Oh, great, really looking forward to it. It's almost here :)";
    }
    
    sub RealPublicOpinionAboutPerl6 : Method Public
    {
        my ($obj) = @_;
        return $obj->OpinionAboutPerl6;
    }
  
    
=head1 DESCRIPTION

This module attempts to give Perl a more formal OO implementation framework.
Providing a distinction between class properties and methods with three levels
of access (Public, Protected and Private).  It also restricts method overriding
in children classes to those properties or methods marked as "Virtual", in which
case a child class can override the method but only from its own context.  As
far as the parent is concern the overridden method or property still behaves in
the expected way from its perspective.

Take the example above:

Any children of MyClass can override the method "OpinionAboutPerl6" as it is
marked "Virtual":
    
    
    # in child

    sub OpinionAboutPerl6 : Method Public
    {
        my ($obj) = @_;
        return "Dude, it's totally tubular!!";
    }
    

However if the public method "RealPublicOpinionAboutPerl6" it's called then it
would in turn call the "OpinionAboutPerl6" method as it was defined in MyClass,
because from the parents perspective the method never changed.  I believe this
is crucial behavior and it goes along with how the OO principles have been
implemented in other popular languages like Java, C# and C++.


=head1 Properties

Class properties are defined by use of the "Property" function attribute.
Properties like methods have three levels of access (see. Access Levels) which
are Public, Protected and Private.  In addition to the various access levels
properties can be marked as Virtual, which allows them to be overriden in
sub-clases and gives them visibility through the entire class hierarchy.

=head3 type

=head3 regex

=head3 orm


=head1 Property access modifiers

=head1 Property virtual

=head1 Property

=head1 Property


=head1 Methods



=head1 EXPORT

None.



=head1 SEE ALSO

Although this framework is currently being used in production environments,
I cannot accept responsibility for any damages cause by this framework, use
only at your own risk.

Documentation for this module is a work in progress.  I hope to be able to
dedicate more time and created a more comprehensive set of docs in the near
future.  Anyone interested in helping with the documentation, please contact
me at bmillares@cpan.org.

=head1 AUTHOR

Benny Millares<lt>bmillares@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Benny Millares

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

