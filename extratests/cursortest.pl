#!/usr/bin/perl -w
#
use DBI;

$dbh = DBI->connect( '', 'Test', '', 'mSQL' );
if ( !defined $dbh ) {
    die "Cannot connect: $DBI::errstr\n";
  }

$sth = $dbh->prepare( "SELECT id, name FROM test" );
if ( !defined $sth ) {
    die "Prepare failed: $DBI::errstr\n";
  }

print "*** I wouldn't have expected to have seen any db action yet!\n";
sleep( 5 );

$sth->execute;

print "*** I would have expected to have seen the query occur here!\n";
sleep( 5 );

while ( @row = $sth->fetchrow ) {
    print "Row: @row\n";
  }

$sth->finish;
undef $sth;

$dbh->disconnect;

exit;
