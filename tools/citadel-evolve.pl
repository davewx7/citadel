#Run this script from the base Anura directory with the citadel module
#installed. It will run a set of evolutionary bots against each other,
#evolving them each generation.
use strict;
use List::Util qw( shuffle );
use Time::HiRes qw/ time sleep /;
use IO::Select;
use POSIX ":sys_wait_h";

my $NumBots = 256;
my $ModuleName = 'citadel';

my $exename = './anura';
while(my $arg = shift @ARGV) {
	if($arg eq '--exename') {
		$exename = shift @ARGV or die "could not find exename after --exename";
	} elsif($arg eq '--module') {
		$ModuleName = shift @ARGV or die "Could not find modulename after --module";
	} else {
		die "unrecognized argument $arg";
	}
}

my $DataDir = "./modules/$ModuleName/evo/";

my @BotSegments = (
	{begin => 0, end => 127, school => 'food',
	 wins => 0, losses => 0, total_wins => 0, total_losses => 0},
	{begin => 128, end => 191, school => 'faith',
	 wins => 0, losses => 0, total_wins => 0, total_losses => 0},
	{begin => 192, end => 256, school => 'blood',
	 wins => 0, losses => 0, total_wins => 0, total_losses => 0},
);

sub in_same_segment($$) {
	my $a = shift @_;
	my $b = shift @_;

	foreach my $segment (@BotSegments) {
		if($a >= $segment->{begin} and $a <= $segment->{end} and
		   $b >= $segment->{begin} and $b <= $segment->{end}) {
			return 1;
		}
	}

	return 0;
}

sub get_segment($) {
	my $a = shift @_;

	foreach my $segment (@BotSegments) {
		if($a >= $segment->{begin} and $a <= $segment->{end}) {
			return $segment;
		}
	}

	return 0;
}

for(my $niteration = 0; ; ++$niteration) {
	my %valid_cards = ();

	foreach my $segment (@BotSegments) {
		$segment->{wins} = 0;
		$segment->{losses} = 0;
	}

	foreach my $school (('food', 'faith', 'blood')) {
		my @valid_cards = ();
		open CARDS, "<modules/$ModuleName/data/cards-$school.cfg" or die "$!";
		while(my $line = <CARDS>) {
			chomp $line;
			if($line =~ /^\s+"[^"]+": \{\s*$/) {
				$line = <CARDS>;
				if(my ($card) = $line =~ /^\s*name: ("[^"]+")/) {
					push @valid_cards, $card;
				}
			} elsif($line =~ /token:.*true/) {
				pop @valid_cards;
			}
		}

		close CARDS;
		@valid_cards or die "could not parse valid cards";

		$valid_cards{$school} = \@valid_cards;
		print "VALID CARDS $school: " . (join ',', @valid_cards) . "\n";
	}

	my $start_iteration = time;

	my $retire_iter = $niteration+1;
	while($retire_iter%50 == 0 and (-d "$DataDir/retired$retire_iter")) {
		$retire_iter += 50;
	}

	my $NumThreads = 4;

	if($retire_iter%50 == 0) {
		system("mkdir $DataDir/retired$retire_iter");
	}
	my @items = shuffle (0..($NumBots-1));
	my @original_items = @items;
	my $ncommand = 0;
	my @tasks = ();
	while(@items or @tasks) {
		while(scalar(@tasks) < $NumThreads and @items) {

			my $bota = shift @items;
			my $botb = shift @items;

			my $child_pid = fork;
			$child_pid >= 0 or die "DIE: could not fork: $!";

			if($child_pid == 0) {
				my $fnamea = 'evo/evolution' . $bota . '.cfg';
				my $fnameb = 'evo/evolution' . $botb . '.cfg';
				my @command = ($exename, '--write-backed-maps', '--tbs_server_delay_ms=1', '--tbs_server_heartbeat_freq=1', '--tbs_bot_delay_ms=1', '--tbs_game_exit_on_winner', "--module=$ModuleName", '--tbs-server', '--utility=tbs_bot_game', '--request', "{type: 'create_game', game_type: 'citadel', users: [{user: 'a', bot: true, bot_type: 'evolutionary', args: {rules: '$fnamea'}, session_id: 1}, {user: 'b', bot: true, bot_type: 'evolutionary', args: {rules: '$fnameb'}, session_id: 2}]}");

				open STDOUT, ">command-$ncommand" or die "$!";

				my $command_str = join ' ', @command;
				print STDERR "PERL: EXEC $ncommand/$NumBots: $command_str\n";

				exec @command;
				die "PERL: couldn't exec: $!";
			}

			print STDERR "PROC: CREATE $child_pid\n";

			push @tasks, {id => $ncommand, pid => $child_pid, timeout => time};
			++$ncommand;
		}

		print STDERR "PERL: TASKS OUTSTANDING: " . scalar(@tasks) . "\n";

		sleep 0.2;

		my $starting_ntasks = scalar(@tasks);
		for(my $n = 0; $n != $starting_ntasks; ++$n) {
			my $task = shift @tasks;
			my $result = waitpid($task->{pid}, WNOHANG);
			if($result <= 0) {
				if(time > $task->{timeout} + 40) {
					print STDERR "PERL: TIMEOUT OF " . $task->{pid} . ": KILLED\n";
					system("kill -9 " . $task->{pid});
					print STDERR "PROC: KILL " . $task->{pid} . "\n";
					waitpid($task->{pid}, 0) or die "DIE: task wouldn't die: $!";
				} else {
					push @tasks, $task;
				}
			} else {
				print STDERR "PROC: COMPLETE $result\n";
				my $ncommand = $task->{id};
				my $winner_line = 'NO WINNER LINE';
				open INPUT, "<command-$ncommand" or die "DIE: could not open command-$ncommand: $!";
				while(my $line = <INPUT>) {
					if($line =~ /^WINNER: /) {
						chomp $line;
						$winner_line = $line;
					}
				}
				close INPUT;
				print STDERR "PERL: TASK " . $task->{pid} . " COMPLETED IN " . (time - $task->{timeout}) . "s OUTPUT: command-$ncommand WINNER LINE: $winner_line\n";

				print STDERR "NO WINNER LINE\n" if $winner_line eq 'NO WINNER LINE';
				#die if $winner_line eq 'NO WINNER LINE';
			}
		}
	}

	print "CLEANING UP ITERATION $niteration...\n";

	$ncommand = 0;

	my $last_winner;

	my @winners = ();
	my @losers = ();

	@items = @original_items;
	while(@items) {
		my $bota = shift @items;
		my $botb = shift @items;

		my $victor = -1;

		open INPUT, "<command-$ncommand" or die "DIE: could not open command-$ncommand: $!";
		++$ncommand;
		while(my $line = <INPUT>) {
			if($line =~ /WINNER: 0/) {
				$victor = 0;
			} elsif($line =~ /WINNER: 1/) {
				$victor = 1;
			}
		}

		close INPUt;

		if($victor == 0) {
			print "$bota beats $botb\n";
			push @winners, $bota;
			push @losers, $botb;
		} elsif($victor == 1) {
			print "$botb beats $bota\n";
			push @winners, $botb;
			push @losers, $bota;
		} elsif($victor == -1) {
			print "$botb ties $bota\n";

			push @losers, $bota;
			push @losers, $botb;

		} else {
			next;
		}
	}

	foreach my $item (@winners) {
		my $segment = &get_segment($item);
		$segment->{wins}++;
		$segment->{total_wins}++;
	}

	foreach my $item (@losers) {
		my $segment = &get_segment($item);
		$segment->{losses}++;
		$segment->{total_losses}++;
	}

	foreach my $segment (@BotSegments) {
		my $school = $segment->{school};
		my $wins = $segment->{wins};
		my $losses = $segment->{losses};
		my $total_wins = $segment->{total_wins};
		my $total_losses = $segment->{total_losses};

		my $percent = int(100*$wins / ($wins+$losses)) . '%';
		my $total_percent = int(100*$total_wins / ($total_wins+$total_losses)) . '%';

		print "SCHOOL: $school record: $wins/$losses ($percent) all-time: $total_wins/$total_losses ($total_percent)\n";
	}

	while(@losers) {
		my $loser = shift @losers;
		my $winner;
		my $ncount = 0;
		while(1) {
			$winner = shift @winners;
			push @winners, $winner;
			last if &in_same_segment($winner, $loser);

			die if $ncount > scalar(@winners);
			++$ncount;
		}

		my $fname_winner = "$DataDir/evolution" . $winner . '.cfg';
		my $fname_loser = "$DataDir/evolution" . $loser . '.cfg';

		my $segment = &get_segment($winner);

		if($retire_iter%50 == 0) {
			system("mv $fname_loser $DataDir/retired$retire_iter");
		} else {
			system("rm $fname_loser");
		}

		my %used_patterns = ();
		my $ntotal_patterns = 0;
		my $nused_patterns = 0;

		open WINNER_STATS, "<$fname_winner.stats" or die "DIE: $!";
		while(my $line = <WINNER_STATS>) {
			if(my ($pattern) = $line =~ /"([^"]+)": \{/) {
				++$ntotal_patterns;
				while(my $info = <WINNER_STATS>) {
					if($info =~ /last_session_reads/) {
						chomp $info;
						$nused_patterns++ unless $info =~ /: 0,/;
						$used_patterns{$pattern} = 1 unless $info =~ /: 0,/;
						#print STDERR "USED PATTERN: ($pattern)\n" unless $info =~ /: 0,/;
						last;
					}
				}
			}
		}

		close WINNER_STATS;

		print "BOT USED $nused_patterns/$ntotal_patterns PATTERNS\n";

		my %function_patterns = ();

		open WINNER, "<$fname_winner" or die "DIE: $!";
		open LOSER, ">$fname_loser" or die "DIE: $!";
		print "REPLICATING $fname_winner to $fname_loser\n";
		while(my $line = <WINNER>) {
			my $EvolveDecks = 0;
			if($EvolveDecks and (my ($deck) = $line =~ /"deck": \[(.*)\]/)) {
				print STDERR "PERL: FOUND DECK: $deck\n";

				my @deck = ();
				while(my ($card) = $deck =~ /^("[^"]+")/) {
					$deck =~ s/^"[^"]+"//;
					$deck =~ s/^,//;
					push @deck, $card;
				}


				scalar(@deck) == 23 or die (join ',', @deck) . " DECK: $deck LINE: $line";

				my %counts = ();
				foreach my $card (@deck) {
					$counts{$card}++;
				}

				for(my $n = 0; $n != scalar(@deck); ++$n) {
					if(rand() < 0.025) {
						my @valid_cards = @{$valid_cards{$segment->{school}}};
						my $new_card = $valid_cards[int(rand(@valid_cards))];
						$deck[$n] = $new_card unless $counts{$new_card} >= 3;
						print STDERR "PERL: REPLACE CARD: $new_card\n";
					}
				}

				$deck = join ',', @deck;
				print LOSER qq("deck": [$deck],\n);
			} elsif(my ($pattern) = $line =~ /"(.*)": -?[0-9]+/) {
				chomp $line;
				my ($key, $value) = $line =~ /(.*".*": ?)(-?[0-9]+)/ or die "DIE: $line: $!";
				print STDERR "DID MUTATE: $pattern\n" if $used_patterns{$pattern};
				print STDERR "DID NOT MUTATE: ($pattern)\n" unless $used_patterns{$pattern};
				$value += int(rand(100)-50) if $used_patterns{$pattern} and $pattern !~ /EVAL /;

				if(my ($xvar) = $pattern =~ / var (-?\d+)/) {
					my $base_pattern = $pattern;
					$base_pattern =~ s/ var -?\d+/ var /;

					$function_patterns{$base_pattern} = [] unless $function_patterns{$base_pattern};
					my $fn = $function_patterns{$base_pattern};
					push @$fn, {x => $xvar, y => $value, immutable => $used_patterns{$pattern}, pattern => $pattern};
				}

				print LOSER "$key$value,\n";
			} else {
				print LOSER $line;
			}
		}

		close LOSER;
		close WINNER;

		my %function_pattern_overrides = ();

		foreach my $key (keys %function_patterns) {
			my $fn = $function_patterns{$key};
			@$fn = sort {$a->{x} <=> $b->{x}} @$fn;

			print STDERR "STARTING PATTERN: $key\n";
			foreach my $item (@$fn) {
				print STDERR "  " . $item->{x} . ": " . $item->{y} . "\n";
			}

			print STDERR "NEW PATTERN\n";

			my ($min, $max) = ('', '');
			my ($min_xpos, $max_xpos) = (0, 0);
			my $index = 0;
			foreach my $item (@$fn) {
				if($max eq '' or $item->{y} > $max) {
					$max = $item->{y};
					$max_xpos = $index;
				}

				if($min eq '' or $item->{y} < $min) {
					$min = $item->{y};
					$min_xpos = $index;
				}
				++$index;
			}

			my $last_index = scalar(@$fn)-1;

			if($min_xpos != 0 and $min_xpos != $last_index and
			   $max_xpos != 0 and $max_xpos != $last_index) {
				if($min_xpos < $max_xpos) {
					for(my $x = 0; $x <= $min_xpos; ++$x) {
						my $item = $fn->[$x];
						if($item->{immutable} and $item->{y} > $min) {
							$min = $item->{y};
							$x = 0;
						} else {
							$item->{y} = $min;
						}
					}

					for(my $x = $max_xpos; $x < scalar(@$fn); ++$x) {
						my $item = $fn->[$x];
						if($item->{immutable} and $item->{y} < $max) {
							$max = $item->{y};
							$x = $max_xpos;
						} else {
							$item->{y} = $max;
						}
					}
				} else {
					for(my $x = 0; $x <= $max_xpos; ++$x) {
						my $item = $fn->[$x];
						if($item->{immutable} and $item->{y} < $max) {
							$max = $item->{y};
							$x = 0;
						} else {
							$item->{y} = $max;
						}
					}

					for(my $x = $min_xpos; $x < scalar(@$fn); ++$x) {
						my $item = $fn->[$x];
						if($item->{immutable} and $item->{y} > $min) {
							$min = $item->{y};
							$x = $min_xpos;
						} else {
							$item->{y} = $min;
						}
					}
				}

				my ($begin, $end) = ($max_xpos, $min_xpos);
				($begin, $end) = ($min_xpos, $max_xpos) if $min_xpos < $max_xpos;

				if($max_xpos > $min_xpos) {
					for(my $x = $begin+1; $x < $end; ++$x) {
						my $cur = $fn->[$x];
						my $prev = $fn->[$x-1];
						if($max_xpos > $min_xpos and $cur->{y} < $prev->{y} or
						   $max_xpos < $min_xpos and $cur->{y} > $prev->{y}) {
							if($cur->{immutable}) {
								$prev->{y} = $cur->{y};
							} else {
								$cur->{y} = $prev->{y};
							}
						}
					}
				}
			}
			
			my $first = $fn->[0];
			my $last = $fn->[$last_index];
			my @segments = (0, $min_xpos, $max_xpos, $last_index);
			my @values = ($min, $max);
			if($min_xpos > $max_xpos) {
				@segments = reverse @segments;
				@values = reverse @values;
			}

			unshift @values, $first->{y};
			push @values, $last->{y};

			my $x = 0;
			for(my $n = 1; $n != scalar(@segments); ++$n) {
				my $begin = $segments[$n-1];
				my $end = $segments[$n];
				my $y1 = $values[$n-1];
				my $y2 = $values[$n];
				my $going_up = $y1 < $y2;

				for(my $x = $begin+1; $x < $end; ++$x) {
					my $cur = $fn->[$x];
					my $prev = $fn->[$x-1];
					if($going_up and $cur->{y} < $prev->{y} or
					   !$going_up and $cur->{y} > $prev->{y}) {
						if($cur->{immutable}) {
							$prev->{y} = $cur->{y};
						} else {
							$cur->{y} = $prev->{y};
						}

						for(my $n = 0; $n < $x; ++$n) {
							my $item = $fn->[$n];
							if($going_up and $item->{y} > $cur->{y} or
							  !$going_up and $item->{y} < $cur->{y}) {
								$item->{y} = $cur->{y};
							}
						}
					}
				}
			}

			foreach my $item (@$fn) {
				print STDERR "  " . $item->{x} . ": " . $item->{y} . "\n";
			}

			print STDERR "---\n";

			foreach my $item (@$fn) {
				$function_pattern_overrides{$item->{pattern}} = $item->{y};
			}
		}

		if(%function_pattern_overrides) {
			open LOSER, "<$fname_loser" or die "DIE: $!";
			my @lines = <LOSER>;
			close LOSER;

			open LOSER, ">$fname_loser" or die "DIE: $!";

			foreach my $line (@lines) {
				if(my ($pattern) = $line =~ /"(.*)": -?[0-9]+/) {
					if($function_pattern_overrides{$pattern}) {
						my ($key, $value) = $line =~ /(.*".*": ?)(-?[0-9]+)/ or die "DIE: $line: $!";
						$line = $key . $function_pattern_overrides{$pattern} . ",\n";
					}
				}

				print LOSER $line;
			}
			close LOSER;
		}
	}

	if($retire_iter%50 == 0) {
		my @compares = (50, 200, 1000);
		print "Running ancestral comparisons $retire_iter\n";
		foreach my $cmp (@compares) {
			my $ancestor = $retire_iter - $cmp;

			my $dira ="$DataDir/retired$retire_iter";
			my $dirb = "$DataDir/retired$ancestor";

			if((-d $dira) and (-d $dirb)) {
				print "Running comparison: $dira vs $dirb...\n";
				system("perl modules/Citadel/tools/evolutionary-challenge.pl retired$retire_iter retired$ancestor");
				system("perl modules/Citadel/tools/evolutionary-challenge.pl retired$ancestor retired$retire_iter");
			}
		}
		print "Done running ancestral comparisons $retire_iter\n";
	}

	#system("killall -9 game");
	print "ITERATION $niteration COMPLETE IN " . (time - $start_iteration) . "s\n";
}
