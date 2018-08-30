use warnings;
use strict;

sub fn_fold_print {
### Given a message to print to the terminal, line-break that message at word breaks
### $_[0] is the message; $_[1] is the number of columns to use if columns can't be determined.
	### Determine how many columns we're working with
	my $v_columns;
	if( exists $ENV{PATH} && defined $ENV{PATH} ) {
		my @v_paths = split( m/:/, $ENV{PATH} );
		for ( @v_paths ) {
			if ( -f ( $_ . "/tput" ) && -x ( $_ . "/tput" ) ) {
				my $v_exe =  $_ . "/tput";
				$v_columns = `$v_exe cols`;
				chomp $v_columns;
				if ( $v_columns =~ m/^[0-9]+$/ ) {
					last;
				}
			}
		}
	}
	if ( $v_columns && $v_columns !~ m/^[0-9]+$/ ) {
		if ( $_[1] ) {
			$v_columns = $_[1];
		} else {
			return $_[0];
		}
	} else {
		$v_columns--;
	}

	### Go through each line of the message and make sure it's breaks appropriately
	my @v_message = split( m/\n/, ( $_[0] . "\n" . "last" ) );
	for my $_line ( @v_message ) {
		chomp( $_line );
		$_line =~ s/\t/     /g;
		$_line = $_line . "\n";
		next if length( $_line ) <= $v_columns;
		my $v_remaining = length( $_line ) - 1;
		my $v_complete = 0;
		my $v_spaces = "";
		for my $_character ( 0 .. ( $v_remaining - 1 ) ) {
			if ( substr( $_line, $_character, 1 ) =~ m/[ *-]/ ) {
				$v_spaces = $v_spaces . " ";
			} else {
				last;
			}
		}
		my $v_length_spaces = length( $v_spaces );
		while ( $v_remaining >= $v_columns ) {
			for my $_character ( reverse( ( $v_complete + $v_length_spaces ) .. ( $v_complete + $v_columns ) ) ) {
				if ( substr( $_line, $_character, 1 ) eq " "  ) {
					$_line = substr( $_line, 0, $_character ) . "\n" . $v_spaces . substr( $_line, ($_character + 1) );
					$v_remaining = ( length( $_line ) - 1 - $_character + 1 );
					$v_complete = ( $_character + 1 );
					last;
				}
				if ( $_character == ( $v_complete + $v_length_spaces ) ) {
					$v_remaining -= $v_columns;
					$v_complete += $v_columns;
				}
			}
		}
	}
	pop @v_message;
	$v_message[$#v_message] = substr( $v_message[$#v_message], 0, (length( $v_message[$#v_message] ) - 1 ) );
	return @v_message;
}

1;
