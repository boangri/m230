#!/usr/bin/perl

use POSIX;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use DBI;
require '/home/askue/m230/system.conf';
$host = `hostname`;
chomp($host);
$DEV = $devices{$host};
# ===================================================================
# CONSTANT DECLARATION
# ===================================================================

$str;
$url = $AS_URL;
$DIR = "/home/askue/m230";
$RDIR = "/var/lib/rrd/askue";
$RRDTOOL = "/usr/bin/rrdtool";
$LIMIT = 30;
$CNT = 5;

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
  print "URL=$url\n";
  return $resp_data;
}
  
# ===================================================================
# Main
# ===================================================================

my (%wthr, $addr, $n, $a, $response, $var, $data);
my ($dbh, $sql, $sth, $sth2, $rv, @p, $st, $st2, $i, $cnt);

$dbh = DBI->connect("DBI:mysql:$db:$db_host:3306",$db_user,$db_pass);
if ( $DBI::errstr ne "" ) {
        print "Could not connect to MySQL, Error: $DBI::errstr\n";
}
$cnt = 0;
for $addr (keys %type) {
	$n = $ktp{$addr};
	$a = $type{$addr};
	$str = `$DIR/mon232 $addr 111111 /dev/$DEV`;
	if ($str) {
		$cnt++;
		$st = `date -u +%s`;
		$st -= ($st % 300);
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
        (FROM_UNIXTIME($st),$p[0],$p[1],$p[2],$p[3],$p[4],$p[5],$p[6],$p[7],
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
		#
        	# save data in RRD
		#
		for ($i = 1; $i < 35; $i++) {
                	$p[$i] = "null" if $p[$i] eq "";
                	$st .= $p[$i] eq "null" ? ":U": ":$p[$i]";
        	}
		$st2 = $st;
        	for (; $i < 38; $i++) {
                	$p[$i] = "null" if $p[$i] eq "";
                	$st2 .= $p[$i] eq "null" ? ":U": ":$p[$i]";
        	}
        	`$RRDTOOL update $RDIR/m230-$a$n.rrd $st`;
        	print "$RRDTOOL update $RDIR/m230-$a$n.rrd $st\n";
        	#`$RRDTOOL update $RDIR/errors-$a$n.rrd $st2`;
	}
}
$sth->finish;
print "Comitted $cnt records\n";

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
        toerr, crcerr, sec FROM mon230 WHERE sent = 0 ORDER BY ts LIMIT $LIMIT";
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
$cnt = 0;
my $nr = 0;
while($sth->fetch) {
	$nr++;
        $n = $ktp{$addr};
        $a = $type{$addr};
        $str = "$ts;$addr;$mv1;$mv2;$mv3;$mc1;$mc2;$mc3;$mf;$ma1;$ma2;$ma3;$mps;$mp1;$mp2;$mp3;$mqs;$mq1;$mq2;$mq3;$mss;$ms1;$ms2;$ms3;$mks;$mk1;$mk2;$mk3;$se1ai;$se1ae;$se1ri;$se1re;$se2ai;$se2ae;$se2ri;$se2re;$toerr;$crcerr;$sec";
        $data .= ($data ? "\&" : "") . "$a$n=$str"; 
        $cnt++;
        if($cnt == $CNT) {
                print "Data=$data\n";
                $response =  &post_url($url, $data);
                print "response=$response\n";
                if ($response =~ /success/) {
                        $sql = "UPDATE mon230 SET sent = 1 WHERE  sent = 0 ORDER BY ts LIMIT $cnt";
                        $sth2 = $dbh->prepare($sql);
                        $rv = $sth2->execute;
			$sth2->finish;
                        print "Updated $rv records\n";
                        $cnt = 0;
                        $data = "";
                } else {
                        print "fail\n";
                        exit;
                } 
        }
}
print "$nr records were found\n";
if($data) {
	print "extra CNT=$cnt\n";
        print "extra Data=$data\n";
        $response =  &post_url($url, $data);
        print "response=$response\n";
        if ($response =~ /success/) {
                $sql = "UPDATE mon230 SET sent = 1 WHERE  sent = 0 ORDER BY ts LIMIT $cnt";
                $sth2 = $dbh->prepare($sql);
                $rv = $sth2->execute;
		$sth2->finish;
                print "Updated $rv records\n";
	}
}
