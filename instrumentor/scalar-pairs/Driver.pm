package Driver;

use strict;
use FindBin;

use CillySampler;
our @ISA = qw(CillySampler);


########################################################################


sub collectOneArgument {
    my $self = shift;
    my ($arg, $pargs) = @_;

    if ($arg =~ /^--(no-)?compare-constants$/) {
	push @{$self->{instrumentor}}, $arg;
	return 1;
    } else {
	return $self->CillySampler::collectOneArgument(@_);
    }
}


sub extraHeaders {
    my $self = shift;
    my @extras = $self->SUPER::extraHeaders;
    push @extras, '-include', "$::root/libreport/requires.h";
    push @extras, '-include', "$::root/libreport/unit.h";
    push @extras, '-include', "$::home/libscalar-pairs/scalar-pairs.h";
    push @extras, '-include', "$::root/libtuples/tuples-cil.h";
    return @extras;
}


sub extraLibs {
    my $self = shift;
    my @extras = $self->SUPER::extraLibs;
    push @extras, "-L$::root/libreport", '-lreport';
    push @extras, "-L$::home/libscalar-pairs", '-lscalar-pairs';
    return @extras;
}


########################################################################


1;
