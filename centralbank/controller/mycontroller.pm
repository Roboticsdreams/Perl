use model::mymodel;
use Data::Dumper;

sub run_controller {
	my (%result, %params, $formname, $submitbutton, @dashboardmenus);
	if ($ENV{'REQUEST_METHOD'} eq "POST") {
		$formname = param('FORMNAME');
		$submitbutton = param('SUBMITBUTTON');
		@dashboardmenus = ('summary','deposit', 'withdraw', 'transfer', 'history','useredit','userupdate');

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
				my $myargs = { USER => $user, METHOD => $submitbutton };
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
			my $user = getUser($acctno);
			my $myargs = { USER => $user, METHOD => $formname };
			my $dboard = getDashboardData($myargs);
			foreach my $key (keys %$dboard) {
				$params{$key} = $dboard->{$key};
			}
			$result{'TEMPLATENAME'} = "views/dashboard.tmpl";
		}
		elsif ($formname eq 'frmupdateuser') {
			my $acctno = param('acctno');
			my $username = param('username');
			my $gender = param('gender');
			my $dateofbirth = param('dateofbirth');
			my $address = param('address');
			my $json = { ACCTNO => $acctno, USERNAME => $username, GENDER => $gender, DATEOFBIRTH => $dateofbirth, ADDRESS => $address };		
			updateProfileCSV($json);
			my $user = getUser($acctno);
			my $myargs = { USER => $user, METHOD => $formname };
			my $dboard = getDashboardData($myargs);
			foreach my $key (keys %$dboard) {
				$params{$key} = $dboard->{$key};
			}
			$params{'ALERT'} = qq{alert("update success");};
			$result{'TEMPLATENAME'} = "views/dashboard.tmpl";
		}
		elsif ($formname eq 'frmdepositamt') {
			my $acctno = param('acctno');
			my $depositamt = param('depositamt');
			my $json = { ACCTNO => $acctno, DEPOSITAMT => $depositamt };
			my $alert = depositAmt($json);
			my $user = getUser($acctno);
			my $myargs = { USER => $user, METHOD => $formname };
			my $dboard = getDashboardData($myargs);
			foreach my $key (keys %$dboard) {
				$params{$key} = $dboard->{$key};
			}
			$params{'ALERT'} = $alert;
			$result{'TEMPLATENAME'} = "views/dashboard.tmpl";
		}
		elsif ($formname eq 'frmwithdrawamt') {
			my $acctno = param('acctno');
			my $withdrawamt = param('withdrawamt');
			my $json = { ACCTNO => $acctno, WITHDRAWAMT => $withdrawamt };
			my $alert = withdrawAmt($json);
			my $user = getUser($acctno);
			my $myargs = { USER => $user, METHOD => $formname };
			my $dboard = getDashboardData($myargs);
			foreach my $key (keys %$dboard) {
				$params{$key} = $dboard->{$key};
			}
			$params{'ALERT'} = $alert;
			$result{'TEMPLATENAME'} = "views/dashboard.tmpl";
		}
		elsif ($formname eq 'frmtransferamt') {
			my $acctno = param('acctno');
			my $transferto = param('transferto');
			my $transferamt = param('transferamt');
			my $json = { ACCTNO => $acctno, TRANSFERTO => $transferto, TRANSFERAMT => $transferamt };
			my $alert = TransferAmt($json);
			my $user = getUser($acctno);
			my $myargs = { USER => $user, METHOD => $formname };
			my $dboard = getDashboardData($myargs);
			foreach my $key (keys %$dboard) {
				$params{$key} = $dboard->{$key};
			}
			$params{'ALERT'} = $alert;
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