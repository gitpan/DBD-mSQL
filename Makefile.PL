#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.21 1995/06/22 00:37:04 timbo Rel $
#
# Modification History:
# By:		Date:		Description:
# Andreas	03/08/95	Added /usr/local/Minerva to MSQL_HOME search
#				list
# Karsten	10/08/95	Fixed missing space in $linkwith
# Descartes	05/11/95	Cleaned the Oracle-isms out for 0.60pl7

use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose %att);
use Getopt::Std;
use Config;

use DBI;	# The DBI must be installed before we can build a DBD

%opts = (
    'NAME'    => 'DBD::mSQL',
    'VERSION' => '0.60pl7',
);

# Options, typically only used for debugging
#$opt_m = '';		# path to proc.mk or oracle.mk file to read

#getopts('m:') or die "Invalid arguments";

# --- Introduction

print "\nConfiguring DBD::mSQL version $opts{VERSION}...\n";
print "Remember to actually read the README file!\n\n";

# --- Where is mSQL installed...

unless ($ENV{MSQL_HOME}){
    warn "\$MSQL_HOME not defined. Searching for mSQL...\n";
    foreach(qw(/usr/local/Minerva /usr/mSQL /opt/mSQL /usr/soft/mSQL)){
	$ENV{MSQL_HOME}=$_,last if -d "$_/lib";
    }
    die "Unable to determine \$MSQL_HOME!\n" unless $ENV{MSQL_HOME};
}
my $MH = $ENV{MSQL_HOME};

print "Using mSQL in $MH\n";

# --- What mSQL is installed...

# Validate we have the right stuff installed

warn "Warning: mSQL library does not appear to be installed.\n"
	unless -f "$MH/lib/libmsql.a"
	   and -f "$MH/include/msql.h";

# read list of libs that oracle requires (eg -lm -lnsl)
$sysliblist = "-L$MH/lib -lmsql -lm";
print "mSQL sysliblist: $sysliblist\n";

# We need to link with -R if we're on Solaris.......Brain-damaged....
if ( $Config{osname} eq 'solaris' ) {
    $linkwith = "-L$MH/lib -R$MH/lib";
  } else {
    $linkwith = "-L$MH/lib";
  }
 
$opts{LIBS} = [ $sysliblist ];
$opts{INC}  = "-I$MH/include -I$Config{archlib}/DBI";
#$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(LIBHOME)' .$linkwith };
$opts{dynamic_lib} = { OTHERLDFLAGS => '-L$(MSQL_HOME)/lib ' .$linkwith };
$opts{OBJECT} = '$(O_FILES)';

$opts{DEFINE} = '-Wall -pedantic -Wno-comment -Wpointer-arith -Wcast-align'
	    . ' -Wconversion -Wtraditional -Wpointer-arith'
	    . ' -Wcast-qual'
	if $Config{cc} eq 'gcc';	# Just me asking gcc to be paranoid.

$opts{DEFINE} .= ' -Xa' if $Config{cc} eq 'clcc';	# CenterLine CC


# log key platform information to help me help you quickly
print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";

# Assorted hints - these should be move to a hints subdirectory
print "See README notes about SPARCompiler on Solaris\n"
    if -d "/opt/SUNWspro/bin" and $Config{osname} eq 'solaris';

print "\n";

WriteMakefile(%opts);

__END__
