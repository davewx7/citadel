use strict;

my $NumGames = 100;
my @dirs = ();
my @bots = ();

while(my $arg = shift @ARGV) {
	if($arg eq '--games') {
		$NumGames = shift @ARGV;
	} else {
		push @bots, $arg;
		push @dirs, 'modules/Citadel/evo/' . $arg;
	}
}

die "Usage $0 <dir1> <dir2>" unless $#dirs == 1;

sub get_bots_in_dir($) {
	my $dir = shift @_;

	my @res = ();

	open FILES, "ls -1 $dir/*.cfg |" or die;

	while(my $fname = <FILES>) {
		chomp $fname;
		$fname =~ s/.*?evo/evo/;
		push @res, $fname;
	}

	close FILES;

	return @res;
}

my @bots_a = &get_bots_in_dir($dirs[0]);
my @bots_b = &get_bots_in_dir($dirs[1]);

@bots_a or die;
@bots_b or die;

print STDERR "player 1 bots: @bots_a\n";
print STDERR "player 2 bots: @bots_b\n";

my $wina = 0;
my $winb = 0;

for(my $n = 0; $n < $NumGames; ++$n) {
	my $bot_a = $bots_a[int(rand($#bots_a))];
	my $bot_b = $bots_b[int(rand($#bots_b))];

	my @command = ('./anura', '--tbs_server_delay_ms=1', '--tbs_server_heartbeat_freq=1', '--tbs_bot_delay_ms=1', '--tbs_game_exit_on_winner', '--module=Citadel', '--tbs-server', '--utility=tbs_bot_game', '--request', "\"{type: 'create_game', game_type: 'citadel', users: [{user: 'a', bot: true, bot_type: 'evolutionary', args: {rules: '$bot_a'}, session_id: 1}, {user: 'b', bot: true, bot_type: 'evolutionary', args: {rules: '$bot_b'}, session_id: 2}]}\"");

	my $command = join ' ', @command;
	$command .= " > /tmp/result.$$";

	my $winner = -1;

	system($command);

	my $found = 0;

	open RESULT, "/tmp/result.$$" or die;
	while(my $line = <RESULT>) {
		if($line =~ /WINNER: 0/) {
			++$wina;
			$found = 1;
		}
		if($line =~ /WINNER: 1/) {
			++$winb;
			$found = 1;
		}
	}
	close RESULT;

	#die "/tmp/result.$$" unless $found;

	unlink("/tmp/result.$$");
}

print "CHALLENGE " . $bots[0] . " vs " . $bots[1] . ": $wina - $winb\n";
