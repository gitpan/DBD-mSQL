#!/usr/bin/perl -w

sub BEGIN {
    unshift @INC, '..';
  }

use Msql;

print "Connect Msql 'localhost' 'Test':\n";
my $dbh = Connect Msql 'localhost', 'Test';
die "connect failed" unless $dbh;
undef $dbh;

print "\Connect Msql 'localhost': \n";
my $dbh = Connect Msql 'localhost';
die "connect failed" unless $dbh;

print "\$dbh->listdbs: \n";
my @dbs = $dbh->listdbs;
print "\tdbs=<@dbs>\n";

print "\$dbh->selectdb ('Test'): \n";
my $rv = $dbh->SelectDB ('Test');
print "\trv=$rv\n";
die "selectdb failed" unless $rv;

print "\$dbh->listtables: \n";
my @tbls = $dbh->listtables;
print "\ttbls=<@tbls>\n";

if (grep /^test$/, @tbls) {
    print "\$dbh->query ('drop table test'): \n";
    my $sh = $dbh->query ("drop table test");
    die "query failed: ", $dbh->errmsg unless $sh;
    undef $sh;
}

print "\$dbh->query ('create table test (t1 integer, t2 char(100))'): \n";
my $sh = $dbh->query ('create table test (t1 integer, t2 char(100))');
die "query failed: ", $dbh->errmsg unless $sh;
print "\tsh=$sh fields=", $sh->numfields(), "\n";
undef $sh;
    
print "\$dbh->listfields ('test'): \n";
my $sh = $dbh->listfields ('test');
print "\tsh=$sh fields=", $sh->numfields, "\n";

print "call name() for reference value\n";
my $name = $sh->name;
print "\tref \$sh->name: ", ref ($sh->name), " name=<@$name>\n";
undef $name;

print "call name() for array value\n";
my @name = $sh->name;
print "\tname=<@name>\n";
undef @name;

print "All sh methods for array value\n",
    "\ttable=<", join (' ', $sh->table), ">\n",
    "\tname=<", join (' ', $sh->name), ">\n",
    "\ttype=<", join (' ', $sh->type), ">\n",
    "\tisnotnull=<", join (' ', $sh->isnotnull), ">\n",
    "\tis_not_null=<", join (' ', $sh->is_not_null), ">\n",
    "\tisprikey=<", join (' ', $sh->isprikey), ">\n",
    "\tis_pri_key=<", join (' ', $sh->is_pri_key), ">\n",
    "\tlength=<", join (' ', $sh->length), ">\n";
undef $sh;

print "\$dbh->query ('insert into test (t1, t2) values (1, 'test1')): \n";
my $sh =  $dbh->query ("insert into test (t1, t2) values (1, 'test1')");
die "query failed: ", $dbh->errmsg unless $sh;
undef $sh;

print "\$dbh->query ('insert into test (t1, t2) values (2, 'test2')): \n";
my $sh =  $dbh->query ("insert into test (t1, t2) values (2, 'test2')");
die "query failed: ", $dbh->errmsg unless $sh;
undef $sh;

print "\$dbh->query ('select from test'): \n";
my $sh = $dbh->query( "SELECT t1, t2 FROM test" );
die "query failed: ", $dbh->errmsg unless $sh;

print "\$sh->numrows: \n";
my $rows =  $sh->numrows;
die "numrows failed: ", $dbh->errmsg unless defined $rows;
print "rows=$rows\n";
die "numrows failed: ", $dbh->errmsg unless $rows;

my @row;
while (@row = $sh->fetchrow) {
    print "\tfetchrow: <@row>\n";
}
print "\tfetchrow should return empty: <", join (' ', $sh->fetchrow), ">\n";
undef $sh;

print "\$dbh->query ('insert into test (t1, t2) values (3, 'test3')): \n";
my $sh =  $dbh->query ("insert into test (t1, t2) values (3, 'test3')");
die "query failed: ", $dbh->errmsg unless $sh;
undef $sh;

print "\$dbh->query ('select t1, t2 from test'): \n";
my $sh =  $dbh->query ("select t1, t2 from test");
die "query failed: ", $dbh->errmsg unless $sh;

print "\$sh->numrows: \n";
my $rows =  $sh->numrows;
die "numrows failed: ", $dbh->errmsg unless defined $rows;
print "rows=$rows\n";
die "numrows failed: ", $dbh->errmsg unless $rows;

print "call name() for reference value\n";
my $name = $sh->name;
print "\tref \$sh->name: ", ref ($sh->name), " name=<@$name>\n";
undef $name;

print "call name() for array value\n";
my @name = $sh->name;
print "\tname=<@name>\n";
undef @name;

print "All sh methods for array value\n",
    "\ttable=<", join (' ', $sh->table), ">\n",
    "\tname=<", join (' ', $sh->name), ">\n",
    "\ttype=<", join (' ', $sh->type), ">\n",
    "\tisnotnull=<", join (' ', $sh->isnotnull), ">\n",
    "\tis_not_null=<", join (' ', $sh->is_not_null), ">\n",
    "\tisprikey=<", join (' ', $sh->isprikey), ">\n",
    "\tis_pri_key=<", join (' ', $sh->is_pri_key), ">\n",
    "\tlength=<", join (' ', $sh->length), ">\n";
undef $sh;

undef $dbh;

