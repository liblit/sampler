package Sampler;

use strict;
use FindBin;

use CilConfig;


########################################################################


sub setDefaultArguments {
    my $self = shift;

    $self->{countdowns} = 'acyclic';
    $self->{sample_events} = 1;
    $self->{TRACE_COMMANDS} = 0;
    unshift @{$self->{LD}}, 'libtool';
}


sub collectOneArgument {
    my $self = shift;
    my ($arg, $pargs) = @_;

    if ($arg =~ /^--(in|ex)clude-(function|file)$/) {
	push @{$self->{instrumentor}}, $arg, shift @{$pargs};
	return 1;
    } elsif ($arg eq '--no-sample') {
	push @{$self->{instrumentor}}, $arg;
	$self->{sample_events} = 0;
	return 1;
    } elsif ($arg eq '--sample') {
	push @{$self->{instrumentor}}, $arg;
	$self->{sample_events} = 1;
	return 1;
    } elsif ($arg =~ /^--(a?cyclic)$/) {
	$self->{countdowns} = $1;
	return 1;
    } elsif ($arg =~ /^--(no-)?show-stats$/) {
	push @{$self->{instrumentor}}, $arg;
	return 1;
    } elsif ($arg =~ /^--(no-)?specialize-(singleton|empty)-regions$/) {
	push @{$self->{instrumentor}}, $arg;
	return 1;
    } elsif ($arg =~ /^--(no-)?use-points-to$/) {
	push @{$self->{instrumentor}}, $arg;
	return 1;
    } else {
	return 0;
    }
}


########################################################################


sub runShellOut {
    my ($self, $out, @cmd) = @_;
    open my $oldOut, '>&STDOUT' or die "cannot dup stdout: $!\n";
    open STDOUT, '>', $out->filename or die "cannot redirect stdout: $!\n";

    $self->runShell(@cmd);

    close STDOUT;
    open STDOUT, '>&', $oldOut or die "cannot restore stdout: $!\n";
}


########################################################################


sub libcountdown {
    my $self = shift;
    return $self->root . '/libcountdown';
}


sub sampling {
    my $self = shift;
    return $self->{sample_events};
}


sub extraHeaders {
    my $self = shift;
    my @extras;

    my $dir = $self->libcountdown;
    push @extras, '-DCIL';
    push @extras, '-include', "$dir/countdown.h" if $self->sampling;
    push @extras, '-include', "$dir/$self->{countdowns}.h" if $self->{sample_events};

    return @extras;
}


sub extraLibs {
    my $self = shift;
    my @extras;

    if ($self->sampling) {
	push @extras, '-L' . $self->libcountdown;
	push @extras, "-l$self->{countdowns}";
    }

    return @extras;
}


########################################################################


1;
