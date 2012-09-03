#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Class::LOP' ) || print "Bail out!\n";
}

diag( "Testing Class::LOP $Class::LOP::VERSION, Perl $], $^X" );
