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

$sth =
    $dbh->prepare( "
        SELECT row0, row1, row2, row3, row4, row5, row6, row7, row8,
               row9, row10, row11
        FROM test12" );
die "Cannot prepare: $DBI::errstr\n" unless $sth;

$sth->execute or die "Cannot execute: $DBI::errstr\n";

while ( @row = $sth->fetchrow ) {
    print "Row: @row\n\t$#row\n";
    foreach $field ( 0..11 ) {
        print "ROW[$field]: $row[$field]\n";
      }
  }

$sth->finish;

$dbh->disconnect;
