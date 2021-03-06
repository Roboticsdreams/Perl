use DateTime;

sub getCSVHash {
	my ($filename) = @_;
	my (@csvhash);
	open(FH, '<', $filename) or die "Could not open '$file' $!\n";
	$first_line = <FH>;
	my @columnname = split "," , $first_line;
	while (my $line = <FH>) {
		chomp $line;
		my @fields = split "," , $line;
		my $cnt = scalar @columnname;
		my $rec = {};
		foreach my $i (0..$cnt) {
			$rec->{$columnname[$i]} = $fields[$i];
		}
		push @csvhash, $rec;
	}
	close FH;
	return @csvhash;
}

sub checkvalidUser {
	my ($emailid, $password) = @_;
	my $loginflag;
	my @arr = getCSVHash('customer.csv');
	foreach my $row (@arr) {
		if($row->{'emailid'} eq $emailid
			&& $row->{'password'} eq $password) {
			
			$loginflag = $row;
			last;
		}
	}
	return $loginflag;
}

sub getUser {
	my ($acctno) = @_;
	my $user;
	my @arr = getCSVHash('customer.csv');
	foreach my $row (@arr) {
		if($row->{'acctno'} eq $acctno) {
			$user = $row;
			last;
		}
	}
	return $user;
}

sub isUserExists {
	my ($email) = @_;
	my $userexist;
	my @arr = getCSVHash('customer.csv');
	foreach my $row (@arr) {
		if($row->{'emailid'} eq $email) {
			$userexist = 1;
			last;
		}
	}
	return $userexist;
}

sub getNewAccontno {
	my ($acctno, $maxid);
	$maxid = 63200000;
	my @arr = getCSVHash('customer.csv');
	foreach my $row (@arr) {
		if($maxid < $row->{'acctno'}) {
			$maxid = $row->{'acctno'};
		}
	}
	$acctno = $maxid + 1;
	return $acctno;
}

sub getDashboardData {
	my ($args) = @_;
	
	my ($result, $method, $user, $resulttable, $header, $acctno, $json, $alert);
	my ($activeaccountsummary, $activemoneydeposit, $activemoneywithdraw, $activemoneytransfer, $activetransactionhistory);

	$acctno = $args->{ACCTNO};
	$method = $args->{METHOD};
	$user = getUser($acctno);

	if ($method eq 'deposit') {
		$resulttable = getDepositform($acctno);
		$header = 'Money Deposit';
		$activemoneydeposit = 'active';
	}
	elsif ($method eq 'frmdepositamt') {
		my $depositamt = param('depositamt');
		$json = { ACCTNO => $acctno, DEPOSITAMT => $depositamt };
		$alert = depositAmt($json);
		$user = getUser($acctno);
		$resulttable = getSummary($user);
		$header = 'Account Summary';
		$activeaccountsummary = 'active';
	}
	elsif ($method eq 'withdraw') {
		$resulttable = getWithdrawform($user);
		$header = 'Money Withdraw';
		$activemoneywithdraw = 'active';
	}
	elsif ($method eq 'frmwithdrawamt') {
		my $withdrawamt = param('withdrawamt');
		$json = { ACCTNO => $acctno, WITHDRAWAMT => $withdrawamt };
		$alert = withdrawAmt($json);
		$user = getUser($acctno);
		$resulttable = getSummary($user);
		$header = 'Account Summary';
		$activeaccountsummary = 'active';
	}
	elsif ($method eq 'transfer') {
		$resulttable = getTransferform($user);
		$header = 'Money Transfer';
		$activemoneytransfer = 'active';
	}
	elsif ($method eq 'frmtransferamt') {
		my $transferto = param('transferto');
		my $transferamt = param('transferamt');
		$json = { ACCTNO => $acctno, TRANSFERTO => $transferto, TRANSFERAMT => $transferamt };
		$alert = TransferAmt($json);
		$user = getUser($acctno);
		$resulttable = getSummary($user);
		$header = 'Account Summary';
		$activeaccountsummary = 'active';
	}
	elsif ($method eq 'history') {
		$resulttable = getTransactionHistory($acctno);
		$header = 'Transaction History';
		$activetransactionhistory = 'active';
	}
	elsif ($method eq 'useredit') {
		$resulttable = getProfile($user);
		$header = 'Profile Details';
	}
	elsif ($method eq 'userupdate') {
		$resulttable = getUpdateform($user);
		$header = 'Edit Profile';
	}
	elsif ($method eq 'frmupdateuser') {
		my $username = param('username');
		my $gender = param('gender');
		my $dateofbirth = param('dateofbirth');
		my $address = param('address');
		$json = { ACCTNO => $acctno, USERNAME => $username, GENDER => $gender, DATEOFBIRTH => $dateofbirth, ADDRESS => $address };		
		updateProfileCSV($json);
		$user = getUser($acctno);
		$resulttable = getSummary($user);
		$header = 'Account Summary';
		$activeaccountsummary = 'active';
	}
	else {
		$resulttable = getSummary($user);
		$header = 'Account Summary';
		$activeaccountsummary = 'active';
	}
	
	my $result = {
		ACTIVEACCOUNTSUMMARY => $activeaccountsummary,
		ACTIVEMONEYDEPOSIT => $activemoneydeposit,
		ACTIVEMONEYWITHDRAW => $activemoneywithdraw,
		ACTIVEMONEYTRANSFER => $activemoneytransfer,
		ACTIVETRANSACTIONHISTORY => $activetransactionhistory,
		RESULT => $resulttable,
		HEADER => $header,
		USERNAME => $user->{'username'} || 'username',
		ACTNUM => $acctno,
		ALERT => $alert,
		AVATAR => $user->{'gender'} eq 'male' ? 'avatar1.png' : ($user->{'gender'} eq 'female' ? 'avatar2.png' : 'avatar3.png'),
	};
	return $result;
}

sub getSummary {
	my ($args) = @_;

	my $html = qq{<div class="container">};
	$html .= qq{<table class="content-table">};
	$html .= qq{<tr> <td><b>Bank Account Number:</b></td> <td><i>} . $args->{'acctno'} . qq{</i></td> </tr>};
	$html .= qq{<tr> <td><b>Bank Account Type:</b></td> <td><i>Savings A/C</i></td> </tr>};
	$html .= qq{<tr> <td><b>Bank Branch Name:</b></td> <td><i>Chennai- HQ</i></td> </tr>};	
	$html .= qq{<tr> <td><b>Bank Address:</b></td> <td><i>Chennai</i></td> </tr>};
	$html .= qq{<tr> <td><b>PIN Code:</b></td> <td><i>600001</i></td> </tr>};
	$html .= qq{<tr> <td><b>State:</b></td> <td><i>Tamilnadu</i></td> </tr>};
	$html .= qq{<tr> <td><b>Country:</b></td><td><i>India</i></td> </tr>};
	$html .= qq{<tr> <td><b>Account Balance:(Rs)</b></td> <td><i>} . $args->{'acctbalance'} . qq{</i></td> </tr>};
	$html .= qq{</table></div>};
	return $html;
}

sub write2CSV {
	my ($filename, $data) = @_;
	open(FH, '>>', $filename) or die "Could not open '$file' $!\n";
	print FH $data;
	close FH;
}

sub updateProfileCSV {
	my ($data) = @_;
	my $filename = "customer.csv";
	my @arr = getCSVHash($filename);
	my $acctno = $data->{'ACCTNO'};
	open(FH, '>', $filename) or die "Could not open '$file' $!\n";
	my $csvheader = "emailid,password,acctno,username,gender,dateofbirth,acctbalance,address,dummy\n";
	print FH $csvheader;
	foreach my $row (@arr) {
		my $updaterow;
		my $emailid = $row->{'emailid'};
		my $password = $row->{'password'};
		my $acctbalance = $row->{'acctbalance'};
		my $dummy = $row->{'dummy'} || 0;

		if($acctno == $row->{'acctno'}) {
			my $updateuser = $data->{'USERNAME'};
			my $updategender = $data->{'GENDER'};
			my $updatedob = $data->{'DATEOFBIRTH'};
			my $updateaddress = $data->{'ADDRESS'};
			$updaterow = $emailid.",".$password.",".$acctno.",".$updateuser.",".$updategender.",".$updatedob.",".$acctbalance.",".$updateaddress.",".$dummy."\n";
			print FH $updaterow if ($acctno);
		}
		else {
			my $oldacctno = $row->{'acctno'};
			my $username = $row->{'username'};
			my $gender = $row->{'gender'};
			my $dob = $row->{'dateofbirth'};
			my $address = $row->{'address'};
			$updaterow = $emailid.",".$password.",".$oldacctno.",".$username.",".$gender.",".$dob.",".$acctbalance.",".$address.",".$dummy."\n";
			print FH $updaterow if ($oldacctno);
		}
	}
	close FH;
}

sub getProfile {
	my ($args) = @_;
	my $html = qq{<div class="container">};
	$html .= qq{<table class="content-table">};
	$html .= qq{<tr> <td><b>Username:</b></td> <td><i>} . $args->{'username'} . qq{</i></td> </tr>};
	$html .= qq{<tr> <td><b>Gender:</b></td> <td><i>} . $args->{'gender'} . qq{</i></td> </tr>};
	$html .= qq{<tr> <td><b>Date of Birth:</b></td> <td><i>} . $args->{'dateofbirth'} . qq{</i></td> </tr>};
	$html .= qq{<tr> <td><b>Address:</b></td> <td><i>} . $args->{'address'} . qq{</i></td> </tr>};
	$html .= qq{</table><br><br><a href="#" onclick="document.getElementById('frmuseredit').submit();" class="main-button">Edit</a></div>};
	return $html;
}

sub getUpdateform {
	my ($args) = @_;
	my $acctno = $args->{'acctno'};
	my $username = $args->{'username'};
	my $gendermale = $args->{'gender'} eq 'male' ? 'checked' : '';
	my $genderfemale = $args->{'gender'} eq 'female' ? 'checked' : '';
	my $dateofbirth = $args->{'dateofbirth'};
	my $address = $args->{'address'};
	
	my $html = qq{<div class="container">};
	$html .= qq{<table class="content-form">};
	$html .= qq{<form id="frmupdateuser" action="index.pl" method="post">};
	$html .= qq{<input type="hidden" name="FORMNAME" value="frmupdateuser"><input type="hidden" name="acctno" value="$acctno">};
	$html .= qq{<tr> <td><b>Username:</b></td> <td><input type="text" name="username" value="$username"</td> </tr>};
	$html .= qq{<tr> <td><b>Gender:</b></td> <td><input type="radio" name="gender" id="male" $gendermale value="male"><label for="male">Male</label>&nbsp;};
    $html .= qq{<input type="radio" name="gender" id="female"  $genderfemale value="female"><label for="female">Female</label></td> </tr>};
	$html .= qq{<tr> <td><b>Date of Birth:</b></td> <td><input type="text" name="dateofbirth" value="$dateofbirth"</td> </tr>};
	$html .= qq{<tr> <td><b>Address:</b></td><td><input type="text" name="address" value="$address"</td> </tr>};
	$html .= qq{</table><br><br><a href="#" onclick="document.getElementById('frmupdateuser').submit();" class="main-button">Update</a></form></div>};
	return $html;
}

sub getTransactionHistory {
	my ($acctno) = @_;
	my ($html, @transactions);
	my @arr = getCSVHash('transaction.csv');
	foreach my $row (@arr) {
		if(($row->{'operation'} ne 'transfer' && $row->{'toacctno'} eq $acctno)
		 || ($row->{'operation'} eq 'transfer' && $row->{'fromacctno'} eq $acctno)) {

			push @transactions, $row;
		}
	}
	if (@transactions) {
		$html = qq{<div class="container">};
		$html .= qq{<table class="content-table" id="transactiontable">};
		$html .= qq{<tr><th>DateTime</th><th>Operation</th><th>From Account</th>};
		$html .= qq{<th>To Account</th><th>OpeningAmount</th>};
		$html .= qq{<th>Amount</th><th>Total Balance</th></tr>};
		foreach my $trans (@transactions) {
			my $datetime = $trans->{'datetime'};
			my $operation = $trans->{'operation'};
			my $fromacctno = $trans->{'fromacctno'};
			my $toacctno = $trans->{'toacctno'};
			my $openingamt = $trans->{'openingamt'};
			my $amount = $trans->{'amount'};
			my $totalbalance= $trans->{'totalbalance'};
			$datetime = substr $datetime, 1, -1;
			$html .= qq{<tr><td>}.$datetime.qq{</td><td>}.$operation.qq{</td><td>}.$fromacctno;
			$html .= qq{</td><td>}.$toacctno.qq{</td><td>}.$openingamt.qq{</td><td>};
			$html .= $amount.qq{</td><td>}.$totalbalance.qq{</td></tr>};
		}
		$html .= qq{</table></div>};
	}
	else {
		$html = qq{No Transaction Found};
	}
	return $html;
}

sub getDepositform {
	my ($acctno) = @_;

	my $html = qq{<div class="container">};
	$html .= qq{<form id="frmdepositamt" action="index.pl" method="post">};
	$html .= qq{<input type="hidden" name="FORMNAME" value="frmdepositamt"><input type="hidden" name="acctno" value="$acctno">};
	$html .= qq{<b>Deposit Amount:</b>&nbsp; &nbsp;<input type="text" name="depositamt">&nbsp; &nbsp;};
	$html .= qq{<a href="#" onclick="validateDepositForm()" class="form-button">Deposit</a>};
	$html .= qq{</form></div>};
	return $html;
}

sub depositAmt {
	my ($args) = @_;
	my $acctno = $args->{'ACCTNO'};
	my $user = getUser($acctno);
	my $depositamt = $args->{'DEPOSITAMT'};

	if ($user) {
		my $currentbalance = $user->{'acctbalance'};
		my $totalbalance = ($currentbalance + $depositamt);
		my $dt = DateTime->now;
		my $ctdate = $dt->ymd;
		my $cttime = $dt->hms; 
		my $datetime = $ctdate." ".$cttime;
		my $data = "'".$datetime."',credit,self,".$acctno.",".$currentbalance.",".$depositamt.",".$totalbalance.",0\n";
		write2CSV('transaction.csv',$data);
		my $json = {ACCTNO => $acctno, NEWBALANCE => $totalbalance };
		updateBalanceCSV($json);
		$alert = qq{alert("Deposit successful");};
	}
	else {
		$alert = qq{alert("user not found");};
	}
	return $alert;
}

sub updateBalanceCSV {
	my ($data) = @_;
	my $filename = "customer.csv";
	my @arr = getCSVHash($filename);
	my $acctno = $data->{'ACCTNO'};
	my $newbalance = $data->{'NEWBALANCE'};
	open(FH, '>', $filename) or die "Could not open '$file' $!\n";
	my $csvheader = "emailid,password,acctno,username,gender,dateofbirth,acctbalance,address,dummy\n";
	print FH $csvheader;
	foreach my $row (@arr) {
		my $updaterow;
		my $emailid = $row->{'emailid'};
		my $password = $row->{'password'};
		my $username = $row->{'username'};
		my $gender = $row->{'gender'};
		my $dateofbirth = $row->{'dateofbirth'};
		my $address = $row->{'address'};
		my $dummy = $row->{'dummy'} || 0;

		if($acctno == $row->{'acctno'}) {
			$updaterow = $emailid.",".$password.",".$acctno.",".$username.",".$gender.",".$dateofbirth.",".$newbalance.",".$address.",".$dummy."\n";
		}
		else {
			my $oldacctno = $row->{'acctno'};
			my $acctbalance = $row->{'acctbalance'};
			$updaterow = $emailid.",".$password.",".$oldacctno.",".$username.",".$gender.",".$dateofbirth.",".$acctbalance.",".$address.",".$dummy."\n";
		}
		print FH $updaterow;
	}
	close FH;
}

sub getWithdrawform {
	my ($args) = @_;

	my $acctno = $args->{'acctno'};
	my $currentbalance = $args->{'acctbalance'};
	
	my $html = qq{<div class="container">};
	$html .= qq{<form id="frmwithdrawamt" action="index.pl" method="post">};
	$html .= qq{<input type="hidden" name="FORMNAME" value="frmwithdrawamt">};
	$html .= qq{<input type="hidden" name="acctno" value="$acctno">};
	$html .= qq{<input type="hidden" name="acctbalance" value="$currentbalance">};
	$html .= qq{<b>Withdraw Amount:</b>&nbsp; &nbsp;<input type="text" name="withdrawamt">&nbsp; &nbsp;};
	$html .= qq{<a href="#" onclick="validateWithdrawForm()" class="form-button">Withdraw</a>};
	$html .= qq{</form></div>};
	return $html;
}

sub withdrawAmt {
	my ($args) = @_;
	my $acctno = $args->{'ACCTNO'};
	my $user = getUser($acctno);
	my $withdrawamt = $args->{'WITHDRAWAMT'};

	if ($user) {
		my $currentbalance = $user->{'acctbalance'};
		my $totalbalance = ($currentbalance - $withdrawamt);
		my $dt = DateTime->now;
		my $ctdate = $dt->ymd;
		my $cttime = $dt->hms; 
		my $datetime = $ctdate." ".$cttime;
		my $data = "'".$datetime."',debit,self,".$acctno.",".$currentbalance.",".$withdrawamt.",".$totalbalance.",0\n";
		write2CSV('transaction.csv',$data);
		my $json = {ACCTNO => $acctno, NEWBALANCE => $totalbalance };
		updateBalanceCSV($json);
		$alert = qq{alert("Withdraw successful");};
	}
	else {
		$alert = qq{alert("user not found");};
	}
	return $alert;
}

sub getTransferform {
	my ($args) = @_;

	my $acctno = $args->{'acctno'};
	my $currentbalance = $args->{'acctbalance'};
	
	my $html = qq{<div class="container">};
	$html .= qq{<form id="frmtransferamt" action="index.pl" method="post">};
	$html .= qq{<input type="hidden" name="FORMNAME" value="frmtransferamt">};
	$html .= qq{<input type="hidden" name="acctno" value="$acctno">};
	$html .= qq{<input type="hidden" name="acctbalance" value="$currentbalance">};
	$html .= qq{<b>Transfer To Account:</b>&nbsp; &nbsp; <input type="text" name="transferto"><br>};
	$html .= qq{<b>Transfer Amount:</b>&nbsp; &nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="text" name="transferamt">&nbsp; &nbsp;};
	$html .= qq{<a href="#" onclick="validateTransferForm()" class="form-button">Transfer</a>};
	$html .= qq{</form></div>};
	return $html;
}

sub TransferAmt {
	my ($args) = @_;
	my $acctno = $args->{'ACCTNO'};
	my $fromuser = getUser($acctno);
	my $currentbalance = $fromuser->{'acctbalance'};
	my $transferto = $args->{'TRANSFERTO'};
	my $touser = getUser($transferto);
	my $transferamt = $args->{'TRANSFERAMT'};

	if ($fromuser->{'acctno'} == '') {
		$alert = qq{alert("Your account number is Invalid!");};
	}
	elsif ($touser->{'acctno'} == '') {
		$alert = qq{alert("To account number is Invalid!");};
	}
	elsif ($transferamt > $currentbalance) {
		$alert = qq{alert("Insufficent Balance!");};
	}
	else {
		my $frombalance = ($currentbalance - $transferamt);
		my $dt = DateTime->now;
		my $ctdate = $dt->ymd;
		my $cttime = $dt->hms; 
		my $datetime = $ctdate." ".$cttime;
		my $data = "'".$datetime."',transfer,".$acctno.",".$transferto.",".$currentbalance.",".$transferamt.",".$frombalance.",0\n";
		write2CSV('transaction.csv',$data);
		my $json = {ACCTNO => $acctno, NEWBALANCE => $frombalance };
		updateBalanceCSV($json);
		
		my $exisitingtobalance = $touser->{'acctbalance'};
		my $tobalance = ($exisitingtobalance + $transferamt);
		my $data = "'".$datetime."',credit,".$acctno.",".$transferto.",".$exisitingtobalance.",".$transferamt.",".$tobalance.",0\n";
		write2CSV('transaction.csv',$data);
		my $json = {ACCTNO => $transferto, NEWBALANCE => $tobalance };
		updateBalanceCSV($json);
		$alert = qq{alert("Transfer successful");};
	}

	return $alert;
}
1;
