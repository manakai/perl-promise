use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Test::Dies;
use Promise;

test {
  my $c = shift;
  my $p = Promise->new (sub { });
  is $p->debug_info, '{Promise: pending, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'new';

test {
  my $c = shift;
  my $p = Promise->new (sub { $_[0]->() });
  is $p->debug_info, '{Promise: fulfilled, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'new fulfilled';

test {
  my $c = shift;
  my $p = Promise->new (sub { $_[1]->() });
  is $p->debug_info, '{Promise: rejected, created at '.__FILE__.' line '.(__LINE__-1).'}';
  $p->catch (sub { }); # catch warning
  done $c;
} n => 1, name => 'new rejected';

test {
  my $c = shift;
  my $p = Promise->resolve;
  is $p->debug_info, '{Promise: fulfilled, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'resolve';

test {
  my $c = shift;
  my $p = Promise->reject;
  is $p->debug_info, '{Promise: rejected, created at '.__FILE__.' line '.(__LINE__-1).'}';
  $p->catch (sub { }); # catch warning
  done $c;
} n => 1, name => 'reject';

test {
  my $c = shift;
  my $p = Promise->all ([]);
  is $p->debug_info, '{Promise: fulfilled, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'all';

test {
  my $c = shift;
  my $p = Promise->race ([]);
  is $p->debug_info, '{Promise: pending, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'race';

test {
  my $c = shift;
  my $p0 = Promise->resolve;
  my $p = $p0->then;
  is $p->debug_info, '{Promise: pending, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'then';

test {
  my $c = shift;
  my $p0 = Promise->resolve;
  my $p = $p0->catch;
  is $p->debug_info, '{Promise: pending, created at '.__FILE__.' line '.(__LINE__-1).'}';
  done $c;
} n => 1, name => 'catch';

run_tests;

=head1 LICENSE

Copyright 2014 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
