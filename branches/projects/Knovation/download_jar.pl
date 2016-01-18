#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use YAML qw(LoadFile);
use Data::Dumper;

if (scalar @ARGV != 1) {
	die "Usage: $0 <YAML Config File>\n";
}

my $config_file = $ARGV[0];

unless ( -e $config_file ) {
	die "Unable to open file: $config_file\n";
}

my $data = LoadFile("$config_file");
#print Dumper \$data;


#my $download_path = $data->{'Download_Jar_Config'}{'DirectoryPath'};

download_jar ( );

sub download_jar {
	my @urls = @{$data->{'Download_Jar_Config'}};
	#print Dumper \@urls;
	
	foreach my $url_sect ( @urls ) {
		my $dir_path = $url_sect->{'DirectoryPath'};
		my @url_list = @{$url_sect->{'URL_list'}};
		foreach ( @url_list ) {
			my $cmd = "wget $_ -P $dir_path >/tmp/output";
			execute_command ( $cmd );
		}
	}
}


sub execute_command {
	my $command = shift @_;
	my $cmd_result = `$command`;
	
	if ( $? == -1 ) {
		 die "wget command failed: $!\n";
	}
	elsif ($cmd_result=~/error/i) {
		 die "wget command returned error: $cmd_result\n";
	}
	else {
		 printf "wget command exited with value %d\n", $? >> 8;
	}

	return $cmd_result;
}
