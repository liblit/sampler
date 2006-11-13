#!/usr/bin/perl -w
# -*- cperl -*-

use strict;

use DBI;
use File::Basename;
use File::Find;

use lib '../populate';
use Common;
use Site;


########################################################################


my %suppressed;
{
    my $dbh = Common::connect;

    my $sth = $dbh->prepare(q{
	SELECT application_name, application_version, application_release, build_distribution
	    FROM build
	    WHERE build_suppress IS NOT NULL
	});
    $sth->execute;

    my ($name, $version, $release, $distro);
    $sth->bind_columns(\$name, \$version, \$release, \$distro);
    while ($sth->fetch) {
	$suppressed{$distro}{"$name-$version-$release"} = 1;
    }

    $dbh->disconnect;
}


########################################################################


print "stamps :=\n";


sub wanted {
    return unless /^(.*)-samplerinfo-(.*)\.[^.]+\.rpm$/;
    my $build = "$1-$2";

    my $distro = basename dirname $File::Find::dir;
    die unless $distro =~ /^\w+-\d+-i386$/;
    return if $suppressed{$distro}{$build};

    my $stamp = "results/$distro/$build/stamp";
    print <<"EOT";

stamps += $stamp
$stamp: $File::Find::name modernize
	mkdir -p \$(\@D)
	./one \$< \$(\@D)
	touch \$@
EOT
}


my $rpmdir = "$ENV{HOME}/public_html/sampler/downloads/rpm";
find \&wanted, $rpmdir if -d $rpmdir;
