#!/usr/bin/env sh

usage () {
	cat <<-USAGE
	use openssl to read an HTTPS certificate from a remote host

	$@ -h <host> -p <port>
	  -h : hostname/IP address
	  -p : port number

	USAGE
}

progname=`basename $0`

if [ $# -ne 4 ] ; then
	usage "$progname"
	exit 1
fi

while getopts "h:p:" opt ; do
	case $opt in
	h)
		HTTPSHOST="$OPTARG"
		;;
	p)
		HTTPSPORT="$OPTARG"
		;;
	\?)
		usage "$progname"
		exit 1
		;;
	esac
done

echo -e 'HEAD / HTTP/1.0\r\n\r\n' | \
  openssl \
    s_client \
    -connect $HTTPSHOST:$HTTPSPORT 2>/dev/null | \
      sed '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/!d'
