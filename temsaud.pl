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
#  john alvord, IBM Corporation, 21 Mar 2011
#  jalvord@us.ibm.com
#
# tested on Windows Activestate 5.16.3
#

$gVersion = 0.99000;

# $DB::single=2;   # remember debug breakpoint

# CPAN packages used
# none

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

my $opt_z;
my $opt_expslot;
my $opt_logpat;
my $opt_logpath;
my $opt_workpath;
my $full_logfn;
my $opt_v;

while (@ARGV) {
   if ($ARGV[0] eq "-h") {
      &GiveHelp;                        # print help and exit
   }
   if ($ARGV[0] eq "-z") {
      $opt_z = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-b") {
      $opt_b = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-v") {
      $opt_v = 1;
      shift(@ARGV);
   } elsif ($ARGV[0] eq "-expslot") {
      shift(@ARGV);
      $opt_expslot = shift(@ARGV);
   } elsif ($ARGV[0] eq "-logpath") {
      shift(@ARGV);
      $opt_logpath = shift(@ARGV);
      die "logpath specified but no path found\n" if !defined $opt_logpath;
   } elsif ($ARGV[0] eq "-workpath") {
$DB::single=2;
      shift(@ARGV);
      $opt_workpath = shift(@ARGV);
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
if (!defined $opt_b) {$opt_b = 0;}
if (!defined $opt_v) {$opt_v = 0;}
if (!defined $opt_expslot) {$opt_expslot = 60;}

$gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

if (!defined $opt_workpath) {
   $opt_workpath = "c:/temp" if $gWin == 1;       # ??? %TEMP%
   $opt_workpath = "/tmp" if $gWin == 0;
}
$opt_workpath .= '/';
$opt_workpath =~ s/\\/\//g;    # switch to forward slashes, less confusing when programming both environments

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



my $pattern;
my @results = ();
my $loginv;
my $inline;
my $logbase;
my %todo = ();     # associative array of names and first identified timestamp
my @seg = ();
my $segi = -1;
my $segp = -1;
my $segcur = "";


if ($logfn eq "") {
   $pattern = "_ms\.inv";
   @results = ();
   opendir(DIR,$opt_logpath) || die("cannot opendir $opt_logpath: $!\n"); # get list of files
   @results = grep {/$pattern/} readdir(DIR);
   closedir(DIR);
   die "No _ms.inv found\n" if $#results == -1;
   if ($#results > 0) {         # more than one inv file - complain and exit
      $invlist = join(" ",@results);
      die "multiple invfiles [$invlist]\n";
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
   die "invalid log form $inline from $full_logfn\n" if !defined $1;
   $logbase = $1;
   $logfn = $1 . '-*.log';
   close(INV);
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
my $logthread;              # thread information - unused
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
my $sitct_tot = 0;          # total results
my $sitrows_tot = 0;        # total rows
my $sitres_tot = 0;         # total size
my $sitstime = 0;           # smallest time seen - distributed
my $sitetime = 0;           # largest time seen  - distributed
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
my $ifiltsize;              # input size
my $ifilttbl;               # input table
my $ifiltsit;               # input situation
my $tx;                     # index

my $soapi = -1;             # count of soap SQLa
my @soap = ();              # indexed array to SOAP SQLs
my %soapx = ();             # associative array to SOAP SQLs
my @soapct;                 # count of soap SQLs
my @soapip;                 # last ip address seen in header
my $soapip_lag = "";        # last ip address spotted
my $soapct_tot;             # total count of SQLs


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
my @hist_appl = ();             # appliaction name
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
my @histobject_appl = ();       # appliaction name
my @histobject_rows = ();       # number of rows
my @histobject_rowsize = ();    # size of rows
my @histobject_bytes = ();      # total size of rows


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

if ($opt_z == 0) {$state = 0}

$inrowsize = 0;

for(;;)
{
   read_kib();
   if (!defined $inline) {
      last;
   }
   $l++;
# following two lines are used to debug errors. First you flood the
# output with the working on log lines, while merging stdout and stderr
# with  1>xxx 2>&1. From that you determine what the line number was
# before the faulting processing. Next you turn that off and set the conditional
# test for debugging and test away.
#   print STDERR "working on log $logfn at $l\n";
# if ($l == 338) { $DB::single=2;}

   chomp($inline);
   if ($state == 0) {                       # state = 0 distributed log - no filtering
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
         $lagline = "";
         $lagtime = 0;
         $laglocus = "";
         $state = 2;
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
      # case 4 - look for operation log id, if not append to saved line and contiue
      #          if not operations log id, emit and resume looking for next
      else {
         $oplogid = substr($inline,21+$offset,8);
         $oplogid =~ s/\s+$//;
         if ((index($oplogid," ") != -1) ||
             (substr($oplogid,0,1) ne "K")) {
            $lagline .= substr($inline,21+$offset);
            $state = 3;
            next;
         }
         $oneline = $lagline;
         $logtime = $lagtime;
         $lagline = "";
         $lagtime = 0;
         $laglocus = "";
         $state = 2;
         # fall through and process $oneline
      }
   }
   else {                   # should never happen
      print $oneline . "\n";
      die "Unknown state [$state] working on log $logfn at $l\n";
      next;
   }
   if (substr($oneline,0,1) ne "(") {next;}
   $oneline =~ /^(\S+).*$/;          # extract locus part of line
   $locus = $1;
   if ($opt_z == 0) {                # distributed has four pieces
      $locus =~ /\((.*)\.(.*):(.*)\,\"(.*)\"\)/;
      next if index($1,"(") != -1;   # ignore weird case with embedded (
      $logtime = hex($1);
      $logtimehex = $1;
      $logthread = $2;
      $logunit = $3;
      $logentry = $4;
   }
   else {                            # z/OS has three pieces
      $locus =~ /\((.*):(.*)\,\"(.*)\"\)/;
      $logthread = $1;
      $logunit = $2;
      $logentry = $3;
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
         next if defined $toobigsitx{$ifiltsit};
         $toobigi++;
         $tx = $toobigi;
         $toobigsit[$tx] = $ifiltsit;
         $toobigsitx{$ifiltsit} = $tx;
         $toobigsize[$tx] = $ifiltsize;
         $toobigtbl[$tx] = $ifilttbl;
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
         if (index($rest,"written from") != 0) {
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
   next if substr($logunit,0,12) ne "kpxrpcrq.cpp";
   next if $logentry ne "IRA_NCS_Sample";
   $oneline =~ /^\((\S+)\)(.+)$/;
   $rest = $2;                       # Rcvd 1 rows sz 816 tbl *.UNIXOS req  <418500981,1490027440> node <evoapcprd:KUX>
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
   if ($opt_z == 0) {
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
}

if ($opt_z == 0) {
   $dur = $sitetime - $sitstime;
}
else {
   # calc based on $timestart/$timeend/$totsecs
   $timestart =~ /(\d+):(\d+):(\d+)\./;
   my $start_hour = $1;
   my $start_min = $2;
   my $start_sec = $3;
   $timeend =~ /(\d+):(\d+):(\d+)\./;
   my $end_hour = $1;
   my $end_min = $2;
   my $end_sec = $3;
   $dur = ($end_hour-$start_hour)*3600 + ($end_min-$start_min)*60 + ($end_sec-$start_sec) + $totsecs;
}

if ($dur == 0)  {
   print STDERR "Duration calculation is zero, setting to 1000\n";
   $dur = 1000;
}


# produce output report

$cnt = 0;
$cnt++;
print "TEMS Audit report v$gVersion\n";
$cnt++;
print "\n";
$cnt++;
print "Too Big Report\n";
$cnt++;
print "Situation,Table,FilterSize\n";
for ($i = 0; $i <= $toobigi; $i++) {
   $cnt++;
   $outl = $toobigsit[$i] . ",";
   $outl .= $toobigtbl[$i] . ",";
   $outl .= $toobigsize[$i] . ",";
   print $outl . "\n";
}
$cnt++;print "\n";

$cnt++;print "Summary Statistics\n";
$cnt++;print "Duration (seconds),,,$dur\n";
$cnt++;print "Total Count,,,$sitct_tot\n";
$cnt++;print "Total Rows,,,$sitrows_tot\n";
$cnt++;print "Total Result (bytes),,,$sitres_tot\n";
my $trespermin = int($sitres_tot / ($dur / 60));
$cnt++;print "Total Results per minute,,,$trespermin\n";
$cnt++;print "\n";

my $f;
my $crespermin = 0;

$cnt++;
print "Situation Summary Report\n";
$cnt++;
print "Situation,Table,Count,Rows,ResultBytes,Result/Min,Fraction,Cumulative%,MinResults,MaxResults,MaxNode\n";
foreach $f ( sort { $sitres[$sitx{$b}] <=> $sitres[$sitx{$a}] } keys %sitx ) {
   $i = $sitx{$f};
   $cnt++;
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
   $pfraction = sprintf "%.2f", $fraction;
   $outl .= $pfraction . "%,";
   $outl .= $sitrmin[$i] . ",";
   $outl .= $sitrmax[$i] . ",";
   $outl .= $sitrmaxnode[$i];
   print $outl . "\n";
}

$cnt++;
print "\n";

$cnt++;
print "Managed System Summary Report - non-HEARTBEAT situations\n";
$cnt++;
print "Node,Table,Count,Rows,ResultBytes,Result/Min,MinResults,MaxResults,MaxSit\n";
foreach $f ( sort { $manres[$manx{$b}] <=> $manres[$manx{$a}] } keys %manx ) {
   $i = $manx{$f};
   $cnt++;
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
   print $outl . "\n";
}
$cnt++;
$outl = "*total" . ",";
$outl .= $dur . ",";
$outl .= $sitct_tot . ",";
$outl .= $sitrows_tot . ",";
$outl .= $sitres_tot . ",";
$respermin = int($sitres_tot / ($dur / 60));
$outl .= $respermin;
print $outl . "\n";


if ($soapi != -1) {
   $cnt++;
   print "SOAP SQL Summary Report\n";
   $cnt++;
   print "IP,Count,SQL\n";
   foreach $f ( sort { $soapct[$soapx{$b}] <=> $soapct[$soapx{$a}] } keys %soapx ) {
      $i = $soapx{$f};
      $cnt++;
      $outl = $soapip[$i] . ",";
      $outl .= $soapct[$i] . ",";
      $csvdata = $soap[$i];
      $csvdata =~ s/\"/\"\"/g;
      $outl .= "\"" . $csvdata . "\"";
      print $outl . "\n";
   }
   $cnt++;
   $outl = "*total" . ",";
   $outl .= $soapct_tot . ",";
   print $outl . "\n";
}

my $total_hist_rows = 0;
my $total_hist_bytes = 0;
$hist_elapsed_time = $hist_max_time - $hist_min_time;
my $time_elapsed;

if ($histi != -1) {
   $cnt++;
   print "\n";
   print "Historical Export summary by object\n";
   $cnt++;
   print "Object,Table,Appl,Rowsize,Rows,Bytes,Bytes_Min,Cycles,MinRows,MaxRows,AvgRows,LastRows\n";
   foreach $f ( sort { $hist[$histx{$a}] cmp $hist[$histx{$b}] } keys %histx ) {
      $i = $histx{$f};
      my $rows_cycle = 0;
      $rows_cycle = int($hist_totrows[$i]/$hist_cycles[$i]) if $hist_cycles[$i] > 0;
      $cnt++;
      $outl = $hist[$i] . ",";
      $outl .= $hist_table[$i] . ",";
      $outl .= $hist_appl[$i] . ",";
      $outl .= $hist_rowsize[$i] . ",";
      $outl .= $hist_rows[$i] . ",";
      $outl .= $hist_bytes[$i] . ",";
      $outl .= int(($hist_bytes[$i]*60)/$hist_elapsed_time) . ",";
      $outl .= $hist_cycles[$i] . ",";
      $outl .= $hist_minrows[$i] . ",";
      $outl .= $hist_maxrows[$i] . ",";
      $outl .= $rows_cycle . ",";
      $outl .= $hist_lastrows[$i] . ",";
      print $outl . "\n";
      $total_hist_rows += $hist_rows[$i];
      $total_hist_bytes += $hist_bytes[$i];
   }
   $cnt++;
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   print $outl . "\n";
}


if ($histi != -1) {
   $cnt++;
   print "\n";
   print "Historical Export summary by time\n";
   $cnt++;
   print "Time,,,,Rows,Bytes,Secs,Bytes_min\n";
   foreach $f ( sort { $histtime[$histtimex{$a}] <=> $histtime[$histtimex{$b}] } keys %histtimex ) {
      $i = $histtimex{$f};
      $cnt++;
      $outl = $histtime[$i] . ",,,,";
      $outl .= $histtime_rows[$i] . ",";
      $outl .= $histtime_bytes[$i] . ",";
      $time_elapsed = $histtime_max_time[$i] - $histtime_min_time[$i] + 1;
      $outl .= $time_elapsed . ",";
      $outl .= int(($histtime_bytes[$i]*60)/$time_elapsed) . ",";
      print $outl . "\n";
   }
   $cnt++;
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   print $outl . "\n";
}

if ($histi != -1) {
   $cnt++;
   print "\n";
   print "Historical Export summary by Object and time\n";
   $cnt++;
   print "Object,Table,Appl,Rowsize,Rows,Bytes,Time\n";
#   foreach $f ( sort { $histobjectx{$a} cmp $histobjectx{$b} } keys %histobjectx ) {
   foreach $f ( sort keys %histobjectx ) {
      $i = $histobjectx{$f};
      $cnt++;
      $outl = $f . ",";
      $outl .= $histobject_table[$i] . ",";
      $outl .= $histobject_appl[$i] . ",";
      $outl .= $histobject_rowsize[$i] . ",";
      $outl .= $histobject_rows[$i] . ",";
      $outl .= $histobject_bytes[$i] . ",";
      $outl .= $histobject_time[$i] . ",";
      print $outl . "\n";
   }
   $cnt++;
   $outl = "*total" . "," . "$hist_elapsed_time" . ",,,";
   $outl .= $total_hist_rows . ",";
   $outl .= $total_hist_bytes . ",";
   print $outl . "\n";
}



print STDERR "Wrote $cnt lines\n";

# all done

exit 0;


sub open_kib {
   # get list of files
   if (defined $logbase) {
      $logpat = $logbase . '-.*\.log';
   } else {
      $logpat = $logfn
   }
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

   foreach $f ( sort { $todo{$a} <=> $todo{$b} } keys %todo ) {
      $segi += 1;
      $seg[$segi] = $f;
   }
}

sub read_kib {
   if ($segp == -1) {
      $segp = 0 if $segi < 4;
      $segp = 1 if $segi == 4;
      $segcurr = $seg[$segp];
      open(KIB, "<$segcurr") || die("Could not open log segment $segp $segcurr\n");
      print STDERR "working on $segp $segcurr\n" if $opt_v == 1;
   }
   $inline = <KIB>;
   return if defined $inline;
   close(KIB);
   $segp += 1;
   return if $segp > $segi;
   $segcurr = $seg[$segp];
   open(KIB, "<$segcurr") || die("Could not open log segment $segp $segcurr\n");
   print STDERR "working on $segp $segcurr\n" if $opt_v == 1;
   $inline = <KIB>;
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
    -h              Produce help message
    -z              z/OS RKLVLOG logfile

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
