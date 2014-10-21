/*
   $Id: dbdimp.h,v 1.5 1995/06/22 00:37:04 timbo Rel $

   Copyright (c) 1994,1995  Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

/* these are (almost) random values ! */
#define MAX_COLS 99
#define MAX_COL_NAME_LEN 99
#define MAX_BIND_VARS	99

#ifndef HDA_SIZE
#define HDA_SIZE 512
#endif

typedef struct imp_fbh_st imp_fbh_t;

/* Lda_def is defined to just being an int. It holds the socket code return
 * - value.
 *
 * We also find from $ORACLE_HOME/rdbms/demo/ocidfn.h that Cda_Def is the
 * - same as Lda_Def
 */

struct imp_drh_st {
    dbih_drc_t com;         /* MUST be first element in structure   */
};

struct Lda_Def_st {
    int lda;
    int rc;		/* Return code? */
    char *svdb;		/* Database Name */
    char *svhost;	/* Hostname of database */
    int svsock;		/* Socket doo-dah */
  };

typedef struct Lda_Def_st Lda_Def;
/* typedef struct Lda_Def_st Cda_Def; */
typedef struct result_s Cda_Def;

/* We need to define some Oracle typedefs too */

#define eb1 char
#define ub1 unsigned char
#define ub2 unsigned short
#define ub4 unsigned long
#define sb1 signed char
#define sb2 signed short
#define sb4 signed int
#define sword signed int

/* Define dbh implementor data structure */
struct imp_dbh_st {
    dbih_dbc_t com;         /* MUST be first element in structure   */

    Lda_Def lda;
    ub1     hda[HDA_SIZE];
};

/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;         /* MUST be first element in structure   */

    Cda_Def *cda;	/* currently just points to cdabuf below */
    Cda_Def cdabuf;
/*    imp_dbh_t *imp_dbh;
    U32       dbh_generation; 
    U16       flags; */

    /* Current row index? */

    int currow;
    int row_num;

    /* Input Details	*/
    char      *statement;   /* sql (see sth_scan)		*/
    HV        *bind_names;

    int is_insert;
    int is_create;
    int is_update;
    int is_drop;
    int is_delete;

    /* Output Details	*/
    int        done_desc;   /* have we described this sth yet ?	*/
    int        fbh_num;     /* number of output fields		*/
    imp_fbh_t *fbh;	    /* array of imp_fbh_t structs	*/
    char      *fbh_cbuf;    /* memory for all field names       */
    sb4   long_buflen;      /* length for long/longraw (if >0)	*/
    bool  long_trunc_ok;    /* is truncating a long an error	*/
};
#define IMP_STH_EXECUTING	0x0001


struct imp_fbh_st { 	/* field buffer EXPERIMENTAL */
    imp_sth_t *imp_sth;	/* 'parent' statement */

    /* Oracle's description of the field	*/
    sb4  dbsize;
    sb2  dbtype;
    sb1  *cbuf;		/* ptr to name of select-list item */
    sb4  cbufl;		/* length of select-list item name */
    sb4  dsize;		/* max display size if field is a char */
    sb2  prec;
    sb2  scale;
    sb2  nullok;

    /* Our storage space for the field data as it's fetched	*/
    sb2  indp;		/* null/trunc indicator variable	*/
    sword ftype;	/* external datatype we wish to get	*/
    ub1  *buf;		/* data buffer (points to sv data)	*/
    ub2  bufl;		/* length of data buffer		*/
    ub2  rlen;		/* length of returned data		*/
    ub2  rcode;		/* field level error status		*/

    SV	*sv;
};



typedef struct phs_st phs_t;    /* scalar placeholder   */

struct phs_st { /* scalar placeholder EXPERIMENTAL      */
    SV  *sv;            /* the scalar holding the value         */
    sword ftype;        /* external OCI field type              */
    sb2 indp;           /* null indicator                       */
};

extern SV *dbd_errnum;
extern SV *dbd_errstr;

/*void    do_error _((SV *h, Lda_Def *lda, int rc, char *what)); */
void	do_error _((int rc, char *what));
void    fbh_dump _((imp_fbh_t *fbh, int i));

void    dbd_init _((dbistate_t *dbistate));
void    dbd_preparse _((imp_sth_t *imp_sth, char *statement));
int     dbd_describe _((SV *h, imp_sth_t *imp_sth));

/* end */
