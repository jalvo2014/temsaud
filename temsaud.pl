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
# tested on Windows Activestate 5.12.2
#

$gVersion = 0.600000;

# $DB::single=2;   # remember debug breakpoint

# CPAN packages used
# none

foreach $f (@ARGV) {
    if ($f eq '-h') { $opt_h = 1}
    elsif ($f eq '-z') { $opt_z = 1}
    else { $logfn = $f}
}

if (!defined $opt_h) {$opt_h = 0};
if (!defined $opt_z) {$opt_z = 0};
if (!defined $logfn) {die "log file not defined\n"}

#$gWin = (-e "C:/") ? 1 : 0;       # determine Windows versus Linux/Unix for detail settings

&GiveHelp if ( $opt_h );           # print help and exit

# This is a typical log scraping program. The log data looks like this
#
# Distributed with a situation:
# (4D81D817.0000-A17:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 220 tbl *.RNODESTS req HEARTBEAT <219213376,1892681576> node <Primary:INMUM01B2JTP01:NT>
#
# Distributed without situation
# (4D81D81A.0000-A1A:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 816 tbl *.UNIXOS req  <418500981,1490027440> node <evoapcprd:KUX>
#
# Distributed "Too Big"
# (4D6F5BC2.0004-F:kpxreqds.cpp,1695,"buildThresholdsFilterObject") Filter object too big (65888 + 15220),Table UNIXDISK Situation IBM_DBA_ArchiveMountPt_Critical.
#
# z/OS RKLVLOG lines contain the same information but often split into two lines
# and the timestamp is in a different form.
#  2011.080 14:53:59.78 (005E-D61DDF8B:kpxrpcrq.cpp,749,"IRA_NCS_Sample") Rcvd 1 rows sz 220 tbl *.RNODESTS req HEARTBEAT <565183706,5
#  2011.080 14:53:59.79 65183700> node <IRAM:S8CMS1:SYS:STORAGE         >
#
# the data is identical otherwise
#
# To manage the differences, a small state engine is used.
#  When set to 3 based on absence of -z option, the lines are processed directly
#
#  For RKLVLOG case the state is set to 0 at outset.
#  When 0, the first line is examined. RKLVLOGs can be in two forms. When
#  collected as a SYSOUT file, there is an initial printer control character
#  of "1", meaning skip to the top of page. In that case all the lines have
#  a printer control character of blank. If recogonized a variable $offset
#  is set to value o1.
#
#  The second form is when the RKLVLOG is written directly to a disk file.
#  In this case the printer control characters are absent. For that case the
#  variable $offset is set to 0. When getting the data, $offset is used
#  calculations.
#
#  After state 0, state 1 is entered.
#
# When state=1, the input record is checked for the expected kpxrpcrq.cpp
# value. If not, the next record is processed. If found, the partial line
# is captured and the state is set to 2. The timestamp is also captured.
# then the next record is processed.
#
# When state=2, the second part of the data is captured. The data is assembled
# as if it was a distributed record - absent the distributed timestamp. The
# state is set to 1 and then the record is processed.
#
# Processing is typical log scraping. The target is identified, an associative
# array is used to look up prior cases, and the data is recorded. At the end
# the accumulated data is printed to standard output.

open(KIB, "< $logfn") || die("Could not open log $logfn\n");

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

my $state = 0;       # 0=look for offset, 1=look for zos initial record, 2=look for zos continuation, 3=distributed log
my $partline = "";          # partial line for z/OS RKLVLOG
my $dateline = "";          # date portion of timestamp
my $timeline = "";          # time portion of timestamp
my $offset = 0;             # track sysout print versus disk flavor of RKLVLOG
my $totsecs = 0;            # added to when time boundary crossed

if ($opt_z == 0) {$state = 3}

foreach $oneline (<KIB>)
{
   $l++;
# following two lines are used to debug errors. First you flood the
# output with the working on log lines, while merging stdout and stderr
# with  1>xxx 2>&1. From that you determine what the line number was
# before the faulting processing. Next you turn that off and set the conditional
# test for debugging and test away.
#   print STDERR "working on log $logfn at $l\n";
#  if ($l == 44) { $DB::single=2;}

   chomp($oneline);
   if ($state == 0) {                       # state 0 - detect print or disk version of sysout file
      if (substr($oneline,0,1) eq "1") {
         $offset = 1;
      }
      $state = 1;
      $partline = "";
      $timeline = "";
      next;
   }
   elsif ($state == 1) {                    # state 1 = look for part one of target lines
      next if length($oneline) < 36+12+$offset;
      if (substr($oneline,36+$offset,12) eq "kpxrpcrq.cpp") {
         $dateline = substr($oneline,$offset,8);
         $timeline = substr($oneline,9+$offset,11);
         $partline = substr($oneline,21+$offset);
         $state = 2;
      }
#todo - need check for kpxrcds.cpp lines. Need test case to verify
      next;
   }
   elsif ($state == 2) {                    # state 2 = collect second part of line
      $partline .=  substr($oneline,21+$offset);
      $oneline = $partline;

      # accumulate first and last timestamps
      if ($timestart eq "") {
         $timestart = $timeline;
      }
      if ($timeend eq "") {
         $timeend = $timeline;
      }

      # if timestamp wraps, that is a day boundary so add 24 hours of seconds
      if ($timeend gt $timeline) {
         $totsecs += 24*60*60;
      }
      $timeend = $timeline;
      $state = 1;
   }
   elsif ($state == 3) {                    # state = 3 distributed log - no filtering
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
   if (substr($logunit,0,12) ne "kpxrpcds.cpp") {
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
         next;
      }
   }
   next if substr($logunit,0,12) ne "kpxrpcrq.cpp";
   next if $logentry ne "IRA_NCS_Sample";
   $oneline =~ /^\((\S+)\)(.+)$/;
   $rest = $2;                       # Rcvd 1 rows sz 816 tbl *.UNIXOS req  <418500981,1490027440> node <evoapcprd:KUX>
   $rest =~ /(\S+) (\d+) rows sz (\d+) tbl (\S+) req (.*)/;
   next if $1 ne "Rcvd";
   $irows = $2;
   $isize = $3;
   $itbl = $4;
   $rest = $5;
   if (substr($rest,0,2) eq " <") {
      $isit = "(NULL)";
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

   next if $isit eq "HEARTBEAT";

   if (!defined $manx{$inode}) {      # if newly observed node, set up initial values and associative array
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
   else {
      $mx = $manx{$inode};
   }
   $manct[$mx] += 1;
   $manrows[$mx] += $irows;
   if ($insize != 0) {
      if ($insize < $manrmin[$mx]) {
         $manrmin[$mx] = $insize;
      }
   }
   if ($insize > $manrmax[$mx]) {
         $manrmax[$mx] = $insize;
         $manrmaxsit[$mx] = $isit;
      }
   $manres[$mx] += $insize;

}
close(KIB);

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
$cnt++;
print "\n";

$cnt++;
print "Situation Summary Report\n";
print "Situation,Table,Count,Rows,ResultBytes,Result/Min,MinResults,MaxResults,MaxNode\n";
for ($i = 0; $i <= $siti; $i++) {
   $cnt++;
   $outl = $sit[$i] . ",";
   $outl .= $sittbl[$i] . ",";
   $outl .= $sitct[$i] . ",";
   $outl .= $sitrows[$i] . ",";
   $outl .= $sitres[$i] . ",";
   $respermin = int($sitres[$i] / ($dur / 60));
   $outl .= $respermin . ",";
   $outl .= $sitrmin[$i] . ",";
   $outl .= $sitrmax[$i] . ",";
   $outl .= $sitrmaxnode[$i];
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

$cnt++;
print "\n";

$cnt++;
print "Managed System Summary Report - non-HEARTBEAT situations\n";
print "Node,Table,Count,Rows,ResultBytes,Result/Min,MinResults,MaxResults,MaxSit\n";
for ($i = 0; $i <= $mani; $i++) {
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

print STDERR "Wrote $cnt lines\n";

# all done

exit 0;

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
