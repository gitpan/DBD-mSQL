BEGIN{unshift @INC, "../../lib", "./lib";}

use DBI;

# Uncomment this line and set 'test' to the database you want to use as a
# - test. Otherwise, this script will use the first database picked up by
# - ListDBs as a test database.

#$test_dbname = '';

# Uncomment this line and set 'testmachine' to the hostname of the the
# - machine running the mSQL daemon that you wish to use as a test. Otherwise,
# - the test script will use a local mSQL daemon.

#$test_hostname = '';

if ( !defined $test_hostname ) {
    $test_hostname = 'localhost';
  }

print "Testing: DBI->install_driver( 'mSQL' ): ";
( $drh = DBI->install_driver( 'mSQL' ) )
  and print( "ok\n" )
  or die "not ok: $DBI::errstr\n";

print "Testing: \$drh->func( '$test_hostname', '_ListDBs' ): ";
( @databases = $drh->func( $test_hostname, '_ListDBs' ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# A small test loop showing the databases on this server....Uncomment this 
# - chunk if you're the curious type.
#
#foreach $db ( @databases ) {
#    print "db: $db\n";
#  }

if ( !defined $test_dbname ) {
    $test_dbname = $databases[0];
  }
print "Testing: \$drh->connect( '$test_hostname', '$test_dbname' ): ";
( $dbh = $drh->connect( $test_hostname, $test_dbname ) )
    and print("ok\n") 
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->disconnect(): ";
( $dbh->disconnect )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$drh->connect( '$test_hostname', '$test_dbname'): ";
( $dbh = $drh->connect( $test_hostname, $test_dbname ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->func( '_ListTables' ): ";
( @tables = $dbh->func( '_ListTables' ) )
    and print( "ok\n" )
    or print "not ok: $DBI::errstr\n";

if ( !defined @tables ) {
    @tables = ( 'rubbish' );
  }

# A small test loop showing the results from _ListTables. Uncomment if you're
# - the curious type.
#
#foreach $table ( @tables ) {
#    print "table: $table\n";
#  }

# A small loop to find a free test table we can use to mangle stuff in and
# - out of.

$foundtesttable = 1;
$testtable = "testaa";
while ( $foundtesttable ) {
    $foundtesttable = 0;
    foreach $table ( @tables ) {
        if ( $table eq $testtable ) {
            $testtable++;
            $foundtesttable = 1;
          }
      }
  }

print STDERR "*** Testing: \$dbh->do FUNCTION: Just ignore: \n
              Statement handle DBI::st=HASH(0x80dedf0) destroyed without
              finish()\n\n    errors ***\n";
print "Testing: \$dbh->do( 'CREATE TABLE $testtable
                       (
                        id INTEGER,
                        name CHAR(64)
                       )' ): ";
( $dbh->do( "CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->do( 'DROP TABLE $testtable' ): ";
( $dbh->do( "DROP TABLE $testtable" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$dbh->do( 'CREATE TABLE $testtable
                       (
                        id INTEGER,
                        name CHAR(64)
                       )' ): ";
( $dbh->do( "CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# List the fields of the table we've just created in here.....

print "Testing: \$dbh->func( $testtable, '_ListFields' ): ";
( $ref = $dbh->func( $testtable, '_ListFields' ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# List the fields. Uncomment this if you're the curious type........
#
# print "NumFields: $ref->{NUMFIELDS}\n";
# @fields = @{ $ref->{NAME} };
# @types = @{ $ref->{TYPE} };
# @nullable = @{ $ref->{IS_NOT_NULL} };
# @primarykey = @{ $ref->{IS_PRI_KEY} };
# for ( $i = 0 ; $i < $ref->{NUMFIELDS} ; $i++ ) {
#     print "Field: $fields[$i]\tType: $types[$i]\tNullable: $nullable[$i]\tPrimaryKey: $primarykey[$i]\n";
#   }

print "Testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )' ): ";
( $dbh->do( "INSERT INTO $testtable VALUES( 1, 'Alligator Descartes' )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->do( 'DELETE FROM $testtable WHERE id = 1' ): ";
( $dbh->do( "DELETE FROM $testtable WHERE id = 1" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$cursor = \$dbh->prepare( 'SELECT FROM $testtable WHERE id = 1' ): ";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable WHERE id = 1" ) )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

print "Testing: \$cursor->execute: ";
( $cursor->execute )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

print "*** Expect this test to fail with NO error message!\n";
print "Testing: \$cursor->fetchrow: ";
( @row = $cursor->fetchrow ) 
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

print "Testing: \$cursor->finish: ";
( $cursor->finish )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

# Temporary bug-plug
undef $cursor;

print "Re-testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )' ): ";
( $dbh->do( "INSERT INTO $testtable VALUES( 1, 'Alligator Descartes' )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$cursor = \$dbh->prepare( 'SELECT FROM $testtable WHERE id = 1' ): ";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable WHERE id = 1" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$cursor->func( '_NumRows' ): ";
( $numrows = $cursor->func( '_NumRows' ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# For the curious, uncomment the next chunk of code
#
print "Rows returned should be: 1\nActual rows returned: $numrows\n";

print "Re-testing: \$cursor->execute: ";
( $cursor->execute )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$cursor->fetchrow: ";
( @row = $cursor->fetchrow ) 
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$cursor->finish: ";
( $cursor->finish )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# Temporary bug-plug
undef $cursor;

print "Testing: \$dbh->do( 'UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'' ): ";
( $dbh->do( "UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$dbh->do( 'DROP TABLE $testtable' ): ";
( $dbh->do( "DROP TABLE $testtable" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

if ( $ENV{LOGNAME} eq 'k' ) {
    print "*** Testing of DBD::mSQL complete! You're totally abnormal, Andreas!\n";
  } else {
    print "*** Testing of DBD::mSQL complete! You appear to be normal! ***\n";
  }
