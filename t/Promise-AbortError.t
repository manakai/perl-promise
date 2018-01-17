use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::More;
use Promise::AbortError;

test {
  my $c = shift;
  ok $Web::DOM::Error::L1ObjectClass->{'Promise::AbortError'};
  done $c;
} n => 1, name => 'Perl Error Object Interface Level 1';

test {
  my $c = shift;

  my $error = new Promise::AbortError ('Error message');
  isa_ok $error, 'Promise::AbortError';

  is $error->name, 'AbortError';
  is $error->message, 'Error message';
  is $error->file_name, __FILE__;
  is $error->line_number, __LINE__-6;
  is $error . '', "AbortError: Error message at ".$error->file_name." line ".$error->line_number.".\n";

  done $c;
} name => 'with message', n => 6;

test {
  my $c = shift;

  my $error = new Promise::AbortError;
  is $error->name, 'AbortError';
  is $error->message, 'Aborted';
  is $error->file_name, __FILE__;
  is $error->line_number, __LINE__-4;
  is $error . '', "AbortError: Aborted at ".$error->file_name." line ".$error->line_number.".\n";
  is $error->stringify, $error . '';
  done $c;
} name => 'without message', n => 6;

test {
  my $c = shift;
  my $error1 = new Promise::AbortError ('hoge');
  my $error2 = new Promise::AbortError ('hoge');

  ok $error1 eq $error1;
  ok not $error1 ne $error1;
  ok not $error2 eq $error1;
  ok $error2 ne $error1;
  ok $error1 ne undef;
  ok not $error1 eq undef;
  is $error1 cmp $error1, 0;
  isnt $error1 cmp $error2, 0;
  isnt $error1 . '', $error1;
  
  done $c;
} name => 'eq', n => 9;

run_tests;

=head1 LICENSE

Copyright 2012-2018 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
