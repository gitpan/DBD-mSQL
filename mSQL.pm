#   $Id: mSQL.pm,v 1.18 1995/08/15 05:31:30 timbo Rel $
#
#   Copyright (c) 1994,1995 Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
    package DBD::mSQL;

    require DBI;

    require DynaLoader;
    @ISA = qw(DynaLoader);

	$VERSION = substr(q$Revision: 1.18 $, 10);

    bootstrap DBD::mSQL;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'mSQL',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::mSQL::err,
	    'Errstr' => \$DBD::mSQL::errstr,
	    'Attribution' => 'mSQL DBD by Alligator Descartes',
	    });

	$drh;
    }

    1;
}


{   package DBD::mSQL::dr; # ====== DRIVER ======
    use strict;

    sub errstr {
	DBD::mSQL::errstr(@_);
    }

    sub connect {
	my($drh, $host, $dbname)= @_;

	# create a 'blank' dbh

        $host = '' if ( $host eq '*' );

	my $this = DBI::_new_dbh($drh, {
            'Host' => $host,
	    'Name' => $dbname
	    });

	# Call mSQL OCI orlon func in mSQL.xs file
	# and populate internal handle data.

	DBD::mSQL::db::_login($this, $host, $dbname)
	    or return undef;

	$this;
    }

}


{   package DBD::mSQL::db; # ====== DATABASE ======
    use strict;

    sub errstr {
	DBD::mSQL::errstr(@_);
    }

    sub prepare {
	my($dbh, $statement)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call mSQL OCI oparse func in mSQL.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::mSQL::st::_prepare($sth, $statement)
	    or return undef;

	$sth;
    }

}


{   package DBD::mSQL::st; # ====== STATEMENT ======
    use strict;

    sub errstr {
	DBD::mSQL::errstr(@_);
    }
}

1;
