use Test::More 'no_plan';
use strict;
use Data::Dumper;

BEGIN { chdir 't' if -d 't' };
BEGIN { use lib '../lib' };

my $Class      = 'Object::Inheritable';
my $BuClass    = $Class . '::BottomUp';
my $TdClass    = $Class . '::TopDown';
my $PMeth      = 'foo'; 
my $ListMeth   = 'list_objects';     
my $GetMeth    = 'object_for';
my @Meths      = ( $ListMeth, $GetMeth );
my $TestNS     = 'My::Test::';

use_ok( $Class );
isa_ok( bless({},$_), $Class )  for $BuClass, $TdClass;
can_ok( $Class, $_ )            for @Meths;

### enable debugging?
$Object::Inheritable::DEBUG = $Object::Inheritable::DEBUG = @ARGV ? 1 : 0;

### set up the classes:
for my $class ( $Class, $BuClass, $TdClass ) {
    no strict 'refs';
    
    ### set the parent method 
    $class->can('import')->( $TestNS.$class, method => $PMeth );
    
    ### generate @ISA and sub new/parent_meth
    @{$TestNS . $class ."::ISA"}       = ($class);
    *{$TestNS . $class .'::new'}       = sub { return bless {}, shift };
    *{$TestNS . $class .'::'. $PMeth } = sub { 
                                               my $self = shift;
                                               $self->{$PMeth} = $_[0] if $_[0];
                                               return $self->{$PMeth};
                                            };
                                                    
}

### test basic functionality
for my $class ( $Class, $BuClass, $TdClass ) {
    my $test_class = $TestNS . $class;
    
    my $obj = $test_class->new;
    ok( $obj,                   "Object created" );
    isa_ok( $obj,               $class );
    isa_ok( $obj,               $Class );
    can_ok( $test_class,        $PMeth );
    can_ok( $test_class,        $_ ) for @Meths;
    

    my $par = $test_class->new;
    ok( $par,                   "Parent object created" );
    ok( $obj->$PMeth( $par ),   "   Parent stored" );
    is( $obj->$PMeth, $par,     "   Parent retrieved" );

    is_deeply( [ sort $obj->$ListMeth ], [sort( $obj, $par )],
                                "   '$ListMeth' returns all objects" );
     
    ### do we get the RIGHT object returned to us? TD classes should return
    ### the parent, the others should return the child
    is( $obj->$GetMeth($PMeth), ( $obj->isa($TdClass) ? $par : $obj ),
                                "   '$GetMeth' returns the right object" );
}
