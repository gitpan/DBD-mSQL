/*
	$Id: mSQL.h,v 1.3 1995/05/25 21:18:56 timbo Rel $
*/

#include <DBIXS.h>		/* installed by the DBI module	*/

#include <msql.h>

/* read in our implementation details */

#include "dbdimp.h"

/* DBI method protos */

void dbd_init _((dbistate_t *dbistate));

int  dbd_db_login _((SV *dbh, char *host, char *dbname));
int  dbd_db_do _((SV *sv, char *statement));
/* int  dbd_db_commit _((SV *dbh));
int  dbd_db_rollback _((SV *dbh)); */
int  dbd_db_disconnect _((SV *dbh));
void dbd_db_destroy _((SV *dbh));
int  dbd_db_STORE _((SV *dbh, SV *keysv, SV *valuesv));
SV  *dbd_db_FETCH _((SV *dbh, SV *keysv));

int  dbd_st_prepare _((SV *sth, char *statement));
int  dbd_st_rows _((SV *sv));
/*int  dbd_bind_ph _((SV *h, SV *param, SV *value, SV *attribs)); */
int  dbd_st_execute _((SV *sv));
AV  *dbd_st_fetch _((SV *sv));
int  dbd_st_finish _((SV *sth));
void dbd_st_destroy _((SV *sth));
/* int  dbd_st_readblob _((SV *sth, int field, long offset, long len,
                        SV *destrv, long destoffset)); */
int  dbd_st_STORE _((SV *dbh, SV *keysv, SV *valuesv));
SV  *dbd_st_FETCH _((SV *dbh, SV *keysv));

/* end of mSQL.h */
