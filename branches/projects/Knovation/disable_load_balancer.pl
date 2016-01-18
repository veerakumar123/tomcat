#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use YAML qw(LoadFile);
use Data::Dumper;

print "Trigger Enable/Disable Load Balancer\n";

if (scalar @ARGV != 2) {
	die "Usage: $0 <YAML Config File> <STATE>\n";
}

my $config_file = $ARGV[0];
my $state = $ARGV[1];

unless ( -e $config_file ) {
	die "Unable to open file: $config_file\n";
}

unless ( $state =~ /^(active|disabled)$/ ) {
	die "Invalid state passed\n";
}

my $status = ( $state eq 'active' ? 'enabled' : 'disabled' );

my $data = LoadFile("$config_file");

my $flag = 0;
my $IPs = $data->{'Load_Balancer_Config'};
foreach my $ip (keys %$IPs) {
	for my $host_name ( @{$IPs->{$ip}} ) {
		$flag = 0;
		change_state ( $host_name, $ip );	
	}
}

sub change_state {
	my $server_name = shift @_;
	my $given_ip = shift @_; 
	my $cmd = "curl -s -H 'Content-Type: application/json' -k -u 'veeraveluchamy:3F417it1Jo' 'https://192.168.102.243:9070/api/tm/3.3/config/active/pools/$server_name'";
	my $json = execute_command ( $cmd );
	
	my $hash_string = decode_json($json);
	my @nodes =  @{$hash_string->{'properties'}{'basic'}{'nodes_table'}};
	
	foreach ( @nodes ) {
		my ($ip, $port) = split(/:/,$_->{'node'});
		if ( $ip eq $given_ip ) {
			$_->{'state'}=$state;
			$flag = 1;
		}
	}
	
	die "Given IP is not available in Load Balancer: $given_ip" if ( $flag == 0 ) ;
	
	$hash_string->{'properties'}{'basic'}{'nodes_table'} = \@nodes;
	my $new_json = encode_json $hash_string;
	
	$cmd = "curl -X PUT -s -k -H 'Content-Type: application/json' -u 'veeraveluchamy:3F417it1Jo' 'https://192.168.102.243:9070/api/tm/3.3/config/active/pools/$server_name' -d '$new_json'";
	execute_command ( $cmd );
	
	print "Node $given_ip $status in load balancer $server_name \n";
}

sub execute_command {
	my $command = shift @_;
	my $cmd_result = `$command`;
	
	if ( $? == -1 )
	{
		 die "curl command failed: $!\n";
	}
	elsif ($cmd_result=~/error/i) 
	{
		 die "curl command returned error: $cmd_result\n";
	}
	else {
		
		 printf "curl command exited with value %d\n", $? >> 8;
	}

	return $cmd_result;
}

