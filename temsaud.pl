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

## (591ACD2E.0000-7C:kshcat.cpp,296,"RetrieveTableByTableName") Unable to get attributes for table tree TOBJACCL

## monitor cases where port != 1918/3660 + N*4096, or +1

## extract out last 10 lines of itm_config.log

## (56CF3C07.0000-8:kdspmou2.c,3077,"PM1_VPM2_AllocateLiteral") Literal Pool Boundary Violated (61/7/64304)
## (56CF3C07.0001-8:kdspmou1.c,721,"PM1_CompilerOutput") Cannot build table object, status = 201
## (56CF3C07.0002-8:kdspmcv.c,1063,"CreateTable") VPM1_Output Failed status: 201
## (56CF3C07.0003-8:kdspmcv.c,1064,"CreateTable") Compiler output error, status = 201
## (56CF3C07.0004-8:kdsvws1.c,1371,"CreateServerView") Bad status from VPM1_CreateTable, 201
## (56CF3C07.0005-8:kdspac1.c,2011,"VPA1_CreateRequest") Create request failed with return code 201
## (56CF3C07.0006-8:kdsruc1.c,5815,"CreateRequest") Cannot create request, status = 201
## (56CF3C07.0007-8:kdsruc1.c,6378,"DecomposePredicate") Cannot create request, status = 201
## (56CF3C07.0008-8:kdsruc1.c,4439,"CreateRuleTree") Cannot create rule tree, status = 201
## (56CF3C07.0009-8:kdssnc1.c,967,"CreateSituation") Cannot create the RULE tree
## (56CF3C07.000A-8:kdspmou1.c,716,"PM1_CompilerOutput") Cannot set root table, status = 201
## (56CF3C07.000B-8:kdspmcv.c,1063,"CreateTable") VPM1_Output Failed status: 201
## (56CF3C07.000C-8:kdspmcv.c,1064,"CreateTable") Compiler output error, status = 201
## (56CF3C07.000D-8:kdsvws1.c,1371,"CreateServerView") Bad status from VPM1_CreateTable, 201
## (56CF3C07.000E-8:kdspac1.c,2011,"VPA1_CreateRequest") Create request failed with return code 201
## (56CF3C07.000F-8:ko4async.cpp,2685,"IBInterface::sendAsyncRequest") createRequest failure prepare <12D9A1B70>
## (56CF3C07.0010-8:ko4sitma.cpp,935,"IBInterface::lodge") error: Lodge <1131>
## (56CF3C07.0011-8:ko4ibstr.cpp,686,"IBStream::op_ls_req") IB Err: 1131
## (56CF3C07.0012-8:ko4sit.cpp,870,"Situation::slice") Sit vil_fss_xuxc_mediatn: Unable to lodge - giving up.

## Can't initialize filter plan, PRB1_InitFilterPlan status 58

## (5970A187.0001-13:kdebeal.c,81,"ssl_provider_open") GSKit error 407: GSK_ERROR_BAD_KEYFILE_LABEL - errno 11

## kqmsnos.cpp|processARMSNOS::processRecs|367,87084,46%,(597AB870.0001-A:kqmsnos.cpp,367,"processARMSNOS::processRecs") Warning: Invalid timestamp in node status record: <dcn1papx617:KUX> <REMOTE_UKSWI-DLTVPVL01> <ip.pipe:#172.30.166.54[59283]<NM>dcn1papx617</NM>> <V>  <Y> at <1170728050701000> locflag <M> <9> <%IBM.STATIC013          000000000U000pyw0a7> <parent>
## kqmlog.cpp|processARMeib::processRecs|779,22530,11%,(597AB875.0000-A:kqmlog.cpp,779,"processARMeib::processRecs") Warning: Invalid timestamp in notify record: operation <I> id <5529> name <RTMAS0146:53                    REMOTE_UKRTH-MCTVPVL06> timestamp <1170728050707001> user <_FAGEN> originnode <>

## ??
## (5940BF37.0046-261F:kdebp0r.c,591,"receive_vectors") ephemeral ip.spipe: peer address translated

## KBB_RAS1=    warn of this case

## (2017/07/21,11:52:55.0005-123:kdcr0ip.c,234,"KDCR0_InboundPacket") Packet too short; is 80, data len is 49193
## (2017/07/21,11:52:55.0006-123:kdcr0ip.c,236,"KDCR0_InboundPacket") status=1dc0000f, "packet length invalid", ncs/KDC1_STC_BADPACKETLENGTH
## KGL_GMMSTORE=2048   or 4096?
## KDS_HEAP_SIZE=2048

## (58694088.0001-3A:khdxhist.cpp,3058,"copyHistoryFile") Found 1 corrupted rows for "KA4PFJOB". Rows were skipped during copying.

## (59B12EE8.0156-15:kde0srq.c,57,"enqueue_sqe") Not starting new service thread because maximum of 16 reached

## capture node status if available !1

## (59DFC978.0002-9:ko4rulex.cpp,920,"PredParser::getDescription") Error: Missing situation <Linux_BP_SpaceUsedPct_Critical>.

## (5927EF95.0000-7:ko4stg3u.cpp,569,"IBInterface::handleNodelistRecord") Error: <1136> failed to download node list record
## (5927EF95.0001-7:ko4eibr.cpp,142,"EibRecord::dump") operation <I> id <5529> obj name <CTXAPP0054VB:51>
## (5927EF95.0002-7:ko4eibr.cpp,143,"EibRecord::dump") send id <> origin <>
## (5927EF95.0003-7:ko4eibr.cpp,144,"EibRecord::dump") timestamp <1170526040407000> user <_FAGEN>
## (5927EF95.0004-7:ko4eibr.cpp,145,"EibRecord::dump") raw obj <CTXAPP0054VB:51                 REMOTE_USDAD-METVPVL01>

##  (59F11DA8.55E2-2B00:kfaibloc.c,859,"IBL_Process") status = 62, jvalstatus = 0, records = 38113
##  count of records retrieved from TEMS database??

## (unit:kfaibloc state er)
## (59F21851.060D-1E08:kfaibloc.c,541,"IBL_Process") StartBrowse (scan: 1, keylen: 64) at '' in TOVERITEM(QA1DOVRI   )
## (59F21851.062C-1E08:kfaibloc.c,859,"IBL_Process") status = 62, jvalstatus = 0, records = 2

## (59F300BA.0006-8:ko4accpr.cpp,1463,"WOSActivity::populate") Error: pcy <Run_nodata_Situations> act <WaitOnSituation1> tgt <bnc_check_datacollection_tems> sit def not found

## (5A1D433C.0002-107:kshdsr.cpp,361,"login") Create Path Error st=1010 for 'ie4013t' 'xxxxxxxx' 'ip.ssl'
## (5A1D433C.0003-107:kshhttp.cpp,493,"writeSoapErrorResponse") faultstring: CMS logon validation failed.
## (5A1D433C.0004-107:kshhttp.cpp,523,"writeSoapErrorResponse") Client: ip.ssl:#127.0.0.1:59190

## (5A2668D0.0004-68:kdsvws1.c,2421,"ManageView") ProcessTable TNODESTS Insert Error status = ( 1551 ).  SRVR01 ip.spipe:#10.64.11.30[3660]

## (5A3E5FA4.0008-110:ko4bkgnd.cpp,482,"BackgroundController::nodeStatusUpdate") TEMS heartbeat insert failed with status 1542

my $gVersion = 1.81000;
my $gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

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
my $opt_jitter = 0;                              # assume no jitter report
my $opt_noded = 0;                               # track inter-arrival times for results
my $opt_b;
my $opt_level = 0;                               # build level not found
my $opt_driver = "";                             # Driver
my $opt_sum;                                     # Summary text
my $opt_nodeid = "";                             # TEMS nodeid
my $opt_tems = "";                               # *HUB or *REMOTE
my $opt_kdcb0 = "";                              # KDCB0_HOSTNAME
my $opt_kdebi = "";                              # KDEB_INTERFACELIST
my $opt_sqldetail;                               # detail SQL report wanted
my $opt_rd;                                      # result detail wanted
my $opt_rdslot;                                  # number of seconds for result detail slot, default 60 seconds
my $opt_rdtop;                                   # number of situations to display
my $ssi = -1;
my @ssout;
my $opt_flip = 1;
my $opt_eph;                                     # produce ephemeral report
my $opt_ephdir;                                  # produce ephemeral report
my $opt_sth;                                     # produce event history status report
my $opt_stfn;                                    # event history filename
my $opt_ndfn;                                    # node history filename
my $opt_evslot = 1;
my $start_date = "";
my $start_time = "";
my $local_diff = -1;


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
my $tempInt;
my $f;
my $g;
my $h;


my @seg = ();
my $segcurr;
my $i;
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
sub sec2ltime;
sub getphys;

my $hdri = -1;                               # some header lines for report
my @hdr = ();                                #

my %mhmx = ();

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
              "TEMSAUDIT1068W" => "85",
              "TEMSAUDIT1069W" => "85",
              "TEMSAUDIT1070W" => "85",
              "TEMSAUDIT1071W" => "85",
              "TEMSAUDIT1072W" => "85",
              "TEMSAUDIT1073W" => "85",
              "TEMSAUDIT1074W" => "85",
              "TEMSAUDIT1075I" => "00",
              "TEMSAUDIT1076W" => "85",
              "TEMSAUDIT1077W" => "85",
              "TEMSAUDIT1078E" => "100",
              "TEMSAUDIT1079W" => "85",
              "TEMSAUDIT1080E" => "100",
              "TEMSAUDIT1081E" => "100",
              "TEMSAUDIT1082E" => "100",
              "TEMSAUDIT1083W" => "90",
              "TEMSAUDIT1084W" => "95",
              "TEMSAUDIT1085W" => "85",
              "TEMSAUDIT1086W" => "90",
              "TEMSAUDIT1087W" => "50",
              "TEMSAUDIT1088W" => "99",
              "TEMSAUDIT1089E" => "100",
              "TEMSAUDIT1090I" => "0",
              "TEMSAUDIT1091I" => "0",
              "TEMSAUDIT1092W" => "50",
              "TEMSAUDIT1093E" => "100",
            );

my %advtextx = ();
my $advkey = "";
my $advtext = "";
my $advline;
my %advgotx = ();
my %advrptx = ();

my %sit32x = ();
my %sitrulx = ();
my $sitrul_ref;
my $sitrul_state = 0;
my $sitrul_sitname = 0;
my $sitrul_pdt = 0;
my $sitrul_atr = 0;

my %readnextx;

my %node_ignorex = ();

my %sthx = ();

my %sitrowx = ();
my $sitrow_key;
my $sitrow_ref;

my %soapcat = ();

my %recvectx= ();        # receive vectors to translate ephemeral ip addresses
my $rvect_def;
my %rvrunx = ();         # receive vector running capture by thread
my $rvrun_def;
my $rvrun_last_line = 0;
my $rvrun_last_thread = "";
my $rvrun_last_def = "";
my %dnrunx = ();         # Duplicate Node warning by thread
my $dnrun_def;
my %dnodex = ();

my %rxrunx = ();         # receive XID running capture by thread
my $rxrun_def;

my %physicalx = ();
my %pipex = ();

my %prtx;      # Process table capture
my %prtrunx;   # Process table run capture by thread
my %prtdurx;    # Duration
my $prt_current = 0;
my $prt_max = 0;
my $prt_max_l = 0;

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
                "kfastins.c|KFA_PutSitRecord" => 1,
                "kfaottev.c|Get_ClassName" => 1,
                "kfaottev.c|KFAOT_Translate_Event" => 1,
             );

my %rdx;
my $rd_ref;
my $sit_ref;

my %codex;
my $code_ref;
my $conv_ref;

my %pcbx;
my %pcbr;

my %rbdupx;
my $rbdup_ref;
my $grace = 5;   # seconds

my $hublost_total = 0;
my %gskiterrorx = ();
my $intexp_total = 0;
my $seq999_total = 0;
my $ruld_total = 0;
my $mktime_total = 0;
my $eipc_none = 0;

my %hist_corruptedx;


my %soaperror;
my $soaperror_fault = "";
my $soaperror_client = "";
my $soaperror_ct;
my $tec_translate_ct = 0;
my $tec_classname_ct = 0;

my %changex;
my $changex_ct = 0;

my %misscolx;
my $misscolx_ct;

my %nodestx;

my $nodelist_error;
my $nodelist_operation;
my $nodelist_id;
my $nodelist_objname;
my $nodelist_agent;
my $nodelist_tems;
my $nodeliste_state = 0;
my %nodelistex;
my $nodeliste_count = 0;

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
my %portscan_timex;

while (<main::DATA>)
{
  $advline = $_;
  $advline =~ s/\x0d//g if $gWin == 0;
  if ($advkey eq "") {
     chomp $advline;
     $advkey = $advline;
     next;
  }
  if (length($advline) >= 14) {
     if ((substr($advline,0,9) eq "TEMSAUDIT") or (substr($advline,0,10) eq "TEMSREPORT")){
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
my $opt_portscan = 1;                         # portscan report
my $opt_last = 1;
my $opt_churnall = 0;                         # when 1, produce 100% churn report

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
   } elsif ($ARGV[0] eq "-noflip") {
      $opt_flip = 0;
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
   } elsif ($ARGV[0] eq "-jitter") {
      $opt_jitter = 1;
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
   } elsif ($ARGV[0] eq "-ephdir") {
      shift(@ARGV);
      $opt_ephdir = shift(@ARGV);
      die "-ephdir output specified but no path found\n" if !defined $opt_ephdir;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-eph") {
      $opt_eph = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-sth") {
      $opt_sth = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-evslot") {
      $opt_evslot = 10;
      shift(@ARGV);
      if (defined $ARGV[0]) {
         if (substr($ARGV[0],0,1) ne "-") {
            $opt_evslot = $ARGV[0];
            shift(@ARGV);
         }
      }
   } elsif ($ARGV[0] eq "-nohdr") {
      $opt_nohdr = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-rd") {
      $opt_rd = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-noportscan") {
      $opt_portscan = 0;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-churnall") {
      $opt_churnall = 1;
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
if (!defined $opt_eph) {$opt_eph = 0;}
if (!defined $opt_ephdir) {$opt_ephdir = "";}
if (!defined $opt_sth) {$opt_sth = 0;}
$opt_stfn = "eventhist.csv" if $opt_sth == 1;
$opt_ndfn = "nodehist.csv" if $opt_sth == 1;


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
      my $uword = uc $words[0];
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
      elsif (substr($uword,0,9) eq "TEMSAUDIT"){
         die "unknown advisory code $words[0]" if !defined $advcx{$uword};
         die "Advisory code $words[0] with no advisory impact" if !defined $words[1];
         $advcx{$uword} = $words[1];
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
my $seedfile_ct = 0;

my %resx;        # hash of result details by minute
my %res_stampx;  # hash of times to result minute stamps

my $advi = -1;
my @advonline = ();
my @advsit = ();
my @advimpact = ();
my @advcode = ();
my %advx = ();
my $rptkey = "";

my $max_impact = 0;

my $logopfn = "";
my $full_logopfn = "";
my $optime = 0;

# if Linux/Unix capture name of most recent operations log

$pattern = "_ms_(\\d+)\.log\$";
@results = ();
opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
@results = grep {/$pattern/} readdir(DIR);
closedir(DIR);
if ($#results != -1) {
   foreach my $f (@results) {
      next if index($f,"plugin") != -1;
      $f =~ /(\d+)\.log/;
#                   $oneline =~ /Nofile Limit: (\d+)(.?)/;
      my $ioptime = $1;
      if ($ioptime > $optime) {
         $optime = $ioptime;
         $logopfn = $f
      }
   }
}
$full_logopfn = $opt_logpath . $logopfn if $logopfn ne "";

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

if ($opt_sth == 1) {
   open STH, ">$opt_stfn" or die "Unable to open Status History output file $opt_stfn\n";
   print STH "Line,LocalTime,Thrunode,Sitname,Node,Atomize,GlobalTime,Status,\n";
   open NDH, ">$opt_ndfn" or die "Unable to open Node History output file $opt_ndfn\n";
   print NDH "Line,Time,Node,Thrunode,Reason,O4ONLINE,Product,Version,Reserved,Hostinfo,Hostaddr,Affinity,\n";
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
my $ithrunode;

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
my %soapdetx = ();          # hash of soap details
my $soapdet_def;
my %soaprunx = ();          # Soap details capture by thread;
my $soaprun_def;
my $soapkey;
my %soapcapx;               # capture of Fetch first row
my $soapcap_def;

my %loginx;

my %ptix;
my $pti_ref;
my $pti_stime = 0;
my $pti_etime = 0;

my $total_sendq = 0;
my $total_recvq = 0;
my $max_sendq = 0;
my $max_recvq = 0;


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
my @agto_fct = ();                           # count of agent offlines
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

my %evhist;
my $evhist_ref;
sub sec2slot;

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
#print STDERR "workong on $l\n";

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
   if ($start_date eq "") {
      if (substr($oneline,0,1) eq "+") {
         if (index($oneline,"Start Date:") != -1) {
            $oneline =~ /Start Date: (\d{4}\/\d{2}\/\d{2})/;
            $start_date = $1 if defined $1;
         }
      }
   }
   if ($start_time eq "") {
      if (substr($oneline,0,1) eq "+") {
         if (index($oneline,"Start Time:") != -1) {
            $oneline =~ /Start Time: (\d{2}:\d{2}:\d{2})/;
            $start_time = $1 if defined $1;
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
   #(5919A82C.000C-22:kdebp0r.c,657,"receive_vectors") ip.pipe connection parameters ...
   #+5919A82C.000C     pipe address: 0.0.0.1:1918
   #+5919A82C.000C         ccbFixup: 10.56.93.54:1918
   #+5919A82C.000C      ccbPhysSelf: 10.56.93.54:1918
   #+5919A82C.000C      ccbPhysPeer: 10.80.90.43:7881
   #+5919A82C.000C      ccbVirtSelf: 10.56.93.54:1918
   #+5919A82C.000C      ccbVirtPeer: 10.80.90.43:7881
   #+5919A82C.000C      socket info: ASD=11A0245D0, recvbuf=33120, sendbuf=33120
   #+5919A82C.000C     ccbEphemeral: 0x00000010
   if (substr($oneline,0,1) eq "+")  {        # convert hex string - ascii - to printable
      $contkey = substr($oneline,1,13);
      $rvrun_def = $rvrunx{$contkey};
      $rxrun_def = $rxrunx{$contkey};
      $dnrun_def = $dnrunx{$contkey};
      $soapcap_def = $soapcapx{$contkey};
      if (defined $rvrun_def) {
         $rest = substr($oneline,14);
         $rest =~ /^(.*?):(.*?)$/;
         my $first = $1;
         my $second = $2;
         $first =~ s/^\s+|\s+$//g;
         $second =~ s/^\s+|\s+$//g;
         if ($first eq "pipe address") {
            $rvrun_def->{pipe_addr} = $second;
         } elsif ($first eq "ccbFixup") {
            $rvrun_def->{fixup} = $second;
         } elsif ($first eq "ccbPhysSelf") {
            $rvrun_def->{phys_self} = $second;
         } elsif ($first eq "ccbPhysPeer") {
            $rvrun_def->{phys_peer} = $second;
         } elsif ($first eq "ccbVirtPeer") {
            $rvrun_def->{virt_peer} = $second;
         } elsif ($first eq "ccbVirtSelf") {
            $rvrun_def->{virt_self} = $second;
         } elsif ($first eq "ccbEphemeral") {
            $rvrun_def->{ephemeral} = hex($second);
            $rvrun_def->{pipe_addr} =~ /(.*?):/;
            my $ephem = $1;
            my $recvect_def = $recvectx{$ephem};
            if (!defined $recvect_def) {
               my %recvectdef = (
                                   pipe_addr => $rvrun_def->{pipe_addr},
                                   fixup => $rvrun_def->{fixup},
                                   phys_self => $rvrun_def->{phys_self},
                                   phys_peer => $rvrun_def->{phys_peer},
                                   virt_self => $rvrun_def->{virt_self},
                                   virt_peer => $rvrun_def->{virt_peer},
                                   ephemeral => $rvrun_def->{ephemeral},
                                   thrunode => $opt_nodeid,
                                   service_point => "",
                                   service_type => "",
                                   driver => "",
                                   build_date => "",
                                   build_target => "",
                                   process_time => 0,
                                );
               $recvectx{$ephem} = \%recvectdef;
               $recvect_def = \%recvectdef;
            }
            $recvect_def->{count} += 1;
            $rvrun_last_line = $l;
            $rvrun_last_thread = $rvrun_def->{thread};
            $rvrun_last_def = $recvect_def;
            delete  $rvrunx{$contkey};
         }

      #+5970DEB6.0002  Insert request for node name <boi_boipva23:KUL                >
      #+5970DEB6.0002 and thrunode <REMOTE_t01rt07px                > with product code <VA>
      #+5970DEB6.0002 matches an existing node with with thrunode <REMOTE_t02rt08px                >
      #+5970DEB6.0002 and product code <UL>.   Please verify that
      #+5970DEB6.0002 that the node name in question is not a duplicate
      #+5970DEB6.0002 of a agent attached at another TEMS or is being
      #+5970DEB6.0002 truncated because it is larger than 32 characters.
      } elsif (defined $dnrun_def) {
         $rest = substr($oneline,14);
         if (substr($rest,1,7) eq " Insert") {
            $rest =~ /\<(.*)\>/;
            my $inode = $1;
            $inode =~ s/\s+$//;   #trim trailing whitespace
            $dnrun_def->{node} = $inode;

         } elsif (substr($rest,1,12) eq "and thrunode") {
            $rest =~ /\<(.*)\> with product code \<(.*)\>/;
            my $ithrunode = $1;
            my $iproduct = $2;
            $ithrunode =~ s/\s+$//;   #trim trailing whitespace
            $iproduct =~ s/\s+$//;   #trim trailing whitespace
            $dnrun_def->{thrunode} = $ithrunode;
            $dnrun_def->{product} = $iproduct;
         } elsif (substr($rest,1,7) eq "matches") {
            $rest =~ /\<(.*)\>/;
            my $ithrunode = $1;
            $ithrunode =~ s/\s+$//;   #trim trailing whitespace
            $dnrun_def->{thrunode_new} = $ithrunode;
         } elsif (substr($rest,1,11) eq "and product") {
            $rest =~ /\<(.*)\>/;
            my $iproduct = $1;
            $iproduct =~ s/\s+$//;   #trim trailing whitespace
            $dnrun_def->{product_new} = $iproduct;
            my $dnodekey = $dnrun_def->{node} . "|" . $dnrun_def->{thrunode} . "|" . $dnrun_def->{product} .
                                                "|" . $dnrun_def->{thrunode_new} . "|" . $dnrun_def->{product_new};
            my $dnode_ref = $dnodex{$dnodekey};
            if (!defined $dnode_ref) {
               my %dnoderef = (
                                 node => $dnrun_def->{node},
                                 thrunode => $dnrun_def->{thrunode},
                                 product => $dnrun_def->{product},
                                 thrunode_new => $dnrun_def->{thrunode_new},
                                 product_new => $dnrun_def->{product_new},
                                 count => 0,
                              );
               $dnodex{$dnodekey} = \%dnoderef;
               $dnode_ref = \%dnoderef;
            }
            $dnode_ref->{count} += 1;
            delete  $dnrunx{$contkey};
         }
      #+59422557.005A    Service Point: ibm05492.th01ham020tthxs_tacmd
      #+59422557.005A      System Type: AIX;7.1
      #+59422557.005A           Driver: tms_ctbs630fp7:d6305a
      #+59422557.005A       Build Date: Oct 31 2016 16:26:19
      #+59422557.005A     Build Target: aix53
      #+59422557.005A     Process Time: 0x59422556
      } elsif (defined $rxrun_def) {       # in this case an extention of %recvectx hash
         $rest = substr($oneline,14);
         $rest =~ /^(.*?):(.*?)$/;
         my $first = $1;
         my $second = $2;
         $first =~ s/^\s+|\s+$//g;
         $second =~ s/^\s+|\s+$//g;
         if ($first eq "Service Point") {
            $rxrun_def->{service_point} = $second;
         } elsif ($first eq "System Type") {
            $rxrun_def->{service_type} = $second;
         } elsif ($first eq "Driver") {
            $rxrun_def->{driver} = $second;
         } elsif ($first eq "Build Date") {
            $rxrun_def->{build_date} = $second;
         } elsif ($first eq "Build Target") {
            $rxrun_def->{build_target} = $second;
         } elsif ($first eq "Process Time") {
            $rxrun_def->{process_time} = $second;
            $rvrun_last_line = 0;
         }
      # +5A21EF8B.025B "<TABLE name="O4SRV.UTCTIME">
      # +5A21EF8B.025B <OBJECT>Universal_Time</OBJECT>
      } elsif (defined $soapcap_def) {
         $soaprun_def = $soapcap_def;
         $rest = substr($oneline,14);
         $rest =~ / [\"]?(.*)$/;
         my $ifrag = $1;
         $ifrag =~ s/\s+$//;   #trim trailing whitespace
         $soaprun_def->{fetch} .= $ifrag;
         if (($ifrag eq "") or ($ifrag eq "</ROW>")) {
            delete $soapcapx{$contkey};
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
   if ($local_diff == -1) {
      if ($start_time ne "") {
         if ($start_date ne "") {
            my $iyear = substr($start_date,0,4) - 1900;
            my $imonth = substr($start_date,5,2) - 1;
            my $iday = substr($start_date,8,2);
            my $ihour = substr($start_time,0,2);
            my $imin = substr($start_time,3,2);
            my $isec = substr($start_time,6,2);
            my $ltime = timelocal($isec,$imin,$ihour,$iday,$imonth,$iyear);
            $local_diff = $ltime - $logtime;
         }
      }
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

   #(5914DB2A.0065-6:kbbssge.c,72,"BSS1_GetEnv") KDEB_HOSTNAME=KDCB0_HOSTNAME="it06qam020xjbxm"
   if ($opt_kdcb0 eq "") {
      if (substr($logunit,0,9) eq "kbbssge.c") {
         if ($logentry eq "BSS1_GetEnv") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # KDEB_HOSTNAME=KDCB0_HOSTNAME="it06qam020xjbxm"
            if (substr($rest,1,29) eq "KDEB_HOSTNAME=KDCB0_HOSTNAME=") {
               $rest =~ /KDCB0_HOSTNAME=\"(\S+)\"/;
               $opt_kdcb0 = $1;
            }
         }
      }
   }

   #(5914DB2A.0064-6:kbbssge.c,72,"BSS1_GetEnv") KDEB_INTERFACELIST="158.98.138.32"
   if ($opt_kdebi eq "") {
      if (substr($logunit,0,9) eq "kbbssge.c") {
         if ($logentry eq "BSS1_GetEnv") {
            $oneline =~ /^\((\S+)\)(.+)$/;
            $rest = $2;                       # KDEB_INTERFACELIST="158.98.138.32"
            if (substr($rest,1,19) eq "KDEB_INTERFACELIST=") {
               $rest =~ /KDEB_INTERFACELIST=\"(\S+)\"/;
               $opt_kdebi = $1;
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
   ## (5995939B.000E-B:kqmmhm.cpp,1348,"mhm::promoteToHub") parent cms <HUB_frmpqam00srb2xm> is now the HUB
   ## (5995939B.000F-B:kqmmhm.cpp,1350,"mhm::promoteToHub") local cms <STANDBY_frmpqam00srb4xm> is now the MIRROR
   if (substr($logunit,0,10) eq "kqmmhm.cpp") {
      if ($logentry eq "mhm::promoteToHub") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if ((substr($rest,1,10) eq "parent cms") or (substr($rest,1,9) eq "local cms")){
            my $mkey = $logtimehex . "|" . $l;
            $mhmx{$mkey} = $rest;
            next;
         }
      }
   }

   ## (59959385.0003-B:kqmarm.cpp,765,"arm::doStageII") Begin FTO Stage-Two processing: FTO mode <Mirror> acting hub <HUB_frmpqam00srb2xm> full sync <Yes> migrate <No>
   ## (5995939B.000C-B:kqmarm.cpp,1141,"arm::doStageII") FTO Stage-Two processing completed at <08/17/17 15:01:15>, rc = 0
   if (substr($logunit,0,10) eq "kqmarm.cpp") {
      if ($logentry eq "arm::doStageII") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if ((substr($rest,1,19) eq "Begin FTO Stage-Two") or (substr($rest,1,34) eq "FTO Stage-Two processing completed")){
            my $mkey = $logtimehex . "|" . $l;
            $mhmx{$mkey} = $rest;
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
   # (5970A187.0001-13:kdebeal.c,81,"ssl_provider_open") GSKit error 407: GSK_ERROR_BAD_KEYFILE_LABEL - errno 11
   if (substr($logunit,0,9) eq "kdebeal.c") {
      if ($logentry eq "ssl_provider_open") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # GSKit error 402: GSK_ERROR_NO_CIPHERS - errno 11   insert
         if (substr($rest,1,11) eq "GSKit error") {
            $rest =~ /GSKit error (\d+): (\S+)/;
            my $errnum = $1;
            my $errtext = $2;
            my $gerror_ref = $gskiterrorx{$errnum};
            if (!defined $gerror_ref) {
               my %gerrorref = (
                                  count => 0,
                                  text => $errtext,
                               );
               $gerror_ref = \%gerrorref;
               $gskiterrorx{$errnum} = \%gerrorref;
            }
            $gerror_ref->{count} += 1;
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
            $ithrunode = $2;
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
         my @scantype;
         if (substr($rest,1,26) eq "Unsupported request method") {
            $portscan++;
            $portscan_Unsupported++;
            push (@{$portscan_timex{$logtimehex}},"unsupported");
         } elsif (substr($rest,1,21) eq "error in HTTP request") {
            $portscan++ if index($rest,"unknown method in request") != -1;
            $portscan_HTTP++;
            push (@{$portscan_timex{$logtimehex}},"http");
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
            push (@{$portscan_timex{$logtimehex}},"integrity");
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
            push (@{$portscan_timex{$logtimehex}},"suspend");
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
            push (@{$portscan_timex{$logtimehex}},"error72");
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

   #(5919A82C.000C-22:kdebp0r.c,657,"receive_vectors") ip.pipe connection parameters ...
   #+5919A82C.000C     pipe address: 0.0.0.1:1918
   #+5919A82C.000C         ccbFixup: 10.56.93.54:1918
   #+5919A82C.000C      ccbPhysSelf: 10.56.93.54:1918
   #+5919A82C.000C      ccbPhysPeer: 10.80.90.43:7881
   #+5919A82C.000C      ccbVirtSelf: 10.56.93.54:1918
   #+5919A82C.000C      ccbVirtPeer: 10.80.90.43:7881
   #+5919A82C.000C      socket info: ASD=11A0245D0, recvbuf=33120, sendbuf=33120
   #+5919A82C.000C     ccbEphemeral: 0x00000010
   if (substr($logunit,0,9) eq "kdebp0r.c") {
      if ($logentry eq "receive_vectors") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # ip.pipe connection parameters ...
         if (index($rest,"connection parameters") != -1) {
            $contkey = substr($oneline,1,13);
            $rvrun_def = $rvrunx{$contkey};
            if (!defined $rvrun_def) {
                my %rvrundef = (
                                  thread => $logthread,
                                  count => 0,
                                  state => 0,
                                  pipe_addr => "",
                                  fixup => "",
                                  phys_self => "",
                                  phys_peer => "",
                                  virt_self => "",
                                  virt_peer => "",
                                  ephemeral => 0,
                               );
                $rvrun_def = \%rvrundef;
                $rvrunx{$contkey} = \%rvrundef;
            }
         }
      }
   }

   # When available the peer information gives good information on what
   # is communicating with us. It depends on the prior receive vector data
   # and adds on to it. In the examples seen so far, the diagnostic
   # lines immediately follow the receive vector lines and that is used
   # as an adhoc way of identifying.

   #(59422557.005A-3D5:kdeprxi.c,150,"KDEP_ReceiveXID") ip.spipe peer information
   #+59422557.005A    Service Point: ibm05492.th01ham020tthxs_tacmd
   #+59422557.005A      System Type: AIX;7.1
   #+59422557.005A           Driver: tms_ctbs630fp7:d6305a
   #+59422557.005A       Build Date: Oct 31 2016 16:26:19
   #+59422557.005A     Build Target: aix53
   #+59422557.005A     Process Time: 0x59422556
   if (substr($logunit,0,9) eq "kdeprxi.c") {
      if ($logentry eq "KDEP_ReceiveXID") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # ip.spipe peer information
         if (($l - $rvrun_last_line) == 1) {
            if ($logthread eq $rvrun_last_thread) {
               if (index($rest,"peer information") != -1) {
                  $contkey = substr($oneline,1,13);
                  $rxrunx{$contkey} = $rvrun_last_def;
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
   # (59622462.0002-1C0C:kdseed.c,1275,"RunSeeder") Seed file <kyn_upg.sql>, Line <12360> not seeded: record not found.
   if (substr($logunit,0,8) eq "kdseed.c") {
      if ($logentry eq "RunSeeder") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Seed file <kyn_upg.sql>, Line <12360> not seeded: record not found.
         if (substr($rest,1,9) eq "Seed file") {
            $seedfile_ct += 1;
            next;
         }
      }
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
      # (5A32F81C.0000-1A:kfastins.c,2604,"GetSitLogRecord") ReadNext Error, status = 5
      if ($logentry eq "GetSitLogRecord") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # ReadNext Error, status = 5
         if (substr($rest,1,14) eq "ReadNext Error") {
            $rest =~ /ReadNext Error, (.*)/;
            my $readnext_err = $1;
            $readnextx{$readnext_err} += 1;
            next;
         }
      }
   }
   #(5A32F0B5.0001-31:kfaottev.c,4929,"Get_ClassName") TEC classname cannot be determined for situation <Perf_CPUBusy_65_C>. status <5>
   #(5A32F0B5.0002-31:kfaottev.c,1105,"KFAOT_Translate_Event") Translate TEC event failed. status <1>. Situation <Perf_CPUBusy_65_C> event status <S> not sent
   if (substr($logunit,0,10) eq "kfaottev.c") {
      if ($logentry eq "Get_ClassName") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  TEC classname cannot be determined for situation <Perf_CPUBusy_65_C>. status <5>
         if (substr($rest,1,34) eq "TEC classname cannot be determined") {
            $tec_classname_ct += 1 if index($rest,"status <5>") != -1;
            next;
         }
      }
      if ($logentry eq "KFAOT_Translate_Event") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Translate TEC event failed. status <1>. Situation <Perf_CPUBusy_65_C> event status <S> not sent
         if (substr($rest,1,26) eq "Translate TEC event failed") {
            $tec_translate_ct += 1 if index($rest,"status <S>") != -1;
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
         next if substr($rest,-6,6) ne "-LINE.";
         $rest =~ /.*\<(\S+)\>/;
         $iagent = $1;
         my $ax = $agtox{$iagent};
         if (!defined $ax) {
            $agtoi += 1;
            $ax = $agtoi;
            $agto[$ax] = $iagent;
            $agtox{$iagent} = $ax;
            $agto_ct[$ax] = 0;
            $agto_fct[$ax] = 0;
         }
         $agto_ct[$ax] += 1 if substr($rest,-8,8) eq "ON-LINE.";
         $agto_fct[$ax] += 1 if substr($rest,-9,9) eq "OFF-LINE.";
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

   # (5927EF95.0000-7:ko4stg3u.cpp,569,"IBInterface::handleNodelistRecord") Error: <1136> failed to download node list record
   # (5927EF95.0001-7:ko4eibr.cpp,142,"EibRecord::dump") operation <I> id <5529> obj name <CTXAPP0054VB:51>
   # (5927EF95.0002-7:ko4eibr.cpp,143,"EibRecord::dump") send id <> origin <>
   # (5927EF95.0003-7:ko4eibr.cpp,144,"EibRecord::dump") timestamp <1170526040407000> user <_FAGEN>
   # (5927EF95.0004-7:ko4eibr.cpp,145,"EibRecord::dump") raw obj <CTXAPP0054VB:51                 REMOTE_USDAD-METVPVL01>
   if (substr($logunit,0,12) eq "ko4stg3u.cpp") {
      if ($logentry eq "IBInterface::handleNodelistRecord") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Error: <1136> failed to download node list record
         next if substr($rest,1,6) ne "Error:";
         $nodelist_error = $rest;
         $nodeliste_state = 0;
      }
   }
   if (substr($logunit,0,11) eq "ko4eibr.cpp") {
      if ($logentry eq "EibRecord::dump") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         $nodeliste_state += 1;
         if ($nodeliste_state == 1) {        # operation <I> id <5529> obj name <CTXAPP0054VB:51>
            $rest =~ /operation <(\S*)> id <(\d*)> obj name <(\S*)>/;
            $nodelist_operation = $1;
            $nodelist_id = $2;
            $nodelist_objname = $3;
         } elsif ($nodeliste_state == 2) {   # send id <> origin <>
         } elsif ($nodeliste_state == 3) {   # timestamp <1170526040407000> user <_FAGEN>
         } elsif ($nodeliste_state == 4) {   # raw obj <CTXAPP0054VB:51                 REMOTE_USDAD-METVPVL01>
            $rest =~ /raw obj <(.*)>/;
            $nodelist_agent = substr($1,0,32);
            $nodelist_tems = substr($1,32);
            $nodelist_agent =~ s/\s+$//;   #trim trailing whitespace
            my $nodeliste_ref = $nodelistex{$nodelist_agent};
            if (!defined $nodeliste_ref) {
               my %nodelisteref = (
                                     count => 0,
                                     error => {},
                                     op => {},
                                     id => {},
                                     tems => {},
                                  );
              $nodeliste_ref = \%nodelisteref;
              $nodelistex{$nodelist_agent} = \%nodelisteref;
            }
            $nodeliste_ref->{count} += 1;
            $nodeliste_ref->{error}{$nodelist_error} += 1;
            $nodeliste_ref->{op}{$nodelist_operation} += 1;
            $nodeliste_ref->{id}{$nodelist_id} += 1;
            $nodeliste_ref->{tems}{$nodelist_tems} += 1;
            $nodeliste_state = 0;
            $nodeliste_count += 1;
         }
      }
   }



   next if $skipzero;

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

   #(57A0B2C2.000D-48:kfastinh.c,1187,"KFA_InsertNodests") Sending Node Status : node <vsmp8288:VA                     > nodetype <V> thrunode <remote_apsp0562                 > expiryint <-1> expirytime <9               > online <  > o4online <Y> product <VA> version <06.20.01> affinities <00000000G000000000000000000000000400004w0a7 > hostinfo <AIX~6.1         > hostloc <                > hostaddr <ip.pipe:#10.125.108.65[57760]<NM>vsmp8288</NM>                                                                                                                                                                                                                  > reserved <A=02:aix523;C=06.20.01.00:aix523;G=06.20.01.00:aix523;          > hrtbeattime <1160802094349000>
   if (substr($logunit,0,10) eq "kfastinh.c") {
      if ($logentry eq "KFA_InsertNodests") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Sending Node Status : node <vsmp8288:VA                     > nodetype <V> thrunode <remote_apsp0562                 > expiryint <-1> expirytime <9               > online <  > o4online <Y> product <VA> version <06.20.01> affinities <00000000G000000000000000000000000400004w0a7 > hostinfo <AIX~6.1         > hostloc <                > hostaddr <ip.pipe:#10.125.108.65[57760]<NM>vsmp8288</NM>                                                                                                                                                                                                                  > reserved <A=02:aix523;C=06.20.01.00:aix523;G=06.20.01.00:aix523;          > hrtbeattime <1160802094349000>
         if (substr($rest,1,19) eq "Sending Node Status") {
            $rest =~ /node <(.*?)> nodetype <(.*?)> thrunode <(.*?)> expiryint <(.*?)> expirytime <(.*?)> online <(.*?)> o4online <(.*?)> product <(.*?)> version <(.*?)> affinities <(.*?)> hostinfo <(.*?)> hostloc <(.*?)> hostaddr <(.*?)> reserved <(.*?)> hrtbeattime <(.*?)>/;
            my $inode = $1;
            my $inodetype = $2;
            $ithrunode = $3;
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
                                 aff => {},
                                 affct => 0,
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

            my $inodeakey = $iaffinities . "|" . $iproduct;
            my $inodea_ref = $inode_ref->{aff}{$inodeakey};
            if (!defined $inodea_ref) {
               my %inodearef = (
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
                $inodea_ref = \%inodearef;
                $inode_ref->{aff}{$inodeakey} = \%inodearef;
                $inode_ref->{affct} += 1;
            }
            $inodea_ref->{count} += 1;

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

   # (5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
   if (substr($logunit,0,10) eq "kfaprpst.c") {
      if ($logentry eq "HandleSimpleHeartbeat") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >Remote node <Primary:VA10PWPAPP032:NT> is ON-LINE.
         if (substr($rest,1,26) eq "Simple heartbeat from node") {
            $rest =~ /node \<(.*?)\> thrunode, \<(.*?)\>/;
            $iagent = $1;
            $ithrunode = $2;
            $iagent =~ s/\s+$//;                    # strip trailing blanks
            $ithrunode =~ s/\s+$//;                    # strip trailing blanks
## capture node status if available !1
            $ithrunode = substr($ithrunode,0,index($ithrunode," ")) if index($ithrunode," ") != -1;
            if ($opt_jitter == 1) {                 # skip collection unless jitter requested
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
            # Richard Bennett logic from FindDupAgents.rex
            $inode = $iagent;
            $rbdup_ref = $rbdupx{$inode};
            if (!defined $rbdup_ref) {
               my %rbdupref = (
                                 thruname => "",
                                 curstatus => "N",
                                 interval => 0,
                                 inttmp => 0,
                                 lasttime => 0,
                                 thruchg => 0,
                                 simpleneg => 0,
                                 dupflag => 0,
                                 Ycnt => 0,
                                 offline => 0,
                                 online => 0,
                                 newonline1 => 0,
                                 duplicate_reasons => {},
                                 leftover_seconds => [],
                                 heartbeat_outside_grace => [],
                                 double_heartbeat => [],
                                 double_offline => [],
                                 early_heartbeat => [],
                                 thrunodes => {},
                                 hostaddrs => {},
                                 hostaddr => 0,
                                 systems => {},
                                 system => 0,
                                 instances => {},
                                 physicals => {},
                              );
               $rbdup_ref = \%rbdupref;
               $rbdupx{$inode} = \%rbdupref;
            }


            # if we have not yet determined an interval for this endpoint, then we
            # never really saw a normal first online heartbeat. This occurs when
            # these is log overwrite.
            if ($rbdup_ref->{interval} == 0) {

               # If we have encountered three or more of these simple heartbeats, then we can see if                 ##2
               # the intervals between pairs match. if they do, we want to save the interval
               # and reset things so processing continues in the future for this endpoint with
               # known interval value.
               if ($rbdup_ref->{inttmp} > 0) {
                  $tempInt = $logtime - $rbdup_ref->{lasttime};   # number of seconds between heartbeats
                  my $minutes = 0;
                  my $leftover;

                  # if the interval between the last two heartbeats is about equal to the
                  # previous heartbeat interval, then we will use that as the interval if
                  # the interval is one minute.
                  if (($tempInt >= $rbdup_ref->{inttmp} - $grace) and ($tempInt <= $rbdup_ref->{inttmp} + $grace)) {
                     $leftover = $tempInt%60;                                                                   ##4
                     $leftover = 0 if $leftover >= (60-$grace);
                     $minutes = int(($tempInt+$grace)/60) if $leftover <= $grace;                                                              ##5
                     if ($minutes == 0) {
                        # Too many seconds left over, so this is a likely duplicate. Increment that
                        # count. Then add the interval to the previous interval.
                        $rbdup_ref->{dupflag} += 1;
                        $rbdup_ref->{duplicate_reasons}{"leftover_seconds"} += 1;
                        push @{$rbdup_ref->{leftover_seconds}},$leftover,$logtimehex;

                        $rbdup_ref->{inttmp} += $tempInt;
                        # If the total interval is now on a minute boundary, then
                        # that is likely the interval we are looking for.
                        $leftover = $rbdup_ref->{lasttime}%60;
                        $leftover = 0 if $leftover == 59;
                        $minutes = int(($rbdup_ref->{inttmp}+2)/60) if $leftover <= 1;                                 ##5
                     }
                  } else {                                                                                            ##4
                     # The two heartbeat are not close in interval, so this is a likely                               ##5
                     # duplicate. Increment that count. Then add the interval to the
                     # previous interval.
                     $rbdup_ref->{dupflag} += 1;
                     $rbdup_ref->{duplicate_reasons}{"heartbeat_outside_grace"} += 1;
                     push @{$rbdup_ref->{heartbeat_outside_grace}},$tempInt,$logtimehex;
                     $rbdup_ref->{inttmp} += $tempInt;

                     # If the total interval is now on a minute boundary, then
                     # that is likely the interval we are looking for.
                     $leftover = $rbdup_ref->{inttmp}%60;
                     $leftover = 0 if $leftover == 59;
                     $minutes = int(($rbdup_ref->{inttmp}+2)/60) if $leftover <= 1;                                 ##5
                  }

                  # if we have something in minutes, then that is our interval */
                  $rbdup_ref->{interval} = $minutes*60 if $minutes != 0;
                  $rbdup_ref->{inttmp} = 0 if $minutes != 0;

               # Otherwise if this is the second simple heartbeat for this endpoint, then determine
               # a temporary interval to check next time we get a simple heartbeat from this endpoint.
               # If there is no difference in time between the two heartbeats, then this is a
               # likely duplicate.

               } elsif ($rbdup_ref->{lasttime} > 0) {
                  $tempInt = $logtime - $rbdup_ref->{lasttime}; # number of seconds between heartbeats            ##6
                  if ($tempInt == 0) {
                     $rbdup_ref->{dupflag} += 1;                                                                  ##7
                     $rbdup_ref->{duplicate_reasons}{"double_heartbeat"} += 1;
                     push @{$rbdup_ref->{double_heartbeat}},$logtimehex;
                  } else {
                     $rbdup_ref->{inttmp} = $tempInt;
                  }

               # Otherwise this is the first time we have seen this endpoint so save so info for next time
               } else {                                                                                          ##6
                  $rbdup_ref->{thruname} = $ithrunode;                                                           ##7
                  $rbdup_ref->{curstatus} = "Y";                                                                 ##7
               }

            # Is the interval a positive number? If not then something is wrong. We should not be getting
            # simple heartbeats when the interval is negative. */
            } elsif ($rbdup_ref->{interval} < 0) {
               $rbdup_ref->{simpleneg} += 1;
               # we have a simple heartbeat and we know what interval they should be at. If the interval is
               # less than the expected interval then we may have a duplicate instance of the endpoint.
               # Larger values are okay since there can be delays.
            } else {  #                                                                                         ##5
               # allow grace period to be early or late */
               my $time_diff = $logtime - $rbdup_ref->{lasttime};                                                           ##5
               if (($time_diff < ($rbdup_ref->{interval} - $grace)) or ($time_diff > ($rbdup_ref->{interval} + $grace))) {
                  $rbdup_ref->{dupflag} += 1;                                                                               ##6
                  $rbdup_ref->{duplicate_reasons}{"heartbeat_outside_grace"} += 1;
                  push @{$rbdup_ref->{heartbeat_outside_grace}},$time_diff,$logtimehex;
               }
            }

            # always save the timestamp of the simple heartbeat */                                           #4
            $rbdup_ref->{lasttime} = $logtime;
            $rbdup_ref->{thruname} = $ithrunode if $rbdup_ref->{thruname} eq "";
            # And check to see if the thrunode has changed. It should never change with a simple heartbeat */
            if ($ithrunode ne $rbdup_ref->{thruname}) {
               $rbdup_ref->{thruchg} += 1;                     #ntest
               $rbdup_ref->{thruname} = $ithrunode;
               $rbdup_ref->{thrunodes}{$ithrunode} += 1;
            }
            next;
         }
      }

      # (58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'
      # (58A73630.0253-DB:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'gto_it06qam020xjbxm:07          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'N', expiryInterval: '-1', online: '  ', hostAddr: 'ip.spipe:#158.98.138.32[7757]<NM>gto_it06qam020xjbxm</NM>   '
      if ($logentry eq "UpdateNodeStatus") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'
         if (substr($rest,1,5) eq "Node:") {
            # Richard Bennett logic from FindDupAgents.rex
            # Get the needed information. Simple heartbeats are always online = "Y"
            #    parse var remainder . "Node: '"endpoint . "', thrunode: '" thrunode . "', flags: '" flags . "', curOnline: '" curonline . "', newOnline: '" newOnline . "', expiryInterval: '" expireInt . "'" .


#           $rest =~ /Node: \'([^']*)\', thrunode: \'([^']*)\', flags: \'([^']*)\', curOnline: \'([^']*)\', newOnline: \'([^']*)\', expiryInterval: \'([^']*)\'[,]* online: \'([^']*)\'[,]* (.*)$/;
            $rest =~ /Node: \'([^']*)\', thrunode: \'([^']*)\', flags: \'([^']*)\', curOnline: \'([^']*)\', newOnline: \'([^']*)\', expiryInterval: \'([^']*)\'[,]*(.*)$/;
            $inode = $1;
            $ithrunode = $2;
            my $iflags = $3;
            my $icurOnline = $4;
            my $inewOnline = $5;
            my $iexpireInt = $6;
            $rest= $7;            # online and hostAddr was added at recent maintenance levels, so capture it only if available
            $inode =~ s/\s+$//;   #trim trailing whitespace
            $ithrunode =~ s/\s+$//;   #trim trailing whitespace
            my $ionline = "";
            if (index($rest,"online") != -1) {
               $rest =~ /online: \'([^']*)\'[,]* (.*)$/;
               $ionline = $1;
               $rest = $2;
            }
            my $ihostAddr = "";
            my $isystem = "";
            my $iport = "";
            if (index($rest,"hostAddr") != -1) {
               if (index($rest,"[") != -1) {
                  $rest =~ /hostAddr: \'.*?#(.*?)\[.*?\'/;
                  $isystem = $1 if defined $1;
                  $rest =~ /hostAddr: \'.*?#(.*?\[\d+\]).*?\'/;
                  $ihostAddr = $1 if defined $1;
                  $rest =~ /hostAddr:.*?\[(\d+)\]/;
                  $iport = $1 if defined $1;
               }
            }
            $ihostAddr =~ s/\s+$//;   #trim trailing whitespace
            $rbdup_ref = $rbdupx{$inode};
            if (!defined $rbdup_ref) {
               my %rbdupref = (
                                 thruname => "",
                                 curstatus => "N",
                                 interval => 0,
                                 inttmp => 0,
                                 lasttime => 0,
                                 thruchg => 0,
                                 simpleneg => 0,
                                 dupflag => 0,
                                 Ycnt => 0,
                                 offline => 0,
                                 online => 0,
                                 newonline1 => 0,
                                 duplicate_reasons => {},
                                 leftover_seconds => [],
                                 heartbeat_outside_grace => [],
                                 double_heartbeat => [],
                                 double_offline => [],
                                 early_heartbeat => [],
                                 thrunodes => {},
                                 hostaddrs => {},
                                 hostaddr => 0,
                                 systems => {},
                                 system => 0,
                                 instances => {},
                                 physicals => {},
                              );
               $rbdup_ref = \%rbdupref;
               $rbdupx{$inode} = \%rbdupref;
            }
            $rbdup_ref->{hostaddrs}{$ihostAddr} = 1 if $ihostAddr ne "";
            if ($isystem ne "") {
               my $system_ref=$rbdup_ref->{systems}{$isystem};
               if (!defined $system_ref) {
                  my %systemref = (
                                     ports => {},
                                  );
                  $system_ref = \%systemref;
                  $rbdup_ref->{systems}{$isystem} = \%systemref;
               }
               $system_ref->{ports}{$iport} = 1 if $iport ne "";
            }
            $rbdup_ref->{newonline1} += 1 if $inewOnline eq "1";
            # We should not be getting an offline status for a node that is already offline

            if (($rbdup_ref->{curstatus} eq "N") and ($inewOnline eq "N")) {
               $rbdup_ref->{dupflag} += 1;
               $rbdup_ref->{duplicate_reasons}{"double_offline"} += 1;
               push @{$rbdup_ref->{double_offline}},$logtimehex;
            # if the endpoint is going offline then reset some things

            } elsif ($inewOnline eq "N") {
               $rbdup_ref->{thruname} = "";
               $rbdup_ref->{interval} = 0;
               $rbdup_ref->{lasttime} = 0;
               $rbdup_ref->{curstatus} = "N";
               $rbdup_ref->{offline} += 1;

            # if the endpoint is currently offline then it must be coming online...  time to
            # save some values.

            } elsif ($rbdup_ref->{curstatus} eq "N"){
               $rbdup_ref->{thruname} = $ithrunode;
               $rbdup_ref->{thrunodes}{$ithrunode} += 1;
               my $pexp = sprintf("0x%X", $iexpireInt);
               if (length($pexp) > 10) {
                  $iexpireInt = hex(substr($pexp,-8));
               }

               if (($iexpireInt > 100) or ($iexpireInt < 1)) {
                  $rbdup_ref->{interval} = 600;
               } else {
                  $rbdup_ref->{interval} = $iexpireInt*60;
               }
               $rbdup_ref->{lasttime} = $logtime;
               $rbdup_ref->{curstatus} = "Y";
               $rbdup_ref->{online} += 1;

            # Endpoint is online and we are getting an online heartbeat...  check the interval */

            # Is the interval a positive number? This is okay in most cases - usually just the RTEMS
            # resending node statuses. But if the thrunode changes then there is a chance we have
           # a duplicate endpoint. Thrunode changes are usually normal unless there are a lot
            # of them.

            } elsif ($rbdup_ref->{interval} < 0) {
               if ($ithrunode ne $rbdup_ref->{thruname}) {
                  $rbdup_ref->{thruchg} += 1;
                  $rbdup_ref->{thruname} = $ithrunode;
                  $rbdup_ref->{thrunodes}{$ithrunode} += 1;
               } elsif ($ithrunode ne $opt_nodeid) {
                  $rbdup_ref->{Ycnt} += 1;
               }
               $rbdup_ref->{lasttime} = $logtime;

            # we have a heartbeat and we know what interval they should be at. If the thrunode changes
            # then there is a chance we have a duplicate endpoint. Thrunode changes are usually normal unless
            # there are a lot of them. We ignore the interval in this case since it is normal for a thrunode
            # change to send in a heartbeat before the interval expires.

            # if there is no thrunode change and the interval is
            # less than the expected interval then we may have a duplicate instance of the endpoint.
            # Larger values are okay since there can be delays.

            } else {
               if ($ithrunode ne $rbdup_ref->{thruname}) {
                   $rbdup_ref->{thruchg} += 1;
                   $rbdup_ref->{thruname} = $ithrunode;
                   $rbdup_ref->{thrunodes}{$ithrunode} += 1;
               } elsif (($logtime - $rbdup_ref->{lasttime}) < ($rbdup_ref->{interval} - 5)) { # allow grace period to be early */
                   $rbdup_ref->{dupflag} += 1;
                   $rbdup_ref->{duplicate_reasons}{"early_heartbeat"} += 1;
                   my $ttime = $logtime - $rbdup_ref->{lasttime};
                   push @{$rbdup_ref->{early_heartbeat}},$ttime,$logtimehex;
               }
            }
            $rbdup_ref->{lasttime} = $logtime;         # always record last time
            next;
         }
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
               $ithrunode = $1;
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
            my $begins = substr($rest,0,10);
            $rest = substr($rest,$pi+20);
            $pi = index($rest,"while processing event record");
            if ($pi != -1) {
               $rest = substr($rest,$pi+30);
#               $rest =~ /.*(\<.*)/;
#               $rest = $1;
               # <1150213164119001PCXTA42:VA10PWPAPP036:MQ            YMQ07.00.03 9                V00040000000000000000000000000000200000qwaa7 REMOTE_va10p10023                 Windows~6.1-SP1                 ip.spipe:#30.128.132.150[16832]<NM>VA10PWPAPP036</NM>                                                                                                                                                                                                           A=00:WINNT;C=06.21.00.02:WINNT;G=06.21.00.02:WINNT;             >
               # <1150213164502000REMOTE_va10p10023               wlp_rfmonitor_2ntw_rfax         RFMonitor:VA10PWPRFS002A:LO     RightFax_Warning, Line=(9 file of type *.job over 10 Minutes Old Found in Dir \\vapwprfnbes01\OutputPath\QCCMEDC\ on Server VA101150213164502999Y>
               # the following logic is used to avoid issues with data on continued lines.
               if (substr($rest,-1,1) eq ">") {                         # ignore continued lines for the moment
                  if (length($rest) <= 260) {                           # Handle only situation summaries here
                     my $itime1 = substr($rest,1,16);
                     $ithrunode = substr($rest,17,32);
                     $ithrunode =~ s/\s+$//;   #trim trailing whitespace
                     my $isitname = substr($rest,49,32);
                     $isitname =~ s/\s+$//;   #trim trailing whitespace
                     my $inode = substr($rest,81,32);
                     $inode =~ s/\s+$//;   #trim trailing whitespace
                     my $iatom = substr($rest,113,128);
                     $iatom =~ s/\s+$//;   #trim trailing whitespace
                     my $itime2 = substr($rest,241,16);
                     my $istatus = substr($rest,257,1);
                     if ($opt_sth == 1) {
                        my $sthline = $l . ",";
                        $sthline .= $itime1 . ",";
                        $sthline .= $ithrunode . ",";
                        $sthline .= $isitname . ",";
                        $sthline .= $inode . ",";
                        $sthline .= $iatom . ",";
                        $sthline .= $itime2 . ",";
                        $sthline .= $istatus . ",";
                        print STH "$sthline\n";
                     }
                     my $key = sec2slot($logtime);
                     $evhist_ref = $evhist{$key};
                     if (!defined $evhist_ref) {
                        my %evhistref = (
                                           status => {},
                                           situation => {},
                                           ptexit_ct => 0,
                                           ptdur_tot => 0,
                                           ptdur_max => 0,
                                           ptdur_maxsl => 0,
                                           ptdur_maxel => 0,
                                           ptlevel_max => 0,
                                           ptlevel_tot => 0,
                                           count => 0,
                                        );
                        $evhist_ref = \%evhistref;
                        $evhist{$key} = \%evhistref;
                     }
                     $evhist_ref->{count} += 1;
                     $evhist_ref->{status}{$istatus} += 1;
                     $evhist_ref->{situation}{$isitname} += 1;
                     $key = $inode . "|" . $isitname;
                     my $evt_ref = $pevtx{$key};
                     if (!defined $evt_ref) {
                        my %evtref = (
                                        sitname => $isitname,
                                        node => $inode,
                                        count => 0,
                                        status => {},
                                     );
                        $pevtx{$key} = \%evtref;
                        $evt_ref      = \%evtref;
                     }
                     $evt_ref->{count} += 1;
                     $evt_ref->{atoms}->{$iatom} = 1 if $iatom ne "";
                     $evt_ref->{thrunode}->{$ithrunode} = 1;
                     $evt_ref->{status}{$istatus} += 1;
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
                  } elsif (substr($begins,1,5) eq "First") {  # node status updates
                                                              ##? "new work and Additional" need to be understood
                     my $itime1 = substr($rest,1,16);
                     $inode = substr($rest,17,32);
                     $inode =~ s/\s+$//;       #trim trailing whitespace
                     my $ireason = substr(51,2);
                     $ireason =~ s/\s+$//;       #trim trailing whitespace
                     my $io4online = substr($rest,53,1);
                     my $iproduct = substr($rest,54,2);
                     $iproduct =~ s/\s+$//;       #trim trailing whitespace
                     my $iversion = substr($rest,56,8);
                     $iversion =~ s/\s+$//;       #trim trailing whitespace
                     my $iaffinity = substr($rest,83,43);
                     $ithrunode = substr($rest,127,32);
                     $ithrunode =~ s/\s+$//;   #trim trailing whitespace
                     my $ihostinfo = substr($rest,161,16);
                     $ihostinfo =~ s/\s+$//;   #trim trailing whitespace
                     my $ihostaddr = substr($rest,193,256);
                     $ihostaddr =~ s/\s+$//;   #trim trailing whitespace
                     my $ireserved = substr($rest,449,64);
                     $ireserved =~ s/\s+$//;   #trim trailing whitespace
                     if ($opt_sth == 1) {
                        my $ndhline = $l . ",";
                        $ndhline .= $itime1 . ",";
                        $ndhline .= $inode . ",";
                        $ndhline .= $ithrunode . ",";
                        $ndhline .= $ireason . ",";
                        $ndhline .= $io4online . ",";
                        $ndhline .= $iproduct . ",";
                        $ndhline .= $iversion . ",";
                        $ndhline .= $ireserved . ",";
                        $ndhline .= $ihostinfo . ",";
                        $ndhline .= $ihostaddr . ",";
                        $ndhline .= $iaffinity . ",";
                        print NDH "$ndhline\n";
                     }
                     my $nodest_ref = $nodestx{$inode};
                     if (!defined $nodest_ref) {
                        my %nodestref = (
                                           count => 0,
                                           instances => {},
                                           status => {},
                                        );
                        $nodest_ref = \%nodestref;
                        $nodestx{$inode} = \%nodestref;
                     }
                     my $inkey = $ithrunode ."|" . $ihostaddr;
                     my $instance_ref = $nodest_ref->{instances}{$inkey};
                     if (!defined $instance_ref) {
                        my %instanceref = (
                                              count => 0,
                                              thrunode => $ithrunode,
                                              hostaddr => $ihostaddr,
                                              product => $iproduct,
                                              online1 => 0,
                                              online => 0,
                                              offline => 0,
                                              version => $iversion,
                                              affinity => $iaffinity,
                                              hostinfo => $ihostinfo,
                                              reserved => $ireserved,
                                          );
                        $instance_ref = \%instanceref;
                        $nodest_ref->{instances}{$inkey} = \%instanceref;
                        $nodest_ref->{count} += 1;
                     }
                     $instance_ref->{count} += 1;
                     $instance_ref->{online1} += 1 if $io4online eq "1";
                     $instance_ref->{online} += 1 if $io4online eq "Y";
                     $instance_ref->{offline} += 1 if $io4online eq "N";
                     $nodest_ref->{status}{$io4online} += 1;
                  }
               }
            }
         }
      }
      next;
   }

   # (5A21EF8B.014C-22:kshstrt.cpp,88,"default_service") Entry
   # (5A21EF8B.0299-22:kshstrt.cpp,206,"default_service") Exit: 0x0
   if (substr($logunit,0,11) eq "kshstrt.cpp") {
      if ($logentry eq "default_service") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Entry
                                           # Exit: 0x0
         $soaprun_def = $soaprunx{$logthread};
         if (substr($rest,1,5) eq "Entry") {
            if (!defined $soaprun_def) {
                my %soaprundef = (
                                    line => $l,
                                    start => $logtime,
                                    end => 0,
                                    msgi => -1,
                                    msg => [],
                                    fetchlen  => 0,
                                    fetch => "",
                                    ip => "",
                                  );
                $soaprun_def = \%soaprundef;
                $soaprunx{$logthread} = \%soaprundef;
             }
         } elsif (substr($rest,1,5) eq "Exit:") {
            if (defined $soaprun_def) {
               $soaprun_def->{end} = $logtime;
               # merge data into %soapdetx hash by line number
               my %soapdet = (
                                start => $soaprun_def->{start},
                                end => $soaprun_def->{end},
                                msgi => $soaprun_def->{msgi},
                                msg => [],
                                fetchlen => $soaprun_def->{fetchlen},
                                fetch => $soaprun_def->{fetch},
                                ip => $soaprun_def->{ip},
                             );
               my $soapdet_ref = \%soapdet;
               @{$soapdet_ref->{msg}} = @{$soaprun_def->{msg}};
               $soapdetx{$soaprun_def->{line}} = \%soapdet;
               delete $soaprunx{$logthread};
            }
         }
      }
   }
   # (5A21EF8B.016F-22:kshxmlxp.cpp,500,"addelement") Nodename: "CT_Get" ("CT_Get")
   # (5A21EF8B.017F-22:kshxmlxp.cpp,875,"setValue") "userid" set to "sysadmin"
   if (substr($logunit,0,12) eq "kshxmlxp.cpp") {
      if ($logentry eq "addelement") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Nodename: "CT_Get" ("CT_Get")
         if (substr($rest,1,8) eq "Nodename") {
            $soaprun_def = $soaprunx{$logthread};
            if (defined $soaprun_def) {
               $rest =~ /Nodename: \"(\S+)\"/;
               my $inodename = $1;
               $soaprun_def->{msgi} += 1;
               $soaprun_def->{msg}[$soaprun_def->{msgi}]{$inodename} = "";
            }
         }
      } elsif ($logentry eq "setValue") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # "userid" set to "sysadmin"
         if (index($rest,"set to") != -1) {
            $soaprun_def = $soaprunx{$logthread};
            if (defined $soaprun_def) {
               $rest =~ /\"(\S+)\" set to \"(.*)\"/;
               my $inodename = $1;
               my $ivalue = $2;
               $soaprun_def->{msg}[$soaprun_def->{msgi}]{$inodename} = $ivalue;
            }
         }
      }
   }


   if (substr($logunit,0,11) eq "kshdhtp.cpp") {
      if ($logentry eq "getHeaderValue") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Header is <ip.ssl:#10.41.100.21:38317>
         next if substr($rest,1,13) ne "Header is <ip";
         $rest =~ /<(.*?)>/;
         $soapip_lag = $1;
         $soaprun_def = $soaprunx{$logthread};
         $soaprun_def->{ip} = $soapip_lag if defined $soaprun_def;
      }
      next;
   }
   if (substr($logunit,0,10) eq "kshreq.cpp") {
      # (5A21EF8B.025B-22:kshreq.cpp,2696,"Fetch") Response is l'250:
      # +5A21EF8B.025B "<TABLE name="O4SRV.UTCTIME">
      # +5A21EF8B.025B <OBJECT>Universal_Time</OBJECT
      # +5A21EF8B.025B <DATA>
      # +5A21EF8B.025B <ROW>
      # +5A21EF8B.025B <THRUNODE>HUB_NMP180</THRUNODE>
      # +5A21EF8B.025B <AFFINITIES>0000000080000000000000000000000004000H46Of0</AFFINITIES>
      # +5A21EF8B.025B <VERSION>06.30.04</VERSION>
      # +5A21EF8B.025B <O4ONLINE>Y</O4ONLINE>
      # +5A21EF8B.025B </ROW>
      # ...
      # (5A21EF8B.025C-22:kshreq.cpp,2704,"Fetch") Exit: 0x0
      if ($logentry eq "Fetch") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Response is l'250:
         if (substr($rest,1,8) eq "Response") {
            $soaprun_def = $soaprunx{$logthread};
            if (defined $soaprun_def) {
               $contkey = substr($oneline,1,13);
               $soapcap_def = $soapcapx{$contkey};
               if (!defined $soapcap_def) {
                  $soapcapx{$contkey} = $soaprun_def;
               }
            }
         }
      } elsif ($logentry eq "buildSQL") {
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
   #(5A1D433C.0002-107:kshdsr.cpp,361,"login") Create Path Error st=1010 for 'ie4013t' 'xxxxxxxx' 'ip.ssl'
   if (substr($logunit,0,10) eq "kshdsr.cpp") {
      if ($logentry eq "login") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       # Create Path Error st=1010 for 'ie4013t' 'xxxxxxxx' 'ip.ssl'
         if (substr($rest,1,17) eq "Create Path Error"){
            $rest =~ /Create Path Error st=(\d+) for \'(\S+)\'/;
            my $ierror = $1;
            my  $iuser = $2;
            $loginx{$iuser} .= $ierror . ";";
         }
      }
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
            $rest =~ /table tree (\S+).*/;
            my $itable = $1;
            if (defined $itable) {
               $soapcat{$itable} += 1;
            }
            next;
         }
      }
   }


   # (5A3D08BE.0057-3:kdsstc1.c,1451,"ProcessTable") Entry
   # (5A3D08BE.0059-3:kdsstc1.c,2097,"ProcessTable") Table Status = 77, Rowcount = 0, TableName = TAPPLOGT, Query Type = Select, TablePath =
   # (5A3D08BE.005A-3:kdsstc1.c,2184,"ProcessTable") Exit: 0x4D
   if (substr($logunit,0,9) eq "kdsstc1.c") {
      if ($logentry eq "ProcessTable") {
         # record start/end times
         if ($pt_stime == 0) {
             $pt_stime = $logtime;
             $pt_etime = $logtime;
            }
         $pt_stime = $logtime if $logtime < $pt_stime;
         $pt_etime = $logtime if $logtime > $pt_etime;


         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,5) eq "Entry") { #  Entry
            my $prt_ref = $prtrunx{$logthread};
            if (!defined $prt_ref) {
               my %prtref = (
                               entry_time => $logtime,
                               epoch => $logtimehex,
                               status_time => 0,
                               exit_time => 0,
                               exit_code => "",
                               status => "",
                               rows => 0,
                               table => "",
                               type => "",
                               path => "",
                               count => 0,
                               l => $l,
                            );
               $prtrunx{$logthread} = \%prtref;
               $prt_ref = \%prtref;
            }
            $prt_ref->{count} += 1;
            $prt_current += 1;
            if ($prt_current > $prt_max) {
               $prt_max = $prt_current;
               $prt_max_l = $l;
            }
         } elsif (substr($rest,1,14) eq "Table Status =") { # Table Status = 74, Rowcount = 0, TableName = WTMEMORY, Query Type = Select, TablePath = WTMEMORY
            my $prt_ref = $prtrunx{$logthread};
            if (defined $prt_ref) { # only process known cases from previous threads
               $rest =~ /.*?= (\S+)\,.*?=\s+(\S+)\,.*?= (\S+)\,.*?=\s*(.*?)\,.*?=\s*(\S*)/;
               $prt_ref->{status} = $1;
               $prt_ref->{rows} = $2;
               $prt_ref->{table} = $3;
               $prt_ref->{type} = $4;
               $prt_ref->{path} = $5;
               $prt_ref->{status_time} = $logtime;
            }
         } elsif (substr($rest,1,5) eq "Exit:") { # Exit: 0x4D
            my $prt_ref = $prtrunx{$logthread};
            if (defined $prt_ref) { # only process known cases from previous threads
               if ($prt_ref->{status_time} > 0) { # handle a case where a status line never showed
                  $rest =~ /Exit: (\S*)/;
                  $prt_ref->{exit_code} = $1;
                  $prt_ref->{exit_time} = $logtime;
                  $ipt_status = $prt_ref->{status};
                  $ipt_rows = $prt_ref->{rows};
                  $ipt_table = $prt_ref->{table};
                  $ipt_type = $prt_ref->{type};
                  $ipt_path  = $prt_ref->{path};
                  my $post = index($ipt_type,",");
                  $ipt_type = substr($ipt_type,0,$post) if $post > 0;
                  $ipt_path =~ s/(^\s+|\s+$)//g;
                  $ipt_key = $ipt_table . "_" . $ipt_path;
                  my $prtsum_ref = $prtx{$ipt_key};
                  if (!defined $prtsum_ref) {
                     my %prtsumref = (
                                        count => 0,
                                        table => $ipt_table,
                                        path => $ipt_path,
                                        rows => 0,
                                        status => {},
                                        insert_ct => 0,
                                        query_ct => 0,
                                        select_ct => 0,
                                        selectpre_ct => 0,
                                        delete_ct => 0,
                                        total_ct => 0,
                                        error_ct => 0,
                                        errors => {},
                                     );
                     $prtx{$ipt_key} = \%prtsumref;
                     $prtsum_ref = \%prtsumref;
                  }
                  $prtsum_ref->{count} += 1;
                  $prtsum_ref->{rows} +=  $ipt_rows;
                  $prtsum_ref->{status}{$ipt_status} += 1;
                  $prtsum_ref->{total_ct} += 1;
                  $prtsum_ref->{insert_ct} += 1 if $ipt_type eq "Insert";
                  $prtsum_ref->{query_ct} += 1 if $ipt_type eq "Query";
                  $prtsum_ref->{select_ct} += 1 if $ipt_type eq "Select";
                  $prtsum_ref->{selectpre_ct} += 1 if $ipt_type eq "Select PreFiltered";
                  $prtsum_ref->{delete_ct} += 1 if $ipt_type eq "Delete";
                  if ($ipt_type eq "Insert") {
                    if (($ipt_status != 74) and ($ipt_status != 0) ) {
                       $prtsum_ref->{error_ct} += 1;
                       $prtsum_ref->{errors}{$ipt_status} += 1;
                    }
                  } elsif ($ipt_status != 0) {
                    $prtsum_ref->{error_ct} += 1;
                    $prtsum_ref->{errors}{$ipt_status} += 1;
                  }

                  # calculate ProcessTable at same time.
                  my $ipt_dur = $prt_ref->{exit_time} - $prt_ref->{entry_time};
                  if ($ipt_dur > 1) {
                     my $key = $prt_ref->{entry_time} . "|" . $prt_ref->{l};
                     my $dur_ref = $prtdurx{$key};
                     if (!defined $dur_ref) {
                        my %durref = (
                                        entry_time => $prt_ref->{entry_time},
                                        epoch => $prt_ref->{epoch},
                                        l => $prt_ref->{l},
                                        dur => $ipt_dur,
                                        key => $ipt_key,
                                        max => $prt_max,
                                     );
                        $dur_ref = \%durref;
                        $prtdurx{$key} = \%durref;
                     }

                  }
                  my $key = sec2slot($prt_ref->{entry_time});
                  my $evhist_ref = $evhist{$key};
                  if (!defined $evhist_ref) {
                        my %evhistref = (
                                           status => {},
                                           situation => {},
                                           ptexit_ct => 0,
                                           ptdur_tot => 0,
                                           ptdur_max => 0,
                                           ptdur_maxsl => 0,
                                           ptdur_maxel => 0,
                                           ptlevel_max => 0,
                                           ptlevel_tot => 0,
                                           count => 0,
                                        );
                        $evhist_ref = \%evhistref;
                        $evhist{$key} = \%evhistref;
                     }
                  $evhist_ref->{ptexit_ct} += 1;
                  $evhist_ref->{ptdur_tot} += $logtime - $prt_ref->{entry_time};
                  $evhist_ref->{ptlevel_tot} += $prt_current;
                  $evhist_ref->{ptlevel_max} = $prt_current if $prt_current > $evhist_ref->{ptlevel_max};
                  if (($logtime - $prt_ref->{entry_time}) > $evhist_ref->{ptdur_max}) {
                     $evhist_ref->{ptdur_max} = $logtime - $prt_ref->{entry_time};
                     $evhist_ref->{ptdur_maxsl} = $prt_ref->{l};
                     $evhist_ref->{ptdur_maxel} = $l;
                  }
               }
               $prt_current -= 1;
               delete $prtrunx{$logthread};
            }
         }
         next;
      }
   }

   #(5A2668D0.0004-68:kdsvws1.c,2421,"ManageView") ProcessTable TNODESTS Insert Error status = ( 1551 ).  SRVR01 ip.spipe:#10.64.11.30[3660]
   if (substr($logunit,0,9) eq "kdsvws1.c") {
      if ($logentry eq "ManageView") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;                       #  ProcessTable TNODESTS Insert Error status = ( 1551 ).  SRVR01 ip.spipe:#10.64.11.30[3660] EMORY
         if (index($rest,"ProcessTable TNODESTS Insert") != -1) {
            if ($pti_stime == 0) {
                $pti_stime = $logtime;
                $pti_etime = $logtime;
            }
            if ($logtime < $pti_stime) {
               $pti_stime = $logtime;
            }
            if ($logtime > $pti_etime) {
                 $pti_etime = $logtime;
            }
            $rest =~ /\( (\d+) \).*?SRVR01 (\S+\])/;
            my $icode = $1;
            my $iaddr = $2;
            $pti_ref = $ptix{$iaddr};
            if (!defined $pti_ref) {
               my %ptiref = (
                               count => 0,
                               codes => {},
                            );
               $pti_ref = \%ptiref;
               $ptix{$iaddr} = \%ptiref;
            }
            $pti_ref->{count} += 1;
            $pti_ref->{codes}{$icode} += 1;
         }
         next;
      }
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
      # (58694088.0001-3A:khdxhist.cpp,3058,"copyHistoryFile") Found 1 corrupted rows for "KA4PFJOB". Rows were skipped during copying.
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
         } elsif (index($rest,"corrupted rows") != -1) {
            $rest =~ / Found (\d+) corrupted rows for \"(.*?)\"/;
            $inrows = $1;
            $intable = $2;
            $hist_corruptedx{$intable} += $inrows;
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
   #(5970DEB6.0002-2E:kfavalid.c,773,"KFA_ValidateNodeNameSpace") Potential DUPLICATE NODE INSERT detected.
   #+5970DEB6.0002  Insert request for node name <boi_boipva23:KUL                >
   #+5970DEB6.0002 and thrunode <REMOTE_t01rt07px                > with product code <VA>
   #+5970DEB6.0002 matches an existing node with with thrunode <REMOTE_t02rt08px                >
   #+5970DEB6.0002 and product code <UL>.   Please verify that
   #+5970DEB6.0002 that the node name in question is not a duplicate
   #+5970DEB6.0002 of a agent attached at another TEMS or is being
   #+5970DEB6.0002 truncated because it is larger than 32 characters.
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
      #5970DEB6.0002-2E:kfavalid.c,773,"KFA_ValidateNodeNameSpace") Potential DUPLICATE NODE INSERT detected
      } elsif ($logentry eq "KFA_ValidateNodeNameSpace") {
         $oneline =~ /^\((\S+)\)(.+)$/;
         $rest = $2;
         if (substr($rest,1,40) eq "Potential DUPLICATE NODE INSERT detected") { # Potential DUPLICATE NODE INSERT detected
            $contkey = substr($oneline,1,13);
            $dnrun_def = $dnrunx{$contkey};
            if (!defined $dnrun_def) {
                my %dnrundef = (
                                  thread => $logthread,
                                  node => "",
                                  thrunode => "",
                                  product => "",
                                  thrunode_new => "",
                                  product_new => "",
                               );
                $dnrun_def = \%dnrundef;
                $dnrunx{$contkey} = \%dnrundef;
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
   $sitrow_key = $isit . "|" . $inode;
   $sitrow_ref = $sitrowx{$sitrow_key};
   if (!defined $sitrow_ref) {
      my %sitrowref = (
                         sit => $isit,
                         node => $inode,
                         ip => "",
                         tems => $opt_nodeid,
                         count => 0,
                         norows => 0,
                         rowfraction => 0,
                         start => 0,
                         end => 0,
                      );
      $sitrow_ref = \%sitrowref;
      $sitrowx{$sitrow_key} = \%sitrowref;
   }
   $sitrow_ref->{count} += 1;
   $sitrow_ref->{norows} += 1 if $irows == 0;
   if ($sitrow_ref->{start} == 0) {
      $sitrow_ref->{start} = $logtime;
      $sitrow_ref->{end} = $logtime;
   }
   $sitrow_ref->{start} = $logtime if $logtime < $sitrow_ref->{start};
   $sitrow_ref->{end} = $logtime if $logtime > $sitrow_ref->{end};

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
foreach $f (keys %sqlrunx) {
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
   $rptkey = "TEMSREPORT001";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="$rptkey: Too Big Report\n";
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

my $hist_corrupted_ct = scalar keys %hist_corruptedx;
if ($hist_corrupted_ct > 0) {
   foreach $f (keys %hist_corruptedx) {

      $advi++;$advonline[$advi] = "$hist_corruptedx{$f} corrupted rows in Short Term History table $f";
      $advcode[$advi] = "TEMSAUDIT1084W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

if ($toobigi > -1) {
      my $ptoobigi = $toobigi + 1;
      $advi++;$advonline[$advi] = "$ptoobigi Filter object(s) too big situations and/or reports - See Report $rptkey";
      $advcode[$advi] = "TEMSAUDIT1001W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TooBig";
   }

my $mhm_ct = scalar keys %mhmx;
if ($mhm_ct > 0) {
   $rptkey = "TEMSREPORT044";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="$rptkey: FTO control messages\n";
   $cnt++;$oline[$cnt]="Epoch,Local_Time,Line_number,Message\n";
   foreach $f ( sort { $a cmp $b } keys %mhmx) {
      $outl = substr($f,0,8) . ",";
      $outl .= sec2ltime(hex(substr($f,0,8))+$local_diff) . ",";
      $outl .= substr($f,9) . ",";
      $outl .= $mhmx{$f} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $cnt++;$oline[$cnt]="\n";
}


if ($opt_kdcb0 ne "") {
   if ($opt_kdebi ne "") {
      if ($opt_kdcb0 ne $opt_kdebi) {
         $advi++;$advonline[$advi] = "KDEB_INTERFACELIST[$opt_kdebi] and KDCB0_HOSTNAME[$opt_kdcb0] conflict";
         $advcode[$advi] = "TEMSAUDIT1080E";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "TEMS";
      }
   }
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
   $test_ras1 =~ s/^\s+|\s+$//;     # strip leading/trailing white space
   if (index($test_ras1,"error") == -1) {
      $advi++;$advonline[$advi] = "KBB_RAS1 missing the all important ERROR specification";
      $advcode[$advi] = "TEMSAUDIT1032E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Ras1";
   } elsif (substr($test_ras1,0,1) eq "'") {
      $advi++;$advonline[$advi] = "KBB_RAS1 starts with single quote which prevents expected usage";
      $advcode[$advi] = "TEMSAUDIT1081E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Ras1";
   }
}


my $res_pc = 0;
my $trc_pc = 0;
my $soap_pc = 0;
my $res_max = 0;


$rptkey = "TEMSREPORT002";$advrptx{$rptkey} = 1;         # record report key
$cnt++;$oline[$cnt]="$rptkey: Summary Statistics\n";
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
   $advi++;$advonline[$advi] = "Results bytes per minute $ppc higher then nominal [$opt_nominal_results] - See Report $rptkey";
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
   $advi++;$advonline[$advi] = "Trace bytes per minute $ppc higher then nominal $opt_nominal_trace - See Report $rptkey";
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

my $portscan_timex_ct = scalar keys %portscan_timex;
if ($opt_portscan == 1) {
   if ($portscan_timex_ct > 0) {
      $rptkey = "TEMSREPORT042";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: Portscan Time Report\n";
      $cnt++;$oline[$cnt]="Epoch,Local_Time,Scan_Types,\n";
      foreach $f ( sort { $a cmp $b } keys %portscan_timex) {
         $outl = $f . ",";
         $outl .= sec2ltime(hex($f)+$local_diff) . ",";
         my $pscans = join(" ",@{$portscan_timex{$f}});
         $outl .= $pscans . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
      $cnt++;$oline[$cnt]="\n";
   }
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
my $pcb_deletePCB_tot = 0;
my $pcb_deletePCB90 = 0;
foreach $f (keys %pcbx) {
   my $pcb_ref = $pcbx{$f};
   $pcb_total += 1;
   next if $pcb_ref->{deletePCB} < 2;
   $pcb_deletePCB_tot += $pcb_ref->{deletePCB};
   $pcb_deletePCB += 1;
}
$pcb_deletePCB90 = int($pcb_deletePCB_tot*.95);

if ($pcb_deletePCB > 0) {
   $advi++;$advonline[$advi] = "Agent connection churning on [$pcb_deletePCB] systems total[$pcb_total] - view TEMSREPORT026 report";
   $advcode[$advi] = "TEMSAUDIT1050W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "PCB";

}

$soaperror_ct = scalar keys %soaperror;
if ($soaperror_ct > 0) {
   my $pcnt = $soaperror_ct + 1;
   $advi++;$advonline[$advi] = "SOAP Errors Types [$pcnt] Detected - See TEMSREPORT027 report";
   $advcode[$advi] = "TEMSAUDIT1054W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "SOAP";

}

my $login_ct = scalar keys %loginx;
if ($login_ct > 0) {
   foreach $f (keys %loginx) {
      $advi++;$advonline[$advi] = "SOAP User Login Failure $f [$loginx{$f}]";
      $advcode[$advi] = "TEMSAUDIT1086W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "SOAP";
   }
}

my $readn_ct = scalar keys %readnextx;
if ($readn_ct > 0) {
   foreach $f (keys %readnextx) {
      $advi++;$advonline[$advi] = "TSITSTSH Read Error $f [$readnextx{$f}]";
      $advcode[$advi] = "TEMSAUDIT1089E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}


my $change_real = 0;
if ($changex_ct > 0) {
   foreach $f ( sort { $a cmp $b } keys %changex) {
      my $change_ref = $changex{$f};
      foreach $g (keys %{$change_ref->{nodes}}) {
         my $change_node_ref = $change_ref->{nodes}{$g};
         next if $change_node_ref->{count} < 2;
         $change_real += 1;
      }
   }
   if ($change_real > 0) {
      $advi++;$advonline[$advi] = "Agent Location Flipping Changes Detected [$change_real] - See TEMSREPORT028 report";
      $advcode[$advi] = "TEMSAUDIT1055W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Agent";
   }
}

$misscolx_ct = scalar keys %misscolx;
if ($misscolx_ct > 0) {
   foreach $f (keys %misscolx) {
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

foreach $f (keys %soapcat) {
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

my $gerror_ct = scalar keys %gskiterrorx;
if ($gerror_ct > 0) {
   foreach $f ( sort { $gskiterrorx{$b}->{count} <=> $gskiterrorx{$a}->{count}} keys %gskiterrorx) {
      my $gerror_ref =  $gskiterrorx{$f};
      $advi++;$advonline[$advi] = "GSKIT Secure Communications error code $f [$gerror_ref->{count}] - $gerror_ref->{text}";
      $advcode[$advi] = "TEMSAUDIT1058E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "Comm";
   }
}

my $sit32_total = scalar keys %sit32x;
if ($sit32_total > 0) {
   $advi++;$advonline[$advi] = "Situations [$sit32_total] with length 32 - see TEMSREPORT029 report";
   $advcode[$advi] = "TEMSAUDIT1060W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

my $sitrul_total = scalar keys %sitrulx;
if ($sitrul_total > 0) {
   foreach $f (keys %sitrulx) {
      $sitrul_ref = $sitrulx{$f};
      $advi++;$advonline[$advi] = "Situation [$sitrul_ref->{sitname}] with unknown attribute [$sitrul_ref->{atr}] - [$sitrul_ref->{pdt}]";
      $advcode[$advi] = "TEMSAUDIT1061E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

my $nodeignore_total = scalar keys %node_ignorex;
if ($nodeignore_total > 0) {
   foreach $f (keys %node_ignorex) {
      $advi++;$advonline[$advi] = "Node [$f] thrunode [$node_ignorex{$f}] ignored because attribute unknown";
      $advcode[$advi] = "TEMSAUDIT1062W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

my $sth_total = scalar keys %sthx;
if ($sth_total > 0) {
   foreach $f (keys %sthx) {
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

foreach $f (keys %miss_tablex) {
   $advi++;$advonline[$advi] = "Application.table $f missing $miss_tablex{$f} times";
   $advcode[$advi] = "TEMSAUDIT1011W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Miss";
}

my $et = scalar keys %etablex;
if ($et > 0) {
   foreach $f (keys %etablex) {
      my $etct = $etablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct errors";
      $advcode[$advi] = "TEMSAUDIT1022E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

if ($seedfile_ct > 0) {
   $advi++;$advonline[$advi] = "Seed file messages seen $seedfile_ct times";
   $advcode[$advi] = "TEMSAUDIT1075I";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

$et = scalar keys %dtablex;
if ($et > 0) {
   foreach $f (keys %dtablex) {
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
   foreach $f (keys %vtablex) {
      my $etct = $vtablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct Verify Index errors";
      $advcode[$advi] = "TEMSAUDIT1044E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %rdtablex;
if ($et > 0) {
   foreach $f (keys %rdtablex) {
      my $etct = $rdtablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table SITDB with $etct Read errors";
      $advcode[$advi] = "TEMSAUDIT1041E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %itablex;
if ($et > 0) {
   foreach $f (keys %itablex) {
      my $etct = $itablex{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS database table with $etct Open Index errors";
      $advcode[$advi] = "TEMSAUDIT1040E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

$et = scalar keys %rtablex;
if ($et > 0) {
   foreach $f (keys %rtablex) {
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

if ($tec_classname_ct > 0) {
   $advi++;$advonline[$advi] = "Translate TEC Send event failed $tec_classname_ct times - not a problem";
   $advcode[$advi] = "TEMSAUDIT1090I";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

if ($tec_translate_ct > 0) {
   $advi++;$advonline[$advi] = "TEC Classname unable to translate $tec_translate_ct times - not a problem";
   $advcode[$advi] = "TEMSAUDIT1091I";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

$et = scalar keys %derrorx;
if ($et > 0) {
   foreach $f (keys %derrorx) {
      my $etct = $derrorx{$f}->{count};
      $advi++;$advonline[$advi] = "TEMS Event Destination experienced $etct send errors";
      $advcode[$advi] = "TEMSAUDIT1025E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = $f;
   }
}

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

$rptkey = "TEMSREPORT047";$advrptx{$rptkey} = 1;         # record report key
my %sitrowsumx;
my $sitrowsum_ref;
foreach $f ( keys %sitrowx ) {
   my $sitrow_ref = $sitrowx{$f};
   $sitrow_ref->{rowfraction} = ($sitrow_ref->{count} - $sitrow_ref->{norows}) / $sitrow_ref->{count};
   my $sitrowsum_ref = $sitrowsumx{$sitrow_ref->{sit}};
   if (!defined $sitrowsum_ref) {
      my %sitrowsumref = (
                            nodes => {},
                            count => 0,
                            norows => 0,
                            rowfraction => 0,
                         );
      $sitrowsum_ref = \%sitrowsumref;
      $sitrowsumx{$sitrow_ref->{sit}} = \%sitrowsumref;
   }
   $sitrowsum_ref->{nodes}{$sitrow_ref->{node}} = 1;
   $sitrowsum_ref->{count} += $sitrow_ref->{count};
   $sitrowsum_ref->{norows} += $sitrow_ref->{norows};
}
foreach $f ( keys %sitrowsumx ) {
   $sitrowsum_ref = $sitrowsumx{$f};
   $sitrowsum_ref->{rowfraction} = ($sitrowsum_ref->{count} - $sitrowsum_ref->{norows}) / $sitrowsum_ref->{count};
}
my $sitrowsum_ct = 0;
my $sitrowsumx_ct = scalar keys %sitrowsumx;
if ($sitrowsumx_ct > 0) {
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Summary Situation-Node often true by Situation\n";
   $cnt++;$oline[$cnt]="Situation,Fraction,Count,Norows,Nodes,\n";
   foreach $f ( sort { $sitrowsumx{$b}->{rowfraction} <=> $sitrowsumx{$a}->{rowfraction} ||
                       $sitrowsumx{$b}->{count} <=> $sitrowsumx{$a}->{count}  } keys %sitrowsumx ) {
      my $sitrowsum_ref = $sitrowsumx{$f};
      next if $sitrowsum_ref->{count} < 2;
      next if $f eq "HEARTBEAT";
      next if substr($f,0,8) eq "UADVISOR";
      next if substr($f,0,6) eq "(NULL)";
      $outl = $f . ",";
      my $res_pc = int($sitrowsum_ref->{rowfraction}*100);
      my $ppc = sprintf '%.0f%%', $res_pc;
      $outl .= $ppc . ",";
      $outl .= $sitrowsum_ref->{count} . ",";
      $outl .= $sitrowsum_ref->{norows} . ",";
      my $node_ct = scalar keys  %{$sitrowsum_ref->{nodes}};
      $outl .= $node_ct . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $sitrowsum_ct += 1 if $sitrowsum_ref->{rowfraction} >= 0.90;
   }
   if ($sitrowsum_ct > 0) {
      $advi++;$advonline[$advi] = "Situations [$sitrowsum_ct] true 90% of the time - See following reports $rptkey";
      $advcode[$advi] = "TEMSAUDIT1083W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }

   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Detail Situation-Node often true by Situation and Node\n";
   $cnt++;$oline[$cnt]="Situation,Percent,Count,Norows,Node,ip,tems,duration,secs/result,\n";
   foreach $f ( sort { $sitrowx{$b}->{rowfraction} <=> $sitrowx{$a}->{rowfraction} ||
                       $sitrowx{$b}->{count} <=> $sitrowx{$a}->{count}  } keys %sitrowx ) {
      my $sitrow_ref = $sitrowx{$f};
      next if $sitrow_ref->{count} < 2;
      next if $sitrow_ref->{sit} eq "HEARTBEAT";
      next if substr($sitrow_ref->{sit},0,8) eq "UADVISOR";
      next if substr($f,0,6) eq "(NULL)";
      my $res_pc = int($sitrow_ref->{rowfraction}*100);
      my $ppc = sprintf '%.0f%%', $res_pc;
      $outl = $sitrow_ref->{sit} . ",";
      $outl .= $ppc . ",";
      $outl .= $sitrow_ref->{count} . ",";
      $outl .= $sitrow_ref->{norows} . ",";
      $outl .= $sitrow_ref->{node} . ",";
      $outl .= $sitrow_ref->{ip} . ",";
      $outl .= $sitrow_ref->{tems} . ",";
      my $dur = $sitrow_ref->{end} - $sitrow_ref->{start};
      $outl .= $dur . ",";
      $res_pc = $dur/$sitrow_ref->{count};
      $ppc = sprintf '%.2f', $res_pc;
      $outl .= $ppc . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
}

if ($opt_rd == 1) {
   my $peakrate = 0;
   $rptkey = "TEMSREPORT003";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Situation Result Over Time Report [Top $opt_rdtop situation contributors]\n";
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
      $cnt++;$oline[$cnt]="$rptkey: Situation Result Over Time Graph - peak rate is $peakrate bytes per minute\n";
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
   $rptkey = "TEMSREPORT004";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Endpoint Communication Problem Report\n";
   $cnt++;$oline[$cnt]="Code,Text,Count,Source,Level\n";
   foreach $f ( sort { $a cmp $b } keys %codex ) {
      $code_ref = $codex{$f};
      $outl = $f . ",";
      $outl .= $code_ref->{text} . ",";
      $outl .= $code_ref->{count} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      foreach $g ( sort { $a cmp $b } keys %{$code_ref->{conv}} ) {
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
   $rptkey = "TEMSREPORT005";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Reflex Command Summary Report\n";
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
   $rptkey = "TEMSREPORT006";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: SQL Summary Report\n";
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
      $rptkey = "TEMSREPORT007";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: SQL Detail Report\n";
      $cnt++;$oline[$cnt]="Type,Count,Duration,Rate/Min,Source,Table,SQL\n";
      $outl = "total" . ",";
      $outl .= $sql_ct_total . ",";
      $outl .= $sql_duration . ",";
      $sql_rate = 0;
      $sql_rate = ($sql_ct_total*60)/$sql_duration if $sql_duration > 0;
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
   $rptkey = "TEMSREPORT008";$advrptx{$rptkey} = 1;         # record report key
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
      $advi++;$advonline[$advi] = "SOAP requests per minute $ppc higher then nominal $opt_nominal_soap - See Report $rptkey";
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

my $prt_ct = scalar keys %prtx;
if ($prt_ct > 0) {
   $pt_dur = $pt_etime - $pt_stime;
   my $pr_total_total = 0;
   $rptkey = "TEMSREPORT009";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Process Table Report\n";
   $cnt++;$oline[$cnt]="Process Table Duration: $pt_dur seconds\n";
   $cnt++;$oline[$cnt]="Table,Path,Insert,Query,Select,SelectPreFiltered,Delete,Total,Total/min,Error,Error/min,Errors\n";
   foreach $f ( sort { $prtx{$b}->{count} <=> $prtx{$a}->{count} || $prtx{$a}->{table} cmp $prtx{$b}->{table} } keys %prtx) {
      my $prt_ref = $prtx{$f};
      $outl = $prt_ref->{table} . ",";
      $outl .= $prt_ref->{path} . ",";
      $outl .= $prt_ref->{insert_ct} . ",";
      $outl .= $prt_ref->{query_ct} . ",";
      $outl .= $prt_ref->{select_ct} . ",";
      $outl .= $prt_ref->{selectpre_ct} . ",";
      $outl .= $prt_ref->{delete_ct} . ",";
      $outl .= $prt_ref->{total_ct} . ",";
      $pr_total_total += $prt_ref->{total_ct};
      $respermin = int($prt_ref->{total_ct} / ($pt_dur / 60));
      $outl .= $respermin . ",";
      $respermin = int($prt_ref->{error_ct} / ($pt_dur / 60));
      $outl .= $respermin . ",";
      my @perror = keys %{$prt_ref->{errors}};
      $outl .= join(" ",@perror) . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   $respermin = int($pt_total_total / ($pt_dur / 60));
   $cnt++;$oline[$cnt]="*total*,,,,,,,$pt_total_total,$respermin,\n";

   $rptkey = "TEMSREPORT052";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Process Table Report Delays - Max overlay $prt_max\n";
   $cnt++;$oline[$cnt]="LocalTime,Epoch,Delay,Line,Table/Path,Max,\n";
   foreach $f ( sort { $prtdurx{$b}->{dur} <=> $prtdurx{$a}->{dur} } keys %prtdurx) {
      my $prtdur_ref = $prtdurx{$f};
      my $ltime = sec2ltime($prtdur_ref->{entry_time}+$local_diff);
      $outl = $ltime . ",";
      $outl .= $prtdur_ref->{epoch} . ",";
      $outl .= $prtdur_ref->{dur} . ",";
      $outl .= $prtdur_ref->{l} . ",";
      $outl .= $prtdur_ref->{key} . ",";
      $outl .= $prtdur_ref->{max} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
}
my $total_evt = 0;
my %total_status = ();
my $pe_dur;
my $pevt_size = scalar keys %pevtx;
if ($pevt_size > 0) {
   $pe_dur = $pe_etime - $pe_stime;
   $rptkey = "TEMSREPORT010";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: PostEvent Report\n";
   $cnt++;$oline[$cnt]="Situation,Node,Count,AtomCount,Thrunodes,Status,\n";
   my %pesumx;
   my $pesum_ref;
   foreach $f ( sort { $pevtx{$b}->{count} <=> $pevtx{$a}->{count} } keys %pevtx) {
      $outl = $pevtx{$f}->{sitname} . ",";
      $outl .= $pevtx{$f}->{node} . ",";
      $outl .= $pevtx{$f}->{count} . ",";
      $total_evt += $pevtx{$f}->{count};
      my $acount = keys %{$pevtx{$f}->{atoms}};
      $outl .= $acount . ",";
      my $tlist = join(" ",keys %{$pevtx{$f}->{thrunode}});
      $outl .= $tlist . ",";
      my $pstatus = "";
      foreach $g (keys %{$pevtx{$f}->{status}}) {
         $pstatus .= $g . "[" . $pevtx{$f}->{status}{$g} . "] ";
      }
      $outl .= $pstatus . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $pesum_ref = $pesumx{$pevtx{$f}->{sitname}};
      if (!defined $pesum_ref) {
         my %pesumref = (
                           count => 0,
                           nodes => 0,
                           status => {},
                        );
         $pesum_ref = \%pesumref;
         $pesumx{$pevtx{$f}->{sitname}} = \%pesumref;
      }
      $pesum_ref->{count} += $pevtx{$f}->{count};
      $pesum_ref->{nodes} += 1;
      foreach $g (keys %{$pevtx{$f}->{status}}) {
         $pesum_ref->{status}{$g} += $pevtx{$f}->{status}{$g};
      }
   }
   my $evtpermin = $total_evt / ($pe_dur / 60) if $pe_dur > 0;
   my $ppc = sprintf '%.2f', $evtpermin;
   $cnt++;$oline[$cnt]="*total*,$pe_dur,$total_evt,$ppc/min,\n";

   $rptkey = "TEMSREPORT045";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: PostEvent Report Summary\n";
   $cnt++;$oline[$cnt]="Situation,Count,Nodes,Rate,Status\n";
   foreach $f ( sort { $pesumx{$b}->{count} <=> $pesumx{$a}->{count} } keys %pesumx) {
      $outl = $f . ",";
      $outl .= $pesumx{$f}->{count} . ",";
      $outl .= $pesumx{$f}->{nodes} . ",";
      my $evtpermin = $pesumx{$f}->{count} / ($pe_dur / 60) if $pe_dur > 0;
      my $ppc = sprintf '%.2f', $evtpermin;
      $outl .= $ppc . "/min,";
      my $pstatus = "";
      foreach $g (keys %{$pesumx{$f}->{status}}) {
         $pstatus .= $g . "[" . $pesumx{$f}->{status}{$g} . "] ";
         $total_status{$g} += $pesumx{$f}->{status}{$g};
      }
      $outl .= $pstatus . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
   foreach $f (keys %total_status) {
      $outl = "Incoming $f" . "[$total_status{$f}] rate ";
      my $statrate = $total_status{$f} / ($pe_dur / 60) if $pe_dur > 0;
      my $ppc = sprintf '%.2f', $statrate;
      $outl .= $ppc . "/min over $pe_dur seconds.";
      $advi++;$advonline[$advi] = "Situation Event Status $f" . "[$total_status{$f}] rate $ppc/min over $pe_dur seconds - see reports TEMSREPORT010 and TEMSREPORT045.";
      $advcode[$advi] = "TEMSAUDIT1092W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

my $evhist_size = scalar keys %evhist;
if ($evhist_size > 0) {
   $rptkey = "TEMSREPORT053";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: PostEvent/ProcessTable Report by time\n";
   $cnt++;$oline[$cnt]="TimeSlot,Event_Count,Event_Rate/Sec,Situation_Count,Status_Count,Status_Type,PT_Count,PT_Rate/sec,Duration_total,Duration_max,Duration_Avg,Level_max,Level_min,Level_total,Level_Avg,\n";
   my $rate;
   my $ppc;
   foreach $f ( sort { $a <=> $b } keys %evhist) {
      my $evhist_ref = $evhist{$f};

      $outl = $f . ",";
      $outl .= $evhist_ref->{count} . ",";
      $rate = ($evhist_ref->{count} ) / ($opt_evslot*60);
      $ppc = sprintf '%.2f', $rate;
      $outl .= $ppc . ",";
      my $sit_ct = scalar keys %{$evhist_ref->{situation}};
      $outl .= $sit_ct . ",";
      my $pstatus = "";
      my $pstatus_ct = 0;
      foreach $g (keys %{$evhist_ref->{status}}) {
         $pstatus .= $g . "[" . $evhist_ref->{status}{$g} . "] ";
         $pstatus_ct += $evhist_ref->{status}{$g};
      }
      $outl .= $pstatus_ct . "," . $pstatus . ",";
      $outl .= $evhist_ref->{ptexit_ct} . ",";
      $rate = ($evhist_ref->{ptexit_ct} ) / ($opt_evslot*60);
      $ppc = sprintf '%.2f', $rate;
      $outl .= $ppc . ",";
      $outl .= $evhist_ref->{ptdur_tot} . "," . $evhist_ref->{ptdur_max} . "(" . $evhist_ref->{ptdur_maxsl} . "-" .  $evhist_ref->{ptdur_maxel} . ")" . ",";
      $rate = 0;
      $rate = $evhist_ref->{ptdur_tot} / $evhist_ref->{ptexit_ct} if $evhist_ref->{ptexit_ct} > 0;
      $ppc = sprintf '%.2f', $rate;
      $outl .= $ppc . ",";
      $outl .= $evhist_ref->{ptlevel_max} . ",";
      $outl .= $evhist_ref->{ptlevel_tot} . ",";
      $rate = 0;
      $rate = $evhist_ref->{ptlevel_tot} / $evhist_ref->{ptexit_ct} if $evhist_ref->{ptexit_ct} > 0;
      my $ppc = sprintf '%.2f', $rate;
      $outl .= $ppc . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
   }
}


my $nodest_size = scalar keys %nodestx;
if ($nodest_size > 0) {
   $rptkey = "TEMSREPORT046";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: PostEvent Node Status Instance Exceptions\n";
   $cnt++;$oline[$cnt]="Node,Count,Thrunode,Hostaddr,Product,Version,\n";
   foreach $f ( sort { $nodestx{$b}->{count} <=> $nodestx{$a}->{count} } keys %nodestx) {
      my $nodest_ref = $nodestx{$f};
      last if $nodest_ref->{count} == 1;
      if ($nodest_ref->{count} == 2) { # do not report on simple case if agent switching
         if (($nodest_ref->{status}{"Y"} == 1) and ($nodest_ref->{status}{"N"} == 1)) {
            next;
         }
      }
      $advi++;$advonline[$advi] = "Agent sending status from $nodest_ref->{count} instances - see following report $rptkey";
      $advcode[$advi] = "TEMSAUDIT1082E";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "$f";
      foreach $g (keys %{$nodest_ref->{instances}}) {
         my $instance_ref = $nodest_ref->{instances}{$g};
         $outl = $f  . ",";
         $outl .= $nodest_ref->{count} . ",";
         $outl .= $instance_ref->{thrunode} . ",";
         $outl .= $instance_ref->{hostaddr} . ",";
         $outl .= $instance_ref->{product} . ",";
         $outl .= $instance_ref->{version} . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
   }
}

my $agto_dur = $agto_etime - $agto_stime;
if ($agto_mult > 0) {
   $rptkey = "TEMSREPORT011";$advrptx{$rptkey} = 1;         # record report key
   $advi++;$advonline[$advi] = "$agto_mult Agents with repeated onlines - See Report $rptkey";
   $advcode[$advi] = "TEMSAUDIT1016W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Onlines";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Multiple Agent online Report - top 20 max\n";
   $cnt++;$oline[$cnt]="Node,Online_Count,Offline_Count\n";
   my $top_online = 20;
   my $top_current = 0;
   foreach $f ( sort { $agto_ct[$agtox{$b}] <=> $agto_ct[$agtox{$a}] } keys %agtox) {
      my $ai = $agtox{$f};
      $top_current += 1;
      last if $top_current > $top_online;
      last if $agto_ct[$ai] == 1;
      $outl = $f . ",";
      $outl .= $agto_ct[$ai] . ",";
      $outl .= $agto_fct[$ai] . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $agto_mult_hr += 1;
   }
   $cnt++;$oline[$cnt]="$agto_dur,$agto_mult_hr,\n";
}

my $invi = keys %valvx;
if ($invi > 0) {
   $rptkey = "TEMSREPORT012";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Invalid Node Name Report\n";
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
   $rptkey = "TEMSREPORT013";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Reflex [Action] Command failures\n";
   $cnt++;$oline[$cnt]="Situation,Status,Count\n";
   foreach $f (sort {$a cmp $b} keys %reflexx) {
      $outl = $f . ",";
      $outl .= $reflexx{$f}->{status} . ",";
      $outl .= $reflexx{$f}->{count} . ",";
      $cnt++;$oline[$cnt]=$outl . "\n";
      $refx_ct += $reflexx{$f}->{count};
   }
   $advi++;$advonline[$advi] = "Reflex [Action] Command $refx_ct failures in $refxi situation(s) - See Report $rptkey";
   $advcode[$advi] = "TEMSAUDIT1034W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "CommandFailures";
}

my $agtsh_dur = $agtsh_etime - $agtsh_stime;
if (($agtsh_dur > 0) and ($opt_jitter == 1)) {
   $rptkey = "TEMSREPORT014";$advrptx{$rptkey} = 1;         # record report key
   my $agtsh_total_multi = 0;
   my $agtsh_jitter_major = 0;
   my $agtsh_jitter_minor = 0;
   my %multi_agent = ();
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Fast Simple Heartbeat report\n";
   $cnt++;$oline[$cnt]="Node,Count,RatePerHour,NonModeCount,NonModeSum,InterArrivalTimes\n";
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
   $advi++;$advonline[$advi] = "Simple agent Heartbeat total[$agtshi] multi_agent[$agtsh_total_multi] jitter_major[$agtsh_jitter_major] jitter_minor[$agtsh_jitter_minor]" - see Report $rptkey;
   $advcode[$advi] = "TEMSAUDIT1020W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "Sum Jitter";

   # If major jitters, correlate large jitter events over time

   if ($agtsh_jitter_major > 0) {
      $rptkey = "TEMSREPORT015";$advrptx{$rptkey} = 1;         # record report key
      my %jitter_correlate;
      my $ptime;
      for (my $i=0;$i<60;$i++) {
         $ptime = substr("00" . $i,-2,2);
         $jitter_correlate{$ptime}{count} = 0;
      }
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
      $cnt++;$oline[$cnt]="$rptkey: Major Jitter Report\n";
      $cnt++;$oline[$cnt]="Minute,Nodes\n";
      foreach $f (sort {$a <=> $b} keys %jitter_correlate) {
         next if $jitter_correlate{$f}{count} == 0;
         foreach $g (@{$jitter_correlate{$f}{nodes}}) {
            $outl = $f . ",";
            $outl .= $g;
            $cnt++;$oline[$cnt]=$outl . "\n";
         }
      }
   }
}

my $inodex_ct = scalar keys %inodex;
my $inodea_ct = 0;
if ($inodex_ct > 0) {
   $rptkey = "TEMSREPORT016";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Send Node Status Exception Report\n";
   $cnt++;$oline[$cnt]="Node,Count,Hostaddr,Thrunode,Product,Version\n";
   my $agent_ct = 0;
   foreach $f ( sort { $a cmp $b } keys %inodex) {
      my $inode_ref = $inodex{$f};
      next if $inode_ref->{count} == 1;
      $agent_ct += 1;
      my $tnodea_ct = scalar keys %{$inode_ref->{aff}};
      $inodea_ct += 1 if $tnodea_ct > 1;
      foreach $g (keys %{$inode_ref->{instances}}) {
         my $inodei_ref = $inode_ref->{instances}{$g};
         $outl = $f . ",";                 # node
         $outl .= $inodei_ref->{count} . ",";
         $outl .= $inodei_ref->{hostaddr} . ",";
         $outl .= $inodei_ref->{thrunode} . ",";
         $outl .= $inodei_ref->{product} . ",";
         $outl .= $inodei_ref->{version} . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
   }
   if ($agent_ct > 0) {
      $advi++;$advonline[$advi] = "Node [$agent_ct] have multiple sendstatus observed - see $rptkey Report";
      $advcode[$advi] = "TEMSAUDIT1033W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "duplicate";
   }
}

if ($inodea_ct > 0) {
   $rptkey = "TEMSREPORT017";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Send Node Status Affinity Exception Report\n";
   $cnt++;$oline[$cnt]="Node,Count,Hostaddr,Thrunode,Product,Version\n";
   foreach $f ( sort { $a cmp $b } keys %inodex) {
      my $inode_ref = $inodex{$f};
      next if $inode_ref->{count} == 1;
      my $tnodea_ct = scalar keys %{$inode_ref->{aff}};
      next if $tnodea_ct <= 1;
      foreach $g (keys %{$inode_ref->{aff}}) {
         my $inodea_ref = $inode_ref->{aff}{$g};
         $outl = $f . ",";                 # node
         $outl .= $inodea_ref->{count} . ",";
         $outl .= $inodea_ref->{product} . ",";
         $outl .= $inodea_ref->{affinities} . ",";
         $outl .= $inodea_ref->{hostaddr} . ",";
         $outl .= $inodea_ref->{thrunode} . ",";
         $outl .= $inodea_ref->{version} . ",";
         $outl .= $inodea_ref->{reserved} . ",";
         $cnt++;$oline[$cnt]=$outl . "\n";
      }
      $advi++;$advonline[$advi] = "Agents [$inodea_ct] have multiple affinities - possible duplicate agent - see $rptkey Report";
      $advcode[$advi] = "TEMSAUDIT1079W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "duplicate";
   }
}

my $timex_ct = scalar keys %timex;
if ($timex_ct > 0) {
   $rptkey = "TEMSREPORT018";$advrptx{$rptkey} = 1;         # record report key
   $advi++;$advonline[$advi] = "$timex_ct Agent time out messages - see $rptkey Report";
   $advcode[$advi] = "TEMSAUDIT1021W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "timeout";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Agent Timeout Report\n";
   $cnt++;$oline[$cnt]="Table,Situation,Count\n";
   foreach $f ( sort { $timex{$b}->{count} <=> $timex{$a}->{count} } keys %timex) {
      my $ptable = $f;
      foreach $g ( sort { $a cmp $b } keys %{$timex{$ptable}->{sit}} ) {
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
   $rptkey = "TEMSREPORT019";$advrptx{$rptkey} = 1;         # record report key
   $advi++;$advonline[$advi] = "Remote Procedure Connection lost $comme_ct - see $rptkey Report";
   $advcode[$advi] = "TEMSAUDIT1039W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "RPCFail";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: RPC Error report\n";
   $cnt++;$oline[$cnt]="Error,Target,Count\n";
   foreach $f ( sort { $commex{$b}->{count} <=> $commex{$a}->{count} } keys %commex) {
      my $perror = $f;
      foreach $g ( sort { $a cmp $b } keys %{$commex{$f}->{targets}} ) {
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
   $rptkey = "TEMSREPORT020";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Historical Export summary by time\n";
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
   $rptkey = "TEMSREPORT021";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Historical Export summary by object\n";
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
   $rptkey = "TEMSREPORT022";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Historical Export summary by Object and time\n";
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
   $rptkey = "TEMSREPORT023";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Time Slot Result workload\n";
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
   $rptkey = "TEMSREPORT024";$advrptx{$rptkey} = 1;         # record report key
   $advi++;$advonline[$advi] = "$atrwx_ct Attribute file warning messages - see $rptkey Report";
   $advcode[$advi] = "TEMSAUDIT1030W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "attribute";
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Attribute File Warning Report\n";
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
   $rptkey = "TEMSREPORT025";$advrptx{$rptkey} = 1;         # record report key
   my $loci_worry = 0;
   my $worry_ct = int(($loci_ct*$opt_nominal_loci)/100);
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Loci Count Report - $loci_ct found\n";
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
      $advi++;$advonline[$advi] = "$loci_worry worrying diagnostic messages - see $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1035W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "diagnostic";
   }
}


if ($pcb_deletePCB > 0) {
   $rptkey = "TEMSREPORT026";$advrptx{$rptkey} = 1;         # record report key
   my $pcb_deletePCB_ct =0;
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Agent connection churning Report - top 95% systems\n";
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
      $pcb_deletePCB_ct += $pcb_ref->{deletePCB};
      if ($pcb_deletePCB_tot > 100) {
         if ($opt_churnall == 0) {
            last if $pcb_deletePCB_ct >= $pcb_deletePCB90;
         }
      }
   }
}

$soaperror_ct = scalar keys %soaperror;
if ($soaperror_ct > 0) {
   $rptkey = "TEMSREPORT027";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: SOAP Error Report\n";
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

my $soapdet_ct = scalar keys %soapdetx;
if ($soapdet_ct > 0) {
   $rptkey = "TEMSREPORT049";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: SOAP Detail Report\n";
   $cnt++;$oline[$cnt]="Local_Time,Duration,IP,Diagnostic_Line_Number,\n";
   $cnt++;$oline[$cnt]=",SOAP_Message_Summary,\n";
   $cnt++;$oline[$cnt]=",First_Row_Result,\n";
   foreach $f ( sort { $a <=> $b } keys %soapdetx) {
      $soaprun_def =  $soapdetx{$f};
      my $ltime = sec2ltime($soaprun_def->{start}+$local_diff);
      $outl = $ltime . ",";
      my $dur = $soaprun_def->{end} - $soaprun_def->{start};
      $outl .= $dur . "," . $soaprun_def->{ip} . "," . $f . ",";
      $cnt++;$oline[$cnt]="$outl\n";
      my $pmsg = '';
      foreach $g (@{$soaprun_def->{msg}}) {
         foreach $h (keys %{$g} ) {
            $pmsg .= $h . "=" . $g->{$h} . ";"
         }
      }
      $outl = "," . $pmsg . ",";
      $cnt++;$oline[$cnt]="$outl\n";
      $outl = "," . $soaprun_def->{fetch};
      $cnt++;$oline[$cnt]="$outl\n";
   }
}

my $pti_ct = scalar keys %ptix;
if ($pti_ct > 0) {
   $rptkey = "TEMSREPORT050";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: TNODESTS Insert Error Summary Report\n";
   $cnt++;$oline[$cnt]="IP_Addr,Count,\n";
   foreach $f ( sort { $a cmp $b } keys %ptix) {
      $pti_ref = $ptix{$f};
      my $pmsg;
      foreach $g ( sort { $a <=> $b } keys %{$pti_ref->{codes}}) {
         $pmsg .= $g . "[" . $pti_ref->{codes}{$g} . "] ";
      }
      $outl = "$f" . "," . $pmsg . ",";
      $cnt++;$oline[$cnt]="$outl\n";
   }
   my $pti_dur = $pti_etime - $pti_stime;
   $outl = $pti_dur . " seconds";
   $cnt++;$oline[$cnt]="$outl\n";
}

if ($change_real > 0) {
   $rptkey = "TEMSREPORT028";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Agent Flipping Report\n";
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
   $rptkey = "TEMSREPORT029";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Situation Length 32 Report\n";
   $cnt++;$oline[$cnt]="Count,Sitname,,\n";
   foreach $f ( sort { $a cmp $b } keys %sit32x) {
      $outl = $sit32x{$f} . ",";
      $outl .= $f . ",";
      $cnt++;$oline[$cnt]="$outl\n";
   }
}

my $ct_rbdup = 0;
my $ct_rbdup_thruchg = 0;
my $ct_rbdup_simpleneg = 0;
my $ct_rbdup_dupflag = 0;
my $ct_rbdup_hostaddr = 0;
my $ct_rbdup_system = 0;
my $ct_rbdup_system_ports = 0;
my $ct_rbdup_newonline1 = 0;

foreach $f ( sort { $a cmp $b } keys %rbdupx) {
   $rbdup_ref = $rbdupx{$f};
   $ct_rbdup += 1 if $rbdup_ref->{thruchg} > 1;
   $ct_rbdup_thruchg += 1 if $rbdup_ref->{thruchg} > 1;
   $ct_rbdup += 1 if $rbdup_ref->{simpleneg} > 0;
   $ct_rbdup_simpleneg += 1 if $rbdup_ref->{simpleneg} > 0;
   $ct_rbdup += 1 if $rbdup_ref->{dupflag} > 1;
   $ct_rbdup_dupflag += 1 if $rbdup_ref->{dupflag} > 1;
   $rbdup_ref->{hostaddr} = scalar keys %{$rbdup_ref->{hostaddrs}};
   $ct_rbdup += 1 if $rbdup_ref->{hostaddr} > 1;
   $ct_rbdup_hostaddr += 1 if $rbdup_ref->{hostaddr} > 1;
   $rbdup_ref->{system} = scalar keys %{$rbdup_ref->{systems}};
   $ct_rbdup += 1 if $rbdup_ref->{system} > 1;
   $ct_rbdup_system += 1 if $rbdup_ref->{system} > 1;
   $ct_rbdup += 1 if $rbdup_ref->{newonline1} > 1;
   $ct_rbdup_newonline1 += 1 if $rbdup_ref->{newonline1} > 1;
}


foreach $f ( sort { $a cmp $b } keys %rbdupx) {
   $rbdup_ref = $rbdupx{$f};
   foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{systems}}) {
      my $system_ref = $rbdup_ref->{systems}{$g};
      my $port_ct = scalar keys %{$system_ref->{ports}};
      $ct_rbdup_system_ports += 1 if $port_ct > 1;
      $ct_rbdup += 1 if $port_ct > 1;
   }
}

# The following logic inverts the receive vector data to use in reports
my $eph_ct = scalar keys %recvectx;
my $eph_ports_ct = 0;
if ($eph_ct > 0) {
   foreach $f ( sort { $a cmp $b } keys %recvectx) {
      my $recvect_def = $recvectx{$f};
      my $ipipeaddr = $recvect_def->{pipe_addr};
      my $ifixup = $recvect_def->{fixup};
      my $iphysself = $recvect_def->{phys_self};
      my $iphyspeer = $recvect_def->{phys_peer};
      my $ivirtself = $recvect_def->{virt_self};
      my $ivirtpeer = $recvect_def->{virt_peer};
      my $iephemeral = $recvect_def->{ephemeral};
      my $ithrunode =   $recvect_def->{thrunode};
      my $iservice_point =   $recvect_def->{service_point};
      my $iservice_type =   $recvect_def->{service_type};
      my $idriver =   $recvect_def->{driver};
      my $ibuild_date =   $recvect_def->{build_date};
      my $ibuild_target =   $recvect_def->{build_target};
      my $iprocess_time =   $recvect_def->{process_time};
      $iphyspeer =~ /(.*)\:(.*)/;
      my $isystem = $1;
      my $iport = $2;
      my $phys_ref = $physicalx{$isystem};
      if (!defined $phys_ref) {
         my %physref = (
                          count => 0,
                          pipes => {},
                          thrunode => $ithrunode,
                          service_point => $iservice_point,
                          service_type => $iservice_type,
                          driver => $idriver,
                          build_date => $ibuild_date,
                          build_target => $ibuild_target,
                          process_time => $iprocess_time,
                          ports => {},
                       );
         $phys_ref = \%physref;
         $physicalx{$isystem} = \%physref;
      }
      $phys_ref->{count} += 1;
      $phys_ref->{ports}{$iport} = 1;
      $eph_ports_ct += 1;
      $pipex{$ipipeaddr} = $iphyspeer;
      my $pipe_ref = $phys_ref->{pipes}{$ipipeaddr};
      if (!defined $pipe_ref) {
         my %piperef = (
                          count => 0,
                          instances => {},
                       );
         $pipe_ref = \%piperef;
         $phys_ref->{pipes}{$ipipeaddr} = \%piperef;
      }
      $pipe_ref->{count} += 1;

      my $ephemkey =  "";
      $ephemkey .= "ephemeral" if $iephemeral & 16;    # define KDEBP_EPH_OPTION           ((unsigned int)0x10)
      $ephemkey .= "|" . "peerxlate" if $iephemeral & 2;    # define KDEBP_EPH_PEERXLATE        ((unsigned int)0x2)
      $ephemkey .= "|" . "selfxlate" if $iephemeral & 1;     # define KDEBP_EPH_SELFXLATE        ((unsigned int)0x1)
                                                         # define KDEBP_EPH_PORTXLATE        ((unsigned int)0x4)
                                                         # define KDEBP_EPH_PORTNUMBER       ((unsigned int)0x8)
      my $ephem_ref = $pipe_ref->{instances}{$ephemkey};
      if (!defined $ephem_ref) {
         my %ephemref = (
                          count => 0,
                          gate => "",
                       );
         $ephem_ref = \%ephemref;
         $pipe_ref->{instances}{$ephemkey} = \%ephemref;
      }
      $ephem_ref->{count} += 1;
      $ephem_ref->{gate} = $ivirtpeer if $iephemeral & 2;
   }
}

my $phys_ct = 0;

if ($ct_rbdup > 0 ) {
   if ($eph_ct > 0) {
      foreach $f (keys %rbdupx) {
         $rbdup_ref = $rbdupx{$f};
         foreach $g (keys %{$rbdup_ref->{hostaddrs}}) {
            my $physid = "";
            my $path = "";
            my $thrunode = "";
            ($physid,$path,$thrunode) = getphys($g);
            $physid =~ /(.*)\:(.*)/;
            my $isystem = $1;
            my $iport = $2;
            my $phys_ref = $physicalx{$isystem};
            if (!defined $phys_ref) {
               my %physref = (
                                count => 0,
                                pipes => {},
                                thrunode => $ithrunode,
                                ports => {},
                             );
               $phys_ref = \%physref;
               $physicalx{$isystem} = \%physref;
            }
            $phys_ref->{count} += 1;
            $phys_ref->{ports}{$iport} = 1;
         }
      }
   }


   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="RB Node Status Unusual Behavior Reports\n";
   if ($ct_rbdup_dupflag > 0) {
      $rptkey = "TEMSREPORT030";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB Duplicate Node Evidence Report\n";
      $cnt++;$oline[$cnt]="Node,HostAddr,Interval,Dup_count,Reason(s),\n";
      foreach $f ( sort { $rbdupx{$b}->{dupflag} <=> $rbdupx{$a}->{dupflag}
                          || $a cmp $b } keys %rbdupx) {
         $rbdup_ref = $rbdupx{$f};
         last if $rbdup_ref->{dupflag} < 2;
         my $hostaddr1 = "";   # calculate a hostaddr - system where the agent self reports
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{hostaddrs}}) {
            $hostaddr1 = $g;
            last;
         }
         my $rstring = "";
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{duplicate_reasons}}) {
            $rstring .= $g . "(" . $rbdup_ref->{duplicate_reasons}{$g} . ") ";
         }
         $cnt++;$oline[$cnt]= $f . "," . $hostaddr1 . "," . $rbdup_ref->{interval} . "," . $rbdup_ref->{dupflag} . "," . $rstring . ",\n";
         my $dstring = "";
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{duplicate_reasons}}) {
            $cnt++;$oline[$cnt]= $f . "," . $hostaddr1 . "," . $rbdup_ref->{interval} . ",," . $g . "," . join(":",@{$rbdup_ref->{$g}}) . ",\n";
            if (($g eq "leftover_seconds" ) or ($g eq "heartbeat_outside_grace") or ($g eq "early_heartbeat")) {
               my %fcount = ();
               while (1) {
                 my $isecs = shift @{$rbdup_ref->{$g}};
                 shift @{$rbdup_ref->{$g}};
                 last if !defined $isecs;
                 $fcount{$isecs} += 1;
               }
               my $istring = "";
               foreach $h  ( sort { $a <=> $b } keys %fcount) {
                  $istring .= $h . "(" . $fcount{$h} . ") ";
               }
               $cnt++;$oline[$cnt]= $f . "," . $hostaddr1 . "," . $rbdup_ref->{interval} . ",frequencies," . $istring . ",\n";
            }
         }
      }
      $advi++;$advonline[$advi] = "Duplicate Agent Evidence in $ct_rbdup_dupflag agents - See $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1068W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
   if ($ct_rbdup_thruchg > 0) {
      $rptkey = "TEMSREPORT031";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB Thrunode Change Report\n";
      $cnt++;$oline[$cnt]="Node,HostAddr,Thrunode_count,Thrunode(s),\n";
      my $max_thruchg = 0;
      foreach $f ( sort { $rbdupx{$b}->{thruchg} <=> $rbdupx{$a}->{thruchg}
                          || $a cmp $b } keys %rbdupx) {
         $rbdup_ref = $rbdupx{$f};
         last if $rbdup_ref->{thruchg} <= 1;
         $max_thruchg = $rbdup_ref->{thruchg} if $max_thruchg == 0;
         my $hostaddr1 = "";   # calculate a hostaddr - system where the agent self reports
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{hostaddrs}}) {
            $hostaddr1 = $g;
            last;
         }
         my $tstring = "";
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{thrunodes}}) {
            $tstring .= $g . "(" . $rbdup_ref->{thrunodes}{$g} . ") ";
         }
         $cnt++;$oline[$cnt]= $f . "," . $hostaddr1 . "," . $rbdup_ref->{thruchg} . "," . $tstring . ",\n";
      }
      $advi++;$advonline[$advi] = "Agent Thrunode Changing Evidence in $ct_rbdup_thruchg agents max[$max_thruchg] - See $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1069W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
   if ($ct_rbdup_system > 0) {
      $rptkey = "TEMSREPORT032";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB Multiple System Report\n";
      $cnt++;$oline[$cnt]="Node,System_count,System(s),\n";
      my $max_system = 0;
      foreach $f ( sort { $rbdupx{$b}->{system} <=> $rbdupx{$a}->{system}
                          || $a cmp $b } keys %rbdupx) {

         $rbdup_ref = $rbdupx{$f};
         last if $rbdupx{$f}->{system} < 2;
         $max_system = $rbdup_ref->{system} if $max_system == 0;
         my $hstring = "";
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{systems}}) {
            $hstring .= $g . " ";
         }
         $cnt++;$oline[$cnt]= $f . "," . $hstring . ",\n";
      }
      $advi++;$advonline[$advi] = "Agent Multiple System Evidence in $ct_rbdup_system agents max[$max_system] - See $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1073W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
   if ($ct_rbdup_system_ports > 0) {
      $rptkey = "TEMSREPORT033";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB System Multiple Listening Ports Report\n";
      $cnt++;$oline[$cnt]="Node,PipeAddr,Count,Ports,\n";
      my $agent_ct = 0;
      foreach $f ( sort { $rbdupx{$b}->{system} <=> $rbdupx{$a}->{system}
                          || $a cmp $b } keys %rbdupx) {
         my $rbdup_ref = $rbdupx{$f};
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{systems}}) {
            my $system_ref = $rbdup_ref->{systems}{$g};
            my $port_ct = scalar keys %{$system_ref->{ports}};
            next if $port_ct <= 1;
            my @pastring = keys %{$system_ref->{ports}};
            my $pstring = join(" ",@pastring);
            $cnt++;$oline[$cnt]= $f . "," . $g . "," . $port_ct . "," . $pstring . ",\n";
            $agent_ct += 1;
         }
      }
      if ($agent_ct > 0) {
         $advi++;$advonline[$advi] = "Agent System [$agent_ct] with with Multiple Listening ports - See $rptkey report";
         $advcode[$advi] = "TEMSAUDIT1076W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "duplicate";
      }
   }
   if ($eph_ports_ct > 0) {
      $rptkey = "TEMSREPORT034";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB System Multiple Listening Ports on Physical Systems Report\n";
      $cnt++;$oline[$cnt]="Node,PipeAddr,Count,Ports,\n";
      my $agent_ct = 0;
      foreach $f ( sort { $a cmp $b } keys %physicalx) {
         my $physical_ref = $physicalx{$f};
         my $port_ct = scalar keys %{$physical_ref->{ports}};
         next if $port_ct <= 1;
         my @pastring = keys %{$physical_ref->{ports}};
         my $pstring = join(" ",@pastring);
         $cnt++;$oline[$cnt]= $f . "," . $physical_ref->{thrunode} . "," . $port_ct . "," . $pstring . ",\n";
         $agent_ct += 1;
      }
      if ($agent_ct > 0) {
         $advi++;$advonline[$advi] = "Systems [$agent_ct] with with Multiple Listening ports - See $rptkey report";
         $advcode[$advi] = "TEMSAUDIT1077W";
         $advimpact[$advi] = $advcx{$advcode[$advi]};
         $advsit[$advi] = "duplicate";
      }
   }
   if ($ct_rbdup_hostaddr > 0) {
      $rptkey = "TEMSREPORT035";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB Multiple Hostaddr Report\n";
      $cnt++;$oline[$cnt]="Node,HostAddr_count,HostAddr(s),\n";
      my $max_hostaddr = 0;
      foreach $f ( sort { $rbdupx{$b}->{hostaddr} <=> $rbdupx{$a}->{hostaddr}
                          || $a cmp $b } keys %rbdupx) {

         $rbdup_ref = $rbdupx{$f};
         last if $rbdupx{$f}->{hostaddr} < 2;
         $max_hostaddr = $rbdup_ref->{hostaddr} if $max_hostaddr == 0;
         my $hstring = "";
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{hostaddrs}}) {
            my $physid = "";
            my $path = "";
            ($physid,$path) = getphys($g);
            $g .= '[' . $physid . ']' if $physid ne "";
            $hstring .= $g . " ";
         }
         $cnt++;$oline[$cnt]= $f . "," . $rbdupx{$f}->{hostaddr} . "," . $hstring . ",\n";
      }
      $advi++;$advonline[$advi] = "Agent Multiple Hostaddr Evidence in $ct_rbdup_hostaddr agents max[$max_hostaddr] - See $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1070W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
   if ($ct_rbdup_newonline1 > 0) {
      $rptkey = "TEMSREPORT036";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB Multiple Agent Initial Status Report\n";
      $cnt++;$oline[$cnt]="Node,HostAddr,InitialStatus_Count,\n";
      my $max_newonline1 = 0;
      foreach $f ( sort { $rbdupx{$b}->{newonline1} <=> $rbdupx{$a}->{newonline1}
                          ||   $a cmp $b } keys %rbdupx) {
         $rbdup_ref = $rbdupx{$f};
         last if $rbdup_ref->{newonline1} < 2;
         $max_newonline1 = $rbdup_ref->{newonline1} if $max_newonline1 == 0;
         my $hostaddr1 = "";
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{hostaddrs}}) {
            $hostaddr1 = $g;
            last;
         }
         $cnt++;$oline[$cnt]= $f . "," . $hostaddr1 . "," . $rbdup_ref->{newonline1} . ",\n";
      }
      $advi++;$advonline[$advi] = "Agent Multiple Initial Status Evidence in $ct_rbdup_newonline1 agents max[$max_newonline1] - See $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1071W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
   if ($ct_rbdup_simpleneg > 0) {
      $rptkey = "TEMSREPORT037";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: RB Negative Heartbeat Time Report\n";
      $cnt++;$oline[$cnt]="Node,Negative_interval(s),\n";
      foreach $f ( sort { $a cmp $b } keys %rbdupx) {
         $rbdup_ref = $rbdupx{$f};
         next if $rbdup_ref->{simpleneg} == 0;
         $cnt++;$oline[$cnt]= $f . "," . $rbdup_ref->{simpleneg} . ",\n";
      }
      $advi++;$advonline[$advi] = "Agent Negative Heartbeat Time Evidence in $ct_rbdup_simpleneg agents - See $rptkey report";
      $advcode[$advi] = "TEMSAUDIT1072W";
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TEMS";
   }
}

$phys_ct = scalar keys %rbdupx;
if ($phys_ct > 0) {
      $rptkey = "TEMSREPORT038";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: Pipeline Report\n";
      $cnt++;$oline[$cnt]="Node,Thrunode,Physical,Path,Pipeaddr,\n";
      foreach $f ( sort { $a cmp $b } keys %rbdupx) {
         $rbdup_ref = $rbdupx{$f};
         foreach $g ( sort { $a cmp $b } keys %{$rbdup_ref->{physicals}}) {
            my $phys_ref = $rbdup_ref->{physicals}{$g};
            next if $phys_ref->{path} eq "";
            $cnt++;$oline[$cnt]= $f  . "," . $phys_ref->{thrunode} . "," . $g . "," . $phys_ref->{path} . "," . $phys_ref->{hostaddr} . ",\n";
         }
      }
}

if ($eph_ct > 0) {
   $rptkey = "TEMSREPORT039";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Summary Receive Vector Report\n";
   $cnt++;$oline[$cnt]="temsnodeid,phys_addr,phys_count,pipe_addr,pipe_count,\n";
   foreach $f ( sort { $a cmp $b } keys %physicalx) {
      my $phys_ref = $physicalx{$f};
      foreach $g ( sort { $a cmp $b } keys %{$phys_ref->{pipes}}) {
         my $pipe_ref = $phys_ref->{pipes}{$g};
         $outl = $opt_nodeid . ",";
         $outl .= $f . ",";
         $outl .= $phys_ref->{count} . ",";
         $outl .= $pipe_ref->{count} . ",";
         $cnt++;$oline[$cnt]="$outl\n";
         last;
      }
   }
   $rptkey = "TEMSREPORT040";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Detail Receive Vector Report\n";
   $cnt++;$oline[$cnt]="temsnodeid,phys_addr,phys_count,pipe_addr,pipe_count,xlate,xlate_count,gateway,service_point,service_type,driver,build_date,build_target,process_time,\n";
   foreach $f ( sort { $a cmp $b } keys %physicalx) {
   my $phys_ref = $physicalx{$f};
      foreach $g ( sort { $a cmp $b } keys %{$phys_ref->{pipes}}) {
         my $pipe_ref = $phys_ref->{pipes}{$g};
         foreach $h ( sort { $a cmp $b } keys %{$pipe_ref->{instances}}) {
            my $ephem_ref = $pipe_ref->{instances}{$h};
            $outl = $opt_nodeid . ",";
            $outl .= $f . ",";
            $outl .= $phys_ref->{count} . ",";
            $outl .= $g . ",";
            $outl .= $pipe_ref->{count} . ",";
            $outl .= $h . ",";
            $outl .= $ephem_ref->{count} . ",";
            $outl .= $ephem_ref->{gate} . ",";
            $outl .= $phys_ref->{service_point} . ",";
            $outl .= $phys_ref->{service_type} . ",";
            $outl .= $phys_ref->{driver} . ",";
            $outl .= $phys_ref->{build_date} . ",";
            $outl .= $phys_ref->{build_target} . ",";
            $outl .= $phys_ref->{process_time} . ",";
            $cnt++;$oline[$cnt]="$outl\n";
         }
      }
   }
}


my $dnode_ct = scalar keys %dnodex;
if ($dnode_ct > 0) {
   $rptkey = "TEMSREPORT041";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: Node Validity Duplicate Node Report\n";
      $cnt++;$oline[$cnt]="Count,Node,Thrunode,Product,Thrunode_new,Product_new,\n";
      foreach $f ( sort { $dnodex{$b}->{count} <=>  $dnodex{$a}->{count} || $a cmp $b } keys %dnodex) {
         my $dnode_ref = $dnodex{$f};
         $outl = $dnode_ref->{count} . ",";
         $outl .= $dnode_ref->{node} . ",";
         $outl .= $dnode_ref->{thrunode} . ",";
         $outl .= $dnode_ref->{product} . ",";
         $outl .= $dnode_ref->{thrunode_new} . ",";
         $outl .= $dnode_ref->{product_new} . ",";
         $cnt++;$oline[$cnt]= "$outl\n";
      }
   $advi++;$advonline[$advi] = "KFA Node Validity detected $dnode_ct potential duplicate agent name cases - See $rptkey report";
   $advcode[$advi] = "TEMSAUDIT1078E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";

}

if ($nodeliste_count > 0) {
   $rptkey = "TEMSREPORT048";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Nodelist Error report - possible duplicate node indications\n";
   $cnt++;$oline[$cnt]="Agent,Count,Error,Op,Id,TEMS,\n";
   foreach $f ( sort { $nodelistex{$b}->{count} <=>  $nodelistex{$a}->{count} || $a cmp $b } keys %nodelistex) {
      my $nodeliste_ref = $nodelistex{$f};
#     next if $nodeliste_ref->{count} == 1;
      $outl = $f . ",";
      $outl .= $nodeliste_ref->{count} . ",";
      foreach $g (keys %{$nodeliste_ref->{error}}) {
         $outl .= $g . "(" . $nodeliste_ref->{error}{$g} . ") ";
      }
      $outl .= ",";
      foreach $g (keys %{$nodeliste_ref->{op}}) {
        $outl .= $g . "(" . $nodeliste_ref->{op}{$g} . ") ";
      }
      $outl .= ",";
      foreach $g (keys %{$nodeliste_ref->{id}}) {
         $outl .= $g . "(" . $nodeliste_ref->{id}{$g} . ") ";
      }
      $outl .= ",";
      foreach $g (keys %{$nodeliste_ref->{tems}}) {
         $outl .= $g . "(" . $nodeliste_ref->{tems}{$g} . ") ";
      }
      $outl .= ",";
      $cnt++;$oline[$cnt]="$outl\n";
   }
   $advi++;$advonline[$advi] = "Nodelist Errors [$nodeliste_count] potential duplicate agent name cases - See $rptkey report";
   $advcode[$advi] = "TEMSAUDIT1085W";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";

}

# new report of last N lines of the itm_config.log and itm_install.log - record of recent start/stops/config operations

if ($opt_last == 1) {
   my $config_itm_log = $opt_logpath . "itm_config.log";
   my $logsize = -s $config_itm_log;
   my $displ;
   my $logdata;
   my $lc;
   if (defined $logsize) {
      $rptkey = "TEMSREPORT043";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: ITM Config and Install last few lines\n";
      $cnt++;$oline[$cnt]="itm_config.log\n";

      $displ = 0;
      $displ = $logsize - 1000 if $logsize > 1000;
      $logdata = "";
      open(FILE,$config_itm_log);
      seek(FILE,$displ,0);
      read(FILE,$logdata,1000);
      close(FILE);
      $lc = -1;
      while($logdata=~/([^\n]+)\n?/g){
        $lc += 1;
        next if $lc < 1;
        $cnt++;$oline[$cnt]="$1\n";
      }
      $cnt++;$oline[$cnt]="\n";
   }
   my $install_itm_log = $opt_logpath . "itm_install.log";
   $logsize = -s $install_itm_log;
   if (defined $logsize) {
      $cnt++;$oline[$cnt]="itm_install.log\n";
      $displ = 0;
      $displ = $logsize - 1000 if $logsize > 1000;
      $logdata = "";
      open(FILE,$install_itm_log);
      seek(FILE,$displ,0);
      read(FILE,$logdata,1000);
      close(FILE);
      $lc = -1;
      while($logdata=~/([^\n]+)\n?/g){
        $lc += 1;
        next if $lc < 1;
        $cnt++;$oline[$cnt]="$1\n";
      }
   }
}

# new report of netstat.info if it can be located

my $netstatpath;
my $netstatfn;
my $gotnet = 0;
$netstatpath = $opt_logpath;
if ( -e $netstatpath . "netstat.info") {
   $gotnet = 1;
   $netstatpath = $opt_logpath;
} elsif ( -e $netstatpath . "../netstat.info") {
   $gotnet = 1;
   $netstatpath = $opt_logpath . "../";
} elsif ( -e $netstatpath . "../../netstat.info") {
   $gotnet = 1;
   $netstatpath = $opt_logpath . "../../";
}

if ($gotnet == 1) {
   if ($gWin == 1) {
      $pwd = `cd`;
      chomp($pwd);
      $netstatpath = `cd $netstatpath & cd`;
   } else {
      $pwd = `pwd`;
      chomp($pwd);
      $netstatpath = `(cd $netstatpath && pwd)`;
   }

   chomp $netstatpath;

   $netstatfn = $netstatpath . "/netstat.info";
   $netstatfn =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

   chomp($netstatfn);
   chdir $pwd;

   my $active_line = "";
   my $descr_line = "";
   my @nzero_line;
   my %nzero_ports = (
                        '1918' => 1,
                        '3660' => 1,
                        '63358' => 1,
                        '65100' => 1,
                     );

   my %inbound;
   my $inbound_ref;

   #   open( FILE, "< $opt_ini" ) or die "Cannot open ini file $opt_ini : $!";
   if (defined $netstatfn) {
      open NETS,"< $netstatfn" or warn " open netstat.info file $netstatfn -  $!";
      my @nts = <NETS>;
      close NETS;

      # sample netstat outputs

      # Active Internet connections (including servers)
      # PCB/ADDR         Proto Recv-Q Send-Q  Local Address      Foreign Address    (state)
      # f1000e000ca7cbb8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e0000ac93b8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e00003303b8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e00005bcbb8 tcp        0      0  *.*                   *.*                   CLOSED
      # f1000e00005bdbb8 tcp4       0      0  *.*                   *.*                   CLOSED
      # f1000e00005b9bb8 tcp6       0      0  *.22                  *.*                   LISTEN
      # ...
      # Active UNIX domain sockets
      # Active Internet connections (servers and established)
      #
      # Active Internet connections (servers and established)
      # Proto Recv-Q Send-Q Local Address               Foreign Address             State       PID/Program name
      # tcp        0      0 0.0.0.0:1920                0.0.0.0:*                   LISTEN      18382/klzagent
      # tcp        0      0 0.0.0.0:34272               0.0.0.0:*                   LISTEN      18382/klzagent
      # tcp        0      0 0.0.0.0:28002               0.0.0.0:*                   LISTEN      5955/avagent.bin
      # ...
      # Active UNIX domain sockets (servers and established)

      my $l = 0;
      my $netstat_state = 0;                 # seaching for "Active Internet connections"
      my $recvq_pos = -1;
      my $sendq_pos = -1;
      foreach my $oneline (@nts) {
         $l++;
         chomp($oneline);
         if ($netstat_state == 0) {           # seaching for "Active Internet connections"
            next if substr($oneline,0,27) ne "Active Internet connections";
            $active_line = $oneline;
            $netstat_state = 1;
         } elsif ($netstat_state == 1) {           # next line is column descriptor line
            $recvq_pos = index($oneline,"Recv-Q");
            $sendq_pos = index($oneline,"Send-Q");
            $descr_line = $oneline;
            $netstat_state = 2;
         } elsif ($netstat_state == 2) {           # collect non-zero send/recv queues
            last if index($oneline,"Active UNIX domain sockets") != -1;
            $oneline =~ /(tcp\S*)\s*(\d+)\s*(\d+)\s*(\S+)\s*(\S+)/;
            my $proto = $1;
            if (defined $proto) {
               my $recvq = $2;
               my $sendq = $3;
               my $localad = $4;
               my $foreignad = $5;
               my $localport = "";
               my $foreignport = "";
               my $localsystem = "";
               my $foreignsystem = "";
               $localad =~ /(\S+):(\S+)/;
               $localsystem = $1 if defined $1;
               $localport = $2 if defined $2;
               $foreignad =~ /(\S+):(\S+)/;
               $foreignsystem = $1 if defined $1;
               $foreignport = $2 if defined $2;
               if ((defined $nzero_ports{$localport}) or (defined $nzero_ports{$foreignport})) {
                  if (defined $recvq) {
                     if (defined $sendq) {
                        if (($recvq > 0) or ($sendq > 0)) {
                           next if ($recvq == 0) and ($sendq == 0);
                           push @nzero_line,$oneline;
                           $total_sendq += 1;
                           $total_recvq += 1;
                           $max_sendq = $sendq if $sendq > $max_sendq;
                           $max_recvq = $recvq if $recvq > $max_recvq;
                        }
                     }
                  }
               }
               if (defined $nzero_ports{$localport}) {
                  $inbound_ref = $inbound{$localport};
                  if (!defined $inbound_ref) {
                     my %inboundref = (
                                         instances => {},
                                         count => 0,
                                      );
                     $inbound_ref = \%inboundref;
                     $inbound{$localport} = \%inboundref;
                  }
                  $inbound_ref->{count} += 1;
                  $inbound_ref->{instances}{$foreignsystem} += 1;
               }
            }
         }
      }
   }

   if (($total_sendq + $total_recvq) > 0) {
      $rptkey = "TEMSREPORT051";$advrptx{$rptkey} = 1;         # record report key
      $cnt++;$oline[$cnt]="\n";
      $cnt++;$oline[$cnt]="$rptkey: NETSTAT Send-Q and Recv-Q Report\n";
      $cnt++;$oline[$cnt]="netstat.info.log\n";
      $cnt++;$oline[$cnt]="$active_line\n";
      $cnt++;$oline[$cnt]="$descr_line\n";
      foreach my $line (@nzero_line) {
         $cnt++;$oline[$cnt]="$line\n";
      }
      $advi++;$advonline[$advi] = "TCP Queue Delays $total_sendq Send-Q [max $max_sendq] Recv-Q [max $max_recvq] - see Report $rptkey";
      if ($max_sendq > 1024) {
         $advcode[$advi] = "TEMSAUDIT1088W";
      } else {
         $advcode[$advi] = "TEMSAUDIT1087W";
      }
      $advimpact[$advi] = $advcx{$advcode[$advi]};
      $advsit[$advi] = "TCP";
   }


   # display count of inbound TCP sockets
   #$cnt++;$oline[$cnt]="\n";
   #foreach my $f (keys %inbound) {
   #   my $inbound_ref = $inbound{$f};
   #   foreach my $g (keys %{$inbound_ref->{instances}}) {
   #      $outl = $f . ",";
   #      $outl .= $g . ",";
   #      $outl .= $inbound_ref->{instances}{$g} . ",";
   #      $cnt++;$oline[$cnt]="$outl\n";
   #   }
   #}

}

my %iheartx;

if ($full_logopfn ne "") {
   my $ol = 0;
   if (open OPLOG,"< $full_logopfn") {
      my $opline;
      while (1) {
         $opline = <OPLOG>;
         last if !defined $opline;
         $ol += 1;
         next if length($opline) < 40;
         #Fri Dec 15 04:33:13 2017 KDS9143I   An initial heartbeat has been received from the TEMS REMOTE_usrdrtm041ccpr2 by the hub TEMS HUB_usrdhtms21ccpx2.
         my $opcode = substr($opline,25,8);
         if ($opcode eq "KDS9143I") {
            $opline =~ /has been received from the TEMS (\S+)/;
            my $irtems = $1;
            my $idate = substr($opline,0,24);
            my $iheart_ref = $iheartx{$irtems};
            if (!defined $iheart_ref) {
               my %iheartref = (
                                  count => 0,
                                  stamps => [],
                               );
               $iheart_ref = \%iheartref;
               $iheartx{$irtems} = \%iheartref;
            }
            $iheart_ref->{count} += 1;
            push @{$iheart_ref->{stamps}},$idate;
         }
      }
      close(OPLOG);
   }
}

my $prob_initial = 0;
foreach my $f (keys %iheartx) {
   my $iheart_ref = $iheartx{$f};
   next if $iheart_ref->{count} == 1;
   $prob_initial += 1;
   $advi++;$advonline[$advi] = "Excess Initial Heartbeats[$iheart_ref->{count}] from Remote TEMS $f - See TEMSREPORT054 report";
   $advcode[$advi] = "TEMSAUDIT1093E";
   $advimpact[$advi] = $advcx{$advcode[$advi]};
   $advsit[$advi] = "TEMS";
}

if ($prob_initial > 0) {
   $rptkey = "TEMSREPORT054";$advrptx{$rptkey} = 1;         # record report key
   $cnt++;$oline[$cnt]="\n";
   $cnt++;$oline[$cnt]="$rptkey: Excess Initial Heartbeat report\n";
   $cnt++;$oline[$cnt]="RemoteTems,Initial_count,Stamps\n";
   foreach my $f (keys %iheartx) {
      my $iheart_ref = $iheartx{$f};
      next if $iheart_ref->{count} == 1;
      $outl = $f . ",";
      $outl .= $iheart_ref->{count} . ",";
      $outl .= join("|",@{$iheart_ref->{stamps}}) . ",";
      $cnt++;$oline[$cnt]="$outl\n";
   }
}


$opt_o = $opt_odir . $opt_o if index($opt_o,'/') == -1;

open OH, ">$opt_o" or die "unable to open $opt_o: $!";


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
   foreach $f ( sort { $advimpact[$advx{$b}] <=> $advimpact[$advx{$a}] ||
                          $advcode[$advx{$a}] cmp $advcode[$advx{$b}] ||
                          $advsit[$advx{$a}] cmp $advsit[$advx{$b}] ||
                          $advonline[$advx{$a}] cmp $advonline[$advx{$b}]
                        } keys %advx ) {
      my $j = $advx{$f};
      next if $advimpact[$j] == -1;
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
   foreach $f ( sort { $a cmp $b } keys %advgotx ) {
      next if substr($f,0,9) ne "TEMSAUDIT";
      print OH "Advisory code: " . $f  . "\n";
      print OH "Impact:" . $advgotx{$f}  . "\n";
#     print STDERR "$f missing\n" if !defined $advtextx{$f};
      print OH $advtextx{$f};
   }
}

my $rpti = scalar keys %advrptx;
if ($rpti != -1) {
   print OH "\n";
   print OH "TEMS Audit Reports - Meaning and Recovery suggestions follow\n\n";
   foreach $f ( sort { $a cmp $b } keys %advrptx ) {
      next if !defined $advrptx{$f};
      print STDERR "$f missing\n" if !defined $advtextx{$f};
      print OH "$f\n";
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

if ($opt_eph == 1) {
   if ($eph_ct > 0) {
      my $opt_eph_fn = $opt_ephdir . $opt_nodeid . "_ephemeral_detail.txt";
      open EPH, ">$opt_eph_fn" or die "Unable to open Ephemeral Detail output file $opt_eph_fn\n";
      print EPH "temsnodeid,eph_addr,pipe_addr,fixup,phys_self,phys_peer,virt_self,virt_peer,ephemeral,service_point,service_type,driver,build_date,build_target,process_time\n";
      foreach $f ( sort { $a cmp $b } keys %recvectx) {
         my $recvect_def = $recvectx{$f};
         $outl = $recvect_def->{thrunode} . ",";
         $outl .= $f . ",";
         $outl .= $recvect_def->{pipe_addr} . ",";
         $outl .= $recvect_def->{fixup} . ",";
         $outl .= $recvect_def->{phys_self} . ",";
         $outl .= $recvect_def->{phys_peer} . ",";
         $outl .= $recvect_def->{virt_self} . ",";
         $outl .= $recvect_def->{virt_peer} . ",";
         $outl .= $recvect_def->{ephemeral} . ",";
         $outl .= $recvect_def->{service_point} . ",";
         $outl .= $recvect_def->{service_type} . ",";
         $outl .= $recvect_def->{driver} . ",";
         $outl .= $recvect_def->{build_date} . ",";
         $outl .= $recvect_def->{build_target} . ",";
         $outl .= $recvect_def->{process_time} . ",";
         print EPH "$outl\n";
      }
      close EPH;
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

close(STH) if $opt_sth == 1;
close(NDH) if $opt_sth == 1;

print STDERR "Wrote $cnt lines\n" if $opt_odir eq "";

# all done

$rc = 0;
$rc = 1 if $max_impact >= $opt_nominal_max_impact;

#print STDERR "exit code 1 $max_impact $opt_max_impact\n" if $rc == 1;

exit $rc;


# given an address like 10.180.211.21[3660] return a describing string that specifies the physical address and
# translation/ephemeral etc. The input is the ITM pipe_address.
sub getphys {
   my $ipipe = shift;
   my $iphys = "";
   my $ipath = "";
   my $ithrunode = "";
   $ipipe =~ /(.*?)\[(\d+)\]/;
   my $iaddr = $1;
   my $iport = $2;
   if (defined $iaddr) {
       if (defined $iport) {
         $iport -= 1;
         $iphys = $iaddr . ":" . $iport;
         my $tphys = $pipex{$iphys};
         if (defined $tphys) {
            $iphys = $tphys;
            my $phys_ref = $physicalx{$iphys};
            $ithrunode = $phys_ref->{thrunode};
            my $tcnt = scalar keys %{$phys_ref->{pipes}};
            foreach $g ( sort { $a cmp $b } keys %{$phys_ref->{pipes}}) {
               my $pipe_ref = $phys_ref->{pipes}{$g};
               foreach $h ( sort { $a cmp $b } keys %{$pipe_ref->{instances}}) {
                  my $ephem_ref = $pipe_ref->{instances}{$h};
                  $ipath .= "|" . $h;
                  $ipath .= "|" . $ephem_ref->{gate} if $ephem_ref->{gate} ne "";
               }
            }
         }
      }
   }
   return ($iphys,$ipath,$ithrunode);
}

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
   # Search for TEMS operations log

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

sub sec2ltime
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
   ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($itime);
   return sprintf "%4d%02d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec;
}

sub sec2slot
{
   my ($itime) = @_;
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($itime+$local_diff);
   my $slotmin = substr('00' . int($min/$opt_evslot)*$opt_evslot,-2,2);
   my $slothour = substr('00' . $hour,-2,2);
   my $slotday = substr('00' . $mday,-2,2);
   my $slotmonth = substr('00' . $mon+1,-2,2);
   my $slotyear = substr('00' . $year+1900,-4,4);

   return sprintf "$slotyear$slotmonth$slotday$slothour$slotmin" . "00";
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
#1.65000 - Add RB FindDupAgents.rex logic
#1.66000 - Report on churning based on 95% of total
#        - make jitter report(s) optional
#1.67000 - Extend some of the node status reports for easier access to diagnostic logs
#          and to allow some cases to be diagnosed immediately.
#1.68000 - More node status reports including base listening port usage
#1.69000 - Capture ephemeral port information - what is physical system/port
#1.70000 - Detect Seed file messages which mean duplicate index messages probably not important
#          Eliminate Bad Port report and add Multiple Listening port report
#          Add KFA Validity Node duplicate agent report
#          Revise GSKit error - handle all error codes
#1.71000 - Advisory on KDEB_INTERFACELIST and KDCB0_HOSTNAME
#        - Advisory on same agent name different affinity
#        - Added inline report explanations.
#1.72000 - handle RB capture better on earlier maintenance levels.
#          Add portscan report over time
#          Add report of recent install and config operations
#1.73000 - Advisory when KBB_RAS1 starts with a single quote
#1.74000 - test advisory 1067 logic
#1.75000 - Add FTO control message report
#        - Correct Local Time calculations
#        - Add PostEvent node status advisory and support
#1.76000 - Improve RB logic based on report ill-logical results
#        - Add Situation True advisory and report
#        - only product FTO Control message if there are any
#1.77000 - always true report/advisory only when result row tracing present
#1.78000 - Exclude (NULL) results from always true report
#        - Add advisory on STH corrupted rows
#1.79000 - Correct RB thrunode switching logic
#        - report number of off-lines along with onlines
#1.80000 - handle temsaud.pl running on a Linux/Unix perl
#1.81000 - Improve report explanation on churning report.
#        - Add advisory and report on nodelist missing messages
# 1.82   - github.com commit log for history

# Following is the embedded "DATA" file used to explain
# advisories and reports.
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
Text: KBB_RAS1 missing the all important ERROR specification

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
Text: GSKIT Secure Communications error code <code> [count] - <text>

Tracing: error
(59183B36.0000-53:kdebeal.c,81,"ssl_provider_open") GSKit error 402: GSK_ERROR_NO_CIPHERS - errno 11

Meaning: When secure communications is established using
GSKIT, some errors were seen. For example error code 402
GSK_ERROR_NO_CIPHERS is relating to inability to negotiate
a common cipher between the TEMS and the agent. In that
particular case, the TEMS had been upgraded and only
allowed TLS 1.2 connections and some of the agents were
not at a level that supported that connection protocol.

Recovery plan: Reconfigure the two ITM processes so they can
communicate.
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

TEMSAUDIT1068W
Text: Duplicate Agent Evidence in count agents - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of a duplicate
agent condition. This can lead to severe TEPS performance
problems and instability/outage of the hub and/or remote
TEMS.

Following are the categories

leftover_seconds: When estimating a node status update
rate, the value was not near any minute boundary.

heartbeat_outside_grace: Node Status arrived before or
after the expected time.

double_heartbeat: Two node status updates occurred rapidly.

double_offline: Two node offline condition occured rapidly.

early_heartbeat: A node status was seen before expected
based on the heartbeat rate.

Recovery plan:  Review the supplied report section to
determine and correct the issues. This can be agents
on different systems accidentally configured with the
same name. It can also be agents double installed on the
same system. It can be failed agent shutdown cases. The
possibilities seem endless.
----------------------------------------------------------------

TEMSAUDIT1069W
Text: Agent Thrunode Changing Evidence in count agents max[count] - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of a regular
connection via different remote TEMSes. It can also show
with managing agents and their sub-node agents. This can
mean accidental duplicate agents. In any event monitoring
is not running as expected.

Recovery plan:  Review the supplied report section to
determine and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1070W
Text: Agent Multiple Hostaddr Evidence in count agents max[count] - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of sending
in an different ip_addr[port] at different times. This
can mean accidental duplicate agents. It can also mean
mis-configuration of multiple agents on the affected
system.

Recovery plan:  Review the supplied report section to
determine and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1071W
Text: Agent Multiple Initial Status Evidence in count agents max[count] - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of sending
an initial connection status multiple times. This usually
means mis-configuration of multiple agents on the affected
system.

Recovery plan:  Review the supplied report section to
determine and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1072W
Text: Agent Negative Heartbeat Time Evidence in count agents - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of intervals
calculated as negative time. This usually means the
diagnostic logs got wrapped around and issue has no
practical effect.

Recovery plan:  If this occurs a lot, please contact
IBM Support to diagnose the issue.
----------------------------------------------------------------

TEMSAUDIT1073W
Text: Agent Multiple System Evidence in count agents max[count] - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of sending
in from a different system [ip_addr] at different times.
This usually means accidental duplicate agents. It can
also mean mis-configuration of multiple agents on the
affected system.

Recovery plan:  Review the supplied report section to
determine and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1074W
Text: Agent Unusual Base Port Evidence in $badbase_agents agents - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: Some agents are showing evidence of registering
listen ports with unusual numbers. The usual port numbers
are 1918 and 3660 although they sometimes show as 1919
and 3661 for technical reasons. The usual listening ports
are base+N*4096 [N=1-15]. If there are none available
then the tcp subsystem is asked for whatever ports are
available.

Usage of non-standard ports may be a signal that the
agent is recycling abnormally. When port usage is ended
TCP normal function places it into a 120 second FIN-WAIT
status. That is to allow processing or late, duplicated or
fragmented packets. Rapid agent recycling could be an
explanation.

When you get a lot of unusual listening ports, it
can also mean the agents running on that system are
mal-configured and are stepping on each others
connections. This can lead to severe issues at the
hub or remote TEMSes including instability.

This area is in active investigation. If you want
to help with this IBM Support would want pdcollects
of a sample of such agent systems,

Recovery plan:  Review the supplied report section to
determine and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1075I
Text: Seed file messages seen count times

Tracing: error
(59622462.0002-1C0C:kdseed.c,1275,"RunSeeder") Seed file <kyn_upg.sql>, Line <12360> not seeded: record not found.

Meaning: The presence of seed file messages means that
any duplicate database index errors are probably normal.
It just means that some TEMS database objects were
inserted even though they were already present. In that
case the database error messages can be ignored.

Recovery plan:  Ignore database duplicate index messages when
seeding is happeening.
----------------------------------------------------------------

TEMSAUDIT1076W
Text: Agent System [system] with with Multiple Listening ports $port_ct - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: A perfectly running agent will have a single
listening port. If many are seen, that usually means
the agent is having problems connecting with the TEMS.
In that case each connection attempt uses a different
listening port.

This is also seen when an agent is connfigure to two
TEMSes [best practice] and the primary TEMS [first listed]
connection fails, agent switches to secondary TEMS. After
75 minutes an attempt is made to fall back to primary.
If the primary TEMS connection is still a problem this
cycle will repeat "forever".

Small number of listening ports over long periods is
normal and can be ignored.


Recovery plan:  Review the supplied report section and
investigate the agent systems to diagnose and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1077W
Text: System [system] with with Multiple Listening ports $port_ct - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: A well running agent should register with a listening port and then
use that for long periods. It may change if the agent or the TEMS
is recycled of course. When the listening port changes frequently,
that can mean the agent is having difficulty connecting to the
TEMS, getting a connection and losing it over and over. It can also
mean a conflict in the KDEB_INTERFACELIST usage between exclusive
and non-exclusive binds.

See this blog post for details about that setting.

Sitworld: ITM 6 Interface Guide Using KDEB_INTERFACELIST
https://goo.gl/odNf2G

If one ITM process uses exclusive bind than all ITM processes
on that system *must* use exclusive bind. This sort of issue
is seen when one agent uses exclusive and another agent
uses non-exclusive bind.

There may be other causes as yet undiagnosed.


Recovery plan:  Review the supplied report section and
investigate the agent systems to diagnose and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1078E
Text: KFA Node Validity detected count potential duplicate agent name cases - See following report

Tracing: error
5970DEB6.0002-2E:kfavalid.c,773,"KFA_ValidateNodeNameSpace") Potential DUPLICATE NODE INSERT detected

Meaning: Hub TEMS node validity checking very likely duplicate
agent name condition.

Recovery plan:  Review the supplied report section and
investigate the agent systems to diagnose and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1079W
Text:  Node node at ip_addr has $tnodea_ct affinities - See following report

Tracing: error (UNIT:kfaprpst ER ST) (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)
(5601ACBE.0001-2E:kfaprpst.c,382,"HandleSimpleHeartbeat") Simple heartbeat from node <wjb2ksc27:UA                    > thrunode, <REMOTE_adm2ksc8                 >
(58A7347F.0051-2B:kfaprpst.c,2419,"UpdateNodeStatus") Node: 'REMOTE_it01qam020xjbxm          ', thrunode: 'REMOTE_it01qam020xjbxm          ', flags: '0x00000000', curOnline: ' ', newOnline: 'Y', expiryInterval: '3', online: 'S ', hostAddr: '<IP.SPIPE>#158.98.138.35[3660]</IP.SPIPE><IP.PIPE>#158.98.13'

Meaning: The same agent name is showing as having different affinities.
This could mean agents running at different maintenance levels, a
truncated agent name, or incorrect usage of Agent configuration
controls, especially CTIRA_SUBSYSTEM_ID which contradict the agent name
versus the actual type of agent.

Recovery plan:  Review the supplied report section and
investigate the agent systems to diagnose and correct the issues.
----------------------------------------------------------------

TEMSAUDIT1080E
Text:  KDEB_INTERFACELIST[value] and KDCB0_HOSTNAME[value] conflict

Tracing: error
(5914DB2A.0065-6:kbbssge.c,72,"BSS1_GetEnv") KDEB_HOSTNAME=KDCB0_HOSTNAME="it06qam020xjbxm"
(5914DB2A.0064-6:kbbssge.c,72,"BSS1_GetEnv") KDEB_INTERFACELIST="!158.98.138.32"

Meaning: The KDEB_INTERFACELIST with ! means an exclusive bind to an
interface. KDCB0_HOSTNAME means a nonexclusive bind to a interface
and this one overrides the first. Thus the result may be very different
than the user intended.

If the KDEB_INTERFACELIST does not have an ! to start, it may work
OK. This form means a statement about which interface to be advertised
first. If the values are different some agents may not be able to
connect to the TEMS as expected.


Recovery plan:  Best would be to remove the KDCB0_HOSTNAME from
config/kbbenv.ini and tables/<temsnodeid>/KBBENV and whereever else
found. That way KDEB_INTERFACELIST can keep the value configued.
----------------------------------------------------------------

TEMSAUDIT1081E
Text: KBB_RAS1 starts with single quote which prevents expected usage

Tracing: error

Meaning: KBB_RAS1 cannot start with a single quote. This prevents
normal interpretation and does not get the expected additional
tracing.

The usual reason in Linux/Unix is that a ms.environemnt file was
created with the KBB_RAS1= environment variable but the value
was single-quoted which is invalid. The same thing can be seen
in Windows if the Edit Trace Parms... dialog box, the RAS1 filter
value is set with single quotes.

Recovery plan:  Correct the invalid setting and recycle the TEMS
to acquire the needed diagnostic tracing.
----------------------------------------------------------------

TEMSAUDIT1082E
Text: Agent sending status from count instances

Trace: error (unit:kfastpst,Entry="KFA_PostEvent" all er)

Meaning: ITM depends on agents having unique instances. This
agent is coming from two or more instances. That can mean
agent mal-configuration, network problems, or duplicate agent
names. When that is true the agent(s) involved are not getting
properly monitored.

Recovery plan:  Examine the agent configuration and correct any
errors. Involve IBM Support if needed.
----------------------------------------------------------------

TEMSAUDIT1083W
Text: Situations [count] true 90% of the time

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)

Meaning: Situations should be 1) rare, 2) exceptional and
3) possible of correction to avoid the condition. With this
situation and node, that goal is being violated. In the
worst cases this leads to hub/remote TEMS instability including
crashes and random offline conditions. At the very best it
shows inefficient workload, providing little useful data.

Recovery plan:  Examine the situation and rework or stop to
avoid problems.
----------------------------------------------------------------

TEMSAUDIT1084W

Text: count corrupted rows in Short Term History table <table>

Tracing: error

Meaning: Historical data is collecting on this TEMS and corrupted
rows were seen during the export process. This may be the same row
seen multiple times. The impact is that the history data cannot be
exported to WPA and thus to the Tivoli data warehouse.

Briefly on a soapbox, collecting historical data at the TEMS is
only best practice in small environments. In most large environments
collecting at the agent avoids issues of a common failure point
and performance problems.

Recovery plan: At that TEMS copy the two related files  XXXXX and
XXXX.hdr to another directory and then erase them. On Linux/Unix
the files are usually in <installdir>/tables/<temsnodeid> and on
Windows they are usually on <installdir>\cms. However the TEMS
can be configured to another directory using CTIRA_HIST_DIR. No
TEMS recycle is needed. The next collection cycle they will be
reconfigured properly.

In most case the broken file is just discarded. In some cases
a portion of the file can be recovered. If you require that
contact IBM Support for aid.
----------------------------------------------------------------

TEMSAUDIT1085W

Text: Nodelist Errors [count] potential duplicate agent name cases

Tracing: error

Meaning: When there are many such cases, there is a strong
implication that there are duplicate agent name cases. See
REPORT048 for more details.
----------------------------------------------------------------

TEMSAUDIT1086W
Text: SOAP User Login Failure user [error_codes]

Tracing: error

Meaning: When a SOAP Logon validation fails, the failure
is recorded. Typically it is a bad password but it could
also be a unknown userid.

Recovery plan: Correct the SOAP to refelect what the correct
userid and password is.
--------------------------------------------------------------

TEMSAUDIT1087W
Text: TCP Queue Delays [count] Send-Q [max count] Recv-Q [max count] - see Report TEMSREPORT051

Tracing: netstat.info file captured during pdcollect

Meaning: These TCP queue deleys can severely impact ITM
processing. The Send-Q values are the more important. This
condition *can* severely impact ITM processing if

1) The communciation links are ITM related
2) The Send-Q values are large, like 10,000 bytes or larger
and persistent.

This advisory code is used if Send-Q max is less than 1024 bytes.

Recovery plan: Work with IBM Support to eliminate the issue.
--------------------------------------------------------------

TEMSAUDIT1088W
Text: TCP Queue Delays [count] Send-Q [max count] Recv-Q [max count] - see Report TEMSREPORT051

Tracing: netstat.info file captured during pdcollect

Meaning: These TCP queue deleys can severely impact ITM
processing. The Send-Q values are the more important. This
condition *can* severely impact ITM processing if

1) The communciation links are ITM related
2) The Send-Q values are large, like 10,000 bytes or larger
and persistent.

This advisory code is used if Send-Q max is more than 1023 bytes.

Recovery plan: Work with IBM Support to eliminate the issue.
--------------------------------------------------------------

TEMSAUDIT1089E
Text: TSITSTSH Read Error <type> [count]

Tracing: error
(591C3F9F.0000-A2:kfastins.c,2166,"GetSitLogRecord") ReadNext Error, status = 5

Meaning: The Situation Status History file is damaged and that
will cause many issues. Happily it can be replaced on any
TEMS when the TEMS is down and nothing will be lost.

Recovery plan: Work with IBM Support to eliminate the issue.
Alternatively this document

Sitworld: TEMS Database Repair http://ibm.biz/BdsYzS

contains everything needed to do the repair yourself.
--------------------------------------------------------------

TEMSAUDIT1090I
Text: Translate TEC Send event failed count times - not a problem

Tracing: error
(5A32F0B5.0002-31:kfaottev.c,1105,"KFAOT_Translate_Event") Translate TEC event failed. status <1>. Situation <Perf_CPUBusy_65_C> event status <S> not sent

Meaning: This is an informational message and can be ignored.

Recovery plan: nothing to be done
--------------------------------------------------------------

TEMSAUDIT1091I
Text: TEC Classname unable to translate count times - not a problem

Tracing: error
(5A32F0B5.0001-31:kfaottev.c,4929,"Get_ClassName") TEC classname cannot be determined for situation <Perf_CPUBusy_65_C>. status <5>

Meaning: This is an informational message and can be ignored.

Recovery plan: nothing to be done
--------------------------------------------------------------

TEMSAUDIT1092W
Text: Situation Event Status type rate count/min over count seconds.

Tracing: error
to be added.

Meaning: to be added

Recovery plan: to be added
--------------------------------------------------------------

TEMSAUDIT1093E
Text: Excess Initial Heartbeats[count] from Remote TEMS temsnodeid

Tracing: error

Meaning: In normal circumstances, the hub TEMS will receive a single
Initial Heartbeat received. It is seen on Linux/Unix in the operations
log. Occasionally there may be a few of such messages when a
remote TEMS is recycled or loses communication. If you see many
of these messages there is often a serious issue and monitoring
is not working as expected.

One type of case involved a remote TEMS on a high latency link.

Another case involved a serious agent side configuration error
which caused many reconnections. Eventually the agent got
stuck, the tcp socket from TEMS to agent got stuck and that
prevented the TEMS from communicating.

We expect there are other cases not yet diagnosed.

Recovery plan: Work with IBM Support to resolve the root cause.
--------------------------------------------------------------

TEMSREPORT001
Text: Too Big Report

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)
(53CD5BBD.0000-1B:kpxreqds.cpp,1723,"buildThresholdsFilterObject") Filter object too big (60320 + 24958),Table NTEVTLOG Situation KQ5_EVTLog_CA_Cluster2_C.

Meaning: When a situation is starting the formula is converted into
to binary objects [plan and pool] If either of these are larger
than 32767 bytes, they are not transmitted to the agent. Instead
the agent receives an empty filter. Each cycle the agent sends
all possible rows to the TEMS. The TEMS then does the needed filtering

The impact is often a performance disaster. The TEMS is overwhelmed
with work and goes unstable. That is not always true: for example
if relatively few agents are running the situation and there are
not many result rows. However that no problem condition is rare.

The condition can be detected during situation development by
editing the product provided TEMS_Alert situation, distributing
to *ALL_CMS and auto-starting. When the condition occurs a
situation event will be seen.

This condition is often surprising. That is mostly because the
situation editor shows a per cent full. However that is just the
first of 5 different situation limit. The Filter Object too
big is the 4th.

Recovery plan:  The situation should be divided into multiple
situations. There is no alternative.
----------------------------------------------------------------

TEMSREPORT002
Text: Summary Statistics

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)

Meaning:
This presents the impact of incoming result data from agents.
The "Total Results per minute" is probably most important.
Experience shows that a rate of 500,000 bytes per minute is
easily sustainable. Depending on system power and storage
higher incoming rates can be accommodated. At 5megs/min is
problems are usually seen. The highest ever measured
was 127 megs/min and the TEMS was in a sorry state.

Summary Statistics
Duration (seconds),,,23138
Total Count,,,45316
Total Rows,,,33545
Total Result (bytes),,,12239004
Total Results per minute,,,31737

The trace report was added because one TEMS was seen
with RAS1=ALL and the TEMS was just barely surviving.
The KBB_RAS1 line was captured from startup. The TEMS
might well have run with another dynamically set trace.

KBB_RAS1= ERROR (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" OUT ER) ...
Trace duration (seconds),,,30938
Trace Lines Per Minute,,,178
Trace Bytes Per Minute,,,29473

The No Matching Request line shows severe TEMS stress. A real-time
data request was made, the request timed out and later the agent
returned data which was discarded of course. A well running TEMS
never sees this issue.

Sample No Matching Request count,,,14,

Following is the report section that shows which situations or
real time request are causing the most data to be returned. The
largest contributors are shown first. This is a relatively lightly
running system and HEARTBEATs [technically node status updates]
dominate at 43% of the bytes. More often one or more situations
totally dominate. By stopping or rethinking those the workload
stress can be relieved. This is often not seen as high CPU.
TEMS has a lot of internal locking and the effect is a lot of
 waiting and general slow processing.

Situation Summary ReportSituation,Table,Count,Rows,ResultBytes,Result/Min,Fraction,Cumulative%,MinResults,MaxResults,MaxNode
HEARTBEAT,*.RNODESTS,23821,23821,5240620,13589,42.82%,42.82%,220,220,mla_udmypdmdb01:07
all_logscrp_x07w_aix,*.K07K07LGS0,7614,7614,5086152,13189,41.56%,84.37%,668,1336,mla_au122db1080mlax2:07
all_svc_gntw_win_3,*.NTSERVICE,800,576,845568,2192,6.91%,91.28%,0,1468,mla_au13uap203mlaw2:NT
all_lastbkp_gudw_db2,*.KUD3437600,160,315,522900,1355,4.27%,95.55%,0,4980,db2inst1:mla_uqmyposms1:UD
... more follow

Following is a second sorting of report that shows which
managed systems are sending the most result data and what
the peak contributing situation is.

Managed System Summary Report - non-HEARTBEAT situations
Node,Table,Count,Rows,ResultBytes,Result/Min,MinResults,MaxResults,MaxSit
db2inst1:mla_uqmyposms1:UD,*.KUD3437600,158,315,522900,1355,3320,4980,all_lastbkp_gudw_db2
mla_norfolk:NT,*.NTPROCESS,120,84,106092,275,0,1468,all_svc_gntw_win_3
mla_au12uap202mlaw2:NT,*.NTPAGEFILE,103,65,94848,245,0,1468,all_svc_gntw_win_3
... more follow

Recovery plan: If the workload is high reduce it by stopping or
reworking situations or other workload elements. If needed
split the agent workload over multiple remote TEMS.
----------------------------------------------------------------

TEMSREPORT003
Text: Situation Result Over Time Report [Top 5 situation contributors] and Result Graph

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)
Parameter added -rd

Meaning:

The first extra report shows a minute by minute presentation of
incoming results and the top 5 contributors. This can be very
helpful in understanding burst behavior. In one case a burst of
139 megs was arriving every 15 minutes which crushed remote TEMS
processing ... even though the long term average wasn�t so bad.

201702161534,,151,37,13684,
,HEARTBEAT,31,31,6820,49.84%,49.84%,
,has_zom_rlzc_redhat,9,5,5720,41.80%,91.64%,
,cur_zom_rlzc_redhat,1,1,1144,8.36%,100.00%,

201702161535,,383,75,37060,
,am3_dcss_g3zc_adv3,4,8,11712,31.60%,31.60%,
,HEARTBEAT,50,50,11000,29.68%,61.28%,
,has_zom_rlzc_redhat,9,5,5720,15.43%,76.72%,
,cur_zom_rlzc_redhat,2,3,3432,9.26%,85.98%,
,has_dbstat_gudc_db2,1,1,1852,5.00%,90.98%,


This linear report is followed by a graphical display. Here is an extract

Situation Result Over Time Graph - peak rate is 1303148 bytes per minute
Each hour is shown, each column is a minute, numbers represent 10 minutes

                           .              .              .
           .               .              .              .
           ..             ..             ..             ..
           ..             ..             ..             ..
           ..             ..             ..             ..
           ..             ..             ..             ..
2017021616 0_________1_________2_________3_________4_________5__________

Each column represents 10% of the maximum, rounded to nearest 10%. This
pattern seems to show a burst roughly every fifteen minutes. In this case
the detailed report looked like

201702161600,,54,806,650316,
,(NULL)-*.KVMSERVERN,2,216,173664,26.70%,26.70%,
,(NULL)-*.KVMSERVRDS,2,238,171360,26.35%,53.05%,
,(NULL)-*.KVMVMDSUTL,2,234,137592,21.16%,74.21%,
,(NULL)-*.KVMSERVERG,2,54,123552,19.00%,93.21%,
,(NULL)-*.KVMCLUSTRT,2,16,13952,2.15%,95.36%,

The workload was not situation related but was likely driven by a TEPS
workspace summary display against KVM servers. Peak rate was only
1.3 megs/minute and so probably sustainable.
----------------------------------------------------------------

TEMSREPORT004
Text: Endpoint Communication Problem Report

Tracing: error

Meaning:

Code,Text,Count,Source,Level
1C010001:1DE0000F, Endpoint unresponsive,3,
,,3,ip.spipe:#10.230.2.45:3660,tms_ctbs630fp7:d6305a,

This reports on ITM communications failures. In any large environment,
there are usually some number of these. If there are a lot of them
there may be network issues or the TEMS or the agent can be overloaded.
In this case a hub TEMS saw time outs talking to one remote TEMS and
that could mean an overloaded remote TEMS.

Recovery plan: There is no specific recovery plan. If there are
a lot of these the condition should be investigated and resolved.
----------------------------------------------------------------

TEMSREPORT005
Text: Reflex Command Summary Report

Tracing: error (unit:kraafira,Entry="runAutomationCommand" all)(unit:kglhc1c all)

Meaning:

First section shows the action commands run and counts.

Count,Error,Elapsed,Cmd
1651,0,1649,"/opt/IBM/ITM/scripts/bsm_history.pl ""MHC_COG_SU_Marketing_Tx"" 'RRT_Response_Time_Critical' 3 ""1170306151941000"" 5 ""Performance degraded"" >/dev/null"
duration 1651,1649,1651,0,

The second part shows the maximum simultaneous number seen operating
at one time. All commands run in the same process space as the TEMS
and as subprocesses. There have been cases where hundreds ran at the
same time and destabilized the TEMS.

Maximum action command overlay - 32
Seq,Command
0,/opt/IBM/ITM/scripts/bsm_history.pl "MHC_SAP_SMP_Login_Tx" 'RRT_Response_Time_Critical' 3 "1170306152002000" 5 "Performance degraded" >/dev/null,
1,/opt/IBM/ITM/scripts/bsm_history.pl "MHC_SAP_SMP_Login_Tx" 'RRT_Response_Time_Critical' 3 "1170306151944000" 5 "Performance degraded" >/dev/null,
2,/opt/IBM/ITM/scripts/bsm_history.pl "MHC_COG_SU_Marketing_Tx" 'RRT_Response_Time_Critical' 3 "1170306151947000" 5 "Performance degraded" >/dev/null,

Action commands running at the time can be very intensive and can
even trigger TEMS instability. Avoid that by limiting such usage.
The highest intensity is when the action command is configured to
run on each evaluation, not just the first time. That is rarely
useful and should be avoided.

Recovery plan: Mimimize the number of action commands.
----------------------------------------------------------------

TEMSREPORT006
Text: SQL Summary Report

Trace: error (unit:kdssqprs in metrics er)

Meaning:

Count,SQL
1655,User=SRVR01 Net=ip.spipe:#167.192.1.21[3660].,"SELECT NODE, THRUN
232,User=sufuser Net=ip.ssl:#129.39.23.53:52078.,"INSERT INTO O4SRV.TS
151,User=KSH Net=ip.ssl:#129.39.23.53:52072.,"SELECT SITNAME, ORIGINNO
80,User=SRVR01 Net=ip.spipe:#100.66.233.8[3660].,"SELECT AFFINITIES,HO
75,User=KSH Net=ip.ssl:#129.39.23.53:52085.,"SELECT SITNAME, ORIGINNOD

This report shows the SQL being processed by the TEMS. If this is high
it may imply a work overload at the TEMS.

Recovery plan: If too high reduce it or create more remote TEMSes
to handle the workload.
----------------------------------------------------------------

TEMSREPORT007
Text: SQL Detail Report

Trace: error (unit:kdssqprs in metrics er)
Parameter added -sqldetail

Meaning:

Type,Count,Duration,Rate,Source,Table,SQL
total,2527,4609,32.90,
source,911,4993,10.95,User=SRVR01 Net=ip.spipe:#167.192.1.21[3660].,      table,896,4993,10.77,,O4SRV.INODESTS,
sql,881,4993,10.59,,,SELECT NODE, THRUNODE, HOSTADDR  FROM O4SRV.INODESTS sql,15,4431,0.20,,,SELECT ORIGINNODE, PRODUCT, O4ONLINE, THRUNODE,
table,15,4683,0.19,,O4SRV.TNODELST,
sql,15,4683,0.19,,,SELECT NODELIST,AFFINITIES,NODE,LSTDATE,LSTUSRPRF,NODET

This is a detailed report showing the source of SQL, the tables
involved and the SQL statement instances. In this case the SQLs
were being processed 32.90 times a minute. The source was probably
another TEMS [based on the 3660 port]. The table involved was
INODESTS or the in-core node status table.

This can reflect a work overload condition. In one case the high
SQL came from agents that were supposed to have been taken out
of service.


Recovery plan: If too high reduce it or create more remote TEMSes
to handle the workload.
----------------------------------------------------------------

TEMSREPORT008
Text: SOAP SQL Summary Repor

Trace: error (unit:kshdhtp,Entry="getHeaderValue"  all) (unit:kshreq,Entry="buildSQL" all)

Meaning:
IP,Count,SQL
ip.ssl:#127.0.0.1:41067,83,"SELECT NODE, AFFINITIES FROM O4SRV.TNODELST WHERE NODELIST='*HUB'"
ip.ssl:#127.0.0.1:41067,83,"SELECT VALUE FROM O4SRV.TSYSVAR WHERE NAME ='KT1_TEMS_SECURE'"
ip.ssl:#127.0.0.1:41067,39,"SELECT NODELIST FROM O4SRV.TNODELST WHERE NODE='REMOTE_uswhram022hasra' AND NODETYPE='M'"
ip.ssl:#127.0.0.1:41067,39,"SELECT THRUNODE, AFFINITIES FROM O4SRV.INODESTS WHERE NODE='REMOTE_uswhram022hasra' "
ip.ssl:#127.0.0.1:59724,37,"SELECT THRUNODE, AFFINITIES, VERSION, O4ONLINE FROM O4SRV.INODESTS WHERE NODE='has_D219421VCSS0001: NT'"

This shows the SQLs coming through SOAP and the origin. 127.0.0.1
means it was run on the hub TEMS itself. These are often tacmd
functions which use SOAP for many functions. There have been cases
where so many tacmd functions were run that the hub TEMS became
unstable. Thus caution should be observed.


Recovery plan: If too high reduce the number of SQLs. That usually
means changing the schedule of when SOAP tasks are run. The
can include tacmd functions in a shell script.
----------------------------------------------------------------

TEMSREPORT008
Text: SOAP SQL Summary Repor

Trace: error (unit:kshdhtp,Entry="getHeaderValue"  all) (unit:kshreq,Entry="buildSQL" all)

Meaning:
IP,Count,SQL
ip.ssl:#127.0.0.1:41067,83,"SELECT NODE, AFFINITIES FROM O4SRV.TNODELST WHERE NODELIST='*HUB'"
ip.ssl:#127.0.0.1:41067,83,"SELECT VALUE FROM O4SRV.TSYSVAR WHERE NAME ='KT1_TEMS_SECURE'"
ip.ssl:#127.0.0.1:41067,39,"SELECT NODELIST FROM O4SRV.TNODELST WHERE NODE='REMOTE_uswhram022hasra' AND NODETYPE='M'"
ip.ssl:#127.0.0.1:41067,39,"SELECT THRUNODE, AFFINITIES FROM O4SRV.INODESTS WHERE NODE='REMOTE_uswhram022hasra' "
ip.ssl:#127.0.0.1:59724,37,"SELECT THRUNODE, AFFINITIES, VERSION, O4ONLINE FROM O4SRV.INODESTS WHERE NODE='has_D219421VCSS0001: NT'"

This shows the SQLs coming through SOAP and the origin. 127.0.0.1
means it was run on the hub TEMS itself. These are often tacmd
functions which use SOAP for many functions. There have been cases
where so many tacmd functions were run that the hub TEMS became
unstable. Thus caution should be observed.


Recovery plan: If too high reduce the number of SQLs. That usually
means changing the schedule of when SOAP tasks are run. The
can include tacmd functions in a shell script.
----------------------------------------------------------------

TEMSREPORT009
Text: Process Table Report

Trace: error (unit:kdsstc1,Entry="ProcessTable" all er)

Meaning
Process Table Duration: 92 seconds
Table,Path,Insert,Query,Select,SelectPreFiltered,Delete,Total,Total/min,Error,Error/min,Errors
CHK532600,,0,0,0,39,0,39,25,39,25, 74,
NTSERVICE,NTSERVICE,0,0,19,0,0,19,12,19,12, 74,
NTPROCESS,NTPROCESS,0,0,0,10,0,10,6,10,6, 74,
KA4PFJOB,,0,0,0,8,0,8,5,8,5, 74,

This report summarizes the completion of each SQL process. If the
numbers of a table is very high that can result can indicate a overload
work condition. The resolution is to reduce the workload or run on a
more powerful system.

Recovery plan: Evaluate workload and reduce if needed. In
large environments this could mean creating a second hub TEMS.
----------------------------------------------------------------

TEMSREPORT010
Text: PostEvent Report

Trace: error (unit:kfastpst,Entry="KFA_PostEvent" all er)

Meaning
Situation,Node,Count,AtomCount,Thrunodes,
has_fss_rlzw_redhat,has_usdaram012hasra:LZ,48,1,REMOTE_uswhram012hasra,
all_svrtsmr_gvmw_esx,VM:vcs2002-d122835esxs2402:ESX,46,1,REMOTE_uswhram022hasra,
all_svrtsmr_gvmw_esx,VM:vcs2002-d122835esxs2404:ESX,36,1,REMOTE_uswhram022hasra,
all_svrtsmr_gvmw_esx,VM:vcs2002-d122835esxs2403:ESX,31,1,REMOTE_uswhram022hasra,

This is seen at the hub TEMS and it shows the number of events
arriving. If the numbers are very high this can severely impact
the hub TEMS and the TEPS. Situations should be rare and
exceptional reports and not arrive in floods.

Recovery plan: Evaluate workload and reduce if needed.
----------------------------------------------------------------

TEMSREPORT011
Text: Multiple Agent online Report - top 20 max

Trace: error

Meaning
UMBSRVCTXDEV:XA,903,
coibmrppaix01:KUX,195,
coibmrppaix01:KUL,186,
coibmptpaix01:KUL,174,

The diagnostic log shows that agents were coming online over
and over. That often suggests that different systems are running
agents with the same name. That is a problem since ITM expects
to have unique names. It also means that only one agent at a time
is being monitored. Also the condition can cause TEMS instability.
Usually you need IBM Support to track down the duplications.

Recovery plan: Eliminate duplicate name agents.
----------------------------------------------------------------

TEMSREPORT012
Text: Invalid Node Name Report

Trace: error

Meaning
Node,Count,Type
VM::v5wvcs01-a0001peenxg0001:ESX,1, Validation for affinity failed.,
VM:v5wvcs01-a001p5eenxg0002:ESX ,1, Validation for affinity failed.,
VM:v5wvcs03-a00001p5eenxg0006:EX,2, Validation for affinity failed.,
PRR-Contabilit� :Grp            ,1, Validation for node failed.,

Nodes and nodelists can be invalid for several reasons. In some
cases illegal characters are used in others [like this case]
application support is missing. From ITM 630 on such agents are
rejected by default and so monitoring is not being performed as
expected. Names should be changed to legal names and application
support should be added to increase the quality of monitoring.

Recovery plan: Reconfigure agents with invalid names.
----------------------------------------------------------------

TEMSREPORT013
Text: Reflex [Action] Command failures

Trace: error

Meaning
Situation,Status,Count
Mem_NT_SCRIPT,4,19,

An intended action command failed. This needs to be researched
otherwise the expected command does not run. The Status is platform
dependent. The status 4 usually means an exception or crash.

Recovery plan: Correct invalid action commands
----------------------------------------------------------------

TEMSREPORT014
Text: Fast Simple Heartbeat report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,Count,RatePerHour,NonModeCount,NonModeSum,InterArrivalTimes
gto_rep69alll:Warehouse,388,6.00980982703726,6,198,600=381;633=3;567=3;,
gto_it06qam020xjbxm:Warehouse,387,5.99432062645211,1,303,903=1;600=385;,
gto_it06qam010xjbxm:Warehouse,387,5.99432062645211,1,345,600=385;945=1;,

The goal here is to show the inter-arrival time of agent node
status updates. The first one shows must 600 seconds [10 minutes]
but there were 3 at 33 seconds early and 3 at 33 seconds late. If
there is a tremendous variability, that suggests that the TEMS
is overloaded or a network problem. TEMS is a real-time system
in many ways and so it should be run with enough capacity to handle
the ebbs and flows of activity.

An overloaded TEMS does not usually show as high CPU. There is a
lot of internal locking and the result is usually just a slowdown
of normal processes.

Recovery plan: Correct agent balance and configuration to make
sure heartbeats arrive smoothly.
----------------------------------------------------------------

TEMSREPORT015
Text: Major Jitter Report

Trace: error (UNIT:kfaprpst ER ST)
Parameter: -jitter

Meaning

Minute,Nodes
02,gto_it01qam010xjbxm:Warehouse|647|1170328050232000
03,gto_it01qam020xjbxm:Warehouse|690|1170328050332000
21,rep70alll:Warehouse|27|1170325162113000
21,rep70alll:Warehouse|27|1170327002113000

This reports the second of the minute when agents send status
which are far away from the expected regular timing.

This report defaults to off, largely replaced by the
more advanced RB reports later on.

Recovery plan: Correct agent balance and configuration to make
sure heartbeats arrive smoothly.
----------------------------------------------------------------

TEMSREPORT016
Text: Send Node Status Exception Report

Trace: error (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)

Meaning

Node,Count,Hostaddr,Thrunode,Product,Version
UITASM1A:KA4,1,ip.pipe:#10.75.200.108[10111]<NM>UITASM1A</NM>,REMOTE_USWS0047,A4,06.21.00,
UITASM1A:KA4,1,ip.pipe:#10.75.200.109[6015]<NM>UITASM1X</NM>,REMOTE_USWS0047,A4,06.21.00,
UITASM1A:KA4,1,ip.pipe:#10.75.200.109[6015]<NM>UITASM1A</NM>,REMOTE_USWS0047,A4,06.21.00,

This records a time when a remote TEMS sends an updated agent
status to a hub TEMS. If this occurs a lot that may indicate
duplicate agents or some other agent misconfiguration or perhaps
a network issues.

Recovery plan: Correct agent balance and configuration to make
sure heartbeats arrive smoothly.
----------------------------------------------------------------

TEMSREPORT017
Text: Send Node Status Affinity Exception Report

Trace: error (UNIT:kfastinh,ENTRY:"KFA_InsertNodests" ALL)

Meaning

[example report to be added]

This records a time when a remote TEMS sends an updated agent
status to a hub TEMS. The exception is when multiple affinities
are seen for one agent name. This is a clear indication of
duplicate agent names. The condition could be on the same system
or several different systems.

Recovery plan: Correct agent name and configuration to rectify
this confition.
----------------------------------------------------------------

TEMSREPORT018
Text: Agent Timeout Report

Trace: error

Meaning

Table,Situation,Count
KISMSTATS,KIS_Bridge_Inactive,1,
KISMSTATS,KIS_HTTPS_Inactive,1,
KISMSTATS,KIS_HTTP_Inactive,1,
KISMSTATS,KIS_TCPPORT_Inactive,1,
FILEINFO,HUB_UX_SizFilSys_Mi_ALL_1,1,

This relates to a TEMS attempting to communicate with an agent
concerning a situation. That usually happens when the agent has
registered with the TEMS but is not ready for full communications.
To understand what agent is involved you needed added kpx tracing
to see the agent address and timing and context.

Small numbers of these are normal. During the TEMS startup
occasionaly an agent will be in the middle of registering but
agent is not equipped to do communications with TEMS yet. The
TEMS attempts to start a situation or something and it faile.
There is no harm since the functoion is retried later.

Recovery plan: If this happens a lot work with IBM Support to
diagnose the issue.
----------------------------------------------------------------

TEMSREPORT019
Text: RPC Error report

Trace: error

Meaning

Error,Target,Count
1C010001:1DE0004D,ip.spipe:#10.230.2.44:3660,1,
1C010001:1DE0004D,ip.spipe:#10.231.46.80:3660,4,

This reports on Remote Procedure Call errors. These can indicate
network or TEMS or Agent workload issues.

Recovery plan: If this happens a lot work with IBM Support to
diagnose the issue.
----------------------------------------------------------------

TEMSREPORT020
Text: Historical Export summary by time

Trace: error (unit:khdxdacl,Entry="routeExportRequest" state er)
(unit:khdxdacl,Entry=" routeData" detail er)

Meaning

Time,,,,Rows,Bytes,Secs,Bytes_min
1605160900,,,,184645,81023272,1077,4513831,
*total,1076,,,0,0,

For large environments it is best practice to collect data at the
agents and export to the WPA from the agents. However if you do
collect at the TEMS and export, this tells you how much data is
being exported over time. At one customer, the import rate was
25 megs/min and the export rate was 10 megs/minute - largely
because of network limitations. This report helped them make
better choices about how much to collect.

Recovery plan: Make sure system and network capacity can handle
the TEMS historical data workload collection and export process.
Consider collecting historical data at the agent.
----------------------------------------------------------------

TEMSREPORT021
Text: Historical Export summary by object

Trace: error (unit:khdxdacl,Entry="routeExportRequest" state er)
(unit:khdxdacl,Entry=" routeData" detail er)

Meaning

Object,Table,Appl,Rowsize,Rows,Bytes,Bytes_Min,Cycles,MinRows,MaxRows,AvgRows,LastRows
Application_Server,KYNAPSRV,KYN,1580,1559,2463220,137354,0,0,0,0,0,
Application_Server_Status,KYNAPSST,KYN,1712,1560,2670720,148924,0,0,0,0,0,

How much export data by attribute group.

Recovery plan: See recovery discussion in TEMSREPORT020.
----------------------------------------------------------------

TEMSREPORT022
Text: Historical Export summary by Object and time

Trace: error (unit:khdxdacl,Entry="routeExportRequest" state er)
(unit:khdxdacl,Entry=" routeData" detail er)

Meaning

Object,Table,Appl,Rowsize,Rows,Bytes,Time

Application_Server_1605160900,KYNAPSRV,KYN,1580,1559,2463220,1605160900,
Application_Server_Status_1605160900,KYNAPSST,KYN,1712,1560,2670720,1605160900,
Current_Queue_Manager_Status_1605160900,QMCURSTAT,KMQ,2128,40,85120,1605160900,
DB_Connection_Pools_1605160900,KYNDBCONP,KYN,1116,2748,3066768,1605160900,

How much export data by attribute group over time.

*Note: You can get the same sort of data from an ITM agent using the following trace

       error (unit:khdxcpub,Entry="KHD_ValidateHistoryFile" state er)
             (unit:khdxhist,Entry="openMetaFile" state er)
             (unit:khdxhist,Entry="open" state er)
             (unit:khdxhist,Entry="close" state er)
             (unit:khdxhist,Entry="copyHistoryFile" state er)

Recovery plan: See recovery discussion in TEMSREPORT020.
----------------------------------------------------------------

TEMSREPORT023
Text: Time Slot Result workload

Obsolete - Replaced by result detail report TEMSREPORT003,.

Recovery plan:
----------------------------------------------------------------

TEMSREPORT024
Text: Attribute File Warning Report

Trace: error

Meaning

Trace: error

AttributeName,WarningType,
,,filename,app,table,column,
attribute name conflict,Diagnostic.IMPORTANCE,
,,KTO.ATR,KTO,TODIAG,IMPORT,
,,KTU.ATR,KTU,TUDIAG,IMPORT,
attribute name conflict,Diagnostic.MESSAGE,
,,KTO.ATR,KTO,TODIAG,MESSAGE,
,,KTU.ATR,KTU,TUDIAG,MESSAGE,

TEMS depends on accurate consistent application support files
including the attribute files. If an attribute is multiply defined,
you will get messages like. The above case is simple and no
trouble - although there is an APAR to eliminate. Most common
are cases where the previous attribute file has been saved u
nder a different name: like ktu.atr.orig. TEMS processes all
names and not just the .atr names. The solution there is just
to erase the saved file, or move it to another directory. In
other cases contact IBM Support to achieve resolution.

The impact is that some attributes might be mis-understood and
situations not work as expected.

Recovery plan: Correct attribute issues. Contact IBM Support
if needed.
----------------------------------------------------------------

TEMSREPORT025
Text: Loci Count Report

Trace: error

Meaning

Loci Count Report - 25811 found

Locus,Count,PerCent,Example_Line

kfaprpst.c|NodeStatusRecordChange|3649,6742,26%,(59245816.0000-1F:kfaprpst.c
kfaprpst.c|NodeStatusRecordChange|3582,6075,23%,(5924583C.0000-2B:kfaprpst.c
kdsrqc1.c|AccessRowsets|2624,3309,12%,(59245E77.0001-19:kdsrqc1.c,2624,"Acce

This is a catch-all report. The theory is that error messages
often show is great volume. Some are ignored as known and
uninteresting. The remaining ones are displayed. The first
section or locus is the source unit, the function name and
the line number. The next is a count of lines and a percentage
of total recorded lines. In this way uncategorized error messages
*may* be displayed for analysis. When the message count is
very small the report is relatively un-interesting.

Recovery plan: Contact IBM Support if messages are concerning.
----------------------------------------------------------------

TEMSREPORT026
Text: Agent connection churning Report

Trace: error

Meaning

Agent connection churning Report - 3 systems

ip_address,Count,NewPCB,DeletePCB,Agents(count),
10.230.2.40,306,153,153,,
10.230.2.44,6,4,2,,
10.231.46.80,5,3,2,,

In a well running ITM environment connections are made [NewPCB]
and then stay active for long periods of time - weeks or months.
Sometimes we see the same ip address being created and then deleted
over and over. That often means a configuration issue at the agent,
where two agents are contending for the same connection. Often a
mis-use of KDEB_INTERFACELIST causes the issue. In any case, the
affected agents are severely affected and the TEMS itself can
experience serious issues include failure at high rates. This
report is of only 3 systems so the big effect is that the agents
involved are likely not monitoring as expected.

One case where this is perfectly normal was identified by a
customer recently. The system involved was where they ran a lot
of their normal tacmd functions. Each one created a tcp connection
that was created and closed.

Recovery plan: Contact IBM Support if messages are concerning.
----------------------------------------------------------------

TEMSREPORT027
Text: SOAP Error Report

Trace: error

Meaning

Count,Fault,
,Count,Client,
8,Unable to open request (79),
,8 , ip.ssl:#127.0.0.1,

This shows SOAP problems. Usually they are seen during
development periods. However they can also be seen when
there are too much simultaneous SOAP activity. Usually
the hub TEMS stability is not affected.

Recovery plan: Identify SOAP usage and correct errors.
----------------------------------------------------------------

TEMSREPORT028
Text: Agent Flipping Report

Trace: error
Parameter added -noflip to suppress

Meaning

Desc,Count,Node,Count,Thrunode,HostAddr,OldThrunode,
Host info/loc/addr,23,Primary:ATENEA2:NT,1,RTEMS01,ip.pipe:#10.231.33.234,,
Host info/loc/addr,23,Primary:ATENEA2:NT,20,RTEMS01,ip.pipe:#10.231.33.95,,
Host info/loc/addr,23,Primary:ATENEA2:NT,2,RTEMS02,ip.pipe:#10.231.33.95,,
...
Thrunode,3,sappspaix04:KUX,2,RTEMS01,ip.spipe:#10.231.38.65,RTEMS02,
Thrunode,3,sappspaix04:KUX,1,RTEMS02,ip.spipe:#10.231.38.65,RTEMS01,
Thrunode,4,enertperpprd:KUX,2,RTEMS02,ip.pipe:#10.231.29.131,RTEMS01,
Thrunode,4,enertperpprd:KUX,2,RTEMS01,ip.pipe:#10.231.29.131,RTEMS02,
...

This report is new at ITM 630 FP7 on a hub or remote TEMS. It means
that a given agent is reporting differently. In the first set of 3
a Windows OS Agent Primary:ATENEA2:NT is reporting from two
different ip addresses. In addition one of the addresses
10.231.33.95 is reporting through two different remote TEMSes.

In the second set one agent is reporting through two different
remote TEMSes, apparently flipping back and forth. That is true
for two different agents.

In the report, there were 1678 lines in that report section.
Things are seriously wrong.

There can be many reasons. For example, the agents may be
configured with the same name even though they are on different
systems. If the OS agent is in the ITM 622 GA to FP2 level, the
agent can be connected to two different remote TEMS at the same
time. And there are lots of other potential problems. The impact
is severe. You can wind up running situations on only part of
the agents and the TEMS itself can be unstable and crash.


Recovery plan: Work with IBM Support to resolve issues.
----------------------------------------------------------------

TEMSREPORT029
Text: Situation Length 32 Report

Trace: error

Meaning

Count,Sitname,,
1,ARG_BK_FilSys_Ma_coibmbppaix01_2,
1,ARG_BK_FilSys_Ma_coibmbwdaix01_2,

This is rarely seen. It usually means a situation was constructed
manually and uploaded using tacmd createsit without the benefit
of the TEP situation editor validity checking. The result is that
the situation is not working, which is obviously a poor result.

On rare occasions this might be a leftover from a ITM 6.1 created
situation where 32 character names were legal.

Recovery plan: Recreate the situation in the TEP situation editor.
----------------------------------------------------------------

TEMSREPORT030
Text: RB Duplicate Node Evidence Reports details

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,HostAddr,Interval,Dup_count,Reason(s),
b0d0r41d:KUX,,600,5,early_heartbeat(5) ,
b0d0r41d:KUX,,600,,early_heartbeat,288:5945837C:279:594586EB:47:59458E22:280:59459192:279:59459501,
b0d0r41d:KUX,,600,frequencies,47(1) 279(2) 280(1) 288(1) ,


There are five cases of evidence: leftover_seconds,
                                  heartbeat_outside_grace,
                                  double_heartbeat,
                                  double_offline,
                                  early_heartbeat.

The double heartbeat and double offline - cases showing in the
same second  just show you the time the condition was observed.
That time is a epoch seconds in hex and is present in the the
diagnostic logs. The other three contain a time different value
and also the epoch seconds in hex, For those three, there is
another line that shows you the frequency of the time differences.

In this example case there were 5 cases of early heartbeats.
The interval is recorded at 600 seconds [default 10 minutes]
and four were observed at 279/280/288 seconds. This is evidence
there are duplicate agents. Late heartbeats get counted separately
since there is can often be a few second plus or minus from the
600 second target and this is considered normal.

Here is another great example

em3_A0172O3WAPPP117:NT,10.130.65.150[52892],600,frequencies,76(5) 77(25) 78(308) 79(16) 521(16) 522(307) 523(24) 524(6) ,

There is a cluster of early arrivals, one around 78 seconds and
another around 522 seconds. This just happen to add up to 600 seconds,
a strong indication of duplicate agents. The large range indicates
the TEMS is under severe stress of some sort.

More information on the various evidence cases are seen at the end
of the TEMS Audit report. As we gain more experience, we will add
more to the blog post commentary.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT031
Text: RB Thrunode Change Report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,HostAddr,Thrunode_count,Thrunode(s),
has_A0001V5WAPP0012:NT,10.176.66.20[50283],1063,REMOTE_usdaram012hasra(532) REMOTE_uswhram012hasra(532) ,
has_JSKS-VM:KUX,10.130.2.10[7757],92,REMOTE_usdaram012hasra(47) REMOTE_uswhram012hasra(46) ,

These are both strong indications of duplicate agent name cases.
Many connects via one remote TEMS and many from another.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT032
Text: RB Multiple System Report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,System_count,System(s),
has_A0001V5WAPP0012:NT,10.176.66.20 10.176.66.21 10.176.66.22 ,
em3_A0172O3WAPPP117:NT,10.130.65.150 10.130.65.156 ,

This is a strong indication that the agents on multiple systems
are accidentally configured with the same name. This causes
severe TEPS performance issues. It causes TEMS instability
including crashes and should be corrected by reconfiguring
the agents so they have the unique names as ITM expects.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT033
Text: RB System Multiple Listening Ports Report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,PipeAddr,Count,Ports,
tbk_tbexhcprd07:06,10.190.50.70,4,43879 31474 21036 6536,
tbk_tbkdrad04:NT,10.190.50.51,3,59824 55120 60997,
tbk_tbctftpdrs1:NT,172.19.215.23,3,60927 60158 61217,

This is a strong indication that the agents reported on are
are having severe connection issues. This can be network
issues. It could be a configuration issue such as inconsistent
use of KDEB_INTERFACELIST and/or KDCB0_HOSTNAME.

This causes severe TEPS performance issues. It causes TEMS
instability including crashes and should be corrected by
reconfiguring the agents and resolving network issues so
the connections persist for long periods.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT034
Text: RB System Multiple Listening Ports on Physical Systems Report

Trace: error (UNIT:kfaprpst ER ST)
             (comp:kde,unit:kdebp0r,Entry="receive_vectors" all er)
             (comp:kde,unit:kdeprxi,Entry="KDEP_ReceiveXID" all er)

Meaning

Node,PipeAddr,Count,Ports,
10.100.2.22,REMOTE_th01ram090tbkxs,2,45143 45154,
10.145.113.132,REMOTE_th01ram090tbkxs,2,11852 64622,
10.180.128.61,REMOTE_th01ram090tbkxs,2,11852 2806,

This is similar to TEMSREPORT033 however the system reported
is reported against the physical address of the agent and not
the pipe address the TEMS uses. This is the same in simple
environments but can be quite different when ephemeral:y or
firewalls or KDE_Gateways are in use.

This is a strong indication that the agents reported on are
are having severe connection issues. This can be network
issues. It could be a configuration issue such as inconsistent
use of KDEB_INTERFACELIST and/or KDCB0_HOSTNAME.

This causes severe TEPS performance issues. It causes TEMS
instability including crashes and should be corrected by
reconfiguring the agents and resolving network issues so
the connections persist for long periods.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT035
Text: RB Multiple Hostaddr Report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,HostAddr_count,HostAddr(s),
w82_apc14cnhl:MQ,3,10.240.137.9[34013] 10.240.137.9[38270] 10.240.137.9[51465] ,
xia_dbc28giax:07,2,160.220.169.32[53613] 160.220.169.32[53842] ,

When an agent registers with a TEMS it supplies a listening ip
address and a port. The above cases are probably the normal
result of an agent recycles. If you see a lot of them - and
ones from different ip addresses, both agent duplicate name
and agent mal-configuration may be in play.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT036
Text: RB Multiple Agent Initial Status Report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

Node,HostAddr,InitialStatus_Count,
b0d0r41d:KUX,,5,
b0d02ie2:KUX,,4,

When an agent sends node status to a TEMS for the first time,
that is tagged with Status '1'. Later it is tagged with 'Y'.
When an agent sends initial status many times, that suggest
a configuration issue at the agent and needs to be investigated.
A certain number are expected: the first connection of course...
but also when agent switches from one remote TEMS to another.
It will also be seen after communication outages. Use your own
best judgement about whether an investigation and diagnosis is needed.

Recovery plan: Work with IBM Support to resolve these issues.
----------------------------------------------------------------

TEMSREPORT037
Text: RB Negative Heartbeat Time Report.

Trace: error (UNIT:kfaprpst ER ST)

Meaning

This usually indicates the diagnostic logs were hand assembled
out of time order.

Recovery plan: Whatever was done should repeated correctly.
----------------------------------------------------------------

TEMSREPORT038
Text: Pipeline Report

Trace: error (UNIT:kfaprpst ER ST)
             (comp:kde,unit:kdebp0r,Entry="receive_vectors" all er)
             (comp:kde,unit:kdeprxi,Entry="KDEP_ReceiveXID" all er)

Meaning

[example to be added later].

This shows what agent physical addresses are, what the internal
pipe address is, and what if any the gateway address is. This is
limited to the agents showing in the RB reports.

Recovery plan: Nothing... used to help explain other reports.
----------------------------------------------------------------

TEMSREPORT039
Text: Summary Receive Vector Report

Trace: error (UNIT:kfaprpst ER ST)
             (comp:kde,unit:kdebp0r,Entry="receive_vectors" all er)
             (comp:kde,unit:kdeprxi,Entry="KDEP_ReceiveXID" all er)

Meaning

temsnodeid,phys_addr,phys_count,pipe_addr,pipe_count,
REMOTE_NLAM3-MCTVPVL00,67.204.110.170,1,1,
REMOTE_NLAM3-MCTVPVL00,67.204.111.201,61,1,

This summarizes receive vector information. If a physical
address has many pipe_addr, that usually means an agent
mal-configuration or a network connection issue.

Recovery plan: Diagnose and correct Agent side issues.
----------------------------------------------------------------

TEMSREPORT040
Text: Detail Receive Vector Report

Trace: error (UNIT:kfaprpst ER ST)
             (comp:kde,unit:kdebp0r,Entry="receive_vectors" all er)
             (comp:kde,unit:kdeprxi,Entry="KDEP_ReceiveXID" all er)

Meaning

temsnodeid,phys_addr,phys_count,pipe_addr,pipe_count,xlate,xlate_count,gateway,service_point,service_type,driver,build_date,build_target,process_time,
REMOTE_th01ram090tbkxs,10.145.113.132,3,10.145.113.132:7756,1,,1,,,,,,,0,
REMOTE_th01ram090tbkxs,10.178.120.12,2,10.178.120.12:7756,1,,1,,,,,,,0,
REMOTE_th01ram090tbkxs,10.180.128.48,2,10.180.128.48:11852,1,,1,,,,,,,0,

This reports detailed receive vector information.

Recovery plan: Used used to help explain other reports.
----------------------------------------------------------------

TEMSREPORT041
Text: Node Validity Duplicate Node Report

Trace: error (UNIT:kfaprpst ER ST)

Meaning

TEMSREPORT041: Node Validity Duplicate Node Report
Count,Node,Thrunode,Product,Thrunode_new,Product_new,
1,DB2plex:DB2plex:Plexview,WD01:CMS,DP,temdhdq01v_hub,D5,
1,DB2plex:DB2plex:Plexview,WD03:CMS,DP,temdhdq01v_hub,D5,

This shows hub TEMS detected node duplication. This usually means
duplicate agent name cases.

Recovery plan: Involve IBM support to resolve issues.
----------------------------------------------------------------

TEMSREPORT042
Text: Portscan Time Report

Trace: error
Parameter: -portscan

Meaning

TEMSREPORT042: Portscan Time Report
Epoch,Local_Time,Scan_Types,
586CE1D6,20170104035150,integrity unsupported http integrity unsupported http integrity unsupported http integrity,
586CE1DE,20170104035158,integrity unsupported http integrity unsupported http integrity unsupported http integrity unsupported http integrity,
586CE1E3,20170104035203,integrity,

This shows hex time and the local time when the possible portscan
cases occured. This may be useful in finding the underlying cause.

Recovery plan: Involve IBM support to resolve issues.
----------------------------------------------------------------

TEMSREPORT043
Text: ITM Config and Install last few lines

Trace: error

Meaning

TEMSREPORT043: ITM Config and Install last few lines
itm_config.log
2017-06-08 15:47:36.472+01:00 ITMinstall.CandleAgent main [LOG_INFO]
      Agent stopped... (traceKey:1496929656472)
2017-06-08 15:47:44.666+01:00 ITMinstall.CandleAgent main [LOG_INFO]
      Warehouse Proxy agent started... (traceKey:1496929664666)

This shows the lines from the last 1000 bytes of the
itm_config.log and itm_install.log. It can be useful in
understanding what has happened recently.

Recovery plan: Involve IBM support to resolve issues.
----------------------------------------------------------------

TEMSREPORT044
Text: FTO control messages

Trace: error

Meaning

TEMSREPORT044: FTO control messages
Epoch,Local_Time,Line_number,Message
59959385,20170817040053,355, Begin FTO Stage-Two processing: FTO mode <Mirror> acting hub <HUB_frmpqam00srb2xm> full sync <Yes> migrate <No>,
5995939B,20170817040115,434, FTO Stage-Two processing completed at <08/17/17 15:01:15>, rc = 0,
5995939B,20170817040115,436, parent cms <HUB_frmpqam00srb2xm> is now the HUB,
5995939B,20170817040115,437, local cms <STANDBY_frmpqam00srb4xm> is now the MIRROR,

This shows when the hub TEMS is synchronizing with a
Fault Tolerant Option partner hub TEMS. It can be useful in
understanding what has happened. The Line Number is the relative
line in all the log segments.

This may be inconsistent if the diagnostic logs wrapped around.

Recovery plan: Involve IBM support to any resolve issues.
----------------------------------------------------------------

TEMSREPORT045
Text: PostEvent Report Summary

Trace: error (unit:kfastpst,Entry="KFA_PostEvent" all er)

Meaning

TEMSREPORT045: PostEvent Report Summary
Situation,Count,Nodes,Rate,
NLHEM_341_NT_Percent_Processor,534,51,8.97/min,
NLENC_351_NT_Percent_Total_Proc,212,109,3.56/min,
NLEZ_341_NT_Percent_Processor,145,43,2.44/min,
NLCGO_351_NT_Percent_Total_Proc,128,55,2.15/min,

This is seen at the hub TEMS and it shows the number of events
arriving. If the numbers are very high this can severely impact
the hub TEMS and the TEPS. Situations should be rare and
exceptional reports and not arrive in floods.

There is no specific guideline. The ulimate test should be whether
the event has value in reducing outages and service degradation.

Recovery plan: Evaluate workload and reduce if needed.
----------------------------------------------------------------

TEMSREPORT046
Text: PostEvent Node Status Instance Exceptions

Trace: error (unit:kfastpst,Entry="KFA_PostEvent" all er)

Meaning

TEMSREPORT047: PostEvent Node Status Instance Exceptions
Node,Count,Thrunode,Hostaddr,Product,Version,
neo:neo:LO,74,REMOTE_NLAMA-MCTVPVL13,ip.pipe:#10.128.122.31[56272]<NM>neo</NM>,LO,06.30.00,
neo:neo:LO,74,REMOTE_NLAMA-MCTVPVL13,ip.pipe:#10.213.193.41[46439]<NM>neo</NM>,LO,06.30.00,
neo:neo:LO,74,REMOTE_NLAM3-MCTVPVL03,ip.pipe:#10.128.122.41[45325]<NM>neo</NM>,LO,06.30.00,

This seen at the hub TEMS and is strong evidence of
mal-configuration at the agents including but not
limited to duplicate agents.

Recovery plan: Evaluate agent configurations and change so the ITM
has unique agent names as it requires for good monitoring.
----------------------------------------------------------------

TEMSREPORT047
Text: Situation-Node often true

Tracing: error (unit:kpxrpcrq,Entry="IRA_NCS_Sample" state er)

Meaning

TEMSREPORT047: Summary Situation-Node often true by Situation
Situation,Fraction,Count,Norows,Nodes,
NLNID_331_3Z_DNS_Srvc_Status_C,100%,1234,0,4,
NLNID_321_3Z_DNS_Srvc_State_Cr,100%,1234,0,4,

TEMSREPORT047: Detail Situation-Node often true by Situation and Node
Situation,Percent,Count,Norows,Node,ip,tems,duration,secs/result,
NLENC_321_3Z_DNS_Srvc_State_C,100%,309,0,ENC-CAP-EDS-01:3Z,,REMOTE_NLAM3-MCTVPVL02,1504261422,9240,29.90,
NLNID_321_3Z_DNS_Srvc_State_Cr,100%,309,0,NDR-DCA-ADC-002:3Z,,REMOTE_NLAM3-MCTVPVL02,1504261422,9240,29.90,
NLENC_321_3Z_DNS_Srvc_State_C,100%,309,0,ENC-CAP-EDS-02:3Z,,REMOTE_NLAM3-MCTVPVL02,1504261421,9240,29.90,

Situations that are always or usually true can have a severe
effect on hub/remote TEMS performance. In addition they suggest
a situation that violates the "rare and exceptional" aspect
of situaton development. If the condition is exceptional the
issue is to explain why the monitored system is not corrected.
If it is not exceptional, monitoring should be terminated.

This report does include pure events, which naturally only
show true events. The same argument holds for pure events.

Recovery plan: Evaluate situation and either stop running,
correct monitored system or rework situation so it matches
best practice for situations: rare, exceptional and a condition
which can be corrected by some manual or automated process.
----------------------------------------------------------------

TEMSREPORT048
Text: Nodelist Error report - possible duplicate node indications

Tracing: error

Meaning

example added later

At times a remote TEMS will get an instruction to change a
EIB data, often Nodelist data. When the attempt to get
additional data fails, this means the agent involved has
switched remote TEMSes.

When this occurs a lot that suggests strongly that a
duplicate agent name condition exists. If it just a few times
that is likely normal behaviour.

Recovery plan: Investigate possible duplicate agents and eliminate
to get accurate and complete monitoring.
----------------------------------------------------------------

TEMSREPORT049
Text: SOAP Detail Report

Tracing: error (unit:kshdhtp,Entry="getHeaderValue"  all) (unit:kshreq,Entry="buildSQL" all)(unit:kshstrt.cpp,Entry="default_service" all er)(unit:kshxmlxp.cpp,Entry="addelement" all er)(unit:kshxmlxp.cpp,Entry="setValue" all er)(unit:kshreq.cpp,Entry="Fetch" all er)

Meaning

Local_Time,Duration,IP,Diagnostic_Line_Number,
,SOAP_Message_Summary,
,First_Row_Result,
20171201161040,0,ip.ssl:#9.30.240.127:52381,55960,
,CT_Export=;filename=a;request=;CT_Get=;userid=sysadmin;password=xxxxxxx;table=O4SRV.UTCTIME;sql=SELECT NODE, AFFINITIES, PRODUCT, VERSION, RESERVED, O4ONLINE FROM O4SRV.INODESTS WHERE (O4ONLINE = 'N' OR O4ONLINE = 'Y');,
,<TABLE name="O4SRV.UTCTIME"><OBJECT>Universal_Time</OBJECT><DATA><ROW><NODE>54905lp7:KUX</NODE><AFFINITIES>%IBM.STATIC013          000000000P000Jyw0a7</AFFINITIES><PRODUCT>UX</PRODUCT><VERSION>06.23.05</VERSION><RESERVED>A=00:aix526;C=06.23.05.00:aix526;G=06.23.05.00:aix526;</RESERVED><O4ONLINE>N</O4ONLINE></ROW>

Report on available details of SOAP processing.

Line refers to the line number on the diagnostic logs where the
initial reference was found. If there are more than one diagnostic
log segment, the line number is cumulative across all the segments.

The "Message Summary" line is the data which the SOAP process has
extracted from the XML that defines the SOAP request.

The "First Row" line is the data concerning the full row. The results
can be very long indeed.

Recovery plan: Use this to understand SOAP processing. This can
be intensive and destabilize the hub TEMS. Reduce excess use or
make more efficient SOAPs.
----------------------------------------------------------------

TEMSREPORT050
Text: TNODESTS Insert Error Summary Report

Tracing: error
(5A2668D0.0004-68:kdsvws1.c,2421,"ManageView") ProcessTable TNODESTS Insert Error status = ( 1551 ).  SRVR01 ip.spipe:#10.64.11.30[3660]

Meaning

TEMSREPORT050: TNODESTS Insert Error Summary Report
IP_Addr,Count,
ip.spipe:#10.64.11.30[3660],1551[735] ,

The TEMS was updating a node status on another TEMS. However
the target TEMS reported the agent no longer was connected to
that TEMS.

Recovery plan: If these numbers are high, the TEMSes should
be studied to determine the high rate of agent switching. There
can be many reasons such as duplicate agent name cases and
agent, TEMS mal-configuration or communication issues.
----------------------------------------------------------------

TEMSREPORT051
Text: NETSTAT Send-Q and Recv-Q Report

Sample Report
Active Internet connections (including servers)
PCB/ADDR         Proto Recv-Q Send-Q  Local Address      Foreign Address    (state)
f1000e000043ebb8 tcp4       0    168  10.64.11.27.22        172.31.18.29.49630    ESTABLISHED

Meaning:

This report is generated from the netstat.info captured from a pdcollect.

When you check TCP queues using netstat, the receive and send queues
are usually zero. In unusual cases, the the ITM to ITM communication
processes that become stuck. In that case the TCP send and receive
queues can get large and that condition can destablize ITM processing
severely. You can usually spot ITM cases because the source and/or the
target reference port 1918 or 3660.

It there are just a few non-zero queue connections or if they are not
associated with any ITM processses, the condition can be ignored... at
least as far as ITM is concerned.  Send-Q values are much more important
than Recv-Q values.

Here are some conditions that have been the underlying cause of the issue.

FTO misconfigured at the RTEMS
Misconfigured agent
Duplicate agent
Agent inactivity
Unresponsive agent

And probably many more we have not yet diagnosed. This diagnosis is a
work in progress and we may have more documentation as time goes on.

The usual starting point is to diagnose the Send-Q target
delays. The Recv-Q conditions are usually a side effect of
the Send-Q issues.

Recovery plan: Involve IBM Support to eliminate the issue.
----------------------------------------------------------------

TEMSREPORT052
Text: Process Table Report Delays - Max overlay count

Sample Report
to be added

Meaning:
to be added


Recovery plan: to be added
----------------------------------------------------------------

TEMSREPORT053
Text: PostEvent/ProcessTable Report by time

Sample Report
TimeSlot,Event_Count,Event_Rate/Sec,Situation_Count,Status_Count,Status_Type,PT_Count,PT_Rate/sec,Duration_total,Duration_max,Duration_Avg,Level_max,Level_total,Level_Avg,
.....
20171229153800,1622,27.03,1501,1622,S[1470] Y[91] N[61] ,1890,31.50,966,764,0.51,10,9790,5.18,

TimeSlot         : time slot for communication, default 10 minutes, can be specified by -evslot <number>, should divide into hour
Event_Count      : count of arriving Situation Event Status History
Event_Rate/Sec   : rate of arriving Situation Event Status History records in second
Situation_Count  : number of situations represented
Status_Count     : Count of statuses
Status_Type      : S=Start, P=Stop, Y=open, N=close and the count
PT_Count         : Number of Process Table completions
PT_Rate/sec      : Rate of process table completions per second
Duration_total   : Total duration in seconds of all Process Table Completions
Duration_max     : Maximum individual duration of Process Table Completions in time slot
Duration_Avg     : Average duration of all Process Table Completions
Level_max        : Maximum level of pending Process Table functions, blocked by lock
Level_total      : Number of pending Process Table functions, blocked by lock
Level_Avg        : Average pending Process Table functions

Meaning:
It is possible for a hub TEMS to be damaged by too much pending work. This can be
created by

1) System running hub TEMS needs more compute power, memory etc
2) The workload running on the hub TEMS needs to be reduced
3) The environment needs multiple hub TEMSes to satisfy the worload.

In general the average number of pending processes [Level_Avg] should be near zero.

An option -sth can be used to create a detailed report on the data which can be help
explain the condition. In the critical case which led to this analysis report, the
root cause was the customer having a tremendous number of active situations [about 9000]
and many situations having *UNTIL conditions that operated on a tight time schedule like
30 seconds. Because of that there were floods of Stop and Start status event history. This
kept the hub TEMS so busy that the TEPS was unable to retrieve critical information in a
timely fashion [sometimes waiting 40 minutes for a response] and the TEP sessions were
also unusable.

Recovery plan: Review workload with a view to reducing impact or get a much more powerful
system to run the hub TEMS.
----------------------------------------------------------------

TEMSREPORT054
Text: Excess Initial Heartbeat report

Sample Report
RemoteTems,Initial_count,Stamps
REMOTE_usrdrtm051ccpr2,6,Fri Dec 15 04:33:45 2017|Wed Dec 20 12:36:18 2017|Sun Dec 31 18:40:56 2017|....

Meaning: In normal circumstances, the hub TEMS will receive a single
Initial Heartbeat received. It is seen on Linux/Unix in the operations
log. Occasionally there may be a few of such messages when a
remote TEMS is recycled or loses communication. If you see many
of these messages there is often a serious issue and monitoring
is not working as expected.

One type of case involved a remote TEMS on a high latency link.

Another case involved a serious agent side configuration error
which caused many reconnections. Eventually the agent got
stuck, the tcp socket from TEMS to agent got stuck and that
prevented the TEMS from communicating.

We expect there are other cases not yet diagnosed.

This report shows the Remote TEMS involved, the count of Initial Heartbeat
messages in the operations log, and the operation log time stamps

Recovery plan: Work with IBM Support to resolve the root cause.
