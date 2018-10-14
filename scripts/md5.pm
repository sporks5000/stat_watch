use strict;
use warnings;

package SWmd5;

use Digest::MD5 'md5_hex';
use Digest::MD5::File 'file_md5_hex';

sub get_md5 {
### Given the name of a file that is not a symlink, return the md5sum of the contents of that file
### Given a symlink, return the md5sum the text of where that link points to
	my $v_md5;
	if ( -e $_[0] ) {
		if ( ! -l $_[0] ) {
			$v_md5 = ( file_md5_hex($_[0]) || '' );
		} else {
			$v_md5 = ( md5_hex( readlink($_[0]) ) || '' );
		}
	}
	return $v_md5;
}

1;
