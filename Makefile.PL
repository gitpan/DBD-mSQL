#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.21 1995/06/22 00:37:04 timbo Rel $
#
# Modification History:
# By:		Date:		Description:
# Andreas	03/08/95	Added /usr/local/Minerva to MSQL_HOME search
#				list
# Karsten	10/08/95	Fixed missing space in $linkwith
# descarte	05/11/95	Cleaned the Oracle-isms out for 0.60pl7
# descarte	30/12/95	Some more twiddles for 0.60pl9
# descarte	02/01/97	Added keyword stuff and some SCO patches
# descarte	12/01/97	Added mSQL-2 optioning.
# descarte  27/03/97    Added TCP socket detection code if the mSQL daemon
#                       is running. This saves people having to answer hard
#                       questions.
# descarte  27/03/97    Added /usr/local/Hughes to the list of default
#                       directories to search

BEGIN { require 5.003 }

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose);
use Getopt::Std;
use Config;

use DBI 0.71;	# The DBI must be installed before we can build a DBD

%opts = (
    'NAME'    => 'DBD::mSQL',
    'VERSION' => '0.63',
);

# --- Introduction

print "\nConfiguring DBD::mSQL version $opts{VERSION}...\n";
print "Remember to actually read the README file!\n\n";
print "And YES, I REALLY MEAN READ IT!\n\n";
print "Hints, tips, ramblings and Frequently Asked Questions at:\n\n";
print "\t\thttp://www.hermetica.com/technologia/perl/DBI\n\n";
print "Please *READ* this information.\n\n";

# --- Where is mSQL installed...

unless ($ENV{MSQL_HOME}){
    warn "\$MSQL_HOME not defined. Searching for mSQL...\n";
    foreach(qw(/usr/local/Minerva /usr/mSQL /opt/mSQL /usr/local/Hughes)){
	$ENV{MSQL_HOME}=$_,last if -d "$_/lib";
    }
    die "** Unable to determine \$MSQL_HOME!\n\n** Please set MSQL_HOME. This is used for building only...\n" unless $ENV{MSQL_HOME};
}
my $MH = $ENV{MSQL_HOME};

# @@We might want to change this in the future to auto-detect the mSQL
# version, but let's be lazy just now.
print "Using mSQL in $MH\n";
open TTY, "/dev/tty" || die "Cannot open tty! Run in the foreground!\n";
print "\n -> Which version of mSQL are you using [1/2]? ";
$blah = <TTY>;
if ( $blah =~ /1/ ) {
    print "\nYou say you're running mSQL version 1........\n\n";
    $msqlVersion = 1;
    $opts{DEFINE} = " -DMSQL1 ";
  } else {
    print "\nYou say you're running mSQL version 2....\n\n";
    $msqlVersion = 2;
    $opts{DEFINE} = " -DMSQL2 ";
  }
close TTY;

# Validate we have the right stuff installed
print <<EOM;
Checking to make sure the value you specified as \$MSQL_HOME is correct,
and that your installation appears to work...
EOM

$installWarning = 0;
if ( !-f "$MH/lib/libmsql.a" ) {
    if ( !-f "$MH/include/msql.h" ) {
        warn "Warning: mSQL library does not appear to be installed.\n";
        $installWarning = 1;
      }
  } 

if ( $installWarning == 0 ) {
    print "Your installation looks fine\n\n";
  }

# read list of libs that mSQL requires (eg -lm -lnsl)
$extralibs = "";
if ( $Config{osname} eq 'sco_sv' ) { # Some extra libraries need added for SCO
    print <<EOM;
Yuk! I see that you are a SCO Unix system. We'll add -lc to the list of
libraries to link with...
EOM
    $extralibs = "-lc";
  }

# List the libraries we're linking with
$sysliblist = "-L$MH/lib -lmsql -lm $extralibs";
print "Libraries we'll link with: $sysliblist\n\n";

# We need to link with -R if we're on Solaris.......Brain-damaged....
if ( $Config{osname} eq 'solaris' ) {
    print <<EOM;
Oh dear. Solaris? Let's add some more flags into the linker stage...

EOM
    $linkwith = "-L$MH/lib -R$MH/lib";
  } else {
    $linkwith = "-L$MH/lib";
  }

# Try running '$MSQL_HOME/bin/msqladmin version' and see what we get
# as the result
print <<EOM;
Checking to see if we can auto-detect your installation's configuration...

EOM

# Check to make sure 'msqladmin' is installed
if ( -x "$MH/bin/msqladmin" ) {
    print "msqladmin found in $MH/bin\n";
    $msqladmin = 1;
  } else {
    $msqladmin = 0;
    undef $msqladminversion;
    print "Cannot find msqladmin in $MH/bin\n";
  }

if ( $msqladmin == 1 ) {
    $msqladminversion = 
        open MSQLADMINVERSION, "$MH/bin/msqladmin version 2>&1 |";
    while ( <MSQLADMINVERSION> ) {
        if ( /^ERROR :/ ) {
            print "'msqladmin version' errored: $_\n";
            print "I'm going to have to prompt for information on your setup!\n";
            print "Don't be scared!\n\n";
            print "Either that, or start up the mSQL daemon, and re-run this script.\n\n";
            undef $msqladminversion;
          }
      }
    close MSQLADMINVERSION;
    open MSQLADMINVERSION, "$MH/bin/msqladmin version 2>&1 |";
  }

if ( !defined $msqladminversion ) {
    # Prompt for root ( or non-root ) install............
    open TTY, "/dev/tty" || die "Cannot open tty! Run in the foreground!\n";
    print <<EOM;
You're about to get asked whether or not you are a root install. This
basically means, did you install mSQL as the user 'root' or not. If you
don't know, answer that you're a root install, or find whoever it was that
installed mSQL in the first place. We use your answer to work out which
port number the mSQL daemon will be running on. However, a caveat is that
the hard-coded values in mSQL may be overridden by either environment
variables or the mSQL configuration file. If you specify a value here,
and the test script fails to connect to the server ( after you've started
the server! ), go find the local guru and ask him/her to restart the 
server. It's much easier that way...

EOM
    print "-> Is this installation a root install or non-root? [root/notroot] ";
    $blah = <TTY>;
    if ( $blah =~ /not/ ) {
        $rootType = "non-root";
        if ( $msqlVersion == 1 ) {
            $port = 4333;
          } else {
            if ( $msqlVersion == 2 ) {
                $port = 4334;
              }
          }
      } else {
        $rootType = "root";
        if ( $msqlVersion == 1 ) {
            $port = 1112;
          } else {
            if ( $msqlVersion == 2 ) {
                $port = 1113;
              }
          }
      }
    print "You say you're a $rootType install on mSQL-$msqlVersion, which makes your default port: $port\n\n";
    close TTY;
  } else {
    # Parse the input for the line marked 'TCP socket'. That'll tell us
    # which port number to use
    print <<EOM;

Splendid! Your mSQL daemon is running. We can auto-detect your configuration!

EOM
    while ( <MSQLADMINVERSION> ) {
        if ( /TCP socket/ ) {
            my $tmpline = $_;
            $tmpline =~ s/\ +/\ /g;
            $tmpline =~ s/\t//g;
            $tmpline =~ s/mSQL //g;
            chomp( $tmpline );
            my @tmp = split( /\ /, $tmpline );
            $port = $tmp[2];
            print <<EOM;
I've auto-detected your configuration to be running on port: $port

EOM
          }
      }
  }

open MSQLPMIN, "./mSQL.pm.pre-install" || die "Cannot open mSQL.pm.pre-install: $!\n";
open MSQLPMOUT, ">./mSQL.pm" || die "Cannot write to mSQL.pm: $!\n";
while ( <MSQLPMIN> ) {
    if ( /\%\%MSQL_TCP_PORT\%\%/ ) {
        s/\%\%MSQL_TCP_PORT\%\%/$port/g;
      }
    print MSQLPMOUT "$_";
  }
close MSQLPMOUT;
close MSQLPMIN;
 
$opts{dist} = { SUFFIX => ".gz", DIST_DEFAULT => 'all tardist',
                COMPRESS => "gzip -9 -v -f" };
$opts{LIBS} = [ $sysliblist ];
$opts{INC}  = "-I$MH/include" . ' -I$(INSTALLSITEARCH)/auto/DBI -I$(INSTALLARCHLIB)';
$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(MSQL_HOME)/lib ' .$linkwith };
$opts{OBJECT} = '$(O_FILES)';

$opts{DEFINE} .= '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
	    . ' -Wconversion -Wtraditional -Wpointer-arith'
	    . ' -Wcast-qual'
	if $Config{cc} eq 'gcc' && $ENV{LOGNAME} eq "descarte";

$opts{DEFINE} .= ' -Xa' if $Config{cc} eq 'clcc';	# CenterLine CC

# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

# Assorted hints - these should be move to a hints subdirectory
print "See README notes about SPARCompiler on Solaris\n"
    if -d "/opt/SUNWspro/bin" and $Config{osname} eq 'solaris';

print "\n";

open TTY, "/dev/tty" || die "Cannot open tty! Run in the foreground!\n";
print "Keyword? ";
$blah = <TTY>;
if ( $blah =~ /ZoOblE/ ) {
    print "Keyword verification is correct!\n";
  } else {
    print "Keyword verification has failed! Read the README, the FAQ and any other\ndocuments mentioned in the README before retrying the build process.\n";
    exit 1;
  }
close TTY;

WriteMakefile(%opts);

__END__
