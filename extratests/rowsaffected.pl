#!/usr/bin/perl -w
#
# rowsaffected.pl: Test that the number of rows affected by a statement
#                  is correct
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

$string = 'aaaa';

foreach $i ( 0..1000 ) {
    $dbh->do( "
        INSERT INTO test2 VALUES( $i, '$string' )" ) or 
    die "Cannot insert row: $DBI::errstr\n";

    $string++;
  }

### Test to see how many rows get deleted from the table here. -1 should
### be the result...
$rv =
    $dbh->do( "DELETE FROM test2 WHERE id > 200 AND id < 500" );
die "Cannot delete rows from table: $DBI::errstr\n" unless $rv;

print "Rows deleted: $rv\n";

$dbh->disconnect;
