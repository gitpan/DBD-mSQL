/*
   $Id: mSQL.xs,v 1.27 1995/06/22 00:37:04 timbo Rel $

   Copyright (c) 1994,1995  Alligator Descartes

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

#include "mSQL.h"


/* --- Variables --- */


DBISTATE_DECLARE;

/* see dbd_init for initialisation */
SV *dbd_errnum = NULL;
SV *dbd_errstr = NULL;


MODULE = DBD::mSQL	PACKAGE = DBD::mSQL

BOOT:
    items = 0;	/* avoid 'unused variable' warning */
    DBISTATE_INIT;
#    fprintf( stderr, "Bootstrapping mSQL-0.60pl1 ** Disney release\n(c)1995 Alligator Descartes <descarte@mcqueen.com>\n(c)1994-1995 Portions by Tim Bunce <Tim.Bunce@ig.co.uk>\nMuch thanks to Andreas Koenig <k@anna.mind.de>\n\n" );
    /* XXX tis interface will change: */
    DBI_IMP_SIZE("DBD::mSQL::dr::imp_data_size", sizeof(imp_drh_t));
    DBI_IMP_SIZE("DBD::mSQL::db::imp_data_size", sizeof(imp_dbh_t));
    DBI_IMP_SIZE("DBD::mSQL::st::imp_data_size", sizeof(imp_sth_t));
    dbd_init(DBIS);

void
errstr(h)
    SV *	h
    CODE:
    h = 0;	/* avoid 'unused variable' warning */
    ST(0) = sv_mortalcopy(dbd_errstr);


MODULE = DBD::mSQL	PACKAGE = DBD::mSQL::dr

void
disconnect_all(drh)
    SV *        drh
    CODE:
    if (!dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0))) {
        D_imp_drh(drh);
        sv_setiv(DBIc_ERR(imp_drh), (IV)1);
        sv_setpv(DBIc_ERRSTR(imp_drh),
                (char*)"disconnect_all not implemented");
        DBIh_EVENT2(drh, ERROR_event,
                DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh));
        XSRETURN(0);
    }
    XST_mIV(0, 1);


void
_ListDBs(drh, host)
    SV *        drh
    char *	host
    PPCODE:
    m_result *res;
    m_row cur;
    int sock;
    sock = msqlConnect( host );
    if ( sock != -1 ) {
        res = msqlListDBs( sock );
        if ( !res ) {
            warn( "Error!\n" );
          } else {
            while ( ( cur = msqlFetchRow( res ) ) ) {
                EXTEND( sp, 1);
                PUSHs( sv_2mortal((SV*)newSVpv( cur[0], strlen(cur[0]))));
              }
          }
        msqlFreeResult( res );
        msqlClose( sock );
      }

MODULE = DBD::mSQL    PACKAGE = DBD::mSQL::db

void
_ListTables(dbh)
    SV *	dbh
    PPCODE:
    D_imp_dbh(dbh);
    m_result *res;
    m_row cur;
    res = msqlListTables( imp_dbh->lda.svsock );
    if ( !res ) {
        warn( "Error in msqlListTables!\n" );
      } else {
        while ( ( cur = msqlFetchRow( res ) ) ) {
            EXTEND( sp, 1 );
            PUSHs( sv_2mortal((SV*)newSVpv( cur[0], strlen( cur[0] )))); 
          }
      }
    msqlFreeResult( res );
  

void
_ListFields(dbh, tabname)
    SV * 	dbh
    char *	tabname
    PPCODE:
    D_imp_dbh(dbh);
    m_result *res;
    m_field *curField;
    HV * stash;
    HV * hv;
    SV * rv;
    AV * avkey;
    AV * avnam;
    AV * avnnl;
    AV * avtab;
    AV * avtyp;
    char *	package = "DBD::mSQL::db::_ListFields";
    res = msqlListFields( imp_dbh->lda.svsock, tabname );
    if ( !res ) {
        warn( "Error in msqlListTables!\n" );
      } else {
        hv = (HV*)sv_2mortal((SV*)newHV());
        hv_store(hv,"NUMROWS",7,(SV *)newSViv((IV)msqlNumRows(res)),0);
        hv_store(hv,"NUMFIELDS",9,(SV *)newSViv((IV)msqlNumFields(res)),0);
        msqlFieldSeek(res,0);
        while ( ( curField = msqlFetchField( res ) ) ) {
            av_push(avnam,(SV*)newSVpv(curField->name,strlen(curField->name)));
            av_push(avtab,(SV*)newSVpv(curField->table,strlen(curField->table)));
            av_push(avtyp,(SV*)newSViv(curField->type));
            av_push(avkey,(SV*)newSViv(IS_PRI_KEY(curField->flags)));
            av_push(avnnl,(SV*)newSViv(IS_NOT_NULL(curField->flags)));
          }
        rv = newRV((SV*)avnam); hv_store(hv,"NAME",4,rv,0);
        rv = newRV((SV*)avtab); hv_store(hv,"TABLE",5,rv,0);
        rv = newRV((SV*)avtyp); hv_store(hv,"TYPE",4,rv,0);
        rv = newRV((SV*)avkey); hv_store(hv,"IS_PRI_KEY",10,rv,0);
        rv = newRV((SV*)avnnl); hv_store(hv,"IS_NOT_NULL",11,rv,0);
        hv_store(hv,"RESULT",6,(SV *)newSViv((IV)res),0);
        rv = newRV((SV*)hv);
        stash = gv_stashpv(package, TRUE);
      }
    msqlFreeResult( res );


void
_login(dbh, host, dbname)
    SV *	dbh
    char *	host
    char *	dbname
    CODE:
    ST(0) = dbd_db_login(dbh, host, dbname) ? &sv_yes : &sv_no;


void
commit(dbh)
    SV *        dbh
    CODE:
    ST(0) = dbd_db_commit(dbh) ? &sv_yes : &sv_no;

void
rollback(dbh)
    SV *        dbh
    CODE:
    ST(0) = dbd_db_rollback(dbh) ? &sv_yes : &sv_no;

void
STORE(dbh, keysv, valuesv)
    SV *        dbh
    SV *        keysv
    SV *        valuesv
    CODE:
    if (!dbd_db_STORE(dbh, keysv, valuesv)) {
        /* XXX hand-off to DBI for possible processing */
        croak("Can't set %s->{%s}: unrecognised attribute",
                SvPV(dbh,na), SvPV(keysv,na));
    }
    ST(0) = &sv_undef;  /* discarded anyway */

void
FETCH(dbh, keysv)
    SV *        dbh
    SV *        keysv
    CODE:
    SV *valuesv = dbd_db_FETCH(dbh, keysv);
    if (!valuesv) {
        /* XXX hand-off to DBI for possible processing  */
        croak("Can't get %s->{%s}: unrecognised attribute",
                SvPV(dbh,na), SvPV(keysv,na));
    }
    ST(0) = valuesv;    /* dbd_db_FETCH did sv_2mortal  */

void
disconnect(dbh)
    SV *        dbh
    CODE:
    D_imp_dbh(dbh);
    if ( !DBIc_ACTIVE(imp_dbh) ) {
        if (DBIc_WARN(imp_dbh) && !dirty)
            warn("disconnect: already logged off!");
        XSRETURN_YES;
    }
    /* Check for disconnect() being called whilst refs to cursors       */
    /* still exists. This needs some more thought.                      */
    /* XXX We need to track DBIc_ACTIVE children not just all children  */
    if (DBIc_KIDS(imp_dbh) && DBIc_WARN(imp_dbh) && !dirty) {
        warn("disconnect(%s) invalidates %d associated cursor(s)",
            SvPV(dbh,na), DBIc_KIDS(imp_dbh));
    }
    ST(0) = dbd_db_disconnect(dbh) ? &sv_yes : &sv_no;


void
DESTROY(dbh)
    SV *        dbh
    CODE:
    D_imp_dbh(dbh);
    ST(0) = &sv_yes;
    if (!DBIc_IMPSET(imp_dbh)) {        /* was never fully set up       */
        if (DBIc_WARN(imp_dbh) && !dirty)
             warn("Database handle %s DESTROY ignored - never set up",
                SvPV(dbh,na));
        return;
    }
    if (DBIc_ACTIVE(imp_dbh)) {
        if (DBIc_WARN(imp_dbh) && !dirty)
             warn("Database handle destroyed without explicit disconnect");
        dbd_db_disconnect(dbh);
    }
    dbd_db_destroy(dbh);                


MODULE = DBD::mSQL    PACKAGE = DBD::mSQL::st

void
_prepare(sth, statement)
    SV *        sth
    char *      statement
    CODE:
    ST(0) = dbd_st_prepare(sth, statement) ? &sv_yes : &sv_no;


void
rows(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
#    XST_mIV(0, (IV)imp_sth->cda->rpc);


void
execute(sth, ...)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    /* Handle binding any supplied values to placeholders */
    if (items > 1) {
        char name[16];
        int i, error;
        if (items-1 != HvKEYS(imp_sth->bind_names)) {
            do_error(0, "Wrong number of bind variables");
            XSRETURN_UNDEF;
        }
        for(i=1, error=0; i < items ; ++i) {
            sprintf(name, ":p%d", i);
#p            if (dbd_bind_ph(sth, imp_sth, name, ST(i)))
#                ++error;
        }
        if (error) {
            XSRETURN_UNDEF;     /* dbd_bind_ph called ora_error */
        }
    } else if (imp_sth->bind_names) {
        /* oracle will tell us if values have not been bound    */
        warn("execute assuming binds done elsewhere\n");
    }

    /* describe and allocate storage for results */
    if (!imp_sth->done_desc && dbd_describe(sth, imp_sth)) {
        XSRETURN_UNDEF; /* dbd_describe called ora_error()      */
    }

    /* Trigger execution of the statement */
/*    if (oexec(imp_sth->cda)) { */ /* will change to oexfet later */
/*        ora_error(sth, imp_sth->cda, imp_sth->cda->rc, "oexec error");
        XSRETURN_UNDEF;
    }*/
    DBIc_ACTIVE_on(imp_sth);
    XST_mYES(0);


void
fetchrow(sth)
    SV *	sth
    PPCODE:
    D_imp_sth(sth);
    int i;
    SV *sv;
    imp_sth->done_desc = 0;
    if ( dbis->debug >= 2 ) {
        printf( "In: DBD::mSQL::fetchrow\n" );
        printf( "In: DBD::mSQL::fetchrow'imp_sth->currow: %d\n", 
                imp_sth->currow );
        printf( "In: DBD::mSQL::fetchrow'imp_sth->row_num: %d\n", 
                imp_sth->row_num );
      }
    dbd_describe( sth, imp_sth );
    /* Check that execute() was executed sucessfuly. This also implies	*/
    /* that dbd_describe() executed sucessfuly so the memory buffers	*/
    /* are allocated and bound.						*/
#    pif ( !(imp_sth->flags & IMP_STH_EXECUTING) ) {
#	do_error( 1, "no statement executing");
#	XSRETURN(0);
#      }
    /* Advance through the buffer until we get to the row we want */

    if ( dbis->debug >= 2 ) {
        warn( "Number of fields: %d\n", imp_sth->fbh_num );
        warn( "Current ROWID: %d\n", imp_sth->currow );
      }

    EXTEND(sp,imp_sth->fbh_num);
    for ( i = 0 ; i < imp_sth->fbh_num ; i++ ) {
        imp_fbh_t *fbh = &imp_sth->fbh[i];
        if ( dbis->debug >=2 ) {
            printf( "In: DBD::mSQL::execute'FieldBufferDump: %d\n", i );
            printf( "In: DBD::mSQL::execute'FieldBufferDump->cbuf: %s\n", 
                    fbh->cbuf );
            printf( "In: DBD::mSQL::execute'FieldBufferDump->rlen: %i\n", 
                    fbh->rlen );
          }
        SvCUR( fbh->sv ) = fbh->rlen;
/*        sv = sv_mortalcopy( fbh->sv ); */
        sv = sv_2mortal( newSVpv( (char *)fbh->cbuf, fbh->rlen ) );
        PUSHs(sv);
      }
    imp_sth->currow++;

void
readblob(sth, field, offset, len, destsv=Nullsv)
    SV *        sth
    int field
    long        offset
    long        len
    SV *        destsv
    CODE:
#    ST(0) = dbd_st_readblob(sth, field, offset, len, destsv);
    ST(0) = &sv_undef;


void
STORE(dbh, keysv, valuesv)
    SV *        dbh
    SV *        keysv
    SV *        valuesv
    CODE:
    if (!dbd_st_STORE(dbh, keysv, valuesv)) {
        /* XXX hand-off to DBI for possible processing  */
        croak("Can't set %s->{%s}: unrecognised attribute",
                SvPV(dbh,na), SvPV(keysv,na));
    }
    ST(0) = &sv_undef;  /* discarded anyway */


void
FETCH(sth, keysv)
    SV *        sth
    SV *        keysv
    CODE:
    SV *valuesv = dbd_st_FETCH(sth, keysv);
    if (!valuesv) {
        /* XXX hand-off to DBI for possible processing  */
        croak("Can't get %s->{%s}: unrecognised attribute",
                SvPV(sth,na), SvPV(keysv,na));
    }
    ST(0) = valuesv;    /* dbd_st_FETCH did sv_2mortal  */

void
finish(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    if (!DBIc_ACTIVE(imp_dbh)) {
        /* Either an explicit disconnect() or global destruction        */
        /* has disconnected us from the database. Finish is meaningless */
        /* XXX warn */
        XSRETURN_YES;
    }
    if (!DBIc_ACTIVE(imp_sth)) {
        /* No active statement to finish        */
        /* XXX warn */
        XSRETURN_YES;
    }
    ST(0) = dbd_st_finish(sth) ? &sv_yes : &sv_no;

void
DESTROY(sth)
    SV *        sth
    CODE:
    D_imp_sth(sth);
    ST(0) = &sv_yes;
    if (!DBIc_IMPSET(imp_sth)) {        /* was never fully set up       */
        if (DBIc_WARN(imp_sth) && !dirty)
             warn("Statement handle %s DESTROY ignored - never set up",
                SvPV(sth,na));
        return;
    }
    if (DBIc_ACTIVE(imp_sth)) {
        if (DBIc_WARN(imp_sth) && !dirty)
            warn("Statement handle %s destroyed without finish()",
                SvPV(sth,na));
        dbd_st_finish(sth);
    }
    dbd_st_destroy(sth);

# end of mSQL.xs
