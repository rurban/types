package types;

use 5.008;
use strict;
use warnings;
use lib '/Users/sky/perl/optimize-0.01/lib';
use optimize;

our $VERSION = '0.01';

my %typed; 

use constant SVpad_TYPED => 0x40000000;

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
	my ($type1, $type2);
	my ($var1, $var2);
	if($op->first->name eq 'padsv' && exists($typed{$cv->ROOT->seq}->{$op->first->targ})) {
	    $type1 = $typed{$cv->ROOT->seq}->{$op->first->targ}->{type};
	    $var1  = $typed{$cv->ROOT->seq}->{$op->first->targ}->{name};
	}
	if($op->last->name eq 'padsv' && exists($typed{$cv->ROOT->seq}->{$op->last->targ})) {
	    $type2 = $typed{$cv->ROOT->seq}->{$op->last->targ}->{type};
	    $var2  = $typed{$cv->ROOT->seq}->{$op->last->targ}->{name};
	}
	if($type1 ne $type2) {
	    $type1 = "unknown" unless($type1);
	    $type2 = "unknown" unless($type2);
	    
	    die "Type mismatch, can't assign $type1 ($var1) to $type2 ($var2) at ". $optimize::state->file . ":" . $optimize::state->line . "\n";
	}


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

package int;
package float;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

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

=head2 EXPORT

None.

=head1 SEE ALSO

L<optimize> L<B::Generate> L<optimizer>

=head1 AUTHOR

Arthur Bergman, E<lt>ABERGMAN@CPAN.ORGE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Arthur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
