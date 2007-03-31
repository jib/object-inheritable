package Object::Inheritable;

use strict;
use vars    qw[$DEBUG $VERSION];
use Carp    ();

$VERSION    = '0.01';
$DEBUG      = 0;

my $DefaultMethod   = 'parent';

=head1 NAME

Object::Inheritable -- Mixin class to enable data inheritance between objects

=head1 SYNOPSIS

    package My::Class;
    use base 'Object::Inheritable'  # load the Mixin

    $child  = My::Class->new;       
    $parent = My::Parent->new;

    ### define the relationship, My::Class needs to define this accessor.
    ### For custom accessors, see 'ALTERNATE PARENT METHODS' section.
    $child->parent( $parent );       

    ### returns all objects in the inheritance chain; $child and $parent;                                    
    @list = $chlid->list_objects;    

    ### returns the object you should call 'some_method' on, according
    ### to your inheritance chain
    $obj  = $child->object_for('some_method'); 

=head1 DESCRIPTION

C<Object::Inheritable> lets you inherit data between objects that use
C<Object::Inheritable> as a baseclass (or other objects that implement
a similar API), by defining a relationship between these objects. 

This works analogous to C<perl>s own C<@ISA> resolving, but rather 
than on classes, it works on objects.

=head1 MIXIN METHODS

=head2 $parent = $obj->parent | $obj->parent( $parent )

Get or set the parent of this object. It should be another object that
uses C<Object::Inheritable> as a mixin, or an object that supports the
same interface, providing it's own C<parent>, C<list_objects> and 
C<object_for> methods.

See the section on C<INHERITANCE ORDER> to see how objects inherit from
eachother.

See the section on C<ALTERNATE PARENT METHODS> to change the method by
which to retrieve the parent object.

=cut

=head2 @objects = $obj->list_objects

Returns a list of all the objects that this objects inherits from,
including itself. The order of these objects is not guaranteed.

=cut

sub list_objects {
    my $self = shift;
    my $meth = $self->___parent_method_for( ref $self );

    __PACKAGE__->___debug( "# Parent method for '".ref($self)."' is '$meth'")
        if $DEBUG;


    my @parents;

    if( $self->can( $meth ) ) {
        my $parent = $self->$meth;

        if( $parent ) {
            #my @list = eval { $parent->list_parents };
            my @list = $parent->list_objects;
            
            ### no objects returned from the parent call -- might have
            ### different implementation, so at least at this object to
            ### our own list
            @list    = ($parent) unless @list;  

            __PACKAGE__->___debug("# Could not get parents for $self: $@")
                if $DEBUG and $@;
            
            push @parents, grep { defined } @list;
        }                   
    }

    return ( $self, @parents );
}

=head2 $target_object = $obj->object_for( METHOD );

Returns the object which, according to your inheritance chain, supplies
C<METHOD>. This is done using a C<can> call on the object and it's 
parents (as returned by C<list_objects>).

The order of your inheritance depends on which class you are inheriting
from. See the section on C<INHERITANCE ORDER> further down.

=cut

sub object_for {
    my $self = shift;
    my $meth = shift;
    
    my @parents = $self->list_objects;
   
    ### reverse the order, if it's a BottomUp object.
    @parents = reverse @parents  
        if UNIVERSAL::isa( $self, __PACKAGE__ . '::TopDown' );

    my($obj) = grep { $_->can( $meth ) } @parents;
    
    return $obj if $obj;
    return;
}

sub ___debug {
    my $self = shift;
    my $msg  = shift;
    my $lvl  = shift || 0;

    local $Carp::CarpLevel += 1;
    
    Carp::carp($msg);
}
=head1 INHERITANCE ORDER

By default, data retrievel is down C<bottom up>, meaning we prefer
child data over parent data. The alternative is to retrieve data
C<top down>, where parent data is prefered over child data.

To allow C<top down> retrieval, create your object as follows 
instead:

    package My::Class;
    use Object::Inheritable;
    use base 'Object::Inheritable::TopDown';
    
You can also be explicit in your C<bottom up> preference by 
declaring your object as follows:

    package My::Class;
    use Object::Inheritable;
    use base 'Object::Inheritable::BottomUp';

=cut

{   package Object::Inheritable::BottomUp;
    use base 'Object::Inheritable';
}

{   package Object::Inheritable::TopDown;
    use base 'Object::Inheritable';
}


=head1 ALTERNATE PARENT METHODS

By default, C<Object::Inheritable> assumes that your parent object
can be retrieved using the C<parent> method on your object.

If you (or your parent object) implement a different accessor to 
retrieve their parent object, you can tell C<Object::Inheritable>
as follows:

    package My::Class;

    use Object::Inheritable method => 'custom_parent_method';
    @ISA = 'Object::Inheritable';

Or, and this also works for other classes than your own as well:

    package My::Class;
    use base 'Object::Inheritable';
    
    Object::Inheritable::import('My::Classs', method => 'custom_parent_method');

=cut

{   my %Cache;
    sub import {
        my $class = shift;
        my %args  = @_;
        
        $Cache{ $class } = $args{ 'method' } 
                                ? $args{ 'method' } 
                                : $DefaultMethod;
    }

    sub ___parent_method_for {
        my $self    = shift;
        my $class   = shift;
        return $Cache{$class} || $DefaultMethod;
    }

    sub ___get_cache { return \%Cache };
}

=head1 BUG REPORTS

Please report bugs or other issues to E<lt>bug-object-inheritable@rt.cpan.org<gt>.

=head1 AUTHOR

This module by Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This library is free software; you may redistribute and/or modify it 
under the same terms as Perl itself.


=cut



1;
