#!/usr/bin/perl -w
#
# doerrortest.pl: Checks to make sure 'do' returns errors correctly
#
# Alter this to the host running msqld. I think this needs to be 'localhost'.

$test_dbhost = 'localhost';

# Alter this to the name of the database you wish to create.

$test_dbname = 'test';

use DBI;

$dbh = DBI->connect( $test_dbhost, $test_dbname, '', 'mSQL' );
if ( !defined $dbh ) {
    die "Cannot connect: $DBI::errstr\n";
  }

$dbh->do( "blahblahblah" ) or die "Died: $DBI::errstr\n";

$dbh->disconnect;
