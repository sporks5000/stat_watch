use strict;
use warnings;

my $v_VERSION = "1.0.0";

package sw_md5;

use Digest::MD5 'md5_hex';
use Digest::MD5::File 'file_md5_hex';

sub get_md5 {
### Given the name of a file that is not a symlink, return the md5sum of the contents of that file
### Given a symlink, return the md5sum the text of where that link points to
	if ( ! -l $_[0] ) {
		return file_md5_hex($_[0]);
	} else {
		return md5_hex( readlink($_[0]) );
	}
}

1;
