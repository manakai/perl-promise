use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use AbortController;

test {
  my $c = shift;
  my $ac = new AbortController;
  isa_ok $ac, 'AbortController';
  isa_ok $ac->signal, 'AbortSignal';
  is $ac->signal, $ac->signal, '[SameObject] signal';
  done $c;
} n => 3, name => 'AbortController';

test {
  my $c = shift;
  my $ac = new AbortController;
  my $sig = $ac->signal;
  ok ! $sig->aborted;
  is $sig->manakai_onabort, undef;
  my $aborted = 0;
  my $code = sub {
    $aborted = 1;
  };
  $sig->manakai_onabort ($code);
  is $aborted, 0;
  $ac->abort;
  is $aborted, 1;
  $ac->abort;
  is $aborted, 1;
  is $sig->manakai_onabort, undef;
  ok $sig->aborted;
  $sig->manakai_onabort (sub { });
  is $sig->manakai_onabort, undef;
  done $c;
} n => 8, name => 'AbortSignal';

test {
  my $c = shift;
  my $ac = new AbortController;
  my $sig = $ac->signal;
  ok ! $sig->aborted;
  is $sig->manakai_onabort, undef;
  my $aborted = 0;
  my $code = sub {
    $aborted = 1;
    die "callback died";
  };
  $sig->manakai_onabort ($code);
  is $aborted, 0;
  $ac->abort;
  is $aborted, 1;
  $ac->abort;
  is $aborted, 1;
  is $sig->manakai_onabort, undef;
  ok $sig->aborted;
  $sig->manakai_onabort (sub { });
  is $sig->manakai_onabort, undef;
  done $c;
} n => 8, name => 'AbortSignal bad callback';

test {
  my $c = shift;
  my $ac = new AbortController;
  my $sig = $ac->signal;
  ok ! $sig->aborted;
  is $sig->manakai_onabort, undef;
  my $aborted = 0;
  my $code = sub {
    $aborted = 1;
  };
  my $aborted2 = 0;
  my $code2 = sub {
    $aborted2 = 1;
  };
  $sig->manakai_onabort ($code);
  $sig->manakai_onabort ($code2);
  is $aborted, 0;
  is $aborted2, 0;
  $ac->abort;
  is $aborted, 0;
  is $aborted2, 1;
  done $c;
} n => 6, name => 'AbortSignal unused callback';

run_tests;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
