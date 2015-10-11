use 5.014002;
use strict;
use warnings;

use CBitcoin::Message;
use CBitcoin::SPV;
use IO::Socket::INET;
$| = 1;

#use Test::More tests => 1;


my $spv = CBitcoin::SPV->new({
	'address' => '192.168.122.67',
	'port' => 8333,
	'isLocal' => 1
	
});

my $y;



eval{
	
	
	
	$y = $spv->add_peer('10.19.202.164','8333');
	
	my $socket = new IO::Socket::INET (
		PeerHost => '10.19.202.164',
		PeerPort => '8333',
		Proto => 'tcp',
	) or die "ERROR in Socket Creation : $!\n";

	warn $spv->peer('10.19.202.164','8333')->our_version;

	#syswrite($socket,$spv->peer('10.19.202.164','8333')->our_version);
	
	#my $buf;
	#while(sysread($socket,$buf,8192)){
#		warn "Buf=$buf\n";
#		close($socket);
#	}	
	
	
	warn "hello\n";

};
if($@){
	my $error = $@;
	die "Error=$error\n";
}

#my $y = CBitcoin::Message::getversion1(CBitcoin::SPV::ip_convert_to_binary('10.24.44.2'),'32',CBitcoin::SPV::ip_convert_to_binary('10.88.44.2'),'8333');




#ok(1) || print "Bail out!";
