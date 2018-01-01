#!/usr/local/bin/perl -w
#------------------------------------------------------------------------------
# Licensed Materials - Property of IBM (C) Copyright IBM Corp. 2010, 2010
# All Rights Reserved US Government Users Restricted Rights - Use, duplication
# or disclosure restricted by GSA ADP Schedule Contract with IBM Corp
#------------------------------------------------------------------------------

#  perl temsaud.pl diagnostic_log
#
#  Create a report on agent row results from
#  kpxrpcrq tracing
#
#  john alvord, IBM Corporation, 22 Jul 2011
#  jalvord@us.ibm.com
#
# tested on Windows Activestate 5.16.3
#
# $DB::single=2;   # remember debug breakpoint

## Todos
## Watch for Override messages
## Take Action command function for high usage
##  (5459ADD0.0000-23:kpxreqi.cpp,126,"InitializeClass") *INFO : Using 20 CTIRA_Recursive_lock objects for class RequestImp
## ...kpxcloc.cpp,1651,"KPX_CreateProxyRequest") Reflex command length <513> is too large, the maximum length is <512>
##  ...kpxcloc.cpp,1653,"KPX_CreateProxyRequest") Try shortening the command field in situation <my_test_situation>

$gVersion = 1.33000;


# CPAN packages used
use Data::Dumper;               # debug only

# This is a typical log scraping program. The log data looks like this
#
# Distributed with a situation:
# (4D81D817.0000-A17:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 220 tbl *.RNODESTS req HEARTBEAT <219213376,1892681576> node <Primary:INMUM01B2JTP01:NT>
#   Interesting failure cases
# (4FF79663.0003-4:kpxrpcrq.cpp,826,"IRA_NCS_Sample") Sample <665885373,2278557540> arrived with no matching request.
# (4FF794A9.0001-28:kpxrpcrq.cpp,802,"IRA_NCS_Sample") RPC socket change detected, initiate reconnect, node thp-gl-04:KUX!
#
# Distributed without situation
# (4D81D81A.0000-A1A:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 816 tbl *.UNIXOS req  <418500981,1490027440> node <evoapcprd:KUX>
#
# z/OS RKLVLOG lines contain the same information but often split into two lines
# and the timestamp is in a different form.
#  2011.080 14:53:59.78 (005E-D61DDF8B:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 220 tbl *.RNODESTS req HEARTBEAT <565183706,5
#  2011.080 14:53:59.79 65183700> node <IRAM:S8CMS1:SYS:STORAGE         >
#
# the data is identical otherwise
#
#  Too Big message
#   (4D75475E.0001-B00:kpxreqds.cpp,1695,"buildThresholdsFilterObject") Filter object too big (39776 + 22968),Table FILEINFO Situation SARM_UX_FileMonitoring2_Warn.
#
#  SOAP IP address
#  (4D9633C2.0010-11:kshdhtp.cpp,363,"getHeaderValue") Header is <ip.ssl:#10.41.100.21:38317>
#
#  SOAP SQL
#  (4D9633C2.0020-11:kshreq.cpp,881,"buildSQL") Using pre-built SQL: SELECT NODE, AFFINITIES, PRODUCT, VERSION, RESERVED, O4ONLINE FROM O4SRV.INODESTS
#  (4D9633C3.0021-11:kshreq.cpp,1307,"buildSQL") Using SQL: SELECT CLCMD,CLCMD2,CREDENTIAL,CWD,KEY,MESSAGE,ACTSECURE,OPTIONS,RESPFILE,RUNASUSER,RUNASPWD,REQSTATUS,ACTPRTY,RESULT,ORIGINNODE FROM O4SRV.CLACTRMT WHERE  SYSTEM.PARMA("NODELIST", "swdc-risk1csc0:KUX", 18) AND  CLCMD =  N"/opt/IBM/custom/ChangeTEMS_1.00.sh PleaseReturnZero"
#
# To manage the differences, a state engine is used.
#  When set to 0 based on absence of -z option, the lines are processed directly
#
#  For RKLVLOG case the state is set to 1 at outset.
#  When 1, the first line is examined. RKLVLOGs can be in two forms. When
#  collected as a SYSOUT file, there is an initial printer control character
#  of "1" or " ", a printer control character. In that case all the lines have
#  a printer control character of blank. If recogonized a variable $offset
#  is set to value o1.
#
#  The second form is when the RKLVLOG is written directly to a disk file.
#  In this case the printer control characters are absent. For that case the
#  variable $offset is set to 0. When getting the data, $offset is used
#  calculations.
#
#  After state 1, state 2 is entered.
#
# When state=2, the input record is checked for the expected form of trace.
# If not, the next record is processed. If found, the partial line
# is captured and the state is set to 3. The timestamp is also captured.
# then the next record is processed.
#
# When state=3, the second part of the data is captured. The data is assembled
# as if it was a distributed record. The timestamp is converted to the
# distributed timestamp. The state is set to 2 and then the record is processed.
# Sometimes we don't know if there is a continuation or not. Thus we usually
# keep the prior record and add to it if the next one is not in correct form.
#
# Processing is typical log scraping. The target is identified, an associative
# array is used to look up prior cases, and the data is recorded. At the end
# the accumulated data is printed to standard output.

# pick up parameters and process
#??? make -z option auto-detect

# following table is used in EBCDIC to ASCII conversion using ccsid 1047 - valid for z/OS
# adapted from CPAN module Convert::EBCDIC;
# the values are recorded in octol notation.
$ccsid1047 =
'\000\001\002\003\234\011\206\177\227\215\216\013\014\015\016\017' .
'\020\021\022\023\235\012\010\207\030\031\222\217\034\035\036\037' .
'\200\201\202\203\204\205\027\033\210\211\212\213\214\005\006\007' .
'\220\221\026\223\224\225\226\004\230\231\232\233\024\025\236\032' .
'\040\240\342\344\340\341\343\345\347\361\242\056\074\050\053\174' .
'\046\351\352\353\350\355\356\357\354\337\041\044\052\051\073\136' .
'\055\057\302\304\300\301\303\305\307\321\246\054\045\137\076\077' .
'\370\311\312\313\310\315\316\317\314\140\072\043\100\047\075\042' .
'\330\141\142\143\144\145\146\147\150\151\253\273\360\375\376\261' .
'\260\152\153\154\155\156\157\160\161\162\252\272\346\270\306\244' .
'\265\176\163\164\165\166\167\170\171\172\241\277\320\133\336\256' .
'\254\243\245\267\251\247\266\274\275\276\335\250\257\135\264\327' .
'\173\101\102\103\104\105\106\107\110\111\255\364\366\362\363\365' .
'\175\112\113\114\115\116\117\120\121\122\271\373\374\371\372\377' .
'\134\367\123\124\125\126\127\130\131\132\262\324\326\322\323\325' .
'\060\061\062\063\064\065\066\067\070\071\263\333\334\331\332\237' ;

my $opt_z;
my $opt_ri;
my $opt_ri_sec;
my $opt_expslot;
my $opt_logpat;
my $opt_logpath;
my $opt_workpath;
my $full_logfn;
my $opt_v;
my $opt_o;
my $opt_nohdr = 0;
my $workdel = "";
my $opt_inplace = 1;
my $opt_work    = 0;
my $opt_nofile = 0;                              # number of file descriptors, zero means not found
my $opt_stack = 0;                               # Stack limit zero means not found
my $opt_sr;                                      # Soap Report
my $opt_cmdall;                                  # show all commands
my $opt_jitall;                                  # show all jitter
my $opt_noded = 0;                               # track inter-arrival times for results

sub gettime;                             # get time

my $hdri = -1;                               # some header lines for report
my @hdr = ();                                #

$hdri++;$hdr[$hdri] = "TEMS Audit report v$gVersion";
my $audit_start_time = gettime();       # formated current time for report
$hdri++;$hdr[$hdri] = "Start: $audit_start_time";

#  following are the nominal values. These are used to generate an advisories section
#  that can guide usage of the Workload report. These can be overridden by the temsaud.ini file.

my $opt_nominal_results   = 500000;          # result bytes per minute
my $opt_nominal_trace     = 1000000;         # trace bytes per minute
my $opt_nominal_workload  = 50;              # When results high, what sits to show
#my $opt_nominal_maxresult = 128000;          # Maximum result size
my $opt_nominal_remotesql = 1200;            # Startup seconds, remote SQL failures during this time may be serious
my $opt_nominal_soap      = 30;              # SOAP results per minute
my $opt_nominal_nmr       = 0;               # No Matching Requests value
my $opt_max_results       = 16*1024*1024 - 8192; # When max results this high, possible truncated results
my $opt_nominal_listen    = 8;               # warn on high listen count
my $opt_nominal_nofile    = 8192;            # warn on low nofile value
my $opt_nominal_stack     = 10240;           # warn on high stack limit value
my $opt_max_listen        = 16;              # maximum listen count allowed by default
my $opt_nominal_soap_burst = 300;            # maximum burst of 300 per minute
my $opt_nominal_agto_mult = 1;               # amount of allowed repeat onlines

my $arg_start = join(" ",@ARGV);
$hdri++;$hdr[$hdri] = "Runtime parameters: $arg_start";

while (@ARGV) {
   if ($ARGV[0] eq "-h") {
      &GiveHelp;                        # print help and exit
   }
   if ($ARGV[0] eq "-z") {
      $opt_z = 1;
      shift(@ARGV);
   } elsif  ($ARGV[0] eq "-ri") {
      $opt_ri = 1;
      shift(@ARGV);
      if (defined $ARGV[0]) {
         if (substr($ARGV[0],0,1) ne "-") {
            if ($ARGV[0] =~ m/^\d+$/) {
               $opt_ri_sec = shift(@ARGV);
            }
         }
      }
   } elsif ($ARGV[0] eq "-b") {
      $opt_b = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-sr") {
      $opt_sr = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-cmdall") {
      $opt_cmdall = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-jitall") {
      $opt_jitall = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-inplace") {
#     $opt_inplace = 1;                # ignore as unused
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-work") {
      $opt_inplace = 0;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-v") {
      $opt_v = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-nohdr") {
      $opt_nohdr = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-expslot") {
      shift(@ARGV);
      $opt_expslot = shift(@ARGV);
   } elsif ($ARGV[0] eq "-logpath") {
      shift(@ARGV);
      $opt_logpath = shift(@ARGV);
      die "logpath specified but no path found\n" if !defined $opt_logpath;
   } elsif ($ARGV[0] eq "-o") {
      shift(@ARGV);
      $opt_o = shift(@ARGV);
      die "-o output specified but no path found\n" if !defined $opt_o;
   } elsif ($ARGV[0] eq "-workpath") {
      shift(@ARGV);
      $opt_workpath = shift(@ARGV);
      $opt_inplace = 0;
      die "workpath specified but no path found\n" if !defined $opt_workpath;
   }
   else {
      $logfn = shift(@ARGV);
      die "log file not defined\n" if !defined $logfn;
   }
}


die "logpath and -z must not be supplied together\n" if defined $opt_z and defined $opt_logpath;

if (!defined $opt_logpath) {$opt_logpath = "";}
if (!defined $logfn) {$logfn = "";}
if (!defined $opt_z) {$opt_z = 0;}
if (!defined $opt_ri) {$opt_ri = 0;}
if (!defined $opt_ri_sec) {$opt_ri_sec = 60;}
if (!defined $opt_b) {$opt_b = 0;}
if (!defined $opt_sr) {$opt_sr = 0;}
if (!defined $opt_cmdall) {$opt_cmdall = 0;}
if (!defined $opt_jitall) {$opt_jitall = 0;}
if (!defined $opt_v) {$opt_v = 0;}
if (!defined $opt_o) {$opt_o = "temsaud.csv";}
if (!defined $opt_expslot) {$opt_expslot = 60;}

$gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

if (!$opt_inplace) {
   if (!defined $opt_workpath) {
      if ($gWin == 1) {
         $opt_workpath = $ENV{TEMP};
         $opt_workpath = "c:\temp" if !defined $opt_workpath;
      } else {
         $opt_workpath = $ENV{TMP};
         $opt_workpath = "/tmp" if !defined $opt_workpath;
      }
   }
   $opt_workpath =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments
   $opt_workpath .= '/';
}

my $pwd;
my $d_res;

# logic below is to normalize the supplied logpath. For example  ../../logs  needs to be resulted to a proper path name.

if ($gWin == 1) {
   $pwd = `cd`;
   chomp($pwd);
   if ($opt_logpath eq "") {
      $opt_logpath = $pwd;
   }
   $opt_logpath = `cd $opt_logpath & cd`;
   chomp($opt_logpath);
   chdir $pwd;
} else {
   $pwd = `pwd`;
   chomp($pwd);
   if ($opt_logpath eq "") {
      $opt_logpath = $pwd;
   } else {
      $opt_logpath = `(cd $opt_logpath && pwd)`;
      chomp($opt_logpath);
   }
   chdir $pwd;
}


$opt_logpath .= '/';
$opt_logpath =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

die "logpath or logfn must be supplied\n" if !defined $logfn and !defined $opt_logpath;

# Establish nominal values for the Advice Summary section

my $opt_ini = "temsaud.ini";

if (-e $opt_ini) {
   open( FILE, "< $opt_ini" ) or die "Cannot open ini file $opt_ini : $!";
   my @ips = <FILE>;
   close FILE;

   # typical ini file scraping.
   my $l = 0;
   foreach my $oneline (@ips)
   {
      $l++;
      chomp($oneline);
      next if (substr($oneline,0,1) eq "#");  # skip comment line
      my @words = split(" ",$oneline);
      next if $#words == -1;                  # skip blank line

      # two word controls - option and value
      if ($words[0] eq "results") {$opt_nominal_results = $words[1];}
      elsif ($words[0] eq "trace") {$opt_nominal_trace = $words[1];}
      elsif ($words[0] eq "workload") {$opt_nominal_workload = $words[1];}
      elsif ($words[0] eq "remotesql") {$opt_nominal_remotesql = $words[1];}
      elsif ($words[0] eq "soap") {$opt_nominal_soap = $words[1];}
      elsif ($words[0] eq "soap_burst") {$opt_nominal_soap_burst = $words[1];}
      elsif ($words[0] eq "nmr") {$opt_nominal_nmr = $words[1];}
      elsif ($words[0] eq "listen") {$opt_nominal_listen = $words[1];}
      elsif ($words[0] eq "nofile") {$opt_nominal_nofile = $words[1];}
      elsif ($words[0] eq "stack") {$opt_nominal_stack = $words[1];}
      elsif ($words[0] eq "maxlisten") {$opt_max_listen = $words[1];}
      elsif ($words[0] eq "agto_mult") {$opt_nominal_agto_mult = $words[1];}
      else {
         die "unknown control in temsaud.ini line $l unknown control $words[0]"
      }
   }
}

my $pattern;
my @results = ();
my $loginv;
my $inline;
my $logbase;
my %todo = ();     # associative array of names and first identified timestamp
my @seg = ();
my @seg_time = ();
my $segi = -1;
my $segp = -1;
my $segcur = "";
my $segline;
my $segmax = "";
my $skipzero = 0;

my %resx;        # hash of result details by minute
my %res_stampx;  # hash of times to result minute stamps

my $advisori = -1;
my @advisor = ();

if ($logfn eq "") {
   $pattern = "_ms(_kdsmain)?\.inv";
   @results = ();
   opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
   @results = grep {/$pattern/} readdir(DIR);
   closedir(DIR);
   die "No _ms.inv found\n" if $#results == -1;
   if ($#results > 0) {         # more than one inv file - complain and exit
      $invlist = join(" ",@results);
      die "multiple invfiles [$invlist] - only one expected\n";
   }
   $logfn =  $results[0];
}


$full_logfn = $opt_logpath . $logfn;
if ($logfn =~ /.*\.inv$/) {
   open(INV, "< $full_logfn") || die("Could not open inv  $full_logfn\n");
   $inline = <INV>;
   die "empty INV file $full_logfn\n" if !defined $inline;
   $inline =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments
   $pos = rindex($inline,'/');
   $inline = substr($inline,$pos+1);
   $inline =~ m/(.*)-\d\d\.log$/;
   $inline =~ m/(.*)-\d\.log$/ if !defined $1;
   die "invalid log form $inline from $full_logfn\n" if !defined $1;
   $logbase = $1;
   $logfn = $1 . '-*.log';
   close(INV);
}


if (!defined $logbase) {
   $logbase = $logfn if ! -e $logfn;
}



die "-expslot [$opt_expslot] is not numeric" if  $opt_expslot !~ /^\d+$/;
die "-expslot [$opt_expslot] is not positive number from 1 to 60" if  ($opt_expslot < 1) or ($opt_expslot > 60);

#??? doubt the next line works
die "-expslot [$opt_expslot] is not an even multiple of 60" if  (int(60/$opt_expslot) * $opt_expslot) != 60;

sub open_kib;
sub read_kib;

my $pos;


open_kib();

$l = 0;

my $locus;                  # (4D81D81A.0000-A1A:kpxrpcrq.cpp,749,"IRA_NCS_Sample")
my $rest;                   # unprocesed data
my $logtime;                # distributed time stamp in seconds - number of seconds since Jan 1, 1970
my $logtimehex;             # distributed time stamp in hex
my $logline;                # line number within $logtimehex
my $logthread;              # thread information - prefixed with "T"
my $logunit;                # where printed from - kpxrpcrq.cpp,749
my $logentry;               # function printed from - IRA_NCS_Sample
my $irows;                  # number of rows
my $isize;                  # size of rows
my $itbl;                   # table name involved
my $isit;                   # Situation name - may be null
my $inode;                  # managed system sending data - unused
my $siti = -1;              # count of situations
my @sit = ();               # situation name
my %sitx = ();              # associative array from situation name to index
my @sitct = ();             # situation results count
my @sitrows = ();           # situation results count of rows
my @sitres = ();            # situation results count of result size
my @sittbl = ();            # situation table
my @sitrmin = ();           # situation results minimum of result size
my @sitrmax = ();           # situation results maximum of result size
my @sitrmaxnode = ();       # situation node giving maximum of result size
my @sitnoded = ();          # array of hashes about each node and arrival times etc
my $sitct_tot = 0;          # total results
my $sitrows_tot = 0;        # total rows
my $sitres_tot = 0;         # total size
my $sitstime = 0;           # smallest time seen - distributed
my $sitetime = 0;           # largest time seen  - distributed
my $trcstime = 0;           # trace smallest time seen - distributed
my $trcetime = 0;           # trace largest time seen  - distributed
my $timestart = "";         # first time seen - z/OS
my $timeend = "";           # last time seen - z/OS
my $sx;                     # index
my $insize;                 # calculated
my $csvdata;
my @words;

my $mani = -1;              # count of managed systems
my @man = ();               # managed system name
my %manx = ();              # associative array from managed system name to index
my @manct = ();             # managed system results count
my @manrows = ();           # managed system results count of rows
my @manres = ();            # managed system results count of result size
my @mantbl = ();            # managed system table
my @manrmin = ();           # managed system results minimum of result size
my @manrmax = ();           # managed system results maximum of result size
my @manrmaxsit = ();        # managed system situation giving maximum of result size
my $mx;                     # index

my $toobigi = -1;           # count of toobig cases
my @toobigsit = ();         # array of toobig situation names
my %toobigsitx = ();        # associative array from  situation to index
my @toobigsize = ();        # size values
my @toobigtbl = ();         # table name
my @toobigct = ();          # Count of too bigs
my $ifiltsize;              # input size
my $ifilttbl;               # input table
my $ifiltsit;               # input situation
my $tx;                     # index

my $syncdist = 0;           # count of sync. dist. error messages
my $syncdist_first_time;    # First noted time in log
my $syncdist_timei = -1;    # count of sync. dist. time counts
my $syncdist_time = ();     # count of sync. dist.

my $soapi = -1;             # count of soap SQLa
my @soap = ();              # indexed array to SOAP SQLs
my %soapx = ();             # associative array to SOAP SQLs
my @soapct;                 # count of soap SQLs
my @soapip;                 # last ip address seen in header
my $soapip_lag = "";        # last ip address spotted
my $soapct_tot;             # total count of SQLs

my $soap_burst_start = 0;   # start of SOAP burst calculation
my $soap_bursti = -1;       # count of SOAP call minutes
my @soap_burst = ();        # SOAP calls in each minute
my $soap_burst_minute;      # current minute from start
my $soap_burst_count;       # current minute count
my $soap_burst_max = 0;     # Maximum SOAP count in a minute
my $soap_burst_max_log = ""; # Maximum SOAP - log segment
my $soap_burst_max_l = 0;   # Maximum SOAP - log segment line
my @soap_burst_time = ();   # time being worked on since first one
my @soap_burst_log = ();    # log being worked on
my @soap_burst_l = ();      # log line being worked on
my $soap_burst_next;        # time for begining of next SOAP call minute

my $pti = -1;               # count of process table records
my @pt  = ();               # pt keys - table_path
my %ptx = ();               # associative array from from pt key to index
my @pt_table = ();          # pt table
my @pt_path = ();           # pt path
my @pt_insert_ct = ();      # Count of insert
my @pt_query_ct = ();       # Count of query
my @pt_select_ct = ();      # Count of select
my @pt_selectpre_ct = ();   # Count of select prefiltered
my @pt_delete_ct = ();      # Count of delete
my @pt_total_ct = ();       # Total Count
my @pt_error_ct = ();       # error count
my @pt_errors   = ();       # string of different error status types
my $pt_etime = 0;
my $pt_stime = 0;
my $pt_dur   = 0;
my $ipt_status = "";
my $ipt_rows = "";
my $ipt_table = "";
my $ipt_type = "";
my $ipt_path  = "";
my $ipt_key = "";
my $ix;
my $pt_total_total = 0;

my $nmr_total = 0;          # no matching request count
my $fsync_enabled = 1;      # assume fsync is enabled

my $lp_high = -1;
my $lp_balance = -1;
my $lp_threads = -1;
my $lp_pipes   = -1;

# Summarized action command captures
my $acti = -1;                               # Action command count
my @act = ();                                # array of action commands - down to first blank
my %actx = ();                               # index from action command
my @act_elapsed = ();                        # total elapsed time of action commands
my @act_ok = ();                             # count when exit status was zero
my @act_err = ();                            # count when exit status was non-zero
my @act_ct = ();                             # count of total action commands
my @act_act = ();                            # array of action commands
my $act_id = -1;                             # sequence id for action commands
my $act_max = 0;                             # max number of simultaneous action commands
my @act_max_cmds = ();                       # array of max simultaneous action commands
my %act_current_cmds = ();                   # hash of current simultaneous action commands

my $act_start = 0;
my $act_end = 0;

# running action command captures.
# used during capture of data
my %runx = ();                               # index of running capture threads using Tthread
my %contx = ();                              # index from cont to same array using hextime.line
my $contkey;

# following are in the $runx value, which is actually an array
my $runref;                                  # reference to array
my $run_thread;                              # needed for cross references

my $sqli = -1;                               # number of SQLs spotted
my @sql = ();                                # Array of SQLs
my %sqlx = ();                               # SQL to index has
my @sql_ct = ();                             # count of SQLs

my $sql_start = 0;
my $sql_end = 0;

my $sqltabi = -1;                            # number of SQL tables spotted
my @sqltab = ();                             # Array of SQL tables
my %sqltabx = ();                            # SQL table to index has
my @sqltab_ct = ();                          # count of SQL table usages
my $sql_state = 0;                           # state of SQL capture
my $sql_cap = "";                            # collection of SQL fragments

my $px;
my $pevti = -1;                              # ProcessEvent count
my @pevt  = ();
my %pevtx = ();
my @pevt_ct = ();

my $pe_etime = 0;
my $pe_stime = 0;


my $agtoi = -1;                              # Agent online records
my @agto = ();                               # array of agent onlines
my %agtox = ();                              # index to agent onlines
my @agto_ct = ();                            # count of agent onlines
my @agto_hr = ();                            # rate of agent onlines per hour
my $agto_mult = 0;                           # number of multiple onlines
my $agto_mult_hr = 0;                        # number of multiple onlines with rate/hr >= 1;
my $agto_etime = 0;                          # time of first agent online
my $agto_stime = 0;                          # time of last agent online

my $agtshi = -1;                             # Agent Simple Heartbeat records
my @agtsh = ();                              # array of agent S-Hs
my %agtshx;                                  # index to agent S-Hs
my @agtsh_ct = ();                           # count of agent S-Hs
my @agtsh_hr = ();                           # rate of agent S-Hs per hour
my @agtsh_rat = ();                          # recent arrival time
my @agtsh_iat = ();                          # inter arrival time - actually anonymous hash
my $agtsh_total_ct = 0;                       # number of multiple S-Hs with rate/hr >= 6;
my $agtsh_etime = 0;                         # time of first agent S-H
my $agtsh_stime = 0;                         # time of last agent S-H

my %timex = ();                   # Hash of Hashes for timeout cases


my $inrowsize;
my $inobject;
my $intable;
my $inappl;
my $inrows;
my $inreadct;
my $inskipct;
my $inwritect;

my %table_rowsize = ();

my $histcnt = 0;
my $total_histrows = 0;
my $total_histsecs = 0;


my $hist_sec;
my $hist_min;
my $hist_hour;
my $hist_day;
my $hist_month;
my $hist_year;

my $hist_min_time = 0;
my $hist_max_time = 0;
my $hist_elapsed_time = 0;

my %histobjx = ();
my $inmetatable;
my $inmetaobject;

my $histi = -1;             # historical data export total, key by object name
my $hx;
my @hist = ();                  # object name - attribute group
my %histx = ();                 # index to object name
my @hist_table = ();            # table name
my @hist_appl = ();             # application name
my @hist_rows = ();             # number of rows
my @hist_rowsize = ();          # size of row
my @hist_bytes = ();            # total size of rows
my @hist_maxrows = ();          # maximum rows at end of cycle
my @hist_minrows = ();          # minimum rows at end of cycle
my @hist_totrows = ();          # Total rows at end of cycle
my @hist_lastrows = ();         # last rows at end of cycle
my @hist_cycles = ();           # total number of export cyclces

my $histtimei = -1;             # historical data export hourly, yymmddhh
my @histtime = ();              # key yymmddhh
my %histtimex = ();             # index to yymmddhh
my @histtime_rows = ();         # number of rows
my @histtime_bytes = ();        # total size of rows
my @histtime_min_time = ();     # minimum epcoh time
my @histtime_max_time = ();     # maximum epcoh time

my $histobjecti = -1;           # historical data export hourly, object_yymmddhh
my @histobject = ();            # key object_yymmddhh
my %histobjectx = ();           # index to object_yymmddhh
my @histobject_object = ();     # object name
my @histobject_time = ();       # time
my @histobject_table = ();      # table name
my @histobject_appl = ();       # application name
my @histobject_rows = ();       # number of rows
my @histobject_rowsize = ();    # size of rows
my @histobject_bytes = ();      # total size of rows

my $trace_ct = 0;               # count of trace lines
my $trace_sz = 0;               # total size of trace lines


my $state = 0;       # 0=look for offset, 1=look for zos initial record, 2=look for zos continuation, 3=distributed log
my $partline = "";          # partial line for z/OS RKLVLOG
my $dateline = "";          # date portion of timestamp
my $timeline = "";          # time portion of timestamp
my $offset = 0;             # track sysout print versus disk flavor of RKLVLOG
my $totsecs = 0;            # added to when time boundary crossed
my $outl;


my %epoch = ();             # convert year/day of year to Unix epoch seconds
my $yyddd;
my $yy;
my $ddd;
my $days;
my $saveline;
my $oplogid;

my $lagline;
my $lagtime;
my $laglocus;

if ($opt_z == 1) {$state = 1}

$inrowsize = 0;

for(;;)
{
   read_kib();
   if (!defined $inline) {
      last;
   }
   $l++;
#print STDERR "Working on $l\n";
# following two lines are used to debug errors. First you flood the
# output with the working on log lines, while merging stdout and stderr
# with  1>xxx 2>&1. From that you determine what the line number was
# before the faulting processing. Next you turn that off and set the conditional
# test for debugging and test away.
# print STDERR "working on log $segcurr at $l\n";

   chomp($inline);
#$DB::single=2 if $l >= 30775;
   if ($opt_z == 1) {
      if (length($inline) > 132) {
         $inline = substr($inline,0,132);
      }
      next if length($inline) <= 21;
   }
   if (($segmax == 0) or ($segp > 0)) {
      if ($skipzero == 0) {
         $trace_ct += 1;
         $trace_sz += length($inline);
      }
   }
   if ($state == 0) {                       # state = 0 distributed log - no filtering - following is pure z logic
      $oneline = $inline;
   }
   elsif ($state == 1) {                       # state 1 - detect print or disk version of sysout file
      $offset = (substr($inline,0,1) eq "1") || (substr($inline,0,1) eq " ");
      $state = 2;
      $lagline = "";
      $lagtime = 0;
      $laglocus = "";
      next;
   }
   elsif ($state == 2) {                    # state 2 = look for part one of target lines
      next if length($inline) < 36;
      next if substr($inline,21+$offset,1) ne '(';
      next if substr($inline,26+$offset,1) ne '-';
      next if substr($inline,35+$offset,1) ne ':';
      next if substr($inline,0+$offset,2) != '20';

      # convert the yyyy.ddd hh:mm:ss:hh stamp into the epoch seconds form.
      # The goal is to allow a common logic for z/OS and distributed logs.

      # for year/month/day calculation is this:
      #   if ($mo > 2) { $mo++ } else {$mo +=13;$yy--;}
      #   $day=($yy*365)+int($yy/4)-int($yy/100)+int($yy/400)+int($mo*306001/10000)+$dd;
      #   $days_since_epoch=$day-719591; # (which is Jan 1 1970)
      #
      # In this case we need the epoch days for begining of Jan 1 of current year and then add day of year
      # Use an associative array part so the day calculation only happens once a day.
      # The result is normalized to UTC 0 time [like GMT] but is fine for duration calculations.

      $yyddd = substr($inline,0+$offset,8);
      $timeline = substr($inline,9+$offset,11);
      if (!defined $epoch{$yyddd}){
         $yy = substr($yyddd,0,4);
         $ddd = substr($yyddd,5,3);
         $yy--;
         $days=($yy*365)+int($yy/4)-int($yy/100)+int($yy/400)+int(14*306001/10000)+$ddd;
         $epoch{$yyddd} = $days-719591;
      }
      $lagtime = $epoch{$yyddd}*86400 + substr($timeline,0,2)*3600 + substr($timeline,3,2)*60 + substr($timeline,6,2);
      $lagline = substr($inline,21+$offset);
      $lagline =~ /^\((.*?)\)/;
      $laglocus = "(" . $1 . ")";
      $state = 3;
      next;
   }

   # continuation is without a locus
   elsif ($state == 3) {                    # state 3 = potentially collect second part of line
      # case 1 - look for the + sign which means a second line of trace output
      #   emit data and resume looking for more
      if (substr($inline,21+$offset,1) eq "+") {
         next if $lagline eq "";
         $oneline = $lagline;
         $logtime = $lagtime;
         $lagline = $inline;
         $lagtime = $lagtime;
         $laglocus = "";
         $state = 3;
         # fall through and process $oneline
      }
      # case 2 - line too short for a locus
      #          Append data to lagline and move on
      elsif (length($inline) < 35 + $offset) {
         $lagline .= " " . substr($inline,21+$offset);
         $state = 3;
         next;
      }

      # case 3 - line has an apparent locus, emit laggine line
      #          and continue looking for data to append to this new line
      elsif ((substr($inline,21+$offset,1) eq '(') &&
             (substr($inline,26+$offset,1) eq '-') &&
             (substr($inline,35+$offset,1) eq ':') &&
             (substr($inline,0+$offset,2) eq '20')) {
         $oneline = $lagline;
         $logtime = $lagtime;
         $yyddd = substr($inline,0+$offset,8);
         $timeline = substr($inline,9+$offset,11);
         if (!defined $epoch{$yyddd}){
            $yy = substr($yyddd,0,4);
            $ddd = substr($yyddd,5,3);
            $yy--;
            $days=($yy*365)+int($yy/4)-int($yy/100)+int($yy/400)+int(14*306001/10000)+$ddd;
           $epoch{$yyddd} = $days-719591;

         }
         $lagtime = $epoch{$yyddd}*86400 + substr($timeline,0,2)*3600 + substr($timeline,3,2)*60 + substr($timeline,6,2);
         $lagline = substr($inline,21+$offset);
         $lagline =~ /^\((.*?)\)/;
         $laglocus = "(" . $1 . ")";
         $state = 3;
         # fall through and process $oneline
      }

      # case 4 - Identify and ignore lines which appear to be z/OS operations log entries
      else {

         $oplogid = substr($inline,21+$offset,7);
         $oplogid =~ s/\s+$//;
         if (index($oplogid," ") == -1) {
             if((substr($oplogid,0,1) eq "K") ||
                (substr($oplogid,0,1) eq "O")) {
                next;
             }
         }
         next if substr($oplogid,0,3) eq "OM2";
         $lagline .= substr($inline,21+$offset);
         $state = 3;
         next;
      }
   }
   else {                   # should never happen
      print STDERR $oneline . "\n";
      die "Unknown state [$state] working on log $logfn at $l\n";
      next;
   }
      # Extract the Number of File Descriptors - a Linux/Unix concern.
      # We documented a recommended setting of 8192 for a TEMS
      #+527A9859.0000      Fsize Limit: None                      Nofile Limit: 1024
      #+527A9859.0000 ==========
   if ($opt_nofile == 0) {
      if (substr($oneline,0,1) eq "+") {
          $opt_nofile = -1 if substr($oneline,14,11) eq " ==========";
          if ($opt_nofile == 0) {
             my $pi = index($oneline,"Nofile Limit: None");
             if ($pi != -1) {
                $opt_nofile = 65536;
             } else {
                $pi = index($oneline,"Nofile Limit:");
                if ($pi != -1) {
                   ($opt_nofile) = substr($oneline,$pi+13) =~ /(\d+)/;
                }
             }
         }
      }
   }
      # Extract the Stack Limit - a Linux/Unix concern.
      # We recommend a maximum of 10 megabytes for a TEMS
      #+52BE1DCC.0000     Nofile Limit: None                       Stack Limit: 32M
      #+527A9859.0000 ==========
   if ($opt_stack == 0) {
      if (substr($oneline,0,1) eq "+") {
          $opt_stack = -1 if substr($oneline,14,11) eq " ==========";
          if ($opt_stack == 0) {
             my $pi = index($oneline,"Stack Limit: None");
             if ($pi != -1) {
                $opt_stack = 4*1024*1024;
             } else {
                $pi = index($oneline,"Stack Limit:");
                if ($pi != -1) {
                   my $in_stack;
                   ($in_stack) = substr($oneline,$pi+12) =~ /(\w+)/;
                   my $stack_last_char = substr($in_stack,-1,1);
                   my $stack_number = substr($in_stack,0,length($in_stack)-1);
                   $stack_number *= 1024 if $stack_last_char eq 'M';
                   $opt_stack = $stack_number;
                }
             }
         }
      }
   }
   # (53FE31BA.0045-61C:kglhc1c.c,601,"KGLHC1_Command") <0x190B4CFB,0x8A> Command String
   # +53FE31BA.0045     00000000   443A5C73 63726970  745C756E 69782031   D:\script\unix.1
   # +53FE31BA.0045     00000010   31343038 32373134  31353038 30303020   140827141508000.
   #  2016.053 09:04:51.66 +0006     00000000   85838896 407DA388  89A24089 A2408140   echo.'this.is.a.
   #  2016.053 09:04:51.66 +0006     00000010   A385A2A3 40869699  40979499 7D         test.for.pmr'
   if (substr($oneline,0,1) eq "+")  {        # convert hex string - ascii - to printable
      $contkey = substr($oneline,1,13);
      $runref = $contx{$contkey};
      if (defined $runref) {
         if ($runref->{'state'} == 3) {
            my $cmd_frag = substr($oneline,30,36);
            $cmd_frag =~ s/\ //g;
            $cmd_frag =~ s/(([0-9a-f][0-9a-f])+)/pack('H*', $1)/ie;
            $runref->{'cmd'} .= $cmd_frag;
         }
      }
   } elsif ( $opt_z == 1) {
      if (substr($oneline,21+$offset,1) eq "+") {    # convert hex string - ebcdic - to printable
         $contkey = $logtimehex . "." . "0";
         $runref = $contx{$contkey};
         if (defined $runref) {
            if ($runref->{'state'} == 3) {
               my $cmd_frag = substr($oneline,43,36);
               $cmd_frag =~ s/\ //g;
               $cmd_frag =~ s/(([0-9a-f][0-9a-f])+)/pack('H*', $1)/ie;
               eval '$cmd_frag =~ tr/\000-\377/' . $ccsid1047 . '/';
               $runref->{'cmd'} .= $cmd_frag;
            }
         }
      }
   }
   if (substr($oneline,0,1) ne "(") {next;}
   $oneline =~ /^(\S+).*$/;          # extract locus part of line
   $locus = $1;
   if ($opt_z == 0) {                # distributed has five pieces
      $locus =~ /\((.*)\.(.*)-(.*):(.*)\,\"(.*)\"\)/;
      next if index($1,"(") != -1;   # ignore weird case with embedded (
      $logtime = hex($1);            # decimal epoch
      $logtimehex = $1;              # hex epoch
      $logline = $2;                 # line number following hex epoch, meaningful with there are + extended lines
      $logthread = "T" . $3;         # Thread key
      $logunit = $4;                 # source unit and line number
      $logentry = $5;                # function name
   }
   else {                            # z/OS has three pieces
      $locus =~ /\((.*):(.*)\,\"(.*)\"\)/;
      $logline = 0;      ##???
      $logthread = "T" . substr($1,5);
      $logtimehex = sprintf("%X",$logtime);
      $logunit = $2;
      $logentry = $3;
   }
   if ($skipzero == 0) {
      if (($segmax <= 1) or ($segp > 0)) {
         if ($trcstime == 0) {
            $trcstime = $logtime;
            $trcetime = $logtime;
         }
         if ($logtime < $trcstime) {
            $trcstime = $logtime;
         }
         if ($logtime > $trcetime) {
            $trcetime = $logtime;
         }
      }
   }
   # looking for a continuaion of sql line
   if ($sql_state == 1) {
      my $sql_frag_line = 1;
      if (substr($logunit,0,10) ne "kdssqprs.c") {
         $sql_frag_line = 0;
         $sql_state = 0;
      } elsif ($logentry ne "PRS_ParseSql") {
         $sql_frag_line = 0;
         $sql_state = 0;
      } else {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,19) eq "SQL to be parsed is") {
            $sql_frag_line = 0;
            $sql_state = 0;
         }
      }
      #(540CE6F4.0047-C:kdssqprs.c,658,"PRS_ParseSql") SELECT TRANSID,GBLTMSTMP,TARGETMSN,CMSNAME,RESERVED2,RETVAL,RETMSGPARM,G
      if ($sql_frag_line == 1) {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         $sql_frag .= substr($rest,1,73);
         next;
      }
      # at this point we have a completed SQL to process
      $sql_frag =~ s/\s+$//;                    # strip trailing blanks
      $sx = $sqlx{$sql_frag};
      if (!defined $sx) {
         $sqli += 1;
         $sx = $sqli;
         $sql[$sx] = $sql_frag;
         $sqlx{$sql_frag} = $sx;
         $sql_ct[$sx] = 0;
      }
      $sql_ct[$sx] += 1;
      $sql_state = 0;
   }
   $syncdist_first_time = $logtime if !defined $syncdist_first_time;
   if (substr($logunit,0,12) eq "kpxreqds.cpp") {
      if ($logentry eq "buildThresholdsFilterObject") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Filter object too big (39776 + 22968),Table FILEINFO Situation SARM_UX_FileMonitoring2_Warn.
                                           # Filter object too big (47840 + 10888),Table KLZCPU Situation .
         next if substr($rest,1,21) ne "Filter object too big";
         $rest =~ /\((.*)\)\,Table (.*) Situation (.*)\./;
         $ifiltsize = $1;
         $ifilttbl = $2;
         $ifiltsit = $3;
         if ($ifiltsit eq "") {
            $ifiltsit = $ifilttbl . "-nosituation";
         }
         my $n2 = $toobigsitx{$ifiltsit};
         if (defined $n2) {
            $toobigct[$n2] += 1;
            next;
         }
         $toobigi++;
         $tx = $toobigi;
         $toobigsit[$tx] = $ifiltsit;
         $toobigsitx{$ifiltsit} = $tx;
         $toobigsize[$tx] = $ifiltsize;
         $toobigtbl[$tx] = $ifilttbl;
         $toobigct[$tx] = 1;
      }
      # (54E64441.0000-12:kpxreqds.cpp,2832,"timeout") Timeout for wlp_chstart_gmqc_std <26221448> *.QMCHANS.
      # (54E7D64D.0000-12:kpxreqds.cpp,2832,"timeout") Timeout for  <1389379034> *.KINAGT.
      if ($logentry eq "timeout") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Timeout for wlp_chstart_gmqc_std <26221448> *.QMCHANS.
                                           # Timeout for  <1389379034> *.KINAGT.
         next if substr($rest,1,11) ne "Timeout for";
         my $isitname = "";
         my $itable = "";
         if (substr($rest,14,1) eq "<") {
            $rest =~ /\*\.(\S+)\./;
            $itable = $1;
         } else {
            $rest =~ / Timeout for (\S+) .*\*\.(\S+)\./;
            $isitname = $1;
            $itable = $2;
         }
         $isitname = "*realtime" if $isitname eq "";
         my $time_table_ref = $timex{$itable};
         if (!defined $time_table_ref) {
            my %table_tableref = ( count => 0,);
            $timex{$itable} = \%table_tableref;
            $time_table_ref  = \%table_tableref;
         }
         $time_table_ref->{count} += 1;
         my $time_sit_ref = $timex{$itable}->{sit};
         if (!defined $time_sit_ref) {
            my %time_sitref   = ();
            $time_sit_ref = \%time_sitref;
            $timex{$itable}->{sit} = \%time_sitref;
         }
         my $sit_ref = $timex{$itable}->{sit}{$isitname};
         if (!defined $sit_ref) {
            my %sitref = (count => 0);
            $timex{$itable}->{sit}{$isitname} = \%sitref;
            $sit_ref = \%sitref;
         }
         $sit_ref->{count} += 1;
      }
      next;
   }
   if (substr($logunit,0,9) eq "kdsrqc1.c") {
      if ($logentry eq "AccessRowsets") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Sync. Dist. request A9E5958 Timeout Status ( 155 ) ntype 1 ...
         next if substr($rest,1,11) ne "Sync. Dist.";
         $syncdist += 1;
         $syncdist_timei += 1;
         $syncdist_time[$syncdist_timei] = $logtime - $syncdist_first_time;
      }
      next;
   }
   if (substr($logunit,0,9) eq "kdebpli.c") {
      if ($logentry eq "KDEBP_Listen") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #     listen 16: PLE=11CE1F2B0, hMon=01900C3B, bal=152, thr=2432, pipes=2026
                                           # 6.3 listenCount 1: PLE=5C4E710, hMon=CE100369, bal=2, thr=2, pipes=0

         next if substr($rest,1,6) ne "listen";
         $rest =~ /(\d+):.*?=\s*(\d+).*?=\s*(\d+).*?=(\d+).*/;
         $lp_high = $1;
         $lp_balance = $2;
         $lp_threads = $3;
         $lp_pipes   = $4;
      }
      next;
   }
   next if $skipzero;


   # (54EA2C3A.0002-AD:kpxreqhb.cpp,924,"HeartbeatInserter") Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.
   if (substr($logunit,0,12) eq "kpxreqhb.cpp") {
      if ($logentry eq "HeartbeatInserter") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.
         next if substr($rest,1,11) ne "Remote node";
         next if substr($rest,-8,8) ne "ON-LINE.";
         $rest =~ /.*\<(\S+)\>/;
         $iagent = $1;
         my $ax = $agtox{$iagent};
         if (!defined $ax) {
            $agtoi += 1;
            $ax = $agtoi;
            $agto[$ax] = $iagent;
            $agtox{$iagent} = $ax;
            $agto_ct[$ax] = 0;
         }
         $agto_ct[$ax] += 1;
         $agto_mult += 1 if $agto_ct[$ax] == 2;
         if ($agto_stime == 0) {
             $agto_stime = $logtime;
             $agto_etime = $logtime;
         }
         if ($logtime < $agto_stime) {
            $agto_stime = $logtime;
         }
         if ($logtime > $agto_etime) {
            $agto_etime = $logtime;
         }
      }
      next;
   }

   # (5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
   if (substr($logunit,0,10) eq "kfaprpst.c") {
      if ($logentry eq "HandleSimpleHeartbeat") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.
         if (substr($rest,1,26) eq "Simple heartbeat from node") {
            $rest =~ /.*?\<(.*?)\>/;
            $iagent = $1;
            $iagent =~ s/\s+$//;                    # strip trailing blanks
            my $ax = $agtshx{$iagent};
            if (!defined $ax) {
               $agtshi += 1;
               $ax = $agtshi;
               $agtsh[$ax] = $iagent;
               $agtshx{$iagent} = $ax;
               $agtsh_ct[$ax] = 0;
               $agtsh_rat[$ax] = 0;
               $agtsh_iat[$ax] = ();
            }
            $agtsh_ct[$ax] += 1;
            $agtsh_total_ct += 1;
            if ($agtsh_rat[$ax] != 0) {
               my $inter_time = $logtime - $agtsh_rat[$ax];
               if ($inter_time < 7200) {
                  my $inter_ref = $agtsh_iat[$ax]{$inter_time};
                  if (!defined $agtsh_iat[$ax]{$inter_time}) {
                     $agtsh_iat[$ax]{$inter_time}{count} = 0;
                     $agtsh_iat[$ax]{$inter_time}{times} = ();
                  }
                  $agtsh_iat[$ax]{$inter_time}{count} += 1;
                  push (@{$agtsh_iat[$ax]{$inter_time}{times}},$logtime);
               }
            }
            $agtsh_rat[$ax] = $logtime;
            if ($agtsh_stime == 0) {
                $agtsh_stime = $logtime;
                $agtsh_etime = $logtime;
            }
            if ($logtime < $agtsh_stime) {
               $agtsh_stime = $logtime;
            }
            if ($logtime > $agtsh_etime) {
               $agtsh_etime = $logtime;
            }
         }
      }
      next;
   }



   # first are two node status update type
   # (54DE6F7F.0008-15:kfastpst.c,902,"KFA_PostEvent") First status queue record <11FF82E54> for viewArea node <NULL> while processing event record      <1150213164119001PCXTA42:VA10PWPAPP036:MQ            YMQ07.00.03 9                V00040000000000000000000000000000200000qwaa7 REMOTE_va10p10023                 Windows~6.1-SP1                 ip.spipe:#30.128.132.150[16832]<NM>VA10PWPAPP036</NM>                                                                                                                                                                                                           A=00:WINNT;C=06.21.00.02:WINNT;G=06.21.00.02:WINNT;             >
   # (54DE6F7F.000E-15:kfastpst.c,868,"KFA_PostEvent") Additional status queue record <11FFC02F4> for viewArea node <NULL> while processing event record <1150213164119001PCXTA42:VA10PWPAPP036:MQ            YMQ07.00.03 9                V00040000000000000000000000000000200000qwaa7 REMOTE_va10p10023                 Windows~6.1-SP1                 ip.spipe:#30.128.132.150[16832]<NM>VA10PWPAPP036</NM>                                                                                                                                                                                                           A=00:WINNT;C=06.21.00.02:WINNT;G=06.21.00.02:WINNT;             >
   # a situation status - pure event
   # (54DE705E.001A-55:kfastpst.c,868,"KFA_PostEvent") Additional status queue record <12331C7D4> for viewArea node <NULL> while processing event record <1150213164502000REMOTE_va10p10023               wlp_rfmonitor_2ntw_rfax         RFMonitor:VA10PWPRFS002A:LO     RightFax_Warning, Line=(9 file of type *.job over 10 Minutes Old Found in Dir \\vapwprfnbes01\OutputPath\QCCMEDC\ on Server VA101150213164502999Y>
   # a situation status - sampled situation
   # (54DE6EEE.0005-62:kfastpst.c,868,"KFA_PostEvent") Additional status queue record <12341B7D4> for viewArea node <NULL> while processing event record <1150213163854000REMOTE_us98ram02umi1xn          wlp_logstw_xorw_std             capturep:va10puvorc007:ORA                                                                                                                                      1150213163853999Y>

   if (substr($logunit,0,10) eq "kfastpst.c") {
      if ($logentry eq "KFA_PostEvent") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Header is <ip.ssl:#10.41.100.21:38317>
         my $pi = index($rest,"status queue record");
         if ($pi != -1) {
            $rest = substr($rest,$pi+20);
            $pi = index($rest,"while processing event record");
            if ($pi != -1) {
               $rest =~ /.*(\<.*)/;
               $rest = $1;
               # <1150213164119001PCXTA42:VA10PWPAPP036:MQ            YMQ07.00.03 9                V00040000000000000000000000000000200000qwaa7 REMOTE_va10p10023                 Windows~6.1-SP1                 ip.spipe:#30.128.132.150[16832]<NM>VA10PWPAPP036</NM>                                                                                                                                                                                                           A=00:WINNT;C=06.21.00.02:WINNT;G=06.21.00.02:WINNT;             >
               # <1150213164502000REMOTE_va10p10023               wlp_rfmonitor_2ntw_rfax         RFMonitor:VA10PWPRFS002A:LO     RightFax_Warning, Line=(9 file of type *.job over 10 Minutes Old Found in Dir \\vapwprfnbes01\OutputPath\QCCMEDC\ on Server VA101150213164502999Y>
               if (substr($rest,241,1) eq "1") {                  # ignore node status updates for the moment
                  my $itime1 = substr($rest,1,16);
                  my $ithrunode = substr($rest,17,32);
                  $ithrunode =~ s/\s+$//;   #trim trailing whitespace
                  my $isitname = substr($rest,49,32);
                  $isitname =~ s/\s+$//;   #trim trailing whitespace
                  my $inode = substr($rest,81,32);
                  $inode =~ s/\s+$//;   #trim trailing whitespace
                  my $iatom = substr($rest,113,128);
                  $iatom =~ s/\s+$//;   #trim trailing whitespace
                  my $iunknown = substr($rest,239,2);
                  my $itime2 = substr($rest,241,16);
                  my $istatus = substr($rest,257,1);
                  my $key = $inode . "|" . $isitname;
                  my $evt_ref = $pevtx{$key};
                  if (!defined $evt_ref) {
                     my %evtref = (
                                     sitname => $isitname,
                                     node => $inode,
                                     count => 0,
                                  );
                     $pevtx{$key} = \%evtref;
                     $evt_ref      = \%evtref;
                  }
                  $evt_ref->{count} += 1;
                  $evt_ref->{atoms}->{$iatom} = 1 if $iatom ne "";
                  $evt_ref->{thrunode}->{$ithrunode} = 1;
                  if ($pe_stime == 0) {
                      $pe_stime = $logtime;
                      $pe_etime = $logtime;
                  }
                  if ($logtime < $pe_stime) {
                     $pe_stime = $logtime;
                  }
                  if ($logtime > $pe_etime) {
                        $pe_etime = $logtime;
                  }
               }
            }
         }
      }
      next;
   }



   if (substr($logunit,0,11) eq "kshdhtp.cpp") {
      if ($logentry eq "getHeaderValue") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Header is <ip.ssl:#10.41.100.21:38317>
         next if substr($rest,1,13) ne "Header is <ip";
         $rest =~ /<(.*?)>/;
         $soapip_lag = $1;
      }
      next;
   }
   if (substr($logunit,0,10) eq "kshreq.cpp") {
      if ($logentry eq "buildSQL") {
         $histcnt++;
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Using pre-built SQL: SELECT NODE, AFFINITIES, PRODUCT, VERSION, RESERVED, O4ONLINE FROM O4SRV.INODESTS
                                           # Using SQL: SELECT CLCMD,CLCMD2,CREDENTIAL,CWD,KEY,MESSAGE,ACTSECURE,OPTIONS,RESPFILE
         next if ((substr($rest,1,20) ne "Using pre-built SQL:" ) && (substr($rest,1,10) ne "Using SQL:" ));
         $rest =~ /: (.*)$/;
         $isql = $1;
         $sx = $soapx{$isql};
         if (!defined $sx) {
            $soapi++;
            $soap[$soapi] = $isql;
            $soapx{$isql} = $soapi;
            $sx = $soapi;
         }
         $soapct[$sx] += 1;
         $soapct_tot += 1;
         $soapip[$sx] = $soapip_lag;
         if ($soap_burst_start == 0) {   # first time recording burst
             $soap_burst_start = $logtime;
             $soap_burst_next = $soap_burst_start + 60; # start of next at 60 seconds
             $soap_burst_minute = 0;
             if ($opt_sr == 1) {
                $soap_burst_time[$soap_burst_minute] = 0;
                $soap_burst_log[$soap_burst_minute] = $segcurr;
                $soap_burst_l[$soap_burst_minute] = $segline;
             }
             $soap_burst_count = 0;
         }
         if ($logtime >= $soap_burst_next) {
             $soap_burst[$soap_burst_minute] = $soap_burst_count;
             if ($opt_sr == 1) {
                $soap_burst_time[$soap_burst_minute] = $logtime - $soap_burst_start;
                $soap_burst_log[$soap_burst_minute] = $segcurr;
                $soap_burst_l[$soap_burst_minute] = $segline;
             }
             if ($soap_burst_max < $soap_burst_count) {
                $soap_burst_max = $soap_burst_count;
                $soap_burst_max_log = $segcurr;
                $soap_burst_max_l = $segline;
             }
             $soap_burst_minute += 1;
             $soap_burst_count = 0;
             $soap_burst_next += 60;
             while ($logtime > $soap_burst_next) {
                $soap_burst[$soap_burst_minute] = $soap_burst_count;
                if ($opt_sr == 1) {
                   $soap_burst_time[$soap_burst_minute] = $logtime - $soap_burst_start;
                   $soap_burst_log[$soap_burst_minute] = $segcurr;
                   $soap_burst_l[$soap_burst_minute] = $segline;
                }
                $soap_burst_next += 60;
                $soap_burst_minute += 1;
             }
         }
         $soap_burst_count++;
      }
      next;
   }

   #(52051207.0004-42:kdsstc1.c,2097,"ProcessTable") Table Status = 74, Rowcount = 0, TableName = WTMEMORY, Query Type = Select, TablePath = WTMEMORY
   if (substr($logunit,0,9) eq "kdsstc1.c") {
      if ($logentry eq "ProcessTable") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Table Status = 74, Rowcount = 0, TableName = WTMEMORY, Query Type = Select, TablePath = WTMEMORY
         next if substr($rest,1,14) ne "Table Status =";
         if ($pt_stime == 0) {
             $pt_stime = $logtime;
             $pt_etime = $logtime;
         }
         if ($logtime < $pt_stime) {
            $pt_stime = $logtime;
         }
         if ($logtime > $pt_etime) {
               $pt_etime = $logtime;
         }
         $rest =~ /.*?= (\S+)\,.*?=\s+(\S+)\,.*?= (\S+)\,.*?=\s*(.*?)\,.*?=\s*(\S*)/;

         $ipt_status = $1;
         $ipt_rows = $2;
         $ipt_table = $3;
         $ipt_type = $4;
         $ipt_path  = $5;
         my $post = index($ipt_type,",");
         $ipt_type = substr($ipt_type,0,$post) if $post > 0;
         $ipt_path =~ s/(^\s+|\s+$)//g;
         $ipt_key = $ipt_table . "_" . $ipt_path;
         $ix = $ptx{$ipt_key};
         if (!defined $ix) {
            $pti += 1;
            $ix = $pti;
            $pt[$ix] = $ipt_key;
            $ptx{$ipt_key} = $ix;
            $pt_table[$ix] = $ipt_table;
            $pt_path[$ix] = $ipt_path;
            $pt_insert_ct[$ix] = 0;
            $pt_query_ct[$ix] = 0;
            $pt_select_ct[$ix] = 0;
            $pt_selectpre_ct[$ix] = 0;
            $pt_delete_ct[$ix] = 0;
            $pt_total_ct[$ix] = 0;
            $pt_error_ct[$ix] = 0;
            $pt_errors[$ix] = "";
         }
         $pt_total_ct[$ix] += 1;
         $pt_total_total += 1;
         $pt_insert_ct[$ix] += 1 if $ipt_type eq "Insert";
         $pt_query_ct[$ix] += 1 if $ipt_type eq "Query";
         $pt_select_ct[$ix] += 1 if $ipt_type eq "Select";
         $pt_selectpre_ct[$ix] += 1 if $ipt_type eq "Select PreFiltered";
         $pt_delete_ct[$ix] += 1 if $ipt_type eq "Delete";
         if ($ipt_type eq "Insert") {
           if (($ipt_status != 74) and ($ipt_status != 0) ) {
              $pt_error_ct[$ix] += 1;
              $pt_errors[$ix] = $pt_errors[$ix] . " " . $ipt_status if index($pt_errors[$ix],$ipt_status) == -1;
           }
         } elsif ($ipt_status != 0) {
           $pt_error_ct[$ix] += 1;
           $pt_errors[$ix] = $pt_errors[$ix] . " " . $ipt_status if index($pt_errors[$ix],$ipt_status) == -1;
         }
      }
      next;
   }
   if (substr($logunit,0,12) eq "khdxcpub.cpp") {
       # (50229EBA.0002-A:khdxcpub.cpp,1383,"KHD_ValidateHistoryFile") History file /opt/Tivoli/ITM61/aix533/to/hist/INTERACTN row length is 4152, size is 132232896.
       if ($logentry eq "KHD_ValidateHistoryFile") {
          $oneline =~ /^\((\S+)\)(.+)$/;
          $rest = $2;                       #  History file /opt/Tivoli/ITM61/aix533/to/hist/INTERACTN row length is 4152, size is 132232896
          if (substr($rest,0,14) eq " History file ") {
             $rest =~ / History file (\S+) row length is (\d+),/;
             $table_rowsize{$1} = $2;      # recrod table row size
          }
       }
       next;
   }
   if (substr($logunit,0,12) eq "khdxhist.cpp") {
      # (502122FA.000C-D:khdxhist.cpp,2974,"openMetaFile") Metafile /opt/Tivoli/ITM61/aix533/to/hist/AGGREGATS.hdr opened
      if ($logentry eq "openMetaFile") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Metafile /opt/Tivoli/ITM61/aix533/to/hist/AGGREGATS.hdr opened
         if (substr($rest,1,8) eq "Metafile") {
            $rest =~ / Metafile (.*?)\.hdr /;
            $inmetatable = substr($1,rindex($1,"\/")+1);
         }
      }
   }
   if (substr($logunit,0,12) eq "khdxhist.cpp") {
      # (502122FA.000E-D:khdxhist.cpp,1382,"open") Starting export at 0000000000000000, row 0 for Aggregates
      if ($logentry eq "open") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Starting export at 0000000000000000, row 0 for Aggregates
         if (substr($rest,1,18) eq "Starting export at") {
            $rest =~ / row (\d+) for (.*)/;
            $inmetaobject = $2;
            if (defined $inmetatable) {
               $histobjx{$inmetatable} = $inmetaobject if !defined $histobjx{$inmetatable};
            }
         }
      }
   }
   if (substr($logunit,0,12) eq "khdxhist.cpp") {
      # (5022A246.0000-D:khdxhist.cpp,2734,"copyHistoryFile") 34030 read, 6359 skipped, 27671 written from "INTERACTN"
      if ($logentry eq "copyHistoryFile") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # 34030 read, 6359 skipped, 27671 written from "INTERACTN"
         if (index($rest,"written from") >= 0) {
            $rest =~ / (\d+) read, (\d+) skipped, (\d+) written from \"(.*?)\"/;
            $inreadct  = $1;
            $inskipct  = $2;
            $inwritect = $3;
            $intable   = $4;
            $inobject = "Object-" . $intable if !defined $histobjx{$intable};
            $inobject = $histobjx{$intable} if defined $histobjx{$intable};
            $hx = $histx{$inobject};
            next if !defined $hx;
            $hist_cycles[$hx] += 1;
            if ($hist_cycles[$hx] == 1) {
               $hist_maxrows[$hx] = $inwritect;
               $hist_minrows[$hx] = $inwritect;
            }
            $hist_maxrows[$hx] = $inwritect if $hist_maxrows[$hx] < $inwritect;
            $hist_minrows[$hx] = $inwritect if $hist_minrows[$hx] > $inwritect;
            $hist_totrows[$hx] += $inwritect;
            $hist_lastrows[$hx] = $inwritect;
         }
      }
   }
   if (substr($logunit,0,12) eq "khdxhist.cpp") {
      # (50229B3C.0000-D:khdxhist.cpp,1724,"close") /opt/Tivoli/ITM61/aix533/to/hist/INTERACTN - 1001 rows fetched, 0 skipped
      if ($logentry eq "close") {
         undef $inmetatable;
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # /opt/Tivoli/ITM61/aix533/to/hist/INTERACTN - 1001 rows fetched, 0 skipped
         if (index($rest," rows ") >= 0) {
            if (substr($rest,0,1) eq " ") {
               $rest =~ / (.*?) - (\d+) .* (\d+) skipped/;
               $inrowsize = $table_rowsize{$1};
               if ($inrowsize != 0) {
                  $intable = substr($1,rindex($1,"\/")+1);
                  $inappl = "Appl-" . $intable;
                  $inrows = $2-$3;
                  $inobject = "Object-" . $intable if !defined $histobjx{$intable};
                  $inobject = $histobjx{$intable} if defined $histobjx{$intable};
                  $hist_min = (localtime($logtime))[1];
                  $hist_min = int($hist_min/$opt_expslot) * $opt_expslot;
                  $hist_min = '00' . $hist_min;
                  $hist_hour = '00' . (localtime($logtime))[2];
                  $hist_day  = '00' . (localtime($logtime))[3];
                  $hist_month = (localtime($logtime))[4] + 1;
                  $hist_month = '00' . $hist_month;
                  $hist_year =  (localtime($logtime))[5] + 1900;
                  $hist_stamp = substr($hist_year,-2,2) . substr($hist_month,-2,2) . substr($hist_day,-2,2) .  substr($hist_hour,-2,2) .  substr($hist_min,-2,2);
                  if ($hist_min_time == 0) {
                     $hist_min_time = $logtime;
                     $hist_max_time = $logtime;
                  }
                  $hist_min_time = $logtime if $hist_min_time > $logtime;
                  $hist_max_time = $logtime if $hist_max_time < $logtime;

                  # first keep stats by object
                  $key = $inobject;
                  $hx = $histx{$key};
                  if (!defined $hx) {
                     $histi++;
                     $hx = $histi;
                     $hist[$hx] = $key;
                     $histx{$key} = $hx;
                     $hist_table[$hx] = $intable;
                     $hist_appl[$hx] = $inappl;
                     $hist_rows[$hx] = 0;
                     $hist_rowsize[$hx] = $inrowsize;
                     $hist_bytes[$hx] = 0;
                     $hist_maxrows[$hx] = 0;
                     $hist_minrows[$hx] = 0;
                     $hist_totrows[$hx] = 0;
                     $hist_lastrows[$hx] = 0;
                     $hist_cycles[$hx] = 0;
                  }
                  $hist_rows[$hx] += $inrows;
                  $hist_bytes[$hx] += $inrows * $inrowsize;

                  # next keep stats by time
                  $key = $hist_stamp;
                  $hx = $histtimex{$key};
                  if (!defined $hx) {
                     $histtimei++;
                     $hx = $histtimei;
                     $histtime[$hx] = $key;
                     $histtimex{$key} = $hx;
                     $histtime_rows[$hx] = 0;
                     $histtime_bytes[$hx] = 0;
                     $histtime_min_time[$hx] = $logtime;
                     $histtime_max_time[$hx] = $logtime;
                  }
                  $histtime_rows[$hx] += $inrows;
                  $histtime_bytes[$hx] += $inrows * $inrowsize;
                  $histtime_min_time[$hx] = $logtime if $histtime_min_time[$hx] > $logtime;
                  $histtime_max_time[$hx] = $logtime if $histtime_max_time[$hx] < $logtime;
                  # next keep stats by object_time
                  $key = $inobject . "_" . $hist_stamp;
                  $hx = $histobjectx{$key};
                  if (!defined $hx) {
                     $histobjecti++;
                     $hx = $histobjecti;
                     $histobject[$hx] = $key;
                     $histobjectx{$key} = $hx;
                     $histobject_object[$hx] = $inobject;
                     $histobject_table[$hx] = $intable;
                     $histobject_appl[$hx] = $inappl;
                     $histobject_time[$hx] = $hist_stamp;
                     $histobject_rowsize[$hx] = $inrowsize;
                     $histobject_rows[$hx] = 0;
                     $histobject_bytes[$hx] = 0;
                  }
                  $histobject_rows[$hx] += $inrows;
                  $histobject_bytes[$hx] += $inrows * $inrowsize;
               }
            }
         }
      }
      next;
   }
   if (substr($logunit,0,12) eq "khdxdacl.cpp") {
      # (4E7CB4A4.0026-16A:khdxdacl.cpp,1985,"routeData") Rowsize = 1592, Rows per buffer = 20
      if ($logentry eq "routeData") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Rowsize = 1592, Rows per buffer = 20
         if (substr($rest,1,9) eq "Rowsize =") {
            $rest =~ /Rowsize = (\d+),/;
            $inrowsize = $1;
         }
      }
   }
   if (substr($logunit,0,12) eq "khdxdacl.cpp") {
      # (4E7CB4A9.0002-16A:khdxdacl.cpp,545,"routeExportRequest") Export request for object KLZ_Process_User_Info table KLZPUSR appl KLZ), 1001 rows, is successful.
      if ($logentry eq "routeExportRequest") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Export request for object KLZ_Process_User_Info table KLZPUSR appl KLZ), 1001 rows, is successful.
         if (substr($rest,1,25) eq "Export request for object") {
            $inrowsize = 1000 if $inrowsize == 0;
            if ($inrowsize != 0) {
               $rest =~ / object (.*?) table (.*?) appl (.*?)\), (\d+) /;
               $inobject = $1;
               $intable = $2;
               $inappl = $3;
               $inrows = $4;
               $hist_min = (localtime($logtime))[1];
               $hist_min = int($hist_min/$opt_expslot) * $opt_expslot;
               $hist_min = '00' . $hist_min;
               $hist_hour = '00' . (localtime($logtime))[2];
               $hist_day  = '00' . (localtime($logtime))[3];
               $hist_month = (localtime($logtime))[4] + 1;
               $hist_month = '00' . $hist_month;
               $hist_year =  (localtime($logtime))[5] + 1900;
               $hist_stamp = substr($hist_year,-2,2) . substr($hist_month,-2,2) . substr($hist_day,-2,2) .  substr($hist_hour,-2,2) .  substr($hist_min,-2,2);
               if ($hist_min_time == 0) {
                  $hist_min_time = $logtime;
                  $hist_max_time = $logtime;
               }
               $hist_min_time = $logtime if $hist_min_time > $logtime;
               $hist_max_time = $logtime if $hist_max_time < $logtime;

               # first keep stats by object
               $key = $inobject;
               $hx = $histx{$key};
               if (!defined $hx) {
                  $histi++;
                  $hx = $histi;
                  $hist[$hx] = $key;
                  $histx{$key} = $hx;
                  $hist_table[$hx] = $intable;
                  $hist_appl[$hx] = $inappl;
                  $hist_rows[$hx] = 0;
                  $hist_rowsize[$hx] = $inrowsize;
                  $hist_bytes[$hx] = 0;
                  $hist_maxrows[$hx] = 0;
                  $hist_minrows[$hx] = 0;
                  $hist_totrows[$hx] = 0;
                  $hist_lastrows[$hx] = 0;
                  $hist_cycles[$hx] = 0;
               }
               $hist_rows[$hx] += $inrows;
               $hist_bytes[$hx] += $inrows * $inrowsize;

               # next keep stats by time
               $key = $hist_stamp;
               $hx = $histtimex{$key};
               if (!defined $hx) {
                  $histtimei++;
                  $hx = $histtimei;
                  $histtime[$hx] = $key;
                  $histtimex{$key} = $hx;
                  $histtime_rows[$hx] = 0;
                  $histtime_bytes[$hx] = 0;
                  $histtime_min_time[$hx] = $logtime;
                  $histtime_max_time[$hx] = $logtime;
               }
               $histtime_rows[$hx] += $inrows;
               $histtime_bytes[$hx] += $inrows * $inrowsize;
               $histtime_min_time[$hx] = $logtime if $histtime_min_time[$hx] > $logtime;
               $histtime_max_time[$hx] = $logtime if $histtime_max_time[$hx] < $logtime;

               # next keep stats by object_time
               $key = $inobject . "_" . $hist_stamp;
               $hx = $histobjectx{$key};
               if (!defined $hx) {
                  $histobjecti++;
                  $hx = $histobjecti;
                  $histobject[$hx] = $key;
                  $histobjectx{$key} = $hx;
                  $histobject_object[$hx] = $inobject;
                  $histobject_table[$hx] = $intable;
                  $histobject_appl[$hx] = $inappl;
                  $histobject_time[$hx] = $hist_stamp;
                  $histobject_rowsize[$hx] = $inrowsize;
                  $histobject_rows[$hx] = 0;
                  $histobject_bytes[$hx] = 0;
               }
               $histobject_rows[$hx] += $inrows;
               $histobject_bytes[$hx] += $inrows * $inrowsize;
            }
         }
      }
      next;
   }
   if (substr($logunit,0,10) eq "kglcbbio.c") {
      if ($logentry eq "kglcb_getFsyncConfig") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  fsync() is NOT ENABLED. KGLCB_FSYNC_ENABLED='0'
         $rest =~ /KGLCB_FSYNC_ENABLED\=\'(\d)\'/;
         $fsync_enabled = $1 if defined $1;
      }
   }
   # (53FE31BA.0043-61C:kglhc1c.c,563,"KGLHC1_Command") Entry
   # (53FE31BA.0044-61C:kglhc1c.c,592,"KGLHC1_Command") <0x190B3D18,0x8> Attribute type 0
   # +53FE31BA.0044     00000000   53595341 444D494E                      SYSADMIN
   # (53FE31BA.0045-61C:kglhc1c.c,601,"KGLHC1_Command") <0x190B4CFB,0x8A> Command String
   # +53FE31BA.0045     00000000   443A5C73 63726970  745C756E 69782031   D:\script\unix.1
   # +53FE31BA.0045     00000010   31343038 32373134  31353038 30303020   140827141508000.
   # +53FE31BA.0045     00000020   27554E49 585F4350  5527206C 74727364   'UNIX_CPU'.ltrsd
   # +53FE31BA.0045     00000030   3032303A 4B555820  2750726F 63657373   020:KUX.'Process
   # +53FE31BA.0045     00000040   20435055 20757469  6C697A61 74696F6E   .CPU.utilization
   # +53FE31BA.0045     00000050   20474520 38352069  73206372 69746963   .GE.85.is.critic
   # +53FE31BA.0045     00000060   616C2C20 20746865  20696E74 656E7369   al,..the.intensi
   # +53FE31BA.0045     00000070   7479206F 66206120  70726F63 65737320   ty.of.a.process.
   # +53FE31BA.0045     00000080   6973206F 66203938  2027                is.of.98.'
   # (53FE31BD.0000-61C:kglhc1c.c,862,"KGLHC1_Command") Exit: 0x0

   if (substr($logunit,0,9) eq "kglhc1c.c") {
      $oneline =~ /^\((\S+)\)(.+)$/;
      $rest = $2;
      if ($act_start == 0) {
         $act_start = $logtime;
         $act_end = $logtime;
      }
      if ($logtime < $act_start) {
         $act_start = $logtime;
      }
      if ($logtime > $act_end) {
         $act_end = $logtime;
      }
      if (substr($rest,1,5) eq "Entry") {             # starting a new command capture
          $act_id += 1;
          $runref = {                                # anonymous hash for command capture
                     thread => $logthread,           # Thread id associated with command capture
                     start => $logtime,              # Decimal time start
                     state => 1,                     # state = 1 means looking for command text
                     stamp => $logtimehex,           # stamp - hex time
                     cmd => "",                      # collected command text
                     cmd_tot => 0,                   # cmd expected length
                     id => $act_id,                  # action command id
          };
          $runx{$logthread} = $runref;
          $contkey = $logtimehex . "." . $logline;
          $contx{$contkey} = $runref;
          $act_current_cmds{$act_id} = $runref;            #
          my $current_act = keys %act_current_cmds;
          if ($current_act > $act_max) {
             $act_max = $current_act;
             @act_max_cmds = ();
             @act_max_cmds = values %act_current_cmds;
          }
      } else {
         $runref = $runx{$logthread};                     # is this a known command capture?
         if (defined $runref) {                           # ignore if process started before trace capture
            # (53FE31BD.0000-61C:kglhc1c.c,862,"KGLHC1_Command") Exit: 0x0
            if ((substr($rest,1,4) eq "Exit") or
                (substr($rest,1,7) eq "Execute")) {            # Ending a command capture
               my $cmd1 = $runref->{'cmd'};
               my $testcmd = $cmd1 . " ";
               my $testkey = substr($cmd1,0,index($cmd1," "));
               my $ax = $actx{$testkey};
               if (!defined $ax) {
                  $acti += 1;
                  $ax = $acti;
                  $act[$ax] = $testkey;
                  $actx{$testkey} = $ax;
                  $act_elapsed[$ax] = 0;
                  $act_ok[$ax] = 0;
                  $act_err[$ax] = 0;
                  $act_ct[$ax] = 0;
                  $act_act[$ax] = [];
               }
               $act_elapsed[$ax] += $logtime - $runref->{'start'};
               $act_ct[$ax] += 1;
               $act_ok[$ax] += 1 if substr($rest,7,3) eq "0x0";
               $act_err[$ax] += 1 if substr($rest,7,3) ne "0x0";
               push(@{$act_act[$ax]},$cmd1);
               my $endid = $runref->{'id'};
               delete $act_current_cmds{$endid};
            } else {
               if (substr($rest,1,1) eq "<") {
                   # (53FE31BA.0044-61C:kglhc1c.c,592,"KGLHC1_Command") <0x190B3D18,0x8> Attribute type 0
                   # (53FE31BA.0045-61C:kglhc1c.c,601,"KGLHC1_Command") <0x190B4CFB,0x8A> Command String
                   $rest =~ /\<\S+\,(\S+)\>(.*)/;
                   my $vlen = $1;
                   $rest = $2;
                   $key = $logtimehex . "." . $logline;
                   if (substr($rest,1,14) eq "Command String") {
                      $runref->{'state'} = 3;
                      $runref->{'cmd'} = "";
                      $runref->{'cmd_tot'} = hex($vlen);
                      $contx{$key} = $runref;
                   } elsif ($runref->{'state'} == 3) {
                      $runref->{'state'} = 1;
                   }

               }
            }
         }
      }
   }

   if (substr($logunit,0,10) eq "kdssqprs.c") {
      if ($logentry eq "PRS_ParseSql") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,19) eq "SQL to be parsed is") {
            $sql_state = 1;
            $sql_frag = "";
            if ($sql_start == 0) {
               $sql_start = $logtime;
               $sql_end = $logtime;
            }
            if ($logtime < $sql_start) {
               $sql_start = $logtime;
            }
            if ($logtime > $sql_end) {
               $sql_end = $logtime;
            }
         }
      }
      next;
   }

   next if substr($logunit,0,12) ne "kpxrpcrq.cpp";
   next if $logentry ne "IRA_NCS_Sample";
   $oneline =~ /^\((\S+)\)(.+)$/;
   $rest = $2;
      # Sample <665885373,2278557540> arrived with no matching request.
   if (substr($rest,1,6) eq "Sample") {
      if (index($rest,"arrived with no matching request.") != -1) {
         $nmr_total += 1;
      }
      next;
   }
     # Rcvd 1 rows sz 816 tbl *.UNIXOS req  <418500981,1490027440> node <evoapcprd:KUX>
   next if substr($rest,1,4) ne 'Rcvd';
   $rest =~ /(\S+) (\d+) rows sz (\d+) tbl (\S+) req (.*)/;
   next if $1 ne "Rcvd";
   $irows = $2;
   $isize = $3;
   $itbl = $4;
   $rest = $5;
   if (substr($rest,0,2) eq " <") {
      $isit = "(NULL)" . "-" . $itbl;
   }
   else {
      $rest =~ /(\S+) <(.*)/;
      $isit = $1;
      $rest = $2;
   }
   $rest =~ /node <(\S+)>/;
   $inode = $1;
   $insize = $isize*$irows;
   if ($sitstime == 0) {
      $sitstime = $logtime;
      $sitetime = $logtime;
   }
   if ($logtime < $sitstime) {
      $sitstime = $logtime;
   }
   if ($logtime > $sitetime) {
      $sitetime = $logtime;
   }
   if (!defined $sitx{$isit}) {      # if newly observed situation, set up initial values and associative array
      $siti++;
      $sit[$siti] = $isit;
      $sitx{$isit} = $siti;
      $sx = $siti;
      $sittbl[$sx] = $itbl;
      $sitct[$sx] = 0;
      $sitrows[$sx] = 0;
      $sitres[$sx] = 0;
      $sitrmin[$sx] = $insize;
      $sitrmax[$sx] = $insize;
      $sitrmaxnode[$sx] = $inode;
      $sitnoded[$sx] = {};
   }
   else {
      $sx = $sitx{$isit};
   }
   $sitct[$sx] += 1;
   $sitct_tot  += 1;
   $sitrows[$sx] += $irows;
   $sitrows_tot += $irows;
   if ($insize != 0) {
      if ($insize < $sitrmin[$sx]) {
         $sitrmin[$sx] = $insize;
      }
   }
   if ($insize > $sitrmax[$sx]) {
         $sitrmax[$sx] = $insize;
         $sitrmaxnode[$sx] = $inode;
      }
   $sitres[$sx] += $insize;
   $sitres_tot  += $insize;
   if ($opt_ri == 1) {
      my $res_stamp = $res_stampx{$logtime};
      my $logstime;
      if (!defined $res_stamp) {
         $logstime = int($logtime/$opt_ri_sec)*$opt_ri_sec;
         my $res_sec = (localtime($logstime))[0];
         $res_sec = '00' . $res_sec;
         my $res_min = (localtime($logstime))[1];
         $res_min = '00' . $res_min;
         my $res_hour = '00' . (localtime($logstime))[2];
         $res_day  = '00' . (localtime($logstime))[3];
         my $res_month = (localtime($logstime))[4] + 1;
         $res_month = '00' . $res_month;
         my $res_year =  (localtime($logstime))[5] + 1900;
         $res_stamp = substr($res_year,-2,2) . substr($res_month,-2,2) . substr($res_day,-2,2) .  substr($res_hour,-2,2) .  substr($res_min,-2,2) .  substr($res_sec,-2,2);
         $res_stampx{$logtime} = $res_stamp;
      }
      my $res_ref = $resx{$res_stamp};
      if (!defined $res_ref) {
         my %resref = (
                         stime => $logstime,
                         count => 0,
                         rows  => 0,
                         bytes => 0,
                         sitx => {},
                      );
         $resx{$res_stamp} = \%resref;
         $res_ref = \%resref;
      }
      $res_ref->{count} += 1;
      $res_ref->{rows} += $irows;
      $res_ref->{bytes} += $insize;
      ${$res_ref->{sitx}}{$isit} = 0 if !defined ${$res_ref->{sitx}}{$isit};
      ${$res_ref->{sitx}}{$isit} += 1;
   }

   if ($opt_b == 0) {next if $isit eq "HEARTBEAT";}

   $mx = $manx{$inode};
   if (!defined $mx) {       # if newly observed node, set up initial values and associative array
      $mani++;
      $man[$mani] = $inode;
      $manx{$inode} = $mani;
      $mx = $mani;
      $mantbl[$mx] = $itbl;
      $manct[$mx] = 0;
      $manrows[$mx] = 0;
      $manres[$mx] = 0;
      $manrmin[$mx] = $insize;
      $manrmax[$mx] = $insize;
      $manrmaxsit[$mx] = $isit;
   }
   $manct[$mx] += 1;
   $manrows[$mx] += $irows;
   if ($insize != 0) {
      if ($insize < $manrmin[$mx]) {
         $manrmin[$mx] = $insize;
      }
      if ($insize > $manrmax[$mx]) {
         $manrmax[$mx] = $insize;
         $manrmaxsit[$mx] = $isit;
      }
   }
   $manres[$mx] += $insize;
   # Following tracks inter-arrival time of results from agents concerning situations
   # don't have good use case yet or exactly how to display data
   # todo: ignore non-situations
   #       ignore pure situations??
   if ($opt_noded == 1) {
      my $node_ref = $sitnoded[$sx]{$inode};
      if (!defined $node_ref) {
         my %noderef = (
                          rarrive => $logtime,
                          rcount => 0,
                          inter_arrive => [],
         );
         $sitnoded[$sx]{$inode} = \%noderef;
         $node_ref = \%noderef;
      } else {
         my $iarrive = $logtime - $node_ref->{rarrive};
         $node_ref->{rarrive} = $logtime;
         $node_ref->{rcount} += 1;
         push(@{$node_ref->{inter_arrive}},$iarrive);
      }
      #$DB::single=2 if $node_ref->{rcount} > 1;
   }

}
   $dur = $sitetime - $sitstime;
   $tdur = $trcetime - $trcstime;

if ($dur == 0)  {
   print STDERR "Results Duration calculation is zero, setting to 1000\n";
   $dur = 1000;
}
if ($tdur == 0)  {
   print STDERR "Trace Duration calculation is zero, setting to 1000\n";
   $tdur = 1000;
}


# produce output report
my @oline = ();

my $cnt = -1;

if ($toobigi != -1) {
   $cnt++;$oline[$cnt]="Too Big Report\n";
   $cnt++;$oline[$cnt]="Situation,Table,FilterSize,Count\n";
   for ($i = 0; $i <= $toobigi; $i++) {
      $outl = $toobigsit[$i] . ",";
      $outl .= $toobigtbl[$i] . ",";
      $outl .= $toobigsize[$i] . ",";
      $outl .= $toobigct[$i] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $cnt++;$oline[$cnt]="\n";
}
if ($toobigi > -1) {
      my $ptoobigi = $toobigi + 1;
      $advisori++;$advisor[$advisori] = "Advisory: $ptoobigi Filter object too big situations and/or reports\n";
   }
if ($lp_high > $opt_nominal_listen) {
   if ($lp_high >= $opt_max_listen) {
      $advisori++;$advisor[$advisori] = "Advisory: Listen Pipe Shortage at maximum - emergency!!\n";
   }
   $advisori++;$advisor[$advisori] = "Advisory: Listen Pipe above nominal[$opt_nominal_listen] listen=$lp_high balance=$lp_balance threads=$lp_threads pipes=$lp_pipes\n";
}
if ($opt_nofile > 0) {
   if ($opt_nofile < $opt_nominal_nofile) {
      $advisori++;$advisor[$advisori] = "Advisory: ulimit nofile [$opt_nofile] is below nominal [$opt_nominal_nofile]\n";
   }
}
if ($opt_stack > 0) {
   if ($opt_stack > $opt_nominal_stack) {
      $advisori++;$advisor[$advisori] = "Advisory: ulimit stack [$opt_stack] is above nominal [$opt_nominal_stack] (kbytes)\n";
   }
}


my $res_pc = 0;
my $trc_pc = 0;
my $soap_pc = 0;
my $res_max = 0;

$cnt++;$oline[$cnt]="Summary Statistics\n";
$cnt++;$oline[$cnt]="Duration (seconds),,,$dur\n";
$cnt++;$oline[$cnt]="Total Count,,,$sitct_tot\n";
$cnt++;$oline[$cnt]="Total Rows,,,$sitrows_tot\n";
$cnt++;$oline[$cnt]="Total Result (bytes),,,$sitres_tot\n";
my $trespermin = int($sitres_tot / ($dur / 60));
$cnt++;$oline[$cnt]="Total Results per minute,,,$trespermin\n";
if ($trespermin > $opt_nominal_results) {
   $res_pc = int((($trespermin - $opt_nominal_results)*100)/$opt_nominal_results);
   my $ppc = sprintf '%.0f%%', $res_pc;
   $advisori++;$advisor[$advisori] = "Advisory: Results bytes per minute $ppc higher then nominal [$opt_nominal_results]\n";
   $res_max = 1;
}

$cnt++;$oline[$cnt]="\n";
$cnt++;$oline[$cnt]="Trace duration (seconds),,,$tdur\n";
my $trace_lines_minute = int($trace_ct / ($tdur / 60));
$cnt++;$oline[$cnt]="Trace Lines Per Minute,,,$trace_lines_minute\n";
my $trace_size_minute = int($trace_sz / ($tdur / 60));
$cnt++;$oline[$cnt]="Trace Bytes Per Minute,,,$trace_size_minute\n";
$cnt++;$oline[$cnt]="\n";
if ($trace_size_minute > $opt_nominal_trace) {
   $trc_pc = int((($trace_size_minute - $opt_nominal_trace)*100)/$opt_nominal_trace);
   my $ppc = sprintf '%.0f%%', $trc_pc;
   $advisori++;$advisor[$advisori] = "Advisory: Trace bytes per minute $ppc higher then nominal $opt_nominal_trace\n";
}
my $syncdist_early = -1;
if ($syncdist > 0) {
   my $synctime_print = join("/",@syncdist_time);
   $cnt++;$oline[$cnt]="Remote SQL time outs,,,$syncdist,$synctime_print\n";
   $cnt++;$oline[$cnt]="\n";
   for (my $i = 0; $i >= $syncdist; $i++) {
      $syncdist_early += 1 if $syncdist_time[$i] < $opt_nominal_remotesql;
   }
}

if ($syncdist_early > -1) {
      $advisori++;$advisor[$advisori] = "Advisory: $syncdist_early early remote SQL failures\n";
   }

if ($fsync_enabled == 0) {
      $advisori++;$advisor[$advisori] = "Advisory: KGLCB_FSYNC_ENABLED set to 0 - risky for TEMS database files\n";
   }

if ($lp_high != -1) {
   $cnt++;$oline[$cnt] = "Listen Pipe Report listen=$lp_high balance=$lp_balance threads=$lp_threads pipes=$lp_pipes\n";
   $cnt++;$oline[$cnt]="\n";
}

if ($nmr_total > 0) {
   $cnt++;$oline[$cnt]="Sample No Matching Request count,,,$nmr_total,\n";
   $cnt++;$oline[$cnt]="\n";
   $advisori++;$advisor[$advisori] = "Advisory: $nmr_total \"No Matching Request\" samples\n";
}

my $f;
my $crespermin = 0;
my $lag_fraction = 0;

my $situation_max = "";

$cnt++;$oline[$cnt]="Situation Summary Report\n";
$cnt++;$oline[$cnt]="Situation,Table,Count,Rows,ResultBytes,Result/Min,Fraction,Cumulative%,MinResults,MaxResults,MaxNode\n";
foreach $f ( sort { $sitres[$sitx{$b}] <=> $sitres[$sitx{$a}] ||
                                    $a cmp $b                      } keys %sitx ) {
   $i = $sitx{$f};
   $outl = $sit[$i] . ",";
   $outl .= $sittbl[$i] . ",";
   $outl .= $sitct[$i] . ",";
   $outl .= $sitrows[$i] . ",";
   $outl .= $sitres[$i] . ",";
   $respermin = int($sitres[$i] / ($dur / 60));
   $outl .= $respermin . ",";
   my $fraction = ($respermin*100) / $trespermin;
   my $pfraction = sprintf "%.2f", $fraction;
   $outl .= $pfraction . "%,";
   $crespermin += $respermin;
   $fraction = ($crespermin*100) / $trespermin;
   if ($res_max == 1) {
      if ($lag_fraction < $opt_nominal_workload) {
         $advisori++;$advisor[$advisori] = "Advisory: $sit[$i] high rate $respermin [$pfraction%]\n";
      }
   }
   $pfraction = sprintf "%.2f", $fraction;
   $outl .= $pfraction . "%,";
   $outl .= $sitrmin[$i] . ",";
   $outl .= $sitrmax[$i] . ",";
   if ($sitrmax[$i] >= $opt_max_results){
         $advisori++;$advisor[$advisori] = "Advisory: $sit[$i] possible truncated results - max result $sitrmax[$i]\n";
   }
   $outl .= $sitrmaxnode[$i];
   $cnt++;$oline[$cnt]=$outl . "\n";
   $lag_fraction = $fraction;
}


$cnt++;$oline[$cnt]="\n";
$situation_max = "";

$cnt++;$oline[$cnt]="Managed System Summary Report - non-HEARTBEAT situations\n";
$cnt++;$oline[$cnt]="Node,Table,Count,Rows,ResultBytes,Result/Min,MinResults,MaxResults,MaxSit\n";
foreach $f ( sort { $manres[$manx{$b}] <=> $manres[$manx{$a}] || $a cmp $b } keys %manx ) {
   $i = $manx{$f};
   $outl = $man[$i] . ",";
   $outl .= $mantbl[$i] . ",";
   $outl .= $manct[$i] . ",";
   $outl .= $manrows[$i] . ",";
   $outl .= $manres[$i] . ",";
   $respermin = int($manres[$i] / ($dur / 60));
   $outl .= $respermin . ",";
   $outl .= $manrmin[$i] . ",";
   $outl .= $manrmax[$i] . ",";
   $outl .= $manrmaxsit[$i];
   $cnt++;$oline[$cnt]=$outl . "\n";
}
$outl = "*total" . ",";
$outl .= $dur . ",";
$outl .= $sitct_tot . ",";
$outl .= $sitrows_tot . ",";
$outl .= $sitres_tot . ",";
$respermin = int($sitres_tot / ($dur / 60));
$outl .= $respermin;
$cnt++;$oline[$cnt]=$outl . "\n";

my $act_ct_total = 0;
my $act_ct_error = 0;
my $act_elapsed_total = 0;
my $act_duration;

if ($acti != -1) {
   $act_duration = $act_end - $act_start;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Reflex Command Summary Report\n";
   $cnt++;$oline[$cnt]="Count,Error,Elapsed,Cmd\n";
   foreach $f ( sort { $act_ct[$actx{$b}] <=> $act_ct[$actx{$a}] || $a cmp $b } keys %actx ) {
      $i = $actx{$f};
      $outl = $act_ct[$i] . ",";
      $outl .= $act_err[$i] . ",";
      $outl .= $act_elapsed[$i] . ",";
      my @cmdarray = @{$act_act[$i]};
      my $pcommand = $cmdarray[0];
      $pcommand =~ s/\x09/\\t/g;
      $pcommand =~ s/\x0A/\\n/g;
      $pcommand =~ s/\x0D/\\r/g;
      $pcommand =~ s/\"/\"\"/g;
      $outl .= "\"" . $pcommand . "\"";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $act_ct_total += $act_ct[$i];
      $act_ct_error += $act_err[$i];
      $act_elapsed_total += $act_elapsed[$i];

      if ($opt_cmdall == 1) {
         if ($#cmdarray > 0) {
            for (my $c=1;$c<=$#cmdarray;$c++) {
               $outl = ",,,";
               $pcommand = $cmdarray[$c];
               $pcommand =~ s/\x09/\\t/g;
               $pcommand =~ s/\x0A/\\n/g;
               $pcommand =~ s/\x0D/\\r/g;
               $pcommand =~ s/\x00/\\0/g;
               $pcommand =~ s/\"/\"\"/g;
               $pcommand =~ s/\'/\'\'/g;
               $outl .= "\"" . $pcommand . "\",";
               $cnt++;$oline[$cnt]=$outl . "\n";
            }
         }
      }
   }
   $outl = "duration" . " " . $act_duration . ",";
   $outl .= $act_elapsed_total . ",";
   $outl .= $act_ct_total . ",";
   $outl .= $act_ct_error . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
   if ($#act_max_cmds > 0) {
      $cnt++;$oline[$cnt]="\n";
      $outl = "Maximum action command overlay - $act_max";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $outl = "Seq,Command";
      $cnt++;$oline[$cnt]=$outl . "\n";
      for (my $i = 0; $i <=$#act_max_cmds; $i++) {
         $runref = $act_max_cmds[$i];
         $outl = "$i,$runref->{cmd},";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
   }
}

my $sqlt_duration;

if ($sqli != -1) {
   $sql_duration = $sql_end - $sql_start;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="SQL Summary Report\n";
   $cnt++;$oline[$cnt]="Count,SQL\n";
   foreach $f ( sort { $sql_ct[$sqlx{$b}] <=> $sql_ct[$sqlx{$a}] || $a cmp $b } keys %sqlx ) {
      $i = $sqlx{$f};
      $outl = $sql_ct[$i] . ",";
      my $psql =  $sql[$i];
      $psql =~ s/\"/\'/g;
      $outl .= "\"" . $psql . "\",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $sql_ct_total += $sql_ct[$i];
   }
   $outl = "duration" . " " . $sql_duration . ",";
   $outl .= $sql_ct_total . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
}

if ($soapi != -1) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="SOAP SQL Summary Report\n";
   $cnt++;$oline[$cnt]="IP,Count,SQL\n";
   foreach $f ( sort { $soapct[$soapx{$b}] <=> $soapct[$soapx{$a}] || $a cmp $b } keys %soapx ) {
      $i = $soapx{$f};
      $outl = $soapip[$i] . ",";
      $outl .= $soapct[$i] . ",";
      $csvdata = $soap[$i];
      $csvdata =~ s/\"/\'/g;
      $outl .= "\"" . $csvdata . "\"";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $outl = "*total" . ",";
   $outl .= $soapct_tot . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
   my $soap_rate = $soapct_tot / ($dur / 60);
   if ($soap_rate > $opt_nominal_soap) {
      $soap_pc = int((($soap_rate - $opt_nominal_soap)*100)/$opt_nominal_soap);
      my $ppc = sprintf '%.0f%%', $soap_pc;
      $advisori++;$advisor[$advisori] = "Advisory: SOAP requests per minute $ppc higher then nominal $opt_nominal_soap\n";
   }
   if ($soap_burst_max > $opt_nominal_soap_burst) {
      $soap_pc = int((($soap_burst_max - $opt_nominal_soap_burst)*100)/$opt_nominal_soap_burst);
      my $ppc = sprintf '%.0f%%', $soap_pc;
      $advisori++;$advisor[$advisori] = "\"Advisory: SOAP Burst requests per minute $ppc higher then nominal $opt_nominal_soap_burst at line $soap_burst_max_l in $soap_burst_max_log\"\n";
   }
}

if ($pti != -1) {
   $pt_dur = $pt_etime - $pt_stime;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Process Table Report\n";
   $cnt++;$oline[$cnt]="Process Table Duration: $pt_dur seconds\n";
   $cnt++;$oline[$cnt]="Table,Path,Insert,Query,Select,SelectPreFiltered,Delete,Total,Total/min,Error,Error/min,Errors\n";
   foreach $f ( sort { $pt_total_ct[$ptx{$b}] <=> $pt_total_ct[$ptx{$a}] || $a cmp $b } keys %ptx) {
      $i = $ptx{$f};
      $outl = $pt_table[$i] . ",";
      $outl .= $pt_path[$i] . ",";
      $outl .= $pt_insert_ct[$i] . ",";
      $outl .= $pt_query_ct[$i] . ",";
      $outl .= $pt_select_ct[$i] . ",";
      $outl .= $pt_selectpre_ct[$i] . ",";
      $outl .= $pt_delete_ct[$i] . ",";
      $outl .= $pt_total_ct[$i] . ",";
      $respermin = int($pt_total_ct[$i] / ($pt_dur / 60));
      $outl .= $respermin . ",";
      $outl .= $pt_error_ct[$i] . ",";
      $respermin = int($pt_error_ct[$i] / ($pt_dur / 60));
      $outl .= $respermin . ",";
      $outl .= $pt_errors[$i] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $respermin = int($pt_total_total / ($pt_dur / 60));
   $cnt++;$oline[$cnt]="*total*,,,,,,,$pt_total_total,$respermin,\n";
}

my $total_evt = 0;
my $pe_dur;
my $pevt_size = scalar (keys %pevtx);
if ($pevt_size > 0) {
   $pe_dur = $pe_etime - $pe_stime;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="PostEvent Report\n";
#   $cnt++;$oline[$cnt]="Process Table Duration: $pt_dur seconds\n";
   $cnt++;$oline[$cnt]="Situation,Node,Count,AtomCount,Thrunodes,\n";
   foreach $f ( sort { $pevtx{$b}->{count} <=> $pevtx{$a}->{count} } keys %pevtx) {
      $outl = $pevtx{$f}->{sitname} . ",";
      $outl .= $pevtx{$f}->{node} . ",";
      $outl .= $pevtx{$f}->{count} . ",";
      $total_evt += $pevtx{$f}->{count};
      my $acount = keys %{$pevtx{$f}->{atoms}};
      $outl .= $acount . ",";
      my $tlist = join(" ",keys %{$pevtx{$f}->{thrunode}});
      $outl .= $tlist . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $cnt++;$oline[$cnt]="*total*,$pe_dur,$total_evt,\n";
}

my $agto_dur = $agto_etime - $agto_stime;
if ($agto_mult > 0) {
   $advisori++;$advisor[$advisori] = "Advisory: $agto_mult_hr Agents with repeated onlines\n";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Multiple Agent online Report - top 20 max\n";
   $cnt++;$oline[$cnt]="Node,Online_Count\n";
   my $top_online = 20;
   my $top_current = 0;
   foreach $f ( sort { $agto_ct[$agtox{$b}] <=> $agto_ct[$agtox{$a}] } keys %agtox) {
      my $ai = $agtox{$f};
      $top_current += 1;
      last if $top_current > $top_online;
      $outl = $f . ",";
      $outl .= $agto_ct[$ai] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $agto_mult_hr += 1;
   }
   $cnt++;$oline[$cnt]="$agto_dur,$agto_mult,\n";
}

my $agtsh_dur = $agtsh_etime - $agtsh_stime;
if ($agtsh_dur > 0) {
#  $advisori++;$advisor[$advisori] = "Advisory: $agto_mult_hr Agents with repeated onlines\n";
   my $agtsh_total_multi = 0;
   my $agtsh_jitter_major = 0;
   my $agtsh_jitter_minor = 0;
   my %multi_agent = ();
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Fast Simple Heartbeat report\n";
   $cnt++;$oline[$cnt]="Node,Count,RatePerHour,NonModeCount,NonModeSum,InterArrivalTimes\n";
#     foreach $f ( keys %agtshx) {
#$DB::single=2 if !defined  $agsh_ct[$agtshx{$f}];
#      }
   foreach $f ( sort { $agtsh_ct[$agtshx{$b}] <=> $agtsh_ct[$agtshx{$a}] } keys %agtshx) {
      my $ai = $agtshx{$f};
      next if $agtsh_ct[$ai] == 1;
      my $avg = ($agtsh_ct[$ai]*3600)/($agtsh_dur);
      my $dur_ct = keys %{$agtsh_iat[$ai]};
      next if $dur_ct == 1;
      my $pdur = "";
      my $dur_mode = 0;
     # first determine mode of interarrival time
      foreach $g (sort  { $agtsh_iat[$ai]{$b}{count} <=> $agtsh_iat[$ai]{$a}{count}} keys %{$agtsh_iat[$ai]}) {
         $dur_mode = $g;
         last;
      }
      my $dur_vary_ct = 0;
      my $dur_vary_sum = 0;
      foreach $g (keys %{$agtsh_iat[$ai]}) {
         $pdur .= $g . "=";
         my $tdur = $agtsh_iat[$ai]{$g}{count};
         if ($g != $dur_mode) {
           $dur_vary_ct += $tdur;
           $dur_vary_sum += abs($g-$dur_mode)*$tdur;
         }
         $pdur .= $agtsh_iat[$ai]{$g}{count} . ";";
      }
      if (4*$dur_vary_ct > $agtsh_ct[$ai]) {
         $advisori++;$advisor[$advisori] = "Advisory: agent $f indication of duplicate agent names on same system: $pdur\n";
         $agtsh_total_multi += 1;
         $multi_agent{$f} = 1;
      } elsif ($dur_vary_sum > $agtsh_ct[$ai]){
         $advisori++;$advisor[$advisori] = "Advisory: agent $f indication of occasional high level jitter: $pdur\n";
         $agtsh_jitter_major += 1;
      } else  {
         $agtsh_jitter_minor += 1;
         if ($opt_jitall == 1){
            $advisori++;$advisor[$advisori] = "Advisory: agent $f indication of occasional low level jitter: $pdur\n";
         }
      }
      $outl = $f . ",";
      $outl .= $agtsh_ct[$ai]. ",";
      $outl .= $avg . ",";
      $outl .= $dur_vary_ct . ",";
      $outl .= $dur_vary_sum . ",";
      $outl .= $pdur . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $cnt++;$oline[$cnt]="$agtsh_dur,\n";
   $advisori++;$advisor[$advisori] = "Advisory: Simple agent Heartbeat total[$agtshi] multi_agent[$agtsh_total_multi] jitter_major[$agtsh_jitter_major] jitter_minor[$agtsh_jitter_minor]\n";

   # If major jitters, correlate large jitter events over time

   if ($agtsh_jitter_major > 0) {
      my %jitter_correlate;
      my $ptime;
      for (my $i=0;$i<60;$i++) {
         $ptime = substr("00" . $i,-2,2);
         $jitter_correlate{$ptime}{count} = 0;
      }
#      foreach $f ( keys %agtshx) {
#$DB::single=2 if !defined  $agsh_ct[$agtshx{$f}];
#      }
      foreach $f ( sort { $agtsh_ct[$agtshx{$b}] <=> $agtsh_ct[$agtshx{$a}] } keys %agtshx) {
         my $ai = $agtshx{$f};
         next if $agtsh_ct[$ai] == 1;
         next if defined $multi_agent{$f};
         my $avg = ($agtsh_ct[$ai]*3600)/($agtsh_dur);
         my $dur_ct = keys %{$agtsh_iat[$ai]};
         next if $dur_ct == 1;
         my $pdur = "";
         my $dur_mode = 0;
         foreach $g (sort  { $agtsh_iat[$ai]{$b}{count} <=> $agtsh_iat[$ai]{$a}{count}} keys %{$agtsh_iat[$ai]}) {
            $dur_mode = $g;
            last;
         }
         foreach $g (keys %{$agtsh_iat[$ai]}) {
            my $tdur = $agtsh_iat[$ai]{$g}{count};
            next if abs($g-$dur_mode) < 5;
            foreach $h (@{$agtsh_iat[$ai]{$g}{times}}) {
               my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($h);
               $mon += 1;
               my $itm_stamp = "1" .
                               substr($year+1900,2,2) .
                               substr("00" . $mon,-2,2) .
                               substr("00" . $mday,-2,2) .
                               substr("00" . $hour,-2,2) .
                               substr("00" . $min,-2,2) .
                               substr("00" . $sec,-2,2) .
                               "000";
               $minkey = substr("00" . $min,-2,2);
               $jitter_correlate{$minkey}{count} += 1;
               my $gdiff = $g-$dur_mode;
               my $prec = $f . "|" . $gdiff . "|" . $itm_stamp;
               push (@{$jitter_correlate{$minkey}{nodes}},$prec);
            }
         }
      }
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="Major Jitter Report\n";
      $cnt++;$oline[$cnt]="Minute,Nodes\n";
      foreach my $f (sort {$a <=> $b} keys %jitter_correlate) {
         next if $jitter_correlate{$f}{count} == 0;
         foreach my $g (@{$jitter_correlate{$f}{nodes}}) {
            $outl = $f . ",";
            $outl .= $g;
            $cnt++;$oline[$cnt]=$outl . "\n";
         }
      }
   }
}


my $timex_ct = scalar keys %timex;
if ($timex_ct > 0) {
   $advisori++;$advisor[$advisori] = "Advisory: $timex_ct Agent time out messages\n";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Agent Timeout Report\n";
   $cnt++;$oline[$cnt]="Table,Situation,Count\n";
   foreach $f ( sort { $timex{$b}->{count} <=> $timex{$a}->{count} } keys %timex) {
      my $ptable = $f;
      foreach my $g ( sort { $a cmp $b } keys %{$timex{$ptable}->{sit}} ) {
         my $psitname = $g;
         my $pcount = $timex{$ptable}->{sit}{$psitname}->{count};
         $outl = $ptable . ',';
         $outl .= $psitname . ",";
         $outl .= $pcount . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
   }
}

my $total_hist_rows = 0;
my $total_hist_bytes = 0;
$hist_elapsed_time = $hist_max_time - $hist_min_time;
my $time_elapsed;

if ($histi != -1) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Historical Export summary by time\n";
   $cnt++;$oline[$cnt]="Time,,,,Rows,Bytes,Secs,Bytes_min\n";
   foreach $f ( sort { $histtime[$histtimex{$a}] <=> $histtime[$histtimex{$b}] || $a cmp $b } keys %histtimex ) {
      $i = $histtimex{$f};
      $outl = $histtime[$i] . ",,,,";
      $outl .= $histtime_rows[$i] . ",";
      $outl .= $histtime_bytes[$i] . ",";
      $time_elapsed = $histtime_max_time[$i] - $histtime_min_time[$i] + 1;
      $outl .= $time_elapsed . ",";
      $outl .= int(($histtime_bytes[$i]*60)/$time_elapsed) . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
}


if ($histi != -1) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Historical Export summary by object\n";
   $cnt++;$oline[$cnt]="Object,Table,Appl,Rowsize,Rows,Bytes,Bytes_Min,Cycles,MinRows,MaxRows,AvgRows,LastRows\n";
   foreach $f ( sort { $hist[$histx{$a}] cmp $hist[$histx{$b}] || $a cmp $b } keys %histx ) {
      $i = $histx{$f};
      my $rows_cycle = 0;
      $rows_cycle = int($hist_totrows[$i]/$hist_cycles[$i]) if $hist_cycles[$i] > 0;
      $outl = $hist[$i] . ",";
      $outl .= $hist_table[$i] . ",";
      $outl .= $hist_appl[$i] . ",";
      $outl .= $hist_rowsize[$i] . ",";
      $outl .= $hist_rows[$i] . ",";
      $outl .= $hist_bytes[$i] . ",";
      my $hist_bytes_min = 0;
      $hist_bytes_min = int(($hist_bytes[$i]*60)/$hist_elapsed_time) if $hist_elapsed_time > 0;
      $outl .= $hist_bytes_min . ",";
      $outl .= $hist_cycles[$i] . ",";
      $outl .= $hist_minrows[$i] . ",";
      $outl .= $hist_maxrows[$i] . ",";
      $outl .= $rows_cycle . ",";
      $outl .= $hist_lastrows[$i] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $total_hist_rows += $hist_rows[$i];
      $total_hist_bytes += $hist_bytes[$i];
   }
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
}


if ($histi != -1) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Historical Export summary by time\n";
   $cnt++;$oline[$cnt]="Time,,,,Rows,Bytes,Secs,Bytes_min\n";
   foreach $f ( sort { $histtime[$histtimex{$a}] <=> $histtime[$histtimex{$b}] || $a cmp $b } keys %histtimex ) {
      $i = $histtimex{$f};
      $outl = $histtime[$i] . ",,,,";
      $outl .= $histtime_rows[$i] . ",";
      $outl .= $histtime_bytes[$i] . ",";
      $time_elapsed = $histtime_max_time[$i] - $histtime_min_time[$i] + 1;
      $outl .= $time_elapsed . ",";
      $outl .= int(($histtime_bytes[$i]*60)/$time_elapsed) . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
}

if ($histi != -1) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Historical Export summary by Object and time\n";
   $cnt++;$oline[$cnt]="Object,Table,Appl,Rowsize,Rows,Bytes,Time\n";
#   foreach $f ( sort { $histobjectx{$a} cmp $histobjectx{$b} } keys %histobjectx ) {
   foreach $f ( sort keys %histobjectx ) {
      $i = $histobjectx{$f};
      $outl = $f . ",";
      $outl .= $histobject_table[$i] . ",";
      $outl .= $histobject_appl[$i] . ",";
      $outl .= $histobject_rowsize[$i] . ",";
      $outl .= $histobject_rows[$i] . ",";
      $outl .= $histobject_bytes[$i] . ",";
      $outl .= $histobject_time[$i] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";
}
my %time_slot;
if ($opt_ri == 1) {
my $time_slag = 0;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Time Slot Result workload\n";
   $cnt++;$oline[$cnt]="Time,Count,Rows,Bytes,MaxSituation,MaxCount\n";
   foreach $f ( sort { $a <=> $b } keys %resx ) {
      my $res_ref = $resx{$f};
      $outl = "=\"" . $f . "\",";
      $outl .= $res_ref->{count} .",";
      $outl .= $res_ref->{rows} .",";
      $outl .= $res_ref->{bytes} .",";
      foreach $g ( sort { $res_ref->{sitx}{$b}  <=> $res_ref->{sitx}{$a}} keys %{$res_ref->{sitx}} ) {
         $outl .= $g .",";
         $outl .= $res_ref->{sitx}{$g} .",";
         last;
      }
      $cnt++;$oline[$cnt]=$outl . "\n";
      if ($time_slag == 0) {
         $time_slag = $res_ref->{stime};
         next;
      }
      my $slotkey = 0;
      for (my $k=$time_slag+$opt_ri_sec;$k < $res_ref->{stime}; $k+=$opt_ri_sec) {
         $time_slot{$slotkey} += 1;
      }
      $slotkey = $res_ref->{count};
      $time_slot{$slotkey} += 1;
      $time_slag = $res_ref->{stime};
   }
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Slot Results Frequency\n";
   $cnt++;$oline[$cnt]="Results,Count,\n";
   foreach $f ( sort { $a <=> $b } keys %time_slot ) {
         $outl = $f .",";
         $outl .= $time_slot{$f} .",";
         $cnt++;$oline[$cnt]=$outl . "\n";
   }
}


open OH, ">$opt_o" or die "can't open $opt_o: $!";


if ($opt_nohdr == 0) {
   for (my $i=0; $i<=$hdri; $i++) {
      print OH $hdr[$i] . "\n";
   }
   print OH "\n";
}


if ($advisori == -1) {
   print OH "No Expert Advisory messages\n";
} else {
   for (my $i=0;$i<=$advisori;$i++){
      print OH $advisor[$i];
   }
}
print OH "\n";

for (my $i = 0; $i<=$cnt; $i++) {
   print OH $oline[$i];
}
if ($opt_sr == 1) {
   if ($soap_burst_minute != -1) {
      my $opt_sr_fn = "soap_detail.txt";
      open SOAP, ">$opt_sr_fn" or die "Unable to open SOAP Detail output file $opt_sr_fn\n";
      select SOAP;              # print will use SOAP instead of STDOUT
      print "Secs   Count Line   Log-segment\n";
      for (my $i=0;$i<=$soap_burst_minute;$i++) {
         next if !defined $soap_burst_log[$i];
         next if $soap_burst[$i] == 0;
         my $oline =  "";
         $oline .= sprintf("%6d",$soap_burst_time[$i]) . " ";
         $oline .= sprintf("%5d",$soap_burst[$i]) . " ";
         $oline .= sprintf("%7d",$soap_burst_l[$i]) . " ";
         $oline .= sprintf("%s",$soap_burst_log[$i]);
         print "$oline\n";
      }
      close SOAP;
   }
}
close(OH);

print STDERR "Wrote $cnt lines\n";

# all done

exit 0;


sub open_kib {
   # get list of files
   $logpat = $logbase . '-.*\.log' if defined $logbase;
   if (!$opt_inplace) {
      if (defined $logbase) {
         my $cmd;
         my $rc;
         if ($gWin == 1) {
            $cmd = "copy \"$opt_logpath$logbase-*.log\" \"$opt_workpath\">nul";
            $cmd =~ s/\//\\/g;    # switch to backward slashes for Windows command
            $rc = system($cmd);
         } else {
            $cmd = "cp $opt_logpath$logbase-*.log $opt_workpath.>/dev/null";
            $rc = system($cmd);
         }
         $opt_logpath = $opt_workpath;
         $workdel = $logbase . "-*.log";
      }
   }

   if (defined $logpat) {
      opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n");
      @dlogfiles = grep {/$logpat/} readdir(DIR);
      closedir(DIR);
      die "no log files found with given specifcation\n" if $#dlogfiles == -1;

      my $dlog;          # fully qualified name of diagnostic log
      my $oneline;       # local variable
      my $tlimit = 100;  # search this many times for a timestamp at begining of a log
      my $t;
      my $tgot;          # track if timestamp found
      my $itime;

      foreach $f (@dlogfiles) {
         $f =~ /^.*-(\d+)\.log/;
         $segmax = $1 if $segmax eq "";
         $segmax = $1 if $segmax < $1;
         $dlog = $opt_logpath . $f;
         open($dh, "< $dlog") || die("Could not open log $dlog\n");
         for ($t=0;$t<$tlimit;$t++) {
            $oneline = <$dh>;                      # read one line
            next if $oneline !~ /^.(.*?)\./;       # see if distributed timestamp in position 1 ending with a period
            $oneline =~ /^.(.*?)\./;               # extract value
            $itime = $1;
            next if length($itime) != 8;           # should be 8 characters
            next if $itime !~ /^[0-9A-F]*/;            # should be upper cased hex digits
            $tgot = 1;                             # flag gotten and quit
            last;
         }
         if ($tgot == 0) {
            print STDERR "the log $dlog ignored, did not have a timestamp in the first $tlimit lines.\n";
            next;
         }
         $todo{$dlog} = hex($itime);               # Add to array of logs
         close($dh);
      }
      $segmax -= 1;

      foreach $f ( sort { $todo{$a} <=> $todo{$b} } keys %todo ) {
         $segi += 1;
         $seg[$segi] = $f;
         $seg_time[$segi] = $todo{$f};
      }
   } else {
         $segi += 1;
         $seg[$segi] = $logfn;
         $segmax = 0;
   }
}

sub read_kib {
   if ($segp == -1) {
      $segp = 0;
      if ($segmax > 0) {
         my $seg_diff_time = $seg_time[1] - $seg_time[0];
         if ($seg_diff_time > 3600) {
            $skipzero = 1;
         }
      }
      $segcurr = $seg[$segp];
      open(KIB, "<$segcurr") || die("Could not open log segment $segp $segcurr\n");
      print STDERR "working on $segp $segcurr\n" if $opt_v == 1;
      $hdri++;$hdr[$hdri] = '"' . "working on $segp $segcurr" . '"';
      $segline = 0;
   }
   $segline ++;
   $inline = <KIB>;
   return if defined $inline;
   close(KIB);
   unlink $segcurr if $workdel ne "";
   $segp += 1;
   $skipzero = 0;
   return if $segp > $segi;
   $segcurr = $seg[$segp];
   open(KIB, "<$segcurr") || die("Could not open log segment $segp $segcurr\n");
   print STDERR "working on $segp $segcurr\n" if $opt_v == 1;
   $hdri++;$hdr[$hdri] = '"' . "working on $segp $segcurr" . '"';
   $segline = 1;
   $inline = <KIB>;
}

sub gettime
{
   my $sec;
   my $min;
   my $hour;
   my $mday;
   my $mon;
   my $year;
   my $wday;
   my $yday;
   my $isdst;
   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
   return sprintf "%4d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec;
}


#------------------------------------------------------------------------------
sub GiveHelp
{
  $0 =~ s|(.*)/([^/]*)|$2|;
  print <<"EndOFHelp";

  $0 v$gVersion

  This script raeds a TEMS diagnostic log and writes a report of certain
  log records which record the result rows.

  Default values:
    none

  Run as follows:
    $0  <options> log_file

  Options
    -h              display help information
    -z              z/OS RKLVLOG log
    -b              Show HEARTBEATs in Managed System section
    -expslot <mins> Historical export report slot size - default 60 mins
    -v              Produce limited progress messages in STDERR
    -inplace        [default and not used - see work parameter]
    -logpath        Directory path to TEMS logs - default current directory
    -work           Copy files to work directory before analyzing.
    -workpath       Directory path to work directory, default is the system
                    Environment variable Windows - TEMP, Linux/Unix tmp

  Examples:
    $0  logfile > results.csv

EndOFHelp
exit;
}
#------------------------------------------------------------------------------
# 0.50000 - initial development
# 0.60000 - too big report first, add managed system report
# 0.70000 - convert RKLVLOG time stamps to Unix epoch seconds
# 0.75000 - sort reports by number of ResultBytes column in descending order ,
#         - add SOAP SQL report if trace entries present
# 0.80000 - add logic for historical data export
# 0.90000 - add -b option to break out HEARTBEAT sources
#           add processing of agent export traces
# 0.95000 - add move summary to top and add per cent column
# 0.99000 - calculate the correct log segments
# 1.00000 - Optional work directory when handling log segments
# 1.01000 - erase work directory files when finished
# 1.05000 - count trace lines and size per minute
#         - inplace added, capture too big cases in hands off mode
#         - Add count of remote SQL time out messages
#         - Handle isolated historical data lines better
# 1.06000 - Add -work option and default inplace to ON
# 1.10000 - Add Advisory section
#           Fix hands off logic with Windows logs
#         - Add 16meg truncated result advisory
# 1.15000 - Summary Dataserver ProcessTable trace
#         - Add check for listen pipe shortage
# 1.16000 - fix broken -z option
# 1.17000 - more -z fixes and truncated result advisory
# 1.18000 - add counts of No Matching Requests
# 1.19000 - add advisory for Nofile less then 8192
# 1.20000 - add advisory for Stack more then 10M
# 1.21000 - handle listen messages at ITM 630
#         - add SOAP Burst calculation and advisory
# 1.22000 - add -sr == soapreport
# 1.23000 - handle z/OS better, especially for ProcessTable capture
# 1.24000 - count action commands
#         - Advisory when KGLCB_FSYNC_ENABLED=0
# 1.25000 - count SQLs
# 1.26000 - Track recursive locks
# 1.27000 - KFA_PostEvent tracking
# 1.28000 - Track duplicate agent online logs
# 1.29000 - Show duplicate agent online better - top 20
# 1.30000 - Add SimpleHeartbeat report - finds another type of duplicate agent
# 1.31000 - Add Major Jitter correlation report
# 1.32000 - Make command capture logic work on z/OS logs
# 1.33000 - Add result interval report
#         - Add results interval count report
