#!/usr/bin/perl -w
#
# preparetest.pl: Checks to make sure 'prepare' returns undef upon failure
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

$sth = $dbh->prepare( "insert into test( i, c ) values ( 1, 'dog' )" );
die "prepare failed: $DBI::errstr\n" unless $sth;
local $rv = $sth->execute();
die "execute failed: $DBI::errstr\n" unless defined $rv;
print "RV: $rv\n";

$dbh->disconnect;
