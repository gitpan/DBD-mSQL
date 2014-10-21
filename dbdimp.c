/*
   $Id: dbdimp.c,v 1.4 1995/06/22 00:37:04 timbo Rel $

   Copyright (c) 1994,1995  Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

#include "mSQL.h"

/* see oparse for usage */
/*static sword oparse_defer = 0;*/  /* PARSE_NO_DEFER */
/*static ub4   oparse_lng   = 1;*/  /* v6 or v7 */


DBISTATE_DECLARE;


void
dbd_init(dbistate)
    dbistate_t *dbistate;
{
    DBIS = dbistate;
    dbd_errnum = GvSV(gv_fetchpv("DBD::mSQL::err",    1, SVt_IV));
    dbd_errstr = GvSV(gv_fetchpv("DBD::mSQL::errstr", 1, SVt_PV));
}


void do_error( rc, what )
    sb2 rc;
    char *what;
{
    sv_setiv(dbd_errnum, (IV)rc);
    sv_setpv(dbd_errstr, (char*)what);
}

void
fbh_dump(fbh, i)
    imp_fbh_t *fbh;
    int i;
{
    FILE *fp = DBILOGFP;
    fprintf(fp, "fbh %d: '%s' %s, ",
		i, fbh->cbuf, (fbh->nullok) ? "NULLable" : "");
    fprintf(fp, "type %d,  dbsize %ld, dsize %ld, p%d s%d\n",
	    fbh->dbtype, (long)fbh->dbsize, (long)fbh->dsize, fbh->prec, fbh->scale);
    fprintf(fp, "   out: ftype %d, indp %d, bufl %d, rlen %d, rcode %d\n",
	    fbh->ftype, fbh->indp, fbh->bufl, fbh->rlen, fbh->rcode);
}


int
dbtype_is_long(dbtype)
    int dbtype;
{
    /* Is it a LONG, LONG RAW, LONG VARCHAR or LONG VARRAW?	*/
    return (dbtype==8 || dbtype==24 || dbtype==94 || dbtype==95) ? 1 : 0;
}

/* ================================================================== */

/* 
static AV *imp_dbh_cache_av;
static IV imp_dbh_generation;

static imp_dbh_t *
alloc_imp_dbh()
{
    imp_dbh_t *imp_dbh;
    SV *sv;
    if (imp_dbh_cache_av && AvFILL(imp_dbh_cache_av) > -1) {
	imp_dbh = (imp_dbh_t *)av_pop(imp_dbh_cache_av);
    } else {
	Newz(42, imp_dbh, sizeof(*imp_dbh), imp_dbh_t);
    }
    imp_dbh->in_use = TRUE;
    imp_dbh->dbh_generation = ++imp_dbh_generation;
    return imp_dbh;
}
*/

/*
static void
free_imp_dbh(imp_dbh)
    imp_dbh_t *imp_dbh;
{
    if (imp_dbh_cache_av)
	imp_dbh_cache_av = newAV(); */
    /* This is the last chance we get to free up the memory	*/
    /* allocated to this object.				*/
    /* XXX check for what to free	*/
/*    imp_dbh->in_use = FALSE;
    av_push(imp_dbh_cache_av, (SV*)imp_dbh_cache_av);
}
*/

int
dbd_db_login(dbh, host, dbname)
    SV *dbh;
    char *host;
    char *dbname;
{
    D_imp_dbh(dbh);
    int ret;

/*    dXSARGS;

    imp_dbh_t *imp_dbh = alloc_imp_dbh();
    ST(0) = sv_newmortal();
*/

    if (host && !*host) host = 0;	/* Patch by Sven Verdoolaege */
    imp_dbh->lda.svsock = msqlConnect( host ); 

    if ( ( imp_dbh->lda.svsock == -1 ) || ( dbname && ( msqlSelectDB( imp_dbh->lda.svsock, dbname ) == -1 ) ) ) {
        do_error( imp_dbh->lda.rc, msqlErrMsg );
/*        free_imp_dbh(imp_dbh); */
        return 0;
      } else {
    
        /* Dump the information we have into the Lda_Def */

        imp_dbh->lda.svdb = dbname;
        imp_dbh->lda.svhost = host;
      }
/*    imp_dbh->logged_on = TRUE;
    XST_mIV(0, (IV)imp_dbh); */
    DBIc_IMPSET_on(imp_dbh);    /* imp_dbh set up now                   */
    DBIc_ACTIVE_on(imp_dbh);    /* call disconnect before freeing       */
    return 1;
}

/* Commit and Rollback don't exist in mSQL but we'll stub them anyway... */

int
dbd_db_commit(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);
    return 1;
}

int
dbd_db_rollback(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);
    return 1;
}

int
dbd_db_disconnect(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);
    /* We assume that disconnect will always work       */
    /* since most errors imply already disconnected.    */
    DBIc_ACTIVE_off(imp_dbh);
    if ( dbis->debug >= 2 )
        printf( "imp_dbh->sock: %i\n", imp_dbh->lda.svsock );

    msqlClose( imp_dbh->lda.svsock );

    /* We don't free imp_dbh since a reference still exists	*/
    /* The DESTROY method is the only one to 'free' memory.	*/
    return 1;
}

void
dbd_db_destroy(dbh)
    SV *dbh;
{
    D_imp_dbh(dbh);
    if (DBIc_ACTIVE(imp_dbh))
        dbd_db_disconnect(dbh);
    /* XXX free contents of imp_dbh */
    DBIc_IMPSET_off(imp_dbh);
}

int
dbd_db_STORE(dbh, keysv, valuesv)
    SV *dbh;
    SV *keysv;
    SV *valuesv;
{
    D_imp_dbh(dbh);
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    SV *cachesv = NULL;
    int on = SvTRUE(valuesv);

    if (kl==10 && strEQ(key, "AutoCommit")){
        /* Ignore SvTRUE warning: '=' where '==' may have been intended. */
/*        if ( (on) ? ocon(&imp_dbh->lda) : ocof(&imp_dbh->lda) ) {
            ora_error(dbh, &imp_dbh->lda, imp_dbh->lda.rc, "ocon/ocof failed");
        } else {
            cachesv = (on) ? &sv_yes : &sv_no;
        } */
    } else {
        return FALSE;
    }
    if (cachesv) /* cache value for later DBI 'quick' fetch? */
        hv_store((HV*)SvRV(dbh), key, kl, cachesv, 0);
    return TRUE;
}

SV *
dbd_db_FETCH(dbh, keysv)
    SV *dbh;
    SV *keysv;
{
    D_imp_dbh(dbh);
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    int i;
    SV *retsv = NULL;
    /* Default to caching results for DBI dispatch quick_FETCH  */
    int cacheit = TRUE;

    if (1) {    /* no attribs defined yet       */
        return Nullsv;
    }
    if (cacheit) { /* cache for next time (via DBI quick_FETCH) */
        hv_store((HV*)SvRV(dbh), key, kl, retsv, 0);
        SvREFCNT_inc(retsv);    /* so sv_2mortal won't free it  */
    }
    return sv_2mortal(retsv);
}


/* ================================================================== */

/*
static imp_sth_t *
alloc_imp_sth(imp_dbh)
    imp_dbh_t *imp_dbh;
{
    imp_sth_t *imp_sth;
    Newz(42, imp_sth, sizeof(imp_sth_t), imp_sth_t);
    imp_sth->imp_dbh = imp_dbh;
    imp_sth->dbh_generation = imp_dbh->dbh_generation;
    return imp_sth;
}
static void
free_imp_sth(imp_sth)
    imp_sth_t *imp_sth;
{
    Safefree(imp_sth);
}
*/

int
dbd_st_prepare(sth, statement)
    SV *sth;
    char *statement;
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;

    int i, inside_quote;
    char func[64];

    imp_sth->done_desc = 0;
    imp_sth->cda = &imp_sth->cdabuf;

    /* Parse statement for binds ( also, INSERTS! ) */
    /* Lowercase the statement first */

/*    for ( i = 0 ; i < strlen( statement ) ; i++ ) {
        if ( ( statement[i] == '\'' ) || ( statement[i] == '"' ) )
            if ( inside_quote == 1 ) 
                inside_quote = 0;
            else
                inside_quote = 1;
        if ( isupper( statement[i] ) && ( inside_quote != 1 ) ) 
            statement[i] = tolower( statement[i] );
      }
*/

    sscanf( statement, "%s", func );
    for ( i = 0 ; i < strlen( func ) ; i++ )
        if ( isupper( func[i] ) )
            func[i] = tolower( func[i] );

    if ( strstr( func, "insert" ) != 0 ) {
        if ( dbis->debug >= 2 )
            warn( "INSERT present in statement\n" );
        imp_sth->is_insert = 1;
      }

    if ( strstr( func, "create" ) != 0 ) {
        if ( dbis->debug >= 2 )
            warn( "CREATE present in statement\n" );
        imp_sth->is_create = 1;
      }

    if ( strstr( func, "update" ) != 0 ) {
        if ( dbis->debug >= 2 )
            warn( "UPDATE present in statement\n" );
        imp_sth->is_update = 1;
      }

    if ( strstr( func, "drop" ) != 0 ) {
        if ( dbis->debug >= 2 )
            warn( "DROP present in statement\n" );
        imp_sth->is_drop = 1;
      }

    if ( strstr( func, "delete" ) != 0 ) {
        if ( dbis->debug >= 2 )
            warn( "DELETE present in statement\n" );
        imp_sth->is_delete = 1;
      }

    if ( strstr( func, "systables" ) != 0 ) {
        if ( dbis->debug >= 2 )
            warn( "dumping tables\n" );
        imp_sth->is_delete = 1;
      }
   
    /* Bind values */

    if ( msqlQuery( imp_dbh->lda.svsock, statement ) == -1 ) { 
/*        do_error( dbh, imp_sth->cda, imp_sth->cda->rc, "msqlQuery error" ); */
        do_error( 0, msqlErrMsg );
/*        free_imp_sth( imp_sth ); */
        return 0;
      }
  /* Store the result from the Query */

    if ( imp_sth->is_insert || imp_sth->is_create || imp_sth->is_update || imp_sth->is_drop || imp_sth->is_delete ) {
      imp_sth->cda = NULL;
      DBIc_IMPSET_on(imp_sth);
      return 1;
    }

  imp_sth->cda = msqlStoreResult();
  if ( !imp_sth->cda ) {
      do_error( 0, msqlErrMsg );
      return 0;
    }

  imp_sth->row_num = msqlNumRows( imp_sth->cda );

  if ( dbis->debug >= 2 )
      printf( "%d rows matched\n", imp_sth->row_num );

  /* Get number of fields and space needed for field names      */

  imp_sth->fbh_num = msqlNumFields( imp_sth->cda );
  if ( dbis->debug >= 2 )
      printf( "DBD::mSQL::dbd_db_prepare'imp_sth->fbh_num: %d\n",
              imp_sth->fbh_num );

/*    ++imp_sth->imp_dbh->open_cursors;
    XST_mIV(0, (IV)imp_sth);*/
    DBIc_IMPSET_on(imp_sth);
    return 1;
}

void
dbd_preparse(imp_sth, statement)
     imp_sth_t *imp_sth;
     char *statement;
{
  bool in_literal = FALSE;
  char *src, *start, *dest;
  phs_t phs_tpl;
  SV *phs_sv;
  int idx=0, style=0, laststyle=0;
  
  /* allocate room for copy of statement with spare capacity	*/
  /* for editing ':1' into ':p1' so we can use obndrv.	*/
  imp_sth->statement = (char*)safemalloc(strlen(statement) + 100);
  
  /* initialise phs ready to be cloned per placeholder	*/
  memset(&phs_tpl, sizeof(phs_tpl), 0);
  phs_tpl.ftype = 1;	/* VARCHAR2 */
  
  src  = statement;
  dest = imp_sth->statement;
  while(*src) 
    {
      if (*src == '\'')
	in_literal = ~in_literal;
      if ((*src != ':' && *src != '?') || in_literal) 
	{
	  *dest++ = *src++;
	  continue;
	}
      start = dest;			/* save name inc colon	*/ 
      *dest++ = *src++;
      if (*start == '?') 
	{		/* X/Open standard	*/
	  sprintf(start,":%d", ++idx); /* '?' -> ':1' (etc)	*/
	  dest = start+strlen(start);
	  style = 3;
	} 
      else 
	if (isDIGIT(*src))
	  {	/* ':1'		*/
	    idx = atoi(src);
	    *dest++ = 'p';		/* ':1'->':p1'	*/
	    if (idx > MAX_BIND_VARS || idx <= 0)
	      croak("Placeholder :%d index out of range", idx);
	    while(isDIGIT(*src))
	      *dest++ = *src++;
	    style = 1;
	  } 
	else
	  {			/* ':foo'	*/
	    while(isALNUM(*src))	/* includes '_'	*/
	      *dest++ = *src++;
	    style = 2;
	  }
      *dest = '\0';			/* handy for debugging	*/
      if (laststyle && style != laststyle)
	croak("Can't mix placeholder styles (%d/%d)",style,laststyle);
      laststyle = style;
      if (imp_sth->bind_names == NULL)
	imp_sth->bind_names = newHV();
      phs_tpl.sv = newSV(0);
/*      phs_tpl.rv = newRV(phs_tpl.sv); */
      phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl));
      hv_store(imp_sth->bind_names, start, (STRLEN)(dest-start),
	       phs_sv, 0);
      /* warn("bind_names: '%s'\n", start);	*/
    }
  *dest = '\0';
  if (imp_sth->bind_names)
    {
      if (dbis->debug >= 2)
	fprintf(DBILOGFP, "scanned %d distinct placeholders\n",
		(int)HvKEYS(imp_sth->bind_names));
    }
}
/*
int
dbd_bind_ph(h, imp_sth, ph_name, newvalue)
    SV *h;
    imp_sth_t *imp_sth;
    char *ph_name;
    SV *newvalue;
{
    SV **svp;
    STRLEN value_len;
    void *value_ptr;
    phs_t *phs;

    if (dbis->debug >= 2)
        warn("bind '%s' ==> %s\n", SvPV(newvalue,na), ph_name );

    svp = hv_fetch(imp_sth->bind_names, ph_name, strlen(ph_name), 0);
    if (svp == NULL)
        croak("dbd_bind_ph placeholder '%s' unknown", ph_name);
    phs = (phs_t*)((void*)SvPVX(*svp));
*/
    /* At the moment we always do sv_setsv() and rebind.        */
    /* Later we may optimise this so that more often we can     */
    /* just copy the value & length over and not rebind!        */
/*
    if (SvOK(newvalue)) {
        sv_setsv(phs->sv, newvalue);
        value_ptr = SvPV(phs->sv, value_len);
        phs->indp = 0;
        phs->ftype = (SvCUR(phs->sv) <= 2000) ? 1 : 8;
    } else {
        value_ptr = "";
        value_len = 0;
        phs->indp = -1;
        phs->ftype = 1;
    }

    return 0;
}
*/

int
dbd_describe(h, imp_sth)
     SV *h;
     imp_sth_t *imp_sth;
{
  sb1 *cbuf_ptr;
  int t_cbufl=0;
  sb4 f_cbufl[MAX_COLS];
  int i, field_info_loop;
/*  m_result *result; */
  m_row cur;
  m_field *curField;
  int length;
  FILE *fp = DBILOGFP;
  
  if ( dbis->debug >= 2 )
      warn( "In: DBD::mSQL::dbd_describe()\n" );

  if (imp_sth->done_desc || imp_sth->is_insert )
    return 0;	/* success, already done it */
  imp_sth->done_desc = 1;

  t_cbufl = 0;

  if ( imp_sth->currow >= imp_sth->row_num )
    {
      imp_sth->fbh_num = 0;
      return 0;
    }
  msqlDataSeek( imp_sth->cda, imp_sth->currow );

  field_info_loop = 0;
  while ( ( curField = msqlFetchField( imp_sth->cda ) ) ) 
    {
      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'Fetching Field\n" );      

      f_cbufl[field_info_loop] = sizeof( curField->name );
      switch(curField->type)
	{
	case REAL_TYPE:
	  length = strlen(curField->name);
	  if (length < 12)
	    {
	      length = 12;
	    }
	  break;
	  
	case INT_TYPE:
	  length = strlen(curField->name);
	  if (length < 8)
	    {
	      length = 8;
	    }
	  break;
	  
	case CHAR_TYPE:
	  length = ( strlen(curField->name) < curField->length ? curField->length : strlen( curField->name ) );
	  break;

        case NULL_TYPE:
          length = 0;
          imp_sth->fbh_cbuf = '\0';
          break;

        default:
          length = 0;
          imp_sth->fbh_cbuf = '\0';
          break;
	}
      f_cbufl[field_info_loop] = length;
      t_cbufl += length;
      field_info_loop++;
    }
  msqlFieldSeek(imp_sth->cda,0);

  /* allocate field buffers	*/
  Newz(42, imp_sth->fbh,      imp_sth->fbh_num, imp_fbh_t);
  /* allocate a buffer to hold all the column names */
  Newz(42, imp_sth->fbh_cbuf, t_cbufl + imp_sth->fbh_num, char);
	  
  cbuf_ptr = (sb1*)imp_sth->fbh_cbuf;
	  
  cur = msqlFetchRow( imp_sth->cda );

  /* Foreach row, we need to allocate some space and link the
   * - header record to it */

  for(i = 0 ; i <  imp_sth->fbh_num /* && imp_sth->cda->rc!=10 */ ; ++i ) {
      imp_fbh_t *fbh = &imp_sth->fbh[i];
      fbh->imp_sth = imp_sth;
      fbh->cbuf    = cbuf_ptr;
      fbh->cbufl   = f_cbufl[i];
	      
      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'LinkRow: %d\n", i );

      if ( (sb1*)cur[i] == '\0' ) { 
          if ( dbis->debug >= 2 )
              warn( "Looks like a NULL!\n" ); 
          fbh->cbuf[0] = '\0'; 
          fbh->cbufl = 0;
          fbh->rlen = fbh->cbufl;
        } else {
          fbh->cbuf = (sb1*)cur[i];
          fbh->cbufl = (sb4)strlen( (const char*)fbh->cbuf );
          fbh->rlen = fbh->cbufl;
        } 

      if ( dbis->debug >= 2 )
          warn( "Name: %s\t%i\n", fbh->cbuf, fbh->rlen );

      fbh->cbuf[fbh->cbufl] = '\0'; /* ensure null terminated */ 
      cbuf_ptr += fbh->cbufl + 1;   /* increment name pointer	*/ 
	      
      /* Now define the storage for this field data.		*/
      /* Hack buffer length value */

      fbh->dsize = fbh->cbufl;
	      
      /* Is it a LONG, LONG RAW, LONG VARCHAR or LONG VARRAW?	*/
      /* If so we need to implement oraperl truncation hacks.	*/
      /* This may change in a future release.			*/

      fbh->bufl = fbh->dsize + 1;
	      
      /* for the time being we fetch everything as strings	*/
      /* that will change (IV, NV and binary data etc)	*/
      /* currently we use an sv, later we'll use an array     */

      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'newSV\n" );
      fbh->sv = newSV((STRLEN)fbh->bufl); 

      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'SvUPGRADE\n" );
      (void)SvUPGRADE(fbh->sv, SVt_PV);

      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'SvREADONLY_ON\n" );
      SvREADONLY_on(fbh->sv);

      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'SvPOK_only\n" );
      (void)SvPOK_only(fbh->sv);

      if ( dbis->debug >= 2 )
          warn( "In: DBD::mSQL::dbd_describe'SvPVX\n" );
      fbh->buf = (ub1*)SvPVX(fbh->sv);
   }

  if ( dbis->debug >= 2 ) {
       printf( "Entering imp_sth->fbh test cycle\n" );
       for(i = 0 ; i <  imp_sth->fbh_num /* && imp_sth->cda->rc!=10 */ ; ++i ) {

            imp_fbh_t *fbh = &imp_sth->fbh[i];

            printf( "In: DBD::mSQL::dbd_describe'FBHDump[%d]: %s\t%d\n",
                    i, fbh->cbuf, fbh->rlen );
         }
    }
  if ( dbis->debug )
      printf( "Out: DBD::mSQL::dbd_describe()\n" );
  return 0;
}

SV *
readblob(sth, field, offset, len, destsv)
    SV *sth;
    int field;
    long offset;
    long len;
    SV *destsv;
{
    D_imp_sth(sth);
    ub4 retl;
    SV *bufsv;

    if (destsv) {               /* write to users buffer        */
        bufsv = SvRV(destsv);
        sv_setpvn(bufsv,"",0);  /* ensure it's writable string  */
        SvGROW(bufsv, len+1);   /* SvGROW doesn't do +1 itself  */
    } else {
        bufsv = newSV((STRLEN)len);     /* allocate new buffer  */
    }
/*    if (oflng(imp_sth->cda, (sword)field+1,
        (ub1*)SvPVX(bufsv), len, 24, &retl, offset)) {
        do_error(sth, imp_sth->cda, imp_sth->cda->rc, "oflng error");
        SvCUR_set(bufsv, 0);
        return &sv_undef;
    }
*/
    /* Sadly, even though retl is a ub4, oracle will cap the    */
    /* value of retl at 65535 even if more was returned!        */
    /* This is according to the OCI manual for Oracle 7.0.      */
    /* Once again Oracle causes us grief. How can we tell what  */
    /* length to assign to destsv? We do have a compromise: if  */
    /* retl is exactly 65535 we assume that all data was read.  */
    SvCUR_set(bufsv, (retl == 65535) ? len : retl);
    *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc */

    return sv_2mortal(bufsv);
}

int
dbd_st_finish(sth)
    SV *sth;
{
    D_imp_sth(sth);
    /* Cancel further fetches from this cursor.                 */
    /* We don't close the cursor till DESTROY.                  */
    /* The application may re execute it.                       */
/* LOOK INTO   if (DBIc_ACTIVE(imp_sth) ) {
        do_error( 0, "DBIc_ACTIVE error" );
        return 0;
    } */
    DBIc_ACTIVE_off(imp_sth);
    return 1;
}

void
dbd_st_destroy(sth)
    SV *sth;
{
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    if (DBIc_ACTIVE(imp_dbh) /* && oclose(imp_sth->cda) */ ) {
      }

    /* XXX free contents of imp_sth here */
    DBIc_IMPSET_off(imp_sth);
}

int
dbd_st_STORE(sth, keysv, valuesv)
    SV *sth;
    SV *keysv;
    SV *valuesv;
{
    D_imp_sth(sth);
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    SV *cachesv = NULL;
    int on = SvTRUE(valuesv);

    if (kl==8 && strEQ(key, "ora_long")){
        imp_sth->long_buflen = SvIV(valuesv);

    } else if (kl==9 && strEQ(key, "ora_trunc")){
        imp_sth->long_trunc_ok = on;

    } else {
        return FALSE;
    }
    if (cachesv) /* cache value for later DBI 'quick' fetch? */
        hv_store((HV*)SvRV(sth), key, kl, cachesv, 0);
    return TRUE;
}


SV *
dbd_st_FETCH(sth, keysv)
    SV *sth;
    SV *keysv;
{
    D_imp_sth(sth);
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    int i;
    SV *retsv = NULL;
    /* Default to caching results for DBI dispatch quick_FETCH  */
    int cacheit = TRUE;

    if (!imp_sth->done_desc && dbd_describe(sth, imp_sth)) {
        return Nullsv;  /* dbd_describe called do_error()       */
    }

    i = imp_sth->fbh_num;

    if (kl==11 && strEQ(key, "ora_lengths")){
        AV *av = newAV();
        retsv = newRV((SV*)av);
        while(--i >= 0)
            av_store(av, i, newSViv((IV)imp_sth->fbh[i].dsize));

    } else if (kl==9 && strEQ(key, "ora_types")){
        AV *av = newAV();
        retsv = newRV((SV*)av);
        while(--i >= 0)
            av_store(av, i, newSViv(imp_sth->fbh[i].dbtype));

    } else if (kl==9 && strEQ(key, "NumParams")){
        HV *bn = imp_sth->bind_names;
        retsv = newSViv( (bn) ? HvKEYS(bn) : 0 );

    } else if (kl==4 && strEQ(key, "NAME")){
        AV *av = newAV();
        retsv = newRV((SV*)av);
        while(--i >= 0)
            av_store(av, i, newSVpv((char*)imp_sth->fbh[i].cbuf,0));

    } else {
        return Nullsv;
    }
    if (cacheit) { /* cache for next time (via DBI quick_FETCH) */
        hv_store((HV*)SvRV(sth), key, kl, retsv, 0);
        (void)SvREFCNT_inc(retsv);      /* so sv_2mortal won't free it  */
    }
    return sv_2mortal(retsv);
}


/* --------------------------------------- */

