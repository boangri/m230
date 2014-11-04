#!/usr/bin/perl

use POSIX;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use DBI;
require 'system.conf';
$host = `hostname`;
chomp($host);
$DEV = $devices{$host};
# ===================================================================
# CONSTANT DECLARATION
# ===================================================================

$str;
$DIR = "/home/askue/m230";
$RDIR = "/var/lib/rrd/askue";
$RRDTOOL = "/usr/bin/rrdtool";

%type = %{$ktplist{$host}};
	
#----------
# post_url : Use http to post the url
#----------
sub  post_url ($) {

  my ($url, $ua, $h, $req, $resp, $resp_data, $data);

  ($url, $data) = @_;

# Comment out the fields below for testing, and uncomment the print statement
  $ua = LWP::UserAgent->new;
  $h = HTTP::Headers->new;
  $h->header('Content-Type' => 'text/plain');  # set
  $req = HTTP::Request->new(POST => $url, $h, $data);
  $resp = $ua->simple_request($req);
  $resp_data = $resp->content;

# For troubleshooting:
#  print "$url\n";
  return $resp_data;
}
  
# ===================================================================
# Main
# ===================================================================

my (%wthr, $addr, $n, $a, $url, $response, $var, $data);
my ($dbh, $sql, $sth, $rv, @p);

$dbh = DBI->connect("DBI:mysql:$db:$db_host:3306",$db_user,$db_pass);
if ( $DBI::errstr ne "" ) {
        print "Could not connect to MySQL, Error: $DBI::errstr\n";
}

for $addr (keys %type) {
	$n = $ktp{$addr};
	$a = $type{$addr};
	$str = `$DIR/mon232 $addr 111111 /dev/$DEV`;
	if ($str) {
		@p = split(/;/, $str);
		$sql = "INSERT INTO mon230(ts, addr, mv1, mv2, mv3, mc1, mc2, mc3, mf,
        ma1, ma2, ma3,
        mps, mp1, mp2, mp3,
        mqs, mq1, mq2, mq3,
        mss, ms1, ms2, ms3,
        mks, mk1, mk2, mk3,
        se1ai, se1ae, se1ri, se1re,
        se2ai, se2ae, se2ri, se2re,
        toerr, crcerr, sec) VALUES
        (NOW(),$p[0],$p[1],$p[2],$p[3],$p[4],$p[5],$p[6],$p[7],
        $p[8],$p[9],$p[10],
        $p[11],$p[12],$p[13],$p[14],
        $p[15],$p[16],$p[17],$p[18],
        $p[19],$p[20],$p[21],$p[22],
        $p[23],$p[24],$p[25],$p[26],
        $p[27],$p[28],$p[29],$p[30],
        $p[31],$p[32],$p[33],$p[34],
        $p[35],$p[36],$p[37])";
		$sth = $dbh->prepare($sql);
		$rv = $sth->execute;
	}
}
$sth->finish;

my ($ts, $addr, $mv1, $mv2, $mv3, $mc1, $mc2, $mc3, $mf,
        $ma1, $ma2, $ma3, 
        $mps, $mp1, $mp2, $mp3, 
        $mqs, $mq1, $mq2, $mq3,
        $mss, $ms1, $ms2, $ms3,
        $mks, $mk1, $mk2, $mk3,
        $se1ai, $se1ae, $se1ri, $se1re,
        $se2ai, $se2ae, $se2ri, $se2re,
        $toerr, $crcerr, $sec);
$sql = "SELECT UNIX_TIMESTAMP(ts), addr, mv1, mv2, mv3, mc1, mc2, mc3, mf,
        ma1, ma2, ma3,
        mps, mp1, mp2, mp3,
        mqs, mq1, mq2, mq3,
        mss, ms1, ms2, ms3,
        mks, mk1, mk2, mk3,
        se1ai, se1ae, se1ri, se1re,
        se2ai, se2ae, se2ri, se2re,
        toerr, crcerr, sec FROM mon230 WHERE sent = 0 ORDER BY ts LIMIT 1000000";
$sth = $dbh->prepare($sql);
$rv = $sth->execute;
$sth->bind_columns( {}, \($ts, $addr, $mv1, $mv2, $mv3, $mc1, $mc2, $mc3, $mf,
        $ma1, $ma2, $ma3,
        $mps, $mp1, $mp2, $mp3,
        $mqs, $mq1, $mq2, $mq3,
        $mss, $ms1, $ms2, $ms3,
        $mks, $mk1, $mk2, $mk3,
        $se1ai, $se1ae, $se1ri, $se1re,
        $se2ai, $se2ae, $se2ri, $se2re,
        $toerr, $crcerr, $sec));
$data = "";
my $cnt = 0;
while($sth->fetch) {
	$cnt++;
	$n = $ktp{$addr};
	$a = $type{$addr};
	$str = "$ts;$addr;$mv1;$mv2;$mv3;$mc1;$mc2;$mc3;$mf;$ma1;$ma2;$ma3;$mps;$mp1;$mp2;$mp3;$mqs;$mq1;$mq2;$mq3;$mss;$ms1;$ms2;$ms3;$mks;$mk1;$mk2;$mk3;$se1ai;$se1ae;$se1ri;$se1re;$se2ai;$se2ae;$se2ri;$se2re;$toerr;$crcerr;$sec";
# rrdtool
	my ($st, $st2, $i, @q);
        @q = split(/;/, $str);
        $st = $q[0];
        $st2 = $q[0];
        shift @q;
        for ($i = 1; $i < 35; $i++) {
                $q[$i] = "null" if $q[$i] eq "";
                $st .= $q[$i] eq "null" ? ":U": ":$q[$i]";
        }
        for (; $i < 38; $i++) {
                $q[$i] = "null" if $q[$i] eq "";
                $st2 .= $q[$i] eq "null" ? ":U": ":$q[$i]";
        }
##        `$RRDTOOL update $RDIR/m230-$a$n.rrd $st`;
        print "$RRDTOOL update $RDIR/m230-$a$n.rrd $st\n";
##        `$RRDTOOL update $RDIR/errors-$a$n.rrd $st2`;
# rrdtool
	if($cnt <= 100) {
		$data .= ($data ? "\&" : "") . "$a$n=$str"; 
	}
}
print "Data=$data\n";

$url = $AS_URL;
$response =  &post_url($url, $data);
print "response=$response\n";
if ($response =~ /success/) {
  $sql = "UPDATE mon230 SET sent = 1 WHERE  sent = 0 ORDER BY ts LIMIT 100";
  $sth = $dbh->prepare($sql);
  $rv = $sth->execute;
  print "Updated $rv records\n";
} 
