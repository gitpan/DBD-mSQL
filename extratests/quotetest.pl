#!/usr/bin/perl -w
#
# quotetest.pl: Test that checks that strings are correctly quoted for mSQL
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
$string = "Don't you ever do that again! Nay! Nay! And thrice nay, I say!";
print "Quoted string: ", $dbh->quote( $string ), "\n";

$dbh->disconnect;
