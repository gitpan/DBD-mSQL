#
# $Id$
#
# (c)1995-1997 Alligator Descartes <descarte@hermetica.com>
# Portions (c)1996 Gary Shea <shea@xmission.com>
#
# $Log$
#

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

# If you want verbose results, set this variable to 1. Otherwise, set it
# to 0
$verboseResults = 0;

# Print a warning up if we haven't defined $test_dbname or $test_hostname
if ( !defined $test_hostname || !defined $test_dbname ) {
    print <<EOM;
    I am about to perform testing of the DBD::mSQL module. This will
    defaultly look for a database called 'test' on an mSQL server running
    on the machine 'localhost'. If it fails to locate 'test', but detects
    a running mSQL server, it will use *any* database it can find,
    production or otherwise! If you don't want this to happen, exit now 
    and create a database called 'test', or edit 'test.pl' and specify the
    hostname and database name you wish to use as a test as indicated at
    the beginning of that file.

    You can hit CTRL-C now, if you wish to abort. Hitting CTRL-D or RETURN
    should start the test running.
EOM

    while ( <> ) {}
  }

### Set the hostname if we haven't defined it.........
if ( !defined $test_hostname ) {
    $test_hostname = 'localhost';
  }

### Does a basic check to make sure we can install the driver! This is
### probably a useful thing to do...
###
### If this fails, then, if you haven't typed 'make install', do it now,
### and re-try the test.
( $drh = DBI->install_driver( 'mSQL' ) )
  or errorDiagnostic( '$error0' );
#"\tDBI->install_driver( 'mSQL' ) failed: $DBI::errstr\n";

### This tests to see if we can list the databases on the server running
### on the given host. If there are no databases, this will error.
( @databases = $drh->func( $test_hostname, '_ListDBs' ) )
    or errorDiagnostic( '$error1' );

# Display the results if we want them
if ( $verboseResults == 1 ) {
    print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
    foreach $db ( @databases ) {
        print "\tDatabase Name: $db\n";
      }
    print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
  }

if ( !defined $test_dbname ) {
    $test_dbname = $databases[0];
  }
### Test the connection routines. First, connect to a database
( $dbh = $drh->connect( $test_hostname, $test_dbname, '' ) )
    or errorDiagnostic( '$error2' );

### ...and disconnect
( $dbh->disconnect )
    or errorDiagnostic( '$error3' );

### Now, re-connect again so that we can do some more complicated stuff..
( $dbh = $drh->connect( $test_hostname, $test_dbname, '' ) )
    or errorDiagnostic( '$error2' );

### List all the tables in the selected database........
( @tables = $dbh->func( '_ListTables' ) )
    or errorDiagnostic( '$error4' );

if ( !defined @tables ) {
    @tables = ( 'rubbish' );
  }

### If you want verbose results, here they are!
if ( $verboseResults == 1 ) {
    print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
    foreach $table ( @tables ) {
        print "\tTable Name: $table\n";
      }
    print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
  }

# A small loop to find a free test table we can use to mangle stuff in and
# out of. This starts at testaa and loops until testaz, then testba - testbz
# and so on until testzz.
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

### Try creating a table in the test database
( $dbh->do( "CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )" ) )
    or errorDiagnostic( '$error5' );

### ....and drop it........
( $dbh->do( "DROP TABLE $testtable" ) )
    or errorDiagnostic( '$error6' );

### Now, re-create it so that we can test data insertion, deletion and
### selection methods........
print "Re-testing: \$dbh->do( 'CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )' )\n";
( $dbh->do( "CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

### Get some meta-data for the table we've just created...
print "Testing: \$dbh->func( $testtable, '_ListFields' )\n";
( $ref = $dbh->func( $testtable, '_ListFields' ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

if ( $verboseResults == 1 ) {
    print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
    print "Fields in Table: $ref->{NUMFIELDS}\n";
    @fields = @{ $ref->{NAME} };
    @types = @{ $ref->{TYPE} };
    @nullable = @{ $ref->{IS_NOT_NULL} };
    @primarykey = @{ $ref->{IS_PRI_KEY} };
    for ( $i = 0 ; $i < $ref->{NUMFIELDS} ; $i++ ) {
        print "\tField: $fields[$i]\tType: $types[$i]\tNullable: $nullable[$i]\tPrimaryKey: $primarykey[$i]\n";
      }
    print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
  }

### Insert a row into the test table.......
print "Testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )' )\n";
( $dbh->do( "INSERT INTO $testtable VALUES( 1, 'Alligator Descartes' )" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

### ...and delete it........
print "Testing: \$dbh->do( 'DELETE FROM $testtable WHERE id = 1' )\n";
( $dbh->do( "DELETE FROM $testtable WHERE id = 1" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

### Now, try SELECT'ing the row out. This should fail.
print "Testing: \$cursor = \$dbh->prepare( 'SELECT * FROM $testtable WHERE id = 1' )\n";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable WHERE id = 1" ) )
    and print( "\tok\n" )
    or print( "\tnot ok: $DBI::errstr\n" );

print "Testing: \$cursor->execute\n";
( $cursor->execute )
    and print( "\tok\n" )
    or print( "\tnot ok: $DBI::errstr\n" );

print "*** Expect this test to fail with NO error message!\n";
print "Testing: \$cursor->fetchrow\n";
( @row = $cursor->fetchrow ) 
    and print( "\tok\n" )
    or print( "\tnot ok: $DBI::errstr\n" );

print "Testing: \$cursor->finish\n";
( $cursor->finish )
    and print( "\tok\n" )
    or print( "\tnot ok: $DBI::errstr\n" );

# Temporary bug-plug
undef $cursor;

### This section should exercise the sth->func( '_NumRows' ) private method
### by preparing a statement, then finding the number of rows within it.
### Prior to execution, this should fail. After execution, the number of
### rows affected by the statement will be returned.
print "Re-testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )' )\n";
( $dbh->do( "INSERT INTO $testtable VALUES( 1, 'Alligator Descartes' )" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

print "Re-testing: \$cursor = \$dbh->prepare( 'SELECT * FROM $testtable WHERE id = 1' )\n";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable WHERE id = 1" ) )
    and print( "\tok\n" )
    or die "\nnot ok: $DBI::errstr\n";

print "Testing: \$cursor->func( '_NumRows' ) before execute. Expect a failure\n";
( $numrows = $cursor->func( '_NumRows' ) )
    and print( "\tok\n" )
    or print "\tnot ok: $DBI::errstr\n";

print "Re-testing: \$cursor->execute\n";
( $cursor->execute )
    and print( "\tok\n" )
    or print( "\tnot ok: $DBI::errstr\n" );

print "Re-testing: \$cursor->func( '_NumRows' ) after execute.\n";
( $numrows = $cursor->func( '_NumRows' ) )
    and print( "\tok\n" )
    or print "\tnot ok: $DBI::errstr\n";

print "Re-testing: \$cursor->finish\n";
( $cursor->finish )
    and print( "\tok\n" )
    or print "\tnot ok: $DBI::errstr\n";

# Temporary bug-plug
undef $cursor;

### Test whether or not a field containing a NULL is returned correctly
### as undef, or something much more bizarre
print "Testing: \$cursor->do( 'INSERT INTO $testtable VALUES ( NULL, 'NULL-valued ID' )' )\n";
( $rv = $dbh->do( "INSERT INTO $testtable VALUES ( NULL, 'NULL-valued id' )" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

print "Testing: \$cursor = \$dbh->prepare( 'SELECT id FROM $testtable WHERE id = NULL' )\n";
( $cursor = $dbh->prepare( "SELECT id FROM $testtable WHERE id = NULL" ) )
    and print "\tok\n"
    or die "\tnot ok: $DBI::errstr\n";

$cursor->execute;

print "Testing: \$cursor->fetchrow\n";
( ( $rv ) = $cursor->fetchrow )
    and print "\tok\n"
    or print "\tnot ok: $DBI::errstr\n";

if ( !defined $rv ) {
    print "\ttest passes. NULL value returned as undef\n";
  } else {
    print "\ttest failed. NULL value returned as $rv\n";
  }

print "Testing: \$cursor->finish\n";
( $cursor->finish )
    and print "\tok\n"
    or print "\tnot ok\n";

# Temporary bug-plug
undef $cursor;

### Delete the test row from the table
$rv = 
    $dbh->do( "DELETE FROM $testtable WHERE id = NULL AND name = 'NULL-valued id'" );

### Test the new funky routines to list the fields applicable to a SELECT
### statement, and not necessarily just those in a table...
print "Re-testing: \$cursor = \$dbh->prepare( 'SELECT * FROM $testtable' )\n";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable" ) )
    and print "\tok\n"
    or die "\tnot ok: $DBI::errstr\n";

$cursor->execute;

print "Testing: \$cursor->func( '_ListSelectedFields' )\n";
( $ref = $cursor->func( '_ListSelectedFields' ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

if ( $verboseResults == 1 ) {
    print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n";
    print "Fields in Query: $ref->{NUMFIELDS}\n";
    @fields = @{ $ref->{NAME} };
    @types = @{ $ref->{TYPE} };
    @notnull = @{ $ref->{IS_NOT_NULL} };
    @primarykey = @{ $ref->{IS_PRI_KEY} };
    for ( $i = 0 ; $i < $ref->{NUMFIELDS} ; $i++ ) {
        print "\tField: $fields[$i]\tType: $types[$i]\tNotNull: $notnull[$i]\tPrimaryKey: $primarykey[$i]\n";
      }
    print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
  }

print "Re-testing: \$cursor->execute\n";
( $cursor->execute )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

print "Re-testing: \$cursor->fetchrow\n";
( @row = $cursor->fetchrow ) 
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

print "Re-testing: \$cursor->finish\n";
( $cursor->finish )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

# Temporary bug-plug
undef $cursor;

### Insert some more data into the test table.........
print "Testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 2, 'Gary Shea' )' )\n";
( $dbh->do( "INSERT INTO $testtable VALUES( 2, 'Gary Shea' )" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

print "Testing: \$cursor = \$dbh->prepare( \"UPDATE $testtable SET id = 3 WHERE name = 'Gary Shea'\" )\n";
( $cursor = $dbh->prepare( "UPDATE $testtable SET id = 3 WHERE name = 'Gary Shea'" ) )
    and print( "\tok\n" )
    or print( "\tnot ok: $DBI::errstr\n" );

print "Testing: \$cursor->func( '_ListSelectedFields' ). This will fail.\n";
( $ref = $cursor->func( '_ListSelectedFields' ) )
    and die( "\tnot ok\n" )
    or print "\tok: $DBI::errstr\n";

# Temporary bug-plug
undef $cursor;

### Test UPDATE'ing a row in the table again....
#print "Testing: \$dbh->do( 'UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'' )\n";
#( $dbh->do( "UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'" ) )
#    and print( "\tok\n" )
#    or die "\tnot ok: $DBI::errstr\n";

### Drop the test table out of our database to clean up.........
print "Re-testing: \$dbh->do( 'DROP TABLE $testtable' )\n";
( $dbh->do( "DROP TABLE $testtable" ) )
    and print( "\tok\n" )
    or die "\tnot ok: $DBI::errstr\n";

### Annoy Andreas. He's not normal.........8-)
if ( $ENV{LOGNAME} eq 'k' ) {
    print "*** Testing of DBD::mSQL complete! You're totally abnormal, Andreas!\n";
  } else {
    print "*** Testing of DBD::mSQL complete! You appear to be normal! ***\n";
  }

exit;

### Error diagnostics: Attempt to give the user a clue as to what to do now
###
sub errorDiagnostic {

    my $testId = shift;

    ### The error diagnostic help stuff.......

$error0 = "";           ### To shut -w up
*error0 = 
\"DBI->install_driver( 'mSQL' ) failed!\n\n" .
"If you haven't typed 'make install', do it now, and re-run 'make test'\n" .
"afterwards. Otherwise, you may see an error about 'unresolved symbols'.\n" .
"If so, email the appropriate log information asked for in the README\n" .
"to 'descarte\@hermetica.com'\n";

$error1 = "";           ### To shut -w up
$error1 =
"\$drh->func( '$test_hostname', '_ListDBs' ) failed!\n\n" .
"Make sure you have at least one database created\n";

$error2 = "";           ### To shut -w up
$error2 =
"\$drh->connect( '$test_hostname', '$test_dbname', '' ) failed!\n\n" .
"Make sure you have typed the database name correctly, and that the database\n" .
"exists. Also check you have permission to access the database ( as defined\n" .
"in the mSQL ACL file ). You may also want to check that the database hasn't\n" .
"inadvertently crashed since the last test!\n";

$error3 = "";           ### To shut -w up
$error3 =
"\$dbh->disconnect() failed!\n\n" .
"Make sure your server is still functioning correctly, and check to make\n" .
"sure your network isn't malfunctioning in the case of the server running\n" .
"on a remote machine.\n";

$error4 = "";           ### To shut -w up
$error4 =
"\$dbh->func( '_ListTables' ) failed!\n\n" .
"This could be due to the fact you have no tables, but I hope not. You\n" .
"could try running 'relshow -h $test_hostname $test_dbname' and see if\n" .
"reports any information about your database, or errors.\n";

$error5 = "";           ### To shut -w up
$error5 =
"\$dbh->do( 'CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )' ) failed!\n\n" .
"Make sure that your server is still running. Check that you have write\n" .
"permission on the database that you are testing on. Also check to make\n" .
"sure the table $testtable doesn't already exist. The test should find\n" .
"a unique one. If this is the case, please email 'descarte\@hermetica.com\n" .
"with this information. Thanks.\n";

$error6 = "";           ### To shut -w up
$error6 =
"\$dbh->do( 'DROP TABLE $testtable' ) failed!\n\n" .
"Check to make sure your server is still running. Also, check using the\n" .
"'relshow -h $test_hostname $test_dbname' command that the testtable\n" .
"$testtable has been created correctly.\n";

    ### Print out the error message + diagnostic help and the DBI
    ### error message, then exit.

    local $safetestId = $testId;
    $testId =~ s/(\$\w+)/$1/eeg;
    print "$testId";
    print "\nDBI Error Message: $DBI::errstr\n";
    if ( $safetestId ne '$error4' ) {
        print "Error: $safetestId\n";
        exit -1;
      } else {
        return;
      }
  }
