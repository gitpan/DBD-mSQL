#!/usr/bin/perl -w
#
# selectrows.pl: Test that the number of rows affected by a SELECT statement
#                is returned
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

### Test to see how many rows get deleted from the table here. -1 should
### be the result...
$sth =
    $dbh->prepare( "SELECT id, name FROM test2 WHERE id < 100" );
die "Cannot delete rows from table: $DBI::errstr\n" unless $sth;

$rv =
    $sth->execute;
die "Cannot execute statement: $DBI::errstr\n" unless $rv;
print "Rows returned by query: $rv\n";

$sth->finish;

$dbh->disconnect;
