#!/usr/bin/perl -w
#
# Checks to see if the connect method is behaving as per the spec

use DBI;

%attr = (
    "username" => "descarte",
    "password" => "blah",
    "hostname" => "localhost",
    "port"     => "1112"
  );

$dbh = DBI->connect( 'host', 'dbname', 'something', 'mSQL', \%attr );
if ( !defined $dbh ) {
    die "Something wrong! $DBI::errstr: $!\n";
  }

undef $dbh;
$drh = DBI->install_driver( 'mSQL' );
if ( !defined $drh ) {
    die "Cannot load driver: $!\n";
  } else {
    $dbh = $drh->connect( '', 'Test' );
    if ( !defined $dbh ) {
        die "Cannot connect: $DBI::errstr\n";
      }
  }
