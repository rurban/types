package types;

use 5.008;
use strict;
use warnings;
use optimize;

our $VERSION = '0.02';

my %typed;
my %op_returns;
use constant SVpad_TYPED => 0x40000000;

our %const_map = (
	  "B::NV" => 'float',
	  "B::IV" => 'int',
	  "B::PV" => 'string',
	    );

sub entry {
    my $op = shift;
    my $cv = $op->find_cv();

    if($op->name eq 'padsv') {
	my $target = (($cv->PADLIST->ARRAY)[0]->ARRAY)[$op->targ];
	if(UNIVERSAL::isa($target,'B::SV') && $target->FLAGS & SVpad_TYPED) {
	    $typed{$cv->ROOT->seq}->{$op->targ}->{type} = $target->SvSTASH->NAME;
	    $typed{$cv->ROOT->seq}->{$op->targ}->{name} = $target->PV;
	}
    }

    if($op->name eq 'sassign') {
	my ($lhs, $rhs, $const);
	my ($lhs_v, $rhs_v);
	if($op->first->name eq 'padsv'
	   && exists($typed{$cv->ROOT->seq}->{$op->first->targ})) {
	    $rhs    = $typed{$cv->ROOT->seq}->{$op->first->targ}->{type};
	    $rhs_v  = $typed{$cv->ROOT->seq}->{$op->first->targ}->{name};

	} elsif(exists($op_returns{$op->first->seq})) {
	    $rhs = $op_returns{$op->first->seq}->{type};
	    $rhs_v = $op_returns{$op->first->seq}->{name};
	} elsif($op->first->name eq 'const' && 
		exists($const_map{ref($op->first->sv)})) {
	    $rhs = $const_map{ref($op->first->sv)};
	    $rhs_v = "constant '" . $op->first->sv->sv."'";

	}
	if($op->last->name eq 'padsv'
	   && exists($typed{$cv->ROOT->seq}->{$op->last->targ})) {
	  ## okay, are we assigning a constant ?

	  $lhs    = $typed{$cv->ROOT->seq}->{$op->last->targ}->{type};
	  $lhs_v  = $typed{$cv->ROOT->seq}->{$op->last->targ}->{name};
	}

	return if(!$lhs and $op->first->name eq 'const');
	
#	print "$lhs - $rhs\n";
#	print "$lhs->isa($rhs): ". $lhs->isa($rhs) . "\n";
#	print "$rhs->isa($lhs): ". $rhs->isa($lhs) . "\n";

	$lhs = "unknown" unless($lhs);
	$rhs = "unknown" unless($rhs);
	if((!$lhs->isa($rhs) and !$rhs->isa($lhs)) or ($lhs->can('check') && !$lhs->check($rhs))) {
	  die "Type mismatch, can't assign $rhs ($rhs_v) to $lhs ($lhs_v) at " . 
	    $optimize::state->file . ":" . $optimize::state->line . "\n";
	}
	$op_returns{$op->seq}->{type} = $lhs;
	$op_returns{$op->seq}->{name} = $lhs_v;
    }

}

sub import {
    my ($package, $filename, $line) = caller;
    optimize->register(\&entry, $package, $filename, $line);
}

sub unimport {
    my ($package, $filename, $line) = caller;

    optimize->unregister($package);
}

package unknown;
our $dummy = 1;


package int;
our $dummy = 1;
sub check {
    return 0 if($_[0] eq 'int' && ($_[1] ne 'number' && $_[1] ne 'int'));    
    return 1;
}
package float;
use base qw(int);
sub check {
    return 0 if($_[1] eq 'string');
    return 1;
}
our $dummy = 1;
package number;
use base qw(float);
sub check {
    return 0 if($_[1] eq 'string');
    return 1;
}
our $dummy = 1;
package string;
use base qw(number);
sub check { return 1};
1;
__END__


=head1 NAME

types - Perl pragma for strict type checking

=head1 SYNOPSIS

  use types;
  my int $int;
  my float $float;
  $int = $float; # BOOM compile time error!

=head1 ABSTRACT

This pragma uses the optimzie module to analyze the optree and
turn on compile time type checking

=head1 DESCRIPTION

This pragma uses the optimzie module to analyze the optree and
turn on compile time type checking

Currently we support int, float, number and string, the implict
casting rules are as follows.

    
    int    < > number
    int      > float
    float  < > number
    number   > string


Normall type casting is allowed both up and down the inheritance tree,
so in theory user defined classes should work already, requires one
to do use base or set @ISA at compileitme in a BEGIN block.

=head2 EXPORT

None.

=head1 BUGS

Please report bugs and submit patches using http://rt.cpan.org/


=head1 SEE ALSO

L<optimize> L<B::Generate> L<optimizer>

=head1 AUTHOR

Arthur Bergman, E<lt>ABERGMAN@CPAN.ORGE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Arthur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
