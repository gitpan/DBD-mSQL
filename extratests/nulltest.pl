#!/usr/bin/perl -w
#
# Tests to make sure NULL variables are returned correctly

use DBI;

$dbname = "pants";
$dbhost = "localhost";
$testtable = "testaa";

$dbh =
    DBI->connect( $dbhost, $dbname, '', 'mSQL' );

if ( !defined $dbh ) {
    die "Cannot connect to mSQL database $dbname on host $dbhost: $DBI::errstr\n";
  }

### Stick a test row into the table
$rv =
    $dbh->do( "INSERT INTO $testtable VALUES ( NULL, 'Alligator Descartes' )" );
if ( !defined $rv ) {
    die "Cannot insert row into table: $DBI::errstr\n";
  }

# Fetch it back out
$sth = $dbh->prepare( "SELECT * FROM $testtable WHERE id = NULL" );
if ( !defined $sth ) {
    die "Cannot prepare sth: $DBI::errstr\n";
  }

$sth->execute;

while ( @row = $sth->fetchrow ) {
    if ( !defined $row[0] ) {
        print "test passes\n";
      } else {
        print "test fails: $row[0]\n";
      }
  }

$sth->finish;

# Delete the row back out the table
undef $rv;
$rv =
    $dbh->do( "DELETE FROM $testtable WHERE id = NULL" );
if ( !defined $rv ) {
    die "Cannot delete data from table: $DBI::errstr\n";
  }

$dbh->disconnect;
