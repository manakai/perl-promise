package AbortSignal;
use strict;
use warnings;
our $VERSION = '1.0';
use AbortSignal;
use Promise::AbortError;

push our @CARP_NOT, qw(Promise::AbortError);

## DOM: isa EventTarget
## DOM: onabort

sub manakai_onabort ($;$) {
  if (@_ > 1) {
    $_[0]->{abort_cb} = $_[0]->{aborted} ? undef : $_[1];
  }
  return $_[0]->{abort_cb};
} # manakai_onabort

sub aborted ($) { $_[0]->{aborted} }

sub _signal_abort ($) {
  my $signal = $_[0];

  return if $signal->{aborted};
  $signal->{aborted} = 1;

  ## Abort algorithms for Perl [DOMPERL]
  my $cb = $signal->{abort_cb};
  if (defined $cb) {
    my $e = Promise::AbortError->new;
    my $file = $e->file_name;
    $file =~ s/[\x0D\x0A\x22]/_/g;
    my $code = sprintf q{#line %d "%s"
$cb->();
1}, $e->line_number, $file;
    eval $code or warn "$@\n"; # XXX report exception
    delete $signal->{abort_cb};
  }
} # _signal_abort

sub DESTROY ($) {
  local $@;
  eval { die };
  if ($@ =~ /during global destruction/) {
    warn "$$: Reference to AbortSignal ($_[0]) is not discarded before global destruction\n";
  }
} # DESTROY

1;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
