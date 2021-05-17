#!"\PortableApps\xampp\perl\bin\perl.exe"

use strict;
use CGI ':standard';
use controller::mycontroller;
use utils::myhelpers;
use Data::Dumper;

my $cgi = CGI->new();
my @param_names = $cgi->param();
foreach my $p (@param_names) {
  my $value = $cgi->param($p);
  #warn "Param $p = $value\n";
}

my %hash = run_controller();

my $args = {
	TEMPLATENAME => $hash{TEMPLATENAME},
	PARAMS => $hash{PARAMS},
};

my $html = rendertemplate($args);
sendpage($html);