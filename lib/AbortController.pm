package AbortController;
use strict;
use warnings;
our $VERSION = '1.0';
use AbortSignal;

push our @CARP_NOT, qw(AbortSignal);

sub new ($) {
  return bless {
    signal => (bless {}, 'AbortSignal'),
  }, $_[0];
} # new

sub signal ($) { $_[0]->{signal} }

sub abort ($) {
  $_[0]->{signal}->_signal_abort;
} # abort

1;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
