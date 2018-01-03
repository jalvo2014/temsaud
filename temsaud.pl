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
## (58231CDA.0002-18:kglaffam.c,294,"AFF1_IsPartOf") Warning: No affinity entry for <&IBM.CAM7_WAS>
##  47955.080.678.pdcollect-dkccham010apmxm.jar_unpack

## (591F66A8.0000-C:kpxreqds.cpp,3555,"addTargetToRegistrationList") Error <2> occurred while attempting to dynamically add node <minsrmped:KUX> to Registration List
##  24058.000.661.pdcollect-itmrtems02_19_Mayo.tar.Z_unpack

## (591F6677.0009-15:kpxrreg.cpp,1623,"IRA_NotifySDAInstallStatus") SDA Notification failed, agent "sapprdaix04:KUX", product "UX" found unexpected RegBind type=4. Can't provide agent with SDA install result.
##  87348,082,000
##  /ecurep/pmr/8/7/87348,082,000/2017-05-19/87348.082.000.pdcollect-dkha3080.tar.Z_unpack/

## (591C3F9F.0000-A2:kfastins.c,2166,"GetSitLogRecord") ReadNext Error, status = 5
##  /ecurep/pmr/0/1/01551,227,000/2017-05-23/01551.227.000.pdcollect-AVPIU507.tar.Z_unpack/

## (591ACD2E.0000-7C:kshcat.cpp,296,"RetrieveTableByTableName") Unable to get attributes for table tree TOBJACCL

my $gVersion = 1.64000;

#use warnings::unused; # debug used to check for unused variables
use strict;
use warnings;
use Time::Local;

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
my $ccsid1047 =
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
my $logfn;
my $opt_v;
my $opt_ss;                                      # create SendStatus report
my $opt_o;
my $opt_odir;                                    # directory for all output files
my $opt_ossdir;                                  # directory for ss output files
my $opt_nohdr = 0;
my $workdel = "";
my $opt_inplace = 1;
my $opt_work    = 0;
my $opt_nofile = 0;                              # number of file descriptors, zero means not found
my $opt_stack = 0;                               # Stack limit zero means not found
my $opt_kbb_ras1 = "";                           # KBB_RAS1 setting
my $opt_kdc_debug = "";                          # KDC_DEBUG setting
my $opt_kde_debug = "";                          # KDE_DEBUG setting
my $opt_kdh_debug = "";                          # KDH_DEBUG setting
my $opt_kbs_debug = "";                          # KBS_DEBUG setting
my $opt_com_debug = 0;                           # KBS_DEBUG setting
my $opt_sr;                                      # Soap Report
my $opt_cmdall;                                  # show all commands
my $opt_jitall;                                  # show all jitter
my $opt_noded = 0;                               # track inter-arrival times for results
my $opt_b;
my $opt_level = 0;                               # build level not found
my $opt_driver = "";                             # Driver
my $opt_sum;                                     # Summary text
my $opt_nodeid = "";                             # TEMS nodeid
my $opt_tems = "";                               # *HUB or *REMOTE
my $opt_sqldetail;                               # detail SQL report wanted
my $opt_rd;                                      # result detail wanted
my $opt_rdslot;                                  # number of seconds for result detail slot, default 60 seconds
my $opt_rdtop;                                   # number of situations to display
my $ssi = -1;
my @ssout;
my $opt_flip = 0;

my $test_logfn;
my $invfile;
my $invpath;
my $testfn;
my @invfn;
my @invdir;
my $logspath;
my $logsinv;
my $endfnp;
my $invlogtime = 0;


my @seg = ();
my $segcurr;
my $i;
my $g;
my $h;
my $l;
my $respermin;
my $dur;
my $tdur;
my @syncdist_time;
my $oneline;
my $sumline;
my $sql_frag;
my $sql_source = "";
my $key;
my $hist_stamp;
my $iagent;
my $pos;
my $rc;

sub gettime;                             # get time
sub capture_sqlrun;
sub time2sec;
sub sec2time;

my $hdri = -1;                               # some header lines for report
my @hdr = ();                                #

# allow user to set impact
my %advcx = (
              "TEMSAUDIT1001W" => "90",
              "TEMSAUDIT1002W" => "80",
              "TEMSAUDIT1003W" => "40",
              "TEMSAUDIT1004W" => "20",
              "TEMSAUDIT1005W" => "0",
              "TEMSAUDIT1006E" => "100",
              "TEMSAUDIT1007W" => "10",
              "TEMSAUDIT1008E" => "100",
              "TEMSAUDIT1009E" => "100",
              "TEMSAUDIT1010W" => "80",
              "TEMSAUDIT1011W" => "90",
              "TEMSAUDIT1022E" => "100",
              "TEMSAUDIT1023W" => "80",
              "TEMSAUDIT1024E" => "100",
              "TEMSAUDIT1012W" => "90",
              "TEMSAUDIT1013W" => "85",
              "TEMSAUDIT1014W" => "60",
              "TEMSAUDIT1015W" => "60",
              "TEMSAUDIT1016W" => "80",
              "TEMSAUDIT1017W" => "90",
              "TEMSAUDIT1018W" => "20",
              "TEMSAUDIT1019W" => "10",
              "TEMSAUDIT1020W" => "40",
              "TEMSAUDIT1021W" => "50",
              "TEMSAUDIT1025E" => "90",
              "TEMSAUDIT1026E" => "90",
              "TEMSAUDIT1027W" => "60",
              "TEMSAUDIT1028W" => "40",
              "TEMSAUDIT1029W" => "75",
              "TEMSAUDIT1030W" => "50",
              "TEMSAUDIT1031E" => "0",
              "TEMSAUDIT1032E" => "100",
              "TEMSAUDIT1033W" => "90",
              "TEMSAUDIT1034W" => "75",
              "TEMSAUDIT1035W" => "80",
              "TEMSAUDIT1036W" => "60",
              "TEMSAUDIT1037E" => "100",
              "TEMSAUDIT1038W" => "80",
              "TEMSAUDIT1039W" => "95",
              "TEMSAUDIT1040E" => "100",
              "TEMSAUDIT1041E" => "100",
              "TEMSAUDIT1042E" => "100",
              "TEMSAUDIT1043E" => "110",
              "TEMSAUDIT1044E" => "100",
              "TEMSAUDIT1045W" => "95",
              "TEMSAUDIT1046W" => "90",
              "TEMSAUDIT1047W" => "95",
              "TEMSAUDIT1048E" => "100",
              "TEMSAUDIT1049E" => "100",
              "TEMSAUDIT1050W" => "100",
              "TEMSAUDIT1051E" => "110",
              "TEMSAUDIT1052E" => "200",
              "TEMSAUDIT1053W" => "95",
              "TEMSAUDIT1054W" => "80",
              "TEMSAUDIT1055W" => "90",
              "TEMSAUDIT1056W" => "85",
              "TEMSAUDIT1057W" => "80",
              "TEMSAUDIT1058E" => "100",
              "TEMSAUDIT1059W" => "90",
              "TEMSAUDIT1060W" => "95",
              "TEMSAUDIT1061E" => "90",
              "TEMSAUDIT1062W" => "85",
              "TEMSAUDIT1063E" => "100",
              "TEMSAUDIT1064E" => "90",
              "TEMSAUDIT1065W" => "75",
              "TEMSAUDIT1066W" => "75",
              "TEMSAUDIT1067E" => "100",
            );

my %advtextx = ();
my $advkey = "";
my $advtext = "";
my $advline;
my %advgotx = ();

my %sit32x = ();
my %sitrulx = ();
my $sitrul_ref;
my $sitrul_state = 0;
my $sitrul_sitname = 0;
my $sitrul_pdt = 0;
my $sitrul_atr = 0;

my %node_ignorex = ();

my %sthx = ();

my %soapcat = ();

my %valvx;
my $val_ref;
my %valx;
my $valkey;
my %vcontx;
my %reflexx;
my %locix;
my $loci_ct = 0;
my $logloci;
my %lociex = (                    # generic loci counter exclusion
                "RAS1|CTBLD" => 1,
                "kdyshdlib.cpp|issueNodeStatusOpenThread" => 1,
                "kdyshdlib.cpp|issueNodeStatusOpenThread" => 1,
                "kdyinodests.cpp|selectNodeStatus" => 1,
                "kdyctrl.cpp|rTEMSSynchThread" => 1,
                "kpxreqhb.cpp|HeartbeatInserter" => 1,
                "kdepnpc.c|KDEP_NewPCB" => 1,
                "kdebpli.c|KDEBP_Listen" => 1,
                "kdepdpc.c|KDEP_DeletePCB" => 1,
                "kpxrwhpx.cpp|LookupWarehouse" => 1,
                "kfaprpst.c|KFA_UpdateNodestatusAtHub" => 1,
                "kfastins.c|KFA_PutSitRecord" => 1,
             );

my %rdx;
my $rd_ref;
my $sit_ref;

my %codex;
my $code_ref;
my $conv_ref;

my %pcbx;
my %pcbr;

my $hublost_total = 0;
my $gskit_nocipher = 0;
my $intexp_total = 0;
my $seq999_total = 0;
my $ruld_total = 0;
my $mktime_total = 0;
my $eipc_none = 0;


my %soaperror;
my $soaperror_fault = "";
my $soaperror_client = "";
my $soaperror_ct;

my %changex;
my $changex_ct = 0;

my %misscolx;
my $misscolx_ct;


my $stage2 = "";
my $stage2_ct = 0;
my $stage2_ct_err = 0;

my %commex;
my $comme_ct = 0;

my %atrwx;                        # collection of attribute warnings
my $atrwx_ct = 0;                 # collection of attribute warnings
my $atr_warn;
my $atr_name;
my $atr_app;
my $atr_table;
my $atr_column;
my $atr_file;
my $atr_ref;
my $atrn_ref;
my $atrf_ref;

my %inodex;

my $portscan = 0;
my $portscan_Unsupported = 0;
my $portscan_HTTP = 0;
my $portscan_integrity = 0;
my $portscan_suspend = 0;
my $portscan_72 = 0;

while (<main::DATA>)
{
  $advline = $_;
  if ($advkey eq "") {
     chomp $advline;
     $advkey = $advline;
     next;
  }
  if (length($advline) >= 15) {
     if (substr($advline,0,9) eq "TEMSAUDIT") {
        $advtextx{$advkey} = $advtext;
        chomp $advline;
        $advkey = $advline;
        $advtext = "";
        next;
     }
  }
  $advtext .= $advline;
}
$advtextx{$advkey} = $advtext;


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
my $opt_nominal_max_impact = 50;                     # Above this impact level, return exit code non-zero
my $opt_nominal_loci = 1;                     # Above this percent, record in loci report

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
   } elsif ($ARGV[0] eq "-sum") {
      $opt_sum = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-sr") {
      $opt_sr = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-flip") {
      $opt_flip = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-cmdall") {
      $opt_cmdall = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-sqldetail") {
      $opt_sqldetail = 1;
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
   } elsif ($ARGV[0] eq "-ss") {
      $opt_ss = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-nohdr") {
      $opt_nohdr = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-rd") {
      $opt_rd = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-rdslot") {
      shift(@ARGV);
      $opt_rdslot = shift(@ARGV);
   } elsif ($ARGV[0] eq "-rdtop") {
      shift(@ARGV);
      $opt_rdtop = shift(@ARGV);
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
   } elsif ($ARGV[0] eq "-odir") {
      shift(@ARGV);
      $opt_odir = shift(@ARGV);
      die "odir specified but no path found\n" if !defined $opt_odir;
   } elsif ($ARGV[0] eq "-ossdir") {
      shift(@ARGV);
      $opt_ossdir = shift(@ARGV);
      die "ossdir specified but no path found\n" if !defined $opt_ossdir;
   } elsif ($ARGV[0] eq "-workpath") {
      shift(@ARGV);
      $opt_workpath = shift(@ARGV);
#     $opt_inplace = 0;
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
if (!defined $opt_sum) {$opt_sum = 0;}
if (!defined $opt_sr) {$opt_sr = 0;}
if (!defined $opt_cmdall) {$opt_cmdall = 0;}
if (!defined $opt_sqldetail) {$opt_sqldetail = 0;}
if (!defined $opt_jitall) {$opt_jitall = 0;}
if (!defined $opt_v) {$opt_v = 0;}
if (!defined $opt_ss) {$opt_ss = 0;}
if (!defined $opt_o) {$opt_o = "temsaud.csv";}
if (!defined $opt_odir) {$opt_odir = "";}
if (!defined $opt_ossdir) {$opt_ossdir = "";}
if (!defined $opt_expslot) {$opt_expslot = 60;}
if (!defined $opt_rd) {$opt_rd = 60;}
if (!defined $opt_rdslot) {$opt_rdslot = 1;}
if (!defined $opt_rdtop) {$opt_rdtop = 5;}

my $gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

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
if ($opt_odir ne "") {
   $opt_odir =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments
   $opt_odir .= '/' if substr($opt_odir,-1,1) ne '/';
}
if ($opt_ossdir ne "") {
   $opt_ossdir =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments
   $opt_ossdir .= '/' if substr($opt_ossdir,-1,1) ne '/';
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
      elsif ($words[0] eq "max_impact") {$opt_nominal_max_impact = $words[1];}
      elsif (substr($words[0],0,9) eq "TEMSAUDIT"){
         die "unknown advisory code $words[0]" if !defined $advcx{$words[0]};
         die "Advisory code with no advisory impact" if !defined $words[1];
         $advcx{$words[0]} = $words[1];
      } else {
         die "unknown control in temsaud.ini line $l unknown control $words[0]";
      }
   }
}

my $pattern;
my @results = ();
my $loginv;
my $inline;
my $logbase;
my %todo = ();     # associative array of names and first identified timestamp
my @seg_time = ();
my $segi = -1;
my $segp = -1;
my $segcur = "";
my $segline;
my $segmax = "";
my $skipzero = 0;


my %etablex = ();
my $etable;
my %dtablex = ();
my $dtable;
my %itablex = ();
my $itable;
my %derrorx = ();
my $derror;
my %rtablex = ();
my $rtable;
my %rdtablex = ();
my $rdtable;
my %rdtime;
my $cur_rdtime;
my $rd_start = "";
my $rd_end = "";
my %vtablex = ();
my $vtable;
my $rindex;

my %resx;        # hash of result details by minute
my %res_stampx;  # hash of times to result minute stamps

my $advi = -1;
my @advonline = ();
my @advsit = ();
my @advimpact = ();
my @advcode = ();
my %advx = ();

my $max_impact = 0;

if ($logfn eq "") {
   $pattern = "(_ms|_MS)(_kdsmain)?\.inv";
   @results = ();
   opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
   @results = grep {/$pattern/} readdir(DIR);
   closedir(DIR);
   die "No _ms.inv found\n" if $#results == -1;
   $logfn =  $results[0];
   if ($#results > 0) {
      # found 2+ inv files
      # review all inv files, some may contain illegal or missing files so need to check all.
      for (my $i=0;$i<=$#results;$i++) {
         my $testinvfn = $opt_logpath . $results[$i];
         next if !open( INV, "< $testinvfn" );
         $inline = <INV>;
         close(INV);
         chomp $inline;
         $inline =~ s|\\|\/|g;  # convert backslash to forward slash, needed for Perl
         my $lpos = rindex($inline,"/");
         my $endfn = substr($inline,$lpos+1);
         $lpos = rindex($endfn,"-");
         my $front_line = substr($endfn,0,$lpos);
         $test_logfn = $opt_logpath . $endfn;
         next if ! -s $test_logfn;
         next if !open( LOG, "< $test_logfn" );
         $inline = <LOG>;
         close(LOG);
         chomp $inline;
         my $testime;
         eval {$testime = hex(substr($inline,1,8))};
         next if $@;
         if ($invlogtime < $testime) {
            $invlogtime = $testime;
            $logfn = $results[$i];   # record inv file with most recent log record
         }
      }
   }
}


$full_logfn = $opt_logpath . $logfn;
if ($logfn =~ /.*\.inv$/) {
   open(INV, "< $full_logfn") || die("Could not open inv  $full_logfn\n");
   $inline = <INV>;
   die "empty INV file $full_logfn\n" if !defined $inline;
   $inline =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments
   $pos = rindex($inline,'/');
   $inline = substr($inline,$pos+1);
   $pos = rindex($inline,"-");
   $logbase = substr($inline,0,$pos);
   $logfn = $logbase . '-*.log';
   close(INV);
}


if (!defined $logbase) {
   $logbase = $logfn if ! -e $logfn;
}



die "-expslot [$opt_expslot] is not numeric" if  $opt_expslot !~ /^\d+$/;
die "-expslot [$opt_expslot] is not positive number from 1 to 60" if  ($opt_expslot < 1) or ($opt_expslot > 60);

#??? doubt the next line works
die "-expslot [$opt_expslot] is not an even multiple of 60" if  (int(60/$opt_expslot) * $opt_expslot) != 60;

die "-rdslot [$opt_rdslot] is not numeric" if  $opt_rdslot !~ /^\d+$/;
die "-rdslot [$opt_rdslot] is not positive number from 1 to 60" if  ($opt_expslot < 1) or ($opt_expslot > 60);

sub open_kib;
sub read_kib;



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
my $uadvisor_bytes = 0;     # Uadvisor size
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
my $soap_burst_minute = -1; # current minute from start
my $soap_burst_count = 0;   # current minute count
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
my $anic_total = 0;         # Activity not in call count
my $fsync_enabled = 1;      # assume fsync is enabled
my $kds_writenos = "";      # assume kds_writenos not specified
my $gmm_total = 0;          # count out of storage messages

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
my @sql_src = ();

my %sqlsourcex;                               # detailed tracking of SQL by source and table and text
my %sqlrunx;                                  # track sql fragments by process number
my $sqlrun_ct;                                #
my $sqlrun_ref;

my $sql_start = 0;
my $sql_end = 0;
my $sql_count = 0;

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

my $invalid_checkpoint_count = 0;
my $kcf_count = 0;


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
my $agtsh_total_ct = 0;                      # number of multiple S-Hs with rate/hr >= 6;
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
my $total_hist_rows;
my $total_hist_bytes;


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

my %miss_tablex;

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
#   last if $l > 300000;
#print STDERR "Working on $l\n";
# following two lines are used to debug errors. First you flood the
# output with the working on log lines, while merging stdout and stderr
# with  1>xxx 2>&1. From that you determine what the line number was
# before the faulting processing. Next you turn that off and set the conditional
# test for debugging and test away.
# print STDERR "working on log $segcurr at $l\n";

   chomp($inline);
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
                   $oneline =~ /Nofile Limit: (\d+)(.?)/;
                   $opt_nofile = $1;
                   my $modi = $2;
                   if (defined $modi) {
                      $opt_nofile *= 1024 if $modi eq "K";
                      $opt_nofile *= 1024*1024 if $modi eq "M";
                   }
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
                   $oneline =~ /Stack Limit: (\d+)(.?)/;
                   $opt_stack = $1;
                   my $modi = $2;
                   if (defined $modi) {
                      $opt_stack *= 1024 if $modi eq "K";
                      $opt_stack *= 1024*1024 if $modi eq "M";
                   }
                }
             }
         }
      }
   }
   if ($opt_kbb_ras1 eq "") {
      if (substr($oneline,0,1) eq "+") {
          $opt_kbb_ras1 = "n/a" if substr($oneline,14,11) eq " ==========";
          # +56B8B325.0000         KBB_RAS1: <not specified>
          if ($opt_kbb_ras1 eq "") {
             my $pi = index($oneline,"KBB_RAS1:");
             if ($pi != -1) {
               $oneline =~ /KBB_RAS1:(.*)/;
               $opt_kbb_ras1 = $1;
             }
         }
      }
   }

   # Extract the build level for TEMS
   #(53EE63EA.0004-165C:kdsops1.c,358,"OPER_Initialize")
   #+53EE63EA.0004      KDS Server   Version: 630  Build: 13245  Driver: 'tms630fp2:d3248'
   #+53EE63EA.0004                   Date: Sep  5 2013  Time: 08:10:00  build date: 'Mon 09/02/13' info: kms/kds prod ne
   if ($opt_level == 0) {
      if (substr($oneline,0,1) eq "+") {
         if (length($oneline) > 40) {
            if (substr($oneline,20,10) eq "KDS Server") {
               $opt_level = -1;
               $opt_driver = "";
               $oneline =~ /Version:.*?(\d+).*?Driver: \'(\S+)\'/;
               $opt_level = $1 if defined $1;
               $opt_driver = $2 if defined $2;
               if ($opt_level >= 630) {
                  if ($opt_driver ge 'tms630fp5:d5163a') {      # at FP5 service thread default changed to 63
                     $opt_max_listen = 63;
                     $opt_nominal_listen = 48;
                  }
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
      my $val_ref = $vcontx{$contkey};
      if (defined $val_ref) {
         if ($val_ref->{'state'} == 2) {
            my $val_frag = substr($oneline,30,36);
            $val_frag =~ s/\ //g;
            $val_frag =~ s/(([0-9a-f][0-9a-f])+)/pack('H*', $1)/ie;
            $val_ref->{'val'} .= $val_frag;
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
      $logline = $2;                 # line number following hex epoch, meaningful when there are + extended lines
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
   $logunit =~ /(.*?)\,(\d+)/;
   if (defined $2) {
   my $locitest = $1 . "|" . $logentry;
      if (!defined $lociex{$locitest}) {
         my $logloci = $1 . "|" . $logentry . "|" . $2;
         my $loci_ref = $locix{$logloci};
         if (!defined $loci_ref) {
            my %lociref = (
                             count => 0,
                             first => "",
                          );
            $loci_ref = \%lociref;
            $locix{$logloci} = \%lociref;
            $loci_ref->{first} = $oneline;
         }
         $loci_ref->{count} += 1;
         $loci_ct += 1;
      }
   }

   $syncdist_first_time = $logtime if !defined $syncdist_first_time;

   # Extract the TEMS nodeid
   #(53EE63EB.0000-165C:kbbssge.c,52,"BSS1_GetEnv") CMS_NODEID="HUB_TEPTEMS"
   if ($opt_nodeid eq "") {
      if (substr($logunit,0,9) eq "kbbssge.c") {
         if ($logentry eq "BSS1_GetEnv") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # CMS_NODEID="HUB_TEPTEMS"
            if (substr($rest,1,11) eq "CMS_NODEID=") {
               $rest =~ /CMS_NODEID=\"(\S+)\"/;
               $opt_nodeid = $1;
            }
         }
      }
   }

   # Extract the TEMS type
   #(53EE63EA.000B-165C:kbbssge.c,52,"BSS1_GetEnv") KDS_HUB="*LOCAL"
   if ($opt_tems eq "") {
      if (substr($logunit,0,9) eq "kbbssge.c") {
         if ($logentry eq "BSS1_GetEnv") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # KDS_HUB="*LOCAL"
            if (substr($rest,1,8) eq "KDS_HUB=") {
               $rest =~ /KDS_HUB=\"(\S+)\"/;
               $opt_tems = $1;
            }
         }
      }
   }

   #(58CE9A38.0002-1:kbbssge.c,72,"BSS1_GetEnv") KDS_WRITENOS="YES"
   if ($kds_writenos eq "") {
      if (substr($logunit,0,9) eq "kbbssge.c") {
         if ($logentry eq "BSS1_GetEnv") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # KDS_WRITENOS="YES"
            if (substr($rest,1,12) eq "KDS_WRITENOS") {
               $rest =~ /KDS_WRITENOS=\"(\S+)\"/;
               $kds_writenos = $1;
            }
         }
      }
   }

   # (540827D1.001C-4:kbbracd.c,126,"set_filter") *** KDC_DEBUG=Y is in effect
   if ($opt_kdc_debug eq "") {
      if (substr($logunit,0,9) eq "kbbracd.c") {
         if ($logentry eq "set_filter") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # *** KDC_DEBUG=Y is in effect
            if (substr($rest,1,13) eq "*** KDC_DEBUG") {
               $rest =~ /KDC_DEBUG=(\S+) /;
               $opt_kdc_debug = $1;
            }
         }
      }
   }
   # (540827D1.001F-4:kbbracd.c,126,"set_filter") *** KDE_DEBUG=Y is in effect
   if ($opt_kde_debug eq "") {
      if (substr($logunit,0,9) eq "kbbracd.c") {
         if ($logentry eq "set_filter") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # *** KDE_DEBUG=Y is in effect
            if (substr($rest,1,13) eq "*** KDE_DEBUG") {
               $rest =~ /KDE_DEBUG=(\S+) /;
               $opt_kde_debug = $1;
            }
         }
      }
   }
   if ($opt_kdh_debug eq "") {
      if (substr($logunit,0,9) eq "kbbracd.c") {
         if ($logentry eq "set_filter") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # *** KDH_DEBUG=Y is in effect
            if (substr($rest,1,13) eq "*** KDH_DEBUG") {
               $rest =~ /KDH_DEBUG=(\S+) /;
               $opt_kdh_debug = $1;
            }
         }
      }
   }
   if ($opt_kbs_debug eq "") {
      if (substr($logunit,0,9) eq "kbbracd.c") {
         if ($logentry eq "set_filter") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # *** KBS_DEBUG=Y is in effect
            if (substr($rest,1,13) eq "*** KBS_DEBUG") {
               $rest =~ /KBS_DEBUG=(\S+) /;
               $opt_kbs_debug = $1;
            }
         }
      }
   }
   # signal(s) for communication failures
   # (57BE11EA.0006-2:kdcc1sr.c,485,"rpc__sar") Connection lost: "ip.pipe:#172.27.2.10:7025", 1C010001:1DE0004D, 0, 130(0), FFFA/30, D140831.1:1.1.1.13, tms_ctbs630fp5:d5135a
   if (substr($logunit,0,9) eq "kdcc1sr.c") {
      if ($logentry eq "rpc__sar") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  Connection lost: "ip.pipe:#172.27.2.10:7025", 1C010001:1DE0004D, 0, 130(0), FFFA/30, D140831.1:1.1.1.13, tms_ctbs630fp5:d5135a
         if (substr($rest,1,15) eq "Connection lost") {
            $rest =~ /\"(.*?):(.*?)\", (\w+):(\w+),/;
            my $iprotocol = $1;
            my $iaddrport = $2;
            my $ierror = $3 . ":" . $4;
            my $addrkey = $1 . ":" . $2;
            my $error_ref = $commex{$ierror};
            if (!defined $error_ref) {
               my %errorref = (
                                 count => 0,
                                 targets => {},
                              );
               $error_ref = \%errorref;
               $commex{$ierror} = \%errorref;
            }
            $error_ref->{count} += 1;
            $comme_ct += 1;
            my $addr_ref = $commex{$ierror}->{targets}{$addrkey};
            if (!defined $addr_ref) {
               my %addrref = (
                                 count => 0,
                              );
               $addr_ref = \%addrref;
               $commex{$ierror}->{targets}{$addrkey} = \%addrref;
            }
            $addr_ref->{count} += 1;
            next;
         }
      }
   }

   # (5890C272.0000-5D3:kdcc1wh.c,114,"conv__who_are_you") status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL
   if (substr($logunit,0,9) eq "kdcc1wh.c") {
      if ($logentry eq "conv__who_are_you") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL
         if (substr($rest,1,15) eq "status=1c010008") {
            $anic_total += 1;
         }
      }
   }

   # Following seen when KDC_DEBUG=Y - more details about ANIC
   # (58CC5929.0001-1579:kdcc1sr.c,924,"rpc__sar") Conversation timeout: "ip.spipe:#129.39.23.114:3660", 1C010008:00000000, 0, 121(0), FFFF/1, D140831.1:1.1.1.13, tms_ctbs630fp5:d5135a
   # (588789D2.0000-2B2:kdcc1sr.c,642,"rpc__sar") Endpoint unresponsive: "ip.spipe:#0.0.1.41:7757", 1C010001:1DE0000F, 210, 131(0), FFFF/181, D140831.1:1.1.1.13, tms_ctbs630fp5:d5135a
   if (substr($logunit,0,9) eq "kdcc1sr.c") {
      if ($logentry eq "rpc__sar") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Conversation timeout: "ip.spipe:#129.39.23.114:3660", 1C010008:00000000, 0, 121(0), FFFF/1, D140831.1:1.1.1.13, tms_ctbs630fp5:d5135a
         if (index($rest,":#") != -1) {
            my $itext = "";
            my $isource = "";
            my $icode = "";
            my $ilevel = "";
            $rest =~ /\"(\S+)\", (\S+):.*(tms\S+)$/;
            $rest =~ /(.*?): \"(\S+)\", (\S+), .*(tms\S+)/;
            $itext = $1 if defined $1;
            $isource = $2 if defined $2;
            $icode = $3 if defined $3;
            $ilevel = $4 if defined $4;
            next if $isource eq "";
            $code_ref = $codex{$icode};
            if (!defined $code_ref) {
               my %coderef = (
                                count => 0,
                                text => $itext,
                                conv => {},
                             );
               $code_ref = \%coderef;
               $codex{$icode} = \%coderef;
            }
            $code_ref->{count} += 1;
            $conv_ref = $code_ref->{conv}{$isource};
            if (!defined $conv_ref) {
               my %convref = (
                                count => 0,
                                level => $ilevel,
                             );
               $conv_ref = \%convref;
               $code_ref->{conv}{$isource} = \%convref;
            }
            $conv_ref->{count} += 1;
         }
      }
   }
   # signal for KDEB_INTERFACELIST conflicts
   # (58DA4E42.0511-73:kdepnpc.c,138,"KDEP_NewPCB") 151.88.15.201: 10B0C8C6, KDEP_pcb_t @ 1383B83B0 created
   if (substr($logunit,0,9) eq "kdepnpc.c") {
      if ($logentry eq "KDEP_NewPCB") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # 151.88.15.201: 10B0C8C6, KDEP_pcb_t @ 1383B83B0 created
         if (substr($rest,-7) eq "created") {
            $rest =~ / (\S+): (\S+),/;
            my $iip = $1;
            my $iaddr = "X" . $2;
            my $pcb_ref = $pcbx{$iip};
            if (!defined $pcb_ref) {
               my %pcbref = (
                               addr => {},
                               newPCB => 0,
                               deletePCB => 0,
                               agents => {},
                            );
               $pcb_ref = \%pcbref;
               $pcbx{$iip} = \%pcbref;
            }
            $pcb_ref->{count} += 1;
            $pcb_ref->{newPCB} += 1;
            $pcb_ref->{addr}{$iaddr}=1;
            $pcbr{$iaddr} = $iip;
            next;
         }
      }
   }
   # signal for KDEB_INTERFACELIST conflicts
   # (58DA4EFE.00B1-174:kdepdpc.c,62,"KDEP_DeletePCB") 10B0C8C6: KDEP_pcb_t deleted
   if (substr($logunit,0,9) eq "kdepdpc.c") {
      if ($logentry eq "KDEP_DeletePCB") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # 10B0C8C6: KDEP_pcb_t deleted
         if (substr($rest,-7) eq "deleted") {
            $rest =~ / (\S+):/;
            my $iaddr = "X" . $1;
            my $iip = $pcbr{$iaddr};
            if (defined $iip) {
               my $pcb_ref = $pcbx{$iip};
               if (defined $pcb_ref) {
                  if (defined $pcb_ref->{addr}{$iaddr}) {
                     $pcb_ref->{count} += 1;
                     $pcb_ref->{deletePCB} += 1;
                     delete $pcb_ref->{addr}{$iaddr};
                     delete $pcbr{$iaddr};
                  }
               }
            }
            next;
         }
      }
   }

   # (58D77E39.0002-11A0:ko4mgtsk.cpp,133,"ManagedTask::sendStatus") Connection to HUB lost - stopping situation status insert
   if (substr($logunit,0,12) eq "ko4mgtsk.cpp") {
      if ($logentry eq "ManagedTask::sendStatus") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Connection to HUB lost - stopping situation status insert
         if (substr($rest,1,22) eq "Connection to HUB lost") {
            $hublost_total += 1;
            next;
         }
      }
   }

   # (59183B36.0000-53:kdebeal.c,81,"ssl_provider_open") GSKit error 402: GSK_ERROR_NO_CIPHERS - errno 11
   if (substr($logunit,0,9) eq "kdebeal.c") {
      if ($logentry eq "ssl_provider_open") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # GSKit error 402: GSK_ERROR_NO_CIPHERS - errno 11   insert
         if (substr($rest,1,16) eq "GSKit error 402:") {
            $gskit_nocipher += 1;
            next;
         }
      }
   }

   # (590CFA4B.002B-449:kgltmbas.c,725,"DriveTimerExit") KDSTMDTE: Interval Missed Seconds=1494015924 Nsecs=763544806 Detected at Seconds=1494022731 Nsecs=80363777
   if (substr($logunit,0,10) eq "kgltmbas.c") {
      if ($logentry eq "DriveTimerExit") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # KDSTMDTE: Interval Missed Seconds=1494015924 Nsecs=763544806 Detected at Seconds=1494022731 Nsecs=80363777
         if (substr($rest,1,25) eq "KDSTMDTE: Interval Missed") {
            $intexp_total += 1;
            next;
         }
      }
   }

   # (59198C7E.005E-A:socket_imp.c,2020,"_create_eipc_client") KDE1_StringToAddress returned 0x1DE00003 for none
   if (substr($logunit,0,12) eq "socket_imp.c") {
      if ($logentry eq "_create_eipc_client") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # KDE1_StringToAddress returned 0x1DE00003 for none
         if (substr($rest,1,49) eq "KDE1_StringToAddress returned 0x1DE00003 for none") {
            $eipc_none += 1;
            next;
         }
      }
   }

   # (59199276.0204-39D:kdsxoc2.c,2081,"VXO2_MakeTime") MKTIME result is not a valid timestamp (mktime returned -1)
   if (substr($logunit,0,9) eq "kdsxoc2.c") {
      if ($logentry eq "VXO2_MakeTime") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # MKTIME result is not a valid timestamp (mktime returned -1)   History file T6SUBTXCS corruption found at file position 008F2E18. EndOfFileReached = 0, CurrRowValid = 0, NextRowValid = 1.
         if (substr($rest,1,38) eq "MKTIME result is not a valid timestamp") {
             $mktime_total += 1;
             next;
         }
      }
   }

   # (591D9C01.0005-129:khdxhist.cpp,3796,"validateRow") History file T6SUBTXCS corruption found at file position 008F2E18. EndOfFileReached = 0, CurrRowValid = 0, NextRowValid = 1.
   if (substr($logunit,0,12) eq "khdxhist.cpp") {
      if ($logentry eq "validateRow") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  History file T6SUBTXCS corruption found at file position 008F2E18. EndOfFileReached = 0, CurrRowValid = 0, NextRowValid = 1.
         if (substr($rest,1,12) eq "History file") {
            $rest =~ /file (\S+) corruption/;
            if (defined $1) {
               my $atrg = $1;
               $sthx{$atrg} += 1;
               next;
            }
         }
      }
   }


   # (59198D87.0005-9:kdssnc1.c,967,"CreateSituation") Cannot create the RULE tree
   if (substr($logunit,0,9) eq "kdssnc1.c") {
      if ($logentry eq "CreateSituation") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Cannot create the RULE tree
         if (substr($rest,1,27) eq "Cannot create the RULE tree") {
            $ruld_total += 1;
            next;
         }
      }
   }

   # (5912EC8A.05F0-1F:kfastplr.c,92,"KFA_LogRecTimestamp") Sequence number overflow, reusing 999
   if (substr($logunit,0,10) eq "kfastplr.c") {
      if ($logentry eq "KFA_LogRecTimestamp") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Sequence number overflow
         if (substr($rest,1,24) eq "Sequence number overflow") {
            $seq999_total += 1;
            next;
         }
      }
   }

   # (591F66A7.0000-8:ko4sitma.cpp,481,"IBInterface::lodge") Error: sit name <ARG_NT_DisSpa_Cr_COIBMPDPW6K01_1> length <32> invalid
   if (substr($logunit,0,12) eq "ko4sitma.cpp") {
      if ($logentry eq "IBInterface::lodge") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Error: sit name <ARG_NT_DisSpa_Cr_COIBMPDPW6K01_1> length <32> invalid
         if (substr($rest,-19,19) eq "length <32> invalid") {
            $rest=~ /name \<(\S+)\>/;
            my $isitname = $1;
            $sit32x{$isitname} += 1;
            next;
         }
      }
   }

   if (substr($logunit,0,12) eq "ko4rulex.cpp") {
      if ($logentry eq "PredParser::build") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Unsupported request method "NESSUS"
         if (substr($rest,1,6) eq "Error:") {
            $sitrul_state = 1;                     #state 1 = looking for further data.
         } elsif (substr($rest,1,12) eq "..Situation:") {
           if ($sitrul_state == 1) {
              $rest =~ /\<(\S+)\>$/;
              $sitrul_sitname = $1;
              $sitrul_state = 2;
            }
         } elsif (substr($rest,1,6) eq "..PDT:") {
           if ($sitrul_state == 2) {
              $rest =~ /\<(.*)\>/;
              $sitrul_pdt = $1;
              $sitrul_state = 3;
           }
        }
        next;
      }
   }
   if (substr($logunit,0,12) eq "ko4rulfa.cpp") {
     if ($logentry eq "NodeFactory::createNode") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #
         if (substr($rest,1,24) eq "Error: Unknown attribute") {
           if ($sitrul_state == 3) {
              $rest =~ /\<(\S+)\> /;
              $sitrul_atr = $1;
              my $sitrul_key = $sitrul_sitname . "|" . $sitrul_atr;
              $sitrul_ref = $sitrulx{$sitrul_key};
              if (!defined $sitrul_ref) {
                 my %sitrulref = (
                                    count => 0,
                                    sitname => $sitrul_sitname,
                                    pdt => $sitrul_pdt,
                                    atr => $sitrul_atr,
                                 );
                 $sitrul_ref = \%sitrulref;
                 $sitrulx{$sitrul_key} = \%sitrulref;
              }
              $sitrul_ref->{count} += 1;
           }
         }
      }
   }

   # (591F6750.0002-2C:kfastinh.c,1114,"KFA_InsertNodestatus") Affinity not loaded for node <UMBSRVCTXDEV:XA> thrunode <RTEMS02> affinities <%IBM.KXA                0000000001000Jyw0a7>.  Node Status Ignored.
   if (substr($logunit,0,10) eq "kfastinh.c") {
      if ($logentry eq "KFA_InsertNodestatus") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  Affinity not loaded for node <UMBSRVCTXDEV:XA> thrunode <RTEMS02> affinities <%IBM.KXA                0000000001000Jyw0a7>.  Node Status Ignored.
         if (substr($rest,1,19) eq "Affinity not loaded") {
            $rest =~ /\<(\S+)\> thrunode \<(\S+)\>/;
            my $inode = $1;
            my $ithrunode = $2;
            $node_ignorex{$inode} = $ithrunode;
         }
      }
   }


   # signals for port scanning
   # (571C6FD5.0000-F6:kdhsiqm.c,772,"KDHS_InboundQueueManager") Unsupported request method "NESSUS"
   # (55C14E21.0002-89:kdhsiqm.c,548,"KDHS_InboundQueueManager") error in HTTP request from ip.ssl:#10.107.19.12:33992, status=7C4C803A, "unknown method in request"
   if (substr($logunit,0,9) eq "kdhsiqm.c") {
      if ($logentry eq "KDHS_InboundQueueManager") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Unsupported request method "NESSUS"
         if (substr($rest,1,26) eq "Unsupported request method") {
            $portscan++;
            $portscan_Unsupported++;
         } elsif (substr($rest,1,21) eq "error in HTTP request") {
            $portscan++ if index($rest,"unknown method in request") != -1;
            $portscan_HTTP++;
         }
         next;
      }
   }

   # (55C14E21.0001-8B:kdebp0r.c,235,"receive_pipe") Status 1DE00074=KDE1_STC_DATASTREAMINTEGRITYLOST
   if (substr($logunit,0,9) eq "kdebp0r.c") {
      if ($logentry eq "receive_pipe") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # DATASTREAMINTEGRITYLOST
         if (substr($rest,1,48) eq "Status 1DE00074=KDE1_STC_DATASTREAMINTEGRITYLOST") {
            $portscan++;
            $portscan_integrity++;
         }
      }
   }
   # (55C220BB.0003-5B:kdebpli.c,115,"pipe_listener") ip.spipe suspending new connections: 1DE0000D
   if (substr($logunit,0,9) eq "kdebpli.c") {
      if ($logentry eq "pipe_listener") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # suspending new connections
         if (index($rest,"suspending new connections") != -1) {
            $portscan++;
            $portscan_suspend++;
         }
      }
   }
   # (58FAAE7F.0000-61B7B:kdebbac.c,50,"KDEB_BaseAccept") Status 1DE0000D=KDE1_STC_IOERROR=72: NULL
   if (substr($logunit,0,9) eq "kdebbac.c") {
      if ($logentry eq "KDEB_BaseAccept") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Status 1DE0000D=KDE1_STC_IOERROR=72: NULL
         if (index($rest,"KDE1_STC_IOERROR=72") != -1) {
            $portscan++;
            $portscan_72++;
         }
      }
   }

   # capture hub TEMS connection timings
   # (57B1FB8E.0064-8:ko4crtsq.cpp,6931,"IBInterface::doStageTwoProcess") Begin stage 2 processing. Database and IB Cache synchronization with the hub
   # (57B1FB93.0008-8:ko4crtsq.cpp,7146,"IBInterface::doStageTwoProcess") End stage 2 processing. Database and IB Cache synchronization with the hub with return code: 0
   if (substr($logunit,0,12) eq "ko4crtsq.cpp") {
      if ($logentry eq "IBInterface::doStageTwoProcess") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Begin stage 2 processing. Database and IB Cache synchronization with the hub
         if (substr($rest,1,13) eq "Begin stage 2") {
            $stage2_ct += 1;
            $stage2 .= "Begin-" . $logtime . ":";
         } elsif (substr($rest,1,11) eq "End stage 2") {
            $stage2_ct += 1;
            $stage2 .= "End-" . $logtime . ":";
            $stage2_ct_err += 1 if index($rest,"return code: 0") == -1;
         }
         next;
      }
   }

   # capture attribute file warnings - following is one example
   #(56CB01BD.0001-1:kglatrvl.c,193,"add_to_index") Warning: attribute name conflict
   #(56CB01BD.0002-1:kglatrvl.c,194,"add_to_index") Block <946C150> name <Diagnostic.Node> id <30001>
   #(56CB01BD.0003-1:kglatrvl.c,194,"add_to_index")  app <KTU> table <TUDIAG> column <ORIGINNODE>
   #(56CB01BD.0004-1:kglatrvl.c,194,"add_to_index")  file <KTU.ATR> timestamp <1121121120356000> line <8>
   #(56CB01BD.0005-1:kglatrvl.c,194,"add_to_index")  data type <2> entry type <0> sample type <3>
   #(56CB01BD.0006-1:kglatrvl.c,194,"add_to_index")  max <9223372036854775807> min <-9223372036854775808> str len <32> end codes <0>
   #(56CB01BD.0007-1:kglatrvl.c,194,"add_to_index")  scale <0> prec <0> cost <0> order <-1>
   #(56CB01BD.0008-1:kglatrvl.c,194,"add_to_index")  dooper <Y> atom <N> multi <N> noscale <N>
   #(56CB01BD.0009-1:kglatrvl.c,194,"add_to_index")  slot <node>
   #(56CB01BD.000A-1:kglatrvl.c,194,"add_to_index")  affinity <%IBM.KTU                000000000100000000> format <>
   #(56CB01BD.000B-1:kglatrvl.c,194,"add_to_index")  enum count <0> required <N>
   #(56CB01BD.000C-1:kglatrvl.c,195,"add_to_index") Block <844D560> name <Diagnostic.Node> id <30001>
   #(56CB01BD.000D-1:kglatrvl.c,195,"add_to_index")  app <KTO> table <TODIAG> column <ORIGINNODE>
   #(56CB01BD.000E-1:kglatrvl.c,195,"add_to_index")  file <PRE-TF0101-KTO.ATR> timestamp <1130220133051000> line <8>
   #(56CB01BD.000F-1:kglatrvl.c,195,"add_to_index")  data type <2> entry type <0> sample type <3>
   #(56CB01BD.0010-1:kglatrvl.c,195,"add_to_index")  max <9223372036854775807> min <-9223372036854775808> str len <32> end codes <0>
   #(56CB01BD.0011-1:kglatrvl.c,195,"add_to_index")  scale <0> prec <0> cost <0> order <-1>
   #(56CB01BD.0012-1:kglatrvl.c,195,"add_to_index")  dooper <Y> atom <N> multi <N> noscale <N>
   #(56CB01BD.0013-1:kglatrvl.c,195,"add_to_index")  slot <node>
   #(56CB01BD.0014-1:kglatrvl.c,195,"add_to_index")  affinity <%IBM.ITCAMfT_KTO        000000000100000000> format <>
   #(56CB01BD.0015-1:kglatrvl.c,195,"add_to_index")  enum count <0> required <N>
   if (substr($logunit,0,10) eq "kglatrvl.c") {
      if ($logentry eq "add_to_index") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Warning: attribute name conflict
         if (substr($rest,1,8) eq "Warning:") {
            $rest =~ / Warning\: (.*)/;
            $atr_warn = $1;
            $atr_warn =~ s/\s+$//;                    # strip trailing blanks
            $atr_ref = $atrwx{$atr_warn};
            if (!defined $atr_ref) {
               my %atrref = (
                               atrname => {},
                               count => 0,
                            );
               $atr_ref = \%atrref;
               $atrwx{$atr_warn} = \%atrref;
            }
            $atr_ref->{count} += 1;
            next;
         }
         #  Block <844D560> name <Diagnostic.Node> id <30001>
         if (substr($rest,1,5) eq "Block") {
            $rest =~ /name \<(\S+)\>/;
            $atr_name = $1;

         # app <KTO> table <TODIAG> column <ORIGINNODE>
         } elsif (substr($rest,1,4) eq " app") {
            $rest =~ /app \<(\S+)\> table \<(\S+)\> column \<(\S+)\>/;
            $atr_app = $1;
            $atr_table = $2;
            $atr_column = $3;

         #  file <KTU.ATR> timestamp <1121121120356000> line <8>
         } elsif (substr($rest,1,5) eq " file") {
            $rest =~ /file \<(\S+)\>/;
            $atr_file = $1;
            $atr_ref = $atrwx{$atr_warn};
            $atrn_ref = $atr_ref->{atrname}{$atr_name};
            if (!defined $atrn_ref) {
               my %atrnref = (
                                file => {},
                                count => 0,
                             );
              $atrn_ref = \%atrnref;
              $atr_ref->{atrname}{$atr_name} = \%atrnref;
            }
            $atrn_ref->{count} += 1;

            $atrf_ref = $atrn_ref->{file}{$atr_file};
            if (!defined $atrf_ref) {
               my %atrfref = (
                                app => $atr_app,
                                table => $atr_table,
                                column => $atr_column,
                                count => 0,
                             );
              $atrf_ref = \%atrfref;
              $atrn_ref->{file}{$atr_file} = \%atrfref;
            }
            $atrf_ref->{count} += 1;
            $atrwx_ct += 1;
         }
         next;
      }
   }

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

   #(57A0B2C2.000D-48:kfastinh.c,1187,"KFA_InsertNodests") Sending Node Status : node <vsmp8288:VA                     > nodetype <V> thrunode <remote_apsp0562                 > expiryint <-1> expirytime <9               > online <  > o4online <Y> product <VA> version <06.20.01> affinities <00000000G000000000000000000000000400004w0a7 > hostinfo <AIX~6.1         > hostloc <                > hostaddr <ip.pipe:#10.125.108.65[57760]<NM>vsmp8288</NM>                                                                                                                                                                                                                  > reserved <A=02:aix523;C=06.20.01.00:aix523;G=06.20.01.00:aix523;          > hrtbeattime <1160802094349000>
   if (substr($logunit,0,10) eq "kfastinh.c") {
      if ($logentry eq "KFA_InsertNodests") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Sending Node Status : node <vsmp8288:VA                     > nodetype <V> thrunode <remote_apsp0562                 > expiryint <-1> expirytime <9               > online <  > o4online <Y> product <VA> version <06.20.01> affinities <00000000G000000000000000000000000400004w0a7 > hostinfo <AIX~6.1         > hostloc <                > hostaddr <ip.pipe:#10.125.108.65[57760]<NM>vsmp8288</NM>                                                                                                                                                                                                                  > reserved <A=02:aix523;C=06.20.01.00:aix523;G=06.20.01.00:aix523;          > hrtbeattime <1160802094349000>
         if (substr($rest,1,19) eq "Sending Node Status") {
            $rest =~ /node <(.*?)> nodetype <(.*?)> thrunode <(.*?)> expiryint <(.*?)> expirytime <(.*?)> online <(.*?)> o4online <(.*?)> product <(.*?)> version <(.*?)> affinities <(.*?)> hostinfo <(.*?)> hostloc <(.*?)> hostaddr <(.*?)> reserved <(.*?)> hrtbeattime <(.*?)>/;
            my $inode = $1;
            my $inodetype = $2;
            my $ithrunode = $3;
            my $iexpiryint = $4;
            my $iexpirytime = $5;
            my $online = $6;
            my $io4online = $7;
            my $iproduct = $8;
            my $iversion = $9;
            my $iaffinities = $10;
            my $ihostinfo = $11;
            my $ihostloc = $12;
            my $ihostaddr = $13;
            my $ireserved = $14;
            my $ihrtbeattime = $15;
            if (($opt_ss == 1) and ($iproduct ne "EM")){
               $outl = "KFA_InsertNodests,";
               $outl .= $logtime . ",";
               $outl .= $inode . ",";
               $outl .= $inodetype . ",";
               $outl .= $ithrunode . ",";
               $outl .= $iexpiryint . ",";
               $outl .= $iexpirytime . ",";
               $outl .= $online . ",";
               $outl .= $io4online . ",";
               $outl .= $iproduct . ",";
               $outl .= $iversion . ",";
               $outl .= $iaffinities . ",";
               $outl .= $ihostinfo . ",";
               $outl .= $ihostloc . ",";
               $outl .= $ihostaddr . ",";
               $outl .= $ireserved . ",";
               $outl .= $ihrtbeattime . ",";
               $ssi++;$ssout[$ssi] = $outl;
            }
            $inode =~ s/\s+$//;                    # strip trailing blanks
            $ithrunode =~ s/\s+$//;                    # strip trailing blanks
            $iaffinities =~ s/\s+$//;                    # strip trailing blanks
            $ihostaddr =~ s/\s+$//;                    # strip trailing blanks
            $iexpirytime =~ s/\s+$//;                    # strip trailing blanks
            next if $iproduct eq "EM";
            my $inode_ref = $inodex{$inode};
            if (!defined $inode_ref) {
               my %inoderef = (
                                 count => 0,
                                 instances => {},
                              );
                $inode_ref = \%inoderef;
                $inodex{$inode} = \%inoderef;
            }
            $inode_ref->{count} += 1;
            my $inodeikey = $ihostaddr . "|" . $iaffinities . "|" . $ithrunode;
            my $inodei_ref = $inode_ref->{instances}{$inodeikey};
            if (!defined $inodei_ref) {
               my %inodeiref = (
                                 hostaddr => $ihostaddr,
                                 affinities => $iaffinities,
                                 thrunode => $ithrunode,
                                 version => $iversion,
                                 reserved => $ireserved,
                                 expirytime => $iexpirytime,
                                 product => $iproduct,
                                 o4online => $io4online,
                                 count => 0,
                              );
                $inodei_ref = \%inodeiref;
                $inode_ref->{instances}{$inodeikey} = \%inodeiref;
            }
            $inodei_ref->{count} += 1;
            # cross-ref with pcbx
            $ihostaddr =~ /:#(\S+)\[(\S+)\]/;
            my $ip_addr = $1;
            if (defined $ip_addr) {
               my $pcb_ref = $pcbx{$ip_addr};
               if (defined $pcb_ref) {
                  $pcb_ref->{agents}{$inode} += 1;
               }
            }
         }
      }
   }
   # (58DE3A4E.007A-12:kcfccmmt.cpp,674,"CMConfigMgrThread::indicateBackground") Error in pthread_attr_setschedparam,
   if (substr($logunit,0,3) eq "kcf") {
      $kcf_count += 1;
      next;
   }

   #(569D717B.007C-4A:kglkycbt.c,1212,"kglky1ar") iaddrec2 failed - status = -1, errno = 9,file = QA1CSTSC, index = PrimaryIndex, key = qbe_prd_ux_systembusy_c         TEMSP01
   #(57F7D605.003B-C:kglkycbt.c,1212,"kglky1ar") iaddrec2 failed - status = -1, errno = 9,file = QA1CNODL, index = PrimaryIndex, key = *ALL_ORACLE                     CCBCFG2:tr2_au02qdb251teax2:ORA
   #(569C6BDD.001D-26:kglkycbt.c,1498,"kglky1dr") idelrec failed - status = -1, errno = 0,file = RKCFAPLN, index = PrimaryIndex
   #(57DAB05B.000E-6:kglkycbt.c,2091,"InitReqObj") Open index failed. errno = 12,file = QA1CSTSH. index = PrimaryIndex,
   #(58B7E159.0002-3:kglkycbt.c,835,"kglky1rs") isam error. errno = 7.file = QA1CSITF, index = PrimaryIndex,
   #(58DD7571.002C-1:kglisopn.c,949,"I_ifopen") Verify of QA1CNODL.IDX failed
   if (substr($logunit,0,10) eq "kglkycbt.c") {
      if ($logentry eq "kglky1ar") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # iaddrec2 failed - status = -1, errno = 9,file = QA1CSTSC, index = PrimaryIndex, key = qbe_prd_ux_systembusy_c
         next if substr($rest,1,15) ne "iaddrec2 failed";
         $rest =~ /file \= (\S+),/;
         $etable = $1;
         next if !defined $etable;
         my $etable_ref = $etablex{$etable};
         if (!defined $etable_ref) {
            my %etableref = (
                               count => 0,
                            );
            $etablex{$etable} = \%etableref;
            $etable_ref = \%etableref;
         }
         $etable_ref->{count} += 1;
         next;
      }
      if ($logentry eq "InitReqObj") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Open index failed. errno = 12,file = QA1CSTSH. index = PrimaryIndex,
         next if substr($rest,1,18) ne "Open index failed.";
         $rest =~ /file \= (\S+)\./;
         $etable = $1;
         next if !defined $etable;
         my $itable_ref = $itablex{$etable};
         if (!defined $itable_ref) {
            my %itableref = (
                               count => 0,
                            );
            $itablex{$etable} = \%itableref;
            $itable_ref = \%itableref;
         }
         $itable_ref->{count} += 1;
         next;
      }
      if ($logentry eq "kglky1dr") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # idelrec failed - status = -1, errno = 0,file = RKCFAPLN, index = PrimaryIndex
         if (substr($rest,1,14) eq "idelrec failed") {
            $rest =~ /file \= (\S+),/;
            $etable = $1;
            next if !defined $etable;
            my $etable_ref = $etablex{$etable};
            if (!defined $etable_ref) {
               my %etableref = (
                                  count => 0,
                               );
               $etablex{$etable} = \%etableref;
               $etable_ref = \%etableref;
            }
            $etable_ref->{count} += 1;
            next;
         }
      }
      if ($logentry eq "kglky1rs") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # isam error. errno = 7.file = QA1CSITF, index = PrimaryIndex,
         if (substr($rest,1,11) eq "isam error.") {
            $rest =~ /file \= (\S+),/;
            $etable = $1;
            next if !defined $etable;
            my $etable_ref = $etablex{$etable};
            if (!defined $etable_ref) {
               my %etableref = (
                                  count => 0,
                               );
               $etablex{$etable} = \%etableref;
               $etable_ref = \%etableref;
            }
            $etable_ref->{count} += 1;
            next;
         }
      }
   }

   #(568A71C2.0000-C5:kglisadd.c,219,"iaddrec2") Duplicate key for index PrimaryIndex,U in QA1CSITF.IDX
   if (substr($logunit,0,10) eq "kglisadd.c") {
      if ($logentry eq "iaddrec2") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Duplicate key for index PrimaryIndex,U in QA1CSITF.IDX
         if (substr($rest,1,13) eq "Duplicate key") {
            $rest =~ / in (\S+)\.IDX/;
            $dtable = $1;
            next if !defined $dtable;
            my $dtable_ref = $dtablex{$dtable};
            if (!defined $dtable_ref) {
               my %dtableref = (
                                  count => 0,
                               );
               $dtablex{$dtable} = \%dtableref;
               $dtable_ref = \%dtableref;
            }
            $dtable_ref->{count} += 1;
            next;
         }
      }
   }

   #(58DD7571.002C-1:kglisopn.c,949,"I_ifopen") Verify of QA1CNODL.IDX failed
   if (substr($logunit,0,10) eq "kglisopn.c") {
      if ($logentry eq "I_ifopen") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Verify of QA1CNODL.IDX failed
         if (substr($rest,1,9) eq "Verify of") {
            $rest =~ / of (\S+)\.IDX/;
            $vtable = $1;
            next if !defined $vtable;
            my $vtable_ref = $vtablex{$vtable};
            if (!defined $vtable_ref) {
               my %vtableref = (
                                  count => 0,
                               );
               $vtablex{$vtable} = \%vtableref;
               $vtable_ref = \%vtableref;
            }
            $vtable_ref->{count} += 1;
            next;
         }
      }
   }

   # (587E44A6.0002-7:kdsruc1.c,6623,"GetRule") Read error status: 5 reason: 26 Rule name: KOY.VKOYSRVR
   if (substr($logunit,0,9) eq "kdsruc1.c") {
      if ($logentry eq "GetRule") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  Read error status: 5 reason: 26 Rule name: KOY.VKOYSRVR
         if (substr($rest,1,10) eq "Read error") {
            $rest =~ / name: (\S+)/;
            $rdtable = $1;
            next if !defined $rdtable;
            my $rdtable_ref = $rdtablex{$rdtable};
            if (!defined $rdtable_ref) {
               my %rdtableref = (
                                   count => 0,
                                );
               $rdtablex{$rdtable} = \%rdtableref;
               $rdtable_ref = \%rdtableref;
            }
            $rdtable_ref->{count} += 1;
            next;
         }
      }
   }

   #(5754ECFD.0022-A:kfaotmgr.c,91,"KFAOT_EIF_Manager") Event send to destination <0> failed. status <8>
   if (substr($logunit,0,10) eq "kfaotmgr.c") {
      if ($logentry eq "KFAOT_EIF_Manager") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Event send to destination <0> failed. status <8>
         if (substr($rest,1,10) eq "Event send") {
            $rest =~ / \<(\d+)\> failed\./;
            $derror = $1;
            next if !defined $derror;
            my $derror_ref = $derrorx{$derror};
            if (!defined $derror_ref) {
               my %derrorref = (
                                  count => 0,
                               );
               $derrorx{$derror} = \%derrorref;
               $derror_ref = \%derrorref;
            }
            $derror_ref->{count} += 1;
            next;
         }
      }
   }

   #(56BC3268.0000-15:kfastins.c,1391,"KFA_PutSitRecord") ***ERROR: for RRN <6076>, (oldest) Index TS <                > does not match TSITSTSH TS <1160209223543004>
   if (substr($logunit,0,10) eq "kfastins.c") {
      if ($logentry eq "KFA_PutSitRecord") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # ***ERROR: for RRN <6076>, (oldest) Index TS <                > does not match TSITSTSH TS <1160209223543004>
         if (substr($rest,1,17) eq "***ERROR: for RRN") {
            # ignore case where message is split on two lines
            if (index($rest," does not match ") != -1) {
               $rest =~/ Index TS \<(.*?)\> .*does not match (.*?) /;
               $rindex = $1;
               next if !defined $rindex;        ## die
               $rtable = $2;
               next if !defined $rtable;        ## die
               my $teststr = $rindex;
               $teststr =~ s/0123456789//g;

               my $rtable_ref = $rtablex{$rtable};
               if (!defined $rtable_ref) {
                  my %rtableref = (
                                     count => 0,
                                     badindex => 0,
                                  );
                  $rtablex{$rtable} = \%rtableref;
                  $rtable_ref = \%rtableref;
               }
               $rtable_ref->{count} += 1 if $teststr eq "";
               $rtable_ref->{badindex} += 1 if $teststr ne "";
            }
            next;
         }
      }
   }

   # (58C49DE0.0000-B:kqmchkpt.cpp,619,"checkPoint::setGblTimestamp") Invalid checkpoint timestamp - ignoring. NAME = <M:LOCALNODESTS> TIMESTAMP <1170312020051000>,
   if (substr($logunit,0,12) eq "kqmchkpt.cpp") {
      if ($logentry eq "checkPoint::setGblTimestamp") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Invalid checkpoint timestamp - ignoring. NAME = <M:LOCALNODESTS> TIMESTAMP <1170312020051000>,
         next if substr($rest,1,28) ne "Invalid checkpoint timestamp";
         $invalid_checkpoint_count += 1;
         next;
      }
   }

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
         next;
      }


      # (590DD139.0000-C5:kfaprpst.c,3649,"NodeStatusRecordChange") Host info/loc/addr change detected for node <uuc_wtwavwq9:06                 > thrunode <REMOTE_usitmpl8057-itm2         > hostAddr: <ip.spipe:#192.168.10.72[4206]<NM>uuc_wtwavwq9</NM>          >
      # (59103772.0000-C9:kfaprpst.c,3618,"NodeStatusRecordChange") Affinities change detected for node <uuc_scent5010:NT                > thrunode <REMOTE_usitmpl8044              > hostAddr: <ip.spipe:#10.188.5.10[60467]<NM>uuc_scent5010</NM>          >
      # (590D97C3.0002-69:kfaprpst.c,3632,"NodeStatusRecordChange") Version change detected for node <CustomMSG:uuc_uswasx3c8:LO      > thrunode <REMOTE_usitmpl8047              > hostAddr: <ip.spipe:#10.56.38.101[34393]<NM>uuc_uswasx3c8</NM>         >
      # (5907C6CF.0001-28:kfaprpst.c,3582,"NodeStatusRecordChange") Thrunode change detected for node <CustomMSG:uuc_ussaspa601:LO     > thrunode <REMOTE_usitmpl8055              > Old thrunode <REMOTE_usitmpl8054              > hostAddr: <ip.spipe:#10.113.3.8[63646]<NM>uuc_ussaspa601</NM>          >
      if ($logentry eq "NodeStatusRecordChange") {
         if ($opt_flip == 1) {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       #  Host info/loc/addr change detected for node <uuc_wtwavwq9:06                 > thrunode <REMOTE_usitmpl8057-itm2         > hostAddr: <ip.spipe:#192.168.10.72[4206]<NM>uuc_wtwavwq9</NM>          >
            if (index($rest,"for node") != -1) {
               $rest =~ / (.*?) change detected for node \<(.*?)\>(.+)$/;
               my $idesc = $1;
               my $inode = $2;
               $rest = $3;
               $rest =~ /thrunode \<(.*?)\>(.+)$/;
               my $ithrunode = $1;
               $rest = $2;
               $ithrunode =~ s/\s+$//;                    # strip trailing blanks
               if (index($ithrunode," ") != -1) {
                  $ithrunode =~ /(.*?) /;
                  $ithrunode = $1;
               }
               my $ioldthrunode = "";
               if (index($rest,"Old thrunode") != -1) {
                  $rest =~ /Old thrunode \<(.*?)\>(.+)$/;
                  $ioldthrunode = $1;
                  $rest = $2;
               }
               $rest =~ /hostAddr\: \<(.*?)\[/;
               my $ihostaddr = $1;
               $ihostaddr = "" if !defined $1;
               $inode =~ s/\s+$//;   #trim trailing whitespace
               $ithrunode =~ s/\s+$//;   #trim trailing whitespace
               $ioldthrunode =~ s/\s+$//;   #trim trailing whitespace
               $ihostaddr =~ s/\s+$//;   #trim trailing whitespace
               my $change_ref = $changex{$idesc};
               $changex_ct += 1;
               if (!defined $change_ref) {
                  my %changeref = (
                                     count => 0,
                                     nodes => {},
                                  );
                  $change_ref = \%changeref;
                  $changex{$idesc} = \%changeref;
               }
               $change_ref->{count} += 1;
               my $change_node_ref = $change_ref->{nodes}{$inode};
               if (!defined $change_node_ref) {
                  my %changenoderef = (
                                         count => 0,
                                         instances => {},
                                  );
                  $change_node_ref = \%changenoderef;
                  $change_ref->{nodes}{$inode} = \%changenoderef;
               }
               $change_node_ref->{count} += 1;
               my $changekey = $ithrunode . "|" . $ihostaddr;
               my $change_instance_ref = $change_node_ref->{instances}{$changekey};
               if (!defined $change_instance_ref) {
                  my %changeinstanceref = (
                                             count => 0,
                                             hostaddr =>$ihostaddr,
                                             thrunode =>$ithrunode,
                                             oldthrunode =>$ioldthrunode,
                                  );
                  $change_instance_ref = \%changeinstanceref;
                  $change_node_ref->{instances}{$changekey} = \%changeinstanceref;
               }
               $change_instance_ref->{count} += 1;
               next;
            }
         }
      }
   }

   # (591116EF.0000-EEC:kdspmcat.c,979,"CompilerCatalog") Column ATFSTAT in Table LIMS_SYSS for Application KIP Not Found.
   if (substr($logunit,0,10) eq "kdspmcat.c") {
      if ($logentry eq "CompilerCatalog") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Column ATFSTAT in Table LIMS_SYSS for Application KIP Not Found.
         if (substr($rest,-10) eq "Not Found.") {
            if (substr($rest,1,6) eq "Column") {
               $rest =~ /Column (\S+) in Table (\S+) for Application (\S+) /;
               my $icolumn = $1;
               my $itable = $2;
               my $iapp = $3;
               my $key = $3 . "|" . $2 . "|" . $1;
               $misscolx{$key} += 1;
               next;
            }
         }
      }
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
               # the following logic is used to avoid issues with data on continued lines.
               if (substr($rest,-1,1) eq ">") {                         # ignore continued lines for the moment
                  if (length($rest) > 241) {                            # ignore short lines
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
         my $isql = $1;
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
   #(59082197.0003-2B7:kshhttp.cpp,493,"writeSoapErrorResponse") faultstring: CMS logon validation failed.
   #(59082197.0004-2B7:kshhttp.cpp,523,"writeSoapErrorResponse") Client: ip.ssl:#158.98.69.8:42858
   if (substr($logunit,0,11) eq "kshhttp.cpp") {
      if ($logentry eq "writeSoapErrorResponse") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # faultstring: CMS logon validation failed.
                                           # Client: ip.ssl:#158.98.69.8:42858
         if (substr($rest,1,12) eq "faultstring:") {
            $rest =~ /: (.*)/;
            $soaperror_fault = $1 if defined $1;
            next;
         } elsif (substr($rest,1,7) eq "Client:") {
            $rest =~ /: (.*):/;
            $soaperror_client = $1 if defined $1;
            if ($soaperror_fault ne "") {
                my $soaperror_ref = $soaperror{$soaperror_fault};
                if (!defined $soaperror_ref) {
                   my %soaperrorref = (
                                         count => 0,
                                         clients => {},
                                      );

                   $soaperror_ref = \%soaperrorref;
                   $soaperror{$soaperror_fault} = \%soaperrorref;
                }
                $soaperror_ref->{count} += 1;
                my $client_ref = $soaperror_ref->{clients}{$soaperror_client};
                if (!defined $client_ref) {
                   my %clientref = (
                                      count => 0,
                                   );

                   $client_ref = \%clientref;
                   $soaperror_ref->{clients}{$soaperror_client} = \%clientref;
                }
                $client_ref->{count} += 1;
            }
            next;
         }
      }
   }

   #(591ACD2E.0000-7C:kshcat.cpp,296,"RetrieveTableByTableName") Unable to get attributes for table tree TOBJACCL
   if (substr($logunit,0,10) eq "kshcat.cpp") {
      if ($logentry eq "RetrieveTableByTableName") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Unable to get attributes for table tree TOBJACCL
         if (substr($rest,1,24) eq "Unable to get attributes") {
            $rest =~ /table tree (\S+)$/;
            my $itable = $1;
            if (defined $itable) {
               $soapcat{$itable} += 1;
            }
            next;
         }
      }
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
   # (56F2B983.0007-1F:kdspmcat.c,449,"CompilerCatalog") Table name TAPPLPROPS for  Application O4SRV Not Found.
   if (substr($logunit,0,10) eq "kdspmcat.c") {
      if ($logentry eq "CompilerCatalog") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Table name TAPPLPROPS for  Application O4SRV Not Found.
         next if substr($rest,1,10) ne "Table name";
         $rest =~ / Table name (\S+) for  Application (\S+) /;
         my $itable = $1;
         my $iappl = $2;
         my $ikey = $iappl . "." . $itable;
         $miss_tablex{$ikey} = 0 if ! defined $miss_tablex{$ikey};
         $miss_tablex{$ikey} += 1;
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
         $rest =~ /KGLCB_FSYNC_ENABLED\=\'(\S+)\'$/;
         my $test_fsync = $1;
         if (defined $test_fsync) {
             if ($test_fsync !~ /^\d+$/) {
                $advi++;$advonline[$advi] = "KGLCB_FSYNC_ENABLED is not numeric [$test_fsync]";
                $advcode[$advi] = "TEMSAUDIT1059W";
                $advimpact[$advi] = $advcx{$advcode[$advi]};
                $advsit[$advi] = "TEMS";
             }
         } else {
            $fsync_enabled = $test_fsync;
         }
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
   #(578F8F57.0001-6:ko4sit.cpp,1573,"Situation::slice") Error : Sit SAPNP_SAP_BO_Process_Down : reflex emulation command returned 4.
   if (substr($logunit,0,10) eq "ko4sit.cpp") {
      if ($logentry eq "Situation::slice") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                                # Error : Sit SAPNP_SAP_BO_Process_Down : reflex emulation command returned 4.
         if (substr($rest,1,11) eq "Error : Sit") {
            $rest =~ /Error : Sit (\S+).*?returned (\d+)\./;
            my $isit = $1;
            my $istatus = $2;
            my $reflex_ref = $reflexx{$isit};
            if (!defined $reflex_ref) {
               my %reflexref = (
                                  status => $istatus,
                                  count => 0,
                               );
               $reflex_ref = \%reflexref;
               $reflexx{$isit} = \%reflexref;
            }
            $reflex_ref->{count} += 1;
         }
      }
   }

   #(58E42EB8.0000-1110:kdsdscom.c,196,"VDM1_Malloc") GMM1_AllocateStorage failed - 1
   if (substr($logunit,0,10) eq "kdsdscom.c") {
      if ($logentry eq "VDM1_Malloc") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,27) eq "GMM1_AllocateStorage failed") {             # Storage Allocation Failure in TEMS
            $gmm_total += 1;
            next;
         }
      }
   }

   #(577D74E2.0000-1A:kfavalid.c,512,"validate") Invalid character discovered.  Integer value:<34> at position 0.
   #(577D74E2.0001-1A:kfavalid.c,575,"ValidateNodeEntry") Validation for node failed.
   #(577D74E2.0002-1A:kfavalid.c,1017,"KFA_InvalidNameMessage") Unsupported Nodelist or Node Status record.  Contents follow:
   #(577D74E2.0003-1A:kfavalid.c,1020,"KFA_InvalidNameMessage") <0x2B483CE0BDF0,0x20> Nodelist/Node contents:
   #+577D74E2.0003     00000000   22697463 616D2D70  6F6C6C65 722D766D   "itcam-poller-vm
   #+577D74E2.0003     00000010   2D30322D 76656761  73223A54 36202020   -02-vegas":T6...
   #(577D74E2.0004-1A:kfavalid.c,1028,"KFA_InvalidNameMessage") <0x2B483CE0BE5E,0x20> Node/Thrunode contents:
   if (substr($logunit,0,10) eq "kfavalid.c") {
      if ($logentry eq "validate") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,17) eq "Invalid character") {             # starting a new command capture
             my %valref = (                                  # anonymous hash for command capture
                             thread => $logthread,           # Thread id associated with command capture
                             start => $logtime,              # Decimal time start
                             state => 1,                     # state = 1 means looking for command text
                             stamp => $logtimehex,           # stamp - hex time
                             val => "",                      # collected command text
                             val_type => "",                 # type of validation failure
                          );
             $valx{$logthread} = \%valref;
             $valkey = $logtimehex . "." . $logline;
             $vcontx{$valkey} = \%valref;
         }
      } elsif ($logentry eq "ValidateNodeEntry") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         $val_ref = $valx{$logthread};
         if (defined $val_ref) {
            $val_ref->{val_type} = $rest;
         }
      } elsif ($logentry eq "KFA_InvalidNameMessage") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,1) eq "<") {
            if (index($rest,"Nodelist/Node contents:") >= 0) {
               $contkey = $logtimehex . "." . $logline;
               $vcontx{$contkey} = $runref;
               $val_ref = $valx{$logthread};
               if (defined $val_ref) {
                  $val_ref->{state} = 2;
                  $contkey = $logtimehex . "." . $logline;
                  $vcontx{$contkey} = $val_ref;
               }
            } elsif (index($rest,"Node/Thrunode contents:") >= 0) {
               $val_ref = $valx{$logthread};
               if (defined $val_ref) {
                  my $nodev = $val_ref->{val};
                  my $valv_ref = $valvx{$nodev};
                  if (!defined $valv_ref) {
                     my %valvref = (
                                      count => 0,
                                      type => $val_ref->{val_type},
                                   );
                     $valvx{$nodev} = \%valvref;
                     $valv_ref  = \%valvref;
                  }
                  $valv_ref->{count} += 1;
                  delete $valx{$logthread};
               }
            }
         }
      }
      next;
   }


   if (substr($logunit,0,10) eq "kdssqprs.c") {
      if ($logentry eq "PRS_ParseSql") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (defined $2) {
            $sqlrun_ref = $sqlrunx{$logthread};
            if (defined $sqlrun_ref) {
               # if we are starting a new capture while one currently is running, extract the SQL for resport
               if (substr($rest,1,14) eq "SQL source is:" or substr($rest,1,19) eq "SQL to be parsed is") {
                  if ($sqlrun_ref->{state} == 2) { # state 2 means an SQL has been captured
                     capture_sqlrun($sqlrun_ref); #completed an sqlrun capture
                     delete $sqlrunx{$logthread};
                  }
               }
            }
            if (substr($rest,1,14) eq "SQL source is:") { # SQL source is: User=SRVR01 Net=ip.spipe:#146.243.106.75[3660].
               $rest =~ / is: (.*)$/;
               $sql_source = $1 if defined $1;
               $sql_source = "" if !defined $1;
               $sql_source =~ s/\s+$//;                              # strip trailing blanks
               $sqlrun_ref = $sqlrunx{$logthread};
               if (!defined $sqlrun_ref) {
                  my %sqlrunref = (
                                     state => 0,
                                     start => $logtime,
                                     frag => "",
                                     source => $sql_source,
                                     pos => $l,
                                  );
                  $sqlrun_ref = \%sqlrunref;
                  $sqlrunx{$logthread} = \%sqlrunref;
               }
               next;
            }
            if (substr($rest,1,19) eq "SQL to be parsed is") { # SQL to be parsed is ... Ascii 0x00550000.
               $sqlrun_ref = $sqlrunx{$logthread};
               if (!defined $sqlrun_ref) {                # trace without METRICS so no source
                  my %sqlrunref = (
                                     state => 0,
                                     start => $logtime,
                                     frag => "",
                                     source => "NotAvailable",
                                     pos => $l,
                                  );
                  $sqlrun_ref = \%sqlrunref;
                  $sqlrunx{$logthread} = \%sqlrunref;
               }
               $sqlrun_ref->{state} = 1;      # enter capture mode
               next;
            }
            $sqlrun_ref = $sqlrunx{$logthread};
            if (defined $sqlrun_ref) {
               if ($sqlrun_ref->{state} >= 1) {
                  #(540CE6F4.0047-C:kdssqprs.c,658,"PRS_ParseSql") SELECT TRANSID,GBLTMSTMP,TARGETMSN,CMSNAME,RESERVED2,RETVAL,RETMSGPARM,G
                  $rest .= " " x 100;
                  $sqlrun_ref->{frag} .= substr($rest,1,72);
                  $sqlrun_ref->{state} = 2;      #Captured at least one fragment
                  next;
               }
            }
         }
      }
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
   $uadvisor_bytes += $insize if substr($isit,0,8) eq "UADVISOR";
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
         my $res_day  = '00' . (localtime($logstime))[3];
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
   if ($opt_rd == 1) {
      # calculate the slotted time stamp. This reuses some variables/logic in historical export slotting logic.
      $hist_min = (localtime($logtime))[1];
      $hist_min = int($hist_min/$opt_rdslot) * $opt_rdslot;
      $hist_min = '00' . $hist_min;
      $hist_hour = '00' . (localtime($logtime))[2];
      $hist_day  = '00' . (localtime($logtime))[3];
      $hist_month = (localtime($logtime))[4] + 1;
      $hist_month = '00' . $hist_month;
      $hist_year =  (localtime($logtime))[5] + 1900;
      $hist_stamp = $hist_year . substr($hist_month,-2,2) . substr($hist_day,-2,2) .  substr($hist_hour,-2,2) .  substr($hist_min,-2,2);
      $rd_ref = $rdx{$hist_stamp};
      if (!defined $rd_ref) {
         my %rdref = (
                        count => 0,
                        rows => 0,
                        bytes => 0,
                        sitx => {},
                     );
        $rd_ref = \%rdref;
        $rdx{$hist_stamp} = \%rdref;
      }
      $rd_ref->{count} += 1;
      $rd_ref->{rows} += $irows;
      $rd_ref->{bytes} += $insize;
      my $sit_ref = $rd_ref->{sitx}{$isit};
      if (!defined $sit_ref) {
         my %sitref = (
                         count => 0,
                         rows => 0,
                         bytes => 0,
                      );
        $sit_ref = \%sitref;
        $rd_ref->{sitx}{$isit} = \%sitref;
      }
      $sit_ref->{count} += 1;
      $sit_ref->{rows} += $irows;
      $sit_ref->{bytes} += $insize;
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

# capture sqlrun check
foreach my $f (keys %sqlrunx) {
   $sqlrun_ref = $sqlrunx{$f};
   if ($sqlrun_ref->{state} == 2) { # state 2 means an SQL has been captured
      capture_sqlrun($sqlrun_ref); #completed an sqlrun capture
   }
}
%sqlrunx = ();

$hdri++;$hdr[$hdri] = "$opt_nodeid $opt_tems";



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
      $advi++;$advonline[$advi] = "$ptoobigi Filter object(s) too big situations and/or reports";
      $advcode[$advi] = "TEMSAUDIT1001W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TooBig";
   }
if ($lp_high >= $opt_nominal_listen) {
   if ($lp_high >= $opt_max_listen) {
      $advi++;$advonline[$advi] = "Listen Pipe Usage at maximum [$opt_max_listen]";
      $advcode[$advi] = "TEMSAUDIT1002W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Pipes";
   }
   $advi++;$advonline[$advi] = "Listen Pipe above nominal[$opt_nominal_listen] listen=$lp_high balance=$lp_balance threads=$lp_threads pipes=$lp_pipes";
   $advcode[$advi] = "TEMSAUDIT1003W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Pipes";
}
if ($opt_nofile > 0) {
   if ($opt_nofile < $opt_nominal_nofile) {
      $advi++;$advonline[$advi] = "ulimit nofile [$opt_nofile] is below nominal [$opt_nominal_nofile]";
      $advcode[$advi] = "TEMSAUDIT1004W";
      $advcode[$advi] = "TEMSAUDIT1026E" if $opt_nofile <= 1024;
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Nofile";
   }
}
if ($opt_stack > 0) {
   if ($opt_stack > $opt_nominal_stack) {
      $advi++;$advonline[$advi] = "ulimit stack [$opt_stack] is above nominal [$opt_nominal_stack] (kbytes)";
      $advcode[$advi] = "TEMSAUDIT1005W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Stack";
   }
}

if ($opt_kbb_ras1 ne "") {
   my $test_ras1 = lc $opt_kbb_ras1;
   if (index($test_ras1,"error") == -1) {
      $advi++;$advonline[$advi] = "KBB_RAS1 missing the very important ERROR specification";
      $advcode[$advi] = "TEMSAUDIT1032E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Ras1";
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
if ($uadvisor_bytes>0) {
   $cnt++;$oline[$cnt]="Total UADVISOR (bytes),,,$uadvisor_bytes\n";
   my $res_pc = int(($uadvisor_bytes*100)/$sitres_tot);
   my $ppc = sprintf '%.0f%%', $res_pc;
   $cnt++;$oline[$cnt]="Total UADVISOR (percent),,,$res_pc\n";
   my $turespermin = int($uadvisor_bytes / ($dur / 60));
   $cnt++;$oline[$cnt]="Total UADVISOR per minute,,,$turespermin\n";
}

if ($trespermin > $opt_nominal_results) {
   $res_pc = int((($trespermin - $opt_nominal_results)*100)/$opt_nominal_results);
   my $ppc = sprintf '%.0f%%', $res_pc;
   $advi++;$advonline[$advi] = "Results bytes per minute $ppc higher then nominal [$opt_nominal_results]";
   $advcode[$advi] = "TEMSAUDIT1006E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Results";
   $res_max = 1;
}

$cnt++;$oline[$cnt]="\n";
$outl = "KBB_RAS1=" . $opt_kbb_ras1;
$cnt++;$oline[$cnt]=$outl . "\n";
if ($opt_kdc_debug ne "") {
   $outl = "KDC_DEBUG=" . $opt_kdc_debug;
   $cnt++;$oline[$cnt]=$outl . "\n";
   $opt_com_debug++;
}
if ($opt_kde_debug ne "") {
   $outl = "KDE_DEBUG=" . $opt_kde_debug;
   $cnt++;$oline[$cnt]=$outl . "\n";
   $opt_com_debug++;
}
if ($opt_kdh_debug ne "") {
   $outl = "KDH_DEBUG=" . $opt_kdh_debug;
   $cnt++;$oline[$cnt]=$outl . "\n";
   $opt_com_debug++;
}
if ($opt_kbs_debug ne "") {
   $outl = "KBS_DEBUG=" . $opt_kbs_debug;
   $cnt++;$oline[$cnt]=$outl . "\n";
   $opt_com_debug++;
}
if ($opt_com_debug > 0) {
   $advi++;$advonline[$advi] = "Communication Tracing set: only use on advisement";
   $advcode[$advi] = "TEMSAUDIT1038W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Trace";
}
$cnt++;$oline[$cnt]="Trace duration (seconds),,,$tdur\n";
my $trace_lines_minute = int($trace_ct / ($tdur / 60));
$cnt++;$oline[$cnt]="Trace Lines Per Minute,,,$trace_lines_minute\n";
my $trace_size_minute = int($trace_sz / ($tdur / 60));
$cnt++;$oline[$cnt]="Trace Bytes Per Minute,,,$trace_size_minute\n";
$cnt++;$oline[$cnt]="\n";
if ($trace_size_minute > $opt_nominal_trace) {
   $trc_pc = int((($trace_size_minute - $opt_nominal_trace)*100)/$opt_nominal_trace);
   my $ppc = sprintf '%.0f%%', $trc_pc;
   $advi++;$advonline[$advi] = "Trace bytes per minute $ppc higher then nominal $opt_nominal_trace";
   $advcode[$advi] = "TEMSAUDIT1007W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Trace";
}
my $syncdist_early = -1;
if ($syncdist > 0) {
   my $synctime_print = join("/",@syncdist_time);
   $cnt++;$oline[$cnt]="Remote SQL time outs,,,$syncdist,$synctime_print\n";
   $cnt++;$oline[$cnt]="\n";
   for (my $i = 0; $i >= $syncdist; $i++) {
      $syncdist_early += 1 if $syncdist_time[$i] < $opt_nominal_remotesql;
   }
   $advi++;$advonline[$advi] = "Remote SQL Time Outs - $syncdist";
   $advcode[$advi] = "TEMSAUDIT1027W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "RemoteSQL";
}

if ($syncdist_early > -1) {
      $advi++;$advonline[$advi] = "$syncdist_early early remote SQL failures";
      $advcode[$advi] = "TEMSAUDIT1008E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Sync";
   }

if ($stage2_ct > 2) {
   my $pct = int(($stage2_ct+1)/2);
   $advi++;$advonline[$advi] = "Reconnection from remote TEMS to hub TEMS - $pct times - $stage2";
   $advcode[$advi] = "TEMSAUDIT1036W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Reconnect";
}

if ($stage2_ct_err > 0) {
   $advi++;$advonline[$advi] = "Failed Reconnection from remote TEMS to hub TEMS - $stage2_ct_err times";
   $advcode[$advi] = "TEMSAUDIT1043E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Reconnect_Fail";
}

if ($portscan > 0) {
   my $scantype = "";
   $scantype .= "Unsupported(" . $portscan_Unsupported . ") " if $portscan_Unsupported > 0;
   $scantype .= "HTTP(" . $portscan_HTTP . ") " if $portscan_HTTP > 0;
   $scantype .= "integrity(" . $portscan_integrity . ") " if $portscan_integrity > 0;
   $scantype .= "suspend(" . $portscan_suspend . ") " if $portscan_suspend > 0;
   $advi++;$advonline[$advi] = "Indications of port scanning [$portscan] $scantype which can destabilize any ITM process including TEMS";
   $advcode[$advi] = "TEMSAUDIT1037E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Portscan";
}

if (($portscan_suspend + $portscan_72) > 0) {
   my $scantype = "";
   $scantype .= "suspend(" . $portscan_suspend . ") " if $portscan_suspend > 0;
   $scantype .= "72(" . $portscan_72 . ") " if $portscan_72 > 0;
   $advi++;$advonline[$advi] = "Definite Evidence of port scanning [$scantype] which can destabilize any ITM process including TEMS";
   $advcode[$advi] = "TEMSAUDIT1049E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Portscan";
}

if ($fsync_enabled == 0) {
      $advi++;$advonline[$advi] = "KGLCB_FSYNC_ENABLED set to 0 - risky for TEMS database files";
      $advcode[$advi] = "TEMSAUDIT1009E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "fsync";
   }

if ($kds_writenos eq "YES") {
      $advi++;$advonline[$advi] = "TEMS configured with KDS_WRITENOS=YES";
      $advcode[$advi] = "TEMSAUDIT1047W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "writenos";
   }

if ($lp_high != -1) {
   $cnt++;$oline[$cnt] = "Listen Pipe Report listen=$lp_high balance=$lp_balance threads=$lp_threads pipes=$lp_pipes\n";
   $cnt++;$oline[$cnt]="\n";
}

if ($nmr_total > 0) {
   $cnt++;$oline[$cnt]="Sample No Matching Request count,,,$nmr_total,\n";
   $cnt++;$oline[$cnt]="\n";
   $advi++;$advonline[$advi] = "$nmr_total \"No Matching Request\" samples";
   $advcode[$advi] = "TEMSAUDIT1010W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "NMR";
}

if ($anic_total > 0) {
   $cnt++;$oline[$cnt]="Activity Not In Call count,,,$anic_total,\n";
   $cnt++;$oline[$cnt]="\n";
   $advi++;$advonline[$advi] = "$anic_total \"activity not in call\" reports";
   $advcode[$advi] = "TEMSAUDIT1042E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "ANIC";
}

if ($gmm_total > 0) {
   $advi++;$advonline[$advi] = "Storage allocation [$gmm_total] failure(s)";
   $advcode[$advi] = "TEMSAUDIT1048E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "GMM";
}

if ($kcf_count > 0) {
   if ($opt_tems eq "*REMOTE") {
      $advi++;$advonline[$advi] = "MQ/Config or Config should run only on hub TEMS and is a remote TEMS";
      $advcode[$advi] = "TEMSAUDIT1046W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "KCF";
   }
}

my $pcb_total = 0;
my $pcb_deletePCB = 0;
foreach my $f (keys %pcbx) {
   my $pcb_ref = $pcbx{$f};
   $pcb_total += 1;
   next if $pcb_ref->{deletePCB} < 2;
   $pcb_deletePCB += 1;
}

if ($pcb_deletePCB > 0) {
   $advi++;$advonline[$advi] = "Agent connection churning on [$pcb_deletePCB] systems total[$pcb_total] - See following report";
   $advcode[$advi] = "TEMSAUDIT1050W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "PCB";

}

$soaperror_ct = scalar keys %soaperror;
if ($soaperror_ct > 0) {
   my $pcnt = $soaperror_ct + 1;
   $advi++;$advonline[$advi] = "SOAP Errors Types [$pcnt] Detected - See following report";
   $advcode[$advi] = "TEMSAUDIT1054W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "SOAP";

}


my $change_real = 0;
if ($changex_ct > 0) {
   foreach my $f ( sort { $a cmp $b } keys %changex) {
      my $change_ref = $changex{$f};
      foreach my $g (keys %{$change_ref->{nodes}}) {
         my $change_node_ref = $change_ref->{nodes}{$g};
         next if $change_node_ref->{count} < 2;
         $change_real += 1;
      }
   }
   if ($change_real > 0) {
      $advi++;$advonline[$advi] = "Agent Location Flipping Changes Detected [$change_real] - See following report";
      $advcode[$advi] = "TEMSAUDIT1055W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Agent";
   }
}

$misscolx_ct = scalar keys %misscolx;
if ($misscolx_ct > 0) {
   foreach my $f (keys %misscolx) {
      $advi++;$advonline[$advi] = "Missing Application/Table/Column $f $misscolx{$f} times";
      $advcode[$advi] = "TEMSAUDIT1056W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

if ($hublost_total > 0) {
   if ($opt_tems eq "*LOCAL" ) {
      $advi++;$advonline[$advi] = "Hub TEMS has lost connection to HUB $hublost_total times";
      $advcode[$advi] = "TEMSAUDIT1052E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "HUB";
   } else {
      $advi++;$advonline[$advi] = "Remote TEMS has lost connection to HUB $hublost_total times";
      $advcode[$advi] = "TEMSAUDIT1051E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "HUB";
   }
}

if ($intexp_total > 0) {
   $advi++;$advonline[$advi] = "Time interval expired late $intexp_total times";
   $advcode[$advi] = "TEMSAUDIT1053W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

foreach my $f (keys %soapcat) {
   $advi++;$advonline[$advi] = "Unable to get attributes for table $f [$soapcat{$f} times]";
   $advcode[$advi] = "TEMSAUDIT1067E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "SOAP";
}

if ($eipc_none > 0) {
   $advi++;$advonline[$advi] = "EIF unknown transmision target [none] $eipc_none times";
   $advcode[$advi] = "TEMSAUDIT1066W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

if ($mktime_total > 0) {
   $advi++;$advonline[$advi] = "Situation with *TIME returned invalid timestamp [$mktime_total] times";
   $advcode[$advi] = "TEMSAUDIT1065W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

if ($ruld_total > 0) {
   $advi++;$advonline[$advi] = "TEMS cannot create Rule tree [$ruld_total] times";
   $advcode[$advi] = "TEMSAUDIT1063E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

if ($gskit_nocipher > 0) {
   $advi++;$advonline[$advi] = "GSKIT Secure Communications - no common cipher found";
   $advcode[$advi] = "TEMSAUDIT1058E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Comm";
}

my $sit32_total = scalar keys %sit32x;
if ($sit32_total > 0) {
   $advi++;$advonline[$advi] = "Situations [$sit32_total] with length 32 - see following report";
   $advcode[$advi] = "TEMSAUDIT1060W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

my $sitrul_total = scalar keys %sitrulx;
if ($sitrul_total > 0) {
   foreach my $f (keys %sitrulx) {
      $sitrul_ref = $sitrulx{$f};
      $advi++;$advonline[$advi] = "Situation [$sitrul_ref->{sitname}] with unknown attribute [$sitrul_ref->{atr}] - [$sitrul_ref->{pdt}]";
      $advcode[$advi] = "TEMSAUDIT1061E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

my $nodeignore_total = scalar keys %node_ignorex;
if ($nodeignore_total > 0) {
   foreach my $f (keys %node_ignorex) {
      $advi++;$advonline[$advi] = "Node [$f] thrunode [$node_ignorex{$f}] ignored because attribute unknown";
      $advcode[$advi] = "TEMSAUDIT1062W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

my $sth_total = scalar keys %sthx;
if ($sth_total > 0) {
   foreach my $f (keys %sthx) {
      $advi++;$advonline[$advi] = "TEMS Short Term History file [$f] is broken [$sthx{$f}] times";
      $advcode[$advi] = "TEMSAUDIT1064E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

if ($seq999_total > 0) {
   $advi++;$advonline[$advi] = "Sequence Number Overflow $seq999_total times - rapid incoming events";
   $advcode[$advi] = "TEMSAUDIT1057W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

foreach my $f (keys %miss_tablex) {
   $advi++;$advonline[$advi] = "Application.table $f missing $miss_tablex{$f} times";
   $advcode[$advi] = "TEMSAUDIT1011W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Miss";
}

my $et = scalar keys %etablex;
if ($et > 0) {
   foreach my $f (keys %etablex) {
      my $etct = $etablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct errors";
      $advcode[$advi] = "TEMSAUDIT1022E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %dtablex;
if ($et > 0) {
   foreach my $f (keys %dtablex) {
      my $etct = $dtablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct Duplicate Record errors";
      $advcode[$advi] = "TEMSAUDIT1023W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

if ($invalid_checkpoint_count > 0) {
   $advi++;$advonline[$advi] = "TEMS TCHECKPT Timestamp invalid $invalid_checkpoint_count time(s)";
   $advcode[$advi] = "TEMSAUDIT1045W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "FTO";
}

$et = scalar keys %vtablex;
if ($et > 0) {
   foreach my $f (keys %vtablex) {
      my $etct = $vtablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct Verify Index errors";
      $advcode[$advi] = "TEMSAUDIT1044E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %rdtablex;
if ($et > 0) {
   foreach my $f (keys %rdtablex) {
      my $etct = $rdtablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table SITDB with $etct Read errors";
      $advcode[$advi] = "TEMSAUDIT1041E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %itablex;
if ($et > 0) {
   foreach my $f (keys %itablex) {
      my $etct = $itablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct Open Index errors";
      $advcode[$advi] = "TEMSAUDIT1040E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %rtablex;
if ($et > 0) {
   foreach my $f (keys %rtablex) {
      my $etct = $rtablex{$f}->{count};
      if ($etct > 0) {
         $advi++;$advonline[$advi] = "TEMS database table $f with $etct Relative Record Number errors";
         $advcode[$advi] = "TEMSAUDIT1024E";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = $f;
      }
      my $keyct = $rtablex{$f}->{badindex};
      if ($keyct > 0) {
         $advi++;$advonline[$advi] = "TEMS database table $f with $keyct Relative Record Number index errors";
         $advcode[$advi] = "TEMSAUDIT1031E";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = $f;
      }
   }
}

$et = scalar keys %derrorx;
if ($et > 0) {
   foreach my $f (keys %derrorx) {
      my $etct = $derrorx{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS Event Destination experienced $etct send errors";
      $advcode[$advi] = "TEMSAUDIT1025E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
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
         $advi++;$advonline[$advi] = "Situation high rate $respermin [$pfraction%]";
         $advcode[$advi] = "TEMSAUDIT1012W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = $sit[$i];
      }
   }
   $pfraction = sprintf "%.2f", $fraction;
   $outl .= $pfraction . "%,";
   $outl .= $sitrmin[$i] . ",";
   $outl .= $sitrmax[$i] . ",";
   if ($sitrmax[$i] >= $opt_max_results){
         $advi++;$advonline[$advi] = "Situation possible truncated results - max result $sitrmax[$i]";
         $advcode[$advi] = "TEMSAUDIT1013W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = $sit[$i];
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

if ($opt_rd == 1) {
   my $peakrate = 0;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Situation Result Over Time Report [Top $opt_rdtop situation contributors]\n";
   $cnt++;$oline[$cnt]="Time,Situation,Count,Rows,Bytes,Percent,Cumulative_Percent,\n";
   foreach $f ( sort { $a <=> $b } keys %rdx ) {
      my $ftime = time2sec($f . "00");
      $rd_start = $ftime if $rd_start eq "";
      $rd_end= $ftime;
      $rd_ref = $rdx{$f};
      $outl = $f . ",,";
      $outl .= $rd_ref->{count} . ",";
      $outl .= $rd_ref->{rows} . ",";
      $outl .= $rd_ref->{bytes} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $peakrate = $rd_ref->{bytes} if $rd_ref->{bytes} > $peakrate;
      my $toprd = 0;
      my $cum_bytes = 0;
      foreach $g ( sort { $rd_ref->{sitx}{$b}->{bytes} <=> $rd_ref->{sitx}{$a}->{bytes} || $a cmp $b } keys %{$rd_ref->{sitx}} ) {
         $sit_ref= $rd_ref->{sitx}{$g};
         last if $sit_ref->{bytes} == 0;
         $toprd += 1;
         last if $toprd > $opt_rdtop;
         $outl = "," . $g . ",";
         $outl .= $sit_ref->{count} . ",";
         $outl .= $sit_ref->{rows} . ",";
         $outl .= $sit_ref->{bytes} . ",";
         $cum_bytes += $sit_ref->{bytes};
         my $res_pc = ($sit_ref->{bytes}*100)/$rd_ref->{bytes};
         my $ppc = sprintf '%.2f%%', $res_pc;
         $outl .= $ppc . ",";
         $res_pc = ($cum_bytes*100)/$rd_ref->{bytes};
         $ppc = sprintf '%.2f%%', $res_pc;
         $outl .= $ppc . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
      $cnt++;$oline[$cnt]="\n";
   }

   if ($rd_start ne "") {
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="Situation Result Over Time Graph - peak rate is $peakrate bytes per minute\n";
      $cnt++;$oline[$cnt]="Each hour is shown, each column is a minute, numbers represent 10 minutes\n";
      $cnt++;$oline[$cnt]="\n";
      # calculate the epoch second when the first hour of results started
      my $rd_starttime = substr(sec2time($rd_start),0,10);
      my $rd_start_secs = time2sec($rd_starttime . "0000");

      # calculate the hour when the last result was observed
      my $rd_endtime = substr(sec2time($rd_end),0,10);
      my $rd_end_secs = time2sec($rd_endtime . "0000");

      # walk through each hour and produce a 10 high graph
      my $rd_curr_secs = $rd_start_secs;
      while ($rd_curr_secs <= $rd_end_secs) {
         my $stime = substr(sec2time($rd_curr_secs),0,10);
         my @rows;                      # produce 10 rows of
         for (my $r=10; $r>0; $r--) {
            for (my $s=0;$s<60;$s++) {
               my $ratekey = $stime . substr("00" . $s,-2,2);
               my $rd_ref = $rdx{$ratekey};
               if (!defined $rd_ref) {
                 $rows[$r] .= " ";
               } else {
                  my $mbyte = $rd_ref->{bytes} + int($peakrate/20);
                  my $tbyte = int($r*($peakrate/10));
                  if ($mbyte > $tbyte) {
                     $rows[$r] .= "+" if $r == 10;
                     $rows[$r] .= "." if $r < 10;
                  } else {
                     $rows[$r] .= " ";
                  }
               }
            }
         }
         for (my $r=10; $r>0; $r--) {
            $cnt++;$oline[$cnt]=" " x 11 . $rows[$r] . "\n";
         }
         $outl = $stime . " " . "0_________1_________2_________3_________4_________5__________";
         $cnt++;$oline[$cnt]=$outl . "\n";
         $cnt++;$oline[$cnt]="\n";
         $rd_curr_secs += 3600;
      }
   }
}

$et = scalar keys %codex;
if ($et > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Endpoint Communication Problem Report\n";
   $cnt++;$oline[$cnt]="Code,Text,Count,Source,Level\n";
   foreach my $f ( sort { $a cmp $b } keys %codex ) {
      $code_ref = $codex{$f};
      $outl = $f . ",";
      $outl .= $code_ref->{text} . ",";
      $outl .= $code_ref->{count} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      foreach my $g ( sort { $a cmp $b } keys %{$code_ref->{conv}} ) {
         my $conv_ref = $code_ref->{conv}{$g};
         $outl = ",," . $conv_ref->{count} . ",";
         $outl .= $g . ",";
         $outl .= $conv_ref->{level} . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
      $cnt++;$oline[$cnt]="\n";
   }
}

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
      if ($#act_max_cmds > 1) {
         my $pmax = $#act_max_cmds;
         $advi++;$advonline[$advi] = "Concurrent Action Commands - $pmax";
         $advcode[$advi] = "TEMSAUDIT1028W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "ActionCMDs";
      }
   }
}

my $sqlt_duration;
my $sql_ct_total = 0;
my $sql_duration;

if ($sqli != -1) {
   $sql_duration = $sql_end - $sql_start;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="SQL Summary Report\n";
   $cnt++;$oline[$cnt]="Count,SQL\n";
   foreach $f ( sort { $sql_ct[$sqlx{$b}] <=> $sql_ct[$sqlx{$a}] || $a cmp $b } keys %sqlx ) {
      $i = $sqlx{$f};
      $outl = $sql_ct[$i] . ",";
      $outl .= $sql_src[$i] . "," if $sql_src[$i] ne "";
      my $psql =  $sql[$i];
      $psql =~ s/\"/\'/g;
      $outl .= "\"" . $psql . "\",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $sql_ct_total += $sql_ct[$i];
   }
   $outl = "duration" . " " . $sql_duration . ",";
   $outl .= $sql_ct_total . ",";
   $cnt++;$oline[$cnt]=$outl . "\n";

   my $sql_rate;
   my $ppc;
   if ($opt_sqldetail == 1) {
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="SQL Detail Report\n";
      $cnt++;$oline[$cnt]="Type,Count,Duration,Rate/Min,Source,Table,SQL\n";
      $outl = "total" . ",";
      $outl .= $sql_ct_total . ",";
      $outl .= $sql_duration . ",";
      $sql_rate = ($sql_ct_total*60)/$sql_duration;
      $ppc = sprintf '%.2f', $sql_rate;
      $outl .= $ppc . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      foreach $f ( sort { $sqlsourcex{$b}->{count} <=> $sqlsourcex{$a}->{count} } keys %sqlsourcex ) {
         my $source_ref = $sqlsourcex{$f};
         $outl = "source" . ",";
         $outl .= $source_ref->{count} . ",";
         my $sql_dur = $source_ref->{end} - $source_ref->{start};
         $sql_dur = 1 if $sql_dur == 0;
         $outl .= $sql_dur . ",";
         $sql_rate = ($source_ref->{count}*60)/$sql_dur;
         my $ppc = sprintf '%.2f', $sql_rate;
         $outl .= $ppc . ",";
         $outl .= $f . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
         foreach $g ( sort { $source_ref->{tables}{$b}->{count} <=> $source_ref->{tables}{$a}->{count} } keys %{$source_ref->{tables}}) {
            my $table_ref = $source_ref->{tables}{$g};
            $outl = "table" . ",";
            $outl .= $table_ref->{count} . ",";
            $sql_dur = $table_ref->{end} - $table_ref->{start};
            $sql_dur = 1 if $sql_dur == 0;
            $outl .= $sql_dur . ",";
            $sql_rate = ($table_ref->{count}*60)/$sql_dur;
            $ppc = sprintf '%.2f', $sql_rate;
            $outl .= $ppc . ",,";
            $outl .= $g . ",";
            $cnt++;$oline[$cnt]=$outl . "\n";
            foreach $h ( sort { $table_ref->{sqls}{$b}->{count} <=> $table_ref->{sqls}{$a}->{count} } keys %{$table_ref->{sqls}}) {
               my $sql_ref = $table_ref->{sqls}{$h};
               $outl = "sql" . ",";
               $outl .= $sql_ref->{count} . ",";
               $sql_dur = $sql_ref->{end} - $sql_ref->{start};
               $sql_dur = 1 if $sql_dur == 0;
               $outl .= $sql_dur . ",";
               $sql_rate = ($sql_ref->{count}*60)/$sql_dur;
               $ppc = sprintf '%.2f', $sql_rate;
               $outl .= $ppc . ",,,";
               $outl .= $h . ",";
               $outl .= $sql_ref->{pos} . ",";
               $cnt++;$oline[$cnt]=$outl . "\n";
            }
         }
         $cnt++;$oline[$cnt]="\n";
      }
   }

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
      $advi++;$advonline[$advi] = "SOAP requests per minute $ppc higher then nominal $opt_nominal_soap";
      $advcode[$advi] = "TEMSAUDIT1014W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "SOAP";
   }
   if ($soap_burst_max > $opt_nominal_soap_burst) {
      $soap_pc = int((($soap_burst_max - $opt_nominal_soap_burst)*100)/$opt_nominal_soap_burst);
      my $ppc = sprintf '%.0f%%', $soap_pc;
      $advi++;$advonline[$advi] = "\"SOAP Burst requests per minute $ppc higher then nominal $opt_nominal_soap_burst at line $soap_burst_max_l in $soap_burst_max_log\"";
      $advcode[$advi] = "TEMSAUDIT1015W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "SOAP";
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
   $advi++;$advonline[$advi] = "$agto_mult Agents with repeated onlines";
   $advcode[$advi] = "TEMSAUDIT1016W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Onlines";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Multiple Agent online Report - top 20 max\n";
   $cnt++;$oline[$cnt]="Node,Online_Count\n";
   my $top_online = 20;
   my $top_current = 0;
   foreach $f ( sort { $agto_ct[$agtox{$b}] <=> $agto_ct[$agtox{$a}] } keys %agtox) {
      my $ai = $agtox{$f};
      $top_current += 1;
      last if $top_current > $top_online;
      last if $agto_ct[$ai] == 1;
      $outl = $f . ",";
      $outl .= $agto_ct[$ai] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $agto_mult_hr += 1;
   }
   $cnt++;$oline[$cnt]="$agto_dur,$agto_mult_hr,\n";
}

my $invi = keys %valvx;
if ($invi > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Invalid Node Name Report\n";
   $cnt++;$oline[$cnt]="Node,Count,Type\n";
   foreach $f (sort {$a cmp $b} keys %valvx) {
# 1.37000 - add 1025E for send event failures, prepare for AOA usage
      $outl = $f . ",";
      $outl .= $valvx{$f}->{count} . ",";
      $outl .= $valvx{$f}->{type} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $advi++;$advonline[$advi] = "Illegal Node Names rejected - $invi";
   $advcode[$advi] = "TEMSAUDIT1029W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "InvalidNodes";
}

my $refxi = keys %reflexx;
if ($refxi > 0) {
   my $refx_ct = 0;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Reflex [Action] Command failures\n";
   $cnt++;$oline[$cnt]="Situation,Status,Count\n";
   foreach $f (sort {$a cmp $b} keys %reflexx) {
      $outl = $f . ",";
      $outl .= $reflexx{$f}->{status} . ",";
      $outl .= $reflexx{$f}->{count} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $refx_ct += $reflexx{$f}->{count};
   }
   $advi++;$advonline[$advi] = "Reflex [Action] Command $refx_ct failures in $refxi situation(s)";
   $advcode[$advi] = "TEMSAUDIT1034W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "CommandFailures";
}

my $agtsh_dur = $agtsh_etime - $agtsh_stime;
if ($agtsh_dur > 0) {
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
         if (abs($g-$dur_mode) > 2) {
            $dur_vary_ct += $tdur;
            $dur_vary_sum += abs($g-$dur_mode)*$tdur;
         }
         $pdur .= $agtsh_iat[$ai]{$g}{count} . ";";
      }
      if (4*$dur_vary_ct > $agtsh_ct[$ai]) {
         $advi++;$advonline[$advi] = "agent $f indication of duplicate agent names on same system: $pdur";
         $advcode[$advi] = "TEMSAUDIT1017W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "Duplicates";
         $agtsh_total_multi += 1;
         $multi_agent{$f} = 1;
      } elsif ($dur_vary_sum > $agtsh_ct[$ai]){
         $advi++;$advonline[$advi] = "agent $f indication of occasional high level jitter: $pdur";
         $advcode[$advi] = "TEMSAUDIT1018W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "High_Jitter";
         $agtsh_jitter_major += 1;
      } else  {
         $agtsh_jitter_minor += 1;
         if ($opt_jitall == 1){
            $advi++;$advonline[$advi] = "agent $f indication of occasional low level jitter: $pdur";
            $advcode[$advi] = "TEMSAUDIT1019W";
            $advimpact[$advi] = $advcx{$advcode[$advi]};
            $advsit[$advi] = "Low Jitter";
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
   $advi++;$advonline[$advi] = "Simple agent Heartbeat total[$agtshi] multi_agent[$agtsh_total_multi] jitter_major[$agtsh_jitter_major] jitter_minor[$agtsh_jitter_minor]";
   $advcode[$advi] = "TEMSAUDIT1020W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Sum Jitter";

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
               my $minkey = substr("00" . $min,-2,2);
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

my $inodex_ct = scalar keys %inodex;
if ($inodex_ct > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Send Node Status Exception Report\n";
   $cnt++;$oline[$cnt]="Node,Count,Hostaddr,Thrunode,Product,Version\n";
   foreach $f ( sort { $a cmp $b } keys %inodex) {
      my $inode_ref = $inodex{$f};
      next if $inode_ref->{count} == 1;
      foreach $g (keys %{$inode_ref->{instances}}) {
         my $inodei_ref = $inode_ref->{instances}{$g};
         $outl = $f . ",";                 # node
         $outl .= $inodei_ref->{count} . ",";
         $outl .= $inodei_ref->{hostaddr} . ",";
         $outl .= $inodei_ref->{thrunode} . ",";
         $outl .= $inodei_ref->{product} . ",";
         $outl .= $inodei_ref->{version} . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
         $advi++;$advonline[$advi] = "Node $f at $inodei_ref->{hostaddr} has $inodei_ref->{count} sendstatus - possible duplicate agent";
         $advcode[$advi] = "TEMSAUDIT1033W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "duplicate";
      }
   }
}


my $timex_ct = scalar keys %timex;
if ($timex_ct > 0) {
   $advi++;$advonline[$advi] = "$timex_ct Agent time out messages";
   $advcode[$advi] = "TEMSAUDIT1021W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "timeout";
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

if ($comme_ct > 0) {
   $advi++;$advonline[$advi] = "Remote Procedure Connection lost $comme_ct";
   $advcode[$advi] = "TEMSAUDIT1039W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "RPCFail";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="RPC Error report\n";
   $cnt++;$oline[$cnt]="Error,Target,Count\n";
   foreach $f ( sort { $commex{$b}->{count} <=> $commex{$a}->{count} } keys %commex) {
      my $perror = $f;
      foreach my $g ( sort { $a cmp $b } keys %{$commex{$f}->{targets}} ) {
         my $ptarget = $g;
         my $pcount = $commex{$f}->{targets}{$g}->{count};
         $outl = $perror . ',';
         $outl .= $ptarget . ",";
         $outl .= $pcount . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
   }
}

$total_hist_rows = 0;
$total_hist_bytes = 0;
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
      my $contrib = 0;
      foreach $g ( sort { $res_ref->{sitx}{$b}  <=> $res_ref->{sitx}{$a}} keys %{$res_ref->{sitx}} ) {
         $outl .= $g .",";
         $outl .= $res_ref->{sitx}{$g} .",";
         $contrib += 1;
         last if $contrib > 5;
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

if ($atrwx_ct > 0) {
   $advi++;$advonline[$advi] = "$atrwx_ct Attribute file warning messages";
   $advcode[$advi] = "TEMSAUDIT1030W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "attribute";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Attribute File Warning Report\n";
   $cnt++;$oline[$cnt]="AttributeName,WarningType,\n";
   $cnt++;$oline[$cnt]=",,filename,app,table,column,\n";
   foreach $f ( sort { $a cmp $b } keys %atrwx) {
      $atr_warn = $f;
      $atr_ref = $atrwx{$f};
      foreach $g ( sort { $a cmp $b } keys %{$atr_ref->{atrname}}) {
         $atr_name = $g;
         $atrn_ref = $atr_ref->{atrname}{$g};
         $outl = $atr_warn . "," . $atr_name . ',';
         $cnt++;$oline[$cnt]=$outl . "\n";
         foreach $h ( sort { $a cmp $b } keys %{$atrn_ref->{file}}) {
            $atr_file = $h;
            $atrf_ref = $atrn_ref->{file}{$h};
            $atr_app = $atrf_ref->{app};
            $atr_table = $atrf_ref->{table};
            $atr_column = $atrf_ref->{column};
            $outl = ",," . $atr_file . "," . $atr_app . ",". $atr_table . ",". $atr_column . ",";
            $cnt++;$oline[$cnt]=$outl . "\n";
         }
      }
   }
}

if ($loci_ct > 0) {
   my $loci_worry = 0;
   my $worry_ct = int(($loci_ct*$opt_nominal_loci)/100);
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Loci Count Report - $loci_ct found\n";
   $cnt++;$oline[$cnt]="Locus,Count,PerCent,Example_Line\n";
   foreach $f ( sort { $locix{$b}->{count} <=> $locix{$a}->{count} || $a cmp $b } keys %locix) {
      last if $locix{$f}->{count} < $worry_ct;
      my $res_pc = int(($locix{$f}->{count}*100)/$loci_ct);
      my $ppc = sprintf '%.0f%%', $res_pc;
      $outl = $f . "," . $locix{$f}->{count} . "," . $ppc . "," . $locix{$f}->{first};
      $cnt++;$oline[$cnt]="$outl\n";
      $loci_worry += 1;
   }
   if ($loci_worry > 0 ) {
      $advi++;$advonline[$advi] = "$loci_worry worrying diagnostic messages - see later report section";
      $advcode[$advi] = "TEMSAUDIT1035W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "diagnostic";
   }
}


if ($pcb_deletePCB > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Agent connection churning Report - $pcb_deletePCB systems\n";
   $cnt++;$oline[$cnt]="ip_address,Count,NewPCB,DeletePCB,Agents(count),\n";
   foreach $f ( sort { $pcbx{$b}->{deletePCB} <=> $pcbx{$a}->{deletePCB} || $a cmp $b } keys %pcbx) {
      my $pcb_ref = $pcbx{$f};
      last if $pcb_ref->{deletePCB} < 2;
      $outl = $f . "," . $pcbx{$f}->{count} . "," . $pcbx{$f}->{newPCB} . "," . $pcbx{$f}->{deletePCB} . ",";
      my $pagents = "";
      foreach $g (keys %{$pcb_ref->{agents}}) {
        $pagents .= $g . "(" . $pcb_ref->{agents}{$g} . ") ";
      }
      $outl .= $pagents . ",";
      $cnt++;$oline[$cnt]="$outl\n";
   }
}

$soaperror_ct = scalar keys %soaperror;
if ($soaperror_ct > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="SOAP Error Report\n";
   $cnt++;$oline[$cnt]="Count,Fault,\n";
   $cnt++;$oline[$cnt]=",Count,Client,\n";
   foreach $f ( sort { $soaperror{$b}->{count} <=> $soaperror{$a}->{count} } keys %soaperror) {
      my $fault_ref = $soaperror{$f};
      $outl = $fault_ref->{count} . "," . $f . ",";
      $cnt++;$oline[$cnt]="$outl\n";
      foreach $g (keys %{$fault_ref->{clients}}) {
         my $client_ref = $fault_ref->{clients}{$g};
         $outl = "," . $client_ref->{count} . " , " . $g . ",";
         $cnt++;$oline[$cnt]="$outl\n";
      }
   }
}

if ($change_real > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Agent Flipping Report\n";
   $cnt++;$oline[$cnt]="Desc,Count,Node,Count,Thrunode,HostAddr,OldThrunode,\n";
   foreach $f ( sort { $a cmp $b } keys %changex) {
      my $change_ref = $changex{$f};
      foreach $g (keys %{$change_ref->{nodes}}) {
         my $change_node_ref = $change_ref->{nodes}{$g};
         next if $change_node_ref->{count} < 2;
         foreach $h (keys %{$change_node_ref->{instances}}) {
            my $change_instance_ref = $change_node_ref->{instances}{$h};
            $outl = $f . ",";
            $outl .= $change_node_ref->{count} . "," . $g . ",";
            $outl .= $change_instance_ref->{count} . ",";
            $outl .= $change_instance_ref->{thrunode} . "," . $change_instance_ref->{hostaddr} . "," . $change_instance_ref->{oldthrunode} . ",";
            $cnt++;$oline[$cnt]="$outl\n";
         }
      }
   }
}

if ($sit32_total > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="Situation Length 32 Report\n";
   $cnt++;$oline[$cnt]="Count,Sitname,,\n";
   foreach $f ( sort { $a cmp $b } keys %sit32x) {
      $outl = $sit32x{$f} . ",";
      $outl .= $f . ",";
      $cnt++;$oline[$cnt]="$outl\n";
   }
}

$opt_o = $opt_odir . $opt_o if index($opt_o,'/') == -1;

open OH, ">$opt_o" or die "can't open $opt_o: $!";


if ($opt_nohdr == 0) {
   for (my $i=0; $i<=$hdri; $i++) {
      print OH $hdr[$i] . "\n";
   }
   print OH "\n";
}

if ($advi != -1) {
   print OH "\n";
   print OH "Advisory Message Report - *NOTE* See advisory notes at report end\n";
   print OH "Impact,Advisory Code,Object,Advisory,\n";
   for (my $a=0; $a<=$advi; $a++) {
       my $mysit = $advsit[$a];
       my $myimpact = $advimpact[$a];
       my $mykey = $mysit . "|" . $a;
       $advx{$mykey} = $a;
   }
   foreach my $f ( sort { $advimpact[$advx{$b}] <=> $advimpact[$advx{$a}] ||
                          $advcode[$advx{$a}] cmp $advcode[$advx{$b}] ||
                          $advsit[$advx{$a}] cmp $advsit[$advx{$b}] ||
                          $advonline[$advx{$a}] cmp $advonline[$advx{$b}]
                        } keys %advx ) {
      my $j = $advx{$f};
      print OH "$advimpact[$j],$advcode[$j],$advsit[$j],$advonline[$j]\n";
      $max_impact = $advimpact[$j] if $advimpact[$j] > $max_impact;
      $advgotx{$advcode[$j]} = $advimpact[$j];
   }
} else {
   print OH "No Expert Advisory messages\n";
}
print OH "\n";

for (my $i = 0; $i<=$cnt; $i++) {
   print OH $oline[$i];
}

if ($advi != -1) {
   print OH "\n";
   print OH "Advisory Trace, Meaning and Recovery suggestions follow\n\n";
   foreach my $f ( sort { $a cmp $b } keys %advgotx ) {
      print OH "Advisory code: " . $f  . "\n";
      print OH "Impact:" . $advgotx{$f}  . "\n";
      print OH $advtextx{$f};
   }
}
print OH "\n";
close(OH);

if ($opt_sr == 1) {
   if ($soap_burst_minute != -1) {

      my $opt_sr_fn = $opt_ossdir . "soap_detail.txt";

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

if ($opt_ss == 1) {
   if ($ssi != -1) {
      my $opt_ss_fn = $opt_ossdir . $opt_nodeid . "_sendstatus_detail.txt";
      open SEND, ">$opt_ss_fn" or die "Unable to open SEND Detail output file $opt_ss_fn\n";
      for (my $i=0;$i<=$ssi;$i++) {
         print SEND "$ssout[$i]\n";
      }
      close SEND;
   }
}


if ($opt_sum != 0) {
# REFIC 90 910 77.83% 06.30.05 chub-gt6-mw1 13532 https://ibm.biz/BdFrJL
# 20160701190930 REFIC 12 /ecurep/pmr/4/5/45555,442,000/2016-07-01/45555.442.000.pdcollect-lxpm1042-DUP0004.tar.Z_unpack/
   $sumline = "TEMSAUDIT ";
   my $padvi = $advi + 1;
   $sumline .= $max_impact . " ";
   $sumline .= $padvi . " ";
   $sumline .= $opt_nodeid . " ";
   $sumline .= $opt_tems . " ";
   $sumline .= "$opt_level ";
   $sumline .= "$opt_driver ";
   $sumline .= "$trespermin ";
   my $sumfn = $opt_odir . "temsaud.txt";
   open SUM, ">$sumfn" or die "Unable to open SOAP Detail output file $sumfn\n";
   print SUM "$sumline\n";
   close(SUM);
}

print STDERR "Wrote $cnt lines\n" if $opt_odir eq "";

# all done

$rc = 0;
$rc = 1 if $max_impact >= $opt_nominal_max_impact;

#print STDERR "exit code 1 $max_impact $opt_max_impact\n" if $rc == 1;

exit $rc;

sub capture_sqlrun {
   my ($sqlrun_ref) = @_;
   $sql_frag = $sqlrun_ref->{frag};
   $sql_frag =~ s/^\s+|\s+$//;                         # strip leading and trailing blanks
   $sx = $sqlx{$sql_frag};
   if (!defined $sx) {
      $sqli += 1;
      $sx = $sqli;
      $sql[$sx] = $sql_frag;
      $sqlx{$sql_frag} = $sx;
      $sql_ct[$sx] = 0;
      $sql_src[$sx] = "";
      $sql_src[$sx] = $sql_source if $sql_source ne "";
   }
   $sql_ct[$sx] += 1;
   if ($sql_start == 0) {
      $sql_start = $sqlrun_ref->{start};
      $sql_end = $sqlrun_ref->{start};
   }
   if ($sqlrun_ref->{start} < $sql_start) {
      $sql_start = $sqlrun_ref->{start};
   }
   if ($sqlrun_ref->{start} > $sql_end) {
      $sql_end = $sqlrun_ref->{start};
   }
   $sql_source = $sqlrun_ref->{source};
   if ($sql_source ne "") {
      my $source_ref = $sqlsourcex{$sql_source};
      if (!defined $source_ref) {
         my %sourceref = (
                            count => 0,
                            start => 0,
                            end => 0,
                            tables => {},
                         );
         $source_ref = \%sourceref;
         $sqlsourcex{$sql_source} = \%sourceref;
      }
      $source_ref->{count} += 1;
      if ($source_ref->{start} == 0) {
         $source_ref->{start} = $logtime;
         $source_ref->{end} = $logtime;
      }
      if ($logtime < $source_ref->{start}) {
         $source_ref->{start} = $logtime;
      }
      if ($logtime > $source_ref->{end}) {
         $source_ref->{end} = $logtime;
      }
      my $sql_table = "";
      if (substr($sql_frag,0,6) eq "SELECT") {
         $sql_frag =~ /[ \)]FROM\s+(\S+)/;
         $sql_table = $1;
      } elsif (substr($sql_frag,0,6) eq "DELETE") {
         $sql_frag =~ /[ \)]FROM\s+(\S+)/;
         $sql_table = $1;
      } elsif (substr($sql_frag,0,6) eq "INSERT") {
         $sql_frag =~ /[ \)]INTO\s+(\S+)/;
         $sql_table = $1;
      } elsif (substr($sql_frag,0,6) eq "UPDATE") {
         $sql_frag =~ /UPDATE\s+(\S+)/;
         $sql_table = $1;
      } else {
         $sql_table = "Unknown";
      }
      my $table_ref = $source_ref->{tables}{$sql_table};
#$DB::single=2 if !defined $sql_table;
      if (!defined $table_ref) {
         my %tableref = (
                            count => 0,
                            start => 0,
                            end => 0,
                            sqls => {},
                         );
         $table_ref = \%tableref;
         $source_ref->{tables}{$sql_table} = \%tableref;
      }
      $table_ref->{count} += 1;
      if ($table_ref->{start} == 0) {
         $table_ref->{start} = $logtime;
         $table_ref->{end} = $logtime;
      }
      if ($logtime < $table_ref->{start}) {
         $table_ref->{start} = $logtime;
      }
      if ($logtime > $table_ref->{end}) {
         $table_ref->{end} = $logtime;
      }
      my $frag_ref = $table_ref->{sqls}{$sql_frag};
      if (!defined $frag_ref) {
         my %fragref = (
                          count => 0,
                          start => 0,
                          end => 0,
                          pos => $l,
                       );
         $frag_ref = \%fragref;
         $table_ref->{sqls}{$sql_frag} = \%fragref;
      }
      $frag_ref->{count} += 1;
      if ($frag_ref->{start} == 0) {
         $frag_ref->{start} = $logtime;
         $frag_ref->{end} = $logtime;
      }
      if ($logtime < $frag_ref->{start}) {
         $frag_ref->{start} = $logtime;
      }
      if ($logtime > $frag_ref->{end}) {
         $frag_ref->{end} = $logtime;
      }
   }
}


sub open_kib {
   # get list of files
   my $logpat = $logbase . '-.*\.log' if defined $logbase;
   if (!$opt_inplace) {
      if (defined $logbase) {
         my $cmd;
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
      my $dlog;          # fully qualified name of diagnostic log
      opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n");
      my @rlogfiles = grep {/$logpat/} readdir(DIR);
      closedir(DIR);
      die "no log files found with given specifcation\n" if $#rlogfiles == -1;
      my @dlogfiles;
      for $f (@rlogfiles) {
         $dlog = $opt_logpath . $f;
         next if ! -e $dlog;
         next if ! -s $dlog;
         push(@dlogfiles,$f);
      }

      my $oneline;       # local variable
      my $tlimit = 100;  # search this many times for a timestamp at begining of a log
      my $t;
      my $tgot = 0;          # track if timestamp found
      my $itime;

      foreach $f (@dlogfiles) {
         $f =~ /^.*-(\d+)\.log/;
         $segmax = $1 if $segmax eq "";
         $segmax = $1 if $segmax < $1;
         $dlog = $opt_logpath . $f;
         open( DIAG, "< $dlog" ) or die "Cannot open Diagnostic file $dlog : $!";
         for ($t=0;$t<$tlimit;$t++) {
            $oneline = <DIAG>;                      # read one line
            last if !defined $oneline;
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
         close(DIAG);
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
         if (defined $seg_time[1]) {
            $skipzero = 1 if ($seg_time[1] - $seg_time[0]) > 3600;
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

sub time2sec
{
   my ($itime) = @_;
   my $year = substr($itime,0,4) - 1900;
   my $mon = substr($itime,4,2) - 1;
   my $day = substr($itime,6,2);
   my $hour = substr($itime,8,2);
   my $min = substr($itime,10,2);
   my $sec = substr($itime,12,2);
   return timegm($sec,$min,$hour,$day,$mon,$year);
}
sub sec2time
{
   my ($itime) = @_;

   my $sec;
   my $min;
   my $hour;
   my $mday;
   my $mon;
   my $year;
   my $wday;
   my $yday;
   my $isdst;
   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=gmtime($itime);
   return sprintf "%4d%02d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec;
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
    -workpath       Where output files get stored
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
# 1.34000 - Add advisory for missing application.table cases
# 1.35000 - Correct some logic on incoming PostEvent messages
# 1.36000 - rework advisories for impact, etc
# 1.37000 - add 1025E for send event failures, prepare for AOA usage
#         - add TEMS nodeid and type
# 1.38000 - add 1026E for ulimit nofiles 1024 or lower
#         - add 1027W remote SQL timeouts
#         - add 1028W concurrent action commands at TEMS
#         - add 1029W for invalid nodes rejected
# 1.39000 - add 1030W for attribute definition conflicts
# 1.40000 - Adjust impact of 1024E to 100 and add 1031E at 0
# 1.41000 - Add advisory for missing ERROR in traces
# 1.42000 - Add advisory on node status update
#         - Adjust jitter logic to avoid silly duplicate advisories
# 1.43000 - Better logic for invalid names
#           Add advisory for reflex command failures
# 1.44000 - Add loci frequency report and advisory
# 1.45000 - Add -ss option
# 1.46000 - Add advisory on multiple remote TEMS reconnects
# 1.47000 - Add advisory on port scanning from four messages
#         - Add initial trace settings
# 1.48000 - Add example [first] line to locui report
#         - Add advisory on lost connections
#         - Add -ossdir to control sendstatus summary report location
# 1.49000 - handle -sr with no tracing better
#         - add types of portscan counts to advisory
#         - add advisory on Open Index database errors
#         - add advisory on Read error cases, seen in SITDB/QA1CRULD
#         - add optional SQL detail report
# 1.50000 - add another 1040E type key problem
#         - handle multiple .inv records better
# 1.51000 - add Historical data bytes to Summary
#         - add Situation Result by Time report
# 1.52000 - add Activity not a Call advisory
#         - Add advisory for verify index failures
# 1.53000 - Add advisory for invalid FTO timestamp
#         - correct wording on 1041E issue.
# 1.54000 - Add Endpoint Communication Problem Report
#         - Add advisory on WRITENOS=YES
#         - Add advisory on low storage
# 1.55000 - correct cumulative results per cent presentation
#         - More information on port scanning
# 1.56000 - Add advisory on DeletePCB cases
# 1.57000 - Add advisories on connection to hub TEMS loss
# 1.58000 - Improve DeletePCB report to include possible agents involved
# 1.59000 - Add advisory for missing timer expiration
#         - Add advisory for SOAP errors
#         - Add advisory and report for Agent Location Flipping
#         - Add advisory for missing application data
# 1.60000 - Avoid errors when Agent Location Flipping data prior to FP7
# 1.61000 - Correct logic in 1056W advisory - was blocking TEMSAUDIT1011W
#         - remove port number from Soap Error report client, hides counts of interest
# 1.62000 - Correct logic in 1055W advisory - missing some cases
# 1.63000 - Add result data graphical display
#         - Add a number of advisories and reports based on recent diagnostics.
# 1.64000 - remove two duplicated reports
#         - add advisory on SOAP unable to get attributes

# Following is the embedded "DATA" file used to explain
# advisories the the report. It replicates text in
# Appendix 2 of TEMS Audit Users Guide.docx
__END__
TEMSAUDIT1001W
Text: num Filter object(s) too big situations and/or reports

Tracing: error
Diag Log: (53CD5BBD.0000-1B:kpxreqds.cpp,1723,"buildThresholdsFilterObject") Filter object too big (60320 + 24958),Table NTEVTLOG Situation KQ5_EVTLog_CA_Cluster2_C.

Meaning: When a situation formula is compiled by the TEMS
SQL processor two binary objects are created: Filter Object
and Pool Object. If either is more than 32767 bytes, they
are not transmitted to the agent. The agent runs with a
null filter which means sending all data to the TEMS for
filtering. This can result in severe workload issues and
cause high CPU and sometimes TEMS instability.

This message will also be seen from a real time data request
as from a TEP workspace or some SOAP SQL.

Recovery plan: Change the situation to have less logic.
Edit the TEMS_Alert product provided situation, distribute
to *ALL_CMS, set to Run at Startup and start it. The next
time there is a situation with filter object too big, an
alert will be seen in the TEPS Enterprise level.

For TEP workspaces and other real time data request, change
the request to limit the size of the formula and do
post-retrieval filtering if necessary. If the real time data
request does no filtering anyway, consider changing the
request to do filtering. Retrieving thousands of rows for
personal TEP viewing is rarely very useful or practical.

In addition, the Agent side has a limit and will never send
more than 16megs of data to any single request. So you may
be getting far less data than you expect anyway.
--------------------------------------------------------------

TEMSAUDIT1002W
Text: Listen Pipe Usage at maximum

Tracing: error
Meaning: ITM communications uses Listen Pipes. When there is
more communications than can be handled by the number of
listen pipes, ITM processing may be degraded.

Recovery plan: You can increase the number of service threads
by adding this to KBBENV

KDEP_SERVICETHREADS=63

and recycling the TEMS involved.
The number 63 is the default from ITM 630 FP5.
--------------------------------------------------------------

TEMSAUDIT1003W
Text: Listen Pipe above nominal[num] listen=num balance=num threads=num  pipes=num

Tracing: error

Meaning: ITM communications uses Listen Pipes. When there
are a lot of listen pipes, that may indicate the TEMS is
nearing capacity.

Recovery plan: You should study TEMS workload and see if the
system is approaching communications capacity. If so workload
can be reduced or the workload can be divided between
multiple TEMSes.
--------------------------------------------------------------

TEMSAUDIT1004W
Text: ulimit nofile [num] is below nominal [num]

Tracing: error
Diag Log: +52BE1DCC.0000     Nofile Limit: None                       Stack Limit: 32M

Meaning: This is a Linux/Unix concern. A TEMS needs 400 file
descriptors for normal processing and an additional file
descriptor for each agent that makes a TCP Socket connection.
The ITM installation guide documents that a TEMS [and WPA
and KDE_Gateway] should specify at least 8192.

Recovery plan: The process of setting this is platform
dependent. For example on Linux this is in /etc/security/limits.conf.

When you do a ulimit -n on the userid where the TEMS will be
running, that should be at least 8192.
--------------------------------------------------------------

TEMSAUDIT1005W
Text: ulimit stack [num] is above nominal [num] (kbytes)

Tracing: error
Diag Log: +52BE1DCC.0000     Nofile Limit: None                       Stack Limit: 32M

Meaning: This is a Linux/Unix concern. Most well running TEMS
show a stack of 10meg or 10240K. In some cases having a
larger value can waste virtual storage capacity.

Recovery plan: It is not certain this makes a gigantic
difference, however you might consider tuning the value
for better virtual storage utilization. It may also be
less of a concern in 64-bit platforms.
--------------------------------------------------------------

TEMSAUDIT1006E
Text: Results bytes per minute num higher then nominal [num]

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)
Diag Log: (53CD5B6E.0000-3A:kpxrpcrq.cpp,852,"IRA_NCS_Sample") Rcvd 0 rows sz 192 tbl *.NTPROCSSR req NTWOS_BP_CPUBusyCritical_95_C <3570423672,3385852696> node <Primary:LACCOLBOGVAS082:NT>

Meaning: Much of TEMS activity is driven by situations
sending results from situations, real time data and sometimes
historical collection data. If this is too high the TEMS may
become unstable. The default nominal value is 500K
bytes/minute. However your own testing and experience may
allow you to set a higher or lower alert value in temsaud.ini.

Recovery plan: There are several ways to proceed:
1) reduce workload by stopping or rewriting situations or
other impactors;
2) create another remote TEMS and split the agents between
the two TEMSes;
3) host the remote TEMS on a more powerful system.

There is no absolute limit for number of agents per remote
TEMS. The Installation Guide states a tested upper limit of
1500 agents. However I have seen cases where a remote TEMS
could handle up to 3000 agents or less than 800 agents.
It depends on workload and system capacity [CPU and Memory
and I/O system and communications].

Experience is always the best guide.
--------------------------------------------------------------

TEMSAUDIT1007W
Text: Trace bytes per minute num higher then nominal num

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)
Diag Log: (53CD5B6E.0000-3A:kpxrpcrq.cpp,852,"IRA_NCS_Sample") Rcvd 0 rows sz 192 tbl *.NTPROCSSR req NTWOS_BP_CPUBusyCritical_95_C <3570423672,3385852696> node <Primary:LACCOLBOGVAS082:NT>

Meaning: ITM tracing is generally very low impact. This
reports the rare case where tracing may be impacting
performance. The key case for this advisory was a site
that accidentally left a remote TEMS with KBB_RAS1=ALL. That
produced 10 megabytes a second of data and that actually
overwhelmed the system and things ran very slowly.

Recovery plan: Do less tracing unless you are specifically
instructed by IBM Support. You should especially avoid setting
communications tracing [KDC_DEBUG=Y,KDE_DEBUG=Y,KBS_DEBUG=Y]
unless specifically requested by IBM Support.
--------------------------------------------------------------

TEMSAUDIT1008E
Text: num early remote SQL failures

Tracing: error

Meaning: During remote TEMS connection processing, three
potentially large tables are synchronized from the hub TEMS
to the remote TEMS. This is accomplished by remote SQL.

The above message means that a table was not retrieved in
the default 600 second limit. The "early remote" means the
condition happened during startup. In that case remote TEMS
runs with incomplete information and the results are very
poor, with not all situations getting distributed.

Recovery plan: There is an environment variable
KDS_SYNDRQ_TIMEOUT which can increase the default seconds.
Typical is to change to 1800 seconds or 30 minutes.

This typically occurs when the hub/remote communications link
is high latency, say 200+ milliseconds measure by ping. This
type of link is often problematical and leads the TEMS
instability: remotes going offline and online randomly. Best
practice is to avoid such cases and place hub TEMS such that
hub/remotes latency is low - perhaps 25 milliseconds or lower.
--------------------------------------------------------------

TEMSAUDIT1009E
Text: KGLCB_FSYNC_ENABLED set to 0 - risky for TEMS database files

Tracing: error
Diag Log: (54DDA359.0015-1:kbbssge.c,72,"BSS1_GetEnv") KGLCB_FSYNC_ENABLED="0"

Meaning: When data is written to a TEMS database file, default
processing is to pause until the data is confirmed on disk.
The environment variable KGLCB_FSYNC_ENABLED defaults to 1.
If this is changed to 0, processing is faster but far riskier.
On any interruption the disk contents may be inconsistent or
missing data.

Recovery plan:  Remove the setting to 0 and let the default
processing take place.
--------------------------------------------------------------

TEMSAUDIT1010W
Text: num "No Matching Request" samples

Tracing: error
Diag Log: (53CD5B2F.0000-4:kpxrpcrq.cpp,897,"IRA_NCS_Sample") Sample <3163560266,2001733381> arrived with no matching request.

Meaning: This counts cases where a request for data to an
agent has timed out and later the data was delivered late.
The message means the late arriving data was discarded. This
can mean that the agent is overloaded, there are communication
issues, or the remote TEMS is overloaded.

Recovery plan:  If this occurs a lot, work with IBM support
to identify the underlying cause and eliminate it. If there
are just a few, the impact is probably not that important.
--------------------------------------------------------------

TEMSAUDIT1011W
Text: Application.table table missing num times

Tracing: error
Diag Log: (56F2B983.0007-1F:kdspmcat.c,449,"CompilerCatalog") Table name TAPPLPROPS for  Application O4SRV Not Found.

Meaning: This usually means some application support is
missing from the TEMS. As a result monitoring related to that
table is not performed.

Recovery plan:  Work with IBM support to identify the
underlying cause and eliminate it.
--------------------------------------------------------------

TEMSAUDIT1012W
Text: Situation high rate num [num%]

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)
Diag Log: (53CD5B2F.0000-4:kpxrpcrq.cpp,897,"IRA_NCS_Sample") Sample <3163560266,2001733381> arrived with no matching request.

Meaning: If the overall result rate is high, this advisory
identifies the situations contributing the most to the result
rate. Situations totaling the top 50% are presented.

Recovery plan:  Change or stop the situation to reduce the
result workload.
--------------------------------------------------------------

TEMSAUDIT1013W
Text: Situation possible truncated results - max result num

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)
Diag Log: (53CD5B2F.0000-4:kpxrpcrq.cpp,897,"IRA_NCS_Sample") Sample <3163560266,2001733381> arrived with no matching request.

Meaning: If the maximum result is near 16 megabytes, the
chances are likely the results have been truncated at the
agent.

Recovery plan:  Change the situation to reduce the amount of
data returned.
--------------------------------------------------------------

TEMSAUDIT1014W
Text: SOAP requests per minute num% higher then nominal num

Tracing: error (unit:kshdhtp,Entry="getHeaderValue"  all) (unit:kshreq,Entry="buildSQL" all)

Meaning: SOAP requests can be very impactful at the hub TEMS.
This shows you how many are being processed.

Recovery plan:  Change the SOAP usage to reduce impact. These
can be tacmd functions, many of which use SOAP.
--------------------------------------------------------------


TEMSAUDIT1015W
Text: SOAP Burst requests per minute num% higher then nominal num at line lineno in soap_burst_max_log

Tracing: error (unit:kshdhtp,Entry="getHeaderValue"  all) (unit:kshreq,Entry="buildSQL" all)

Meaning: This requires using the -sr option to create the
detailed SOAP log file. Sometimes SOAPs come in a high burst
that can destabilize the hub TEMS.

Recovery plan:  Change the SOAP usage to reduce impact.
These can be tacmd functions, many of which use SOAP.
--------------------------------------------------------------


TEMSAUDIT1016W
Text: num Agents with repeated onlines

Tracing: error
Diag Log: (54EA2C3A.0002-AD:kpxreqhb.cpp,924,"HeartbeatInserter") Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.

Meaning: Agents sometimes come online over and over. This
usually means there are duplicate agent name cases. This
causes many problems including TEMS and TEPS performance issues.

Recovery plan:  Work to eliminate the duplicate agent name
cases. One project that can be used for this purpose is
Sitworld: TEPS Audit https://ibm.biz/BdXNvy.

There are several other techniques that require IBM Support
help. Those detect agents with duplicate names that connect
to the same remote TEMS and have the same version number will
not be seen by TEPS but still affect TEMS and degrade
monitoring.
--------------------------------------------------------------

TEMSAUDIT1017W
Text: agent name indication of duplicate agent names on same system: time

Tracing: error (UNIT:kfaprpst ER ST)
Diag Log: (5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >

Meaning: Agents send node status updates to a TEMS. This agent
name might reflect duplicate agents on the same system.

Recovery plan:  Work to eliminate the duplicate agent name
cases. One project that can be used for this purpose is
Sitworld: TEPS Audit https://ibm.biz/BdXNvy.

There are several other techniques that require IBM Support
help. Those detect agents with duplicate names that connect
to the same remote TEMS and have the same version number will
not be seen by TEPS but still affect TEMS and degrade
monitoring.
--------------------------------------------------------------

TEMSAUDIT1018W
Text: agent name indication of occasional high level jitter: time

Tracing: error (UNIT:kfaprpst ER ST)
Diag Log: (54EA2C3A.0002-AD:kpxreqhb.cpp,924,"HeartbeatInserter") Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.

Meaning: Agents send node status updates to a TEMS. This
indicates a wide variation in the inter-arrival time.

Recovery plan:  This can mean the TEMS, the communications
or the Agent is under heavy stress. That might or might be
important. Check for other advisory messages.
--------------------------------------------------------------

TEMSAUDIT1019W
Text: agent name indication of occasional low level jitter: time
Diag Log: (5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >

Tracing: error (UNIT:kfaprpst ER ST)

Meaning: Agents send node status updates to a TEMS. This
indicates a small variation in the inter-arrival time.

Recovery plan:  This means the TEMS is under a small amount
of stress.
--------------------------------------------------------------

TEMSAUDIT1020W
Text: Simple agent Heartbeat total[num] multi_agent[num] jitter_major[num] jitter_minor[num]

Tracing: error (UNIT:kfaprpst ER ST)
Diag Log: (54EA2C3A.0002-AD:kpxreqhb.cpp,924,"HeartbeatInserter") Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.

Meaning: Summary of inter-arrival node status times

Recovery plan:  see other advisory messages and reports
--------------------------------------------------------------

TEMSAUDIT1021W
Text: num Agent time out messages

Tracing: error
Diag Log: (54E64441.0000-12:kpxreqds.cpp,2832,"timeout") Timeout for wlp_chstart_gmqc_std <26221448> *.QMCHANS.
          (54E7D64D.0000-12:kpxreqds.cpp,2832,"timeout") Timeout for  <1389379034> *.KINAGT.

Meaning: How many times attempted communication with an agent
timed out. This needs addition diagnostic tracing to clarify.
It does suggest a problem with communications or with the
agent.

Recovery plan:  Work with IBM Support.
--------------------------------------------------------------

TEMSAUDIT1022E
Text: TEMS database table with num errors

Tracing: error
Diag Log: (569D717B.007C-4A:kglkycbt.c,1212,"kglky1ar") iaddrec2 failed - status = -1, errno = 9,file = QA1CSTSC, index = PrimaryIndex, key = qbe_prd_ux_systembusy_c         TEMSP01
          (569C6BDD.001D-26:kglkycbt.c,1498,"kglky1dr") idelrec failed - status = -1, errno = 0,file = RKCFAPLN, index = PrimaryIndex

Meaning: Count of TEMS database errors.

Recovery plan:  Work with IBM Support. The issue is severe
and needs prompt attention.
--------------------------------------------------------------


TEMSAUDIT1023W
Text: TEMS database table with num Duplicate Record errors

Tracing: error
Diag Log: (568A71C2.0000-C5:kglisadd.c,219,"iaddrec2") Duplicate key for index PrimaryIndex,U in QA1CSITF.IDX

Meaning: Count of TEMS database duplicate record errors.
On a remote TEMS this usually means a workload issue is
causing the remote TEMS to lose contact with hub TEMS and
then make contact again. On a hub TEMS this means a TEMS
database error.

This is often paired with TEMSAUDIT1022E messages and when
both occur together, the duplicate error is what counts.

Recovery plan:  Work with IBM Support. It isn't as bad as
other sorts of database errors, but ITM monitoring is usually
severely degraded.
--------------------------------------------------------------

TEMSAUDIT1024E
Text: TEMS database table with num Relative Record Number errors

Tracing: error
Diag Log: (56BC3268.0000-15:kfastins.c,1391,"KFA_PutSitRecord") ***ERROR: for RRN <6076>, (oldest) Index TS <                > does not match TSITSTSH TS <1160209223543004>

Meaning: Count of TEMS database errors of the
Relative Record Number type. This error message was added at
the ITM 630 FP6 level and reflects a real problem.

Recovery plan:  Work with IBM Support.
--------------------------------------------------------------

TEMSAUDIT1025E
Text: TEMS Event Destination experienced num send errors

Tracing: error
Diag Log: (5754ECFD.0022-A:kfaotmgr.c,91,"KFAOT_EIF_Manager") Event send to destination <0> failed. status <8>

Meaning: Event Integration Facility send event processing failed.
This could mean the om_tec.config is wrong if event destination is 0.
It could also mean the event receiver process is not running.

Recovery plan:  Correct issue. Work with IBM Support if needed.
--------------------------------------------------------------

TEMSAUDIT1026E
Text: ulimit nofile [num] is below nominal [num]

Tracing: error
Diag Log: +52BE1DCC.0000     Nofile Limit: None                       Stack Limit: 32M

Meaning: This is a Linux/Unix concern. A TEMS needs 400 file
descriptors for normal processing and an additional file
descriptor for each agent that makes a TCP Socket connection.
The ITM installation guide documents that a TEMS [and WPA
and KDE_Gateway] should specify at least 8192.

In this case the limit is set to 1024 or below. This often
means a serious problem since only 500-600 agents can connect.

Recovery plan: The process of setting this is platform
dependent. For example on Linux this is in /etc/security/limits.conf.

When you do a ulimit -n on the userid where the TEMS will be
running, that should be at least 8192.
--------------------------------------------------------------

TEMSAUDIT1027W
Text: Remote SQL Time Outs - num

Tracing: error

Meaning: During TEMS processing, remote SQL processing
is used to update tables. The above message means that a
remote SQL exceeded the default 600 second limit.

This is not the very serious TEMSAUDIT1008E case. However
such cases are abnormal and can result in incorrect monitoring.

Recovery plan: There is an environment variable
KDS_SYNDRQ_TIMEOUT which can increase the default seconds.
Typical is to change to 1800 seconds or 30 minutes.

The computing environment and capacity should be studied
carefully. Perhaps the TEMS needs to have fewer agents, the
system running the TEMS needs more cpu or memory. In any case
it should be studied and eliminated.
--------------------------------------------------------------

TEMSAUDIT1028W
Text: Concurrent Action Commands - num

Tracing: error (UNIT:kraafira,Entry="runAutomationCommand" all) (UNIT:kglhc1c all)

Meaning: When an action command is processed at the TEMS,
that occurs in the same process space as the TEMS and as a
subprocess. When there are many running, this can de-stabilize
the TEMS and even cause TEMS failures.

Recovery plan: Avoid running action commands at the TEMS unless
you can know for certain they will run infrequently and never
many at the same time.
--------------------------------------------------------------

TEMSAUDIT1029W
Text: Illegal Node Names rejected - num

Tracing: error

Meaning: When an agent name attempts to register with illegal
characters, by default the connection is refused.

First character must not be blank or period or asterisk or hash.
After the first character, the following are legal

A-Z
a-z
0-9
*
  [blank]
-
:
@
$
#
.

Recovery plan: Reconfigure agent with legal characters.
--------------------------------------------------------------

TEMSAUDIT1030W
Text: num Attribute file warning messages

Tracing: error

Meaning: TEMS depends on attribute files to recognize the meaning
and usage of agent defined attribute groups and variables. Occasionally
the attribute files are self-contradictory - with the same attrbute
name defined in two different files. This can lead to incorrect
processing.

Usually this is caused by manual saving of old attribute files. It is
important to know that all attribute files are processed, not just ones
in the standard form.

One specific case involves KTO and KTU - ITCAM for Transactions Collector
and Reporter. This conflict was corrected by APAR IV55733. The APAR text
notes that normal operations are completely unaffected.

Recovery plan: Delete old attribute files or save them in another directory.
--------------------------------------------------------------

TEMSAUDIT1031E
Text: TEMS database table with num Relative Record Number key errors

Tracing: error
Diag Log: (56BC3268.0000-15:kfastins.c,1391,"KFA_PutSitRecord") ***ERROR: for RRN <6076>, (oldest) Index TS <                > does not match TSITSTSH TS <1160209223543004>

Meaning: Count of TEMS database errors of the Relative Record
Number type. The index TS key should contain characters 0-9 and
they do not in this case. This error message was added at the
ITM 630 FP6 level and the APAR change had an error. ITM 630 FP7
will contain APAR  IV87174 fix to eliminate the spurious error.

Recovery plan:  Ignore message.
--------------------------------------------------------------

TEMSAUDIT1032E
Text: KBB_RAS1 missing the very important ERROR specification

Tracing: none
Diag Log: +56B8B325.0000         KBB_RAS1: <not specified>

Meaning: If this is missing from the TEMS environment, the
diagnostic log will be almost worthless in diagnosing issues.

Recovery plan: Make sure KBB_RAS1 specification has the ERROR
specification included. In Windows, this would be usually seen
in the MTEMS Advanced->Edit Trace Parms... dialog box in the
RAS1 Filter data area.
--------------------------------------------------------------

TEMSAUDIT1033W
Text: Node <nodename> has <count> at <addr> sendstatus - possible duplicate agent

Tracing: error (UNIT:kfastinh,ENTRY="KFA_InsertNodests" out er)
Diag Log: (57A0B2C2.000D-48:kfastinh.c,1187,"KFA_InsertNodests") Sending Node Status : node <vsmp8288:VA ... continues for a long way

Meaning: This will be seen in one case of duplicate agent names.
Usually it means two agents are running on the same system with the
same system name. See later report for details.

Recovery plan: This is likely normal if the agent has reconnected.
Otherwise this is abnormal and only one should be running on a system.
--------------------------------------------------------------

TEMSAUDIT1034W
Text: Reflex [Action] Command count failures in count situation(s)

Tracing: error
Diag Log: (578F9048.0009-6:ko4sit.cpp,1573,"Situation::slice") Error : Sit SAPP_DB2_Failedarchive : reflex emulation command returned 4.

Meaning: The TEMS ran an action commands which failed
with a status. The status is not the command exit code. The meaning
is platform dependent can mean failed to start or suffered an exception
[crash] while running. At the least it means that the action command
did not do what was intended.

There are many potential issues with action commands. Here is a technote
that explores many of them:

http://www.ibm.com/support/docview.wss?uid=swg21407744

The following diagnostic trace string will capture more information about
the action commands run.

error (unit:kraafira,Entry="runAutomationCommand" all)(unit:kglhc1c all)

Recovery plan: Rework the action commands so they run as expected. Or perhaps
find a way to do the work without action commands.
--------------------------------------------------------------

TEMSAUDIT1035W
Text: count worrying diagnostic messages - see later report section

Tracing: error
Diag Log: various

Meaning: TEMS normally runs with an error condition diagnostic trace.
When a severe error condition exists, it is common to see many error
messages occur many times in a row. This does not always mean a severe
condition has occured, however when a severe condition occurs there are
often many messages.

This advisory is created when an error source is producing more than
2% of the total number of diagnostic messages. A later report gives more
details. If you are also experiencing symptoms this may aid diagnosis.

This is a work in progress and known normal messages are excluded. The
list of normal messages will be updated over time based on experience.

Recovery plan: If you are experiencing symptoms, involve IBM Support. If
not use your own best judgement.
--------------------------------------------------------------

TEMSAUDIT1036W
Text: Reconnection from remote TEMS to hub TEMS - count times - times

Tracing: error
Diag Log: (57B25924.001A-8:ko4crtsq.cpp,6931,"IBInterface::doStageTwoProcess") Begin stage 2 processing. Database and IB Cache synchronization with the hu

Meaning: The remote TEMS has reconnected with the hub TEMS multiple
times. This has many origins including hub TEMS overload, configuration
problems and communications issues.

Recovery plan: Involve IBM support.
--------------------------------------------------------------

TEMSAUDIT1037E
Text: Indications of port scanning [portscan] which can destabilize any ITM process including TEMS

Tracing: error
Diag Log: (571C6FD5.0000-F6:kdhsiqm.c,772,"KDHS_InboundQueueManager") Unsupported request method "NESSUS"
          (5C220BB.0003-5B:kdebpli.c,115,"pipe_listener") ip.spipe suspending new connections: 1DE0000D
          (55C14E21.0001-8B:kdebp0r.c,235,"receive_pipe") Status 1DE00074=KDE1_STC_DATASTREAMINTEGRITYLOST
          (55C14E21.0002-89:kdhsiqm.c,548,"KDHS_InboundQueueManager") error in HTTP request from ip.ssl:#10.107.19.12:33992, status=7C4C803A, "unknown method in request"

Meaning: ITM processes do not defend against port scanning. After 120
such detected cases the affected port will stop listening.

Recovery plan: Work with security team to NOT do port scanning against
known valid ITM listening ports.
--------------------------------------------------------------

TEMSAUDIT1038W
Text: Communication Tracing set - only use on advisement

Tracing: error
Diag Log: (540827D1.001C-4:kbbracd.c,126,"set_filter") *** KDC_DEBUG=Y is in effect

Meaning: Communication tracing is very powerful. However it consumes
an enormous proportion of the limited tracing logs and often hides
important information. This can delay diagnostic work considerably.

Only use these settings when IBM L3 support/development or very experienced
other IBM support people advise.

Recovery plan: Avoid such use unless advised by IBM Support.
--------------------------------------------------------------

TEMSAUDIT1039W
Text: Remote Procedure call Connection lost count - see following report

Tracing: error
Diag Log: (57BE11EA.0006-2:kdcc1sr.c,485,"rpc__sar") Connection lost: "ip.pipe:#172.27.2.10:7025", 1C010001:1DE0004D, 0, 130(0), FFFA/30, D140831.1:1.1.1.13, tms_ctbs630fp5:d5135a

Meaning: Remote Procedure call failed. Most of ITM communications
is performed via remote procedure calls using the Network Communication
Services architecture. Connection losts at a high frequency imply
a serious network issue and ITM processing is often unstable. At a low
level ITM basic services will recover and run normally.

If ITM is unstable, work with your local networking support people and
resolve whatever is causing the network failures.

IDE0004D corresponds to KDE1_STC_INVALIDTRANSPORTCORRELATOR which often
means the tcp socket connect was closed unexpectedly. There are many
such codes. There has been an increase in cases where customer
networking firewall rules close tcp socket connections which are idle
for some fixed time. This probably benefits overall networking efficiency
but it often has a major negative impact on ITM stablity and usefulness.

Recovery plan: IBM Support can help in understanding the basic issues but
resolution depends on customer network support.
--------------------------------------------------------------

TEMSAUDIT1040E
Text: TEMS database table with num Open Index errors

Tracing: error
Diag Log: (57DAB05B.000E-6:kglkycbt.c,2091,"InitReqObj") Open index failed. errno = 12,file = QA1CSTSH. index = PrimaryIndex
          (58B7E159.0002-3:kglkycbt.c,835,"kglky1rs") isam error. errno = 7.file = QA1CSITF, index = PrimaryIndex,

Meaning: Count of TEMS Open Index database errors.

Recovery plan:  Work with IBM Support. The issue is severe
and needs prompt attention.
--------------------------------------------------------------

TEMSAUDIT1041E
Text: TEMS database table SITDB [QA1CRULD] with num Read errors

Tracing: error
Diag Log: (587E44A6.0002-7:kdsruc1.c,6623,"GetRule") Read error status: 5 reason: 26 Rule name: KOY.VKOYSRVR

Meaning: Count of Read Errors on the QA1CRULD - SITDB - database file.
This means certain situations are not running.

Recovery plan:  Work with IBM Support. The issue is severe
and needs prompt attention. It can usually be resolved by
resetting QA1CRULD and QA1CCOBJ to emptytable status.
--------------------------------------------------------------

TEMSAUDIT1042E
Text: count "activity not in call" reports

Tracing: error
Diag Log: (5890C272.0000-5D3:kdcc1wh.c,114,"conv__who_are_you") status=1c010008, "activity not in call", ncs/KDC1_STC_NOT_IN_CALL

Meaning: This condition occurs between any two ITM processes
where at least one side is running on an AIX system. The impact
is that the activity is lost. That can result in many
issues such as agent unable to monitor. The only good news
is the issue is rare.

The issue is completely resolved in ITM 630 FP7 and documented
here

APAR IV78468: AGENT ON AIX LOSES CONNECTION TO THE TEMS
http://www-01.ibm.com/support/docview.wss?uid=swg1IV78468

Running with KDC_DEBUG=Y will give additional information about
the source of the lost activities.

Recovery plan:  Upgrade the ITM components involved. That means
TEMS/WPA/S&P/TEPS and OS Agents running on AIX systems..
----------------------------------------------------------------

TEMSAUDIT1043E
Text: Failed Reconnection from remote TEMS to hub TEMS - count times

Tracing: error
(58C18A6C.0000-6:ko4crtsq.cpp,7146,"IBInterface::doStageTwoProcess") End stage 2 processing. Database and IB Cache synchronization with the hub with return code: 1

Meaning: The remote TEMS failed the stage 2 resynchronization
process with the hub TEMS. That means it could not get the
three major tables TNODELST, TOBJACCL and TSITDESC. After that
the remote TEMS runs in a largely failure mode not doing
what was intended.

In some cases the remote TEMS needs to be configured with a
longer remote SQL timeout.

Remote TEMS fails to startup
http://www.ibm.com/support/docview.wss?uid=swg21591476

That can occur if the tables get significantly larger, the
latency between remote and hub TEMS gets larger, or the
system running the remote TEMS has less than needed capacity.

Recovery plan:  Work with IBM support to diagnose and correct
the condition.
----------------------------------------------------------------

TEMSAUDIT1044E
Text: TEMS database table with $etct Verify Index errors

Tracing: error
(58DD7571.002C-1:kglisopn.c,949,"I_ifopen") Verify of QA1CNODL.IDX failed

Meaning: When a TEMS starts up after a failure, the TEMS
database files have an index verify performed. If this
fails that means things are seriously wrong and the
TEMS will be unstable or fail again.

Recovery plan:  Work with IBM support to correct the condition.
----------------------------------------------------------------

TEMSAUDIT1045W
Text: TEMS TCHECKPT Timestamp invalid count time(s)

Tracing: error
(58C49DE0.0000-B:kqmchkpt.cpp,619,"checkPoint::setGblTimestamp") Invalid checkpoint timestamp - ignoring. NAME = <M:LOCALNODESTS> TIMESTAMP <1170312020051000>,

Meaning: The TCHECKPT table is critical for proper operation
of the Fault Tolerant Option [FTO]. This message suggests
that the FTO process is not working as planned.

Usually the related database files can be reset to emptytable
status on both primary and backup hub TEMS to restore normal
operation.

Recovery plan:  Work with IBM support to correct the condition.
----------------------------------------------------------------

TEMSAUDIT1046W
Text: MQ/Config or Config should run only on hub TEMS and not a remote TEMS

Tracing: error
(58DE3A4E.007A-12:kcfccmmt.cpp,674,"CMConfigMgrThread::indicateBackground") Error in pthread_attr_setschedparam,

Meaning: The Config process is designed to run only on a
hub TEMS. When operating on a remote TEMS the best case is
excess hub TEMS workload. The worst case is remote TEMS
instability.

It should not be configured on a hub TEMS using FTO. Best
practive is to set up a separate hub TEMS just for Config
in that case.

Recovery plan: Unconfigure Config from the remote TEMS.

Windows: remove KCFFEPRB.KCFCCTII from KDS_RUN from
  <installdir>\cms\KBBENV

Linux/Unix: remove KCFFEPRB.KCFCCTII from KDS_RUN from
  <installdir>/tables/<temsnodeid>/KBBENV and
  <installdir>/config/kbbenv.ini

zOS: remove KCFFEPRB.KCFCCTII from KDS_RUN from
  RKANDATU(KMSENV)

and recycle the remote TEMS.
----------------------------------------------------------------

TEMSAUDIT1047W
Text: TEMS configured with KDS_WRITENOS=YES

Tracing: error
(58CE9A38.0002-1:kbbssge.c,72,"BSS1_GetEnv") KDS_WRITENOS="YES"

Meaning: This option causes TEMS to keep a disk copy of
the node status table. It was created during ITM development
many years ago and has not been tested since perhaps
2001. It has never been publically documented.

The impact is worse TEMS performance and possible TEMS
instability because of no testing.

Recovery plan: Remove the setting. In the most recent case
it was discoved in <installdir>/config/kbbenv.ini file, but
it could be anyplace. If you cannot locate it, contact
IBM Support to assist.
----------------------------------------------------------------

TEMSAUDIT1048E
Text: Storage allocation [count] failure(s)

Tracing: error
(58E42EB8.0000-1110:kdsdscom.c,196,"VDM1_Malloc") GMM1_AllocateStorage failed - 1

Meaning: There are messages stating that storage allocation failed.
This most often seen in Windows as the kdsmain process size approaches
the 2gig [32-bit] or 4gig [64-bit] limit. It used to be seen in Unix
at 2gig until ITM 623 FP2. It is still seen in any environment
if paging space cannot handle the kdsmain process size.

The impact is severe and usuall a TEMS failure is imminent.

Recovery plan: Work with IBM Support to determin the underlying
cause. It could be too much workload, environmental factors like
paging space, too many agents etc etc.
----------------------------------------------------------------

TEMSAUDIT1049E
Text: Definite Evidence of port scanning [$scantype] which can destabilize any ITM process including TEMS

Tracing: error
(55C220BB.0003-5B:kdebpli.c,115,"pipe_listener") ip.spipe suspending new connections: 1DE0000D
(58FAAE7F.0000-61B7B:kdebbac.c,50,"KDEB_BaseAccept") Status 1DE0000D=KDE1_STC_IOERROR=72: NULL

Meaning: The log indicates port scanning is taking place.

There is a diagnostic fix referenced here

https://www-304.ibm.com/support/entdocview.wss?uid=swg1IV85368

When that diagnostic fix is installed and enabled, there are
documented messages which identify the ip address source of the
port scanning.

Recovery plan: Critical plan is to work with network and security
team to NOT port scan ITM processes. As an alternative stop the
ITM processes during such scanning.
----------------------------------------------------------------

TEMSAUDIT1050W
Text: Agent connection churning on [count] systems total[count] - See following report

Tracing: error
(58DA4E42.0511-73:kdepnpc.c,138,"KDEP_NewPCB") 151.88.15.201: 10B0C8C6, KDEP_pcb_t @ 1383B83B0 created
(58DA4EFE.00B1-174:kdepdpc.c,62,"KDEP_DeletePCB") 10B0C8C6: KDEP_pcb_t deleted

Meaning: When an agent connects there is a NewPCB log entry. PCB means
Process Control Block. When that connection is dropped there is a
DeletePCB entry. These are all normal messages. However the DeletePCB
is relatively rare. It might be seen when an agent is recycled.

In one circumstance two agents were seen which had an ITM communications
conflict. One Agent had a control

KDEB_INTERFACELIST=!xxx.xxx.xxx.xxx

and another agent had no such control. In that circumstance the first
agent created a exclusive bind on its listening port. The second agent
created a non-exclusive bind on the same listening port. The main
diagnostic clue was many DeletePCB messages - two every 10 minutes.
This causes severe problems for ITM since each agent knocks out
the other agent each cycle.

This advisory concerns cases where there are DeletePCB messages.
A later report section gives details.

Recovery plan: The report shows the ip address of the system
but does not give the agent name. Review all the agents looking
for the KDEB_INTERFACELIST issue. If the issue is not obvious
involve IBM Support to assist.
----------------------------------------------------------------

TEMSAUDIT1051E
Text: Remote TEMS has lost connection to HUB count times

Tracing: error
(58D77E39.0002-11A0:ko4mgtsk.cpp,133,"ManagedTask::sendStatus") Connection to HUB lost - stopping situation status insert

Meaning: This is produced when a remote TEMS can no longer connect
with a hub TEMS. Usually the remote TEMS is attempting something
like a situation status insert. Sometimes the remote TEMS can
recover for a while and then lose connection again.

This is a severe issue and needs prompt diagnosis. It can be
caused by many reasons including TEMS database problems,
network problems and excessive workload.


Recovery plan: Contact IBM support for aid in diagnosis.
----------------------------------------------------------------

TEMSAUDIT1052E
Text: Hub TEMS has lost connection to HUB count times

Tracing: error
(58D77E39.0002-11A0:ko4mgtsk.cpp,133,"ManagedTask::sendStatus") Connection to HUB lost - stopping situation status insert

Meaning: This is produced when one hub TEMS task can no longer
connect with the dataserver function of the hub TEMS. This
is a severe error which is only recovered with a hub TEMS recycle.
The hub TEMS will not recover without a recycle.

This is a most severe issue and needs prompt diagnosis. It can be
caused by many reasons including TEMS database problems,
network problems and excessive workload.

Recovery plan: Contact IBM support for aid in diagnosis.
----------------------------------------------------------------

TEMSAUDIT1053W
Text: Time interval expired late count times

Tracing: error
(590CFA4B.002B-449:kgltmbas.c,725,"DriveTimerExit") KDSTMDTE: Interval Missed Seconds=1494015924 Nsecs=763544806 Detected at Seconds=1494022731 Nsecs=80363777

Meaning: This message is seen when ITM logic sets an expiry time and
later when the exit routine is runs the logic discovers that some
intermediate timer exits were missed.

This condition is only seen when the ITM process is under extremely
heavy load. Think of it as a skipped heartbeat, There are
probably a lot of other bad conditions happening.

Recovery plan: Reduce workload or run ITM process on a more
powerful system.
----------------------------------------------------------------

TEMSAUDIT1054W
Text: SOAP Error Types [count] Detected - See following report

Tracing: error
(59082197.0003-2B7:kshhttp.cpp,493,"writeSoapErrorResponse") faultstring: CMS logon validation failed.
(59082197.0004-2B7:kshhttp.cpp,523,"writeSoapErrorResponse") Client: ip.ssl:#158.98.69.8:42858

Meaning: These errors mean SOAP failures. The might mean nothing
more than a side effect of testing and development. However if
there are floods of them like "CMS logon validation failed" then
a production process might be failing. Other cases might imply
an environment issue such as a hub TEMS with too much workload.

Recovery plan: Investigate the SOAP workload and correct as needed.
----------------------------------------------------------------

TEMSAUDIT1055W
Text: Agent Location Flipping Changes Detected [count] - See following report

Tracing: error
(590DD139.0000-C5:kfaprpst.c,3649,"NodeStatusRecordChange") Host info/loc/addr change detected for node <uuc_wtwavwq9:06                 > thrunode <REMOTE_usitmpl8057-itm2         > hostAddr: <ip.spipe:#192.168.10.72[4206]<NM>uuc_wtwavwq9</NM>          >
(59103772.0000-C9:kfaprpst.c,3618,"NodeStatusRecordChange") Affinities change detected for node <uuc_scent5010:NT                > thrunode <REMOTE_usitmpl8044              > hostAddr: <ip.spipe:#10.188.5.10[60467]<NM>uuc_scent5010</NM>          >
(590D97C3.0002-69:kfaprpst.c,3632,"NodeStatusRecordChange") Version change detected for node <CustomMSG:uuc_uswasx3c8:LO      > thrunode <REMOTE_usitmpl8047              > hostAddr: <ip.spipe:#10.56.38.101[34393]<NM>uuc_uswasx3c8</NM>         >
(5907C6CF.0001-28:kfaprpst.c,3582,"NodeStatusRecordChange") Thrunode change detected for node <CustomMSG:uuc_ussaspa601:LO     > thrunode <REMOTE_usitmpl8055              > Old thrunode <REMOTE_usitmpl8054              > hostAddr: <ip.spipe:#10.113.3.8[63646]<NM>uuc_ussaspa601</NM>          >

Meaning: These message mean that an agent is flipping from
one location and/or thrunode and/or ip address to another.

A certain number of those are expected as agents are recycled
or change from one remote TEMS to another. However when these
are seen in volume, there can be configuration issue including
accidental duplicate agent names.

Duplicate agents can cause TEPS slow response and TEMS instabilty
including crashes. In addition the agents involved are not
being monitored full time as expected. Therefore it is important
to resolve the issues and restore normal function.

Recovery plan: Investigate the Agents involved and resolve
issue if needed.
----------------------------------------------------------------

TEMSAUDIT1056W
Text: Missing Application/Table/Column string count times

Tracing: error
(591116EF.0000-EEC:kdspmcat.c,979,"CompilerCatalog") Column ATFSTAT in Table LIMS_SYSS for Application KIP Not Found.

Meaning: This means application support is missing or
backlevel. The impact is that situations and real time
reports will not be run as expected.

Recovery plan: Install the missing application support.
----------------------------------------------------------------

TEMSAUDIT1057W
Text: Sequence Number Overflow count times - rapid incoming events

Tracing: error
(5912EC8A.05F0-1F:kfastplr.c,92,"KFA_LogRecTimestamp") Sequence number overflow, reusing 999

Meaning: This is sometimes normal and sometimes abnormal.

At the hub TEMS incoming events are assigned a time stamp
valid to the second. The ITM time stamp has three characters
past the second used to record sequence of arrival during
that second - sort of a tie breaker. If more than 999 events
arrive in one second, this message is produced.

This is sometimes seen in FTO [Fault Tolerant Option] configuration
and is considered normal.

If this occurs more often the workload [situations] should be
examined and changed to avoid the issue. In the worst case
such a high volume can cause TEMS instablity and even crashes.

Recovery plan: Change workload to avoid such intense levels
of activity.
----------------------------------------------------------------

TEMSAUDIT1058E
Text: GSKIT Secure Communications - no common cipher found

Tracing: error
(59183B36.0000-53:kdebeal.c,81,"ssl_provider_open") GSKit error 402: GSK_ERROR_NO_CIPHERS - errno 11

Meaning: When secure communications is established using
GSKIT, a common cipher is negotiated. This message means
there is no common cipher defined and thus communications
has failed.

Recovery plan: Reconfigure the two ITM processes so there is a
a common cipher.
----------------------------------------------------------------

TEMSAUDIT1059W
Text: KGLCB_FSYNC_ENABLED is not numeric [value]

Tracing: error
(591F44AA.0015-1:kglcbbio.c,129,"kglcb_getFsyncConfig") fsync() is ENABLED. KGLCB_FSYNC_ENABLED=''0''

Meaning: The setting was likely '0' instead of 0. This will
reverse the intent of the setting.

On the other hand, this setting to 0 is very bad practice
and puts the TEMS database files at increased risk of corruption.

Recovery plan: Remove that setting whereever it is defined.
----------------------------------------------------------------

TEMSAUDIT1060W
Text: Situations [count] with length 32 - see following report

Tracing: error
(591F66A7.0000-8:ko4sitma.cpp,481,"IBInterface::lodge") Error: sit name <ARG_NT_DisSpa_Cr_COIBMPDPW6K01_1> length <32> invalid

Meaning: These are likely situations composed in ITM 6.1 level when
situation names could be 32 bytes long. From ITM 6.2 onward these
are not permitted. The result is that the situations are not running.

Recovery plan: Re-author the situations with a shorter name.
----------------------------------------------------------------

TEMSAUDIT1061E
Text: Situation [name] with unknown attribute [attribute] - [pdt]

Tracing: error
(591F66A5.0003-8:ko4rulex.cpp,729,"PredParser::build") Error: Failed to process situation formula rc <1133>
(591F66A5.0004-8:ko4rulex.cpp,731,"PredParser::build") ..Situation: <ARG_UX_FilSys_M1386196025092200>
(591F66A5.0005-8:ko4rulex.cpp,732,"PredParser::build") ..PDT:       <*IF ((*VALUE Disk.Mount_Point_U *EQ '/proc' *AND *VALUE Disk.Space_Used_Pce_Used_Percent *LT 90))>
(591F66A5.0007-8:ko4rulfa.cpp,121,"NodeFactory::createNode") Error: Unknown attribute <Disk.Space_Used_Pce_Used_Percent> at position <56>

Meaning: This message means the application support is missing
or out of date compared to the hub TEMS. As a result the situations
will not run as expected

Recovery plan: Install the missing application support at the TEMS.
----------------------------------------------------------------

TEMSAUDIT1062W
Text: Node [agent] thrunode [tems] ignored because attribute unknown

Tracing: error
(591F6750.0002-2C:kfastinh.c,1114,"KFA_InsertNodestatus") Affinity not loaded for node <UMBSRVCTXDEV:XA> thrunode <RTEMS02> affinities <%IBM.KXA                0000000001000Jyw0a7>.  Node Status Ignored.

Meaning: This message means the application support is missing
for the agent connecting. It is ignored.

Recovery plan: Install the missing application support at the TEMS.
----------------------------------------------------------------

TEMSAUDIT1063E
Text: TEMS cannot create Rule tree [count] times

Tracing: error
(59198D87.0005-9:kdssnc1.c,967,"CreateSituation") Cannot create the RULE tree

Meaning: This is quite serious. The situation formula [or predicate] is converted
to ITM SQL during situation start. The SQL is stored in the SITDB table
QA1CRULD.DB/IDX file. Usually this means the SITDB file is broken in some way.

The result is that situations are not running as expected.

Recovery plan: Reset the QA1CRULD.DB/IDX and the QA1CCOBJ.DB/IDX
files to emptytable status while the TEMS is stopped. This is always
safe since needed entries will be rebuild. See this document for
details http://ibm.biz/BdsYzS - or contact IBM Support for aid.
----------------------------------------------------------------

TEMSAUDIT1064E
Text: TEMS Short Term History file [name] is broken [count] times

Tracing: error
(591D9C01.0005-129:khdxhist.cpp,3796,"validateRow") History file T6SUBTXCS corruption found at file position 008F2E18. EndOfFileReached = 0, CurrRowValid = 0, NextRowValid = 1.

Meaning: Best practice is to collect historical data at the agent.
However it is is kept at the TEMS, the above condition means that
the named attribute group is not in the proper form. Because of this
none of the historical data will be exported to the TDW.

Recovery plan: Usual recovery is to save the XXXX and XXXX.hdr file
and then while TEMS is stopped erase those two files. XXXX represents
the STH file name involved. If it is critical to recover some of the
historical data, work with IBM Support.
----------------------------------------------------------------

TEMSAUDIT1065W
Text: Situation with *TIME returned invalid timestamp [count] times

Tracing: error
(59199276.0204-39D:kdsxoc2.c,2081,"VXO2_MakeTime") MKTIME result is not a valid timestamp (mktime returned -1)

Meaning: This condition needs additional diagnostic tracing to
determine what situation(s) are involved. One diagnosed case
was a situation against FILEINFO where *TIME was used and so
much data was returned that the internal limit of 16 megs
was reached only partial data was returned. In another case a
file system returned all zeros - APAR IV50626 was created at
ITM 623 FP5 to suppress such errors.

Situation formula with *TIME can be highly impactful and can
even de-stabilize the TEMS receiving the data.

Recovery plan: Determine which situations are causing the issue
and consider how to rework them to avoid the issue.
----------------------------------------------------------------

TEMSAUDIT1066W
Text: EIF unknown transmision target [none] $eipc_none times

Tracing: error
(59198C7E.005E-A:socket_imp.c,2020,"_create_eipc_client") KDE1_StringToAddress returned 0x1DE00003 for none

Meaning: TEMS can be configured to send event data to an
event receiver - EIF or Event Integration Facility. The target
is defined during a hub TEMS configuration.

When there is no event receiver, that address must be entered
as the number 0. This message indicates the configuration
was set to "none". In that case the EIF facility keeps looking
to resolve "none" as a domain name and complains at the failiure.

Recovery plan: Recongfigure the TEMS and specify zero [0] as the
EIF target if no event receiver target is needed.
----------------------------------------------------------------

TEMSAUDIT1067E
Text: Unable to get attributes for table <table> [<count> times]

Tracing: error
(591ACD2E.0000-7C:kshcat.cpp,296,"RetrieveTableByTableName") Unable to get attributes for table tree TOBJACCL

Meaning: The SOAP request failed. This hints of an out of storage
issue, a broken attribute collection or mssing application
support files.

Recovery plan: Work with IBM Support to resolve issue.
----------------------------------------------------------------

