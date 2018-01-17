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

test {
  my $c = shift;

  my $ac = AbortController->new;
  is $ac->signal->manakai_error, undef;

  $ac->abort;
  my $e = $ac->signal->manakai_error;
  is $ac->signal->manakai_error, $e;
  isa_ok $e, 'Promise::AbortError';
  is $e->name, 'AbortError';
  is $e->message, 'Aborted';
  is $e->file_name, __FILE__;
  is $e->line_number, __LINE__-7;

  my $f = rand;
  $ac->signal->manakai_error ($f);
  is $ac->signal->manakai_error, $f;

  $ac->signal->manakai_error (undef);
  is $ac->signal->manakai_error, undef;

  done $c;
} n => 9, name => 'manakai_error set by abort';

test {
  my $c = shift;

  my $ac = AbortController->new;
  is $ac->signal->manakai_error, undef;

  my $f = rand;
  $ac->signal->manakai_error ($f);
  is $ac->signal->manakai_error, $f;

  $ac->abort;
  my $e = $ac->signal->manakai_error;
  is $ac->signal->manakai_error, $e;
  isa_ok $e, 'Promise::AbortError';
  is $e->name, 'AbortError';
  is $e->message, 'Aborted';
  is $e->file_name, __FILE__;
  is $e->line_number, __LINE__-7;

  done $c;
} n => 8, name => 'manakai_error set before abort';

run_tests;

=head1 LICENSE

Copyright 2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
