#!/usr/bin/perl -w
#
# Checks to see if the connect method is behaving as per the spec

use DBI;

%connect = (
    "username" => "descarte",
    "database" => "test",
    "hostname" => "localhost"
  );

$dbh = DBI->connect( '', 'test', 'something', 'mSQL', \%connect ) ||
    die "Something wrong! $DBI::errstr: $!\n";

$sth = $dbh->prepare( "SELECT id, name FROM test2" ) or
    die "Cannot prepare statement: $DBI::errstr\n";

$rv = $sth->execute() or 
    die "Cannot execute statement: $DBI::errstr\n";


@row = $sth->fetchrow();
$$names = $sth->{NAME};
print "First column: ", $$names->[0], "\n";
print "Second column: ", $$names->[1], "\n";

$sth->finish;

$dbh->disconnect;
