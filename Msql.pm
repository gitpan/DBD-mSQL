#
# $Id$
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#                    Taken from a template by Tim Bunce <Tim.Bunce@ig.co.uk>
#                    Based on the original MsqlPerl module by Andreas Koenig
#                        <k@anna.mind.de>
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
# $Log$

package Msql;

use DBI;
use Exporter;

$VERSION = "0.62";

@ISA = qw( Exporter );
@EXPORT = qw( &connect &selectdb &listtables &query &numrows &name &type &table &isnotnull &is_not_null &isprikey &is_pri_key &length &fetchrow );

# Install the DBD::mSQL driver
$drh = DBI->install_driver( 'mSQL' );
if ( $drh ) {
    print "DBD::mSQL driver installed as $drh\n";
  } else {
    die "DBD::mSQL driver *failed* to install: $!\n";
  }
print "Version: $VERSION\n";

#use strict;

sub Msql::AUTOLOAD {
    my $meth = $Msql::AUTOLOAD;
print "in new AUTOLOAD: $Msql::AUTOLOAD\n";
    $meth =~ s/^.*:://g;
    $meth =~ s/_//g;
    $meth = lc( $meth );

    TRY: {
          if (defined &$meth) {
              *$meth = \&{$meth};
              return &$meth(@_);
          } elsif ($meth =~ s/(.*)type$/uc($1)."_TYPE"/e) {
              # Try to determine the type that was requested by
              # translating inttype to INT_TYPE Not that I consider it
              # good style to write inttype, but we once allowed it,
              # so...
              redo TRY;
          }
      }
  }

sub _func_ref {
    my $name = shift;
    my $pkg = "DBD::mSQL";
    print "in func_ref\n";
    \&{"${pkg}::$name"};
}

###
# Connect: Connects to an mSQL server on the given host. Returns $dbh
#
sub connect {

    my @ary = @_;
    my $junk = "";
#    print "Args: $#ary\n";
    if ( $#ary == 1 ) {
        warn "Single argument Connect is deprecated. Use double argument\n";
        ( $junk, $connect::host ) = @ary;
        $Msql::drh->connect( $connect::host, '', '' );
      } else {
        ( $junk, $connect::host, $connect::dbname ) = @ary;
#        print "Msqlperl: connect( $connect::host, $connect::dbname )\n";
        $Msql::drh->connect( $connect::host, $connect::dbname, '' );
      }
  } 

### Backward compatibility stub
sub Connect {
    &connect( @_ );
  }

###
# listdbs: Lists the databases in a given $dbh
#
sub DBI::db::listdbs {
    ( $DBI::db::listdbs::dbh ) = @_;
    $DBI::db::listdbs::dbh->func( '_ListDBs' );
  }

### Backward compatibility stub
sub DBI::db::ListDBs {
    &DBI::db::listdbs( @_ );
  }

###
# selectdb:
#
sub DBI::db::selectdb {
    ( $DBI::db::selectdb::dbh, $dbname ) = @_;
    warn "SelectDB deprecated. Use double argument Connect call instead.\n";
    $DBI::db::selectdb::dbh->func( "$dbname", '_SelectDB' );
    return "OK";
  }

### Backward compatibility stub
sub DBI::db::SelectDB {
    &DBI::db::selectdb( @_ );
  }

###
# ListTable: Lists tables in the selected database
#
sub DBI::db::listtables {
    ( $DBI::db::listtables::dbh ) = @_;
    $DBI::db::listtables::dbh->func( '_ListTables' );
  }

### Backward compatibility stub
sub DBI::db::ListTables {
    &DBI::db::listtables( @_ );
  }

###
# ListFields: Lists the fields in a specified table
#
sub DBI::db::listfields {
    ( $DBI::db::listfields::dbh, $tablename ) = @_;
    bless $DBI::db::listfields::dbh->func( "$tablename", '_ListFields' ),
          DBI::st;
  }

### Backward compatibility stub
sub DBI::db::ListFields {
    &DBI::db::listfields( @_ );
  }

###
# Query: Issue a query to the database
# 
sub DBI::db::query {
    ( $DBI::db::query::dbh, $stmt ) = @_;
    # Do the query cycle of prepare and execute in one
    $sth = $DBI::db::query::dbh->prepare( $stmt );
    $sth->execute;
    # Return a ref to the metadata of the fields in the query
#    bless $sth->func( '_ListSelectedFields' ), DBI::st;
    return &DBI::st::listselectedfields( $sth );
  }

### Backward compatibility stub
sub DBI::db::Query {
    &DBI::db::query( @_ );
  }

### 
# listselectedfields: Returns a reference to metadata of the selected fields
#
sub DBI::st::listselectedfields {
    ( $DBI::st::listselectedfields::sth ) = @_;
    bless $sth->{Database}->func( "TABLE01", '_ListFields' ), DBI::st;
  }

###
# numrows: Get the number of rows from a $sth
#
sub DBI::st::numrows {
    ( $DBI::st::numrows::sth ) = @_;
    $DBI::st::numrows::sth->func( '_NumRows' );
  }

###
# numfields: Get the number of fields from a $sth
#
sub DBI::st::numfields {
    ( $DBI::st::numfields::sth ) = @_;
    $DBI::st::numfields::sth->{NUMFIELDS};
  }

###
# name: Returns the name of the $sth?
#
sub DBI::st::name {
    ( $DBI::st::name::sth ) = @_;
    $nameok = 0;
    foreach $key ( keys %{$DBI::st::name::sth} ) {
        if ( $key eq "NAME" ) {
            $nameok = 1;
          }
      }
    if ( $nameok == 1 ) {
        return $DBI::st::name::sth->{NAME};
      } else {
        $ref = $DBI::st::name::sth->func( '_ListSelectedFields' );
        return $ref->{NAME};
      }
    return undef;
  }

###
# table: Returns the table name of this reference
#
sub DBI::st::table {
    ( $DBI::st::table::sth ) = @_;
    $tableok = 0;
    foreach $key ( keys %{$DBI::st::name::sth} ) {
        if ( $key eq "TABLE" ) {
            $tableok = 1;
          }
      }
    if ( $tableok == 1 ) {
        return $DBI::st::name::sth->{TABLE};
      } else {
        $ref = $DBI::st::table::sth->func( '_ListSelectedFields' );
        return $ref->{NAME};
      }
    return undef;
  }

###
# type: Stores the type of field
#
sub DBI::st::type {
    ( $DBI::st::type::sth ) = @_;
    $typeok = 0;
    foreach $key ( keys %{$DBI::st::type::sth} ) {
        if ( $key eq "TYPE" ) {
            $typeok = 1;
          }
      }
    if ( $typeok == 1 ) {
        return $DBI::st::type::sth->{TYPE};
      } else {
        $ref = $DBI::st::table::sth->func( '_ListSelectedFields' );
        return $ref->{TYPE};
      }
    return undef;
  }

###
# isnotnull: Returns whether this field is NULLable or not
#
sub DBI::st::isnotnull {
    ( $DBI::st::isnotnull::sth ) = @_;
    $isnotnullok = 0;
    foreach $key ( keys %{$DBI::st::isnotnull::sth} ) {
        if ( $key eq "IS_NOT_NULL" ) {
            $isnotnullok = 1;
          }
      }
    if ( $isnotnullok == 1 ) { 
        return $DBI::st::isnotnull::sth->{IS_NOT_NULL};
      } else {
        $ref = $DBI::st::isnotnull::sth->func( '_ListSelectedFields' );
        return $ref->{IS_NOT_NULL};
      }
    return undef;
  }

###
# is_not_null: As above
#
sub DBI::st::is_not_null {
    ( $DBI::st::is_not_null::sth ) = @_;
    $isnotnullok = 0;
    foreach $key ( keys %{$DBI::st::is_not_null::sth} ) {
        if ( $key eq "IS_NOT_NULL" ) {
            $isnotnullok = 1;
          }
      }
    if ( $isnotnullok == 1 ) { 
        return $DBI::st::is_not_null::sth->{IS_NOT_NULL};
      } else {
        $ref = $DBI::st::is_not_null::sth->func( '_ListSelectedFields' );
        return $ref->{IS_NOT_NULL};
      }
    return undef;
  }

###
# isprikey: Returns whether this field is a Primary Key or not
#
sub DBI::st::isprikey {
    ( $DBI::st::isprikey::sth ) = @_;
    $isprikey = 0;
    foreach $key ( keys %{$DBI::st::isprikey::sth} ) {
        if ( $key eq "IS_PRI_KEY" ) {
            $isprikey = 1;
          }
      }
    if ( $isprikey == 1 ) {
        return $DBI::st::isprikey::sth->{IS_PRI_KEY};
      } else {
        $ref = $DBI::st::isprikey::sth->func( '_ListSelectedFields' );
        return $ref->{IS_PRI_KEY};
      }
    return undef;
  }

###
# isprikey: Returns whether this field is a Primary Key or not
#
sub DBI::st::is_pri_key {
    ( $DBI::st::is_pri_key::sth ) = @_;
    $isprikey = 0;
    foreach $key ( keys %{$DBI::st::is_pri_key::sth} ) {
        if ( $key eq "IS_PRI_KEY" ) {
            $isprikey = 1;
          }
      }
    if ( $isprikey == 1 ) {
        return $DBI::st::is_pri_key::sth->{IS_PRI_KEY};
      } else {
        $ref = $DBI::st::is_pri_key::sth->func( '_ListSelectedFields' );
        return $ref->{IS_PRI_KEY};
      }
    return undef;
  }

###
# length: Returns the length of the field
#
sub DBI::st::length {
    ( $DBI::st::length::sth ) = @_;
    $length = 0;
    foreach $key ( keys %{ $DBI::st::length::sth} ) {
        if ( $key eq "LENGTH" ) {
            $length = 1;
          }
      }
    if ( $length == 1 ) {
        return $DBI::st::length::sth->{LENGTH};
      } else {
        $ref = $DBI::st::length::sth->func( '_ListSelectedFields' );
        return $ref->{LENGTH};
      }
    return undef;
  }

###
# Seeks a particular row within a result set. Not implemented
#
sub DBI::st::dataseek {
    warn "Not implemented.\n";
  }

###
# as_string: Not implemented.
#
sub DBI::st::as_string {
    warn "Not implemented.\n";
  }

###
# fetchhash: Not implemented.
#
sub DBI::st::fetchhash {
    warn "Not implemented.\n";
  }

###
# Msqlperl error handling stuff
#
# References the Msqlperl error message string to our DBI one
*Msql::db_errstr = \$DBI::errstr;

###
# errmsg: Returns $DBI::errstr
#
sub errmsg {
    return DBI::errstr;
  }

1;
__END__
