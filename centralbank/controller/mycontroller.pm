use model::mymodel;
use Data::Dumper;

sub run_controller {
	my (%result, %params, $formname, $submitbutton, @dashboardmenus);
	if ($ENV{'REQUEST_METHOD'} eq "POST") {
		$formname = param('FORMNAME');
		$submitbutton = param('SUBMITBUTTON');
		@dashboardmenus = ('summary','deposit', 'withdraw', 'transfer', 'history','useredit','userupdate','frmupdateuser','frmdepositamt','frmwithdrawamt','frmtransferamt');

		if ($formname eq 'index'
			&& $submitbutton eq 'index') {

			$result{'TEMPLATENAME'} = "views/index.tmpl";
		}
		elsif ($formname eq 'index'
			&& $submitbutton eq 'signin') {

			$result{'TEMPLATENAME'} = "views/login.tmpl";
		}
		elsif ($formname eq 'index'
			&& $submitbutton eq 'signup') {

			$result{'TEMPLATENAME'} = "views/registration.tmpl";
		}
		elsif ($formname eq 'login') {
			my $emailid = param('emailid');
			my $password = param('psw');
			my $user = checkvalidUser($emailid, $password);
			if ($user) {
				my $myargs = { ACCTNO => $user->{acctno}, METHOD => $submitbutton };
				my $dboard = getDashboardData($myargs);
				foreach my $key (keys %$dboard) {
					$params{$key} = $dboard->{$key};
				}
				$result{'TEMPLATENAME'} = "views/dashboard.tmpl";
			}
			else {
				$params{'ERROR'} = qq{<span class="error-text">Email ID or Password Invalid</span>};
				$result{'TEMPLATENAME'} = "views/login.tmpl";
			}
		}
		elsif ($formname eq 'registration'
			&& $submitbutton eq 'register') {

			my $emailid = param('emailid');
			my $password1 = param('psw');
			my $password2 = param('psw-repeat');
			my $user = isUserExists($emailid);
			my $matchpwd = ($password1 eq $password2 ) ? 1 : 0;
			if ($user) {
				$params{'ERROR'} = qq{<span class="error-text">user already exist</span>};
				$result{'TEMPLATENAME'} = "views/registration.tmpl";
			}
			elsif (!$matchpwd) {
				$params{'ERROR'} = qq{<span class="error-text">password mismatch</span>};
				$result{'TEMPLATENAME'} = "views/registration.tmpl";
			}
			else {
				my $newaccontnumber = getNewAccontno();
				my $json = "\n".$emailid.",".$password1.",".$newaccontnumber.",,,,0,,0";
				write2CSV('customer.csv',$json);
				$params{'ALERT'} = qq{alert("Register success");};
				$result{'TEMPLATENAME'} = "views/index.tmpl";
			}
		}
		elsif ($formname ~~ @dashboardmenus ) {
			my $acctno = param('acctno');
			my $myargs = { ACCTNO => $acctno, METHOD => $formname };
			my $dboard = getDashboardData($myargs);
			foreach my $key (keys %$dboard) {
				$params{$key} = $dboard->{$key};
			}
			$result{'TEMPLATENAME'} = "views/dashboard.tmpl";
		}
		else {
			$result{'TEMPLATENAME'} = "views/index.tmpl";
		}
	} else {
		$result{'TEMPLATENAME'} = "views/index.tmpl";
	}
	$result{'PARAMS'} = \%params;
	return %result;
}

1;