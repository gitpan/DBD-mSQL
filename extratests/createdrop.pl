#!/usr/bin/perl -w
#
# createdrop.pl: Creates and drops a database just to exercise the driver
#		 methods.
#
#
# Alter this to the host running msqld. I think this needs to be 'localhost'.

$test_dbhost = 'localhost';

# Alter this to the name of the database you wish to create.

$test_dbname = 'test';

use DBI;

$drh = DBI->install_driver( 'mSQL' );

print "Testing: \$drh->func( $test_dbhost, $test_dbname, '_CreateDB' ): ";
( $drh->func( $test_dbhost, $test_dbname, '_CreateDB' ) )
    and print "ok\n"
    or die "$DBI::errstr\n";

print "Testing: \$drh->func( $test_dbhost, $test_dbname, '_DropDB' ): ";
( $drh->func( $test_dbhost, $test_dbname, '_DropDB' ) )
    and print "ok\n"
    or die "$DBI::errstr\n";
