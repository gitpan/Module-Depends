#!perl -w
use strict;
use Test::More tests => 9;
my $class = 'Module::Depends::Intrusive';
require_ok( "Module::Depends" );
require_ok( $class );

# when you edit Build.PL, edit this, then rerun
# perl Build.PL ; ./Build distmeta
my $our_requires = {
    'Class::Accessor::Chained' => 0,
    'File::chdir' => 0,
    'File::Spec' => 0,
    'YAML' => 0,
};

# test against ourself
my $mb = $class->new->dist_dir( '.' )->find_modules;
isa_ok( $mb, $class );

is_deeply( $mb->requires, $our_requires, "got our own requires" );

is_deeply( $mb->build_requires,
           { 'Test::More' => 0 },
           "got our own build_requires" );

my $other = $class->new->dist_dir("t/mmish")->find_modules;

is_deeply( $other->requires,
           { 'Not::A::Real::Module' => 42 },
           "got other (makemaker) requires" );

my $notthere = $class->new->dist_dir('t/no-such-dir');
eval { $notthere->find_modules };
like( $@, qr{^couldn't chdir to t/no-such-dir: }, "fails on not existing dir" );

$notthere->dist_dir( 't/empty' );
eval { $notthere->find_modules };
like( $@, qr{^No {Build,Makefile}.PL found }, "fails on empty dir" );


my $shy = Module::Depends->new->dist_dir( '.' )->find_modules;
is_deeply( $shy->requires, $our_requires,
           "got our own requires, non-intrusively" );

