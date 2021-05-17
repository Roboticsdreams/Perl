# HELPERS which are common to the framework

use CGI ':standard';
use HTML::Template;
use Data::Dumper;

sub sendpage {
	my $content = shift;
	print CGI::header();
	print $content->output();
}

sub rendertemplate {
	my ($args) = @_;
	my $params = $args->{PARAMS};
	my $filename = $args->{TEMPLATENAME};
	my $template = HTML::Template->new(filename => $filename);
	
	foreach my $key (keys %$params) {
		$template->param($key => $params->{$key});
	}
	return $template;
}
1;