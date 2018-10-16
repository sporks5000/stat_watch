use warnings;
use strict;

package SWEscape;

sub fn_escape_filename {
### Given a file name that might have unprintable characters, appropriately escape and quote everything
	my $v_file = $_[0];
	if ( $v_file =~ m/'/ ) {
		### replace all single quotes with a single quote, a backslash, and then two single quotes
		$v_file =~ s/'/'\\''/g;
	}
	if ( $v_file =~ m/[\001-\037\x7F]/ ) {
		### For blocks of unprintable characters, place "'$'" at the start, and "'" at the end
		$v_file =~ s/([\x01-\x1F\x7F]+)/'\$'$1''/g;
		### Replace unprintable characters with their hex value or special character
		$v_file =~ s/\001/\\001/g;
		$v_file =~ s/\002/\\002/g;
		$v_file =~ s/\003/\\003/g;
		$v_file =~ s/\004/\\004/g;
		$v_file =~ s/\005/\\005/g;
		$v_file =~ s/\006/\\006/g;
		$v_file =~ s/\007/\\a/g;
		$v_file =~ s/\010/\\b/g;
		$v_file =~ s/\011/\\t/g;
		$v_file =~ s/\012/\\n/g;
		$v_file =~ s/\013/\\v/g;
		$v_file =~ s/\014/\\f/g;
		$v_file =~ s/\015/\\r/g;
		$v_file =~ s/\016/\\016/g;
		$v_file =~ s/\017/\\017/g;
		$v_file =~ s/\020/\\020/g;
		$v_file =~ s/\021/\\021/g;
		$v_file =~ s/\022/\\022/g;
		$v_file =~ s/\023/\\023/g;
		$v_file =~ s/\024/\\024/g;
		$v_file =~ s/\025/\\025/g;
		$v_file =~ s/\026/\\026/g;
		$v_file =~ s/\027/\\027/g;
		$v_file =~ s/\030/\\030/g;
		$v_file =~ s/\031/\\031/g;
		$v_file =~ s/\032/\\032/g;
		$v_file =~ s/\033/\\033/g;
		$v_file =~ s/\034/\\034/g;
		$v_file =~ s/\035/\\035/g;
		$v_file =~ s/\036/\\036/g;
		$v_file =~ s/\037/\\037/g;
		$v_file =~ s/\x7F/\\177/g;
	}
	### Add a quote at the start of the file name
	$v_file = "'" . $v_file . "'";
	return $v_file;
}

sub fn_shell_escape_filename {
### Escape the file name such that it can be used in a command run with backticks
	my $v_file = $_[0];
	$v_file =~ s/'/'\\''/g;
	$v_file = "'" . $v_file . "'";
	return $v_file;
}

sub fn_unescape_filename {
### Experimental - has not be thoroughly tested
### Take the results of fn_escape_filename and return them to their original form
	my $v_file = $_[0];
	while ( $v_file =~ m/'\$'[\\0-7abtnvfr]+''/ ) {
	### for each block of escaped hex characters
		### separate out the block, and use a null character as a place holder
		my $v_file2 = substr( $&, 3, -2 );
		$v_file = $` . "\000" . $';
		### Replace all of the escaped characters
		$v_file2 =~ s/\\001/\001/g;
		$v_file2 =~ s/\\002/\002/g;
		$v_file2 =~ s/\\003/\003/g;
		$v_file2 =~ s/\\004/\004/g;
		$v_file2 =~ s/\\005/\005/g;
		$v_file2 =~ s/\\006/\006/g;
		$v_file2 =~ s/\\a/\007/g;
		$v_file2 =~ s/\\b/\010/g;
		$v_file2 =~ s/\\t/\011/g;
		$v_file2 =~ s/\\n/\012/g;
		$v_file2 =~ s/\\v/\013/g;
		$v_file2 =~ s/\\f/\014/g;
		$v_file2 =~ s/\\r/\015/g;
		$v_file2 =~ s/\\016/\016/g;
		$v_file2 =~ s/\\017/\017/g;
		$v_file2 =~ s/\\020/\020/g;
		$v_file2 =~ s/\\021/\021/g;
		$v_file2 =~ s/\\022/\022/g;
		$v_file2 =~ s/\\023/\023/g;
		$v_file2 =~ s/\\024/\024/g;
		$v_file2 =~ s/\\025/\025/g;
		$v_file2 =~ s/\\026/\026/g;
		$v_file2 =~ s/\\027/\027/g;
		$v_file2 =~ s/\\030/\030/g;
		$v_file2 =~ s/\\031/\031/g;
		$v_file2 =~ s/\\032/\032/g;
		$v_file2 =~ s/\\033/\033/g;
		$v_file2 =~ s/\\034/\034/g;
		$v_file2 =~ s/\\035/\035/g;
		$v_file2 =~ s/\\036/\036/g;
		$v_file2 =~ s/\\037/\037/g;
		$v_file2 =~ s/\\177/\x7F/g;
		### Put the block of non-printable characters back in place
		$v_file =~ s/\000/$v_file2/;
	}
	if ( $v_file =~ m/'\\''/ ) {
		$v_file =~ s/'\\''/'/g;
	}
	### Remove the first and last character, because they're single quotes
	$v_file = substr( $v_file, 1, -1 );
	return $v_file;
}

1;
