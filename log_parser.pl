#!/usr/bin/env perl
use strict;
use warnings;
use v5.30;
use DBI;
use utf8;
use experimental 'smartmatch'; # про List::Util 'any' знаю.

$| = 1;

use File::Slurp qw(read_file);

my @file_data = read_file('out', chomp=>1);

my $messages;
my $logs;

foreach (@file_data) {
	my @line = split /\s/, $_, 6;

	if ($line[3] eq '<=') {
		push $messages->{'created'}->@*, (join ' ', $line[0], $line[1]);
		my ($id) = $line[5] =~ / id=(\d+)/;
		push $messages->{'id'    }->@*, $id;
		push $messages->{'int_id'}->@*, $line[2];
		push $messages->{'str'   }->@*, substr($_, 20);
	}
	else {
		push $logs->{'created'}->@*, (join ' ', $line[0], $line[1]);
		push $logs->{'int_id' }->@*, $line[2];
		push $logs->{'str'    }->@*, substr($_, 20);

		if ($line[3] ~~ ['=>', '->', '**', '==']) {
			push $logs->{'address'}->@*, $line[4];
		} else {
			push $logs->{'address'}->@*, undef;
		}
	}
}

my $db_name = 'test';
my ($user, $pass) = ('test_user', '1');
my $dsn = "dbi:mysql:database=$db_name";
my $dbh = DBI->connect($dsn, $user, $pass);

my $sth = $dbh->prepare("INSERT INTO test.message (id, created, int_id, str) VALUES(?, ?, ?, ?);");
my $tuples = $sth->execute_array(
    { ArrayTupleStatus => \my @tuple_status_msg },
    $messages->{'id'},
    $messages->{'created'},
    $messages->{'int_id'},
    $messages->{'str'},
);
if ($tuples) {
    print "message --> Successfully inserted $tuples records\n";
} else { die $sth->errstr; }

$sth = $dbh->prepare("INSERT INTO test.log (created, int_id, str, address) VALUES(?, ?, ?, ?);");
$tuples = $sth->execute_array(
    { ArrayTupleStatus => \my @tuple_status_log },
    $logs->{'created'},
    $logs->{'int_id'},
    $logs->{'str'},
    $logs->{'address'},
);
if ($tuples) {
    print "log --> Successfully inserted $tuples records\n";
} else { die $sth->errstr; }

say 'well done';
